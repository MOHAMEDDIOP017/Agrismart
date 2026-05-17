"""Configuration globale de l'application KoobalaTech."""

from functools import lru_cache
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Paramètres de configuration chargés depuis le fichier .env."""

    # Application
    app_name: str = "KoobalaTech Backend"
    app_version: str = "1.0.0"
    env: str = "development"
    api_secret_key: str = "changeme"

    # Firebase (Auth + Firestore + FCM uniquement — PAS Storage)
    firebase_service_account_path: str = "./firebase_service_account.json"
    firebase_project_id: str = "agrismart-final"

    # MinIO — stockage objet S3-compatible pour les images de plantes
    minio_endpoint: str = "localhost:9000"
    # Endpoint public utilisé dans les URLs retournées aux clients mobiles.
    # En dev Wi-Fi local : mettre l'IP du PC (ex: 10.156.84.163:9000).
    # Si vide, on utilise minio_endpoint.
    minio_public_endpoint: str = ""
    minio_access_key: str = "agrismartadmin"
    minio_secret_key: str = "AgriSmart2026!Secret"
    minio_secure: bool = False
    minio_bucket_images: str = "agrismart-images"

    # OpenWeatherMap
    openweather_api_key: str = ""
    openweather_base_url: str = "https://api.openweathermap.org/data/2.5"

    # Seuils IA
    seuil_confiance_detection: float = 0.7
    top_k_recommandations: int = 3

    # Chemins des modèles IA
    modele_recommandation_path: str = "./models_ia/svm_crop.pkl"
    scaler_path: str = "./models_ia/scaler_crop.pkl"
    label_encoder_path: str = "./models_ia/label_encoder_crop.pkl"
    modele_metadata_path: str = "./models_ia/model_metadata.json"
    modele_detection_path: str = "./models_ia/efficientnetb0_plantvillage.tflite"
    classes_detection_path: str = "./models_ia/class_names.json"

    # Contraintes sur les images
    taille_max_image_bytes: int = 10 * 1024 * 1024  # 10 Mo
    formats_image_autorises: list[str] = ["image/jpeg", "image/png", "image/webp"]

    # Dimension d'entrée du modèle EfficientNetB0
    image_width: int = 224
    image_height: int = 224

    # Redis — cache pour tokens et profils utilisateurs
    redis_url: str = "redis://localhost:6379/0"
    redis_ttl_token: int = 300      # 5 minutes (secondes)
    redis_ttl_profil: int = 1800    # 30 minutes (secondes)

    # Mode développement : bypass Firebase Auth (ne jamais activer en production)
    dev_bypass_auth: bool = False
    dev_user_id: str = "usr_001"
    dev_user_role: str = "AGRICULTEUR"
    dev_user_email: str = "dev@agrismart.sn"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    """Retourne l'instance de configuration mise en cache."""
    return Settings()


# Instance globale utilisée dans toute l'application
settings = get_settings()
