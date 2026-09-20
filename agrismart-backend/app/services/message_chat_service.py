"""
Service de persistance de `MessageChat` (diagramme UML).

Sépare la persistance (Firestore) de la logique LLM pure (`agent_service.py`,
qui reste sans dépendance Firestore). Le router `app/routers/agent.py`
orchestre les deux : il lit l'historique d'une conversation ici, appelle
`agent_service.chat()`, puis persiste le nouvel échange.
"""

import logging
import re
from datetime import datetime, timezone

from app.models.enums import RoleMessage
from app.services.firestore_service import messages_chat_svc

logger = logging.getLogger(__name__)

# Détection de langue heuristique (pas de dépendance NLP dans le projet) :
# quelques mots-outils wolof à forte spécificité, peu susceptibles
# d'apparaître dans une phrase française. Best-effort, pas une détection
# linguistique rigoureuse — suffisant pour tracer `MessageChat.langue`.
_MARQUEURS_WOLOF = [
    "naka", "nanga", "jàmm", "jamm", "waaw", "deedeet", "dangay", "dama",
    "mangi", "yaangi", "ndax", "dëgg", "bàyyi", "liggéey", "mbay", "dañu",
    "lañu", "ñu ngi", "bu baax", "nit ñi", "sama ", "sa xarit",
]


def detecter_langue(texte: str) -> str:
    """Retourne 'wo' si un marqueur wolof est détecté, sinon 'fr' par défaut."""
    texte_normalise = texte.lower()
    if any(marqueur in texte_normalise for marqueur in _MARQUEURS_WOLOF):
        return "wo"
    return "fr"


async def persister(
    conversation_id: str,
    agriculteur_id: str,
    emetteur: RoleMessage,
    contenu: str,
    outil_appele: str | None = None,
) -> str:
    """Sauvegarde un MessageChat et retourne son id Firestore."""
    doc = {
        "conversationId": conversation_id,
        "agriculteurId": agriculteur_id,
        "emetteur": emetteur.value,
        "contenu": contenu,
        "langue": detecter_langue(contenu),
        "outilAppele": outil_appele,
        "dateEnvoi": datetime.now(timezone.utc),
    }
    return await messages_chat_svc.creer(doc)


async def lister_conversation(conversation_id: str, limite: int = 30) -> list[dict]:
    """Messages d'un fil de discussion, du plus ancien au plus récent."""
    return await messages_chat_svc.lister(
        filtres=[("conversationId", "==", conversation_id)],
        ordre_par="dateEnvoi",
        decroissant=False,
        limite=limite,
    )


async def construire_historique_openai(conversation_id: str, limite: int = 30) -> list[dict]:
    """
    Reconstruit l'historique d'une conversation au format attendu par
    `agent_service.chat()` : [{"role": "user"|"assistant", "content": ...}, ...].
    """
    messages = await lister_conversation(conversation_id, limite=limite)
    return [
        {
            "role": "user" if m.get("emetteur") == RoleMessage.UTILISATEUR.value else "assistant",
            "content": m.get("contenu", ""),
        }
        for m in messages
    ]


async def lister_conversations_agriculteur(agriculteur_id: str, limite: int = 100) -> list[dict]:
    """Tous les messages d'un agriculteur, tous fils confondus (pour un futur écran d'historique)."""
    return await messages_chat_svc.lister(
        filtres=[("agriculteurId", "==", agriculteur_id)],
        ordre_par="dateEnvoi",
        decroissant=True,
        limite=limite,
    )
