"""
Module IA 1 (v2) : collecte des variables sol / climat / végétation par
zone agroécologique du Sénégal.

Ce module factorise la logique de collecte présente dans le script fourni
`outil_recommander_culture.py` (racine du dépôt), pour qu'elle soit
réutilisable à la fois par :
  - `recommandation_service_v2` (génération pour un champ enregistré, à
    partir de sa latitude/longitude) ;
  - `agent_service` (outil `recommander_culture` appelé par l'agent
    conversationnel, à partir du nom d'une localité).

Principe : chaque localité du Sénégal est rattachée à l'une des 6 zones
agroécologiques (par ses coordonnées). Les moyennes de zone (issues du
dataset d'entraînement du modèle) constituent un socle toujours disponible ;
on les remplace par des mesures temps réel quand SoilGrids / NASA POWER
répondent.
"""

import logging
import time

import requests

from app.core.exceptions import SourceDonneesIndisponibleException

logger = logging.getLogger(__name__)

TIMEOUT_SOILGRIDS = 25
TIMEOUT_NASA_POWER = 40
TIMEOUT_GEOCODAGE = 20

# ──────────────────────────────────────────────────────────────────────────
# 1. TABLES DE RÉFÉRENCE PAR ZONE AGROÉCOLOGIQUE (issues du dataset
#    d'entraînement de modele_final.joblib — socle garanti, sans appel réseau)
# ──────────────────────────────────────────────────────────────────────────

NDVI_ZONE: dict[str, dict[str, float]] = {
    "Bassin_Arachidier":   {"ndvi_moyen_annuel": 0.329, "ndvi_hivernage": 0.438},
    "Casamance":           {"ndvi_moyen_annuel": 0.544, "ndvi_hivernage": 0.644},
    "Niayes":              {"ndvi_moyen_annuel": 0.303, "ndvi_hivernage": 0.369},
    "Senegal_Oriental":    {"ndvi_moyen_annuel": 0.437, "ndvi_hivernage": 0.612},
    "Vallee_du_Fleuve":    {"ndvi_moyen_annuel": 0.236, "ndvi_hivernage": 0.290},
    "Zone_Sylvopastorale": {"ndvi_moyen_annuel": 0.288, "ndvi_hivernage": 0.382},
}

# Moyennes P/K par zone (iSDA) — pas de source temps réel exploitée pour
# l'instant, on utilise systématiquement la moyenne de zone.
PK_ZONE: dict[str, dict[str, float]] = {
    "Bassin_Arachidier":   {"P_extractible_ppm": 7.19, "K_extractible_ppm": 71.3},
    "Casamance":           {"P_extractible_ppm": 6.87, "K_extractible_ppm": 53.9},
    "Niayes":              {"P_extractible_ppm": 9.50, "K_extractible_ppm": 88.0},
    "Senegal_Oriental":    {"P_extractible_ppm": 6.10, "K_extractible_ppm": 62.0},
    "Vallee_du_Fleuve":    {"P_extractible_ppm": 8.20, "K_extractible_ppm": 95.0},
    "Zone_Sylvopastorale": {"P_extractible_ppm": 5.80, "K_extractible_ppm": 58.0},
}

