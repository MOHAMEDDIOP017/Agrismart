"""Router FastAPI — Module IA 2 : Détection de maladies des plantes."""

import logging
from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import Optional

from app.core.dependencies import get_utilisateur_courant, require_expert
from app.core.exceptions import koobalatec_exception_handler, KoobalaTechException
from app.models.diagnostic_maladie import (
    ResultatAnalyseIA,
    ValidationDiagnostic,
    CorrectionDiagnostic,
    EvaluationDiagnostic,
)
from app.models.enums import StatutValidation, TypeNotification
from app.services.detection_service import detection_service
from app.services.firestore_service import (
    diagnostics_svc, images_plantes_svc, maladies_service
)
from app.services.notification_service import notification_service
from app.services.historique_service import historique_service
from app.utils.helpers import maintenant_utc

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/diagnostics", tags=["Module IA - Détection maladies"])


@router.post(
    "/analyser/{image_id}",
    summary="Analyser une image de plante (IA)",
    description=(
        "Lance l'analyse IA (EfficientNetB0) sur une image préalablement uploadée. "
        "Retourne la maladie détectée avec son score de confiance et le top-3 des prédictions. "
        "Si le score est sous le seuil, le statut est EN_ATTENTE (validation expert requise). "
        "Si gravité ELEVE/CRITIQUE, une alerte push est envoyée à l'agriculteur."
    ),
    status_code=status.HTTP_201_CREATED,
    response_model=ResultatAnalyseIA,
)
async def analyser_image(
    image_id: str,
    champ_id: Optional[str] = Query(None, description="ID du champ associé"),
    seuil_confiance: Optional[float] = Query(
        None, ge=0.1, le=1.0, description="Seuil de confiance (défaut: 0.7)"
    ),
    courant: dict = Depends(get_utilisateur_courant),
) -> ResultatAnalyseIA:
    """
    Workflow complet du Module IA 2 :
    1. Télécharge l'image depuis Firebase Storage
    2. Prétraite l'image (224x224, normalisation)
    3. Inférence EfficientNetB0 (TFLite)
    4. Détermine le statut selon le seuil
    5. Génère traitement recommandé si AUTO_CONFIRME
    6. Envoie alerte si ELEVE/CRITIQUE
    7. Sauvegarde le diagnostic en Firestore
    """
    uid = courant["uid"]

    # Vérification que l'image appartient à l'utilisateur
    image = await images_plantes_svc.lire(image_id)
    if image is None:
        raise HTTPException(status_code=404, detail=f"Image '{image_id}' introuvable.")
    if courant.get("role") not in ["ADMIN", "EXPERT"] and image.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Accès refusé à cette image.")

    try:
        resultat = await detection_service.analyser_image(
            image_id=image_id,
            agriculteur_id=uid,
            champ_id=champ_id or image.get("champId"),
            seuil_confiance=seuil_confiance,
        )

        # Alerte si maladie grave
        if resultat.alerteEnvoyee and resultat.maladieDetectee:
            try:
                await notification_service.envoyer_alerte_maladie(
                    agriculteur_id=uid,
                    nom_maladie=resultat.maladieDetectee,
                    diagnostic_id=resultat.diagnosticId,
                    gravite="ELEVE",
                )
            except Exception as notif_err:
                logger.warning(f"Alerte non envoyée : {notif_err}")

        await historique_service.enregistrer(
            uid, "ANALYSE_IA",
            f"Analyse IA image {image_id} — Score : {resultat.scoreConfiance:.2f}",
            resultat.diagnosticId,
            {"maladie": resultat.maladieDetectee, "statut": resultat.statut.value},
        )

        return resultat

    except KoobalaTechException as e:
        raise koobalatec_exception_handler(e)
    except Exception as e:
        logger.error(f"Erreur lors de l'analyse IA : {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get(
    "/en-attente",
    summary="Diagnostics en attente de validation",
    description="Retourne les diagnostics dont le score est sous le seuil et qui attendent une validation d'expert.",
    status_code=status.HTTP_200_OK,
)
async def diagnostics_en_attente(
    limite: int = Query(default=20, ge=1, le=100),
    expert: dict = Depends(require_expert()),
):
    """Accessible uniquement aux experts et administrateurs."""
    diagnostics = await diagnostics_svc.lister(
        filtres=[("statut", "==", StatutValidation.EN_ATTENTE.value)],
        ordre_par="dateAnalyse",
        decroissant=True,
        limite=limite,
    )
    return {"diagnostics": diagnostics, "total": len(diagnostics)}


@router.get(
    "/agriculteur/{agriculteur_id}",
    summary="Diagnostics d'un agriculteur",
    description="Retourne l'historique des diagnostics d'un agriculteur.",
    status_code=status.HTTP_200_OK,
)
async def diagnostics_agriculteur(
    agriculteur_id: str,
    limite: int = Query(default=20, ge=1, le=100),
    courant: dict = Depends(get_utilisateur_courant),
):
    uid = courant["uid"]
    if courant.get("role") not in ["ADMIN", "EXPERT"] and uid != agriculteur_id:
        raise HTTPException(status_code=403, detail="Accès refusé.")

    diagnostics = await diagnostics_svc.lister(
        filtres=[("agriculteurId", "==", agriculteur_id)],
        ordre_par="dateAnalyse",
        decroissant=True,
        limite=limite,
    )
    return {"diagnostics": diagnostics, "total": len(diagnostics)}


