"""
Service CRUD pour le référentiel `ZoneAgroecologique` (diagramme UML).

Les 6 zones sont un référentiel quasi statique (bounding-box + NDVI moyen).
La collection Firestore `zonesAgroecologiques` en est la représentation
persistée/consultable (conforme au diagramme), mais le calcul opérationnel
"quelle zone pour ce point ?" reste `agroeco_zones.zone_de()` — une fonction
pure, déterministe, sans dépendance réseau — pour ne pas fragiliser le
pipeline de prédiction déjà validé. L'id Firestore d'une zone est son code
interne (ex : "Bassin_Arachidier"), donc les deux restent toujours cohérents
sans synchronisation explicite.
"""

import logging

from app.services import agroeco_zones
from app.services.firestore_service import zones_agroecologiques_svc as zones_service

logger = logging.getLogger(__name__)


def zone_id_pour_point(latitude: float, longitude: float) -> str:
    """Code de la zone agroécologique (= id Firestore) pour un point donné."""
    return agroeco_zones.zone_de(latitude, longitude)


async def seed_si_vide() -> int:
    """
    Crée les 6 zones agroécologiques de référence si la collection est vide.
    Idempotent : appelé au démarrage de l'application (voir main.py).

    Returns:
        Nombre de zones créées (0 si déjà seedée).
    """
    existantes = await zones_service.lister(limite=1)
    if existantes:
        return 0

    nb_crees = 0
    for code, (lat_min, lat_max, lon_min, lon_max) in agroeco_zones.ZONES_BBOX.items():
        ndvi = agroeco_zones.NDVI_ZONE.get(code, {})
        doc = {
            "nom": agroeco_zones.ZONE_NOM_AFFICHAGE.get(code, code),
            "latMin": lat_min,
            "latMax": lat_max,
            "lonMin": lon_min,
            "lonMax": lon_max,
            "ndviMoyenAnnuel": ndvi.get("ndvi_moyen_annuel", 0.0),
            "ndviHivernage": ndvi.get("ndvi_hivernage", 0.0),
        }
        await zones_service.creer_avec_id(code, doc)
        nb_crees += 1

    logger.info(f"[OK] {nb_crees} zones agroécologiques seedées dans Firestore.")
    return nb_crees
