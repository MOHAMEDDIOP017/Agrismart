"""Configuration globale de l'application KoobalaTech."""

from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Paramètres de configuration chargés depuis le fichier .env."""

    # Application
    app_name: str = "KoobalaTech Backend"
    app_version: str = "1.0.0"
    env: str = "development"
    api_secret_key: str = "changeme"

    # Firebase (Auth + Firestore + FCM uniquement — PAS Storage)
    firebase_service_account_path: str = "./firebase_service_account.json"
    firebase_project_id: str = "koobalatec-final"

    # MinIO — stockage objet S3-compatible pour les photos de champs
    minio_endpoint: str = "localhost:9000"
    minio_public_endpoint: str = ""
    minio_access_key: str = "koobalatecadmin"
    minio_secret_key: str = "KoobalaTech2026!Secret"
    minio_secure: bool = False
    minio_bucket_images: str = "koobalatec-images"

    # Contraintes sur les images uploadées
    taille_max_image_bytes: int = 10 * 1024 * 1024  # 10 Mo
    formats_image_autorises: list[str] = ["image/jpeg", "image/png", "image/webp"]

    # OpenWeatherMap
    openweather_api_key: str = ""
    openweather_base_url: str = "https://api.openweathermap.org/data/2.5"

    # Seuils IA
    top_k_recommandations: int = 3

    # Modèle de recommandation de cultures — RandomForest multi-label (16 variables, 8 cultures)
    modele_final_path: str = "./models_ia/modele_final.joblib"

    # Agent conversationnel IA (Qwen via OpenRouter)
    openrouter_api_key: str = ""
    openrouter_base_url: str = "https://openrouter.ai/api/v1/chat/completions"
    openrouter_modele: str = "qwen/qwen-2.5-72b-instruct"

    # Redis — cache pour tokens et profils utilisateurs
    redis_url: str = "redis://localhost:6379/0"
    redis_ttl_token: int = 300      # 5 minutes (secondes)
    redis_ttl_profil: int = 1800    # 30 minutes (secondes)

    # Mode développement : bypass Firebase Auth (ne jamais activer en production)
    dev_bypass_auth: bool = False
    dev_user_id: str = "usr_001"
    dev_user_role: str = "AGRICULTEUR"
    dev_user_email: str = "dev@koobalatec.sn"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )


@lru_cache()
def get_settings() -> Settings:
    """Retourne l'instance de configuration mise en cache."""
    return Settings()


# Instance globale utilisée dans toute l'application
settings = get_settings()
