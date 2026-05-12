"""Router FastAPI — Catalogue des maladies des plantes."""

import logging
from fastapi import APIRouter, Depends, HTTPException, status

from app.core.dependencies import get_utilisateur_courant, require_expert
from app.models.maladie import MaladieCreate, MaladieUpdate
from app.services.firestore_service import maladies_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/maladies", tags=["Maladies des plantes"])


@router.get(
    "",
    summary="Lister toutes les maladies",
    description="Retourne le catalogue complet des maladies des plantes connues.",
    status_code=status.HTTP_200_OK,
)
async def lister_maladies(courant: dict = Depends(get_utilisateur_courant)):
    maladies = await maladies_service.lister(limite=500)
    return {"maladies": maladies, "total": len(maladies)}


@router.get(
    "/{maladie_id}",
    summary="Détails d'une maladie",
    status_code=status.HTTP_200_OK,
)
async def obtenir_maladie(
    maladie_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    maladie = await maladies_service.lire(maladie_id)
    if maladie is None:
        raise HTTPException(status_code=404, detail=f"Maladie '{maladie_id}' introuvable.")
    return maladie


@router.get(
    "/culture/{culture_id}",
    summary="Maladies affectant une culture",
    description="Retourne toutes les maladies qui peuvent affecter une culture donnée.",
    status_code=status.HTTP_200_OK,
)
async def maladies_par_culture(
    culture_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    maladies = await maladies_service.lister(
        filtres=[("culturesAffectees", "array_contains", culture_id)],
        limite=100,
    )
    return {"cultureId": culture_id, "maladies": maladies}


@router.post(
    "",
    summary="Ajouter une maladie (Expert)",
    description="Un expert peut enrichir le catalogue des maladies.",
    status_code=status.HTTP_201_CREATED,
)
async def creer_maladie(
    donnees: MaladieCreate,
    expert: dict = Depends(require_expert()),
):
    maladie_id = await maladies_service.creer(donnees.model_dump())
    return {"id": maladie_id, **donnees.model_dump()}


@router.put(
    "/{maladie_id}",
    summary="Mettre à jour une maladie (Expert)",
    status_code=status.HTTP_200_OK,
)
async def mettre_a_jour_maladie(
    maladie_id: str,
    donnees: MaladieUpdate,
    expert: dict = Depends(require_expert()),
):
    maladie = await maladies_service.lire(maladie_id)
    if maladie is None:
        raise HTTPException(status_code=404, detail="Maladie introuvable.")

    await maladies_service.mettre_a_jour(maladie_id, donnees.model_dump(exclude_none=True))
    return await maladies_service.lire(maladie_id)
