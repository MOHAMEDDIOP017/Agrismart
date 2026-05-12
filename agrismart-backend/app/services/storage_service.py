"""Service de stockage d'images — délègue à MinIO (remplace l'ancien Firebase Storage)."""

from app.services.minio_service import MinioService, minio_service
from app.core.exceptions import ImageInvalideException

__all__ = ["StorageService", "storage_service"]

# Alias pour compatibilité avec les anciens imports
StorageService = MinioService
storage_service = minio_service
