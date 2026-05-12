"""
Module IA 1 : Service de recommandation de cultures.

Modèle : SVM (kernel RBF) entraîné par GridSearchCV sur 2200 observations.
Dataset : AgriSmart_Dataset_2200 (300 réelles NASA POWER + ISRA, 1900 SMOTE).
Accuracy test : 97,50 % — F1-score weighted : 0,9750
"""

import json
import logging
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

import numpy as np

from app.config import settings
from app.core.exceptions import (
    ModeleIAIndisponibleException,
    DonneesAgronomiquesAbsentesException,
    ChampNonTrouveException,
)
from app.services.firestore_service import (
    champs_service,
    donnees_agronomiques_svc,
    recommandations_svc,
    cultures_service,
)
from app.services.meteo_service import meteo_service
from app.models.recommandation_culture import PredictionCulture, ResultatRecommandation

logger = logging.getLogger(__name__)

# ──────────────────────────────────────────────────────────────────────────────
# Données agronomiques par culture (8 classes du modèle SVM)
# ──────────────────────────────────────────────────────────────────────────────

CONSEILS_PAR_CULTURE: dict[str, str] = {
    "Arachide": "Enrichit le sol en azote. Rotation recommandée avec le mil. "
                "Sol sableux bien drainé, pH 5.5–7.0.",
    "Maïs":     "Forte demande en eau et en azote. Réservez les zones irriguées "
                "ou à pluviométrie > 600 mm. Apport d'urée recommandé.",
    "Mil":      "Culture résistante à la sécheresse, idéale pour les zones sahéliennes. "
                "Semez en juin-juillet dès les premières pluies.",
    "Niébé":    "Légumineuse fixatrice d'azote, excellente en association. "
                "Bonne tolérance à la chaleur et aux sols pauvres.",
    "Oignon":   "Marché porteur. Privilégiez les variétés locales (Galmi violet). "
                "Irrigation régulière indispensable.",
    "Riz":      "Requis : plaine inondable ou périmètre irrigué. "
                "Zone casamançaise et vallée du fleuve Sénégal idéales.",
    "Sorgho":   "Adapté aux sols pauvres et aux périodes de sécheresse prolongée. "
                "Excellente culture de sécurité alimentaire.",
    "Tomate":   "Nécessite un suivi phytosanitaire régulier. "
                "Préférez la saison sèche en irrigué pour limiter les maladies fongiques.",
}

PERIODES_PAR_CULTURE: dict[str, str] = {
    "Arachide": "Juin - Juillet",
    "Maïs":     "Juin - Août",
    "Mil":      "Juin - Juillet",
    "Niébé":    "Juillet - Août",
    "Oignon":   "Novembre - Janvier",
    "Riz":      "Juillet - Août (hivernage)",
    "Sorgho":   "Juin - Août",
    "Tomate":   "Octobre - Décembre (saison sèche)",
}

RENDEMENT_PAR_CULTURE: dict[str, float] = {
    "Arachide": 1.2,
    "Maïs":     2.0,
    "Mil":      0.8,
    "Niébé":    0.6,
    "Oignon":  20.0,
    "Riz":      3.5,
    "Sorgho":   1.0,
    "Tomate":  15.0,
}

# Besoins en eau (mm/saison) — source ISRA / FAO Sénégal
BESOIN_EAU_PAR_CULTURE: dict[str, int] = {
    "Arachide": 500,
    "Maïs":     600,
    "Mil":      350,
    "Niébé":    400,
    "Oignon":   550,
    "Riz":     1200,
    "Sorgho":   400,
    "Tomate":   600,
}

# Prix marché estimés (FCFA/kg) — source ANSD / marchés ruraux sénégalais
PRIX_MARCHE_PAR_CULTURE: dict[str, int] = {
    "Arachide": 300,
    "Maïs":     175,
    "Mil":      250,
    "Niébé":    350,
    "Oignon":   200,
    "Riz":      400,
    "Sorgho":   200,
    "Tomate":   150,
}