@router.get(
    "/{diagnostic_id}",
    summary="Détails d'un diagnostic",
    description="Retourne les détails complets d'un diagnostic de maladie.",
    status_code=status.HTTP_200_OK,
)
async def obtenir_diagnostic(
    diagnostic_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    diagnostic = await diagnostics_svc.lire(diagnostic_id)
    if diagnostic is None:
        raise HTTPException(status_code=404, detail=f"Diagnostic '{diagnostic_id}' introuvable.")

    uid = courant["uid"]
    role = courant.get("role", "")
    if role not in ["ADMIN", "EXPERT"] and diagnostic.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Accès refusé.")

    return diagnostic


@router.post(
    "/{diagnostic_id}/valider",
    summary="Valider un diagnostic (Expert)",
    description="Un expert confirme le diagnostic IA et peut ajouter un commentaire.",
    status_code=status.HTTP_200_OK,
)
async def valider_diagnostic(
    diagnostic_id: str,
    corps: ValidationDiagnostic,
    expert: dict = Depends(require_expert()),
):
    diagnostic = await diagnostics_svc.lire(diagnostic_id)
    if diagnostic is None:
        raise HTTPException(status_code=404, detail="Diagnostic introuvable.")

    expert_id = expert["uid"]
    await diagnostics_svc.mettre_a_jour(diagnostic_id, {
        "statut": StatutValidation.VALIDE_EXPERT.value,
        "expertId": expert_id,
        "maladieId": corps.maladieId,
        "commentaireExpert": corps.commentaireExpert,
    })

    # Notification à l'agriculteur
    try:
        await notification_service.envoyer_notification(
            destinataire_id=diagnostic.get("agriculteurId", ""),
            type_notif=TypeNotification.VALIDATION_DIAGNOSTIC,
            titre="Diagnostic validé par un expert",
            corps=f"Votre diagnostic a été validé. {corps.commentaireExpert[:100]}...",
            reference_id=diagnostic_id,
        )
    except Exception as e:
        logger.warning(f"Notification validation non envoyée : {e}")

    return {"message": "Diagnostic validé.", "diagnosticId": diagnostic_id}


@router.post(
    "/{diagnostic_id}/corriger",
    summary="Corriger un diagnostic (Expert)",
    description="Un expert corrige la maladie identifiée par l'IA.",
    status_code=status.HTTP_200_OK,
)
async def corriger_diagnostic(
    diagnostic_id: str,
    corps: CorrectionDiagnostic,
    expert: dict = Depends(require_expert()),
):
    diagnostic = await diagnostics_svc.lire(diagnostic_id)
    if diagnostic is None:
        raise HTTPException(status_code=404, detail="Diagnostic introuvable.")

    expert_id = expert["uid"]
    await diagnostics_svc.mettre_a_jour(diagnostic_id, {
        "statut": StatutValidation.VALIDE_EXPERT.value,
        "expertId": expert_id,
        "maladieId": corps.maladieIdCorrecte,
        "commentaireExpert": corps.commentaireExpert,
    })

    return {"message": "Diagnostic corrigé.", "diagnosticId": diagnostic_id}


@router.post(
    "/{diagnostic_id}/evaluer",
    summary="Évaluer un diagnostic (Agriculteur)",
    description="L'agriculteur note la qualité du diagnostic de 1 à 5 étoiles.",
    status_code=status.HTTP_200_OK,
)
async def evaluer_diagnostic(
    diagnostic_id: str,
    corps: EvaluationDiagnostic,
    courant: dict = Depends(get_utilisateur_courant),
):
    diagnostic = await diagnostics_svc.lire(diagnostic_id)
    if diagnostic is None:
        raise HTTPException(status_code=404, detail="Diagnostic introuvable.")

    uid = courant["uid"]
    if diagnostic.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Seul l'agriculteur concerné peut évaluer.")

    await diagnostics_svc.mettre_a_jour(diagnostic_id, {
        "evaluationAgriculteur": corps.note,
    })

    return {"message": "Évaluation enregistrée.", "note": corps.note}


@router.post(
    "/{diagnostic_id}/partager-expert",
    summary="Partager avec un expert",
    description="L'agriculteur envoie le diagnostic à un expert pour validation.",
    status_code=status.HTTP_200_OK,
)
async def partager_avec_expert(
    diagnostic_id: str,
    expert_id: str,
    courant: dict = Depends(get_utilisateur_courant),
):
    diagnostic = await diagnostics_svc.lire(diagnostic_id)
    if diagnostic is None:
        raise HTTPException(status_code=404, detail="Diagnostic introuvable.")

    uid = courant["uid"]
    if diagnostic.get("agriculteurId") != uid:
        raise HTTPException(status_code=403, detail="Accès non autorisé.")

    # Notification à l'expert
    try:
        await notification_service.envoyer_notification(
            destinataire_id=expert_id,
            type_notif=TypeNotification.VALIDATION_DIAGNOSTIC,
            titre="Diagnostic partagé par un agriculteur",
            corps="Un agriculteur vous a partagé un diagnostic en attente de validation.",
            reference_id=diagnostic_id,
            urgent=True,
        )
    except Exception as e:
        logger.warning(f"Notification expert non envoyée : {e}")

    return {"message": f"Diagnostic partagé avec l'expert {expert_id}.", "diagnosticId": diagnostic_id}
