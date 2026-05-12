"""Router FastAPI — Données météorologiques (OpenWeatherMap)."""

import logging
from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.core.dependencies import get_utilisateur_courant
from app.core.exceptions import APIMeteoIndisponibleException, agrismart_exception_handler
from app.services.firestore_service import champs_service
from app.services.meteo_service import meteo_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/meteo", tags=["Météo"])


@router.get(
    "/actuelle/{champ_id}",
    summary="Météo actuelle d'un champ",
    description=(
        "Retourne les données météorologiques actuelles pour les coordonnées GPS d'un champ "
        "via l'API OpenWeatherMap."
    ),
    status_code=status.HTTP_200_OK,
)
async def meteo_actuelle(
    champ_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    """Récupère la météo actuelle basée sur la position GPS du champ."""
    champ = await champs_service.lire(champ_id)
    if champ is None:
        raise HTTPException(status_code=404, detail=f"Champ '{champ_id}' introuvable.")

    try:
        donnees = await meteo_service.get_donnees_actuelles(
            champ["latitude"], champ["longitude"]
        )
        return {"champId": champ_id, "meteo": donnees}
    except APIMeteoIndisponibleException as e:
        raise agrismart_exception_handler(e)


@router.get(
    "/previsions/{champ_id}",
    summary="Prévisions météo sur N jours",
    description=(
        "Retourne les prévisions météo pour les 7 prochains jours "
        "(limité à 5 jours avec l'API gratuite OpenWeatherMap)."
    ),
    status_code=status.HTTP_200_OK,
)
async def previsions_meteo(
    champ_id: str,
    jours: int = Query(default=7, ge=1, le=7, description="Nombre de jours de prévision"),
    courant: dict = Depends(get_utilisateur_courant),
):
    champ = await champs_service.lire(champ_id)
    if champ is None:
        raise HTTPException(status_code=404, detail=f"Champ '{champ_id}' introuvable.")

    try:
        previsions = await meteo_service.get_previsions_jours(
            champ["latitude"], champ["longitude"], jours=jours
        )
        return {
            "champId": champ_id,
            "jours": jours,
            "previsions": previsions,
            "total_tranches": len(previsions),
        }
    except APIMeteoIndisponibleException as e:
        raise agrismart_exception_handler(e)
