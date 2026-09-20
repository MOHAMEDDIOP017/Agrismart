"""
Router FastAPI — Actions génériques sur les recommandations de cultures.

Ce router n'héberge plus de moteur de prédiction (le SVM v1 a été retiré :
ses artefacts n'ont jamais été présents dans le dépôt, la comparaison prévue
pour le mémoire n'était pas réalisable). Il reste utile pour deux endpoints
génériques, indépendants du moteur ayant produit la recommandation (v2
multi-label aujourd'hui) : la consultation d'une recommandation par id et le
calcul post-récolte, tous deux consommés par l'app Flutter. Le moteur actif
vit dans `app/routers/recommandations_v2.py`.
"""

import logging
from fastapi import APIRouter, Depends, HTTPException, status

from app.core.dependencies import get_utilisateur_courant
from app.services.fiches_cultures import PRIX_MARCHE_PAR_CULTURE, RENDEMENT_PAR_CULTURE
from app.services.firestore_service import recommandations_svc, recommandations_pr_svc
from app.utils.helpers import maintenant_utc

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/recommandations", tags=["Recommandations cultures — actions génériques"])


@router.get(
    "/{recommandation_id}",
    summary="Détails d'une recommandation",
    description="Retourne les détails complets d'une recommandation de culture.",
    status_code=status.HTTP_200_OK,
)
async def obtenir_recommandation(
    recommandation_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    reco = await recommandations_svc.lire(recommandation_id)
    if reco is None:
        raise HTTPException(status_code=404, detail="Recommandation introuvable.")

    uid = courant["uid"]
    if courant.get("role") not in ["ADMIN", "EXPERT"] and reco.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Accès refusé.")

    return reco


@router.post(
    "/{recommandation_id}/post-recolte",
    summary="Générer une recommandation post-récolte",
    description=(
        "Calcule une recommandation post-récolte (vente brute vs transformation) "
        "pour une recommandation de culture existante."
    ),
    status_code=status.HTTP_201_CREATED,
)
async def generer_post_recolte(
    recommandation_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    """Génère deux scénarios post-récolte et sauvegarde le meilleur."""
    reco = await recommandations_svc.lire(recommandation_id)
    if reco is None:
        raise HTTPException(status_code=404, detail="Recommandation introuvable.")

    uid = courant["uid"]
    if courant.get("role") not in ["ADMIN", "EXPERT"] and reco.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Accès refusé.")

    culture_nom = reco.get("cultureNom") or reco.get("cultureRecommandeeId", "")
    rendement = float(reco.get("rendementEstime") or RENDEMENT_PAR_CULTURE.get(culture_nom, 1.0))

    # Prix réels par culture (FCFA/kg) — source ANSD / marchés ruraux sénégalais
    prix_brut_kg = reco.get("prixMarcheEstime") or PRIX_MARCHE_PAR_CULTURE.get(culture_nom, 200)
    # Coût de transformation : 35 % du prix brut (séchage, conditionnement, transport)
    cout_transfo_kg = round(prix_brut_kg * 0.35)
    # Prix transformé : 2.2× le prix brut (valeur ajoutée conditionnement / 2e transformation)
    prix_transforme_kg = round(prix_brut_kg * 2.2)

    quantite_kg = rendement * 1000  # t → kg

    profit_vente  = quantite_kg * prix_brut_kg
    profit_transfo = quantite_kg * (prix_transforme_kg - cout_transfo_kg)

    # Score économique : proportion du profit par rapport au scénario le plus rentable
    max_profit = max(profit_vente, profit_transfo)
    score_vente  = round(profit_vente  / max_profit, 2) if max_profit > 0 else 0.5
    score_transfo = round(profit_transfo / max_profit, 2) if max_profit > 0 else 0.75

    scenario_vente = {
        "recommandationCultureId": recommandation_id,
        "typeRec": "VENTE_BRUTE",
        "score": score_vente,
        "prixVenteEstime": round(profit_vente),
        "coutTransformation": 0.0,
        "profitPotentiel": round(profit_vente),
        "date": maintenant_utc(),
    }
    scenario_transfo = {
        "recommandationCultureId": recommandation_id,
        "typeRec": "TRANSFORMATION",
        "score": score_transfo,
        "prixVenteEstime": round(quantite_kg * prix_transforme_kg),
        "coutTransformation": round(quantite_kg * cout_transfo_kg),
        "profitPotentiel": round(profit_transfo),
        "date": maintenant_utc(),
    }

    id_vente = await recommandations_pr_svc.creer(scenario_vente)
    id_transfo = await recommandations_pr_svc.creer(scenario_transfo)

    return {
        "recommandationCultureId": recommandation_id,
        "scenarios": [
            {"id": id_vente, **scenario_vente},
            {"id": id_transfo, **scenario_transfo},
        ],
    }
