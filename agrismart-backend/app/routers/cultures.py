"""Router FastAPI — Catalogue des cultures agricoles."""

import logging
from fastapi import APIRouter, Depends, HTTPException, status

from app.core.dependencies import get_utilisateur_courant, require_admin
from app.models.culture import CultureCreate, CultureUpdate
from app.services.firestore_service import cultures_service, analyses_parcelles_svc, champs_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/cultures", tags=["Cultures"])


@router.get(
    "",
    summary="Lister toutes les cultures",
    description="Retourne le catalogue complet des cultures supportées par KoobalaTech.",
    status_code=status.HTTP_200_OK,
)
async def lister_cultures(
    courant: dict = Depends(get_utilisateur_courant),
):
    cultures = await cultures_service.lister(limite=200)
    return {"cultures": cultures, "total": len(cultures)}


@router.get(
    "/{culture_id}",
    summary="Détails d'une culture",
    description="Retourne les informations détaillées d'une culture.",
    status_code=status.HTTP_200_OK,
)
async def obtenir_culture(
    culture_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    culture = await cultures_service.lire(culture_id)
    if culture is None:
        raise HTTPException(status_code=404, detail=f"Culture '{culture_id}' introuvable.")
    return culture


@router.get(
    "/compatibles/{champ_id}",
    summary="Cultures compatibles avec un champ",
    description=(
        "Analyse la dernière AnalyseParcelle d'un champ (collectée automatiquement) "
        "et retourne les cultures les plus compatibles selon le pH et l'humidité. "
        "Heuristique simple, indépendante du moteur multi-label (voir /recommandations/v2 "
        "pour la recommandation IA à proprement parler)."
    ),
    status_code=status.HTTP_200_OK,
)
async def cultures_compatibles(
    champ_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    """Compatibilité basée sur les seuils optimaux de chaque culture."""
    champ = await champs_service.lire(champ_id)
    if champ is None:
        raise HTTPException(status_code=404, detail="Champ introuvable.")

    analyses_list = await analyses_parcelles_svc.lister(
        filtres=[("champId", "==", champ_id)], limite=1,
        ordre_par="dateAnalyse", decroissant=True,
    )
    if not analyses_list:
        raise HTTPException(
            status_code=422,
            detail="Aucune AnalyseParcelle disponible pour ce champ "
                   "(générez d'abord une recommandation via /recommandations/v2).",
        )

    analyse = analyses_list[0]
    ph_sol = analyse.get("phEau", 6.5)
    humidite = analyse.get("humiditeMoy", 50)

    cultures = await cultures_service.lister(limite=200)
    compatibles = []

    for culture in cultures:
        score = 0.0
        raisons = []
        avertissements = []

        # Compatibilité pH
        ph_opt = culture.get("phOptimal", 6.5)
        ecart_ph = abs(ph_sol - ph_opt)
        if ecart_ph <= 0.5:
            score += 0.4
            raisons.append(f"pH du sol ({ph_sol}) proche de l'optimum ({ph_opt})")
        elif ecart_ph <= 1.0:
            score += 0.2
            avertissements.append(f"pH légèrement éloigné de l'optimum ({ph_opt})")
        else:
            avertissements.append(f"pH incompatible : sol={ph_sol}, optimum={ph_opt}")

        # Compatibilité humidité
        h_min = culture.get("humiditeMin", 30)
        h_max = culture.get("humiditeMax", 80)
        if h_min <= humidite <= h_max:
            score += 0.4
            raisons.append(f"Humidité ({humidite}%) dans la plage optimale [{h_min}-{h_max}%]")
        else:
            avertissements.append(f"Humidité ({humidite}%) hors plage [{h_min}-{h_max}%]")

        score += 0.2  # Score de base

        if score > 0.3:
            compatibles.append({
                "culture": culture,
                "scoreCompatibilite": round(score, 2),
                "raisonsCompatibilite": raisons,
                "avertissements": avertissements,
            })

    # Tri par score décroissant
    compatibles.sort(key=lambda x: x["scoreCompatibilite"], reverse=True)
    return {"champId": champ_id, "cultures": compatibles[:10]}


@router.post(
    "",
    summary="Ajouter une culture au catalogue",
    description="Ajoute une nouvelle culture au catalogue (admin uniquement).",
    status_code=status.HTTP_201_CREATED,
)
async def creer_culture(
    donnees: CultureCreate,
    admin: dict = Depends(require_admin()),
):
    culture_id = await cultures_service.creer(donnees.model_dump())
    return {"id": culture_id, **donnees.model_dump()}
