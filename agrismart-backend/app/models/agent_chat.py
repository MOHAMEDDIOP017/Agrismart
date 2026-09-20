"""
Modèles Pydantic pour l'agent conversationnel IA (chat bilingue FR/Wolof).

Historique désormais autoritaire côté serveur (persisté comme `MessageChat`,
diagramme UML) : le client n'envoie plus l'historique complet à chaque
appel, seulement le `conversationId` du fil en cours (absent au premier
message, généré par le serveur et renvoyé au client).
"""

from typing import Optional
from pydantic import BaseModel, Field


class RequeteChat(BaseModel):
    """Requête envoyée par l'app Flutter à POST /agent/chat."""
    message: str = Field(..., min_length=1, description="Message de l'utilisateur (français ou wolof)")
    conversationId: Optional[str] = Field(
        None,
        description="Fil de discussion existant. Omis pour démarrer une nouvelle conversation.",
    )


class OutilUtilise(BaseModel):
    """Trace d'un appel d'outil effectué par l'agent pour construire sa réponse."""
    outil: str
    arguments: dict


class ReponseChat(BaseModel):
    """Réponse de l'agent."""
    conversationId: str
    reponse: str
    outilsUtilises: list[OutilUtilise] = Field(default_factory=list)
