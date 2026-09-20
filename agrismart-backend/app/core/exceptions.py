"""Exceptions métier personnalisées pour KoobalaTech."""

from fastapi import HTTPException, status


class KoobalaTechException(Exception):
    """Exception de base pour KoobalaTech."""

    def __init__(self, message: str, code: int = 500):
        self.message = message
        self.code = code
        super().__init__(message)


class AuthentificationEchoueeException(KoobalaTechException):
    """Token Firebase invalide ou expiré."""

    def __init__(self, message: str = "Token d'authentification invalide ou expiré"):
        super().__init__(message, 401)


class AutorisationRefuseeException(KoobalaTechException):
    """L'utilisateur n'a pas les droits nécessaires."""

    def __init__(self, message: str = "Vous n'avez pas les droits pour effectuer cette action"):
        super().__init__(message, 403)


class UtilisateurNonTrouveException(KoobalaTechException):
    """Utilisateur introuvable en base."""

    def __init__(self, utilisateur_id: str):
        super().__init__(f"Utilisateur '{utilisateur_id}' introuvable", 404)


class ChampNonTrouveException(KoobalaTechException):
    """Champ agricole introuvable."""

    def __init__(self, champ_id: str):
        super().__init__(f"Champ '{champ_id}' introuvable", 404)


class ChampNonAccessibleException(KoobalaTechException):
    """L'utilisateur n'est pas propriétaire du champ."""

    def __init__(self, champ_id: str):
        super().__init__(f"Accès au champ '{champ_id}' refusé", 403)


class ImageInvalideException(KoobalaTechException):
    """Fichier image invalide (format, taille ou corruption)."""

    def __init__(self, raison: str = "Format ou taille d'image invalide"):
        super().__init__(raison, 400)


class MinioIndisponibleException(KoobalaTechException):
    """Erreur lors d'une opération sur MinIO (upload, download, delete)."""

    def __init__(self, detail: str = "Service de stockage MinIO indisponible"):
        super().__init__(detail, 503)


class ModeleIAIndisponibleException(KoobalaTechException):
    """Modèle IA non chargé ou fichier absent dans models_ia/."""

    def __init__(self, nom_modele: str):
        super().__init__(
            f"Modèle IA '{nom_modele}' indisponible — vérifiez le fichier dans models_ia/",
            503,
        )


class APIMeteoIndisponibleException(KoobalaTechException):
    """Erreur lors de l'appel à l'API OpenWeatherMap."""

    def __init__(self, detail: str = "API météo indisponible"):
        super().__init__(detail, 503)


class AgentIAIndisponibleException(KoobalaTechException):
    """L'agent conversationnel (Qwen via OpenRouter) est mal configuré ou indisponible."""

    def __init__(self, detail: str = "Agent conversationnel indisponible"):
        super().__init__(detail, 503)


class RessourceNonTrouveException(KoobalaTechException):
    """Ressource générique introuvable."""

    def __init__(self, ressource: str, id_val: str):
        super().__init__(f"{ressource} '{id_val}' introuvable", 404)


# ─── Convertisseur vers HTTPException ────────────────────────────────────────

def koobalatec_exception_handler(exc: KoobalaTechException) -> HTTPException:
    """Convertit une exception métier KoobalaTech en HTTPException FastAPI."""
    status_map = {
        400: status.HTTP_400_BAD_REQUEST,
        401: status.HTTP_401_UNAUTHORIZED,
        403: status.HTTP_403_FORBIDDEN,
        404: status.HTTP_404_NOT_FOUND,
        422: status.HTTP_422_UNPROCESSABLE_ENTITY,
        503: status.HTTP_503_SERVICE_UNAVAILABLE,
    }
    http_status = status_map.get(exc.code, status.HTTP_500_INTERNAL_SERVER_ERROR)
    return HTTPException(status_code=http_status, detail=exc.message)
