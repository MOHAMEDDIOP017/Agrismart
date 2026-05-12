"""Router FastAPI — Gestion des images de plantes (stockage via MinIO)."""

import logging
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Query, status

from app.core.dependencies import get_utilisateur_courant
from app.models.image_plante import ImagePlanteUploadResponse
from app.services.firestore_service import images_plantes_svc
from app.services.minio_service import minio_service
from app.services.historique_service import historique_service
from app.utils.image_preprocessing import valider_image

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/images", tags=["Images de plantes"])

FORMATS_AUTORISES = {"image/jpeg", "image/png", "image/webp"}


@router.post(
    "/upload",
    summary="Uploader une image de plante",
    description=(
        "Upload une image (JPEG/PNG/WebP, max 10 Mo) vers **MinIO** "
        "et sauvegarde les métadonnées (urlMinio, nomFichierMinio, bucketMinio) en Firestore. "
        "Retourne l'ID Firestore de l'image et son URL MinIO directe."
    ),
    status_code=status.HTTP_201_CREATED,
    response_model=ImagePlanteUploadResponse,
)
async def uploader_image(
    fichier: UploadFile = File(..., description="Image de la plante (JPEG/PNG/WebP)"),
    latitude: float = Form(..., description="Latitude GPS de la prise de vue"),
    longitude: float = Form(..., description="Longitude GPS de la prise de vue"),
    champ_id: Optional[str] = Form(None, description="ID du champ associé (optionnel)"),
    commentaire: Optional[str] = Form(None, description="Commentaire de l'agriculteur"),
    courant: dict = Depends(get_utilisateur_courant),
) -> ImagePlanteUploadResponse:
    """
    Workflow d'upload vers MinIO :
    1. Validation du content type (JPEG/PNG/WebP)
    2. Lecture des bytes du fichier
    3. Validation Pillow de l'image (intégrité)
    4. Upload vers MinIO via MinioService (organisé par dossier agriculteur)
    5. Sauvegarde des métadonnées MinIO en Firestore
    6. Enregistrement dans l'historique d'activité
    7. Retour de l'ID image et de l'URL MinIO
    """
    uid = courant["uid"]

    # 1. Validation du content type
    content_type = fichier.content_type or ""
    if content_type not in FORMATS_AUTORISES:
        raise HTTPException(
            status_code=400,
            detail=f"Format non supporté : '{content_type}'. Acceptés : JPEG, PNG, WebP.",
        )

    # 2. Lecture des bytes
    contenu = await fichier.read()

    # 3. Validation de l'image avec Pillow
    valide, message_erreur = valider_image(contenu)
    if not valide:
        raise HTTPException(status_code=400, detail=message_erreur)

    # 4. Upload vers MinIO
    try:
        metadonnees_minio = await minio_service.uploader_image(
            fichier_bytes=contenu,
            content_type=content_type,
            agriculteur_id=uid,
            nom_original=fichier.filename,
        )
    except Exception as e:
        logger.error(f"Erreur upload MinIO pour l'utilisateur {uid} : {e}")
        raise HTTPException(status_code=503, detail=f"Erreur lors de l'upload MinIO : {e}")

    # 5. Sauvegarde des métadonnées en Firestore
    doc_firestore = {
        "agriculteurId": uid,
        "champId": champ_id,
        "urlMinio": metadonnees_minio["urlMinio"],
        "nomFichierMinio": metadonnees_minio["nomFichierMinio"],
        "bucketMinio": metadonnees_minio["bucketMinio"],
        "dateCapture": datetime.now(timezone.utc),
        "latitude": latitude,
        "longitude": longitude,
        "formatFichier": metadonnees_minio["formatFichier"],
        "taille": metadonnees_minio["taille"],
        "commentaireAgriculteur": commentaire or "",
        "nomOriginal": fichier.filename or "",
    }
    image_id = await images_plantes_svc.creer(doc_firestore)

    # 6. Historique d'activité
    await historique_service.enregistrer(
        uid,
        "UPLOAD_IMAGE",
        f"Image uploadée vers MinIO ({metadonnees_minio['taille']} bytes)",
        image_id,
        {
            "champ_id": champ_id,
            "taille": metadonnees_minio["taille"],
            "bucket": metadonnees_minio["bucketMinio"],
        },
    )

    logger.info(
        f"Image {image_id} uploadée par {uid} → MinIO:{metadonnees_minio['nomFichierMinio']} "
        f"({metadonnees_minio['taille']} bytes)"
    )

    return ImagePlanteUploadResponse(
        imageId=image_id,
        urlMinio=metadonnees_minio["urlMinio"],
        nomFichierMinio=metadonnees_minio["nomFichierMinio"],
        message="Image uploadée avec succès vers MinIO",
    )


@router.get(
    "/{image_id}",
    summary="Détails d'une image",
    description="Retourne les métadonnées Firestore d'une image de plante (URL MinIO incluse).",
    status_code=status.HTTP_200_OK,
)
async def obtenir_image(
    image_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    """Retourne les métadonnées d'une image stockée en Firestore."""
    image = await images_plantes_svc.lire(image_id)
    if image is None:
        raise HTTPException(status_code=404, detail=f"Image '{image_id}' introuvable.")

    uid = courant["uid"]
    if courant.get("role") not in ["ADMIN", "EXPERT"] and image.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Accès refusé.")

    return image


@router.get(
    "/agriculteur/{agriculteur_id}",
    summary="Images d'un agriculteur",
    description="Retourne toutes les images uploadées par un agriculteur (triées par date).",
    status_code=status.HTTP_200_OK,
)
async def images_agriculteur(
    agriculteur_id: str,
    limite: int = Query(default=20, ge=1, le=100),
    courant: dict = Depends(get_utilisateur_courant),
):
    """Liste les images d'un agriculteur (accès restreint à lui-même, expert ou admin)."""
    uid = courant["uid"]
    if courant.get("role") not in ["ADMIN", "EXPERT"] and uid != agriculteur_id:
        raise HTTPException(status_code=403, detail="Accès refusé.")

    images = await images_plantes_svc.lister(
        filtres=[("agriculteurId", "==", agriculteur_id)],
        ordre_par="dateCapture",
        decroissant=True,
        limite=limite,
    )
    return {"images": images, "total": len(images)}


@router.delete(
    "/{image_id}",
    summary="Supprimer une image",
    description=(
        "Supprime l'image de **MinIO** (objet S3) "
        "ET ses métadonnées de Firestore."
    ),
    status_code=status.HTTP_204_NO_CONTENT,
)
async def supprimer_image(
    image_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    """
    Suppression en deux étapes :
    1. Suppression de l'objet dans MinIO via son nomFichierMinio
    2. Suppression du document Firestore
    """
    image = await images_plantes_svc.lire(image_id)
    if image is None:
        raise HTTPException(status_code=404, detail=f"Image '{image_id}' introuvable.")

    uid = courant["uid"]
    if courant.get("role") != "ADMIN" and image.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Suppression non autorisée.")

    # 1. Suppression dans MinIO
    nom_fichier_minio = image.get("nomFichierMinio", "")
    if nom_fichier_minio:
        supprime = await minio_service.supprimer_image(nom_fichier_minio)
        if not supprime:
            logger.warning(f"Image MinIO '{nom_fichier_minio}' introuvable lors de la suppression.")

    # 2. Suppression dans Firestore
    await images_plantes_svc.supprimer(image_id)
    logger.info(f"Image {image_id} supprimée de Firestore et MinIO par {uid}.")
