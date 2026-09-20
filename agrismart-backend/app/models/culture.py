"""Modèles Pydantic pour les cultures agricoles."""

from typing import Optional
from pydantic import BaseModel, Field


class CultureBase(BaseModel):
    """Données de référence d'une culture agricole."""
    nom: str = Field(..., max_length=100, description="Ex: Mil, Arachide, Niébé")
    nomWolof: str = Field(..., max_length=100, description="Ex: dugub, gerte, ñebbe")
    variete: str = Field(..., max_length=100)
    cycleMaturation: int = Field(..., gt=0, description="Durée du cycle en jours")
    besoinsHydriques: str = Field(..., max_length=200)
    rendementMoyen: float = Field(..., gt=0, description="Rendement moyen en t/ha")
    # Conditions optimales du sol
    phOptimal: float = Field(..., ge=0, le=14)
    nOptimal: float = Field(..., ge=0)
    pOptimal: float = Field(..., ge=0)
    kOptimal: float = Field(..., ge=0)
    # Conditions climatiques
    tempMin: float = Field(..., description="Température minimale en °C")
    tempMax: float = Field(..., description="Température maximale en °C")
    humiditeMin: float = Field(..., ge=0, le=100)
    humiditeMax: float = Field(..., ge=0, le=100)
    # Économie
    prixMoyenMarche: float = Field(..., ge=0, description="Prix moyen en FCFA/kg")


class CultureCreate(CultureBase):
    pass


class CultureUpdate(BaseModel):
    """Mise à jour partielle d'une culture."""
    variete: Optional[str] = None
    cycleMaturation: Optional[int] = Field(None, gt=0)
    rendementMoyen: Optional[float] = Field(None, gt=0)
    prixMoyenMarche: Optional[float] = Field(None, ge=0)
    besoinsHydriques: Optional[str] = None


class CultureResponse(CultureBase):
    """Réponse complète d'une culture."""
    id: str

    class Config:
        from_attributes = True


class CultureCompatible(BaseModel):
    """Culture compatible avec un champ donné, avec score de compatibilité."""
    culture: CultureResponse
    scoreCompatibilite: float = Field(..., ge=0, le=1)
    raisonsCompatibilite: list[str]
    avertissements: list[str] = []
