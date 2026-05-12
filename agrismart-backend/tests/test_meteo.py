"""Tests du service météo (OpenWeatherMap)."""

import pytest
from unittest.mock import patch, MagicMock
import requests


class TestMeteoService:
    """Tests du service d'intégration météo."""

    @pytest.fixture
    def service(self):
        """Instance du service météo."""
        from app.services.meteo_service import MeteoService
        return MeteoService()

    @pytest.mark.asyncio
    async def test_donnees_fictives_sans_cle_api(self, service):
        """Sans clé API, des données fictives doivent être retournées."""
        service.api_key = ""
        donnees = await service.get_donnees_actuelles(14.7, -17.4)

        assert "temperature" in donnees
        assert "humidite" in donnees
        assert "pluviometrie" in donnees
        assert donnees["source"] == "mock"

    @pytest.mark.asyncio
    @patch("app.services.meteo_service.requests.get")
    async def test_donnees_actuelles_api_ok(self, mock_get, service):
        """La météo doit être correctement parsée depuis la réponse OpenWeatherMap."""
        service.api_key = "cle_fictive"

        mock_reponse = MagicMock()
        mock_reponse.status_code = 200
        mock_reponse.json.return_value = {
            "main": {
                "temp": 32.5,
                "feels_like": 35.0,
                "temp_min": 28.0,
                "temp_max": 36.0,
                "humidity": 70,
                "pressure": 1008,
            },
            "wind": {"speed": 4.2, "deg": 220},
            "weather": [{"description": "ciel dégagé"}],
            "rain": {"1h": 0.0},
            "name": "Dakar",
        }
        mock_reponse.raise_for_status = MagicMock()
        mock_get.return_value = mock_reponse

        donnees = await service.get_donnees_actuelles(14.7, -17.4)

        assert donnees["temperature"] == 32.5
        assert donnees["humidite"] == 70
        assert donnees["ville"] == "Dakar"
        assert donnees["source"] == "openweathermap"

    @pytest.mark.asyncio
    @patch("app.services.meteo_service.requests.get")
    async def test_timeout_leve_exception(self, mock_get, service):
        """Un timeout doit lever APIMeteoIndisponibleException."""
        from app.core.exceptions import APIMeteoIndisponibleException
        service.api_key = "cle_fictive"
        mock_get.side_effect = requests.exceptions.Timeout()

        with pytest.raises(APIMeteoIndisponibleException):
            await service.get_donnees_actuelles(14.7, -17.4)

    @pytest.mark.asyncio
    async def test_previsions_fictives_sans_cle_api(self, service):
        """Sans clé API, des prévisions fictives doivent être retournées."""
        service.api_key = ""
        previsions = await service.get_previsions_jours(14.7, -17.4, jours=3)

        assert len(previsions) > 0
        for p in previsions:
            assert "date" in p
            assert "temperature" in p
            assert "humidite" in p

    @pytest.mark.asyncio
    @patch("app.services.meteo_service.requests.get")
    async def test_erreur_http_leve_exception(self, mock_get, service):
        """Une erreur HTTP 401 (clé invalide) doit lever APIMeteoIndisponibleException."""
        from app.core.exceptions import APIMeteoIndisponibleException
        service.api_key = "cle_invalide"

        mock_reponse = MagicMock()
        mock_reponse.status_code = 401
        mock_reponse.raise_for_status.side_effect = requests.exceptions.HTTPError(
            response=mock_reponse
        )
        mock_get.return_value = mock_reponse

        with pytest.raises(APIMeteoIndisponibleException):
            await service.get_donnees_actuelles(14.7, -17.4)
