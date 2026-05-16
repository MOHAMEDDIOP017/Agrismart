"""Router FastAPI — Authentification Firebase."""

import logging
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
import firebase_admin.auth as firebase_auth

from app.core.dependencies import get_utilisateur_courant
from app.core.exceptions import koobalatec_exception_handler, AuthentificationEchoueeException
from app.services.auth_service import auth_service
from app.services.firestore_service import utilisateurs_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Authentification"])


@router.post(
    "/verify-token",
    summary="Vérifier un token Firebase",
    description=(
        "Vérifie la validité d'un idToken Firebase. "
        "Crée le profil utilisateur en Firestore s'il n'existe pas encore (premier login). "
        "Retourne le profil complet de l'utilisateur."
    ),
    status_code=status.HTTP_200_OK,
)
async def verify_token(
    utilisateur: dict = Depends(get_utilisateur_courant),
):
    """
    Endpoint appelé après chaque connexion Firebase côté Flutter.
    Le token Bearer est passé dans l'en-tête Authorization.
    """
    try:
        profil = await auth_service.verifier_ou_creer_utilisateur(utilisateur)
        return {"success": True, "utilisateur": profil}
    except Exception as e:
        logger.error(f"Erreur verify-token : {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post(
    "/register-agriculteur",
    summary="Inscription publique d'un agriculteur",
    description=(
        "Endpoint public (sans auth admin). "
        "Reçoit un token Firebase d'un nouvel utilisateur et crée son profil AGRICULTEUR : "
        "pose le Custom Claim 'role=AGRICULTEUR' sur Firebase, crée le document Firestore."
    ),
    status_code=status.HTTP_201_CREATED,
)
async def inscrire_agriculteur(
    body: dict,
    utilisateur: dict = Depends(get_utilisateur_courant),
):
    """
    Appelé après que le client Flutter a créé le compte Firebase Auth côté client.
    Le token Bearer est le token Firebase du nouvel utilisateur.
    Le rôle est forcé à AGRICULTEUR — pas de choix possible ici.
    """
    uid = utilisateur["uid"]

    # Forcer le rôle AGRICULTEUR (Custom Claim Firebase)
    try:
        firebase_auth.set_custom_user_claims(uid, {"role": "AGRICULTEUR"})
    except Exception as e:
        logger.warning(f"Impossible de poser le Custom Claim pour {uid} : {e}")

    # Créer ou mettre à jour le document Firestore avec les champs agriculteur
    profil = {
        "id": uid,
        "email": utilisateur.get("email", body.get("email", "")),
        "nom": body.get("nom", ""),
        "prenom": body.get("prenom", ""),
        "telephone": body.get("telephone", ""),
        "role": "AGRICULTEUR",
        "zone_geographique": body.get("zone_geographique", body.get("zoneGeographique", "")),
        "adresse": body.get("adresse", ""),
        "village_ville": body.get("village_ville", body.get("villageVille", "")),
        "actif": True,
        "dateInscription": datetime.now(timezone.utc),
    }

    try:
        await utilisateurs_service.creer_avec_id(uid, profil)
        logger.info(f"Agriculteur {uid} inscrit avec succès")
    except Exception as e:
        # Profil peut déjà exister (verify-token appelé avant) → mise à jour
        try:
            await utilisateurs_service.mettre_a_jour(uid, profil)
        except Exception as update_err:
            logger.error(f"Erreur création profil agriculteur {uid} : {update_err}")
            raise HTTPException(status_code=500, detail="Erreur lors de la création du profil.")

    return {"id": uid, "role": "AGRICULTEUR", "email": profil["email"]}


@router.get(
    "/me",
    summary="Profil de l'utilisateur connecté",
    description="Retourne le profil Firestore de l'utilisateur authentifié.",
    status_code=status.HTTP_200_OK,
)
async def get_me(
    utilisateur: dict = Depends(get_utilisateur_courant),
):
    """Retourne le profil de l'utilisateur courant depuis Firestore."""
    try:
        uid = utilisateur["uid"]
        profil = await auth_service.obtenir_utilisateur(uid)
        return profil
    except Exception as e:
        raise koobalatec_exception_handler(e) if hasattr(e, "code") else HTTPException(
            status_code=500, detail=str(e)
        )
