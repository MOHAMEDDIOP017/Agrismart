"""Router FastAPI — Suivi des cultures en champ (CultureEnChamp)."""

import logging
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from app.core.dependencies import get_utilisateur_courant
from app.services.firestore_service import culture_en_champ_svc

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/cultures-en-champ", tags=["Suivi cultures"])


# ─── Schémas ────────────────────────────────────────────────────────────────

class CreerCultureRequest(BaseModel):
    champId: str
    cultureName: str
    datePlantation: str  # ISO date string
    statutCycle: str = "EN_COURS"
    dureeCycleDays: int | None = None
    notes: str | None = None


class MettreAJourStatutRequest(BaseModel):
    statutCycle: str


# ─── Endpoints ──────────────────────────────────────────────────────────────

@router.get(
    "/champ/{champ_id}",
    summary="Cultures en cours pour un champ",
    status_code=status.HTTP_200_OK,
)
async def cultures_par_champ(
    champ_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    """Retourne toutes les cultures enregistrées pour un champ donné."""
    cultures = await culture_en_champ_svc.lister(
        filtres=[("champId", "==", champ_id)],
        ordre_par="datePlantation",
        decroissant=True,
    )
    return {"cultures": cultures, "total": len(cultures)}


@router.post(
    "/",
    summary="Enregistrer une culture dans un champ",
    status_code=status.HTTP_201_CREATED,
)
async def creer_culture(
    corps: CreerCultureRequest,
    courant: dict = Depends(get_utilisateur_courant),
):
    """Enregistre une culture plantée dans un champ de l'agriculteur connecté."""
    donnees = corps.model_dump()
    donnees["agriculteurId"] = courant["uid"]
    donnees["dateCreation"] = datetime.now(timezone.utc).isoformat()

    culture_id = await culture_en_champ_svc.creer(donnees)
    logger.info(f"[CultureEnChamp] Créé {culture_id} pour champ {corps.champId}")
    return {"message": "Culture enregistrée.", "cultureId": culture_id}


@router.patch(
    "/{culture_id}/statut",
    summary="Mettre à jour le statut du cycle",
    status_code=status.HTTP_200_OK,
)
async def mettre_a_jour_statut(
    culture_id: str,
    corps: MettreAJourStatutRequest,
    courant: dict = Depends(get_utilisateur_courant),
):
    """Met à jour le statut du cycle d'une culture (EN_COURS, RECOLTE, ABANDONNE)."""
    culture = await culture_en_champ_svc.lire(culture_id)
    if culture is None:
        raise HTTPException(status_code=404, detail="Culture introuvable.")

    uid = courant["uid"]
    if culture.get("agriculteurId") != uid and courant.get("role") != "ADMIN":
        raise HTTPException(status_code=403, detail="Accès refusé.")

    await culture_en_champ_svc.mettre_a_jour(
        culture_id,
        {"statutCycle": corps.statutCycle, "dateModification": datetime.now(timezone.utc).isoformat()},
    )
    return {"message": "Statut mis à jour."}


@router.delete(
    "/{culture_id}",
    summary="Supprimer une culture",
    status_code=status.HTTP_200_OK,
)
async def supprimer_culture(
    culture_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    """Supprime une entrée CultureEnChamp (agriculteur propriétaire ou admin)."""
    culture = await culture_en_champ_svc.lire(culture_id)
    if culture is None:
        raise HTTPException(status_code=404, detail="Culture introuvable.")

    uid = courant["uid"]
    if culture.get("agriculteurId") != uid and courant.get("role") != "ADMIN":
        raise HTTPException(status_code=403, detail="Accès refusé.")

    await culture_en_champ_svc.supprimer(culture_id)
    return {"message": "Culture supprimée."}
