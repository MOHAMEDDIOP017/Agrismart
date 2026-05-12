"""Modèles Pydantic pour les données agronomiques d'un champ."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class DonneesAgronomiquesBase(BaseModel):
    """Mesures agronomiques relevées sur un champ."""
    phSol: float = Field(..., ge=0, le=14, description="pH du sol")
    tauxAzote: float = Field(..., ge=0, description="Azote (N) en kg/ha")
    tauxPhosphore: float = Field(..., ge=0, description="Phosphore (P) en kg/ha")
    tauxPotassium: float = Field(..., ge=0, description="Potassium (K) en kg/ha")
    humiditeObservee: float = Field(..., ge=0, le=100, description="Humidité sol en %")
    observations: Optional[str] = Field(None, max_length=1000)


class DonneesAgronomiquesCreate(DonneesAgronomiquesBase):
    """Données requises pour saisir de nouvelles mesures."""
    champId: str = Field(..., description="Référence Firestore du champ")


class DonneesAgronomiquesUpdate(BaseModel):
    """Mise à jour partielle des données agronomiques."""
    phSol: Optional[float] = Field(None, ge=0, le=14)
    tauxAzote: Optional[float] = Field(None, ge=0)
    tauxPhosphore: Optional[float] = Field(None, ge=0)
    tauxPotassium: Optional[float] = Field(None, ge=0)
    humiditeObservee: Optional[float] = Field(None, ge=0, le=100)
    observations: Optional[str] = None


class DonneesAgronomiquesResponse(DonneesAgronomiquesBase):
    """Réponse complète des données agronomiques."""
    id: str
    champId: str
    dateSaisie: datetime

    class Config:
        from_attributes = True


class EvolutionAgronomique(BaseModel):
    """Série temporelle des données agronomiques pour un champ."""
    champId: str
    periodeDebut: datetime
    periodeFin: datetime
    donnees: list[DonneesAgronomiquesResponse]
    tendancePh: float = Field(..., description="Variation moyenne du pH sur la période")
    tendanceHumidite: float = Field(..., description="Variation moyenne de l'humidité")
