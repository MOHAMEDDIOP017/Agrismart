"""
Seed du référentiel `Culture` (diagramme UML) — les 8 cultures du modèle
multi-label, avec leur nom wolof (`Culture.nomWolof`).

Comme pour `zone_service.py`, le seed est idempotent (ne s'exécute que si la
collection est vide) et se déclenche au démarrage de l'application. Les
plages agronomiques (phOptimal, nOptimal...) sont des valeurs indicatives
d'usage courant en agronomie sénégalaise (ISRA/FAO), au même niveau de
précision que les fiches techniques déjà présentes dans
`fiches_cultures.py` — elles ne proviennent PAS du dataset
d'entraînement du modèle (qui ne porte que sur les 16 variables sol/climat/
NDVI, pas sur ce référentiel de compatibilité).
"""

import logging

from app.services.firestore_service import cultures_service
from app.services.recommandation_service_v2 import (
    NOM_AFFICHAGE_PAR_CODE,
    NOM_WOLOF_PAR_CODE,
    RENDEMENT_PAR_CULTURE_V2,
    PRIX_MARCHE_PAR_CULTURE_V2,
)

logger = logging.getLogger(__name__)

# Complément agronomique par code de classe (non couvert par les dicts de
# recommandation_service_v2, qui portent sur les conseils/périodes/engrais).
_REFERENTIEL_PAR_CODE: dict[str, dict] = {
    "arachide": dict(variete="Locale / 58-63", cycleMaturation=100,
                      phOptimal=6.0, nOptimal=20, pOptimal=20, kOptimal=30,
                      tempMin=20, tempMax=35, humiditeMin=40, humiditeMax=70,
                      besoinsHydriques="500-600 mm/cycle"),
    "mais": dict(variete="Locale", cycleMaturation=90,
                 phOptimal=6.0, nOptimal=80, pOptimal=40, kOptimal=40,
                 tempMin=18, tempMax=35, humiditeMin=50, humiditeMax=80,
                 besoinsHydriques="500-800 mm/cycle"),
    "manioc": dict(variete="Locale", cycleMaturation=300,
                    phOptimal=5.5, nOptimal=40, pOptimal=20, kOptimal=60,
                    tempMin=20, tempMax=35, humiditeMin=50, humiditeMax=85,
                    besoinsHydriques="700-1000 mm/cycle"),
    "mil": dict(variete="Souna / Sanio", cycleMaturation=90,
                phOptimal=5.5, nOptimal=30, pOptimal=15, kOptimal=20,
                tempMin=20, tempMax=40, humiditeMin=30, humiditeMax=60,
                besoinsHydriques="350-500 mm/cycle"),
    "niebe": dict(variete="Locale / Mouride", cycleMaturation=70,
                  phOptimal=6.0, nOptimal=20, pOptimal=20, kOptimal=20,
                  tempMin=20, tempMax=35, humiditeMin=40, humiditeMax=70,
                  besoinsHydriques="400-500 mm/cycle"),
    "riz": dict(variete="Sahel 108 / Nerica", cycleMaturation=120,
                phOptimal=5.5, nOptimal=100, pOptimal=40, kOptimal=40,
                tempMin=20, tempMax=35, humiditeMin=70, humiditeMax=100,
                besoinsHydriques="1000-1500 mm/cycle (irrigué)"),
    "sorgho": dict(variete="Locale", cycleMaturation=100,
                   phOptimal=5.5, nOptimal=40, pOptimal=20, kOptimal=20,
                   tempMin=20, tempMax=40, humiditeMin=35, humiditeMax=65,
                   besoinsHydriques="400-600 mm/cycle"),
    "tomate": dict(variete="Xina / Mongal", cycleMaturation=90,
                   phOptimal=6.2, nOptimal=100, pOptimal=60, kOptimal=80,
                   tempMin=18, tempMax=30, humiditeMin=50, humiditeMax=70,
                   besoinsHydriques="600-800 mm/cycle"),
}


async def seed_si_vide() -> int:
    """
    Crée les 8 cultures de référence (avec nomWolof) si la collection
    `cultures` est vide. Idempotent : appelé au démarrage de l'application.

    Note : ne touche pas une collection déjà peuplée (ex : un ancien
    référentiel avec "Oignon" laissé par une itération précédente) — dans ce
    cas, seul un ré-alignement manuel via l'API admin des cultures permet de
    retirer "Oignon" / vérifier la présence de "Manioc".

    Returns:
        Nombre de cultures créées (0 si déjà seedée).
    """
    existantes = await cultures_service.lister(limite=1)
    if existantes:
        return 0

    nb_crees = 0
    for code, nom_fr in NOM_AFFICHAGE_PAR_CODE.items():
        champs_agro = _REFERENTIEL_PAR_CODE[code]
        doc = {
            "nom": nom_fr,
            "nomWolof": NOM_WOLOF_PAR_CODE[code],
            "rendementMoyen": RENDEMENT_PAR_CULTURE_V2.get(nom_fr, 1.0),
            "prixMoyenMarche": PRIX_MARCHE_PAR_CULTURE_V2.get(nom_fr, 200),
            **champs_agro,
        }
        await cultures_service.creer_avec_id(code, doc)
        nb_crees += 1

    logger.info(f"[OK] {nb_crees} cultures seedées dans Firestore (référentiel 8 cultures).")
    return nb_crees
