"""Tests unitaires pour le service MinIO d'KoobalaTech."""

import io
import pytest
from unittest.mock import AsyncMock, MagicMock, patch, PropertyMock
from minio.error import S3Error

from app.core.exceptions import ImageInvalideException, MinioIndisponibleException


# ─── Fixtures ────────────────────────────────────────────────────────────────

@pytest.fixture
def image_jpeg_valide():
    """Bytes d'un JPEG 1x1 pixel valide (minimum pour Pillow)."""
    from PIL import Image
    img = Image.new("RGB", (10, 10), color=(100, 150, 200))
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    return buf.getvalue()


@pytest.fixture
def image_png_valide():
    """Bytes d'un PNG valide."""
    from PIL import Image
    img = Image.new("RGB", (10, 10), color=(50, 100, 200))
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


@pytest.fixture
def minio_service_mock():
    """Instance de MinioService avec le client MinIO mocké."""
    with patch("app.services.minio_service.get_minio_client") as mock_get_client:
        mock_client = MagicMock()
        mock_get_client.return_value = mock_client

        from app.services.minio_service import MinioService
        service = MinioService()
        yield service, mock_client


# ─── Tests : upload d'image ───────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_uploader_image_jpeg_succes(minio_service_mock, image_jpeg_valide):
    """Upload d'un JPEG valide doit retourner les métadonnées MinIO."""
    service, mock_client = minio_service_mock
    mock_client.put_object.return_value = None

    resultat = await service.uploader_image(
        fichier_bytes=image_jpeg_valide,
        content_type="image/jpeg",
        agriculteur_id="agriculteur_001",
        nom_original="plante.jpg",
    )

    assert "urlMinio" in resultat
    assert "nomFichierMinio" in resultat
    assert "bucketMinio" in resultat
    assert resultat["formatFichier"] == "JPG"
    assert resultat["taille"] == len(image_jpeg_valide)
    assert "agriculteur_001/" in resultat["nomFichierMinio"]
    mock_client.put_object.assert_called_once()


@pytest.mark.asyncio
async def test_uploader_image_png_succes(minio_service_mock, image_png_valide):
    """Upload d'un PNG valide doit fonctionner correctement."""
    service, mock_client = minio_service_mock
    mock_client.put_object.return_value = None

    resultat = await service.uploader_image(
        fichier_bytes=image_png_valide,
        content_type="image/png",
        agriculteur_id="agriculteur_002",
    )

    assert resultat["formatFichier"] == "PNG"
    assert "koobalatec-images" in resultat["bucketMinio"] or resultat["bucketMinio"] == service.bucket


@pytest.mark.asyncio
async def test_uploader_image_format_invalide(minio_service_mock):
    """Format non supporté doit lever ImageInvalideException."""
    service, _ = minio_service_mock

    with pytest.raises(ImageInvalideException) as exc_info:
        await service.uploader_image(
            fichier_bytes=b"donnees_pdf",
            content_type="application/pdf",
            agriculteur_id="agriculteur_001",
        )

    assert "non supporté" in str(exc_info.value.message).lower() or "format" in str(exc_info.value.message).lower()


@pytest.mark.asyncio
async def test_uploader_image_trop_volumineuse(minio_service_mock):
    """Image dépassant la taille maximale doit lever ImageInvalideException."""
    service, _ = minio_service_mock

    # Crée un contenu fictif dépassant 10 Mo
    gros_fichier = b"x" * (11 * 1024 * 1024)

    with pytest.raises(ImageInvalideException) as exc_info:
        await service.uploader_image(
            fichier_bytes=gros_fichier,
            content_type="image/jpeg",
            agriculteur_id="agriculteur_001",
        )

    assert "volumineuse" in str(exc_info.value.message).lower() or "taille" in str(exc_info.value.message).lower()


@pytest.mark.asyncio
async def test_uploader_image_erreur_minio(minio_service_mock, image_jpeg_valide):
    """Erreur S3 lors de l'upload doit lever MinioIndisponibleException."""
    service, mock_client = minio_service_mock
    mock_client.put_object.side_effect = S3Error(
        "InternalError", "Erreur serveur", "resource", "request_id", "host_id", response=MagicMock()
    )

    with pytest.raises(MinioIndisponibleException):
        await service.uploader_image(
            fichier_bytes=image_jpeg_valide,
            content_type="image/jpeg",
            agriculteur_id="agriculteur_001",
        )


@pytest.mark.asyncio
async def test_uploader_image_sans_agriculteur_id(minio_service_mock, image_jpeg_valide):
    """Upload sans agriculteur_id doit quand même fonctionner (fichier à la racine du bucket)."""
    service, mock_client = minio_service_mock
    mock_client.put_object.return_value = None

    resultat = await service.uploader_image(
        fichier_bytes=image_jpeg_valide,
        content_type="image/jpeg",
    )

    # Sans agriculteur_id, le chemin ne doit pas contenir de slash préfixe
    assert "/" not in resultat["nomFichierMinio"].split(".")[0].split("_")[0]
    mock_client.put_object.assert_called_once()


