"""Router FastAPI — Endpoints réservés aux administrateurs."""

import asyncio
import logging
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, HTTPException, status

from app.core.dependencies import require_admin
from app.services.firestore_service import (
    utilisateurs_service, champs_service,
    recommandations_svc, interventions_svc,
    conseils_svc,
)
from app.services.historique_service import historique_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/admin", tags=["Administration"])


@router.get(
    "/statistiques-globales",
    summary="Statistiques globales de la plateforme",
    description=(
        "Retourne des métriques clés : nombre d'utilisateurs, champs, diagnostics, "
        "recommandations générées, images analysées, etc."
    ),
    status_code=status.HTTP_200_OK,
)
async def statistiques_globales(
    admin: dict = Depends(require_admin()),
):
    """Agrège les compteurs des principales collections Firestore."""

    (
        nb_utilisateurs_actifs,
        nb_champs,
        nb_recommandations,
        nb_interventions,
        nb_conseils,
        agriculteurs,
        experts,
        admins,
    ) = await asyncio.gather(
        utilisateurs_service.compter(filtres=[("actif", "==", True)]),
        champs_service.compter(),
        recommandations_svc.compter(),
        interventions_svc.compter(),
        conseils_svc.compter(),
        utilisateurs_service.compter(filtres=[("role", "==", "AGRICULTEUR")]),
        utilisateurs_service.compter(filtres=[("role", "==", "EXPERT")]),
        utilisateurs_service.compter(filtres=[("role", "==", "ADMIN")]),
    )

    return {
        "date_rapport": datetime.now(timezone.utc).isoformat(),
        "utilisateurs": {
            "total": nb_utilisateurs_actifs,
            "agriculteurs": agriculteurs,
            "experts": experts,
            "admins": admins,
        },
        "champs": nb_champs,
        "ia_module1": {
            "total_recommandations": nb_recommandations,
        },
        "experts": {
            "interventions_planifiees": nb_interventions,
            "conseils_envoyes": nb_conseils,
        },
    }


@router.get(
    "/historique-systeme",
    summary="Historique global des activités",
    description="Retourne l'historique de toutes les actions effectuées sur la plateforme.",
    status_code=status.HTTP_200_OK,
)
async def historique_systeme(
    limite: int = 100,
    admin: dict = Depends(require_admin()),
):
    historique = await historique_service.obtenir_historique_global(limite=limite)
    return {"historique": historique, "total": len(historique)}


@router.post(
    "/assigner-expert",
    summary="Assigner un expert à une intervention",
    description="L'admin assigne un expert à une intervention existante.",
    status_code=status.HTTP_200_OK,
)
async def assigner_expert(
    intervention_id: str,
    expert_id: str,
    admin: dict = Depends(require_admin()),
):
    """Réassigne une intervention à un autre expert."""
    intervention = await interventions_svc.lire(intervention_id)
    if intervention is None:
        raise HTTPException(status_code=404, detail="Intervention introuvable.")

    await interventions_svc.mettre_a_jour(intervention_id, {"expertId": expert_id})
    return {
        "message": f"Expert {expert_id} assigné à l'intervention {intervention_id}.",
        "interventionId": intervention_id,
        "expertId": expert_id,
    }
