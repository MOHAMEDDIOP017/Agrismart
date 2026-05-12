"""Modèles Pydantic pour les images de plantes stockées dans MinIO."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class ImagePlanteBase(BaseModel):
    """Métadonnées de base d'une image de plante."""

    agriculteurId: str
    champId: Optional[str] = None
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    commentaireAgriculteur: Optional[str] = Field(None, max_length=500)


class ImagePlanteCreate(ImagePlanteBase):
    """Données enregistrées en Firestore après upload vers MinIO."""

    # URL directe vers l'objet MinIO : http://localhost:9000/agrismart-images/uid/img.jpg
    urlMinio: str = Field(..., description="URL MinIO complète de l'image")
    # Chemin relatif dans le bucket MinIO : ex. uid/2026-04-23_abc12345.jpg
    nomFichierMinio: str = Field(..., description="Chemin relatif de l'objet dans le bucket MinIO")
    # Nom du bucket MinIO : ex. agrismart-images
    bucketMinio: str = Field(..., description="Nom du bucket MinIO contenant l'image")
    formatFichier: str = Field(..., description="Extension du fichier : JPG, PNG ou WEBP")
    taille: int = Field(..., gt=0, description="Taille du fichier en bytes")


class ImagePlanteResponse(ImagePlanteBase):
    """Réponse complète d'une image de plante (depuis Firestore)."""

    id: str
    urlMinio: str
    nomFichierMinio: str
    bucketMinio: str
    dateCapture: datetime
    formatFichier: str
    taille: int

    class Config:
        from_attributes = True


class ImagePlanteUploadResponse(BaseModel):
    """Réponse immédiate retournée après l'upload d'une image."""

    imageId: str = Field(..., description="ID Firestore de l'image créée")
    urlMinio: str = Field(..., description="URL MinIO directe pour affichage dans Flutter")
    nomFichierMinio: str = Field(..., description="Chemin relatif dans le bucket MinIO")
    message: str = "Image uploadée avec succès vers MinIO"
