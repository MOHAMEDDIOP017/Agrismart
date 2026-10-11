"""Initialisation du client MinIO pour le stockage des images de plantes."""

import json
import logging

from minio import Minio
from minio.error import S3Error

from app.config import settings
from app.core.exceptions import MinioIndisponibleException

logger = logging.getLogger(__name__)


class MinioClient:
    """Client MinIO singleton pour AgriSmart."""

    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._verifier_identifiants()
            cls._instance = super().__new__(cls)
            cls._instance.client = Minio(
                endpoint=settings.minio_endpoint,
                access_key=settings.minio_access_key,
                secret_key=settings.minio_secret_key,
                secure=settings.minio_secure,
            )
            cls._instance._initialiser_buckets()
        return cls._instance

    @staticmethod
    def _verifier_identifiants() -> None:
        """
        Refuse de construire le client si les identifiants MinIO ne sont pas
        fournis par l'environnement.

        `settings.minio_access_key` / `minio_secret_key` n'ont plus de valeur
        par défaut dans le code (elles y étaient en clair). Sans ce contrôle,
        l'absence de configuration produirait une erreur S3 « SignatureDoesNot
        Match » au premier upload, difficile à relier à un .env incomplet.
        """
        manquantes = [
            nom for nom, valeur in (
                ("MINIO_ACCESS_KEY", settings.minio_access_key),
                ("MINIO_SECRET_KEY", settings.minio_secret_key),
            )
            if not valeur
        ]
        if manquantes:
            raise MinioIndisponibleException(
                "Identifiants MinIO absents de l'environnement : "
                f"{', '.join(manquantes)}. Renseignez-les dans votre fichier .env "
                "(voir .env.example) — ils ne sont volontairement plus définis "
                "dans le code."
            )

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
