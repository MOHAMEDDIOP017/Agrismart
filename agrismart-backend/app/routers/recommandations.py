"""Router FastAPI — Module IA 1 : Recommandation de cultures."""

import logging
from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.core.dependencies import get_utilisateur_courant
from app.core.exceptions import koobalatec_exception_handler, KoobalaTechException
from app.models.recommandation_culture import ResultatRecommandation
from app.models.recommandation_post_recolte import RecommandationPostRecolteCreate
from app.services.recommandation_service import (
    recommandation_service,
    PRIX_MARCHE_PAR_CULTURE,
    RENDEMENT_PAR_CULTURE,
)
from app.services.firestore_service import (
    recommandations_svc, recommandations_pr_svc, champs_service
)
from app.services.notification_service import notification_service
from app.services.historique_service import historique_service
from app.models.enums import TypeNotification
from app.utils.helpers import maintenant_utc

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/recommandations", tags=["Module IA - Recommandation cultures"])


@router.post(
    "/generer/{champ_id}",
    summary="Générer des recommandations de cultures (IA)",
    description=(
        "Déclenche le moteur d'IA (Random Forest) pour recommander les meilleures cultures "
        "pour un champ donné. Combine données agronomiques + données météo actuelles. "
        "Retourne le top 3 des cultures avec scores et conseils."
    ),
    status_code=status.HTTP_201_CREATED,
    response_model=ResultatRecommandation,
)
async def generer_recommandations(
    champ_id: str,
    top_k: int = Query(default=3, ge=1, le=5, description="Nombre de recommandations"),
    courant: dict = Depends(get_utilisateur_courant),
) -> ResultatRecommandation:
    """
    Workflow complet du Module IA 1 :
    1. Vérifie l'accès au champ
    2. Récupère les données agronomiques récentes
    3. Appelle OpenWeatherMap pour la météo actuelle
    4. Charge le modèle Random Forest
    5. Prédit les cultures recommandées
    6. Sauvegarde en Firestore
    7. Envoie une notification à l'agriculteur
    """
    uid = courant["uid"]

    # Vérification de l'accès au champ
    champ = await champs_service.lire(champ_id)
    if champ is None:
        raise HTTPException(status_code=404, detail=f"Champ '{champ_id}' introuvable.")
    if courant.get("role") not in ["ADMIN", "EXPERT"] and champ.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Accès refusé à ce champ.")

    try:
        resultat = await recommandation_service.generer_recommandations(
            champ_id=champ_id,
            utilisateur_id=uid,
            top_k=top_k,
        )

        # Notification à l'agriculteur
        try:
            top_culture = resultat.topRecommandations[0].cultureNom if resultat.topRecommandations else "N/A"
            await notification_service.envoyer_notification(
                destinataire_id=uid,
                type_notif=TypeNotification.RECOMMANDATION,
                titre="Nouvelles recommandations disponibles",
                corps=f"Culture recommandée pour votre champ : {top_culture}. Consultez vos recommandations.",
                reference_id=resultat.recommandationsSauvegardees[0] if resultat.recommandationsSauvegardees else None,
            )
        except Exception as notif_err:
            logger.warning(f"Notification non envoyée : {notif_err}")

        await historique_service.enregistrer(
            uid, "GENERATION_RECOMMANDATION",
            f"Recommandations générées pour le champ {champ_id}",
            champ_id,
        )

        return resultat

    except KoobalaTechException as e:
        raise koobalatec_exception_handler(e)
    except Exception as e:
        logger.error(f"Erreur lors de la génération des recommandations : {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get(
    "/champ/{champ_id}",
    summary="Historique des recommandations d'un champ",
    description="Retourne toutes les recommandations générées pour un champ.",
    status_code=status.HTTP_200_OK,
)
async def recommandations_champ(
    champ_id: str,
    limite: int = Query(default=10, ge=1, le=50),
    courant: dict = Depends(get_utilisateur_courant),
):
    champ = await champs_service.lire(champ_id)
    if champ is None:
        raise HTTPException(status_code=404, detail="Champ introuvable.")

    uid = courant["uid"]
    if courant.get("role") not in ["ADMIN", "EXPERT"] and champ.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Accès refusé.")

    recommandations = await recommandations_svc.lister(
        filtres=[("champId", "==", champ_id)],
        ordre_par="date",
        decroissant=True,
        limite=limite,
    )
    return {"champId": champ_id, "recommandations": recommandations, "total": len(recommandations)}


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
