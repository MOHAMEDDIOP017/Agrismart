"""Modèles Pydantic pour les conseils d'experts."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

from app.models.enums import TypeConseil


class ConseilBase(BaseModel):
    """Données de base d'un conseil envoyé par un expert."""
    expertId: str
    agriculteurId: str
    champId: Optional[str] = None
    typeConseil: TypeConseil
    titre: str = Field(..., min_length=5, max_length=200)
    contenu: str = Field(..., min_length=20, max_length=5000)
    urgent: bool = False
    pieceJointeUrl: Optional[str] = None


class ConseilCreate(ConseilBase):
    pass


class ConseilUpdate(BaseModel):
    """Mise à jour partielle d'un conseil."""
    titre: Optional[str] = Field(None, min_length=5, max_length=200)
    contenu: Optional[str] = Field(None, min_length=20, max_length=5000)
    urgent: Optional[bool] = None


class ConseilResponse(ConseilBase):
    """Réponse complète d'un conseil."""
    id: str
    dateEnvoi: datetime
    lu: bool = False

    class Config:
        from_attributes = True
