"""Tests d'authentification Firebase."""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi.testclient import TestClient


# ─── Fixtures ────────────────────────────────────────────────────────────────

@pytest.fixture
def mock_firebase():
    """Mock des services Firebase pour les tests."""
    with patch("app.firebase_init.initialiser_firebase") as mock_init, \
         patch("app.firebase_init.get_firestore") as mock_fs, \
         patch("app.firebase_init.get_storage_bucket") as mock_bucket:

        mock_init.return_value = None
        mock_fs.return_value = MagicMock()
        mock_bucket.return_value = MagicMock()
        yield mock_init, mock_fs, mock_bucket


@pytest.fixture
def client(mock_firebase):
    """Client de test FastAPI avec Firebase mocké."""
    from main import app
    return TestClient(app)


# ─── Tests ───────────────────────────────────────────────────────────────────

class TestHealthCheck:
    """Tests des endpoints de santé."""

    def test_racine_retourne_200(self, client):
        """L'endpoint racine doit retourner 200 OK."""
        response = client.get("/")
        assert response.status_code == 200

    def test_racine_contient_nom_application(self, client):
        """La réponse racine doit contenir le nom de l'application."""
        response = client.get("/")
        data = response.json()
        assert "application" in data
        assert "AgriSmart" in data["application"]

    def test_health_check_retourne_ok(self, client):
        """L'endpoint /health doit retourner statut ok."""
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["statut"] == "ok"


class TestVerifyToken:
    """Tests de vérification du token Firebase."""

    @patch("app.core.security.verifier_token_firebase")
    @patch("app.services.auth_service.AuthService.verifier_ou_creer_utilisateur")
    def test_verify_token_valide(self, mock_creer, mock_verifier, client):
        """Un token valide doit retourner un profil utilisateur."""
        mock_verifier.return_value = {
            "uid": "uid123",
            "email": "test@agrismart.sn",
            "role": "AGRICULTEUR",
        }
        mock_creer.return_value = {
            "id": "uid123",
            "email": "test@agrismart.sn",
            "nom": "Diop",
            "prenom": "Mamadou",
            "role": "AGRICULTEUR",
            "actif": True,
        }

        response = client.post(
            "/auth/verify-token",
            headers={"Authorization": "Bearer token_fictif"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "utilisateur" in data

    def test_verify_token_sans_header_retourne_401(self, client):
        """Une requête sans token doit retourner 401."""
        response = client.post("/auth/verify-token")
        assert response.status_code == 401

    @patch("app.core.security.verifier_token_firebase")
    def test_verify_token_invalide_retourne_401(self, mock_verifier, client):
        """Un token invalide doit retourner 401."""
        from app.core.exceptions import AuthentificationEchoueeException
        mock_verifier.side_effect = AuthentificationEchoueeException("Token invalide")

        response = client.post(
            "/auth/verify-token",
            headers={"Authorization": "Bearer token_invalide"},
        )
        assert response.status_code == 401
