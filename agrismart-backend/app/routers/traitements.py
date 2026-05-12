"""Router FastAPI — Traitements recommandés pour les maladies."""

import logging
from fastapi import APIRouter, Depends, HTTPException, status

from app.core.dependencies import get_utilisateur_courant, require_expert
from app.models.traitement_recommande import TraitementRecommandeCreate, TraitementRecommandeUpdate
from app.services.firestore_service import traitements_svc, maladies_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/traitements", tags=["Traitements recommandés"])


@router.get(
    "/maladie/{maladie_id}",
    summary="Traitements pour une maladie",
    description="Retourne tous les traitements recommandés pour une maladie donnée.",
    status_code=status.HTTP_200_OK,
)
async def traitements_par_maladie(
    maladie_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    traitements = await traitements_svc.lister(
        filtres=[("maladieId", "==", maladie_id)], limite=20
    )
    return {"maladieId": maladie_id, "traitements": traitements}


@router.get(
    "/{traitement_id}",
    summary="Détails d'un traitement",
    status_code=status.HTTP_200_OK,
)
async def obtenir_traitement(
    traitement_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    traitement = await traitements_svc.lire(traitement_id)
    if traitement is None:
        raise HTTPException(status_code=404, detail=f"Traitement '{traitement_id}' introuvable.")
    return traitement


@router.post(
    "",
    summary="Ajouter un traitement (Expert)",
    description="Un expert peut proposer un nouveau traitement pour une maladie.",
    status_code=status.HTTP_201_CREATED,
)
async def creer_traitement(
    donnees: TraitementRecommandeCreate,
    expert: dict = Depends(require_expert()),
):
    # Vérification que la maladie existe
    maladie = await maladies_service.lire(donnees.maladieId)
    if maladie is None:
        raise HTTPException(status_code=404, detail=f"Maladie '{donnees.maladieId}' introuvable.")

    doc = donnees.model_dump()
    doc["proposeParExpert"] = True
    doc["expertId"] = expert["uid"]
    traitement_id = await traitements_svc.creer(doc)
    return {"id": traitement_id, **doc}


@router.put(
    "/{traitement_id}",
    summary="Mettre à jour un traitement (Expert)",
    status_code=status.HTTP_200_OK,
)
async def mettre_a_jour_traitement(
    traitement_id: str,
    donnees: TraitementRecommandeUpdate,
    expert: dict = Depends(require_expert()),
):
    traitement = await traitements_svc.lire(traitement_id)
    if traitement is None:
        raise HTTPException(status_code=404, detail="Traitement introuvable.")

    await traitements_svc.mettre_a_jour(traitement_id, donnees.model_dump(exclude_none=True))
    return await traitements_svc.lire(traitement_id)