# Moyennes sol + climat par zone — repli complet si SoilGrids/NASA POWER
# sont indisponibles : la recommandation reste toujours possible.
SOL_CLIMAT_ZONE: dict[str, dict[str, float]] = {
    "Bassin_Arachidier": {
        "N_total_g_kg": 0.66, "pH_eau": 6.17, "clay_pct": 13.86, "sand_pct": 71.23,
        "silt_pct": 14.93, "carbone_org_g_kg": 7.51, "temperature_moy_C": 27.88,
        "temperature_max_mois_C": 31.41, "temperature_min_mois_C": 24.18,
        "humidite_moy_pct": 49.05, "pluie_annuelle_mm": 632.79, "pluie_hivernage_mm": 621.16,
    },
    "Casamance": {
        "N_total_g_kg": 1.44, "pH_eau": 5.61, "clay_pct": 24.55, "sand_pct": 49.16,
        "silt_pct": 26.29, "carbone_org_g_kg": 21.13, "temperature_moy_C": 27.23,
        "temperature_max_mois_C": 31.47, "temperature_min_mois_C": 23.45,
        "humidite_moy_pct": 60.49, "pluie_annuelle_mm": 1175.84, "pluie_hivernage_mm": 1148.24,
    },
    "Niayes": {
        "N_total_g_kg": 0.88, "pH_eau": 6.48, "clay_pct": 21.33, "sand_pct": 61.36,
        "silt_pct": 17.3, "carbone_org_g_kg": 9.44, "temperature_moy_C": 25.58,
        "temperature_max_mois_C": 28.2, "temperature_min_mois_C": 22.5,
        "humidite_moy_pct": 63.73, "pluie_annuelle_mm": 525.35, "pluie_hivernage_mm": 465.19,
    },
    "Senegal_Oriental": {
        "N_total_g_kg": 0.87, "pH_eau": 6.05, "clay_pct": 25.97, "sand_pct": 42.36,
        "silt_pct": 31.67, "carbone_org_g_kg": 11.08, "temperature_moy_C": 28.64,
        "temperature_max_mois_C": 34.46, "temperature_min_mois_C": 24.66,
        "humidite_moy_pct": 48.64, "pluie_annuelle_mm": 965.99, "pluie_hivernage_mm": 933.03,
    },
    "Vallee_du_Fleuve": {
        "N_total_g_kg": 0.48, "pH_eau": 6.87, "clay_pct": 15.23, "sand_pct": 70.87,
        "silt_pct": 13.9, "carbone_org_g_kg": 5.81, "temperature_moy_C": 28.39,
        "temperature_max_mois_C": 32.65, "temperature_min_mois_C": 22.97,
        "humidite_moy_pct": 40.62, "pluie_annuelle_mm": 395.6, "pluie_hivernage_mm": 380.05,
    },
    "Zone_Sylvopastorale": {
        "N_total_g_kg": 0.47, "pH_eau": 6.47, "clay_pct": 15.9, "sand_pct": 67.16,
        "silt_pct": 16.94, "carbone_org_g_kg": 6.01, "temperature_moy_C": 28.92,
        "temperature_max_mois_C": 33.74, "temperature_min_mois_C": 23.94,
        "humidite_moy_pct": 39.25, "pluie_annuelle_mm": 506.09, "pluie_hivernage_mm": 498.73,
    },
}

# Bornes (lat_min, lat_max, lon_min, lon_max) des 6 zones agroécologiques
ZONES_BBOX: dict[str, tuple[float, float, float, float]] = {
    "Vallee_du_Fleuve":    (15.50, 16.70, -16.60, -13.30),
    "Niayes":              (14.75, 15.35, -17.05, -16.65),
    "Bassin_Arachidier":   (13.70, 15.10, -16.90, -14.50),
    "Zone_Sylvopastorale": (14.60, 16.00, -15.50, -13.50),
    "Senegal_Oriental":    (12.60, 14.40, -13.50, -11.40),
    "Casamance":           (12.30, 13.15, -16.75, -13.60),
}

ZONE_NOM_AFFICHAGE: dict[str, str] = {
    "Vallee_du_Fleuve": "Vallée du Fleuve",
    "Niayes": "Niayes",
    "Bassin_Arachidier": "Bassin arachidier",
    "Zone_Sylvopastorale": "Zone sylvopastorale",
    "Senegal_Oriental": "Sénégal oriental",
    "Casamance": "Casamance",
}

# Propriétés SoilGrids interrogées : nom SoilGrids -> (clé locale, diviseur d'unité)
_PROPRIETES_SOILGRIDS: dict[str, tuple[str, float]] = {
    "nitrogen": ("N_total_g_kg", 100.0),
    "phh2o":    ("pH_eau", 10.0),
    "clay":     ("clay_pct", 10.0),
    "sand":     ("sand_pct", 10.0),
    "silt":     ("silt_pct", 10.0),
    "soc":      ("carbone_org_g_kg", 10.0),
}

_MOIS_NASA = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
              "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
