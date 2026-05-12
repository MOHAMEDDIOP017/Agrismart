"""Modèles Pydantic pour les recommandations de cultures (Module IA 1)."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class PredictionCulture(BaseModel):
    """Une prédiction individuelle du modèle SVM."""
    cultureNom: str
    cultureId: Optional[str] = None
    score: float = Field(..., ge=0, le=1, description="Probabilité prédite")
    periodePlantation: str
    rendementEstime: float = Field(..., ge=0)
    conseil: str
    besoinEauMm: int = Field(default=400, description="Besoin en eau (mm/saison)")
    prixMarcheEstime: int = Field(default=200, description="Prix marché estimé (FCFA/kg)")
    engraisConseilles: list[str] = Field(default_factory=list)
    maladiesFrequentes: list[str] = Field(default_factory=list)


class RecommandationCultureBase(BaseModel):
    """Données de base d'une recommandation de culture."""
    champId: str
    cultureRecommandeeId: str
    score: float = Field(..., ge=0, le=1)
    periodePlantation: str
    rendementEstime: float = Field(..., ge=0)
    modeleVersion: str
    conseil: str
    type: str = Field(default="AUTOMATIQUE", pattern="^(AUTOMATIQUE|EXPERT)$")


class RecommandationCultureCreate(RecommandationCultureBase):
    pass


class RecommandationCultureResponse(RecommandationCultureBase):
    """Réponse complète d'une recommandation de culture."""
    id: str
    date: datetime

    class Config:
        from_attributes = True


class ResultatRecommandation(BaseModel):
    """Résultat complet renvoyé après exécution du moteur IA."""
    champId: str
    topRecommandations: list[PredictionCulture]
    donneesMeteoUtilisees: dict
    donneesAgronomiquesUtilisees: dict
    modeleVersion: str
    dateAnalyse: datetime
    recommandationsSauvegardees: list[str] = Field(
        default=[], description="IDs Firestore des recommandations créées"
    )
