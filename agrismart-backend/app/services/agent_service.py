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

Tout le module est asynchrone de bout en bout : l'outil doit pouvoir lire
Firestore (résolution d'un `champId`), et les appels réseau bloquants
(OpenRouter, SoilGrids, NASA POWER, géocodage) sont déportés dans un thread
par `asyncio.to_thread` pour ne pas figer la boucle d'événements du serveur.
"""

import asyncio
import json
import logging

import requests

from app.config import settings
from app.core.exceptions import AgentIAIndisponibleException
from app.services import agroeco_zones
from app.services.firestore_service import champs_service
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
- Quand l'utilisateur demande quelles cultures planter, tu DOIS appeler l'outil \
`recommander_culture`. Ne devine jamais les cultures toi-même : utilise toujours \
l'outil.
- Cet outil accepte trois façons de désigner un endroit, par ordre de précision \
décroissante. Choisis TOUJOURS la plus précise dont tu disposes :
  1. `champId` : l'identifiant d'une parcelle enregistrée. Si le contexte de \
conversation t'indique un champ actuellement consulté, utilise CE champId, même \
si l'utilisateur ne le mentionne pas.
  2. `latitude` et `longitude` : un point GPS précis.
  3. `localite` : un nom de commune ou de ville, à n'utiliser que si tu n'as ni \
champId ni coordonnées, ou si l'utilisateur demande explicitement un autre lieu \
que sa parcelle.
- Quand l'outil renvoie une recommandation à l'échelle « localite », dis \
clairement à l'utilisateur qu'elle vaut pour la commune et non pour sa parcelle \
précise : reprends la phrase du champ `avertissement_echelle`.
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
            "Recommande les cultures les mieux adaptées à un endroit du Sénégal, "
            "à partir des données de sol, climat et végétation. Renvoie le top-3 "
            "avec le taux d'aptitude, en français et en wolof. L'endroit se désigne "
            "de trois façons, par précision décroissante : champId (parcelle "
            "enregistrée), latitude/longitude (point GPS), ou localite (commune). "
            "Aucun paramètre n'est obligatoire mais il en faut au moins un."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "champId": {
                    "type": "string",
                    "description": (
                        "Identifiant d'une parcelle enregistrée de l'agriculteur. "
                        "À privilégier : la recommandation porte alors sur la parcelle "
                        "elle-même. Utilise l'identifiant du champ actuellement "
                        "consulté quand le contexte de conversation te le donne."
                    ),
                },
                "latitude": {
                    "type": "number",
                    "description": "Latitude en degrés décimaux (ex : 14.1652 pour Kaolack)",
                },
                "longitude": {
                    "type": "number",
                    "description": "Longitude en degrés décimaux (ex : -16.0726 pour Kaolack)",
                },
                "localite": {
                    "type": "string",
                    "description": (
                        "Nom d'une ville ou commune du Sénégal (ex : Kaolack, Ziguinchor). "
                        "Dernier recours : la recommandation vaut alors pour la commune "
                        "entière, pas pour une parcelle précise."
                    ),
                },
                "top_k": {
                    "type": "integer",
                    "description": "Nombre de cultures à recommander (défaut 3)",
                    "default": 3,
                },
            },
            # Aucun paramètre obligatoire : le modèle choisit le mode de
            # localisation le plus précis dont il dispose. L'outil vérifie
            # lui-même qu'au moins un a été fourni (voir `recommander_culture`).
            "required": [],
        },
    },
}

# Paramètres que le modèle a le droit de fournir. Les arguments renvoyés par le
# LLM sont filtrés sur cette liste avant l'appel : le contexte de sécurité
# (`utilisateur_id`) est injecté par le serveur, jamais par le modèle.
PARAMETRES_OUTIL = frozenset(OUTIL_SCHEMA["function"]["parameters"]["properties"])

AVERTISSEMENT_LOCALITE = (
    "Cette recommandation vaut pour la commune dans son ensemble, et non pour une "
    "parcelle précise : le sol peut varier d'un champ à l'autre. Pour une "
    "recommandation sur votre parcelle, enregistrez-la dans l'application."
)


async def _point_depuis_champ(
    champ_id: str, utilisateur_id: str | None
) -> tuple[float, float, str] | dict:
    """
    Résout un `champId` en (latitude, longitude, libellé).

    Vérifie que le champ appartient bien à l'utilisateur de la conversation :
    le champId vient du modèle de langage, qui pourrait en inventer un ou
    reprendre celui d'un autre agriculteur aperçu dans l'historique. Sans ce
    contrôle, l'outil divulguerait la position d'une parcelle d'autrui. Le
    message d'erreur est volontairement identique à celui d'un champ
    inexistant, pour ne pas révéler l'existence de la parcelle.

    Returns:
        (latitude, longitude, libellé), ou un dict {"erreur": ...} directement
        renvoyable au modèle.
    """
    champ = await champs_service.lire(champ_id)
    if champ is None:
        return {"erreur": f"Parcelle introuvable : « {champ_id} »."}

    if utilisateur_id and champ.get("agriculteurId") != utilisateur_id:
        logger.warning(
            f"Agent : champId « {champ_id} » refusé — n'appartient pas à {utilisateur_id}."
        )
        return {"erreur": f"Parcelle introuvable : « {champ_id} »."}

    latitude, longitude = champ.get("latitude"), champ.get("longitude")
    if latitude is None or longitude is None:
        return {
            "erreur": f"La parcelle « {champ.get('nom', champ_id)} » n'a pas de "
                      f"coordonnées GPS enregistrées."
        }

    return float(latitude), float(longitude), champ.get("nom", "votre parcelle")


async def recommander_culture(
    champId: str | None = None,
    latitude: float | None = None,
    longitude: float | None = None,
    localite: str | None = None,
    top_k: int = 3,
    utilisateur_id: str | None = None,
) -> dict:
    """
    Outil appelé par l'agent (function calling) : un endroit du Sénégal
    -> top-k cultures recommandées + message bilingue FR/Wolof.

    Trois modes de localisation, appliqués dans cet ordre de priorité :
      1. `champId`                -> parcelle enregistrée (échelle « parcelle »)
      2. `latitude` + `longitude` -> point GPS           (échelle « parcelle »)
      3. `localite`               -> géocodage de commune (échelle « localite »)

    Aucun n'est obligatoire, mais au moins un doit être fourni, sinon l'outil
    renvoie une erreur explicite indiquant au modèle quoi fournir. La réponse
    porte le champ `echelle`, pour que l'agent — et donc l'utilisateur — sache
    si la recommandation vaut pour une parcelle précise ou pour une commune
    entière.

    Réutilise `agroeco_zones` (géocodage + collecte sol/climat/NDVI) et
    `recommandation_service_v2` (chargement du modèle + prédiction) : aucune
    logique dupliquée par rapport au flux « champ » du router /recommandations.
    """
    # ── Résolution de l'endroit, par priorité décroissante ────────────────
    if champId:
        resolu = await _point_depuis_champ(champId, utilisateur_id)
        if isinstance(resolu, dict):
            return resolu
        latitude, longitude, libelle = resolu
        echelle = "parcelle"

    elif latitude is not None and longitude is not None:
        latitude, longitude = float(latitude), float(longitude)
        libelle = f"votre position ({latitude:.4f}, {longitude:.4f})"
        echelle = "parcelle"

    elif localite:
        # Appels réseau bloquants -> thread, pour ne pas figer la boucle.
        geo = await asyncio.to_thread(agroeco_zones.geocoder_localite, localite)
        if not geo:
            return {
                "erreur": f"Localité introuvable : « {localite} ». "
                          f"Précisez une commune ou une ville du Sénégal."
            }
        latitude, longitude, libelle = geo
        echelle = "localite"

    else:
        return {
            "erreur": "Aucun endroit fourni. Appelle à nouveau l'outil avec l'un "
                      "de ces paramètres, par ordre de préférence : `champId` "
                      "(parcelle enregistrée), `latitude` et `longitude` "
                      "(point GPS), ou `localite` (nom de commune)."
        }

    # ── Collecte des 16 variables, puis prédiction ────────────────────────
    variables, zone, sources = await asyncio.to_thread(
        agroeco_zones.assembler_variables, latitude, longitude
    )
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
        f"Pour {libelle} ({zone_fr}), les cultures les plus adaptées sont : "
        + ", ".join(f"{c['culture_fr']} ({c['aptitude_pct']:.0f}%)" for c in top)
        + f". La plus recommandée est le {premiere['culture_fr']}."
    )
    message_wo = (
        f"Ci {libelle}, mbay yi gën a baax ñooy : "
        + ", ".join(c["culture_wolof"] for c in top)
        + f". Bi gën a baax mooy {premiere['culture_wolof']}."
    )
    if echelle == "localite":
        message_fr += " " + AVERTISSEMENT_LOCALITE

    return {
        "echelle": echelle,
        "avertissement_echelle": AVERTISSEMENT_LOCALITE if echelle == "localite" else None,
        "localisation": libelle,
        "champId": champId,
        "latitude": round(latitude, 4),
        "longitude": round(longitude, 4),
        "zone_agroecologique": zone_fr,
        "recommandations": top,
        "message_francais": message_fr,
        "message_wolof": message_wo,
        "sources_donnees": sources,
    }


# Registre des outils disponibles pour l'agent (nom -> coroutine)
OUTILS = {"recommander_culture": recommander_culture}


async def _appeler_qwen(messages: list[dict], avec_outils: bool = True) -> dict:
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
        # `requests` est bloquant : on le déporte dans un thread pour ne pas
        # figer la boucle d'événements pendant les ~secondes de génération.
        reponse = await asyncio.to_thread(
            lambda: requests.post(
                settings.openrouter_base_url,
                headers={
                    "Authorization": f"Bearer {settings.openrouter_api_key}",
                    "Content-Type": "application/json",
                },
                json=payload,
                timeout=TIMEOUT_OPENROUTER,
            )
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


def _contexte_champ(champ_id: str | None) -> list[dict]:
    """
    Message système additionnel indiquant le champ actuellement consulté
    dans l'application.

    C'est ce qui permet au modèle de privilégier `champId` : sans ce contexte,
    il ne peut connaître que les localités citées dans la conversation.
    """
    if not champ_id:
        return []
    return [{
        "role": "system",
        "content": (
            f"Contexte : l'utilisateur consulte actuellement la parcelle dont "
            f"l'identifiant est « {champ_id} ». Utilise ce champId comme "
            f"paramètre de l'outil `recommander_culture`, sauf si l'utilisateur "
            f"demande explicitement un autre endroit."
        ),
    }]


async def chat(
    message: str,
    historique: list[dict],
    champ_id_courant: str | None = None,
    utilisateur_id: str | None = None,
) -> dict:
    """
    Point d'entrée principal appelé par le router /agent/chat.
    Boucle agentique : Qwen -> (éventuel appel d'outil) -> Qwen -> réponse.

    Args:
        message: nouveau message de l'utilisateur.
        historique: messages précédents au format [{role, content}, ...].
        champ_id_courant: champ consulté dans l'app, transmis au modèle comme
            contexte pour qu'il privilégie une recommandation à l'échelle de
            la parcelle.
        utilisateur_id: uid de l'appelant, injecté dans l'outil pour vérifier
            qu'un champId appartient bien à cet utilisateur.

    Returns:
        {"reponse": str, "outils_utilises": [{"outil": str, "arguments": dict}, ...]}
    """
    messages: list[dict] = [{"role": "system", "content": SYSTEME_PROMPT}]
    messages += _contexte_champ(champ_id_courant)
    messages += historique
    messages.append({"role": "user", "content": message})

    reponse = await _appeler_qwen(messages)
    outils_utilises: list[dict] = []

    for _ in range(MAX_TOURS_OUTILS):
        tool_calls = reponse.get("tool_calls")
        if not tool_calls:
            break
        messages.append(reponse)

        for tc in tool_calls:
            nom_outil = tc["function"]["name"]
            args = json.loads(tc["function"]["arguments"])
            # Filtrage sur le schéma : le modèle ne doit pas pouvoir injecter
            # `utilisateur_id` et contourner le contrôle de propriété du champ.
            args = {cle: val for cle, val in args.items() if cle in PARAMETRES_OUTIL}
            fonction = OUTILS.get(nom_outil)
            try:
                if fonction is None:
                    resultat = {"erreur": "outil inconnu"}
                else:
                    resultat = await fonction(**args, utilisateur_id=utilisateur_id)
            except Exception as e:
                logger.error(f"Erreur lors de l'exécution de l'outil {nom_outil} : {e}")
                resultat = {"erreur": str(e)}
            outils_utilises.append({"outil": nom_outil, "arguments": args})
            messages.append({
                "role": "tool",
                "tool_call_id": tc["id"],
                "content": json.dumps(resultat, ensure_ascii=False),
            })
        reponse = await _appeler_qwen(messages)

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
