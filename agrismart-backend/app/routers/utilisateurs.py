"""Router FastAPI — Gestion des utilisateurs."""

import logging
from fastapi import APIRouter, Depends, HTTPException, status

from app.core.dependencies import get_utilisateur_courant, require_admin
from app.core.exceptions import agrismart_exception_handler, AgriSmartException
from app.models.utilisateur import UtilisateurUpdate
from app.models.enums import RoleUtilisateur
from app.services.auth_service import auth_service
from app.services.firestore_service import utilisateurs_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/utilisateurs", tags=["Utilisateurs"])


@router.post(
    "",
    summary="Créer un utilisateur",
    description="Crée un utilisateur Firebase Auth + Custom Claims + Firestore (admin uniquement).",
    status_code=status.HTTP_201_CREATED,
)
async def creer_utilisateur(
    body: dict,
    admin: dict = Depends(require_admin()),
):
    """Création complète : Firebase Auth + rôle Custom Claim + document Firestore."""
    champs_requis = ["email", "motDePasse", "nom", "prenom"]
    for champ in champs_requis:
        if not body.get(champ):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Champ requis manquant : {champ}",
            )
    try:
        return await auth_service.creer_utilisateur_complet(body)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Erreur création utilisateur : {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la création de l'utilisateur.")


@router.get(
    "",
    summary="Lister tous les utilisateurs",
    description="Retourne la liste de tous les utilisateurs (admin uniquement).",
    status_code=status.HTTP_200_OK,
)
async def lister_utilisateurs(
    limite: int = 100,
    admin: dict = Depends(require_admin()),
):
    """Liste tous les utilisateurs de l'application."""
    utilisateurs = await auth_service.lister_utilisateurs(limite=limite)
    return {"utilisateurs": utilisateurs, "total": len(utilisateurs)}


@router.get(
    "/experts",
    summary="Lister les experts disponibles",
    description="Retourne la liste des experts actifs. Accessible à tous les utilisateurs connectés.",
    status_code=status.HTTP_200_OK,
)
async def lister_experts(
    courant: dict = Depends(get_utilisateur_courant),
):
    """Permet à un agriculteur de voir les experts disponibles pour partager un diagnostic."""
    experts = await utilisateurs_service.lister(
        filtres=[("role", "==", RoleUtilisateur.EXPERT.value)],
        limite=50,
    )
    return {
        "experts": [
            {
                "id": e.get("id") or e.get("uid", ""),
                "nom": e.get("nom", ""),
                "prenom": e.get("prenom", ""),
                "specialite": e.get("specialite", "Agronomie générale"),
                "zone_geographique": e.get("zone_geographique", "Sénégal"),
                "actif": e.get("actif", True),
            }
            for e in experts
        ],
        "total": len(experts),
    }


@router.get(
    "/{utilisateur_id}",
    summary="Obtenir un utilisateur",
    description="Retourne le profil d'un utilisateur par son ID.",
    status_code=status.HTTP_200_OK,
)
async def obtenir_utilisateur(
    utilisateur_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    """
    Un utilisateur peut voir son propre profil.
    Un admin peut voir n'importe quel profil.
    """
    uid_courant = courant["uid"]
    role = courant.get("role", "")

    # Un non-admin ne peut accéder qu'à son propre profil
    if role != "ADMIN" and uid_courant != utilisateur_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : vous ne pouvez consulter que votre propre profil.",
        )

    try:
        return await auth_service.obtenir_utilisateur(utilisateur_id)
    except AgriSmartException as e:
        raise agrismart_exception_handler(e)


@router.put(
    "/{utilisateur_id}",
    summary="Mettre à jour un utilisateur",
    description="Met à jour les informations d'un utilisateur.",
    status_code=status.HTTP_200_OK,
)
async def mettre_a_jour_utilisateur(
    utilisateur_id: str,
    donnees: UtilisateurUpdate,
    courant: dict = Depends(get_utilisateur_courant),
):
    """L'utilisateur ne peut modifier que son propre profil (sauf admin)."""
    uid_courant = courant["uid"]
    role = courant.get("role", "")

    if role != "ADMIN" and uid_courant != utilisateur_id:
        raise HTTPException(status_code=403, detail="Modification non autorisée.")

    try:
        return await auth_service.mettre_a_jour_profil(
            utilisateur_id, donnees.model_dump(exclude_none=True)
        )
    except AgriSmartException as e:
        raise agrismart_exception_handler(e)


@router.delete(
    "/{utilisateur_id}",
    summary="Supprimer un utilisateur",
    description="Supprime un utilisateur de Firebase Auth et Firestore (admin uniquement).",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def supprimer_utilisateur(
    utilisateur_id: str,
    admin: dict = Depends(require_admin()),
):
    """Suppression définitive — irréversible."""
    try:
        await auth_service.supprimer_utilisateur(utilisateur_id)
    except AgriSmartException as e:
        raise agrismart_exception_handler(e)


@router.patch(
    "/{utilisateur_id}/suspendre",
    summary="Suspendre un utilisateur",
    description="Désactive le compte d'un utilisateur et révoque ses sessions (admin uniquement).",
    status_code=status.HTTP_200_OK,
)
async def suspendre_utilisateur(
    utilisateur_id: str,
    admin: dict = Depends(require_admin()),
):
    """Suspend un utilisateur sans le supprimer définitivement."""
    try:
        utilisateur = await auth_service.suspendre_utilisateur(utilisateur_id)
        return {"message": "Utilisateur suspendu.", "utilisateur": utilisateur}
    except AgriSmartException as e:
        raise agrismart_exception_handler(e)


@router.patch(
    "/{utilisateur_id}/role",
    summary="Changer le rôle d'un utilisateur",
    description="Assigne un nouveau rôle Firebase Custom Claims + Firestore (admin uniquement).",
    status_code=status.HTTP_200_OK,
)
async def changer_role(
    utilisateur_id: str,
    body: dict,
    admin: dict = Depends(require_admin()),
):
    nouveau_role_str = body.get("role", "AGRICULTEUR").upper()
    try:
        role_enum = RoleUtilisateur(nouveau_role_str)
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Rôle invalide : {nouveau_role_str}")
    await auth_service.definir_role(utilisateur_id, role_enum)
    return {"message": f"Rôle '{nouveau_role_str}' assigné.", "utilisateurId": utilisateur_id}


@router.patch(
    "/me/fcm-token",
    summary="Enregistrer le token FCM de l'appareil",
    description="Sauvegarde le token FCM de l'utilisateur connecté pour les notifications push.",
    status_code=status.HTTP_200_OK,
)
async def enregistrer_fcm_token(
    body: dict,
    courant: dict = Depends(get_utilisateur_courant),
):
    uid = courant["uid"]
    fcm_token = body.get("fcmToken")
    if fcm_token:
        try:
            await utilisateurs_service.mettre_a_jour(uid, {"fcmToken": fcm_token})
        except Exception as e:
            logger.warning(f"FCM token non enregistré pour {uid} : {e}")
    return {"message": "Token FCM enregistré."}
