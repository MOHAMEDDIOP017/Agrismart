"""Router FastAPI — Données agronomiques."""

import logging
from fastapi import APIRouter, Depends, HTTPException, status

from app.core.dependencies import get_utilisateur_courant
from app.models.donnees_agronomiques import DonneesAgronomiquesCreate, DonneesAgronomiquesResponse
from app.services.firestore_service import donnees_agronomiques_svc, champs_service
from app.utils.helpers import maintenant_utc

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/donnees-agronomiques", tags=["Données agronomiques"])


@router.post(
    "",
    summary="Saisir de nouvelles données agronomiques",
    description="Enregistre une nouvelle mesure agronomique pour un champ.",
    status_code=status.HTTP_201_CREATED,
)
async def saisir_donnees(
    donnees: DonneesAgronomiquesCreate,
    courant: dict = Depends(get_utilisateur_courant),
):
    """Vérifie que le champ appartient bien à l'utilisateur avant d'enregistrer."""
    champ = await champs_service.lire(donnees.champId)
    if champ is None:
        raise HTTPException(status_code=404, detail="Champ introuvable.")

    uid = courant["uid"]
    if courant.get("role") not in ["ADMIN", "EXPERT"] and champ.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Accès refusé à ce champ.")

    doc = donnees.model_dump()
    doc["dateSaisie"] = maintenant_utc()
    doc_id = await donnees_agronomiques_svc.creer(doc)
    resultat = await donnees_agronomiques_svc.lire(doc_id)
    return resultat


@router.get(
    "/champ/{champ_id}",
    summary="Historique des données d'un champ",
    description="Retourne toutes les mesures agronomiques d'un champ, du plus récent au plus ancien.",
    status_code=status.HTTP_200_OK,
)
async def historique_donnees(
    champ_id: str,
    limite: int = 50,
    courant: dict = Depends(get_utilisateur_courant),
):
    champ = await champs_service.lire(champ_id)
    if champ is None:
        raise HTTPException(status_code=404, detail="Champ introuvable.")

    uid = courant["uid"]
    if courant.get("role") not in ["ADMIN", "EXPERT"] and champ.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Accès refusé.")

    donnees = await donnees_agronomiques_svc.lister(
        filtres=[("champId", "==", champ_id)],
        ordre_par="dateSaisie",
        decroissant=True,
        limite=limite,
    )
    return {"donnees": donnees, "total": len(donnees)}


@router.get(
    "/champ/{champ_id}/recentes",
    summary="Dernières données agronomiques d'un champ",
    description="Retourne uniquement la mesure agronomique la plus récente.",
    status_code=status.HTTP_200_OK,
)
async def donnees_recentes(
    champ_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    champ = await champs_service.lire(champ_id)
    if champ is None:
        raise HTTPException(status_code=404, detail="Champ introuvable.")

    uid = courant["uid"]
    if courant.get("role") not in ["ADMIN", "EXPERT"] and champ.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Accès refusé.")

    donnees_list = await donnees_agronomiques_svc.lister(
        filtres=[("champId", "==", champ_id)],
        ordre_par="dateSaisie",
        decroissant=True,
        limite=1,
    )
    if not donnees_list:
        raise HTTPException(
            status_code=404,
            detail=f"Aucune donnée agronomique pour le champ '{champ_id}'.",
        )
    return donnees_list[0]


@router.get(
    "/champ/{champ_id}/evolution",
    summary="Évolution des données agronomiques",
    description="Retourne les tendances d'évolution des paramètres agronomiques d'un champ.",
    status_code=status.HTTP_200_OK,
)
async def evolution_donnees(
    champ_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    champ = await champs_service.lire(champ_id)
    if champ is None:
        raise HTTPException(status_code=404, detail="Champ introuvable.")

    uid = courant["uid"]
    if courant.get("role") not in ["ADMIN", "EXPERT"] and champ.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Accès refusé.")

    donnees = await donnees_agronomiques_svc.lister(
        filtres=[("champId", "==", champ_id)],
        ordre_par="dateSaisie",
        decroissant=False,
        limite=100,
    )
    if len(donnees) < 2:
        return {
            "champId": champ_id,
            "message": "Données insuffisantes pour calculer une évolution (minimum 2 mesures).",
            "donnees": donnees,
        }

    import statistics
    phs = [d.get("phSol", 0) for d in donnees if d.get("phSol")]
    humidites = [d.get("humiditeObservee", 0) for d in donnees if d.get("humiditeObservee")]

    return {
        "champId": champ_id,
        "nbMesures": len(donnees),
        "periodeDebut": donnees[0].get("dateSaisie"),
        "periodeFin": donnees[-1].get("dateSaisie"),
        "phMoyen": statistics.mean(phs) if phs else None,
        "humiditeMoyenne": statistics.mean(humidites) if humidites else None,
        "tendancePh": (phs[-1] - phs[0]) if len(phs) >= 2 else 0,
        "tendanceHumidite": (humidites[-1] - humidites[0]) if len(humidites) >= 2 else 0,
        "donnees": donnees,
    }
