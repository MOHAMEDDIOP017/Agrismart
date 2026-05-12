"""Modèles Pydantic pour l'association Culture-Champ."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

from app.models.enums import StatutCulture


class CultureEnChampBase(BaseModel):
    """Données de base d'une culture plantée dans un champ."""
    champId: str = Field(..., description="Référence Firestore du champ")
    cultureId: str = Field(..., description="Référence Firestore de la culture")
    dateDebut: datetime
    dateFinPrevue: datetime
    statut: StatutCulture = StatutCulture.PREVU


class CultureEnChampCreate(CultureEnChampBase):
    pass


class CultureEnChampUpdate(BaseModel):
    """Mise à jour d'une culture en cours."""
    statut: Optional[StatutCulture] = None
    dateFinPrevue: Optional[datetime] = None
    dateFinReelle: Optional[datetime] = None
    rendementReel: Optional[float] = Field(None, ge=0, description="Rendement réel en t/ha")


class CultureEnChampResponse(CultureEnChampBase):
    """Réponse complète d'une culture en champ."""
    id: str
    dateFinReelle: Optional[datetime] = None
    rendementReel: Optional[float] = None

    class Config:
        from_attributes = True
