"""Service de gestion des images via MinIO (stockage objet S3-compatible)."""

import io
import logging
import uuid
from datetime import datetime, timedelta
from typing import Optional

from minio.error import S3Error

from app.config import settings
from app.core.exceptions import ImageInvalideException, MinioIndisponibleException
from app.minio_init import get_minio_client

logger = logging.getLogger(__name__)

# Formats MIME acceptés
FORMATS_AUTORISES = {"image/jpeg", "image/png", "image/webp"}
# Extension par type MIME
EXTENSIONS = {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp"}


class MinioService:
    """Service de gestion des fichiers via MinIO (compatible S3)."""

    def __init__(self):
        self.bucket = settings.minio_bucket_images

    @property
    def client(self):
        """Retourne le client MinIO initialisé (lazy)."""
        return get_minio_client()

    async def uploader_image(
        self,
        fichier_bytes: bytes,
        content_type: str,
        agriculteur_id: Optional[str] = None,
        nom_original: Optional[str] = None,
    ) -> dict:
        """
        Upload une image vers MinIO et retourne ses métadonnées.

        Args:
            fichier_bytes: Contenu binaire de l'image.
            content_type: Type MIME (image/jpeg, image/png, image/webp).
            agriculteur_id: UID de l'agriculteur pour organiser les fichiers dans MinIO.
            nom_original: Nom de fichier original (optionnel, pour garder l'extension).

        Returns:
            dict avec les clés : urlMinio, nomFichierMinio, bucketMinio, taille, formatFichier.

        Raises:
            ImageInvalideException si le format ou la taille sont invalides.
            MinioIndisponibleException en cas d'erreur S3.
        """
        # Validation du format
        if content_type not in FORMATS_AUTORISES:
            raise ImageInvalideException(
                f"Format '{content_type}' non supporté. Formats acceptés : "
                + ", ".join(FORMATS_AUTORISES)
            )

        # Validation de la taille
        taille = len(fichier_bytes)
        if taille > settings.taille_max_image_bytes:
            taille_mo = settings.taille_max_image_bytes / (1024 * 1024)
            raise ImageInvalideException(
                f"Image trop volumineuse. Taille maximale autorisée : {taille_mo:.0f} Mo."
            )

        # Génération d'un nom de fichier unique horodaté
        extension = EXTENSIONS.get(content_type, "jpg")
        nom_unique = f"{datetime.now().strftime('%Y-%m-%d')}_{uuid.uuid4().hex[:8]}.{extension}"

        # Organisation des fichiers par dossier agriculteur
        chemin_minio = f"{agriculteur_id}/{nom_unique}" if agriculteur_id else nom_unique

        try:
            self.client.put_object(
                bucket_name=self.bucket,
                object_name=chemin_minio,
                data=io.BytesIO(fichier_bytes),
                length=taille,
                content_type=content_type,
            )
        except S3Error as e:
            logger.error(f"Erreur upload MinIO ({chemin_minio}) : {e}")
            raise MinioIndisponibleException(f"Échec de l'upload vers MinIO : {e}")

        # Construction de l'URL directe (bucket en lecture publique).
        # On utilise minio_public_endpoint si défini (accès depuis mobile/Wi-Fi local).
        public_host = settings.minio_public_endpoint or settings.minio_endpoint
        url_minio = f"http://{public_host}/{self.bucket}/{chemin_minio}"

        logger.info(f"Image uploadée vers MinIO : {chemin_minio} ({taille} bytes)")

        return {
            "urlMinio": url_minio,
            "nomFichierMinio": chemin_minio,
            "bucketMinio": self.bucket,
            "taille": taille,
            "formatFichier": extension.upper(),
        }

    async def telecharger_image(self, nom_fichier_minio: str) -> bytes:
        """
        Télécharge une image depuis MinIO et retourne ses bytes.

        Args:
            nom_fichier_minio: Chemin relatif de l'objet dans le bucket (ex: uid/img.jpg).

        Returns:
            Bytes bruts de l'image.

        Raises:
            MinioIndisponibleException en cas d'erreur S3.
        """
        try:
            reponse = self.client.get_object(self.bucket, nom_fichier_minio)
            donnees = reponse.read()
            reponse.close()
            reponse.release_conn()
            logger.debug(f"Image téléchargée depuis MinIO : {nom_fichier_minio} ({len(donnees)} bytes)")
            return donnees
        except S3Error as e:
            logger.error(f"Erreur téléchargement MinIO ({nom_fichier_minio}) : {e}")
            raise MinioIndisponibleException(f"Échec du téléchargement depuis MinIO : {e}")

    async def supprimer_image(self, nom_fichier_minio: str) -> bool:
        """
        Supprime une image de MinIO.

        Args:
            nom_fichier_minio: Chemin relatif de l'objet dans le bucket.

        Returns:
            True si la suppression a réussi, False sinon.
        """
        try:
            self.client.remove_object(self.bucket, nom_fichier_minio)
            logger.info(f"Image supprimée de MinIO : {nom_fichier_minio}")
            return True
        except S3Error as e:
            logger.error(f"Erreur suppression MinIO ({nom_fichier_minio}) : {e}")
            return False

    def generer_url_presignee(
        self,
        nom_fichier_minio: str,
        duree_validite_heures: int = 24,
    ) -> str:
        """
        Génère une URL pré-signée temporaire pour un accès sécurisé (si bucket privé).

        Args:
            nom_fichier_minio: Chemin relatif de l'objet dans le bucket.
            duree_validite_heures: Durée de validité de l'URL en heures (défaut 24h).

        Returns:
            URL pré-signée sous forme de chaîne.

        Raises:
            MinioIndisponibleException en cas d'erreur S3.
        """
        try:
            url = self.client.presigned_get_object(
                bucket_name=self.bucket,
                object_name=nom_fichier_minio,
                expires=timedelta(hours=duree_validite_heures),
            )
            return url
        except S3Error as e:
            logger.error(f"Erreur génération URL pré-signée MinIO : {e}")
            raise MinioIndisponibleException(f"Impossible de générer l'URL pré-signée : {e}")

    async def uploader_photo_champ(
        self,
        fichier_bytes: bytes,
        content_type: str,
        champ_id: str,
    ) -> str:
        """
        Upload la photo d'un champ agricole et retourne l'URL MinIO.

        Args:
            fichier_bytes: Contenu binaire de la photo.
            content_type: Type MIME.
            champ_id: ID du champ pour organiser le stockage.

        Returns:
            URL MinIO directe de la photo.
        """
        extension = EXTENSIONS.get(content_type, "jpg")
        chemin = f"champs/{champ_id}/{uuid.uuid4().hex}.{extension}"

        try:
            self.client.put_object(
                bucket_name=self.bucket,
                object_name=chemin,
                data=io.BytesIO(fichier_bytes),
                length=len(fichier_bytes),
                content_type=content_type,
            )
        except S3Error as e:
            logger.error(f"Erreur upload photo champ ({champ_id}) : {e}")
            raise MinioIndisponibleException(f"Échec de l'upload de la photo du champ : {e}")

        public_host = settings.minio_public_endpoint or settings.minio_endpoint
        url = f"http://{public_host}/{self.bucket}/{chemin}"
        logger.info(f"Photo du champ {champ_id} uploadée : {chemin}")
        return url


# Instance globale du service MinIO
minio_service = MinioService()
