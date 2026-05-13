"""Router FastAPI — Interventions d'experts sur les champs."""

import logging
from fastapi import APIRouter, Depends, HTTPException, status

from app.core.dependencies import get_utilisateur_courant, require_expert
from app.models.intervention import InterventionCreate, InterventionUpdate
from app.models.enums import StatutIntervention, TypeNotification
from app.services.firestore_service import interventions_svc, champs_service
from app.services.notification_service import notification_service
from app.utils.helpers import maintenant_utc

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/interventions", tags=["Interventions d'experts"])


@router.get(
    "/expert/{expert_id}",
    summary="Interventions d'un expert",
    description="Retourne toutes les interventions planifiées ou réalisées par un expert.",
    status_code=status.HTTP_200_OK,
)
async def interventions_expert(
    expert_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    uid = courant["uid"]
    role = courant.get("role", "")
    if role != "ADMIN" and uid != expert_id:
        raise HTTPException(status_code=403, detail="Accès refusé.")

    interventions = await interventions_svc.lister(
        filtres=[("expertId", "==", expert_id)],
        ordre_par="dateInterventionPrevue",
        decroissant=True,
        limite=50,
    )
    return {"interventions": interventions, "total": len(interventions)}


@router.get(
    "/champ/{champ_id}",
    summary="Interventions sur un champ",
    description="Retourne toutes les interventions planifiées pour un champ donné.",
    status_code=status.HTTP_200_OK,
)
async def interventions_champ(
    champ_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    champ = await champs_service.lire(champ_id)
    if champ is None:
        raise HTTPException(status_code=404, detail="Champ introuvable.")

    uid = courant["uid"]
    role = courant.get("role", "")
    if role not in ["ADMIN", "EXPERT"] and champ.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Accès refusé.")

    interventions = await interventions_svc.lister(
        filtres=[("champId", "==", champ_id)],
        ordre_par="dateInterventionPrevue",
        decroissant=True,
        limite=50,
    )
    return {"interventions": interventions}


@router.post(
    "",
    summary="Planifier une intervention",
    description="Planifie une nouvelle intervention d'expert sur un champ.",
    status_code=status.HTTP_201_CREATED,
)
async def planifier_intervention(
    donnees: InterventionCreate,
    expert: dict = Depends(require_expert()),
):
    doc = donnees.model_dump()
    doc["expertId"] = expert["uid"]  # Forcé depuis le token, ne pas faire confiance au body
    intervention_id = await interventions_svc.creer(doc)

    # Notification à l'agriculteur
    try:
        await notification_service.envoyer_notification(
            destinataire_id=donnees.agriculteurId,
            type_notif=TypeNotification.INTERVENTION_PLANIFIEE,
            titre="Intervention planifiée sur votre champ",
            corps=f"Une intervention '{donnees.typeIntervention.value}' est prévue le {donnees.dateInterventionPrevue.strftime('%d/%m/%Y')}.",
            reference_id=intervention_id,
        )
    except Exception as e:
        logger.warning(f"Notification intervention non envoyée : {e}")

    return {"id": intervention_id, **doc}


@router.put(
    "/{intervention_id}",
    summary="Mettre à jour une intervention",
    status_code=status.HTTP_200_OK,
)
async def mettre_a_jour_intervention(
    intervention_id: str,
    donnees: InterventionUpdate,
    courant: dict = Depends(get_utilisateur_courant),
):
    intervention = await interventions_svc.lire(intervention_id)
    if intervention is None:
        raise HTTPException(status_code=404, detail="Intervention introuvable.")

    uid = courant["uid"]
    role = courant.get("role", "")
    if role != "ADMIN" and intervention.get("expertId") != uid:
        raise HTTPException(status_code=403, detail="Modification non autorisée.")

    await interventions_svc.mettre_a_jour(intervention_id, donnees.model_dump(exclude_none=True))
    return await interventions_svc.lire(intervention_id)


@router.patch(
    "/{intervention_id}/realiser",
    summary="Marquer une intervention comme réalisée",
    description="L'expert clôture l'intervention en fournissant un rapport.",
    status_code=status.HTTP_200_OK,
)
async def realiser_intervention(
    intervention_id: str,
    rapport: str,
    expert: dict = Depends(require_expert()),
):
    intervention = await interventions_svc.lire(intervention_id)
    if intervention is None:
        raise HTTPException(status_code=404, detail="Intervention introuvable.")

    if intervention.get("expertId") != expert["uid"] and expert.get("role") != "ADMIN":
        raise HTTPException(status_code=403, detail="Non autorisé.")

    await interventions_svc.mettre_a_jour(intervention_id, {
        "statut": StatutIntervention.REALISEE.value,
        "rapportIntervention": rapport,
        "dateRealisation": maintenant_utc(),
    })
    return {"message": "Intervention marquée comme réalisée.", "interventionId": intervention_id}


@router.delete(
    "/{intervention_id}",
    summary="Annuler une intervention",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def annuler_intervention(
    intervention_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    intervention = await interventions_svc.lire(intervention_id)
    if intervention is None:
        raise HTTPException(status_code=404, detail="Intervention introuvable.")

    uid = courant["uid"]
    if courant.get("role") != "ADMIN" and intervention.get("expertId") != uid:
        raise HTTPException(status_code=403, detail="Annulation non autorisée.")

    await interventions_svc.mettre_a_jour(
        intervention_id, {"statut": StatutIntervention.ANNULEE.value}
    )
