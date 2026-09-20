"""
Agent IA conversationnel bilingue français/wolof (Module IA — nouveauté).

Adapté du script fourni `agent_api.py` (racine du dépôt) à l'architecture
services/ existante : au lieu d'une mini-application FastAPI autonome, la
logique métier (appel du LLM, boucle de function calling, outil de
recommandation) vit ici et est exposée par `app/routers/agent.py`, qui
réutilise le CORS et les conventions des autres routers.

Chaîne : app Flutter -> POST /agent/chat -> Qwen (via OpenRouter)
                                                 |
                                                 v function calling
                                    outil `recommander_culture`
                                                 |
                                                 v
                          recommandation_service_v2 (modele_final.joblib)
                          + agroeco_zones (géocodage, sol, climat, NDVI)
"""

import json
import logging

import requests

from app.config import settings
from app.core.exceptions import AgentIAIndisponibleException
from app.services import agroeco_zones
from app.services.recommandation_service_v2 import (
    recommandation_service_v2,
    NOM_AFFICHAGE_PAR_CODE,
    NOM_WOLOF_PAR_CODE as CULTURE_WOLOF,
)

logger = logging.getLogger(__name__)

TIMEOUT_OPENROUTER = 60
MAX_TOURS_OUTILS = 3  # garde-fou anti-boucle infinie de function calling

SYSTEME_PROMPT = """Tu es AgriSmart, un assistant agricole intelligent pour les \
agriculteurs du Sénégal. Tu es bienveillant, clair et concret.

RÈGLES :
- Tu réponds SOIT en français SOIT en wolof, jamais les deux à la fois, sauf si \
l'outil `recommander_culture` te fournit explicitement les deux (message_francais \
ET message_wolof) : dans ce cas seulement, tu peux reprendre les deux tels quels.
- N'utilise JAMAIS de caractères chinois, cyrilliques ou d'une autre écriture que \
l'alphabet latin, même pour traduire ou vérifier une phrase en wolof. Si tu n'es \
pas sûr d'une traduction wolof, reste en français plutôt que d'improviser.
- Ne montre jamais ton raisonnement, tes hésitations ou une correction en cours \
de réponse (pas de "note :", pas de "version corrigée :") : écris directement la \
réponse finale, propre, en une seule fois.
- Quand l'utilisateur demande quelles cultures planter dans une localité, tu \
DOIS appeler l'outil `recommander_culture` avec le nom de la localité. Ne devine \
jamais les cultures toi-même : utilise toujours l'outil.
- Après l'outil, explique la recommandation simplement, comme à un cultivateur \
qui ne connaît rien à la technologie. Cite le taux d'aptitude.
- Pour les questions générales d'agriculture (maladies, techniques, calendrier \
cultural), réponds avec tes connaissances de façon simple et pratique.
- Reste toujours dans le domaine agricole. Sois concis."""

OUTIL_SCHEMA = {
    "type": "function",
    "function": {
        "name": "recommander_culture",
        "description": (
            "Recommande les cultures les mieux adaptées à une localité du Sénégal, "
            "à partir des données de sol, climat et végétation. Renvoie le top-3 "
            "avec le taux d'aptitude, en français et en wolof."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "localite": {
                    "type": "string",
                    "description": "Nom d'une ville ou commune du Sénégal (ex : Kaolack, Ziguinchor)",
                },
                "top_k": {
                    "type": "integer",
                    "description": "Nombre de cultures à recommander (défaut 3)",
                    "default": 3,
                },
            },
            "required": ["localite"],
        },
    },
}


def recommander_culture(localite: str, top_k: int = 3) -> dict:
    """
    Outil appelé par l'agent (function calling) : nom de localité sénégalaise
    -> top-k cultures recommandées + message bilingue FR/Wolof.

    Réutilise `agroeco_zones` (géocodage + collecte sol/climat/NDVI) et
    `recommandation_service_v2` (chargement du modèle + prédiction) : aucune
    logique dupliquée par rapport au flux "champ" du router /recommandations/v2.
    """
    geo = agroeco_zones.geocoder_localite(localite)
    if not geo:
        return {
            "erreur": f"Localité introuvable : « {localite} ». "
                      f"Précisez une commune ou une ville du Sénégal."
        }
    latitude, longitude, nom_resolu = geo

    variables, zone, sources = agroeco_zones.assembler_variables(latitude, longitude)
    resultats = recommandation_service_v2.predire_top_k(variables, top_k=top_k)

    zone_fr = agroeco_zones.ZONE_NOM_AFFICHAGE.get(zone, zone)
    top = [
        {
            "culture_fr": NOM_AFFICHAGE_PAR_CODE.get(code, code),
            "culture_wolof": CULTURE_WOLOF.get(code, code),
            "aptitude_pct": round(float(proba) * 100, 1),
        }
        for code, proba in resultats
    ]

    premiere = top[0]
    message_fr = (
        f"Pour {nom_resolu} ({zone_fr}), les cultures les plus adaptées sont : "
        + ", ".join(f"{c['culture_fr']} ({c['aptitude_pct']:.0f}%)" for c in top)
        + f". La plus recommandée est le {premiere['culture_fr']}."
    )
    message_wo = (
        f"Ci {nom_resolu}, mbay yi gën a baax ñooy : "
        + ", ".join(c["culture_wolof"] for c in top)
        + f". Bi gën a baax mooy {premiere['culture_wolof']}."
    )

    return {
        "localite": nom_resolu,
        "latitude": round(latitude, 4),
        "longitude": round(longitude, 4),
        "zone_agroecologique": zone_fr,
        "recommandations": top,
        "message_francais": message_fr,
        "message_wolof": message_wo,
        "sources_donnees": sources,
    }


