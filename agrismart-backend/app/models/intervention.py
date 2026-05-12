"""Modèles Pydantic pour les interventions d'experts."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

from app.models.enums import TypeIntervention, StatutIntervention


class InterventionBase(BaseModel):
    """Données de base d'une intervention d'expert sur un champ."""
    champId: str
    expertId: str
    agriculteurId: str
    typeIntervention: TypeIntervention
    description: str = Field(..., min_length=10, max_length=2000)
    dateInterventionPrevue: datetime
    dureeEstimeeHeures: float = Field(..., gt=0)
    materielNecessaire: list[str] = Field(default=[])
    statut: StatutIntervention = StatutIntervention.PLANIFIEE


class InterventionCreate(InterventionBase):
    pass


class InterventionUpdate(BaseModel):
    """Mise à jour partielle d'une intervention."""
    description: Optional[str] = Field(None, min_length=10, max_length=2000)
    dateInterventionPrevue: Optional[datetime] = None
    dureeEstimeeHeures: Optional[float] = Field(None, gt=0)
    materielNecessaire: Optional[list[str]] = None
    statut: Optional[StatutIntervention] = None
    rapportIntervention: Optional[str] = Field(None, max_length=5000)


class InterventionResponse(InterventionBase):
    """Réponse complète d'une intervention."""
    id: str
    rapportIntervention: Optional[str] = None

    class Config:
        from_attributes = True
