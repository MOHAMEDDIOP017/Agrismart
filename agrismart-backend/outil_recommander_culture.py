#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
==============================================================================
 Outil `recommander_culture` — Agent IA agricole AgriSmart
 Mémoire : recommandation de cultures / zones agroécologiques du Sénégal

 RÔLE : à partir du simple nom d'une localité sénégalaise, l'outil récupère
 automatiquement les 16 variables (sol, climat, végétation) attendues par le
 modèle, interroge `modele_final.joblib`, et renvoie le top-3 des cultures
 recommandées — avec un message bilingue français / wolof.

 CHAÎNE INTERNE :
   localité --(géocodage Open-Meteo)--> lat/lon
            --(SoilGrids)--> sol (N, pH, texture, carbone)
            --(iSDA moyennes de zone)--> P, K
            --(NASA POWER)--> climat
            --(NDVI moyen de la zone agroécologique)--> ndvi
            --(modèle)--> probabilités par culture --> top-3

 Cet outil est conçu pour être appelé par l'agent Qwen (function calling),
 mais il est aussi utilisable seul en ligne de commande pour les tests.

 Usage test :
   pip install requests joblib scikit-learn xgboost numpy
   python outil_recommander_culture.py "Kaolack"
==============================================================================
"""

import json
import sys
import unicodedata

import joblib
import numpy as np
import requests

MODELE_PATH = "modele_final.joblib"

# -----------------------------------------------------------------------------
# 1. TABLES DE RÉFÉRENCE (issues du dataset — pas d'appel externe nécessaire)
# -----------------------------------------------------------------------------
# NDVI moyen par zone agroécologique (décision : moyenne de zone, sans GEE)
NDVI_ZONE = {
    "Bassin_Arachidier":  {"ndvi_moyen_annuel": 0.329, "ndvi_hivernage": 0.438},
    "Casamance":          {"ndvi_moyen_annuel": 0.544, "ndvi_hivernage": 0.644},
    "Niayes":             {"ndvi_moyen_annuel": 0.303, "ndvi_hivernage": 0.369},
    "Senegal_Oriental":   {"ndvi_moyen_annuel": 0.437, "ndvi_hivernage": 0.612},
    "Vallee_du_Fleuve":   {"ndvi_moyen_annuel": 0.236, "ndvi_hivernage": 0.290},
    "Zone_Sylvopastorale":{"ndvi_moyen_annuel": 0.288, "ndvi_hivernage": 0.382},
}

# Moyennes P/K par zone (iSDA) — utilisées en repli si l'API iSDA est absente
PK_ZONE = {
    "Bassin_Arachidier":  {"P_extractible_ppm": 7.19, "K_extractible_ppm": 71.3},
    "Casamance":          {"P_extractible_ppm": 6.87, "K_extractible_ppm": 53.9},
    "Niayes":             {"P_extractible_ppm": 9.50, "K_extractible_ppm": 88.0},
    "Senegal_Oriental":   {"P_extractible_ppm": 6.10, "K_extractible_ppm": 62.0},
    "Vallee_du_Fleuve":   {"P_extractible_ppm": 8.20, "K_extractible_ppm": 95.0},
    "Zone_Sylvopastorale":{"P_extractible_ppm": 5.80, "K_extractible_ppm": 58.0},
}

# Moyennes SOL + CLIMAT par zone (issues du dataset) — repli complet si une
# API externe est indisponible : l'outil recommande toujours quelque chose.
SOL_CLIMAT_ZONE = {
    "Bassin_Arachidier": {"N_total_g_kg": 0.66, "pH_eau": 6.17, "clay_pct": 13.86, "sand_pct": 71.23, "silt_pct": 14.93, "carbone_org_g_kg": 7.51, "temperature_moy_C": 27.88, "temperature_max_mois_C": 31.41, "temperature_min_mois_C": 24.18, "humidite_moy_pct": 49.05, "pluie_annuelle_mm": 632.79, "pluie_hivernage_mm": 621.16},
    "Casamance": {"N_total_g_kg": 1.44, "pH_eau": 5.61, "clay_pct": 24.55, "sand_pct": 49.16, "silt_pct": 26.29, "carbone_org_g_kg": 21.13, "temperature_moy_C": 27.23, "temperature_max_mois_C": 31.47, "temperature_min_mois_C": 23.45, "humidite_moy_pct": 60.49, "pluie_annuelle_mm": 1175.84, "pluie_hivernage_mm": 1148.24},
    "Niayes": {"N_total_g_kg": 0.88, "pH_eau": 6.48, "clay_pct": 21.33, "sand_pct": 61.36, "silt_pct": 17.3, "carbone_org_g_kg": 9.44, "temperature_moy_C": 25.58, "temperature_max_mois_C": 28.2, "temperature_min_mois_C": 22.5, "humidite_moy_pct": 63.73, "pluie_annuelle_mm": 525.35, "pluie_hivernage_mm": 465.19},
    "Senegal_Oriental": {"N_total_g_kg": 0.87, "pH_eau": 6.05, "clay_pct": 25.97, "sand_pct": 42.36, "silt_pct": 31.67, "carbone_org_g_kg": 11.08, "temperature_moy_C": 28.64, "temperature_max_mois_C": 34.46, "temperature_min_mois_C": 24.66, "humidite_moy_pct": 48.64, "pluie_annuelle_mm": 965.99, "pluie_hivernage_mm": 933.03},
    "Vallee_du_Fleuve": {"N_total_g_kg": 0.48, "pH_eau": 6.87, "clay_pct": 15.23, "sand_pct": 70.87, "silt_pct": 13.9, "carbone_org_g_kg": 5.81, "temperature_moy_C": 28.39, "temperature_max_mois_C": 32.65, "temperature_min_mois_C": 22.97, "humidite_moy_pct": 40.62, "pluie_annuelle_mm": 395.6, "pluie_hivernage_mm": 380.05},
    "Zone_Sylvopastorale": {"N_total_g_kg": 0.47, "pH_eau": 6.47, "clay_pct": 15.9, "sand_pct": 67.16, "silt_pct": 16.94, "carbone_org_g_kg": 6.01, "temperature_moy_C": 28.92, "temperature_max_mois_C": 33.74, "temperature_min_mois_C": 23.94, "humidite_moy_pct": 39.25, "pluie_annuelle_mm": 506.09, "pluie_hivernage_mm": 498.73},
}

# Bornes (lat_min, lat_max, lon_min, lon_max) des 6 zones -> pour rattacher
# une localité à sa zone agroécologique
ZONES_BBOX = {
    "Vallee_du_Fleuve":   (15.50, 16.70, -16.60, -13.30),
    "Niayes":             (14.75, 15.35, -17.05, -16.65),
    "Bassin_Arachidier":  (13.70, 15.10, -16.90, -14.50),
    "Zone_Sylvopastorale":(14.60, 16.00, -15.50, -13.50),
    "Senegal_Oriental":   (12.60, 14.40, -13.50, -11.40),
    "Casamance":          (12.30, 13.15, -16.75, -13.60),
}

# Noms lisibles + traduction wolof des cultures
CULTURE_FR = {"arachide": "arachide", "mais": "maïs", "manioc": "manioc",
              "mil": "mil", "niebe": "niébé", "riz": "riz",
              "sorgho": "sorgho", "tomate": "tomate"}
CULTURE_WO = {"arachide": "gerte", "mais": "mbóq", "manioc": "ñambi",
              "mil": "dugub", "niebe": "ñebbe", "riz": "ceeb",
              "sorgho": "bàkka", "tomate": "tamaate"}
ZONE_FR = {"Vallee_du_Fleuve": "Vallée du Fleuve", "Niayes": "Niayes",
           "Bassin_Arachidier": "Bassin arachidier",
           "Zone_Sylvopastorale": "Zone sylvopastorale",
           "Senegal_Oriental": "Sénégal oriental", "Casamance": "Casamance"}


# -----------------------------------------------------------------------------
# 2. FONCTIONS DE COLLECTE EN TEMPS RÉEL
# -----------------------------------------------------------------------------
def geocoder(localite):
    """Nom de localité -> (lat, lon, nom_resolu) via l'API Open-Meteo."""
    r = requests.get("https://geocoding-api.open-meteo.com/v1/search",
                     params={"name": localite, "count": 1,
                             "country": "SN", "language": "fr"}, timeout=20)
    res = r.json().get("results")
    if not res:
        # nouvel essai sans filtre pays
        r = requests.get("https://geocoding-api.open-meteo.com/v1/search",
                         params={"name": localite, "count": 1}, timeout=20)
        res = r.json().get("results")
    if not res:
        return None
    g = res[0]
    return g["latitude"], g["longitude"], g["name"]