# Engrais recommandés par culture (pratiques ISRA Sénégal)
ENGRAIS_PAR_CULTURE: dict[str, list[str]] = {
    "Arachide": ["Phosphate naturel 100 kg/ha", "Dolomie 200 kg/ha"],
    "Maïs":     ["Urée 46% 100 kg/ha", "NPK 15-15-15 150 kg/ha"],
    "Mil":      ["Fumure organique 5 t/ha", "Phosphate de Tilemsi 100 kg/ha"],
    "Niébé":    ["Inoculant rhizobium", "Phosphate naturel 50 kg/ha"],
    "Oignon":   ["NPK 17-17-17 300 kg/ha", "Urée 100 kg/ha", "Sulfate de potasse 50 kg/ha"],
    "Riz":      ["Urée 46% 100 kg/ha", "DAP 50 kg/ha", "Chlorure de potassium 60 kg/ha"],
    "Sorgho":   ["Fumure organique 3 t/ha", "NPK 14-18-18 100 kg/ha"],
    "Tomate":   ["NPK 12-24-12 200 kg/ha", "Calcium-Bore en foliaire"],
}

# Maladies fréquentes par culture au Sénégal
MALADIES_PAR_CULTURE: dict[str, list[str]] = {
    "Arachide": ["Cercosporiose", "Rosette de l'arachide"],
    "Maïs":     ["Helminthosporiose", "Rouille commune du maïs"],
    "Mil":      ["Mildiou du mil", "Charbon du mil"],
    "Niébé":    ["Virus de la mosaïque du niébé", "Anthracnose"],
    "Oignon":   ["Mildiou de l'oignon", "Fusariose basale"],
    "Riz":      ["Pyriculariose du riz", "Bactériose du riz"],
    "Sorgho":   ["Charbon couvert", "Anthracnose du sorgho"],
    "Tomate":   ["Mildiou de la tomate", "Alternariose", "Fusariose"],
}


