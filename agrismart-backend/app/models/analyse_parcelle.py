"""
Modèles Pydantic pour `AnalyseParcelle` (diagramme UML).

Remplace `DonneesAgronomiques` (saisie manuelle, supprimée) : les 16
variables sol/climat/NDVI sont désormais collectées automatiquement
(SoilGrids, NASA POWER, moyenne de zone) par `app/services/agroeco_zones.py`
et persistées ici, une fois par génération de recommandation. Chaque
AnalyseParcelle porte ensuite 1 à 3 `RecommandationCulture` (top-3).
"""

from datetime import datetime
from pydantic import BaseModel, Field


class AnalyseParcelleBase(BaseModel):
    """Les 16 variables du modèle multi-label, collectées pour un champ à un instant T."""
    champId: str
    dateAnalyse: datetime

    # Sol (SoilGrids ou moyenne de zone)
    nTotal_g_kg: float
    pExtractible_ppm: float
    kExtractible_ppm: float
    phEau: float
    argile_pct: float
    sable_pct: float
    limon_pct: float
    carboneOrganique: float

    # Climat (NASA POWER ou moyenne de zone)
    temperatureMoy: float
    temperatureMaxMois: float
    temperatureMinMois: float
    humiditeMoy: float
    pluieAnnuelle: float
    pluieHivernage: float

    # Végétation (moyenne de zone)
    ndviMoyenAnnuel: float
    ndviHivernage: float

    # Traçabilité : quelle source a fourni chaque groupe de variables
    # (ex : "sol=SoilGrids (temps réel), climat=NASA POWER (temps réel), ...")
    sourceDonnees: str


class AnalyseParcelleResponse(AnalyseParcelleBase):
    id: str

    class Config:
        from_attributes = True