def zone_de(lat, lon):
    """Rattache un point à sa zone agroécologique (par les bornes)."""
    for zone, (la0, la1, lo0, lo1) in ZONES_BBOX.items():
        if la0 <= lat <= la1 and lo0 <= lon <= lo1:
            return zone
    # repli : zone la plus proche du centre
    best, dmin = None, 1e9
    for zone, (la0, la1, lo0, lo1) in ZONES_BBOX.items():
        cla, clo = (la0 + la1) / 2, (lo0 + lo1) / 2
        d = (lat - cla) ** 2 + (lon - clo) ** 2
        if d < dmin:
            best, dmin = zone, d
    return best


def collecter_sol(lat, lon):
    """SoilGrids -> N, pH, texture, carbone. Interrogation propriété par
    propriété (plus fiable que tout demander d'un coup) avec 2 tentatives.
    Renvoie ce qui a pu être récupéré (éventuellement partiel)."""
    import time
    props = {"nitrogen": ("N_total_g_kg", 100.0),
             "phh2o": ("pH_eau", 10.0), "clay": ("clay_pct", 10.0),
             "sand": ("sand_pct", 10.0), "silt": ("silt_pct", 10.0),
             "soc": ("carbone_org_g_kg", 10.0)}
    out = {}
    for prop, (cle, diviseur) in props.items():
        for essai in range(2):
            try:
                r = requests.get(
                    "https://rest.isric.org/soilgrids/v2.0/properties/query",
                    params=[("lon", lon), ("lat", lat), ("value", "mean"),
                            ("property", prop),
                            ("depth", "0-5cm"), ("depth", "5-15cm")],
                    timeout=25)
                if r.status_code != 200:
                    time.sleep(2)
                    continue
                layer = r.json()["properties"]["layers"][0]
                vals = [d["values"]["mean"] for d in layer["depths"]
                        if d["values"]["mean"] is not None]
                if vals:
                    out[cle] = (sum(vals) / len(vals)) / diviseur
                break
            except requests.RequestException:
                time.sleep(2)
    return out


