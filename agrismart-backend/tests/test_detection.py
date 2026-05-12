"""Tests du Module IA 2 — Détection de maladies des plantes."""

import pytest
import io
import numpy as np
from unittest.mock import AsyncMock, MagicMock, patch
from PIL import Image


def creer_image_test(largeur: int = 224, hauteur: int = 224) -> bytes:
    """Crée une image PNG de test en mémoire."""
    image = Image.fromarray(
        np.random.randint(0, 255, (hauteur, largeur, 3), dtype=np.uint8)
    )
    buffer = io.BytesIO()
    image.save(buffer, format="PNG")
    return buffer.getvalue()


class TestDetectionService:
    """Tests du service de détection de maladies (EfficientNetB0)."""

    @pytest.fixture
    def service(self):
        """Instance du service de détection."""
        from app.services.detection_service import DetectionService
        return DetectionService()

    def test_preprocesser_image_shape_correcte(self, service):
        """Le prétraitement doit produire un tableau de shape (1, 224, 224, 3)."""
        image_bytes = creer_image_test()
        resultat = service._preprocesser_image(image_bytes)

        assert resultat.shape == (1, 224, 224, 3)
        assert resultat.dtype == np.float32

    def test_preprocesser_image_normalisation(self, service):
        """Les pixels doivent être normalisés entre 0 et 1."""
        image_bytes = creer_image_test()
        resultat = service._preprocesser_image(image_bytes)

        assert resultat.min() >= 0.0
        assert resultat.max() <= 1.0

    def test_predire_mock_retourne_top3(self, service):
        """Le mock de prédiction doit retourner au moins 3 prédictions."""
        resultats = service._predire_mock()

        assert len(resultats) >= 3
        for nom, score in resultats[:3]:
            assert isinstance(nom, str)
            assert 0 <= score <= 1

    def test_predire_mock_premier_score_plus_eleve(self, service):
        """Le premier résultat doit avoir le score le plus élevé."""
        resultats = service._predire_mock()
        scores = [score for _, score in resultats]

        assert scores[0] >= scores[1]
        assert scores[1] >= scores[2]

    @pytest.mark.asyncio
    @patch("app.services.detection_service.images_plantes_svc")
    async def test_analyser_image_inexistante(self, mock_images, service):
        """Une exception doit être levée si l'image n'existe pas."""
        from app.core.exceptions import ImageNonTrouveException
        mock_images.lire = AsyncMock(return_value=None)

        with pytest.raises(ImageNonTrouveException):
            await service.analyser_image("image_inexistante", "agri1")

    @pytest.mark.asyncio
    @patch("app.services.detection_service.images_plantes_svc")
    @patch("app.services.detection_service.storage_service")
    @patch("app.services.detection_service.diagnostics_svc")
    @patch("app.services.detection_service.maladies_service")
    @patch("app.services.detection_service.traitements_svc")
    async def test_analyser_image_mode_mock(
        self,
        mock_traitements,
        mock_maladies,
        mock_diagnostics,
        mock_storage,
        mock_images,
        service,
    ):
        """L'analyse doit fonctionner en mode mock (sans modèle TFLite)."""
        from app.models.enums import StatutValidation

        image_bytes = creer_image_test()

        mock_images.lire = AsyncMock(return_value={
            "id": "img1",
            "agriculteurId": "agri1",
            "cheminStorage": "images_plantes/agri1/test.png",
            "champId": "champ1",
        })
        mock_storage.telecharger_image = AsyncMock(return_value=image_bytes)
        mock_diagnostics.creer = AsyncMock(return_value="diag_id_1")
        mock_maladies.lister = AsyncMock(return_value=[])
        mock_traitements.lister = AsyncMock(return_value=[])

        resultat = await service.analyser_image("img1", "agri1", "champ1")

        assert resultat is not None
        assert resultat.diagnosticId == "diag_id_1"
        assert resultat.imageId == "img1"
        assert 0 <= resultat.scoreConfiance <= 1
        assert len(resultat.topPredictions) >= 1
        assert resultat.statut in [StatutValidation.EN_ATTENTE, StatutValidation.AUTO_CONFIRME]


class TestImagePreprocessing:
    """Tests des utilitaires de prétraitement d'images."""

    def test_valider_image_valide(self):
        """Une image PNG valide doit passer la validation."""
        from app.utils.image_preprocessing import valider_image
        image_bytes = creer_image_test()
        valide, message = valider_image(image_bytes)
        assert valide is True

    def test_valider_image_trop_grande(self):
        """Une image dépassant la taille maximale doit échouer."""
        from app.utils.image_preprocessing import valider_image
        image_bytes = b"x" * (11 * 1024 * 1024)  # 11 Mo
        valide, message = valider_image(image_bytes, taille_max=10 * 1024 * 1024)
        assert valide is False
        assert "volumineuse" in message.lower()

    def test_extraire_miniature_dimensions(self):
        """La miniature doit avoir les dimensions spécifiées."""
        from app.utils.image_preprocessing import extraire_miniature
        image_bytes = creer_image_test(500, 500)
        miniature = extraire_miniature(image_bytes, taille=(128, 128))
        assert len(miniature) > 0
        image_mini = Image.open(io.BytesIO(miniature))
        assert image_mini.size[0] <= 128
        assert image_mini.size[1] <= 128