_JOURS_PAR_MOIS_NASA = [31, 28.25, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
_MOIS_HIVERNAGE = ("JUN", "JUL", "AUG", "SEP", "OCT")


# ──────────────────────────────────────────────────────────────────────────
# 2. GÉOCODAGE (utilisé uniquement par l'agent conversationnel — le flux
#    "champ" connaît déjà sa latitude/longitude)
# ──────────────────────────────────────────────────────────────────────────

def geocoder_localite(localite: str) -> tuple[float, float, str] | None:
    """Nom de localité -> (latitude, longitude, nom résolu) via Open-Meteo."""
    try:
        r = requests.get(
            "https://geocoding-api.open-meteo.com/v1/search",
            params={"name": localite, "count": 1, "country": "SN", "language": "fr"},
            timeout=TIMEOUT_GEOCODAGE,
        )
        resultats = r.json().get("results")
        if not resultats:
            # Nouvel essai sans filtre pays (localités frontalières, orthographe)
            r = requests.get(
                "https://geocoding-api.open-meteo.com/v1/search",
                params={"name": localite, "count": 1},
                timeout=TIMEOUT_GEOCODAGE,
            )
            resultats = r.json().get("results")
        if not resultats:
            return None
        g = resultats[0]
        return g["latitude"], g["longitude"], g["name"]
    except requests.RequestException as e:
        logger.warning(f"Géocodage Open-Meteo indisponible pour « {localite} » : {e}")
        return None


# ──────────────────────────────────────────────────────────────────────────
# 3. ZONE AGROÉCOLOGIQUE + COLLECTE TEMPS RÉEL
# ──────────────────────────────────────────────────────────────────────────

def zone_de(latitude: float, longitude: float) -> str:
    """Rattache un point à sa zone agroécologique (par bounding-box, repli
    sur la zone dont le centre est le plus proche)."""
    for zone, (la0, la1, lo0, lo1) in ZONES_BBOX.items():
        if la0 <= latitude <= la1 and lo0 <= longitude <= lo1:
            return zone
    plus_proche, distance_min = None, float("inf")
    for zone, (la0, la1, lo0, lo1) in ZONES_BBOX.items():
        centre_lat, centre_lon = (la0 + la1) / 2, (lo0 + lo1) / 2
        distance = (latitude - centre_lat) ** 2 + (longitude - centre_lon) ** 2
        if distance < distance_min:
            plus_proche, distance_min = zone, distance
    return plus_proche


def collecter_sol_soilgrids(latitude: float, longitude: float) -> dict[str, float]:
    """
    SoilGrids (ISRIC) -> azote, pH, texture, carbone organique.
    Interrogation propriété par propriété (plus fiable que tout demander
    d'un coup), avec 2 tentatives par propriété. Renvoie ce qui a pu être
    récupéré (éventuellement partiel) — jamais d'exception levée ici, c'est
    à l'appelant de décider si le résultat est assez complet.
    """
    resultats: dict[str, float] = {}
    for propriete, (cle, diviseur) in _PROPRIETES_SOILGRIDS.items():
        for essai in range(2):
            try:
                r = requests.get(
                    "https://rest.isric.org/soilgrids/v2.0/properties/query",
                    params=[
                        ("lon", longitude), ("lat", latitude), ("value", "mean"),
                        ("property", propriete),
                        ("depth", "0-5cm"), ("depth", "5-15cm"),
                    ],
                    timeout=TIMEOUT_SOILGRIDS,
                )
                if r.status_code != 200:
                    time.sleep(2)
                    continue
                couche = r.json()["properties"]["layers"][0]
                valeurs = [
                    d["values"]["mean"] for d in couche["depths"]
                    if d["values"]["mean"] is not None
                ]
                if valeurs:
                    resultats[cle] = (sum(valeurs) / len(valeurs)) / diviseur
                break
            except (requests.RequestException, KeyError, IndexError):
                time.sleep(2)
    return resultats


def collecter_climat_nasa_power(latitude: float, longitude: float) -> dict[str, float]:
    """
    NASA POWER (climatologie long-terme) -> températures, humidité, pluies
    annuelle et d'hivernage. Lève SourceDonneesIndisponibleException si la
    source ne répond pas — à la différence de `collecter_sol_soilgrids`, car ici une
    seule requête suffit à tout récupérer.
    """
    try:
        r = requests.get(
            "https://power.larc.nasa.gov/api/temporal/climatology/point",
            params={
                "parameters": "T2M,PRECTOTCORR,RH2M", "community": "AG",
                "longitude": longitude, "latitude": latitude, "format": "JSON",
            },
            timeout=TIMEOUT_NASA_POWER,
        )
        r.raise_for_status()
        parametres = r.json()["properties"]["parameter"]

        pluie_mensuelle = parametres["PRECTOTCORR"]
        pluie_annuelle = sum(
            pluie_mensuelle[mois] * jours
            for mois, jours in zip(_MOIS_NASA, _JOURS_PAR_MOIS_NASA)
        )
        pluie_hivernage = sum(
            pluie_mensuelle[mois] * jours
            for mois, jours in zip(_MOIS_NASA, _JOURS_PAR_MOIS_NASA)
            if mois in _MOIS_HIVERNAGE
        )
        temperatures = parametres["T2M"]

        return {
            "temperature_moy_C": temperatures["ANN"],
            "temperature_max_mois_C": max(temperatures[m] for m in _MOIS_NASA),
            "temperature_min_mois_C": min(temperatures[m] for m in _MOIS_NASA),
            "humidite_moy_pct": parametres["RH2M"]["ANN"],
            "pluie_annuelle_mm": pluie_annuelle,
            "pluie_hivernage_mm": pluie_hivernage,
        }
    except requests.exceptions.Timeout:
        raise SourceDonneesIndisponibleException("NASA POWER ne répond pas (timeout).")
    except (requests.RequestException, KeyError) as e:
        raise SourceDonneesIndisponibleException(f"NASA POWER indisponible : {e}")


# Correspondance entre les clés internes (celles attendues, dans cet ordre
# exact, par modele_final.joblib) et les attributs `AnalyseParcelle` du
# diagramme UML. Les clés internes ne doivent JAMAIS changer (elles doivent
# rester identiques à `modele["features"]`) ; ce mapping isole ce contrat du
# nommage du modèle de persistance.
CLE_ML_VERS_ANALYSE_PARCELLE: dict[str, str] = {
    "N_total_g_kg": "nTotal_g_kg",
    "P_extractible_ppm": "pExtractible_ppm",
    "K_extractible_ppm": "kExtractible_ppm",
    "pH_eau": "phEau",
    "clay_pct": "argile_pct",
    "sand_pct": "sable_pct",
    "silt_pct": "limon_pct",
    "carbone_org_g_kg": "carboneOrganique",
    "temperature_moy_C": "temperatureMoy",
    "temperature_max_mois_C": "temperatureMaxMois",
    "temperature_min_mois_C": "temperatureMinMois",
    "humidite_moy_pct": "humiditeMoy",
    "pluie_annuelle_mm": "pluieAnnuelle",
    "pluie_hivernage_mm": "pluieHivernage",
    "ndvi_moyen_annuel": "ndviMoyenAnnuel",
    "ndvi_hivernage": "ndviHivernage",
}


def vers_champs_analyse_parcelle(variables: dict[str, float]) -> dict[str, float]:
    """Renomme les 16 variables internes vers les attributs `AnalyseParcelle`."""
    return {
        CLE_ML_VERS_ANALYSE_PARCELLE[cle]: valeur
        for cle, valeur in variables.items()
        if cle in CLE_ML_VERS_ANALYSE_PARCELLE
    }


def resumer_sources(sources: dict[str, str]) -> str:
    """Condense le dict `sources` (voir `assembler_variables`) en une chaîne
    lisible pour `AnalyseParcelle.sourceDonnees`."""
    return ", ".join(f"{groupe}={origine}" for groupe, origine in sources.items())


def assembler_variables(latitude: float, longitude: float) -> tuple[dict[str, float], str, dict[str, str]]:
    """
    Assemble les 16 variables attendues par `modele_final.joblib` pour un
    point (latitude, longitude) donné.

    Stratégie : on part des moyennes de la zone agroécologique (toujours
    disponibles), puis on les remplace par des mesures temps réel quand
    SoilGrids / NASA POWER répondent correctement. P, K et NDVI n'ont pas
    de source temps réel exploitée : ce sont systématiquement des moyennes
    de zone (issues d'iSDA / MODIS sur le dataset d'entraînement).

    Returns:
        (variables, zone_agroecologique, sources) où `sources` indique
        l'origine ("temps réel" ou "moyenne de zone") de chaque groupe de
        variables, pour traçabilité (affichée à l'utilisateur, utile pour
        le mémoire).
    """
    zone = zone_de(latitude, longitude)

    variables: dict[str, float] = {}
    variables.update(SOL_CLIMAT_ZONE.get(zone, {}))
    variables.update(PK_ZONE.get(zone, {}))
    variables.update(NDVI_ZONE.get(zone, {}))

    sources = {
        "sol": "moyenne de zone", "climat": "moyenne de zone",
        "phosphore_potassium": "moyenne de zone", "ndvi": "moyenne de zone",
    }

    try:
        sol = collecter_sol_soilgrids(latitude, longitude)
        if len(sol) >= 4:  # assez de variables sol récupérées pour faire confiance à la mesure
            variables.update(sol)
            sources["sol"] = "SoilGrids (temps réel)"
    except Exception as e:
        logger.warning(f"SoilGrids indisponible ({e}) — repli sur la moyenne de zone.")

    try:
        climat = collecter_climat_nasa_power(latitude, longitude)
        variables.update(climat)
        sources["climat"] = "NASA POWER (temps réel)"
    except SourceDonneesIndisponibleException as e:
        logger.warning(f"NASA POWER indisponible ({e}) — repli sur la moyenne de zone.")

    return variables, zone, sources
