"""Vérification des tokens Firebase et gestion de la sécurité."""

import logging
from typing import Optional

import firebase_admin.auth as firebase_auth

from app.core.exceptions import AuthentificationEchoueeException
from app.core import cache as redis_cache
from app.config import settings

logger = logging.getLogger(__name__)


async def verifier_token_firebase(id_token: str) -> dict:
    """
    Vérifie un idToken Firebase et retourne les informations décodées.
    Le résultat est mis en cache Redis (TTL = redis_ttl_token).

    Args:
        id_token: Token JWT émis par Firebase Authentication côté client.

    Returns:
        dict contenant uid, email, et les custom claims (dont le rôle).

    Raises:
        AuthentificationEchoueeException si le token est invalide ou expiré.
    """
    cache_key = redis_cache.token_cache_key(id_token)
    cached = await redis_cache.get_cached(cache_key)
    if cached:
        return cached

    try:
        decoded_token = firebase_auth.verify_id_token(id_token)
        logger.debug(f"Token vérifié pour l'utilisateur : {decoded_token.get('uid')}")
        serializable = {k: v for k, v in decoded_token.items() if isinstance(v, (str, int, float, bool, list, dict, type(None)))}
        await redis_cache.set_cached(cache_key, serializable, settings.redis_ttl_token)
        return decoded_token
    except firebase_auth.ExpiredIdTokenError:
        logger.warning("Token Firebase expiré.")
        raise AuthentificationEchoueeException("Token expiré. Veuillez vous reconnecter.")
    except firebase_auth.InvalidIdTokenError as e:
        logger.warning(f"Token Firebase invalide : {e}")
        raise AuthentificationEchoueeException("Token invalide.")
    except firebase_auth.RevokedIdTokenError:
        logger.warning("Token Firebase révoqué.")
        raise AuthentificationEchoueeException("Token révoqué. Veuillez vous reconnecter.")
    except Exception as e:
        logger.error(f"Erreur inattendue lors de la vérification du token : {e}")
        raise AuthentificationEchoueeException(f"Erreur d'authentification : {str(e)}")


def extraire_token_du_header(authorization: Optional[str]) -> str:
    """
    Extrait le Bearer token depuis l'en-tête Authorization.

    Args:
        authorization: Valeur de l'en-tête Authorization (ex: "Bearer <token>").

    Returns:
        Le token JWT brut.

    Raises:
        AuthentificationEchoueeException si le format est invalide.
    """
    if not authorization:
        raise AuthentificationEchoueeException(
            "En-tête Authorization manquant. Format attendu : 'Bearer <token>'"
        )

    parties = authorization.split(" ")
    if len(parties) != 2 or parties[0].lower() != "bearer":
        raise AuthentificationEchoueeException(
            "Format Authorization invalide. Attendu : 'Bearer <token>'"
        )

    return parties[1]
