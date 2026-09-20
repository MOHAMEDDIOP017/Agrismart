"""Modèles Pydantic pour `MessageChat` (diagramme UML) — persistance de l'agent conversationnel."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

from app.models.enums import RoleMessage


class MessageChatBase(BaseModel):
    """Un message persisté d'un fil de conversation avec l'agent AgriSmart."""
    conversationId: str = Field(..., description="Regroupe les messages d'un même fil de discussion")
    agriculteurId: str
    emetteur: RoleMessage
    contenu: str
    langue: str = Field(default="fr", description="'fr' ou 'wo' (détection heuristique)")
    outilAppele: Optional[str] = Field(
        None, description="Nom de l'outil function-calling appelé pour produire ce message, si applicable"
    )
    dateEnvoi: datetime


class MessageChatResponse(MessageChatBase):
    id: str

    class Config:
        from_attributes = True