def collecter_climat(lat, lon):
    """NASA POWER -> températures, humidité, pluies."""
    r = requests.get(
        "https://power.larc.nasa.gov/api/temporal/climatology/point",
        params={"parameters": "T2M,PRECTOTCORR,RH2M", "community": "AG",
                "longitude": lon, "latitude": lat, "format": "JSON"},
        timeout=40)
    p = r.json()["properties"]["parameter"]
    mois = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
            "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
    jours = [31, 28.25, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    pr = p["PRECTOTCORR"]
    pluie_an = sum(pr[m] * j for m, j in zip(mois, jours))
    pluie_hiv = sum(pr[m] * j for m, j in zip(mois, jours)
                    if m in ("JUN", "JUL", "AUG", "SEP", "OCT"))
    t = p["T2M"]
    return {
        "temperature_moy_C": t["ANN"],
        "temperature_max_mois_C": max(t[m] for m in mois),
        "temperature_min_mois_C": min(t[m] for m in mois),
        "humidite_moy_pct": p["RH2M"]["ANN"],
        "pluie_annuelle_mm": pluie_an,
        "pluie_hivernage_mm": pluie_hiv,
    }


# -----------------------------------------------------------------------------
# 3. FONCTION PRINCIPALE DE L'OUTIL
# -----------------------------------------------------------------------------
def recommander_culture(localite, top_k=3):
    """
    Entrée : nom d'une localité sénégalaise (str).
    Sortie : dict JSON avec le top-k des cultures recommandées + message
             bilingue. Format pensé pour être renvoyé tel quel par l'agent.
    """
    modele = joblib.load(MODELE_PATH)
    pipeline = modele["pipeline"]
    classes = list(modele["binarizer"].classes_)
    features = modele["features"]

    # 1) localité -> coordonnées
    geo = geocoder(localite)
    if not geo:
        return {"erreur": f"Localité introuvable : « {localite} ». "
                          f"Précisez une commune ou une ville du Sénégal."}
    lat, lon, nom = geo
    zone = zone_de(lat, lon)

    # 2) collecte des variables — temps réel si possible, sinon moyenne de zone
    #    On part des moyennes de la zone (toujours disponibles) et on remplace
    #    par les valeurs temps réel quand les APIs répondent.
    vars_ = {}
    vars_.update(SOL_CLIMAT_ZONE.get(zone, {}))   # socle garanti (sol + climat)
    vars_.update(PK_ZONE.get(zone, {}))           # P, K de la zone
    vars_.update(NDVI_ZONE.get(zone, {}))         # NDVI de la zone

    sources = {"sol": "moyenne de zone", "climat": "moyenne de zone",
               "P_K": "moyenne de zone", "ndvi": "moyenne de zone"}
    try:
        sol = collecter_sol(lat, lon)
        if len(sol) >= 4:                 # assez de variables sol récupérées
            vars_.update(sol)
            sources["sol"] = "SoilGrids (temps réel)"
    except Exception:
        pass
    try:
        clim = collecter_climat(lat, lon)
        if clim:
            vars_.update(clim)
            sources["climat"] = "NASA POWER (temps réel)"
    except Exception:
        pass

    manquantes = [f for f in features if f not in vars_]
    if manquantes:      # ne devrait plus arriver grâce au socle de zone
        return {"erreur": "Données indisponibles pour cette zone.",
                "variables_manquantes": manquantes}

    # 3) vecteur d'entrée dans le bon ordre + prédiction
    X = np.array([[vars_[f] for f in features]])
    X_std = pipeline.named_steps["scaler"].transform(X)
    proba = np.array([est.predict_proba(X_std)[0, 1]
                      for est in pipeline.named_steps["clf"].estimators_])

    ordre = np.argsort(-proba)[:top_k]
    top = [{"culture": classes[i],
            "culture_fr": CULTURE_FR[classes[i]],
            "culture_wolof": CULTURE_WO[classes[i]],
            "aptitude_pct": round(float(proba[i]) * 100, 1)} for i in ordre]

    # 4) message bilingue prêt à afficher
    l1 = top[0]
    msg_fr = (f"Pour {nom} ({ZONE_FR[zone]}), les cultures les plus adaptées "
              f"sont : " + ", ".join(
                  f"{c['culture_fr']} ({c['aptitude_pct']:.0f}%)" for c in top)
              + f". La plus recommandée est le {l1['culture_fr']}.")
    msg_wo = (f"Ci {nom}, mbay yi gën a baax ñooy : " + ", ".join(
                  f"{c['culture_wolof']}" for c in top)
              + f". Bi gën a baax mooy {l1['culture_wolof']}.")

    return {
        "localite": nom, "latitude": round(lat, 4), "longitude": round(lon, 4),
        "zone_agroecologique": ZONE_FR[zone],
        "recommandations": top,
        "message_francais": msg_fr,
        "message_wolof": msg_wo,
        "sources_donnees": sources,
    }


# -----------------------------------------------------------------------------
# 4. SCHÉMA DE L'OUTIL (pour le function calling de l'agent Qwen)
# -----------------------------------------------------------------------------
OUTIL_SCHEMA = {
    "type": "function",
    "function": {
        "name": "recommander_culture",
        "description": ("Recommande les cultures les mieux adaptées à une "
                        "localité du Sénégal, à partir des données de sol, "
                        "climat et végétation. Renvoie le top-3 avec le taux "
                        "d'aptitude, en français et en wolof."),
        "parameters": {
            "type": "object",
            "properties": {
                "localite": {"type": "string",
                             "description": "Nom d'une ville ou commune du "
                                            "Sénégal (ex : Kaolack, Ziguinchor)"},
                "top_k": {"type": "integer",
                          "description": "Nombre de cultures à recommander "
                                         "(défaut 3)", "default": 3},
            },
            "required": ["localite"],
        },
    },
}


if __name__ == "__main__":
    loc = sys.argv[1] if len(sys.argv) > 1 else "Kaolack"
    print(json.dumps(recommander_culture(loc), ensure_ascii=False, indent=2))
