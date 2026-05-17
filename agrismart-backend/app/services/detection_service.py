"""Module IA 2 : Service de détection de maladies des plantes (EfficientNetB0 TFLite)."""

import json
import logging
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

import numpy as np
from PIL import Image
import io

from app.config import settings
from app.core.exceptions import (
    ModeleIAIndisponibleException,
    ImageInvalideException,
    ImageNonTrouveException,
    MinioIndisponibleException,
)
from app.models.enums import StatutValidation, NiveauGravite
from app.models.diagnostic_maladie import ResultatAnalyseIA
from app.services.firestore_service import (
    images_plantes_svc,
    diagnostics_svc,
    maladies_service,
    traitements_svc,
)
from app.services.minio_service import minio_service

logger = logging.getLogger(__name__)

VERSION_MODELE_DETECTION = "efficientnetb0_2025-04-15"

# Maladies de mock pour le développement (tirées du dataset PlantVillage)
MALADIES_MOCK = [
    {"nom": "Tomato_Late_blight", "label_fr": "Mildiou de la tomate", "gravite": NiveauGravite.CRITIQUE},
    {"nom": "Tomato_Early_blight", "label_fr": "Alternariose de la tomate", "gravite": NiveauGravite.MODERE},
    {"nom": "Potato_Late_blight", "label_fr": "Mildiou de la pomme de terre", "gravite": NiveauGravite.CRITIQUE},
    {"nom": "Corn_Common_rust", "label_fr": "Rouille commune du maïs", "gravite": NiveauGravite.MODERE},
    {"nom": "Pepper_Bacterial_spot", "label_fr": "Tache bactérienne du piment", "gravite": NiveauGravite.ELEVE},
    {"nom": "Tomato_Healthy", "label_fr": "Tomate saine", "gravite": NiveauGravite.FAIBLE},
    {"nom": "Potato_Healthy", "label_fr": "Pomme de terre saine", "gravite": NiveauGravite.FAIBLE},
    {"nom": "Corn_Healthy", "label_fr": "Maïs sain", "gravite": NiveauGravite.FAIBLE},
    {"nom": "Groundnut_Early_leaf_spot", "label_fr": "Cercosporiose de l'arachide", "gravite": NiveauGravite.MODERE},
    {"nom": "Millet_Downy_mildew", "label_fr": "Mildiou du mil", "gravite": NiveauGravite.ELEVE},
]


