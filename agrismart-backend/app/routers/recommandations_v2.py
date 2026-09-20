"""Router FastAPI — Module IA 1 (v2) : Recommandation de cultures (multi-label)."""

import logging
from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.core.dependencies import get_utilisateur_courant
from app.core.exceptions import koobalatec_exception_handler, KoobalaTechException
from app.models.recommandation_culture_v2 import (
    ResultatRecommandationV2,
    RecommandationCultureV2Response,
    ValiderRecommandationRequest,
    CorrigerRecommandationRequest,
    RejeterRecommandationRequest,
)
from app.services.recommandation_service_v2 import recommandation_service_v2
from app.services.firestore_service import champs_service, recommandations_svc
from app.services.notification_service import notification_service
from app.services.historique_service import historique_service
from app.models.enums import TypeNotification

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/recommandations/v2",
    tags=["Module IA - Recommandation cultures (v2, multi-label)"],
)


def _verifier_role_expert(courant: dict) -> None:
    if courant.get("role") not in ["ADMIN", "EXPERT"]:
        raise HTTPException(status_code=403, detail="Réservé aux experts et administrateurs.")


@router.post(
    "/generer/{champ_id}",
    summary="Générer des recommandations de cultures (IA multi-label)",
    description=(
        "Déclenche le nouveau moteur d'IA multi-label (RandomForest, 16 variables "
        "sol/climat/NDVI dérivées de la localisation du champ) pour recommander les "
        "cultures les mieux adaptées. Persiste une AnalyseParcelle (remplace la saisie "
        "manuelle) puis un top-K de RecommandationCulture (rang 1..k), chacune avec sa "
        "probabilité d'aptitude et son propre statut de validation expert."
    ),
    status_code=status.HTTP_201_CREATED,
    response_model=ResultatRecommandationV2,
)
async def generer_recommandations_v2(
    champ_id: str,
    top_k: int = Query(default=3, ge=1, le=3, description="Nombre de recommandations (top-3 max)"),
    courant: dict = Depends(get_utilisateur_courant),
) -> ResultatRecommandationV2:
    uid = courant["uid"]

    champ = await champs_service.lire(champ_id)
    if champ is None:
        raise HTTPException(status_code=404, detail=f"Champ '{champ_id}' introuvable.")
    if courant.get("role") not in ["ADMIN", "EXPERT"] and champ.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Accès refusé à ce champ.")

    try:
        resultat = await recommandation_service_v2.generer_recommandations(
            champ_id=champ_id,
            utilisateur_id=uid,
            top_k=top_k,
        )

        try:
            top_culture = (
                resultat.topRecommandations[0].cultureNom
                if resultat.topRecommandations else "N/A"
            )
            await notification_service.envoyer_notification(
                destinataire_id=uid,
                type_notif=TypeNotification.RECOMMANDATION,
                titre="Nouvelles recommandations disponibles",
                corps=f"Culture recommandée pour votre champ : {top_culture}. Consultez vos recommandations.",
                reference_id=resultat.topRecommandations[0].id if resultat.topRecommandations else None,
            )
        except Exception as notif_err:
            logger.warning(f"Notification non envoyée : {notif_err}")

        await historique_service.enregistrer(
            uid, "GENERATION_RECOMMANDATION_V2",
            f"Recommandations multi-label générées pour le champ {champ_id}",
            champ_id,
        )

        return resultat

    except KoobalaTechException as e:
        raise koobalatec_exception_handler(e)
    except Exception as e:
        logger.error(f"Erreur lors de la génération des recommandations v2 : {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get(
    "/champ/{champ_id}",
    summary="Historique des recommandations multi-label d'un champ",
    description="Retourne toutes les RecommandationCulture (v2) générées pour un champ.",
    status_code=status.HTTP_200_OK,
)
async def recommandations_champ_v2(
    champ_id: str,
    limite: int = Query(default=30, ge=1, le=100),
    courant: dict = Depends(get_utilisateur_courant),
):
    champ = await champs_service.lire(champ_id)
    if champ is None:
        raise HTTPException(status_code=404, detail="Champ introuvable.")

    uid = courant["uid"]
    if courant.get("role") not in ["ADMIN", "EXPERT"] and champ.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Accès refusé.")

    recommandations = await recommandations_svc.lister(
        filtres=[("champId", "==", champ_id), ("moteur", "==", "MULTILABEL")],
        ordre_par="date",
        decroissant=True,
        limite=limite,
    )
    return {"champId": champ_id, "recommandations": recommandations, "total": len(recommandations)}


@router.get(
    "/en-attente",
    summary="Analyses en attente de validation, groupées par top-3 (Expert)",
    description=(
        "Une carte par AnalyseParcelle ayant un top-3 EN_ATTENTE : regroupe les 1 à 3 "
        "RecommandationCulture d'une même analyse (champ, agriculteur, snapshot des "
        "16 variables, top-3 cultures). Chaque RecommandationCulture garde son propre "
        "statutValidation en base ; valider/corriger/rejeter agit sur le groupe entier."
    ),
    status_code=status.HTTP_200_OK,
)
async def recommandations_en_attente(
    courant: dict = Depends(get_utilisateur_courant),
):
    _verifier_role_expert(courant)
    cartes = await recommandation_service_v2.lister_en_attente_groupees()
    return {"recommandations": cartes, "total": len(cartes)}


