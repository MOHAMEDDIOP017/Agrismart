#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
==============================================================================
 Étape 2 — Construction des étiquettes (variable cible)
 Mémoire AgriSmart — Recommandation de cultures / zones agroécologiques Sénégal

 Entrée  : dataset_senegal_brut.csv   (sortie de l'étape 1)
 Sorties :
   - dataset_final_multiclasse.csv : 1 ligne par (point, culture compatible)
                                     -> pour entraîner le classifieur
   - dataset_final_meilleure_culture.csv : 1 ligne par point, étiquette =
                                     culture au score maximal
   - rapport_etiquetage.txt : statistiques et décisions documentées

 Méthodologie (à reprendre dans le chapitre "Construction du dataset") :
   1. Nettoyage : suppression des points sans données sol SoilGrids
      (points en mer/fleuve) ; imputation P/K par moyenne de zone.
   2. Score d'aptitude par culture : fonction trapézoïdale inspirée de la
      méthode FAO Ecocrop — chaque variable (température, pluie, pH) vaut
      1 dans la plage optimale, décroît linéairement jusqu'à 0 aux bornes
      absolues. Score global = moyenne géométrique (une variable rédhibitoire
      annule le score).
   3. Irrigation : dans les zones à agriculture irriguée (Vallée du Fleuve,
      Niayes), la contrainte de pluviométrie est levée pour les cultures
      irrigables (riz, tomate, oignon, patate douce) — conforme à la réalité
      des périmètres irrigués SAED et du maraîchage des Niayes.
   4. Étiquetage : une ligne d'entraînement par culture dont le score >= 0.5 ;
      la colonne 'score_aptitude' permet une pondération ultérieure.

 Usage :
   python construire_etiquettes.py --entree dataset_senegal_brut.csv
==============================================================================
"""

import argparse
import sys

import numpy as np
import pandas as pd

# -----------------------------------------------------------------------------
# 1. RÈGLES ECOCROP POUR LES 8 CULTURES CIBLES
#    Plages (opt_min, opt_max) = optimales ; (abs_min, abs_max) = absolues.
#    Sources : base FAO Ecocrop + fiches techniques ISRA. Unités :
#    température °C (moyenne annuelle), pluie mm/an, pH eau.
#    'irrigable' : la contrainte pluie peut être levée en zone irriguée.
# -----------------------------------------------------------------------------
CULTURES = {
    "mil": {
        "temp": (25, 32, 18, 38), "pluie": (400, 750, 250, 1200),
        "ph": (5.5, 7.5, 4.5, 8.3), "irrigable": False,
    },
    "sorgho": {
        "temp": (24, 32, 15, 38), "pluie": (500, 1000, 300, 1500),
        "ph": (5.5, 7.5, 4.5, 8.5), "irrigable": False,
    },
    "mais": {
        "temp": (22, 30, 15, 36), "pluie": (600, 1200, 400, 1800),
        "ph": (5.5, 7.5, 4.5, 8.0), "irrigable": False,
    },
    "riz": {
        "temp": (22, 32, 15, 38), "pluie": (900, 1800, 700, 3000),
        "ph": (5.0, 7.0, 4.0, 8.2), "irrigable": True,
    },
    "arachide": {
        "temp": (24, 32, 18, 38), "pluie": (500, 1000, 350, 1300),
        "ph": (5.5, 7.0, 4.8, 8.0), "irrigable": False,
    },
    "niebe": {
        "temp": (24, 33, 18, 38), "pluie": (400, 900, 300, 1400),
        "ph": (5.5, 7.5, 4.5, 8.3), "irrigable": False,
    },
    "manioc": {
        "temp": (24, 32, 18, 36), "pluie": (800, 1500, 500, 2500),
        "ph": (4.8, 7.0, 4.0, 8.0), "irrigable": False,
    },
    "tomate": {
        "temp": (20, 28, 15, 34), "pluie": (600, 1300, 400, 1800),
        "ph": (5.5, 7.0, 4.5, 8.0), "irrigable": True,
    },
}

# Zones où l'irrigation est structurellement disponible
ZONES_IRRIGUEES = {"Vallee_du_Fleuve", "Niayes"}

SEUIL_APTITUDE = 0.5   # score minimal pour retenir une culture comme étiquette

# -----------------------------------------------------------------------------
# 1 bis. VARIABLES DU MODÈLE
#    Les 16 variables d'entrée, dans l'ordre exact attendu par
#    modele_final.joblib. Cette liste est le contrat entre la chaîne
#    d'entraînement (FEATURES du notebook entrainer_multilabel.ipynb) et le
#    backend (CLE_ML_VERS_ANALYSE_PARCELLE de app/services/agroeco_zones.py).
#    Toute divergence d'ordre ou de nom produirait des prédictions fausses
#    sans lever d'erreur — un test automatique la verrouille, voir
#    agrismart-backend/tests/test_pipeline_donnees.py
# -----------------------------------------------------------------------------
VARIABLES_MODELE = [
    "N_total_g_kg", "P_extractible_ppm", "K_extractible_ppm",
    "pH_eau", "clay_pct", "sand_pct", "silt_pct",
    "carbone_org_g_kg", "temperature_moy_C",
    "temperature_max_mois_C", "temperature_min_mois_C",
    "humidite_moy_pct", "pluie_annuelle_mm", "pluie_hivernage_mm",
    "ndvi_moyen_annuel", "ndvi_hivernage",
]

# Colonnes conservées dans les CSV produits : identification du point + variables.
VARIABLES_DATASET = ["zone_agroecologique", "latitude", "longitude"] + VARIABLES_MODELE


# -----------------------------------------------------------------------------
# 2. FONCTION D'APTITUDE TRAPÉZOÏDALE (méthode Ecocrop)
# -----------------------------------------------------------------------------
def aptitude_trapezoidale(x, opt_min, opt_max, abs_min, abs_max):
    """Vaut 1 dans [opt_min, opt_max], 0 hors [abs_min, abs_max],
    décroissance linéaire entre les deux."""
    if pd.isna(x):
        return np.nan
    if opt_min <= x <= opt_max:
        return 1.0
    if x <= abs_min or x >= abs_max:
        return 0.0
    if x < opt_min:
        return (x - abs_min) / (opt_min - abs_min)
    return (abs_max - x) / (abs_max - opt_max)


def score_culture(ligne, regles, zone_irriguee):
    """Score global = moyenne géométrique des aptitudes temp/pluie/pH."""
    s_temp = aptitude_trapezoidale(ligne["temperature_moy_C"], *regles["temp"])
    s_ph = aptitude_trapezoidale(ligne["pH_eau"], *regles["ph"])
    if regles["irrigable"] and zone_irriguee:
        s_pluie = 1.0          # contrainte pluie levée : irrigation disponible
    else:
        s_pluie = aptitude_trapezoidale(ligne["pluie_annuelle_mm"],
                                        *regles["pluie"])
    scores = [s_temp, s_pluie, s_ph]
    if any(pd.isna(s) for s in scores):
        return np.nan
    return float(np.cbrt(s_temp * s_pluie * s_ph))   # moyenne géométrique


# -----------------------------------------------------------------------------
# 3. PIPELINE
# -----------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--entree", default="dataset_senegal_brut.csv")
    ap.add_argument("--seuil", type=float, default=SEUIL_APTITUDE)
    args = ap.parse_args()

    df = pd.read_csv(args.entree)
    rapport = [f"Fichier d'entrée : {args.entree}",
               f"Lignes brutes : {len(df)}"]

    # --- Nettoyage --------------------------------------------------------
    # a) points sans données sol SoilGrids (mer/fleuve) -> suppression
    avant = len(df)
    df = df.dropna(subset=["pH_eau", "N_total_g_kg", "clay_pct"]).copy()
    rapport.append(f"Points supprimés (pas de sol SoilGrids, mer/fleuve) : "
                   f"{avant - len(df)}")

    # b) P/K manquants -> imputation par moyenne de zone (documentée)
    for col in ["P_extractible_ppm", "K_extractible_ppm"]:
        n_imp = df[col].isna().sum()
        df[col] = df.groupby("zone_agroecologique")[col].transform(
            lambda s: s.fillna(s.mean()))
        rapport.append(f"Imputation moyenne de zone — {col} : {n_imp} valeurs")

    rapport.append(f"Points conservés : {len(df)}")

    # --- Scores d'aptitude ------------------------------------------------
    for culture, regles in CULTURES.items():
        df[f"score_{culture}"] = df.apply(
            lambda l: score_culture(
                l, regles, l["zone_agroecologique"] in ZONES_IRRIGUEES),
            axis=1)

    cols_scores = [f"score_{c}" for c in CULTURES]

    # --- Dataset multi-classes : 1 ligne par (point, culture apte) --------
    variables = VARIABLES_DATASET

    lignes = []
    for _, l in df.iterrows():
        for culture in CULTURES:
            s = l[f"score_{culture}"]
            if pd.notna(s) and s >= args.seuil:
                d = {v: l[v] for v in variables}
                d["culture"] = culture
                d["score_aptitude"] = round(s, 3)
                lignes.append(d)
    multi = pd.DataFrame(lignes)
    multi.to_csv("dataset_final_multiclasse.csv", index=False,
                 encoding="utf-8-sig")

    # --- Dataset "meilleure culture" : 1 ligne par point ------------------
    df["culture"] = df[cols_scores].idxmax(axis=1).str.replace("score_", "")
    df["score_aptitude"] = df[cols_scores].max(axis=1).round(3)
    meilleur = df[variables + ["culture", "score_aptitude"]]
    meilleur.to_csv("dataset_final_meilleure_culture.csv", index=False,
                    encoding="utf-8-sig")

    # --- Rapport ----------------------------------------------------------
    rapport.append(f"\nSeuil d'aptitude : {args.seuil}")
    rapport.append(f"Dataset multi-classes : {len(multi)} lignes")
    rapport.append("\nRépartition des étiquettes (multi-classes) :")
    rapport.append(multi["culture"].value_counts().to_string())
    rapport.append("\nRépartition (meilleure culture par point) :")
    rapport.append(meilleur["culture"].value_counts().to_string())
    rapport.append("\nCultures aptes par zone (nb de lignes multi-classes) :")
    rapport.append(multi.groupby(["zone_agroecologique", "culture"])
                   .size().unstack(fill_value=0).to_string())

    texte = "\n".join(rapport)
    with open("rapport_etiquetage.txt", "w", encoding="utf-8") as f:
        f.write(texte)
    print(texte)
    print("\nFichiers produits : dataset_final_multiclasse.csv, "
          "dataset_final_meilleure_culture.csv, rapport_etiquetage.txt")


if __name__ == "__main__":
    sys.exit(main())
