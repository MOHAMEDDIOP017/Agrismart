"""Modèles Pydantic pour les maladies des plantes."""

from typing import Optional
from pydantic import BaseModel, Field

from app.models.enums import NiveauGravite


class MaladieBase(BaseModel):
    """Données de référence d'une maladie végétale."""
    nom: str = Field(..., max_length=200)
    nomScientifique: str = Field(..., max_length=300)
    symptomes: list[str] = Field(..., min_length=1)
    culturesAffectees: list[str] = Field(..., min_length=1)
    gravite: NiveauGravite
    facteurFavorisant: str = Field(..., max_length=500)
    imagesReference: list[str] = Field(default=[])
    descriptionComplete: str = Field(..., max_length=5000)


class MaladieCreate(MaladieBase):
    pass


class MaladieUpdate(BaseModel):
    """Mise à jour partielle d'une maladie (expert)."""
    symptomes: Optional[list[str]] = None
    culturesAffectees: Optional[list[str]] = None
    gravite: Optional[NiveauGravite] = None
    facteurFavorisant: Optional[str] = None
    imagesReference: Optional[list[str]] = None
    descriptionComplete: Optional[str] = None


class MaladieResponse(MaladieBase):
    """Réponse complète d'une maladie."""
    id: str

    class Config:
        from_attributes = True
