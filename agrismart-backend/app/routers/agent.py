"""Router FastAPI — Agent conversationnel IA bilingue français/wolof (nouveauté)."""

import logging
import uuid
from fastapi import APIRouter, Depends, HTTPException, status

from app.core.dependencies import get_utilisateur_courant
from app.core.exceptions import agrismart_exception_handler, AgriSmartException
from app.models.agent_chat import RequeteChat, ReponseChat
from app.models.enums import RoleMessage
from app.services import agent_service, message_chat_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/agent", tags=["Agent IA conversationnel"])


@router.post(
    "/chat",
    summary="Discuter avec l'agent agricole IA (français/wolof)",
    description=(
        "Envoie un message à l'agent conversationnel AgriSmart (Qwen via OpenRouter). "
        "L'historique est autoritaire côté serveur : persisté comme `MessageChat` et "
        "regroupé par `conversationId` (généré au premier message d'un nouveau fil). "
        "L'agent répond en français ou en wolof selon la langue de l'utilisateur, et "
        "appelle automatiquement l'outil de recommandation de cultures (function "
        "calling) quand la question porte sur les cultures adaptées à une localité."
    ),
    status_code=status.HTTP_200_OK,
    response_model=ReponseChat,
)
async def chat(
    requete: RequeteChat,
    courant: dict = Depends(get_utilisateur_courant),
) -> ReponseChat:
    uid = courant["uid"]
    conversation_id = requete.conversationId or str(uuid.uuid4())

    try:
        historique = await message_chat_service.construire_historique_openai(conversation_id)
        resultat = await agent_service.chat(
            requete.message,
            historique,
            champ_id_courant=requete.champId,
            utilisateur_id=uid,
        )

        # Persistance du MessageChat de l'utilisateur et de la réponse de l'agent.
        await message_chat_service.persister(
            conversation_id, uid, RoleMessage.UTILISATEUR, requete.message,
        )
        outil_appele = (
            resultat["outils_utilises"][0]["outil"] if resultat["outils_utilises"] else None
        )
        await message_chat_service.persister(
            conversation_id, uid, RoleMessage.AGENT, resultat["reponse"], outil_appele,
        )

        return ReponseChat(
            conversationId=conversation_id,
            reponse=resultat["reponse"],
            outilsUtilises=resultat["outils_utilises"],
        )
    except AgriSmartException as e:
        raise agrismart_exception_handler(e)
    except Exception as e:
        logger.error(f"Erreur lors de la conversation avec l'agent IA : {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get(
    "/conversations/{conversation_id}",
    summary="Historique d'un fil de discussion",
    description="Retourne tous les MessageChat d'un fil de discussion, du plus ancien au plus récent.",
    status_code=status.HTTP_200_OK,
)
async def obtenir_conversation(
    conversation_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    messages = await message_chat_service.lister_conversation(conversation_id)
    # Un agriculteur ne peut consulter que ses propres conversations.
    if courant.get("role") not in ["ADMIN", "EXPERT"] and messages:
        if any(m.get("agriculteurId") != courant["uid"] for m in messages):
            raise HTTPException(status_code=403, detail="Accès refusé à cette conversation.")
    return {"conversationId": conversation_id, "messages": messages, "total": len(messages)}
