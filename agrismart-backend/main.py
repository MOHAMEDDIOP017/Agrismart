"""
AgriSmart Backend — Point d'entrée principal FastAPI.

Application d'assistance agricole intelligente pour les agriculteurs sénégalais.
Modules IA :
  - Module 1 : Recommandation de cultures (Random Forest)
  - Module 2 : Détection de maladies (EfficientNetB0 TFLite)
"""

import logging
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import settings
from app.utils.logger import configurer_logging
from app.core.exceptions import AgriSmartException, agrismart_exception_handler

# Importation de tous les routers
from app.routers import (
    auth,
    utilisateurs,
    champs,
    donnees_agronomiques,
    cultures,
    recommandations,
    images,
    diagnostics,
    maladies,
    traitements,
    interventions,
    conseils,
    notifications,
    meteo,
    admin,
)

# ─── Configuration du logging ────────────────────────────────────────────────
configurer_logging()
logger = logging.getLogger("agrismart.main")


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

    # Préchargement du modèle SVM (évite la latence au premier appel)
    try:
        from app.services.recommandation_service import recommandation_service
        recommandation_service._charger_modeles()
        if recommandation_service._modeles_charges:
            logger.info(f"[OK] Modele SVM precharge : {recommandation_service._version_modele}")
        else:
            logger.warning("[WARN] Modele SVM non charge -- mode degrade heuristique actif")
    except Exception as e:
        logger.error(f"❌ Erreur chargement modèle SVM au démarrage : {e}")

    logger.info("AgriSmart Backend prêt à recevoir des requêtes.")
    yield

    logger.info("Arrêt d'AgriSmart Backend.")


# ─── Création de l'application FastAPI ───────────────────────────────────────

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="""
## AgriSmart Backend API

API backend pour l'application mobile Flutter AgriSmart, destinée aux agriculteurs sénégalais.

### Modules IA

| Module | Description | Modèle |
|--------|-------------|--------|
| **Recommandation cultures** | Analyse sol + météo → top-3 cultures | Random Forest (scikit-learn) |
| **Détection maladies** | Analyse image plante → maladie + traitement | EfficientNetB0 (TFLite) |

### Rôles utilisateurs

- **AGRICULTEUR** : Gère ses champs, consulte ses diagnostics et recommandations
- **EXPERT** : Valide les diagnostics, envoie des conseils, planifie des interventions
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

@app.exception_handler(AgriSmartException)
async def gestionnaire_exceptions_metier(request: Request, exc: AgriSmartException):
    """Convertit les exceptions AgriSmart en réponses HTTP structurées."""
    http_exc = agrismart_exception_handler(exc)
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
app.include_router(donnees_agronomiques.router)
app.include_router(cultures.router)
app.include_router(recommandations.router)
app.include_router(images.router)
app.include_router(diagnostics.router)
app.include_router(maladies.router)
app.include_router(traitements.router)
app.include_router(interventions.router)
app.include_router(conseils.router)
app.include_router(notifications.router)
app.include_router(meteo.router)
app.include_router(admin.router)


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
        reload=settings.env == "development",
        log_level="debug" if settings.env == "development" else "info",
    )
