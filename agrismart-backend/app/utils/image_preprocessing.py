"""Utilitaires de prétraitement des images pour KoobalaTech."""

import io
import logging
from typing import Optional

import numpy as np
from PIL import Image, ImageEnhance

from app.config import settings

logger = logging.getLogger(__name__)


def redimensionner_image(
    image_bytes: bytes,
    largeur: int = 224,
    hauteur: int = 224,
) -> np.ndarray:
    """
    Redimensionne et normalise une image pour l'inférence.

    Args:
        image_bytes: Bytes bruts de l'image.
        largeur: Largeur cible en pixels.
        hauteur: Hauteur cible en pixels.

    Returns:
        np.ndarray de shape (hauteur, largeur, 3), normalisé [0, 1].
    """
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    image = image.resize((largeur, hauteur), Image.BILINEAR)
    array = np.array(image, dtype=np.float32) / 255.0
    return array


def preparer_batch(image_array: np.ndarray) -> np.ndarray:
    """Ajoute la dimension batch : (H, W, C) → (1, H, W, C)."""
    return np.expand_dims(image_array, axis=0)


def valider_image(image_bytes: bytes, taille_max: Optional[int] = None) -> tuple[bool, str]:
    """
    Valide qu'une image est bien formée et dans les limites acceptables.

    Returns:
        Tuple (valide: bool, message: str).
    """
    taille_max = taille_max or settings.taille_max_image_bytes

    if len(image_bytes) > taille_max:
        return False, f"Image trop volumineuse ({len(image_bytes)} bytes > {taille_max})"

    try:
        image = Image.open(io.BytesIO(image_bytes))
        image.verify()
        return True, "Image valide"
    except Exception as e:
        return False, f"Image corrompue ou invalide : {e}"


def extraire_miniature(image_bytes: bytes, taille: tuple[int, int] = (128, 128)) -> bytes:
    """Génère une miniature d'une image en JPEG."""
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    image.thumbnail(taille, Image.LANCZOS)
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=85)
    return buffer.getvalue()
