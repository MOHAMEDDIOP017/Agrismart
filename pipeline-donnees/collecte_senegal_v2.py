#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
==============================================================================
 Étape 1 — Collecte du jeu de données brut (sol + climat)
 Mémoire AgriSmart — Recommandation de cultures / zones agroécologiques Sénégal

 Échantillonne des points GPS dans les 6 zones agroécologiques du Sénégal, puis
 interroge les API ouvertes pour constituer, point par point, les variables de
 sol et de climat.

 Entrée  : aucune (les points sont générés)
 Sortie  : dataset_senegal_brut.csv  -> entrée de l'étape 2 (NDVI)

 Usage :
   python collecte_senegal_v2.py --points-par-zone 150        --isda-user <utilisateur> --isda-pass <mot_de_passe>

 Les réponses des API sont mises en cache sur disque (cache_api/) : une
 exécution interrompue reprend sans réinterroger les points déjà collectés.

 Sources interrogées :
   1. ISRIC SoilGrids v2.0  -> propriétés du sol (azote total, pH, texture,
      carbone organique) à 250 m de résolution
   2. NASA POWER (climatologie) -> température, pluviométrie, humidité
      relative (moyennes mensuelles et annuelles 2001-2020)
   3. (Optionnel) iSDAsoil Africa -> phosphore et potassium extractibles
      (SoilGrids ne fournit PAS P et K ; iSDA les fournit pour l'Afrique
      à 30 m — compte gratuit : https://www.isda-africa.com/api/registration/
      L'API v2 utilise un login username/password -> token Bearer 60 min)

"""

import argparse
import json
import math
import os
import random
import sys
import time

import pandas as pd
import requests
from tqdm import tqdm

# -----------------------------------------------------------------------------
# 1. DÉFINITION DES 6 ZONES AGROÉCOLOGIQUES DU SÉNÉGAL
#    Boîtes englobantes approximatives (lat_min, lat_max, lon_min, lon_max).
#    Sources : découpage classique ISRA / CSE. À affiner si tu disposes
#    d'un shapefile officiel (voir README).
# -----------------------------------------------------------------------------
ZONES = {
    "Vallee_du_Fleuve": {
        "bbox": (15.50, 16.65, -16.50, -13.30),
        "cultures_dominantes": ["riz", "tomate", "oignon", "patate_douce"],
    },
    "Niayes": {
        "bbox": (14.75, 15.35, -17.05, -16.65),
        "cultures_dominantes": ["tomate", "oignon", "chou", "carotte"],
    },
    "Bassin_Arachidier": {
        "bbox": (13.70, 15.10, -16.90, -14.50),
        "cultures_dominantes": ["arachide", "mil", "niebe", "sorgho"],
    },
    "Zone_Sylvopastorale": {
        "bbox": (14.60, 16.00, -15.50, -13.50),
        "cultures_dominantes": ["mil", "niebe", "sorgho"],
    },
    "Senegal_Oriental": {
        "bbox": (12.60, 14.40, -13.50, -11.40),
        "cultures_dominantes": ["mais", "coton", "sorgho", "arachide"],
    },
    "Casamance": {
        "bbox": (12.30, 13.15, -16.75, -13.60),
        "cultures_dominantes": ["riz", "mais", "manioc", "arachide"],
    },
}

# -----------------------------------------------------------------------------
# 2. PARAMÈTRES DES APIs
# -----------------------------------------------------------------------------
SOILGRIDS_URL = "https://rest.isric.org/soilgrids/v2.0/properties/query"
# Propriétés SoilGrids demandées (couche superficielle 0-20 cm) :
#   nitrogen = azote total (cg/kg), phh2o = pH eau (pH*10),
#   clay/sand/silt = texture (g/kg -> %), soc = carbone organique (dg/kg)
SOILGRIDS_PROPS = ["nitrogen", "phh2o", "clay", "sand", "silt", "soc"]
SOILGRIDS_DEPTHS = ["0-5cm", "5-15cm"]

NASA_POWER_URL = "https://power.larc.nasa.gov/api/temporal/climatology/point"
# T2M = température à 2 m (°C), PRECTOTCORR = précipitations (mm/jour),
# RH2M = humidité relative (%)
NASA_PARAMS = "T2M,PRECTOTCORR,RH2M"

ISDA_BASE = "https://api.isda-africa.com"
ISDA_TOKEN = {"value": None, "ts": 0}  # token v2, expire au bout de 60 min

# Temporisations entre appels — valeurs retenues lors de la collecte réelle.
# SoilGrids tolère environ 1 requête/seconde ; iSDA impose un rate limit.
PAUSE_APRES_SOILGRIDS_S = 1.2
PAUSE_AVANT_ISDA_S = 0.3
PAUSE_ENTRE_PROPRIETES_ISDA_S = 0.5

# Le token iSDA v2 expire au bout de 60 min : on le renouvelle à 55 min.
ISDA_TOKEN_TTL_S = 3300

# Bruit appliqué à la grille régulière, en fraction du pas, pour éviter que
# tous les points tombent au centre d'un même pixel SoilGrids.
JITTER_GRILLE = 0.1

CACHE_DIR = "cache_api"
os.makedirs(CACHE_DIR, exist_ok=True)


# -----------------------------------------------------------------------------
# 3. UTILITAIRES
# -----------------------------------------------------------------------------
def _cache_path(prefix: str, lat: float, lon: float) -> str:
    return os.path.join(CACHE_DIR, f"{prefix}_{lat:.4f}_{lon:.4f}.json")


def _get_with_cache(prefix, lat, lon, url, params, headers=None,
                    max_retries=4, timeout=40):
    """GET avec cache disque + retries exponentiels (APIs publiques lentes)."""
    cpath = _cache_path(prefix, lat, lon)
    if os.path.exists(cpath):
        with open(cpath, encoding="utf-8") as f:
            return json.load(f)
    for attempt in range(max_retries):
        try:
            r = requests.get(url, params=params, headers=headers or {},
                             timeout=timeout)
            if r.status_code == 200:
                data = r.json()
                with open(cpath, "w", encoding="utf-8") as f:
                    json.dump(data, f)
                return data
            if r.status_code == 429:          # rate limit
                time.sleep(10 * (attempt + 1))
                continue
        except requests.RequestException:
            time.sleep(3 * (attempt + 1))
    return None


def generer_grille(bbox, n_points, seed=42):
    """
    Génère n_points répartis dans la boîte englobante :
    grille régulière + léger bruit aléatoire (jitter) pour éviter
    l'alignement parfait des pixels SoilGrids.
    """
    lat_min, lat_max, lon_min, lon_max = bbox
    rng = random.Random(seed)
    n_cote = max(2, math.ceil(math.sqrt(n_points)))
    pas_lat = (lat_max - lat_min) / n_cote
    pas_lon = (lon_max - lon_min) / n_cote
    points = []
    for i in range(n_cote):
        for j in range(n_cote):
            lat = lat_min + (i + 0.5) * pas_lat + rng.uniform(-JITTER_GRILLE, JITTER_GRILLE) * pas_lat
            lon = lon_min + (j + 0.5) * pas_lon + rng.uniform(-JITTER_GRILLE, JITTER_GRILLE) * pas_lon
            points.append((round(lat, 4), round(lon, 4)))
    rng.shuffle(points)
    return points[:n_points]


# -----------------------------------------------------------------------------
# 4. COLLECTE SOILGRIDS
# -----------------------------------------------------------------------------
def collecter_soilgrids(lat, lon):
    params = [("lon", lon), ("lat", lat), ("value", "mean")]
    params += [("property", p) for p in SOILGRIDS_PROPS]
    params += [("depth", d) for d in SOILGRIDS_DEPTHS]
    data = _get_with_cache("soilgrids", lat, lon, SOILGRIDS_URL, params)
    if not data:
        return {}

    res = {}
    try:
        for layer in data["properties"]["layers"]:
            nom = layer["name"]
            # moyenne des profondeurs 0-5 et 5-15 cm -> couche arable ~0-15 cm
            vals = [d["values"]["mean"] for d in layer["depths"]
                    if d["values"]["mean"] is not None]
            if not vals:
                continue
            v = sum(vals) / len(vals)
            # conversions vers unités usuelles
            if nom == "nitrogen":          # cg/kg -> g/kg
                res["N_total_g_kg"] = round(v / 100.0, 3)
            elif nom == "phh2o":           # pH*10 -> pH
                res["pH_eau"] = round(v / 10.0, 2)
            elif nom in ("clay", "sand", "silt"):   # g/kg -> %
                res[f"{nom}_pct"] = round(v / 10.0, 1)
            elif nom == "soc":             # dg/kg -> g/kg
                res["carbone_org_g_kg"] = round(v / 10.0, 2)
    except (KeyError, TypeError):
        return {}
    return res


# -----------------------------------------------------------------------------
# 5. COLLECTE NASA POWER (climatologie 2001-2020)
# -----------------------------------------------------------------------------
def collecter_nasa_power(lat, lon):
    params = {
        "parameters": NASA_PARAMS,
        "community": "AG",
        "longitude": lon,
        "latitude": lat,
        "format": "JSON",
    }
    data = _get_with_cache("nasapower", lat, lon, NASA_POWER_URL, params)
    if not data:
        return {}
    try:
        p = data["properties"]["parameter"]
        # "ANN" = valeur annuelle ; les mois servent aux variables saisonnières
        t2m = p["T2M"]
        rh = p["RH2M"]
        pr = p["PRECTOTCORR"]
        mois = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
        # pluviométrie annuelle : PRECTOTCORR est en mm/jour -> mm/an
        jours = [31, 28.25, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        pluie_annuelle = sum(pr[m] * j for m, j in zip(mois, jours))
        # saison des pluies (juin-octobre) : cœur de l'hivernage sénégalais
        pluie_hivernage = sum(pr[m] * j for m, j in zip(mois, jours)
                              if m in ("JUN", "JUL", "AUG", "SEP", "OCT"))
        return {
            "temperature_moy_C": round(t2m["ANN"], 2),
            "temperature_max_mois_C": round(max(t2m[m] for m in mois), 2),
            "temperature_min_mois_C": round(min(t2m[m] for m in mois), 2),
            "humidite_moy_pct": round(rh["ANN"], 2),
            "pluie_annuelle_mm": round(pluie_annuelle, 1),
            "pluie_hivernage_mm": round(pluie_hivernage, 1),
        }
    except (KeyError, TypeError):
        return {}


# -----------------------------------------------------------------------------
# 6. COLLECTE iSDA (P et K extractibles) — OPTIONNEL, clé API gratuite requise
# -----------------------------------------------------------------------------
def _isda_token(username, password):
    """Obtient (ou renouvelle) le token d'accès iSDA v2 — expire en 60 min."""
    if ISDA_TOKEN["value"] and (time.time() - ISDA_TOKEN["ts"]) < ISDA_TOKEN_TTL_S:
        return ISDA_TOKEN["value"]
    try:
        r = requests.post(f"{ISDA_BASE}/login",
                          data={"username": username, "password": password},
                          timeout=30)
        if r.status_code == 200:
            ISDA_TOKEN["value"] = r.json().get("access_token")
            ISDA_TOKEN["ts"] = time.time()
            return ISDA_TOKEN["value"]
    except requests.RequestException:
        pass
    return None


def collecter_isda(lat, lon, username, password):
    """P et K extractibles via l'API iSDA v2 (login -> token Bearer)."""
    if not username or not password:
        return {}
    res = {}
    for prop, cle_sortie in [("phosphorous_extractable", "P_extractible_ppm"),
                             ("potassium_extractable", "K_extractible_ppm")]:
        cpath = _cache_path(f"isda_{prop}", lat, lon)
        if os.path.exists(cpath):
            with open(cpath, encoding="utf-8") as f:
                data = json.load(f)
        else:
            token = _isda_token(username, password)
            if not token:
                return res
            try:
                r = requests.get(
                    f"{ISDA_BASE}/isdasoil/v2/soilproperty",
                    params={"lat": lat, "lon": lon,
                            "property": prop, "depth": "0-20"},
                    headers={"Authorization": f"Bearer {token}"},
                    timeout=30)
                if r.status_code != 200:
                    continue
                data = r.json()
                with open(cpath, "w", encoding="utf-8") as f:
                    json.dump(data, f)
            except requests.RequestException:
                continue
            time.sleep(PAUSE_ENTRE_PROPRIETES_ISDA_S)   # respect du rate limit iSDA
        try:
            val = data["property"][prop][0]["value"]["value"]
            res[cle_sortie] = round(float(val), 2)
        except (KeyError, TypeError, IndexError, ValueError):
            pass
    return res


# -----------------------------------------------------------------------------
# 7. PIPELINE PRINCIPAL
# -----------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser(description="Collecte dataset Sénégal")
    ap.add_argument("--points-par-zone", type=int, default=60,
                    help="Nombre de points GPS par zone agroécologique")
    ap.add_argument("--isda-user", type=str, default="",
                    help="Nom d'utilisateur iSDAsoil (optionnel, pour P et K)")
    ap.add_argument("--isda-pass", type=str, default="",
                    help="Mot de passe iSDAsoil (optionnel, pour P et K)")
    ap.add_argument("--sortie", type=str, default="dataset_senegal_brut.csv")
    args = ap.parse_args()

    lignes = []
    for zone, info in ZONES.items():
        points = generer_grille(info["bbox"], args.points_par_zone)
        print(f"\n=== Zone : {zone} — {len(points)} points ===")
        for lat, lon in tqdm(points, desc=zone):
            ligne = {"zone_agroecologique": zone,
                     "latitude": lat, "longitude": lon,
                     "cultures_dominantes": ";".join(info["cultures_dominantes"])}
            ligne.update(collecter_soilgrids(lat, lon))
            time.sleep(PAUSE_APRES_SOILGRIDS_S)   # SoilGrids tolère ~1 req/s max
            ligne.update(collecter_nasa_power(lat, lon))
            time.sleep(PAUSE_AVANT_ISDA_S)
            ligne.update(collecter_isda(lat, lon, args.isda_user, args.isda_pass))
            lignes.append(ligne)

        # sauvegarde incrémentale après chaque zone (reprise possible via cache)
        pd.DataFrame(lignes).to_csv(args.sortie, index=False,
                                    encoding="utf-8-sig")
        print(f"  -> sauvegarde intermédiaire : {args.sortie} "
              f"({len(lignes)} lignes)")

    df = pd.DataFrame(lignes)
    df.to_csv(args.sortie, index=False, encoding="utf-8-sig")

    # petit rapport de complétude
    print("\n========= RAPPORT DE COLLECTE =========")
    print(f"Total lignes : {len(df)}")
    print(f"Colonnes     : {list(df.columns)}")
    print("\nTaux de valeurs manquantes (%) :")
    print((df.isna().mean() * 100).round(1).to_string())
    print("\nFichier final :", os.path.abspath(args.sortie))


if __name__ == "__main__":
    sys.exit(main())
