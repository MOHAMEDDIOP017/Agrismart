"""Service d'intégration avec l'API OpenWeatherMap et NASA POWER."""

import logging
from datetime import datetime, timezone
from typing import Optional

import requests

from app.config import settings
from app.core.exceptions import APIMeteoIndisponibleException

logger = logging.getLogger(__name__)

# Timeout des requêtes HTTP en secondes
TIMEOUT_HTTP = 10

# URL de l'API NASA POWER (climatologie à long terme, sans clé API)
NASA_POWER_BASE_URL = "https://power.larc.nasa.gov/api/temporal/climatology/point"

# Jours par mois (année non bissextile)
_JOURS_PAR_MOIS = {
    "JAN": 31, "FEB": 28, "MAR": 31, "APR": 30, "MAY": 31, "JUN": 30,
    "JUL": 31, "AUG": 31, "SEP": 30, "OCT": 31, "NOV": 30, "DEC": 31,
}


class MeteoService:
    """Récupère les données météorologiques depuis OpenWeatherMap."""

    def __init__(self):
        self.base_url = settings.openweather_base_url
        self.api_key = settings.openweather_api_key

    def _construire_params(self, latitude: float, longitude: float) -> dict:
        """Construit les paramètres communs aux appels OpenWeatherMap."""
        return {
            "lat": latitude,
            "lon": longitude,
            "appid": self.api_key,
            "units": "metric",
            "lang": "fr",
        }

    async def get_donnees_actuelles(self, latitude: float, longitude: float) -> dict:
        """
        Récupère les données météo actuelles pour des coordonnées GPS.

        Args:
            latitude: Latitude du champ.
            longitude: Longitude du champ.

        Returns:
            dict avec : temperature, humidite, pluviometrie, vent, description, ville.

        Raises:
            APIMeteoIndisponibleException en cas d'erreur réseau ou d'API.
        """
        if not self.api_key:
            logger.warning("Clé API OpenWeatherMap non configurée — retour de données fictives.")
            return self._donnees_fictives()

        try:
            params = self._construire_params(latitude, longitude)
            reponse = requests.get(
                f"{self.base_url}/weather",
                params=params,
                timeout=TIMEOUT_HTTP,
            )
            reponse.raise_for_status()
            data = reponse.json()

            return {
                "temperature": data["main"]["temp"],
                "temperature_ressentie": data["main"]["feels_like"],
                "temperature_min": data["main"]["temp_min"],
                "temperature_max": data["main"]["temp_max"],
                "humidite": data["main"]["humidity"],
                "pression": data["main"]["pressure"],
                "pluviometrie": data.get("rain", {}).get("1h", 0.0),
                "vitesse_vent": data["wind"]["speed"],
                "direction_vent": data["wind"].get("deg", 0),
                "description": data["weather"][0]["description"] if data.get("weather") else "",
                "ville": data.get("name", ""),
                "horodatage": datetime.now(timezone.utc).isoformat(),
                "source": "openweathermap",
            }
        except requests.exceptions.Timeout:
            logger.warning(f"Timeout API météo pour ({latitude}, {longitude})")
            raise APIMeteoIndisponibleException("L'API météo ne répond pas (timeout).")
        except requests.exceptions.HTTPError as e:
            logger.error(f"Erreur HTTP OpenWeatherMap : {e}")
            raise APIMeteoIndisponibleException(f"Erreur API météo : {e.response.status_code}")
        except requests.exceptions.RequestException as e:
            logger.error(f"Erreur réseau OpenWeatherMap : {e}")
            raise APIMeteoIndisponibleException(f"Erreur réseau : {str(e)}")

    async def get_previsions_jours(
        self, latitude: float, longitude: float, jours: int = 7
    ) -> list[dict]:
        """
        Récupère les prévisions météo sur N jours (max 5 jours via l'API gratuite).

        Args:
            latitude: Latitude du champ.
            longitude: Longitude du champ.
            jours: Nombre de jours de prévision (1-7, limité à 5 par l'API gratuite).

        Returns:
            Liste de dicts avec les prévisions par tranche de 3h, groupées par jour.
        """
        if not self.api_key:
            logger.warning("Clé API OpenWeatherMap non configurée — prévisions fictives.")
            return self._previsions_fictives(jours)

        try:
            params = self._construire_params(latitude, longitude)
            # L'API gratuite fournit des prévisions par tranches de 3h sur 5 jours
            params["cnt"] = min(jours * 8, 40)  # 8 tranches par jour, max 40

            reponse = requests.get(
                f"{self.base_url}/forecast",
                params=params,
                timeout=TIMEOUT_HTTP,
            )
            reponse.raise_for_status()
            data = reponse.json()

            previsions = []
            for item in data.get("list", []):
                previsions.append({
                    "date": item["dt_txt"],
                    "temperature": item["main"]["temp"],
                    "temperature_min": item["main"]["temp_min"],
                    "temperature_max": item["main"]["temp_max"],
                    "humidite": item["main"]["humidity"],
                    "pluviometrie": item.get("rain", {}).get("3h", 0.0),
                    "description": item["weather"][0]["description"] if item.get("weather") else "",
                    "vitesse_vent": item["wind"]["speed"],
                })

            return previsions[:jours * 8]

        except requests.exceptions.RequestException as e:
            logger.error(f"Erreur lors de la récupération des prévisions : {e}")
            raise APIMeteoIndisponibleException(f"Impossible de récupérer les prévisions : {str(e)}")

    async def get_pluviometrie_annuelle(
        self, latitude: float, longitude: float
    ) -> float:
        """
        Retourne la pluviométrie annuelle moyenne (mm/an) via NASA POWER.

        L'API NASA POWER fournit des climatologies à long terme (20 ans+)
        basées sur les données satellitaires. Le paramètre PRECTOTCORR
        donne la précipitation corrigée en mm/jour pour chaque mois.
        On somme : Σ(mois) = valeur_mm_jour × nb_jours_mois.

        C'est la même source que le dataset d'entraînement KoobalaTech_Dataset_2200
        (300 observations réelles NASA POWER + ISRA).

        Returns:
            Pluviométrie annuelle en mm/an.

        Raises:
            APIMeteoIndisponibleException si l'API NASA POWER est indisponible.
        """
        try:
            params = {
                "parameters": "PRECTOTCORR",
                "community": "AG",
                "longitude": round(longitude, 4),
                "latitude": round(latitude, 4),
                "format": "JSON",
                "header": "true",
            }
            reponse = requests.get(
                NASA_POWER_BASE_URL,
                params=params,
                timeout=TIMEOUT_HTTP,
            )
            reponse.raise_for_status()
            data = reponse.json()

            mensuel: dict = (
                data.get("properties", {})
                    .get("parameter", {})
                    .get("PRECTOTCORR", {})
            )

            if not mensuel:
                raise ValueError("Réponse NASA POWER vide ou format inattendu.")

            # Somme mensuelle : mm/jour × nb_jours = mm/mois → total annuel
            total_mm_an = sum(
                mensuel.get(mois, 0.0) * jours
                for mois, jours in _JOURS_PAR_MOIS.items()
            )

            logger.info(
                f"NASA POWER — pluviométrie annuelle ({latitude:.2f}, {longitude:.2f}) : "
                f"{total_mm_an:.1f} mm/an"
            )
            return round(total_mm_an, 1)

        except requests.exceptions.Timeout:
            logger.warning("NASA POWER — timeout, fallback latitude.")
            raise APIMeteoIndisponibleException("NASA POWER ne répond pas (timeout).")
        except requests.exceptions.RequestException as e:
            logger.warning(f"NASA POWER — erreur réseau : {e}")
            raise APIMeteoIndisponibleException(f"NASA POWER indisponible : {e}")
        except Exception as e:
            logger.warning(f"NASA POWER — erreur inattendue : {e}")
            raise APIMeteoIndisponibleException(str(e))

    def _donnees_fictives(self) -> dict:
        """Retourne des données météo fictives pour le Sénégal (développement sans clé API)."""
        return {
            "temperature": 28.5,
            "temperature_ressentie": 30.0,
            "temperature_min": 24.0,
            "temperature_max": 33.0,
            "humidite": 65.0,
            "pression": 1012.0,
            "pluviometrie": 0.0,
            "vitesse_vent": 3.5,
            "direction_vent": 180,
            "description": "ciel dégagé (données fictives - configurez OPENWEATHER_API_KEY)",
            "ville": "Dakar (mock)",
            "horodatage": datetime.now(timezone.utc).isoformat(),
            "source": "mock",
        }

    def _previsions_fictives(self, jours: int) -> list[dict]:
        """Retourne des prévisions fictives pour le développement."""
        from datetime import timedelta
        previsions = []
        base = datetime.now(timezone.utc)
        for i in range(jours):
            for h in range(0, 24, 3):
                previsions.append({
                    "date": (base + timedelta(days=i, hours=h)).strftime("%Y-%m-%d %H:%M:%S"),
                    "temperature": 27 + i * 0.3,
                    "temperature_min": 22.0,
                    "temperature_max": 34.0,
                    "humidite": 60 + i,
                    "pluviometrie": 0.0,
                    "description": "partiellement nuageux (mock)",
                    "vitesse_vent": 3.0,
                })
        return previsions


meteo_service = MeteoService()
