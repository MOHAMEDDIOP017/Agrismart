"""Énumérations utilisées dans les modèles Pydantic d'KoobalaTech."""

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


class TypeNotification(str, Enum):
    """Type d'une notification push FCM."""
    RECOMMANDATION = "RECOMMANDATION"
    CONSEIL_EXPERT = "CONSEIL_EXPERT"
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


class StatutValidation(str, Enum):
    """Statut de validation d'une RecommandationCulture par un expert (diagramme UML)."""
    EN_ATTENTE = "EN_ATTENTE"
    VALIDEE = "VALIDEE"
    CORRIGEE = "CORRIGEE"
    REJETEE = "REJETEE"


class RoleMessage(str, Enum):
    """Émetteur d'un MessageChat (diagramme UML)."""
    UTILISATEUR = "UTILISATEUR"
    AGENT = "AGENT"
