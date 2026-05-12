"""Router FastAPI — Conseils envoyés par les experts."""

import logging
from fastapi import APIRouter, Depends, HTTPException, status

from app.core.dependencies import get_utilisateur_courant, require_expert
from app.models.conseil import ConseilCreate
from app.models.enums import TypeNotification
from app.services.firestore_service import conseils_svc
from app.services.notification_service import notification_service
from app.utils.helpers import maintenant_utc

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/conseils", tags=["Conseils d'experts"])


@router.get(
    "/agriculteur/{agriculteur_id}",
    summary="Conseils reçus par un agriculteur",
    description="Retourne tous les conseils envoyés à un agriculteur.",
    status_code=status.HTTP_200_OK,
)
async def conseils_agriculteur(
    agriculteur_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    uid = courant["uid"]
    if courant.get("role") not in ["ADMIN", "EXPERT"] and uid != agriculteur_id:
        raise HTTPException(status_code=403, detail="Accès refusé.")

    conseils = await conseils_svc.lister(
        filtres=[("agriculteurId", "==", agriculteur_id)],
        ordre_par="dateEnvoi",
        decroissant=True,
        limite=50,
    )
    return {"conseils": conseils, "total": len(conseils)}


@router.get(
    "/expert/{expert_id}",
    summary="Conseils envoyés par un expert",
    status_code=status.HTTP_200_OK,
)
async def conseils_expert(
    expert_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    uid = courant["uid"]
    if courant.get("role") != "ADMIN" and uid != expert_id:
        raise HTTPException(status_code=403, detail="Accès refusé.")

    conseils = await conseils_svc.lister(
        filtres=[("expertId", "==", expert_id)],
        ordre_par="dateEnvoi",
        decroissant=True,
        limite=100,
    )
    return {"conseils": conseils, "total": len(conseils)}


@router.post(
    "",
    summary="Envoyer un conseil (Expert)",
    description="Un expert envoie un conseil agricole à un agriculteur.",
    status_code=status.HTTP_201_CREATED,
)
async def envoyer_conseil(
    donnees: ConseilCreate,
    expert: dict = Depends(require_expert()),
):
    doc = donnees.model_dump()
    doc["expertId"] = expert["uid"]
    doc["dateEnvoi"] = maintenant_utc()
    doc["lu"] = False

    conseil_id = await conseils_svc.creer(doc)

    # Notification push à l'agriculteur
    try:
        icone = "🚨" if donnees.urgent else "💡"
        await notification_service.envoyer_notification(
            destinataire_id=donnees.agriculteurId,
            type_notif=TypeNotification.CONSEIL_EXPERT,
            titre=f"{icone} Conseil de votre expert : {donnees.titre}",
            corps=donnees.contenu[:150] + "..." if len(donnees.contenu) > 150 else donnees.contenu,
            reference_id=conseil_id,
            urgent=donnees.urgent,
        )
    except Exception as e:
        logger.warning(f"Notification conseil non envoyée : {e}")

    return {"id": conseil_id, **doc}


@router.patch(
    "/{conseil_id}/marquer-lu",
    summary="Marquer un conseil comme lu",
    description="L'agriculteur marque un conseil comme lu.",
    status_code=status.HTTP_200_OK,
)
async def marquer_conseil_lu(
    conseil_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    conseil = await conseils_svc.lire(conseil_id)
    if conseil is None:
        raise HTTPException(status_code=404, detail="Conseil introuvable.")

    uid = courant["uid"]
    if conseil.get("agriculteurId") != uid and courant.get("role") != "ADMIN":
        raise HTTPException(status_code=403, detail="Non autorisé.")

    await conseils_svc.mettre_a_jour(conseil_id, {"lu": True, "dateLecture": maintenant_utc()})
    return {"message": "Conseil marqué comme lu."}


@router.delete(
    "/{conseil_id}",
    summary="Supprimer un conseil",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def supprimer_conseil(
    conseil_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    conseil = await conseils_svc.lire(conseil_id)
    if conseil is None:
        raise HTTPException(status_code=404, detail="Conseil introuvable.")

    uid = courant["uid"]
    role = courant.get("role", "")
    if role != "ADMIN" and conseil.get("expertId") != uid:
        raise HTTPException(status_code=403, detail="Suppression non autorisée.")

    await conseils_svc.supprimer(conseil_id)