@router.post(
    "/{recommandation_id}/valider",
    summary="Valider une recommandation (Expert)",
    status_code=status.HTTP_200_OK,
    response_model=RecommandationCultureV2Response,
)
async def valider_recommandation_v2(
    recommandation_id: str,
    donnees: ValiderRecommandationRequest,
    courant: dict = Depends(get_utilisateur_courant),
) -> RecommandationCultureV2Response:
    _verifier_role_expert(courant)
    try:
        reco = await recommandation_service_v2.valider(
            recommandation_id, courant["uid"], donnees.commentaire
        )
        await historique_service.enregistrer(
            courant["uid"], "VALIDATION_RECOMMANDATION_V2",
            f"Recommandation {recommandation_id} validée", recommandation_id,
        )
        return reco
    except KoobalaTechException as e:
        raise koobalatec_exception_handler(e)


@router.post(
    "/{recommandation_id}/corriger",
    summary="Corriger une recommandation (Expert)",
    status_code=status.HTTP_200_OK,
    response_model=RecommandationCultureV2Response,
)
async def corriger_recommandation_v2(
    recommandation_id: str,
    donnees: CorrigerRecommandationRequest,
    courant: dict = Depends(get_utilisateur_courant),
) -> RecommandationCultureV2Response:
    _verifier_role_expert(courant)
    try:
        reco = await recommandation_service_v2.corriger(
            recommandation_id, courant["uid"], donnees.commentaire, donnees.cultureCorrigeeNom
        )
        await historique_service.enregistrer(
            courant["uid"], "CORRECTION_RECOMMANDATION_V2",
            f"Recommandation {recommandation_id} corrigée", recommandation_id,
        )
        return reco
    except KoobalaTechException as e:
        raise koobalatec_exception_handler(e)


@router.post(
    "/{recommandation_id}/rejeter",
    summary="Rejeter une recommandation (Expert)",
    status_code=status.HTTP_200_OK,
    response_model=RecommandationCultureV2Response,
)
async def rejeter_recommandation_v2(
    recommandation_id: str,
    donnees: RejeterRecommandationRequest,
    courant: dict = Depends(get_utilisateur_courant),
) -> RecommandationCultureV2Response:
    _verifier_role_expert(courant)
    try:
        reco = await recommandation_service_v2.rejeter(
            recommandation_id, courant["uid"], donnees.motif
        )
        await historique_service.enregistrer(
            courant["uid"], "REJET_RECOMMANDATION_V2",
            f"Recommandation {recommandation_id} rejetée", recommandation_id,
        )
        return reco
    except KoobalaTechException as e:
        raise koobalatec_exception_handler(e)


# ─── Actions groupées (une AnalyseParcelle = un top-3 = une décision) ─────────
# Consommées par l'écran expert (carte "top-3"). Appliquent la même action aux
# 1 à 3 RecommandationCulture d'une même AnalyseParcelle ; chacune garde son
# statutValidation propre en base (conforme au diagramme), simplement mis à
# jour ensemble ici.

@router.post(
    "/analyses/{analyse_id}/valider",
    summary="Valider le top-3 d'une AnalyseParcelle (Expert)",
    status_code=status.HTTP_200_OK,
)
async def valider_analyse_v2(
    analyse_id: str,
    donnees: ValiderRecommandationRequest,
    courant: dict = Depends(get_utilisateur_courant),
):
    _verifier_role_expert(courant)
    try:
        carte = await recommandation_service_v2.valider_groupe(
            analyse_id, courant["uid"], donnees.commentaire
        )
        await historique_service.enregistrer(
            courant["uid"], "VALIDATION_RECOMMANDATION_V2",
            f"Analyse {analyse_id} validée", analyse_id,
        )
        return carte
    except KoobalaTechException as e:
        raise koobalatec_exception_handler(e)


@router.post(
    "/analyses/{analyse_id}/corriger",
    summary="Corriger le top-3 d'une AnalyseParcelle (Expert)",
    status_code=status.HTTP_200_OK,
)
async def corriger_analyse_v2(
    analyse_id: str,
    donnees: CorrigerRecommandationRequest,
    courant: dict = Depends(get_utilisateur_courant),
):
    _verifier_role_expert(courant)
    try:
        carte = await recommandation_service_v2.corriger_groupe(
            analyse_id, courant["uid"], donnees.commentaire, donnees.cultureCorrigeeNom
        )
        await historique_service.enregistrer(
            courant["uid"], "CORRECTION_RECOMMANDATION_V2",
            f"Analyse {analyse_id} corrigée", analyse_id,
        )
        return carte
    except KoobalaTechException as e:
        raise koobalatec_exception_handler(e)


@router.post(
    "/analyses/{analyse_id}/rejeter",
    summary="Rejeter le top-3 d'une AnalyseParcelle (Expert)",
    status_code=status.HTTP_200_OK,
)
async def rejeter_analyse_v2(
    analyse_id: str,
    donnees: RejeterRecommandationRequest,
    courant: dict = Depends(get_utilisateur_courant),
):
    _verifier_role_expert(courant)
    try:
        carte = await recommandation_service_v2.rejeter_groupe(
            analyse_id, courant["uid"], donnees.motif
        )
        await historique_service.enregistrer(
            courant["uid"], "REJET_RECOMMANDATION_V2",
            f"Analyse {analyse_id} rejetée", analyse_id,
        )
        return carte
    except KoobalaTechException as e:
        raise koobalatec_exception_handler(e)