# Registre des outils disponibles pour l'agent (nom -> fonction Python)
OUTILS = {"recommander_culture": recommander_culture}


def _appeler_qwen(messages: list[dict], avec_outils: bool = True) -> dict:
    """Un appel à Qwen via OpenRouter. Lève AgentIAIndisponibleException en cas d'échec."""
    if not settings.openrouter_api_key:
        raise AgentIAIndisponibleException(
            "Clé OPENROUTER_API_KEY non configurée sur le serveur."
        )

    # Température basse : Qwen a tendance à "dériver" (mélanger des caractères
    # chinois, laisser apparaître son raisonnement) sur des réponses longues ou
    # en wolof à température par défaut — observé en test réel sur ce projet.
    payload = {"model": settings.openrouter_modele, "messages": messages, "temperature": 0.3}
    if avec_outils:
        payload["tools"] = [OUTIL_SCHEMA]
        payload["tool_choice"] = "auto"

    try:
        reponse = requests.post(
            settings.openrouter_base_url,
            headers={
                "Authorization": f"Bearer {settings.openrouter_api_key}",
                "Content-Type": "application/json",
            },
            json=payload,
            timeout=TIMEOUT_OPENROUTER,
        )
        reponse.raise_for_status()
        # NB : on décode nous-mêmes `reponse.content` avec `json.loads` plutôt
        # que d'utiliser `reponse.json()`. OpenRouter ne renvoie pas toujours
        # un `charset` explicite dans son Content-Type ; `requests` retombe
        # alors sur ISO-8859-1 (RFC 2616) pour `.text`/`.json()`, ce qui
        # corrompt tous les caractères accentués et le wolof (mojibake du
        # type « Ã© » au lieu de « é »). `json.loads` sur les octets bruts
        # détecte correctement l'UTF-8 (RFC 8259) et évite le problème.
        return json.loads(reponse.content)["choices"][0]["message"]
    except requests.exceptions.Timeout:
        raise AgentIAIndisponibleException("OpenRouter ne répond pas (timeout).")
    except (requests.RequestException, KeyError, IndexError, ValueError) as e:
        logger.error(f"Erreur d'appel à OpenRouter/Qwen : {e}")
        raise AgentIAIndisponibleException(f"Agent IA indisponible : {e}")


def chat(message: str, historique: list[dict]) -> dict:
    """
    Point d'entrée principal appelé par le router /agent/chat.
    Boucle agentique : Qwen -> (éventuel appel d'outil) -> Qwen -> réponse.

    Args:
        message: nouveau message de l'utilisateur.
        historique: messages précédents au format [{role, content}, ...].

    Returns:
        {"reponse": str, "outils_utilises": [{"outil": str, "arguments": dict}, ...]}
    """
    messages: list[dict] = [{"role": "system", "content": SYSTEME_PROMPT}]
    messages += historique
    messages.append({"role": "user", "content": message})

    reponse = _appeler_qwen(messages)
    outils_utilises: list[dict] = []

    for _ in range(MAX_TOURS_OUTILS):
        tool_calls = reponse.get("tool_calls")
        if not tool_calls:
            break
        messages.append(reponse)

        for tc in tool_calls:
            nom_outil = tc["function"]["name"]
            args = json.loads(tc["function"]["arguments"])
            fonction = OUTILS.get(nom_outil)
            try:
                resultat = fonction(**args) if fonction else {"erreur": "outil inconnu"}
            except Exception as e:
                logger.error(f"Erreur lors de l'exécution de l'outil {nom_outil} : {e}")
                resultat = {"erreur": str(e)}
            outils_utilises.append({"outil": nom_outil, "arguments": args})
            messages.append({
                "role": "tool",
                "tool_call_id": tc["id"],
                "content": json.dumps(resultat, ensure_ascii=False),
            })
        reponse = _appeler_qwen(messages)

    return {
        "reponse": _reparer_mojibake(reponse.get("content", "")),
        "outils_utilises": outils_utilises,
    }


def _reparer_mojibake(texte: str) -> str:
    """
    Corrige un mojibake UTF-8 relu en Latin-1 (« Ã© » au lieu de « é »),
    observé de façon intermittente sur les réponses OpenRouter — certains
    fournisseurs backend de la route Qwen renvoient un texte mal ré-encodé,
    indépendamment du décodage JSON côté client (voir `_appeler_qwen`).
    Best-effort : si le texte n'est pas du mojibake réparable, il est
    retourné inchangé (aucune exception ne remonte).
    """
    try:
        repare = texte.encode("latin-1").decode("utf-8")
    except (UnicodeEncodeError, UnicodeDecodeError):
        return texte
    return repare
