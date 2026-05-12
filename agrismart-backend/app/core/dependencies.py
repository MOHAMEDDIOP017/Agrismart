"""Dépendances FastAPI pour l'authentification et les autorisations par rôle."""

import logging
from typing import Annotated

from fastapi import Depends, Header
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from app.core.security import verifier_token_firebase
from app.core.exceptions import (
    AuthentificationEchoueeException,
    AutorisationRefuseeException,
    agrismart_exception_handler,
)
from app.models.enums import RoleUtilisateur

logger = logging.getLogger(__name__)

# Schéma de sécurité HTTP Bearer
bearer_scheme = HTTPBearer(auto_error=False)


async def get_utilisateur_courant(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)]
) -> dict:
    """
    Dépendance principale : vérifie le token Bearer et retourne l'utilisateur décodé.

    Usage dans un router :
        @router.get("/me")
        async def get_me(utilisateur: dict = Depends(get_utilisateur_courant)):
            ...

    Returns:
        dict Firebase décodé avec : uid, email, custom claims (role, etc.)
    """
    from app.config import settings

    # Mode développement : bypass Firebase (DEV_BYPASS_AUTH=true dans .env)
    if settings.dev_bypass_auth:
        logger.debug(f"[DEV BYPASS] Utilisateur simulé : {settings.dev_user_id}")
        return {
            "uid": settings.dev_user_id,
            "email": settings.dev_user_email,
            "role": settings.dev_user_role,
        }

    if credentials is None:
        raise AuthentificationEchoueeException(
            "En-tête Authorization manquant. Format attendu : 'Bearer <token>'"
        )
    try:
        token_data = await verifier_token_firebase(credentials.credentials)
        return token_data
    except AuthentificationEchoueeException as e:
        raise agrismart_exception_handler(e)


def require_role(*roles: RoleUtilisateur):
    """
    Fabrique de dépendances qui vérifie qu'un utilisateur possède l'un des rôles requis.

    Usage :
        @router.post("/admin/action")
        async def action_admin(
            utilisateur: dict = Depends(require_role(RoleUtilisateur.ADMIN))
        ):
            ...
    """
    async def verifier_role(
        utilisateur: dict = Depends(get_utilisateur_courant),
    ) -> dict:
        role_utilisateur = utilisateur.get("role") or utilisateur.get("claims", {}).get("role")
        roles_str = [r.value for r in roles]

        if role_utilisateur not in roles_str:
            logger.warning(
                f"Accès refusé : utilisateur {utilisateur.get('uid')} "
                f"avec rôle '{role_utilisateur}' tente d'accéder à une ressource réservée à {roles_str}"
            )
            raise AutorisationRefuseeException(
                f"Cette action requiert l'un des rôles suivants : {', '.join(roles_str)}"
            )
        return utilisateur

    return verifier_role


def require_admin():
    """Raccourci : accès réservé aux administrateurs."""
    return require_role(RoleUtilisateur.ADMIN)


def require_expert():
    """Raccourci : accès réservé aux experts (et admins)."""
    return require_role(RoleUtilisateur.EXPERT, RoleUtilisateur.ADMIN)


def require_agriculteur():
    """Raccourci : accès réservé aux agriculteurs (et admins)."""
    return require_role(RoleUtilisateur.AGRICULTEUR, RoleUtilisateur.ADMIN)


def require_any_role():
    """Raccourci : accès à tout utilisateur authentifié, quel que soit son rôle."""
    return get_utilisateur_courant
