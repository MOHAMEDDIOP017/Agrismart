"""Modèles Pydantic pour les traitements recommandés."""

from typing import Optional
from pydantic import BaseModel, Field

from app.models.enums import TypeTraitement


class TraitementRecommandeBase(BaseModel):
    """Données de base d'un traitement recommandé pour une maladie."""
    maladieId: str = Field(..., description="Référence Firestore de la maladie")
    diagnosticId: Optional[str] = Field(None, description="Référence du diagnostic associé")
    nomProduit: str = Field(..., max_length=200)
    dosage: str = Field(..., max_length=100, description="Ex: 2L/ha")
    frequenceApplication: str = Field(..., max_length=200)
    dureeJours: int = Field(..., gt=0)
    type: TypeTraitement
    coutEstimeFCFA: float = Field(..., ge=0)
    proposeParExpert: bool = False
    expertId: Optional[str] = None


class TraitementRecommandeCreate(TraitementRecommandeBase):
    pass


class TraitementRecommandeUpdate(BaseModel):
    """Mise à jour partielle d'un traitement."""
    dosage: Optional[str] = None
    frequenceApplication: Optional[str] = None
    dureeJours: Optional[int] = Field(None, gt=0)
    coutEstimeFCFA: Optional[float] = Field(None, ge=0)


class TraitementRecommandeResponse(TraitementRecommandeBase):
    """Réponse complète d'un traitement recommandé."""
    id: str

    class Config:
        from_attributes = True
