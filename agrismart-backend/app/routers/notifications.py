"""Router FastAPI — Notifications push (FCM)."""

import logging
from fastapi import APIRouter, Depends, HTTPException, status

from app.core.dependencies import get_utilisateur_courant, require_admin
from app.models.notification import EnvoiNotificationRequest
from app.services.firestore_service import notifications_svc
from app.services.notification_service import notification_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get(
    "/utilisateur/{utilisateur_id}",
    summary="Notifications d'un utilisateur",
    description="Retourne toutes les notifications d'un utilisateur (lues et non lues).",
    status_code=status.HTTP_200_OK,
)
async def notifications_utilisateur(
    utilisateur_id: str,
    limite: int = 50,
    courant: dict = Depends(get_utilisateur_courant),
):
    uid = courant["uid"]
    if courant.get("role") != "ADMIN" and uid != utilisateur_id:
        raise HTTPException(status_code=403, detail="Accès refusé.")

    notifs = await notifications_svc.lister(
        filtres=[("destinataireId", "==", utilisateur_id)],
        ordre_par="dateEnvoi",
        decroissant=True,
        limite=limite,
    )
    return {"notifications": notifs, "total": len(notifs)}


@router.get(
    "/utilisateur/{utilisateur_id}/non-lues",
    summary="Notifications non lues",
    description="Retourne uniquement les notifications non lues d'un utilisateur.",
    status_code=status.HTTP_200_OK,
)
async def notifications_non_lues(
    utilisateur_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    uid = courant["uid"]
    if courant.get("role") != "ADMIN" and uid != utilisateur_id:
        raise HTTPException(status_code=403, detail="Accès refusé.")

    notifs = await notification_service.obtenir_non_lues(utilisateur_id)
    return {"notifications": notifs, "total": len(notifs)}


@router.post(
    "/envoyer",
    summary="Envoyer une notification (interne)",
    description="Envoie une notification push manuelle (admin uniquement).",
    status_code=status.HTTP_201_CREATED,
)
async def envoyer_notification(
    corps: EnvoiNotificationRequest,
    admin: dict = Depends(require_admin()),
):
    notif_id = await notification_service.envoyer_notification(
        destinataire_id=corps.destinataireId,
        type_notif=corps.type,
        titre=corps.titre,
        corps=corps.corps,
        reference_id=corps.referenceId,
        urgent=corps.urgent,
    )
    return {"message": "Notification envoyée.", "notifId": notif_id}


@router.patch(
    "/{notif_id}/marquer-lue",
    summary="Marquer une notification comme lue",
    status_code=status.HTTP_200_OK,
)
async def marquer_notification_lue(
    notif_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    notif = await notifications_svc.lire(notif_id)
    if notif is None:
        raise HTTPException(status_code=404, detail="Notification introuvable.")

    uid = courant["uid"]
    if notif.get("destinataireId") != uid and courant.get("role") != "ADMIN":
        raise HTTPException(status_code=403, detail="Non autorisé.")

    await notification_service.marquer_lue(notif_id, uid)
    return {"message": "Notification marquée comme lue."}