# ─── Tests : téléchargement d'image ──────────────────────────────────────────

@pytest.mark.asyncio
async def test_telecharger_image_succes(minio_service_mock, image_jpeg_valide):
    """Téléchargement d'une image existante doit retourner ses bytes."""
    service, mock_client = minio_service_mock

    mock_reponse = MagicMock()
    mock_reponse.read.return_value = image_jpeg_valide
    mock_client.get_object.return_value = mock_reponse

    resultat = await service.telecharger_image("agriculteur_001/2026-04-23_abc12345.jpg")

    assert resultat == image_jpeg_valide
    mock_client.get_object.assert_called_once()
    mock_reponse.close.assert_called_once()
    mock_reponse.release_conn.assert_called_once()


@pytest.mark.asyncio
async def test_telecharger_image_erreur_minio(minio_service_mock):
    """Erreur S3 lors du téléchargement doit lever MinioIndisponibleException."""
    service, mock_client = minio_service_mock
    mock_client.get_object.side_effect = S3Error(
        "NoSuchKey", "Objet introuvable", "resource", "request_id", "host_id", response=MagicMock()
    )

    with pytest.raises(MinioIndisponibleException):
        await service.telecharger_image("agriculteur_001/inexistant.jpg")


# ─── Tests : suppression d'image ─────────────────────────────────────────────

@pytest.mark.asyncio
async def test_supprimer_image_succes(minio_service_mock):
    """Suppression réussie doit retourner True."""
    service, mock_client = minio_service_mock
    mock_client.remove_object.return_value = None

    resultat = await service.supprimer_image("agriculteur_001/2026-04-23_abc12345.jpg")

    assert resultat is True
    mock_client.remove_object.assert_called_once()


@pytest.mark.asyncio
async def test_supprimer_image_erreur_minio(minio_service_mock):
    """Erreur S3 lors de la suppression doit retourner False (sans lever d'exception)."""
    service, mock_client = minio_service_mock
    mock_client.remove_object.side_effect = S3Error(
        "InternalError", "Erreur serveur", "resource", "request_id", "host_id", response=MagicMock()
    )

    resultat = await service.supprimer_image("agriculteur_001/inexistant.jpg")

    assert resultat is False


# ─── Tests : URL pré-signée ───────────────────────────────────────────────────

def test_generer_url_presignee_succes(minio_service_mock):
    """Génération d'une URL pré-signée valide."""
    service, mock_client = minio_service_mock
    url_attendue = "http://localhost:9000/koobalatec-images/fichier.jpg?X-Amz-Signature=abc123"
    mock_client.presigned_get_object.return_value = url_attendue

    url = service.generer_url_presignee("agriculteur_001/fichier.jpg", duree_validite_heures=12)

    assert url == url_attendue
    mock_client.presigned_get_object.assert_called_once()


def test_generer_url_presignee_erreur(minio_service_mock):
    """Erreur S3 lors de la génération d'URL doit lever MinioIndisponibleException."""
    service, mock_client = minio_service_mock
    mock_client.presigned_get_object.side_effect = S3Error(
        "InternalError", "Erreur", "resource", "request_id", "host_id", response=MagicMock()
    )

    with pytest.raises(MinioIndisponibleException):
        service.generer_url_presignee("agriculteur_001/fichier.jpg")


# ─── Tests : organisation des fichiers ───────────────────────────────────────

@pytest.mark.asyncio
async def test_chemin_minio_structure_correcte(minio_service_mock, image_jpeg_valide):
    """Le nomFichierMinio doit suivre le format : agriculteur_id/YYYY-MM-DD_xxxxxxxx.ext."""
    service, mock_client = minio_service_mock
    mock_client.put_object.return_value = None

    resultat = await service.uploader_image(
        fichier_bytes=image_jpeg_valide,
        content_type="image/jpeg",
        agriculteur_id="user_xyz",
    )

    chemin = resultat["nomFichierMinio"]
    # Structure attendue : user_xyz/2026-04-23_abc12345.jpg
    parties = chemin.split("/")
    assert parties[0] == "user_xyz"
    assert parties[1].endswith(".jpg")
    assert len(parties[1].split("_")) >= 2


@pytest.mark.asyncio
async def test_url_minio_format_correct(minio_service_mock, image_jpeg_valide):
    """L'urlMinio doit pointer vers le bon endpoint et bucket."""
    service, mock_client = minio_service_mock
    mock_client.put_object.return_value = None

    resultat = await service.uploader_image(
        fichier_bytes=image_jpeg_valide,
        content_type="image/jpeg",
        agriculteur_id="agriculteur_test",
    )

    url = resultat["urlMinio"]
    # L'URL doit commencer par http://endpoint/bucket/
    assert url.startswith("http://")
    assert service.bucket in url
    assert resultat["nomFichierMinio"] in url
