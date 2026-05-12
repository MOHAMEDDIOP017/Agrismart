"""Modèles Pydantic pour l'historique des activités."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class HistoriqueActiviteBase(BaseModel):
    """Données de base d'une entrée d'historique."""
    utilisateurId: str
    typeAction: str = Field(..., max_length=100)
    description: str = Field(..., max_length=500)
    referenceId: Optional[str] = None
    details: dict = Field(default_factory=dict)


class HistoriqueActiviteCreate(HistoriqueActiviteBase):
    pass


class HistoriqueActiviteResponse(HistoriqueActiviteBase):
    """Réponse complète d'une entrée d'historique."""
    id: str
    dateAction: datetime

    class Config:
        from_attributes = True
