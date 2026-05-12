"""Modèles Pydantic pour les diagnostics de maladies (Module IA 2)."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

from app.models.enums import StatutValidation


class DiagnosticMaladieBase(BaseModel):
    """Données de base d'un diagnostic de maladie."""
    imageId: str
    agriculteurId: str
    champId: Optional[str] = None
    seuilConfiance: float = Field(default=0.7, ge=0, le=1)


class DiagnosticMaladieCreate(DiagnosticMaladieBase):
    """Données enregistrées après analyse IA."""
    maladieId: Optional[str] = None
    scoreConfiance: float = Field(..., ge=0, le=1)
    topPredictions: list[dict] = Field(
        ..., description='Ex: [{"maladie": "Mildiou", "probabilite": 0.87}]'
    )
    modeleVersion: str
    statut: StatutValidation = StatutValidation.EN_ATTENTE


class DiagnosticMaladieResponse(DiagnosticMaladieBase):
    """Réponse complète d'un diagnostic de maladie."""
    id: str
    maladieId: Optional[str] = None
    scoreConfiance: float
    topPredictions: list[dict]
    modeleVersion: str
    dateAnalyse: datetime
    statut: StatutValidation
    expertId: Optional[str] = None
    commentaireExpert: Optional[str] = None
    evaluationAgriculteur: Optional[int] = Field(None, ge=1, le=5)

    class Config:
        from_attributes = True


class ValidationDiagnostic(BaseModel):
    """Corps de la requête de validation par un expert."""
    maladieId: str
    commentaireExpert: str = Field(..., min_length=10, max_length=2000)
    confirmerDiagnostic: bool = True


class CorrectionDiagnostic(BaseModel):
    """Corps de la requête de correction par un expert."""
    maladieIdCorrecte: str
    commentaireExpert: str = Field(..., min_length=10, max_length=2000)


class EvaluationDiagnostic(BaseModel):
    """Évaluation de la qualité du diagnostic par l'agriculteur."""
    note: int = Field(..., ge=1, le=5, description="Note de 1 à 5 étoiles")
    commentaire: Optional[str] = Field(None, max_length=500)


class ResultatAnalyseIA(BaseModel):
    """Résultat complet renvoyé après analyse IA d'une image."""
    diagnosticId: str
    imageId: str
    maladieDetectee: Optional[str] = None
    scoreConfiance: float
    topPredictions: list[dict]
    statut: StatutValidation
    traitementRecommandeId: Optional[str] = None
    alerteEnvoyee: bool = False
    modeleVersion: str
    dateAnalyse: datetime
