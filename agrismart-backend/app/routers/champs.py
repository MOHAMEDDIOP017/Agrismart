"""Router FastAPI — Gestion des champs agricoles."""

import logging
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File

from app.core.dependencies import get_utilisateur_courant
from app.core.exceptions import agrismart_exception_handler, AgriSmartException
from app.models.champ import (
    ChampCreate,
    ChampUpdate,
    ChampResponse,
    ChampListeResponse,
    ScoreSanteChamp,
)
from app.services.firestore_service import (
    champs_service, recommandations_svc
)
from app.services.storage_service import storage_service
from app.services.historique_service import historique_service
from app.services.zone_service import zone_id_pour_point
from app.utils.helpers import calculer_score_sante_champ, maintenant_utc

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/champs", tags=["Champs agricoles"])


@router.get(
    "",
    summary="Lister tous les champs (Admin)",
    description="Retourne tous les champs de la plateforme. Accès réservé aux administrateurs.",
    status_code=status.HTTP_200_OK,
    response_model=ChampListeResponse,
)
async def lister_tous_champs(
    courant: dict = Depends(get_utilisateur_courant),
):
    if courant.get("role") != "ADMIN":
        raise HTTPException(status_code=403, detail="Accès réservé aux administrateurs.")

    champs = await champs_service.lister(
        ordre_par="dateCreation",
        decroissant=True,
    )
    return {"champs": champs, "total": len(champs)}


@router.get(
    "/agriculteur/{agriculteur_id}",
    summary="Lister les champs d'un agriculteur",
    description="Retourne tous les champs appartenant à l'agriculteur spécifié.",
    status_code=status.HTTP_200_OK,
    response_model=ChampListeResponse,
)
async def lister_champs_agriculteur(
    agriculteur_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    """Un agriculteur ne peut voir que ses propres champs."""
    uid = courant["uid"]
    role = courant.get("role", "")
    if role not in ["ADMIN", "EXPERT"] and uid != agriculteur_id:
        raise HTTPException(status_code=403, detail="Accès refusé.")

    champs = await champs_service.lister(
        filtres=[("agriculteurId", "==", agriculteur_id)],
        ordre_par="dateCreation",
        decroissant=True,
    )
    return {"champs": champs, "total": len(champs)}


@router.get(
    "/{champ_id}",
    summary="Obtenir un champ",
    description="Retourne les détails d'un champ par son ID.",
    status_code=status.HTTP_200_OK,
    response_model=ChampResponse,
)
async def obtenir_champ(
    champ_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    champ = await champs_service.lire(champ_id)
    if champ is None:
        raise HTTPException(status_code=404, detail=f"Champ '{champ_id}' introuvable.")

    uid = courant["uid"]
    role = courant.get("role", "")
    if role not in ["ADMIN", "EXPERT"] and champ.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Accès refusé à ce champ.")

    return champ


@router.post(
    "",
    summary="Créer un champ",
    description="Crée un nouveau champ agricole pour l'utilisateur connecté.",
    status_code=status.HTTP_201_CREATED,
    response_model=ChampResponse,
)
async def creer_champ(
    donnees: ChampCreate,
    courant: dict = Depends(get_utilisateur_courant),
):
    """L'agriculteurId est automatiquement déduit du token Firebase."""
    uid = courant["uid"]
    doc = donnees.model_dump()
    doc["agriculteurId"] = uid
    # Relation "située dans" du diagramme UML : calculée depuis lat/lon, jamais saisie.
    doc["zoneAgroecologiqueId"] = zone_id_pour_point(donnees.latitude, donnees.longitude)

    champ_id = await champs_service.creer(doc)
    await historique_service.enregistrer(
        uid, "CREATION_CHAMP", f"Champ '{donnees.nom}' créé", champ_id
    )
    champ = await champs_service.lire(champ_id)
    return {"id": champ_id, **champ}


@router.put(
    "/{champ_id}",
    summary="Mettre à jour un champ",
    description="Met à jour les informations d'un champ existant.",
    status_code=status.HTTP_200_OK,
    response_model=ChampResponse,
)
async def mettre_a_jour_champ(
    champ_id: str,
    donnees: ChampUpdate,
    courant: dict = Depends(get_utilisateur_courant),
):
    champ = await champs_service.lire(champ_id)
    if champ is None:
        raise HTTPException(status_code=404, detail=f"Champ '{champ_id}' introuvable.")

    uid = courant["uid"]
    if courant.get("role") != "ADMIN" and champ.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Modification non autorisée.")

    maj = donnees.model_dump(exclude_none=True)
    if "latitude" in maj or "longitude" in maj:
        nouvelle_latitude = maj.get("latitude", champ.get("latitude"))
        nouvelle_longitude = maj.get("longitude", champ.get("longitude"))
        maj["zoneAgroecologiqueId"] = zone_id_pour_point(nouvelle_latitude, nouvelle_longitude)

    await champs_service.mettre_a_jour(champ_id, maj)
    return await champs_service.lire(champ_id)


@router.delete(
    "/{champ_id}",
    summary="Supprimer un champ",
    description="Supprime définitivement un champ et ses données associées.",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def supprimer_champ(
    champ_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    champ = await champs_service.lire(champ_id)
    if champ is None:
        raise HTTPException(status_code=404, detail=f"Champ '{champ_id}' introuvable.")

    uid = courant["uid"]
    if courant.get("role") != "ADMIN" and champ.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Suppression non autorisée.")

    await champs_service.supprimer(champ_id)


@router.get(
    "/{champ_id}/score-sante",
    summary="Score de santé d'un champ",
    description=(
        "Calcule et retourne le score de santé d'un champ (0-100) "
        "basé sur les diagnostics et recommandations actives."
    ),
    status_code=status.HTTP_200_OK,
    response_model=ScoreSanteChamp,
)
async def score_sante_champ(
    champ_id: str,
    courant: dict = Depends(get_utilisateur_courant),
) -> ScoreSanteChamp:
    champ = await champs_service.lire(champ_id)
    if champ is None:
        raise HTTPException(status_code=404, detail=f"Champ '{champ_id}' introuvable.")

    uid = courant["uid"]
    if courant.get("role") not in ["ADMIN", "EXPERT"] and champ.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Accès refusé.")

    recommandations = await recommandations_svc.lister(
        filtres=[("champId", "==", champ_id)], limite=10
    )

    score, interpretation = calculer_score_sante_champ(
        nb_maladies_recentes=0,
        nb_diagnostics_confirmes=0,
        nb_recommandations_actives=len(recommandations),
    )

    return ScoreSanteChamp(
        champId=champ_id,
        score=score,
        interpretation=interpretation,
        dernierDiagnostic=None,
        nbMaladiesDetectees=0,
        nbRecommandationsActives=len(recommandations),
    )
