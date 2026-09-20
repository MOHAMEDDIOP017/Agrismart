#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
==============================================================================
 Agent IA agricole AgriSmart — API FastAPI
 Mémoire : recommandation de cultures / zones agroécologiques du Sénégal

 ARCHITECTURE :
   App Flutter  ->  POST /chat  ->  Agent (Qwen via OpenRouter)
                                        |
                                        v  (function calling)
                                    Outil recommander_culture
                                        |
                                        v
                              modele_final.joblib (+ SoilGrids, NASA POWER)

 L'agent reçoit une question en français ou en wolof, décide seul s'il doit
 appeler l'outil de recommandation, puis rédige une réponse conversationnelle
 bilingue adaptée à un agriculteur.

 CONFIGURATION (avant de lancer) :
   1. Crée un compte sur https://openrouter.ai et génère une clé API
   2. Définis la variable d'environnement :
        Windows PowerShell :  $env:OPENROUTER_API_KEY="sk-or-..."
        Linux/Mac :           export OPENROUTER_API_KEY="sk-or-..."
   3. Place modele_final.joblib et outil_recommander_culture.py dans ce dossier

 LANCEMENT :
   pip install fastapi uvicorn requests joblib scikit-learn xgboost numpy
   uvicorn agent_api:app --reload --port 8000

   Puis teste sur http://localhost:8000/docs (interface Swagger interactive)
==============================================================================
"""

import json
import os

import requests
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# On importe l'outil déjà construit et testé
from outil_recommander_culture import recommander_culture, OUTIL_SCHEMA

# -----------------------------------------------------------------------------
# Configuration OpenRouter / Qwen
# -----------------------------------------------------------------------------
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
API_KEY = os.environ.get("OPENROUTER_API_KEY", "")
# Modèle Qwen sur OpenRouter (supporte le function calling).
# Alternatives : "qwen/qwen-2.5-7b-instruct", "qwen/qwen-2.5-72b-instruct"
MODELE_LLM = "qwen/qwen-2.5-72b-instruct"

SYSTEME = """Tu es AgriSmart, un assistant agricole intelligent pour les \
agriculteurs du Sénégal. Tu es bienveillant, clair et concret.

RÈGLES :
- Tu réponds dans la langue de l'utilisateur : français OU wolof.
- Quand l'utilisateur demande quelles cultures planter dans une localité, tu \
DOIS appeler l'outil `recommander_culture` avec le nom de la localité. Ne devine \
jamais les cultures toi-même : utilise toujours l'outil.
- Après l'outil, explique la recommandation simplement, comme à un cultivateur \
qui ne connaît rien à la technologie. Cite le taux d'aptitude.
- Pour les questions générales d'agriculture (maladies, techniques, calendrier \
cultural), réponds avec tes connaissances de façon simple et pratique.
- Reste toujours dans le domaine agricole. Sois concis."""

# -----------------------------------------------------------------------------
# Application FastAPI
# -----------------------------------------------------------------------------
app = FastAPI(title="Agent AgriSmart",
              description="Assistant agricole bilingue français-wolof",
              version="1.0")

# CORS : autorise l'app Flutter à appeler l'API
app.add_middleware(CORSMiddleware, allow_origins=["*"],
                   allow_methods=["*"], allow_headers=["*"])


class Question(BaseModel):
    message: str
    historique: list = []      # [{role, content}, ...] pour le multi-tours


# Registre des outils disponibles pour l'agent (nom -> fonction Python)
OUTILS = {"recommander_culture": recommander_culture}


def appeler_qwen(messages, avec_outils=True):
    """Un appel à Qwen via OpenRouter."""
    payload = {"model": MODELE_LLM, "messages": messages}
    if avec_outils:
        payload["tools"] = [OUTIL_SCHEMA]
        payload["tool_choice"] = "auto"
    r = requests.post(OPENROUTER_URL,
                      headers={"Authorization": f"Bearer {API_KEY}",
                               "Content-Type": "application/json"},
                      json=payload, timeout=60)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]


@app.get("/")
def racine():
    return {"service": "Agent AgriSmart", "statut": "en ligne",
            "cle_configuree": bool(API_KEY)}


@app.post("/chat")
def chat(q: Question):
    """
    Point d'entrée principal appelé par l'app Flutter.
    Boucle agentique : Qwen -> (éventuel appel d'outil) -> Qwen -> réponse.
    """
    if not API_KEY:
        return {"erreur": "Clé OPENROUTER_API_KEY non configurée sur le serveur."}

    messages = [{"role": "system", "content": SYSTEME}]
    messages += q.historique
    messages.append({"role": "user", "content": q.message})

    # 1er appel : Qwen décide s'il utilise un outil
    reponse = appeler_qwen(messages)
    outils_utilises = []

    # Boucle : tant que l'agent veut appeler des outils (max 3 tours de sécurité)
    for _ in range(3):
        tool_calls = reponse.get("tool_calls")
        if not tool_calls:
            break
        messages.append(reponse)   # on garde la demande d'outil dans l'historique

        for tc in tool_calls:
            nom = tc["function"]["name"]
            args = json.loads(tc["function"]["arguments"])
            fonction = OUTILS.get(nom)
            resultat = fonction(**args) if fonction else {"erreur": "outil inconnu"}
            outils_utilises.append({"outil": nom, "arguments": args})
            messages.append({
                "role": "tool",
                "tool_call_id": tc["id"],
                "content": json.dumps(resultat, ensure_ascii=False),
            })
        # Qwen reformule à partir du résultat de l'outil
        reponse = appeler_qwen(messages)

    return {
        "reponse": reponse.get("content", ""),
        "outils_utilises": outils_utilises,
    }
