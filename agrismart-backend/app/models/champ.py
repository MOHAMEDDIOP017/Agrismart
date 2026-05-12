"""Modèles Pydantic pour les champs agricoles."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class ChampBase(BaseModel):
    """Données de base d'un champ agricole."""
    nom: str = Field(..., min_length=2, max_length=200)
    superficie: float = Field(..., gt=0, description="Superficie en hectares")
    typeSol: str = Field(..., max_length=100)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    adresse: str = Field(..., max_length=300)
    commentaire: Optional[str] = Field(None, max_length=500)


class ChampCreate(ChampBase):
    """Données pour créer un champ (agriculteurId injecté via token)."""
    pass


class ChampUpdate(BaseModel):
    """Champs modifiables d'un champ agricole."""
    nom: Optional[str] = Field(None, min_length=2, max_length=200)
    superficie: Optional[float] = Field(None, gt=0)
    typeSol: Optional[str] = Field(None, max_length=100)
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    adresse: Optional[str] = Field(None, max_length=300)
    commentaire: Optional[str] = None


class ChampResponse(ChampBase):
    """Réponse complète d'un champ."""
    id: str
    agriculteurId: str
    photoUrl: Optional[str] = None
    dateCreation: datetime

    class Config:
        from_attributes = True


class ScoreSanteChamp(BaseModel):
    """Score de santé calculé pour un champ."""
    champId: str
    score: float = Field(..., ge=0, le=100, description="Score de santé de 0 à 100")
    interpretation: str
    dernierDiagnostic: Optional[datetime] = None
    nbMaladiesDetectees: int = 0
    nbRecommandationsActives: int = 0
