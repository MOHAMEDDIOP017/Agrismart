"""Modèles Pydantic pour les recommandations post-récolte."""

from datetime import datetime
from pydantic import BaseModel, Field

from app.models.enums import TypeRecommandationPostRecolte


class RecommandationPostRecolteBase(BaseModel):
    """Données de base d'une recommandation post-récolte."""
    recommandationCultureId: str = Field(..., description="Référence RecommandationCulture")
    typeRec: TypeRecommandationPostRecolte
    score: float = Field(..., ge=0, le=1)
    prixVenteEstime: float = Field(..., ge=0, description="Prix estimé en FCFA")
    coutTransformation: float = Field(default=0.0, ge=0, description="Coût en FCFA")
    profitPotentiel: float = Field(..., description="Profit estimé en FCFA")


class RecommandationPostRecolteCreate(RecommandationPostRecolteBase):
    pass


class RecommandationPostRecolteResponse(RecommandationPostRecolteBase):
    """Réponse complète d'une recommandation post-récolte."""
    id: str
    date: datetime

    class Config:
        from_attributes = True
