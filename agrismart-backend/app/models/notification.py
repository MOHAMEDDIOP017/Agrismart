"""Modèles Pydantic pour les notifications push FCM."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

from app.models.enums import TypeNotification


class NotificationBase(BaseModel):
    """Données de base d'une notification."""
    destinataireId: str
    type: TypeNotification
    titre: str = Field(..., max_length=200)
    corps: str = Field(..., max_length=1000)
    referenceId: Optional[str] = Field(None, description="ID de la ressource liée")
    urgent: bool = False


class NotificationCreate(NotificationBase):
    pass


class NotificationResponse(NotificationBase):
    """Réponse complète d'une notification."""
    id: str
    dateEnvoi: datetime
    lu: bool = False
    dateLecture: Optional[datetime] = None

    class Config:
        from_attributes = True


class EnvoiNotificationRequest(BaseModel):
    """Corps de la requête pour envoyer une notification manuellement."""
    destinataireId: str
    type: TypeNotification
    titre: str = Field(..., max_length=200)
    corps: str = Field(..., max_length=1000)
    referenceId: Optional[str] = None
    urgent: bool = False
    fcmToken: Optional[str] = Field(None, description="Token FCM du destinataire")