class RecommandationService:
    """
    Service de recommandation de cultures via SVM (kernel RBF).

    Chargement lazy : les artefacts ML (modèle, scaler, label encoder) sont
    lus depuis le disque au premier appel, puis conservés en mémoire.
    Si les fichiers sont absents, un mode dégradé heuristique prend le relai.
    """

    def __init__(self):
        self._modele = None
        self._scaler = None
        self._label_encoder = None
        self._metadata: dict = {}
        self._modeles_charges = False

    # ──────────────────────────────────────────────────────────────────────
    # Chargement des artefacts ML
    # ──────────────────────────────────────────────────────────────────────

    def _charger_modeles(self) -> None:
        """Charge les artefacts ML depuis le disque (lazy, une seule fois)."""
        if self._modeles_charges:
            return

        try:
            import joblib

            modele_path  = Path(settings.modele_recommandation_path)
            scaler_path  = Path(settings.scaler_path)
            encoder_path = Path(settings.label_encoder_path)
            meta_path    = Path(settings.modele_metadata_path)

            manquants = [p for p in [modele_path, scaler_path, encoder_path] if not p.exists()]
            if manquants:
                logger.warning(
                    f"Fichiers modèle SVM absents : {manquants}. Mode dégradé activé."
                )
                return

            self._modele        = joblib.load(modele_path)
            self._scaler        = joblib.load(scaler_path)
            self._label_encoder = joblib.load(encoder_path)

            if meta_path.exists():
                with open(meta_path, "r", encoding="utf-8") as f:
                    self._metadata = json.load(f)
                logger.info(
                    f"Modèle SVM chargé — version {self._metadata.get('model_version', '?')} "
                    f"(accuracy test : {self._metadata.get('test_accuracy', 0):.2%})"
                )
            else:
                logger.warning("model_metadata.json introuvable — métadonnées indisponibles.")

            self._modeles_charges = True

        except Exception as e:
            logger.error(f"Erreur lors du chargement du modèle SVM : {e}")
            self._modeles_charges = False

    @property
    def _version_modele(self) -> str:
        """Retourne la version du modèle depuis les métadonnées."""
        return self._metadata.get("model_version", "svm_v1.0.0")

    # ──────────────────────────────────────────────────────────────────────
    # Mode dégradé (heuristique sans modèle)
    # ──────────────────────────────────────────────────────────────────────

    def _predire_heuristique(
        self,
        n: float, p: float, k: float,
        temp: float, humidite: float, ph: float, pluvio: float,
    ) -> list[tuple[str, float]]:
        """
        Prédiction heuristique utilisée quand le modèle SVM n'est pas disponible.
        Basée sur des règles agronomiques simplifiées pour le Sénégal.
        """
        logger.warning("Mode dégradé : heuristique (modèle SVM absent)")

        scores: dict[str, float] = {
            "Arachide": 0.70 if (5.5 <= ph <= 7.0 and humidite < 60) else 0.25,
            "Maïs":     0.65 if (humidite >= 55 and pluvio > 500) else 0.20,
            "Mil":      0.60 if (humidite < 50 and pluvio < 600) else 0.30,
            "Niébé":    0.50,
            "Oignon":   0.45 if temp >= 20 else 0.20,
            "Riz":      0.70 if pluvio > 700 else 0.10,
            "Sorgho":   0.55 if (humidite < 55 and ph >= 5.5) else 0.25,
            "Tomate":   0.75 if temp >= 22 else 0.30,
        }

        total = sum(scores.values())
        return sorted(
            [(culture, score / total) for culture, score in scores.items()],
            key=lambda x: x[1],
            reverse=True,
        )

    # ──────────────────────────────────────────────────────────────────────
    # Point d'entrée principal
    # ──────────────────────────────────────────────────────────────────────

    async def generer_recommandations(
        self,
        champ_id: str,
        utilisateur_id: str,
        top_k: int = 3,
    ) -> ResultatRecommandation:
        """
        Génère les recommandations de cultures pour un champ.

        Workflow :
        1. Récupère les données agronomiques du champ (pH, NPK)
        2. Récupère les données météo actuelles (température, humidité, pluvio)
        3. Construit le vecteur de 7 features attendu par le SVM
        4. Lance la prédiction SVM (ou heuristique si modèle absent)
        5. Sauvegarde le top-K en Firestore et retourne le résultat

        Args:
            champ_id: ID Firestore du champ.
            utilisateur_id: UID de l'agriculteur (pour la sauvegarde).
            top_k: Nombre de recommandations à retourner (défaut : 3).

        Returns:
            ResultatRecommandation avec le top-K des cultures recommandées.

        Raises:
            ChampNonTrouveException si le champ est introuvable.
            DonneesAgronomiquesAbsentesException si aucune donnée agronomique n'existe.
        """
        debut = time.time()

        # 1. Champ
        champ = await champs_service.lire(champ_id)
        if champ is None:
            raise ChampNonTrouveException(champ_id)

        # 2. Dernières données agronomiques
        donnees_list = await donnees_agronomiques_svc.lister(
            filtres=[("champId", "==", champ_id)],
            limite=1,
            ordre_par="dateSaisie",
            decroissant=True,
        )
        if not donnees_list:
            raise DonneesAgronomiquesAbsentesException(champ_id)

        donnees_agro = donnees_list[0]

        # 3. Données météo
        try:
            meteo = await meteo_service.get_donnees_actuelles(
                champ["latitude"], champ["longitude"]
            )
        except Exception as e:
            logger.warning(f"Météo indisponible, valeurs par défaut utilisées : {e}")
            meteo = {"temperature": 28.0, "humidite": 65.0, "pluviometrie": 0.0}

        # 4. Vecteur de 7 features (ordre strict attendu par le SVM)
        n_kg_ha        = float(donnees_agro.get("tauxAzote",     50))
        p_kg_ha        = float(donnees_agro.get("tauxPhosphore", 40))
        k_kg_ha        = float(donnees_agro.get("tauxPotassium", 40))
        temperature_c  = float(meteo.get("temperature",   28))
        humidite_pct   = float(meteo.get("humidite",      65))
        ph_sol         = float(donnees_agro.get("phSol",  6.5))
        pluvio_mm      = float(meteo.get("pluviometrie",   0))

        features_dict = {
            "N_kg_ha":          n_kg_ha,
            "P_kg_ha":          p_kg_ha,
            "K_kg_ha":          k_kg_ha,
            "temp_opt_C":       temperature_c,
            "humidite_pct":     humidite_pct,
            "pH_sol":           ph_sol,
            "pluviometrie_mm":  pluvio_mm,
        }

        # 5. Prédiction SVM (ou heuristique)
        self._charger_modeles()

        if self._modeles_charges:
            try:
                features_array = np.array([[
                    n_kg_ha, p_kg_ha, k_kg_ha,
                    temperature_c, humidite_pct, ph_sol, pluvio_mm,
                ]])
                features_normalises = self._scaler.transform(features_array)
                probas  = self._modele.predict_proba(features_normalises)[0]
                classes = self._label_encoder.classes_
                resultats = sorted(
                    zip(classes, probas), key=lambda x: x[1], reverse=True
                )
                logger.info(
                    f"Prédiction SVM réussie en {time.time() - debut:.3f}s — "
                    f"top-1 : {resultats[0][0]} ({resultats[0][1]:.2%})"
                )
            except Exception as e:
                logger.error(f"Erreur de prédiction SVM : {e} — bascule sur heuristique")
                resultats = self._predire_heuristique(
                    n_kg_ha, p_kg_ha, k_kg_ha,
                    temperature_c, humidite_pct, ph_sol, pluvio_mm,
                )
        else:
            resultats = self._predire_heuristique(
                n_kg_ha, p_kg_ha, k_kg_ha,
                temperature_c, humidite_pct, ph_sol, pluvio_mm,
            )

        # 6. Construction et sauvegarde du top-K
        top_predictions: list[PredictionCulture] = []
        ids_sauvegardes: list[str] = []

        for culture_nom, score in resultats[:top_k]:
            # Recherche de l'ID Firestore de la culture (si elle existe dans le catalogue)
            cultures_trouvees = await cultures_service.lister(
                filtres=[("nom", "==", culture_nom)], limite=1
            )
            culture_id = cultures_trouvees[0]["id"] if cultures_trouvees else None

            prix_kg = PRIX_MARCHE_PAR_CULTURE.get(culture_nom, 200)
            rendement = RENDEMENT_PAR_CULTURE.get(culture_nom, 1.0)
            prediction = PredictionCulture(
                cultureNom=culture_nom,
                cultureId=culture_id,
                score=float(score),
                periodePlantation=PERIODES_PAR_CULTURE.get(culture_nom, "À déterminer"),
                rendementEstime=rendement,
                conseil=CONSEILS_PAR_CULTURE.get(culture_nom, "Consultez un expert local."),
                besoinEauMm=BESOIN_EAU_PAR_CULTURE.get(culture_nom, 400),
                prixMarcheEstime=prix_kg,
                engraisConseilles=ENGRAIS_PAR_CULTURE.get(culture_nom, []),
                maladiesFrequentes=MALADIES_PAR_CULTURE.get(culture_nom, []),
            )
            top_predictions.append(prediction)

            doc = {
                "champId":              champ_id,
                "cultureRecommandeeId": culture_id or culture_nom,
                "cultureNom":           culture_nom,
                "score":                float(score),
                "periodePlantation":    prediction.periodePlantation,
                "rendementEstime":      prediction.rendementEstime,
                "modeleVersion":        self._version_modele,
                "conseil":              prediction.conseil,
                "besoinEauMm":          prediction.besoinEauMm,
                "prixMarcheEstime":     prediction.prixMarcheEstime,
                "engraisConseilles":    prediction.engraisConseilles,
                "maladiesFrequentes":   prediction.maladiesFrequentes,
                "date":                 datetime.now(timezone.utc),
                "type":                 "AUTOMATIQUE",
                "agriculteurId":        utilisateur_id,
                "featuresUtilisees":    features_dict,
            }
            doc_id = await recommandations_svc.creer(doc)
            ids_sauvegardes.append(doc_id)

        logger.info(
            f"Recommandations générées pour champ {champ_id} en "
            f"{time.time() - debut:.3f}s | modèle : {self._version_modele}"
        )

        return ResultatRecommandation(
            champId=champ_id,
            topRecommandations=top_predictions,
            donneesMeteoUtilisees=meteo,
            donneesAgronomiquesUtilisees={
                "phSol":           donnees_agro.get("phSol"),
                "tauxAzote":       donnees_agro.get("tauxAzote"),
                "tauxPhosphore":   donnees_agro.get("tauxPhosphore"),
                "tauxPotassium":   donnees_agro.get("tauxPotassium"),
                "humiditeObservee": donnees_agro.get("humiditeObservee"),
            },
            modeleVersion=self._version_modele,
            dateAnalyse=datetime.now(timezone.utc),
            recommandationsSauvegardees=ids_sauvegardes,
        )


recommandation_service = RecommandationService()
