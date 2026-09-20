"""
KoobalaTech Backend — Point d'entrée principal FastAPI.

Application d'assistance agricole intelligente pour les agriculteurs sénégalais.
Module IA :
  - Recommandation de cultures — RandomForest multi-label (One-vs-Rest), 16 variables
    sol/climat/NDVI, 8 cultures, top-3 avec probabilité d'aptitude par culture
  - Agent conversationnel IA bilingue français/wolof (Qwen via OpenRouter)

Note historique : un premier moteur SVM (7 variables, 1 seule classe prédite) avait
été prévu pour comparaison dans le mémoire, mais ses artefacts (svm_crop.pkl,
scaler_crop.pkl, label_encoder_crop.pkl) n'ont jamais été présents dans le dépôt —
il a été retiré. Seules ses fiches techniques par culture ont été conservées, dans
`app/services/fiches_cultures.py`.
"""

import logging
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import settings
from app.utils.logger import configurer_logging
from app.core.exceptions import KoobalaTechException, koobalatec_exception_handler

# Importation de tous les routers
from app.routers import (
    auth,
    utilisateurs,
    champs,
    cultures,
    recommandations,
    recommandations_v2,
    agent,
    interventions,
    conseils,
    notifications,
    meteo,
    admin,
    suivi_culture,
)

# ─── Configuration du logging ────────────────────────────────────────────────
configurer_logging()
logger = logging.getLogger("koobalatec.main")


# ─── Cycle de vie de l'application ───────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialisation au démarrage et nettoyage à l'arrêt."""
    logger.info(f"Démarrage de {settings.app_name} v{settings.app_version} [{settings.env}]")

    # Initialisation Firebase
    try:
        from app.firebase_init import initialiser_firebase
        initialiser_firebase()
        logger.info("Firebase initialisé avec succès.")
    except Exception as e:
        logger.warning(
            f"Firebase non initialisé (mode développement sans credentials) : {e}\n"
            "Configurez FIREBASE_SERVICE_ACCOUNT_PATH dans votre .env pour activer Firebase."
        )

    # Seed du référentiel ZoneAgroecologique (6 zones du Sénégal, diagramme UML) —
    # idempotent, ne fait rien si la collection est déjà peuplée.
    try:
        from app.services.zone_service import seed_si_vide
        nb_zones = await seed_si_vide()
        if nb_zones:
            logger.info(f"[OK] {nb_zones} zones agroécologiques créées (premier démarrage).")
    except Exception as e:
        logger.warning(f"Seed des zones agroécologiques ignoré (Firestore indisponible ?) : {e}")

    # Seed du référentiel Culture (8 cultures + nomWolof, diagramme UML) — idempotent.
    try:
        from app.services.culture_service import seed_si_vide as seed_cultures_si_vide
        nb_cultures = await seed_cultures_si_vide()
        if nb_cultures:
            logger.info(f"[OK] {nb_cultures} cultures créées (référentiel initial).")
    except Exception as e:
        logger.warning(f"Seed du référentiel cultures ignoré (Firestore indisponible ?) : {e}")

    # Préchargement du modèle multi-label v2 (modele_final.joblib)
    try:
        from app.services.recommandation_service_v2 import recommandation_service_v2
        recommandation_service_v2._charger_modele()
        if recommandation_service_v2.modeles_charges:
            logger.info("[OK] Modele multi-label v2 precharge (modele_final.joblib)")
        else:
            logger.warning("[WARN] Modele multi-label v2 non charge -- /recommandations/v2 indisponible")
    except Exception as e:
        logger.error(f"❌ Erreur chargement modèle multi-label v2 au démarrage : {e}")

    logger.info("KoobalaTech Backend prêt à recevoir des requêtes.")
    yield

    logger.info("Arrêt d'KoobalaTech Backend.")


# ─── Création de l'application FastAPI ───────────────────────────────────────

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="""
## KoobalaTech Backend API

API backend pour l'application mobile Flutter KoobalaTech, destinée aux agriculteurs sénégalais.

### Module IA

| Module | Description | Modèle |
|--------|-------------|--------|
| **Recommandation cultures** | Analyse sol/climat/NDVI par zone agroécologique → aptitude par culture, top-3 | RandomForest multi-label, 16 variables (scikit-learn) |
| **Agent conversationnel** | Chat bilingue FR/Wolof, function calling vers la recommandation | Qwen (OpenRouter) |

### Rôles utilisateurs

- **AGRICULTEUR** : Gère ses champs et consulte ses recommandations
- **EXPERT** : Envoie des conseils, planifie des interventions
- **ADMIN** : Administration complète de la plateforme

### Authentification

Toutes les routes (sauf `/auth/*`) nécessitent un token Firebase dans le header :
```
Authorization: Bearer <firebase_id_token>
```
    """,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan,
)


# ─── Middlewares ─────────────────────────────────────────────────────────────

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if settings.env == "development" else [],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def timing_middleware(request: Request, call_next):
    t0 = time.perf_counter()
    response = await call_next(request)
    elapsed = time.perf_counter() - t0
    if elapsed > 5:
        logger.warning(f"[SLOW >5s] {request.method} {request.url.path} — {elapsed:.2f}s")
    elif elapsed > 1:
        logger.info(f"[PERF >1s] {request.method} {request.url.path} — {elapsed:.2f}s")
    response.headers["X-Process-Time"] = f"{elapsed:.3f}s"
    return response


# ─── Gestionnaire d'exceptions global ────────────────────────────────────────

@app.exception_handler(KoobalaTechException)
async def gestionnaire_exceptions_metier(request: Request, exc: KoobalaTechException):
    """Convertit les exceptions KoobalaTech en réponses HTTP structurées."""
    http_exc = koobalatec_exception_handler(exc)
    return JSONResponse(
        status_code=http_exc.status_code,
        content={"detail": http_exc.detail, "type": type(exc).__name__},
    )


@app.exception_handler(Exception)
async def gestionnaire_exceptions_generiques(request: Request, exc: Exception):
    """Capture toutes les exceptions non gérées pour éviter les fuites d'informations."""
    logger.error(f"Exception non gérée sur {request.url.path} : {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Une erreur interne est survenue. Contactez l'administrateur."},
    )


# ─── Enregistrement des routers ──────────────────────────────────────────────

app.include_router(auth.router)
app.include_router(utilisateurs.router)
app.include_router(champs.router)
app.include_router(cultures.router)
app.include_router(recommandations.router)
app.include_router(recommandations_v2.router)
app.include_router(agent.router)
app.include_router(interventions.router)
app.include_router(conseils.router)
app.include_router(notifications.router)
app.include_router(meteo.router)
app.include_router(admin.router)
app.include_router(suivi_culture.router)


# ─── Routes utilitaires ──────────────────────────────────────────────────────

@app.get("/", tags=["Santé"], summary="Accueil de l'API")
async def racine():
    """Point de vérification de base de l'API."""
    return {
        "application": settings.app_name,
        "version": settings.app_version,
        "statut": "opérationnel",
        "docs": "/docs",
        "redoc": "/redoc",
    }


@app.get("/health", tags=["Santé"], summary="Vérification de santé")
async def health_check():
    """Endpoint de health check pour les orchestrateurs (Docker, Kubernetes)."""
    return {"statut": "ok", "version": settings.app_version}


# ─── Démarrage direct ────────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=False,
        log_level="debug" if settings.env == "development" else "info",
    )
