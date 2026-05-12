"""Tests du Module IA 1 — Recommandation de cultures."""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime, timezone


class TestRecommandationService:
    """Tests du service de recommandation (Random Forest)."""

    @pytest.fixture
    def service(self):
        """Instance du service avec modèles mockés."""
        from app.services.recommandation_service import RecommandationService
        return RecommandationService()

    @pytest.mark.asyncio
    @patch("app.services.recommandation_service.champs_service")
    @patch("app.services.recommandation_service.donnees_agronomiques_svc")
    @patch("app.services.recommandation_service.meteo_service")
    @patch("app.services.recommandation_service.recommandations_svc")
    @patch("app.services.recommandation_service.cultures_service")
    async def test_generer_recommandations_mode_mock(
        self,
        mock_cultures,
        mock_recommandations,
        mock_meteo,
        mock_donnees,
        mock_champs,
        service,
    ):
        """Le service doit retourner des recommandations même sans modèle IA réel."""
        # Arrange
        mock_champs.lire = AsyncMock(return_value={
            "id": "champ1",
            "nom": "Champ Nord",
            "latitude": 14.7,
            "longitude": -17.4,
            "agriculteurId": "agri1",
        })
        mock_donnees.lister = AsyncMock(return_value=[{
            "id": "data1",
            "champId": "champ1",
            "phSol": 6.5,
            "tauxAzote": 50,
            "tauxPhosphore": 40,
            "tauxPotassium": 40,
            "humiditeObservee": 65,
            "dateSaisie": datetime.now(timezone.utc),
        }])
        mock_meteo.get_donnees_actuelles = AsyncMock(return_value={
            "temperature": 28.5,
            "humidite": 65.0,
            "pluviometrie": 0.0,
        })
        mock_cultures.lister = AsyncMock(return_value=[])
        mock_recommandations.creer = AsyncMock(return_value="reco_id_1")

        # Act
        resultat = await service.generer_recommandations("champ1", "agri1", top_k=3)

        # Assert
        assert resultat is not None
        assert len(resultat.topRecommandations) <= 3
        assert resultat.champId == "champ1"
        assert resultat.modeleVersion is not None
        for pred in resultat.topRecommandations:
            assert 0 <= pred.score <= 1
            assert pred.cultureNom != ""
            assert pred.periodePlantation != ""

    @pytest.mark.asyncio
    @patch("app.services.recommandation_service.champs_service")
    async def test_generer_recommandations_champ_inexistant(self, mock_champs, service):
        """Une exception doit être levée si le champ n'existe pas."""
        from app.core.exceptions import ChampNonTrouveException
        mock_champs.lire = AsyncMock(return_value=None)

        with pytest.raises(ChampNonTrouveException):
            await service.generer_recommandations("champ_inexistant", "agri1")

    def test_predire_mock_retourne_resultats(self, service):
        """Le mock de prédiction doit retourner des résultats valides."""
        features = [50, 40, 40, 28, 65, 6.5, 200, 65]
        resultats = service._predire_mock(features)

        assert len(resultats) > 0
        for nom, score in resultats:
            assert isinstance(nom, str)
            assert 0 <= score <= 1

    def test_predire_mock_scores_normalisés(self, service):
        """La somme des scores mockés doit être approximativement 1."""
        features = [50, 40, 40, 28, 65, 6.5, 200, 65]
        resultats = service._predire_mock(features)
        total = sum(score for _, score in resultats)
        assert abs(total - 1.0) < 0.01


class TestRecommandationRouter:
    """Tests des endpoints du router de recommandation."""

    @pytest.fixture
    def client_authentifie(self):
        """Client de test avec authentification mockée."""
        with patch("app.firebase_init.initialiser_firebase"), \
             patch("app.firebase_init.get_firestore", return_value=MagicMock()), \
             patch("app.firebase_init.get_storage_bucket", return_value=MagicMock()):
            from main import app
            from fastapi.testclient import TestClient
            client = TestClient(app)
            return client

    def test_generer_sans_token_retourne_401(self, client_authentifie):
        """L'endpoint doit refuser les requêtes sans token."""
        response = client_authentifie.post("/recommandations/generer/champ1")
        assert response.status_code == 401
