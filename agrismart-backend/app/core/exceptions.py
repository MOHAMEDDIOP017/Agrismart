"""Exceptions métier personnalisées pour AgriSmart."""

from fastapi import HTTPException, status


class AgriSmartException(Exception):
    """Exception de base pour AgriSmart."""

    def __init__(self, message: str, code: int = 500):
        self.message = message
        self.code = code
        super().__init__(message)


class AuthentificationEchoueeException(AgriSmartException):
    """Token Firebase invalide ou expiré."""

    def __init__(self, message: str = "Token d'authentification invalide ou expiré"):
        super().__init__(message, 401)


class AutorisationRefuseeException(AgriSmartException):
    """L'utilisateur n'a pas les droits nécessaires."""

    def __init__(self, message: str = "Vous n'avez pas les droits pour effectuer cette action"):
        super().__init__(message, 403)


class UtilisateurNonTrouveException(AgriSmartException):
    """Utilisateur introuvable en base."""

    def __init__(self, utilisateur_id: str):
        super().__init__(f"Utilisateur '{utilisateur_id}' introuvable", 404)


class ChampNonTrouveException(AgriSmartException):
    """Champ agricole introuvable."""

    def __init__(self, champ_id: str):
        super().__init__(f"Champ '{champ_id}' introuvable", 404)


class ChampNonAccessibleException(AgriSmartException):
    """L'utilisateur n'est pas propriétaire du champ."""

    def __init__(self, champ_id: str):
        super().__init__(f"Accès au champ '{champ_id}' refusé", 403)


class DonneesAgronomiquesAbsentesException(AgriSmartException):
    """Aucune donnée agronomique disponible pour le champ."""

    def __init__(self, champ_id: str):
        super().__init__(
            f"Aucune donnée agronomique disponible pour le champ '{champ_id}'", 422
        )


class ImageInvalideException(AgriSmartException):
    """Fichier image invalide (format, taille ou corruption)."""

    def __init__(self, raison: str = "Format ou taille d'image invalide"):
        super().__init__(raison, 400)


class ImageNonTrouveException(AgriSmartException):
    """Image introuvable en Firestore ou dans MinIO."""

    def __init__(self, image_id: str):
        super().__init__(f"Image '{image_id}' introuvable", 404)


class MinioIndisponibleException(AgriSmartException):
    """Erreur lors d'une opération sur MinIO (upload, download, delete)."""

    def __init__(self, detail: str = "Service de stockage MinIO indisponible"):
        super().__init__(detail, 503)


class ModeleIAIndisponibleException(AgriSmartException):
    """Modèle IA non chargé ou fichier absent dans models_ia/."""

    def __init__(self, nom_modele: str):
        super().__init__(
            f"Modèle IA '{nom_modele}' indisponible — vérifiez le fichier dans models_ia/",
            503,
        )


class APIMeteoIndisponibleException(AgriSmartException):
    """Erreur lors de l'appel à l'API OpenWeatherMap."""

    def __init__(self, detail: str = "API météo indisponible"):
        super().__init__(detail, 503)


class DiagnosticNonTrouveException(AgriSmartException):
    """Diagnostic de maladie introuvable."""

    def __init__(self, diagnostic_id: str):
        super().__init__(f"Diagnostic '{diagnostic_id}' introuvable", 404)


class RessourceNonTrouveException(AgriSmartException):
    """Ressource générique introuvable."""

    def __init__(self, ressource: str, id_val: str):
        super().__init__(f"{ressource} '{id_val}' introuvable", 404)


# ─── Convertisseur vers HTTPException ────────────────────────────────────────

def agrismart_exception_handler(exc: AgriSmartException) -> HTTPException:
    """Convertit une exception métier AgriSmart en HTTPException FastAPI."""
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