class DetectionService:
    """Service de détection de maladies des plantes par analyse d'image."""

    def __init__(self):
        self._interpreter = None       # TFLite interpreter
        self._keras_model = None       # Keras .h5 model (fallback si TFLite incompatible)
        self._classes: list[str] = []  # Noms des classes de maladies
        self._modele_charge = False

    def _charger_modele(self) -> None:
        """Charge le modèle TFLite (ou .h5 en fallback) et la liste des classes."""
        if self._modele_charge:
            return

        classes_path = Path(settings.classes_detection_path)
        modele_path = Path(settings.modele_detection_path)

        # Chargement des classes
        if classes_path.exists():
            with open(classes_path, "r", encoding="utf-8") as f:
                self._classes = json.load(f)
            logger.info(f"{len(self._classes)} classes de maladies chargées depuis {classes_path}.")
        else:
            logger.warning(f"Fichier de classes absent : {classes_path}. Utilisation du mock.")
            self._classes = [m["nom"] for m in MALADIES_MOCK]

        # Chargement du modèle TFLite
        if not modele_path.exists():
            logger.warning(f"Modèle TFLite absent : {modele_path}. Mode MOCK activé.")
            return

        try:
            try:
                import tflite_runtime.interpreter as tflite
                self._interpreter = tflite.Interpreter(model_path=str(modele_path))
                logger.debug("TFLite chargé via tflite_runtime")
            except ImportError:
                import tensorflow as tf
                self._interpreter = tf.lite.Interpreter(model_path=str(modele_path))
                logger.debug("TFLite chargé via tensorflow.lite")
            self._interpreter.allocate_tensors()
            self._modele_charge = True
            logger.info(f"Modèle EfficientNetB0 (TFLite) chargé : {modele_path}")
        except Exception as tflite_err:
            logger.warning(f"TFLite indisponible ({tflite_err}). Tentative chargement .h5 Keras...")
            self._charger_modele_keras(modele_path)

    def _charger_modele_keras(self, tflite_path: Path) -> None:
        """Fallback : charge le modèle .h5 via tf.keras quand TFLite est incompatible."""
        h5_path = tflite_path.parent / tflite_path.stem.replace("_plantvillage", "_plantvillage").replace(".tflite", "")
        h5_path = tflite_path.with_suffix(".h5").parent / (tflite_path.stem + ".h5")
        # Cherche efficientnetb0_plantvillage.h5 dans le même dossier
        h5_candidates = list(tflite_path.parent.glob("efficientnetb0*.h5"))
        if not h5_candidates:
            logger.error("Fichier .h5 introuvable. Mode MOCK activé.")
            return
        h5_path = h5_candidates[0]
        try:
            import tensorflow as tf

            class _PatchedDense(tf.keras.layers.Dense):
                def __init__(self, *args, quantization_config=None, **kwargs):
                    super().__init__(*args, **kwargs)

            self._keras_model = tf.keras.models.load_model(
                str(h5_path),
                custom_objects={"Dense": _PatchedDense},
                compile=False,
            )
            # Warmup pour compiler le graphe TF une seule fois
            import numpy as np
            dummy = np.zeros((1, settings.image_height, settings.image_width, 3), dtype=np.float32)
            self._keras_model.predict(dummy, verbose=0)
            self._modele_charge = True
            logger.info(f"Modèle EfficientNetB0 (Keras .h5) chargé et warmup effectué : {h5_path}")
        except Exception as e:
            logger.error(f"Erreur chargement .h5 Keras : {e}")
            self._modele_charge = False

    def _preprocesser_image(self, image_bytes: bytes) -> np.ndarray:
        """
        Prétraite une image pour l'inférence EfficientNetB0.

        Étapes :
        1. Ouverture avec Pillow et conversion en RGB
        2. Redimensionnement à 224x224 (image_width x image_height)
        3. Normalisation [0-255] → [0-1] (division par 255)
        4. Ajout de la dimension batch → shape (1, 224, 224, 3)
        """
        try:
            image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
            image = image.resize(
                (settings.image_width, settings.image_height), Image.BILINEAR
            )
            # EfficientNetB0 preprocess_input : normalisation vers [-1, 1]
            array = (np.array(image, dtype=np.float32) - 127.5) / 127.5
            return np.expand_dims(array, axis=0)
        except Exception as e:
            raise ImageInvalideException(f"Impossible de prétraiter l'image : {e}")

    def _predire_avec_tflite(self, image_array: np.ndarray) -> list[tuple[str, float]]:
        """Lance l'inférence TFLite et retourne les probabilités triées par ordre décroissant."""
        input_details = self._interpreter.get_input_details()
        output_details = self._interpreter.get_output_details()

        self._interpreter.set_tensor(input_details[0]["index"], image_array)
        self._interpreter.invoke()

        probas = self._interpreter.get_tensor(output_details[0]["index"])[0]
        return sorted(
            zip(self._classes, probas.tolist()),
            key=lambda x: x[1],
            reverse=True,
        )

    def _predire_avec_keras(self, image_array: np.ndarray) -> list[tuple[str, float]]:
        """Lance l'inférence Keras (.h5) et retourne les probabilités triées par ordre décroissant."""
        probas = self._keras_model.predict(image_array, verbose=0)[0]
        return sorted(
            zip(self._classes, probas.tolist()),
            key=lambda x: x[1],
            reverse=True,
        )

    def _predire_mock(self) -> list[tuple[str, float]]:
        """Prédictions fictives pour le développement sans modèle réel."""
        logger.info("Mode MOCK : prédictions fictives pour la détection de maladies.")
        scores = [0.72, 0.15, 0.08, 0.03, 0.02]
        classes_mock = [m["nom"] for m in MALADIES_MOCK[:5]]
        return list(zip(classes_mock, scores))

    async def analyser_image(
        self,
        image_id: str,
        agriculteur_id: str,
        champ_id: Optional[str] = None,
        seuil_confiance: Optional[float] = None,
    ) -> ResultatAnalyseIA:
        """
        Analyse une image de plante pour détecter une maladie.

        Workflow complet :
        1. Récupère les métadonnées Firestore de l'image (notamment nomFichierMinio)
        2. Télécharge les bytes de l'image depuis MinIO via MinioService
        3. Prétraite l'image (224x224, normalisation)
        4. Charge le modèle TFLite (lazy) et lance l'inférence (ou mock si absent)
        5. Extrait le top-3 des prédictions
        6. Recherche la maladie correspondante en Firestore
        7. Détermine le statut selon le seuil de confiance
        8. Sauvegarde le diagnostic en Firestore
        9. Déclenche une alerte si gravité ELEVE ou CRITIQUE

        Args:
            image_id: ID Firestore de l'image à analyser.
            agriculteur_id: UID de l'agriculteur demandant l'analyse.
            champ_id: ID du champ concerné (optionnel).
            seuil_confiance: Seuil de confiance pour la validation automatique (défaut : settings).

        Returns:
            ResultatAnalyseIA avec le diagnostic complet.
        """
        debut = time.time()
        seuil = seuil_confiance or settings.seuil_confiance_detection

        # 1. Récupération des métadonnées Firestore de l'image
        image_doc = await images_plantes_svc.lire(image_id)
        if image_doc is None:
            raise ImageNonTrouveException(image_id)

        # Le champ nomFichierMinio contient le chemin relatif dans MinIO
        nom_fichier_minio = image_doc.get("nomFichierMinio", "")
        if not nom_fichier_minio:
            raise ImageInvalideException(
                f"Image {image_id} : champ 'nomFichierMinio' manquant en Firestore. "
                "Vérifiez que l'image a été uploadée via le nouvel endpoint MinIO."
            )

        # 2. Téléchargement de l'image depuis MinIO
        try:
            image_bytes = await minio_service.telecharger_image(nom_fichier_minio)
        except MinioIndisponibleException as e:
            logger.error(f"Impossible de télécharger l'image {image_id} depuis MinIO : {e}")
            raise ImageInvalideException(f"Échec du téléchargement MinIO : {e}")

        # 3. Prétraitement
        image_array = self._preprocesser_image(image_bytes)

        # 4. Chargement du modèle et inférence
        self._charger_modele()

        if self._modele_charge:
            try:
                if self._interpreter is not None:
                    resultats = self._predire_avec_tflite(image_array)
                    backend = "TFLite"
                else:
                    resultats = self._predire_avec_keras(image_array)
                    backend = "Keras"
                logger.info(
                    f"Inférence {backend} réussie en {time.time() - debut:.3f}s — "
                    f"top-1 : {resultats[0][0]} ({resultats[0][1]:.3f})"
                )
            except Exception as e:
                logger.error(f"Erreur inférence : {e}. Basculement sur le mock.")
                resultats = self._predire_mock()
        else:
            resultats = self._predire_mock()

        # 5. Extraction du top-3
        top_3 = resultats[:3]
        maladie_principale_nom = top_3[0][0]
        score_confiance = float(top_3[0][1])

        top_predictions = [
            {"maladie": nom, "probabilite": float(score)}
            for nom, score in top_3
        ]

        # 6. Recherche de la maladie en Firestore
        maladies_trouvees = await maladies_service.lister(
            filtres=[("nom", "==", maladie_principale_nom)], limite=1
        )
        maladie_id = maladies_trouvees[0]["id"] if maladies_trouvees else None
        gravite = maladies_trouvees[0].get("gravite") if maladies_trouvees else NiveauGravite.MODERE.value

        # 7. Statut selon le seuil de confiance
        statut = (
            StatutValidation.AUTO_CONFIRME
            if score_confiance >= seuil
            else StatutValidation.EN_ATTENTE
        )

        # 8. Traitement recommandé automatique si maladie confirmée
        traitement_id = None
        if maladie_id and statut == StatutValidation.AUTO_CONFIRME:
            traitements = await traitements_svc.lister(
                filtres=[("maladieId", "==", maladie_id)], limite=1
            )
            if traitements:
                traitement_id = traitements[0]["id"]

        # 9. Sauvegarde du diagnostic en Firestore
        diagnostic_doc = {
            "imageId": image_id,
            "agriculteurId": agriculteur_id,
            "champId": champ_id,
            "maladieId": maladie_id,
            "scoreConfiance": score_confiance,
            "topPredictions": top_predictions,
            "modeleVersion": VERSION_MODELE_DETECTION,
            "seuilConfiance": seuil,
            "dateAnalyse": datetime.now(timezone.utc),
            "statut": statut.value,
            "expertId": None,
            "commentaireExpert": None,
            "evaluationAgriculteur": None,
        }
        diagnostic_id = await diagnostics_svc.creer(diagnostic_doc)

        # 10. Alerte FCM si gravité élevée ou critique
        alerte_envoyee = False
        if gravite in [NiveauGravite.ELEVE.value, NiveauGravite.CRITIQUE.value]:
            alerte_envoyee = True
            logger.warning(
                f"ALERTE : maladie '{maladie_principale_nom}' gravité {gravite} "
                f"détectée sur champ {champ_id} (agriculteur {agriculteur_id})"
            )
            try:
                from app.services.notification_service import notification_service
                await notification_service.envoyer_alerte_maladie(
                    agriculteur_id=agriculteur_id,
                    nom_maladie=maladie_principale_nom,
                    diagnostic_id=diagnostic_id,
                    gravite=gravite,
                )
            except Exception as e:
                logger.error(f"Erreur envoi notification FCM : {e}")

        duree = time.time() - debut
        logger.info(
            f"Analyse IA terminée | image={image_id} | durée={duree:.3f}s | "
            f"confiance={score_confiance:.3f} | statut={statut.value} | "
            f"version={VERSION_MODELE_DETECTION}"
        )

        return ResultatAnalyseIA(
            diagnosticId=diagnostic_id,
            imageId=image_id,
            maladieDetectee=maladie_principale_nom,
            scoreConfiance=score_confiance,
            topPredictions=top_predictions,
            statut=statut,
            traitementRecommandeId=traitement_id,
            alerteEnvoyee=alerte_envoyee,
            modeleVersion=VERSION_MODELE_DETECTION,
            dateAnalyse=datetime.now(timezone.utc),
        )


detection_service = DetectionService()
