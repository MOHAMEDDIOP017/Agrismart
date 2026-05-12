"""Initialisation du client MinIO pour le stockage des images de plantes."""

import json
import logging

from minio import Minio
from minio.error import S3Error

from app.config import settings

logger = logging.getLogger(__name__)


class MinioClient:
    """Client MinIO singleton pour AgriSmart."""

    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.client = Minio(
                endpoint=settings.minio_endpoint,
                access_key=settings.minio_access_key,
                secret_key=settings.minio_secret_key,
                secure=settings.minio_secure,
            )
            cls._instance._initialiser_buckets()
        return cls._instance

    def _initialiser_buckets(self) -> None:
        """Crée les buckets nécessaires s'ils n'existent pas et applique la politique publique."""
        bucket = settings.minio_bucket_images
        try:
            if not self.client.bucket_exists(bucket):
                self.client.make_bucket(bucket)
                logger.info(f"Bucket MinIO '{bucket}' créé avec succès.")
                self._definir_politique_publique(bucket)
            else:
                logger.info(f"Bucket MinIO '{bucket}' déjà existant.")
        except S3Error as e:
            logger.error(f"Erreur lors de l'initialisation du bucket MinIO : {e}")
            raise

    def _definir_politique_publique(self, bucket_name: str) -> None:
        """Applique une politique de lecture publique pour l'affichage direct dans Flutter."""
        policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {"AWS": "*"},
                    "Action": ["s3:GetObject"],
                    "Resource": [f"arn:aws:s3:::{bucket_name}/*"],
                }
            ],
        }
        self.client.set_bucket_policy(bucket_name, json.dumps(policy))
        logger.info(f"Politique publique appliquée sur le bucket '{bucket_name}'.")


def get_minio_client() -> Minio:
    """Retourne le client MinIO initialisé (singleton)."""
    return MinioClient().client
