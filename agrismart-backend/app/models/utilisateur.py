"""Modèles Pydantic pour les utilisateurs d'AgriSmart."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field

from app.models.enums import RoleUtilisateur


# ─── Modèles de base ─────────────────────────────────────────────────────────

class UtilisateurBase(BaseModel):
    """Champs communs à tous les types d'utilisateurs."""
    nom: str = Field(..., min_length=2, max_length=100)
    prenom: str = Field(..., min_length=2, max_length=100)
    email: str = Field(..., description="Adresse email unique")
    telephone: str = Field(..., max_length=20)
    role: RoleUtilisateur
    actif: bool = True


class UtilisateurCreate(UtilisateurBase):
    """Données requises pour créer un utilisateur (admin)."""
    pass


class UtilisateurUpdate(BaseModel):
    """Champs modifiables d'un utilisateur."""
    nom: Optional[str] = Field(None, min_length=2, max_length=100)
    prenom: Optional[str] = Field(None, min_length=2, max_length=100)
    telephone: Optional[str] = Field(None, max_length=20)
    actif: Optional[bool] = None


class UtilisateurResponse(UtilisateurBase):
    """Réponse complète renvoyée au client."""
    id: str
    dateInscription: datetime

    class Config:
        from_attributes = True


# ─── Agriculteur ─────────────────────────────────────────────────────────────

class AgriculteurBase(UtilisateurBase):
    """Champs spécifiques à un agriculteur."""
    role: RoleUtilisateur = RoleUtilisateur.AGRICULTEUR
    zoneGeographique: str = Field(..., max_length=200)
    adresse: str = Field(..., max_length=300)
    villageVille: str = Field(..., max_length=100)


class AgriculteurCreate(AgriculteurBase):
    pass


class AgriculteurUpdate(UtilisateurUpdate):
    zoneGeographique: Optional[str] = None
    adresse: Optional[str] = None
    villageVille: Optional[str] = None


class AgriculteurResponse(AgriculteurBase):
    id: str
    dateInscription: datetime

    class Config:
        from_attributes = True


# ─── Expert ──────────────────────────────────────────────────────────────────

class ExpertBase(UtilisateurBase):
    """Champs spécifiques à un expert agricole."""
    role: RoleUtilisateur = RoleUtilisateur.EXPERT
    regionCouverture: str = Field(..., max_length=200)
    specialite: str = Field(..., max_length=200)
    anneesExperience: int = Field(..., ge=0, le=60)
    nbDiagnosticsValides: int = Field(default=0, ge=0)
    tauxPrecisionValidee: float = Field(default=0.0, ge=0.0, le=1.0)


class ExpertCreate(ExpertBase):
    pass


class ExpertUpdate(UtilisateurUpdate):
    regionCouverture: Optional[str] = None
    specialite: Optional[str] = None
    anneesExperience: Optional[int] = Field(None, ge=0, le=60)


class ExpertResponse(ExpertBase):
    id: str
    dateInscription: datetime

    class Config:
        from_attributes = True


# ─── Administrateur ──────────────────────────────────────────────────────────

class AdministrateurBase(UtilisateurBase):
    """Champs spécifiques à un administrateur."""
    role: RoleUtilisateur = RoleUtilisateur.ADMIN
    niveauAcces: int = Field(..., ge=1, le=10)
    dateCreation: datetime


class AdministrateurCreate(AdministrateurBase):
    pass


class AdministrateurResponse(AdministrateurBase):
    id: str
    dateInscription: datetime

    class Config:
        from_attributes = True
