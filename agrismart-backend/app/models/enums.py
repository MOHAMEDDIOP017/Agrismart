"""Énumérations utilisées dans les modèles Pydantic d'AgriSmart."""

from enum import Enum


class RoleUtilisateur(str, Enum):
    """Rôles des utilisateurs de l'application."""
    AGRICULTEUR = "AGRICULTEUR"
    EXPERT = "EXPERT"
    ADMIN = "ADMIN"


class StatutCulture(str, Enum):
    """Statut d'une culture en cours dans un champ."""
    PREVU = "PREVU"
    EN_COURS = "EN_COURS"
    RECOLTE = "RECOLTE"
    EN_TRAITEMENT = "EN_TRAITEMENT"
    ABANDONNE = "ABANDONNE"


class StatutValidation(str, Enum):
    """Statut de validation d'un diagnostic de maladie."""
    EN_ATTENTE = "EN_ATTENTE"
    VALIDE_EXPERT = "VALIDE_EXPERT"
    REJETE = "REJETE"
    AUTO_CONFIRME = "AUTO_CONFIRME"


class NiveauGravite(str, Enum):
    """Niveau de gravité d'une maladie."""
    FAIBLE = "FAIBLE"
    MODERE = "MODERE"
    ELEVE = "ELEVE"
    CRITIQUE = "CRITIQUE"


class TypeTraitement(str, Enum):
    """Type d'un traitement recommandé."""
    CHIMIQUE = "CHIMIQUE"
    BIOLOGIQUE = "BIOLOGIQUE"
    PREVENTIF = "PREVENTIF"
    CURATIF = "CURATIF"


class TypeNotification(str, Enum):
    """Type d'une notification push FCM."""
    ALERTE_MALADIE = "ALERTE_MALADIE"
    RECOMMANDATION = "RECOMMANDATION"
    CONSEIL_EXPERT = "CONSEIL_EXPERT"
    VALIDATION_DIAGNOSTIC = "VALIDATION_DIAGNOSTIC"
    INTERVENTION_PLANIFIEE = "INTERVENTION_PLANIFIEE"


class TypeIntervention(str, Enum):
    """Type d'une intervention d'expert."""
    DIAGNOSTIC = "DIAGNOSTIC"
    TRAITEMENT = "TRAITEMENT"
    CONSEIL = "CONSEIL"
    SUIVI = "SUIVI"
    URGENCE = "URGENCE"


class StatutIntervention(str, Enum):
    """Statut d'une intervention planifiée."""
    PLANIFIEE = "PLANIFIEE"
    EN_COURS = "EN_COURS"
    REALISEE = "REALISEE"
    ANNULEE = "ANNULEE"


class TypeConseil(str, Enum):
    """Catégorie d'un conseil donné par un expert."""
    CULTURE = "CULTURE"
    TRAITEMENT = "TRAITEMENT"
    IRRIGATION = "IRRIGATION"
    RECOLTE = "RECOLTE"
    FERTILISATION = "FERTILISATION"
    AUTRE = "AUTRE"


class TypeRecommandationPostRecolte(str, Enum):
    """Type de recommandation post-récolte."""
    VENTE_BRUTE = "VENTE_BRUTE"
    TRANSFORMATION = "TRANSFORMATION"
