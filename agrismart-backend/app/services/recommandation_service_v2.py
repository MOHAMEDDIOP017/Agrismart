"""
Module IA 1 (v2) : Service de recommandation de cultures — modèle multi-label.

Modèle : `modele_final.joblib` = { pipeline: StandardScaler → OneVsRestClassifier
(RandomForestClassifier, 300 arbres), binarizer: MultiLabelBinarizer, features:
liste des 16 variables }. Contrairement au SVM v1 (une seule classe prédite
par probabilités qui somment à 1), ce modèle donne une probabilité
d'APTITUDE indépendante par culture — plusieurs cultures peuvent être
fortement recommandées en même temps sur un même sol.

Le moteur SVM v1 (7 variables) initialement prévu pour comparaison dans le
mémoire a été retiré : ses artefacts (`svm_crop.pkl`, `scaler_crop.pkl`,
`label_encoder_crop.pkl`) n'ont jamais été présents dans le dépôt, la
comparaison n'était donc pas réalisable en pratique. Seules les fiches
techniques par culture qu'il utilisait ont été conservées, dans
`app/services/fiches_cultures.py`. Voir aussi `app/services/agroeco_zones.py`
pour la collecte des 16 variables (sol/climat/NDVI par zone agroécologique),
factorisée avec l'outil de l'agent conversationnel.
"""

import logging
import time
from datetime import datetime, timezone
from pathlib import Path

import numpy as np

from app.config import settings
from app.core.exceptions import (
    ChampNonTrouveException,
    ModeleIAIndisponibleException,
    RessourceNonTrouveException,
)
from app.models.enums import StatutValidation
from app.services import agroeco_zones
from app.services.firestore_service import (
    champs_service,
    cultures_service,
    recommandations_svc,
    analyses_parcelles_svc,
    utilisateurs_service,
)
from app.services.fiches_cultures import (
    CONSEILS_PAR_CULTURE,
    PERIODES_PAR_CULTURE,
    RENDEMENT_PAR_CULTURE,
    BESOIN_EAU_PAR_CULTURE,
    PRIX_MARCHE_PAR_CULTURE,
    ENGRAIS_PAR_CULTURE,
    MALADIES_PAR_CULTURE,
)
from app.models.recommandation_culture_v2 import (
    RecommandationCultureV2Response,
    ResultatRecommandationV2,
)

logger = logging.getLogger(__name__)

MODELE_VERSION = "multilabel_rf_v2.0.0"

# Nom affiché en français par code de classe du modèle. Les 7 cultures
# communes avec le modèle SVM v1 réutilisent les fiches techniques
# (conseils, périodes, engrais, maladies) déjà définies dans
# `recommandation_service.py` — seul Manioc est nouveau (Oignon a disparu
# du nouveau modèle, sa fiche v1 reste inutilisée mais n'est pas supprimée).
NOM_AFFICHAGE_PAR_CODE: dict[str, str] = {
    "arachide": "Arachide",
    "mais": "Maïs",
    "manioc": "Manioc",
    "mil": "Mil",
    "niebe": "Niébé",
    "riz": "Riz",
    "sorgho": "Sorgho",
    "tomate": "Tomate",
}

# Nom wolof par code de classe — diagramme UML (Culture.nomWolof) et messages
# bilingues de l'agent conversationnel.
NOM_WOLOF_PAR_CODE: dict[str, str] = {
    "arachide": "gerte", "mais": "mbóq", "manioc": "ñambi", "mil": "dugub",
    "niebe": "ñebbe", "riz": "ceeb", "sorgho": "bàkka", "tomate": "tamaate",
}

# Fiche technique du Manioc — absente de v1, ajoutée pour le nouveau modèle.
# Sources : ISRA / FAO Sénégal (pratiques génériques, culture pérenne peu
# répandue traditionnellement au Sénégal mais bien adaptée à la Casamance).
_MANIOC_CONSEIL = (
    "Culture pérenne (8-12 mois), tolère les sols pauvres et acides. "
    "Bien adaptée à la Casamance et au Sénégal oriental. Boutures saines "
    "indispensables, buttage recommandé en sol lourd."
)
_MANIOC_PERIODE = "Mars - Mai (avant l'installation des pluies)"
_MANIOC_RENDEMENT = 8.0
_MANIOC_BESOIN_EAU = 700
_MANIOC_PRIX = 150
_MANIOC_ENGRAIS = ["Fumure organique 5 t/ha", "NPK 10-10-20 100 kg/ha"]
_MANIOC_MALADIES = ["Mosaïque africaine du manioc", "Bactériose vasculaire"]

CONSEILS_PAR_CULTURE_V2 = {**CONSEILS_PAR_CULTURE, "Manioc": _MANIOC_CONSEIL}
PERIODES_PAR_CULTURE_V2 = {**PERIODES_PAR_CULTURE, "Manioc": _MANIOC_PERIODE}
RENDEMENT_PAR_CULTURE_V2 = {**RENDEMENT_PAR_CULTURE, "Manioc": _MANIOC_RENDEMENT}
BESOIN_EAU_PAR_CULTURE_V2 = {**BESOIN_EAU_PAR_CULTURE, "Manioc": _MANIOC_BESOIN_EAU}
PRIX_MARCHE_PAR_CULTURE_V2 = {**PRIX_MARCHE_PAR_CULTURE, "Manioc": _MANIOC_PRIX}
ENGRAIS_PAR_CULTURE_V2 = {**ENGRAIS_PAR_CULTURE, "Manioc": _MANIOC_ENGRAIS}
MALADIES_PAR_CULTURE_V2 = {**MALADIES_PAR_CULTURE, "Manioc": _MANIOC_MALADIES}


class RecommandationServiceV2:
    """
    Service de recommandation de cultures via classifieur multi-label
    (OneVsRestClassifier de RandomForest, 16 variables sol/climat/NDVI).

    Chargement lazy identique au service v1 : le fichier `.joblib` est lu
    depuis le disque au premier appel puis conservé en mémoire.
    """

    def __init__(self):
        self._pipeline = None
        self._classes: list[str] = []
        self._features: list[str] = []
        self._modele_charge = False

    def _charger_modele(self) -> None:
        if self._modele_charge:
            return
        try:
            import joblib

            modele_path = Path(settings.modele_final_path)
            if not modele_path.exists():
                logger.warning(
                    f"Fichier modèle multi-label absent : {modele_path}. "
                    "Le module IA v2 restera indisponible."
                )
                return

            artefact = joblib.load(modele_path)
            self._pipeline = artefact["pipeline"]
            self._classes = list(artefact["binarizer"].classes_)
            self._features = list(artefact["features"])
            self._modele_charge = True

            logger.info(
                f"[OK] Modèle multi-label chargé — {len(self._features)} variables, "
                f"{len(self._classes)} cultures : {', '.join(self._classes)}"
            )
        except Exception as e:
            logger.error(f"Erreur lors du chargement du modèle multi-label : {e}")
            self._modele_charge = False

    @property
    def modeles_charges(self) -> bool:
        return self._modele_charge

    def _predire_probabilites(self, vecteur_features: np.ndarray) -> dict[str, float]:
        """Renvoie {code_culture: probabilité_aptitude} pour toutes les classes."""
        scaler = self._pipeline.named_steps["scaler"]
        classifieur = self._pipeline.named_steps["clf"]

        x_normalise = scaler.transform(vecteur_features)
        # OneVsRestClassifier : un estimateur binaire par classe, dans l'ordre de self._classes
        probabilites = np.array([
            estimateur.predict_proba(x_normalise)[0, 1]
            for estimateur in classifieur.estimators_
        ])
        return dict(zip(self._classes, probabilites))

    def predire_top_k(self, variables: dict[str, float], top_k: int = 3) -> list[tuple[str, float]]:
        """
        Charge le modèle si nécessaire et renvoie les k cultures les plus adaptées,
        triées par probabilité d'aptitude décroissante : [(code_culture, probabilité), ...].

        Point d'entrée partagé par le flux "champ" (generer_recommandations,
        ci-dessous) et par l'outil de l'agent conversationnel (agent_service),
        qui appelle cette méthode directement avec des variables dérivées d'une
        localité plutôt que d'un champ enregistré.

        Raises:
            ModeleIAIndisponibleException si le modèle ou des variables manquent.
        """
        self._charger_modele()
        if not self._modele_charge:
            raise ModeleIAIndisponibleException("modele_final.joblib")

        manquantes = [f for f in self._features if f not in variables]
        if manquantes:
            raise ModeleIAIndisponibleException(
                f"modele_final.joblib (variables manquantes : {manquantes})"
            )

        vecteur = np.array([[variables[f] for f in self._features]])
        probabilites = self._predire_probabilites(vecteur)
        resultats_tries = sorted(probabilites.items(), key=lambda x: x[1], reverse=True)
        return resultats_tries[:top_k]

    async def generer_recommandations(
        self,
        champ_id: str,
        utilisateur_id: str,
        top_k: int = 3,
    ) -> ResultatRecommandationV2:
        """
        Génère les recommandations multi-label pour un champ.

        Workflow (conforme au diagramme UML) :
        1. Récupère le champ (latitude/longitude)
        2. Assemble les 16 variables via `agroeco_zones.assembler_variables`
           (SoilGrids + NASA POWER temps réel, repli sur moyenne de zone)
        3. Persiste ces variables comme une `AnalyseParcelle` (remplace la
           saisie manuelle `DonneesAgronomiques`)
        4. Prédit une probabilité d'aptitude indépendante par culture
        5. Sauvegarde le top-K comme autant de `RecommandationCulture`
           (rang 1..k) rattachées à cette AnalyseParcelle, statut EN_ATTENTE

        Raises:
            ChampNonTrouveException si le champ est introuvable.
            ModeleIAIndisponibleException si `modele_final.joblib` est absent.
        """
        debut = time.time()

        champ = await champs_service.lire(champ_id)
        if champ is None:
            raise ChampNonTrouveException(champ_id)

        latitude = float(champ.get("latitude", 14.5))
        longitude = float(champ.get("longitude", -14.5))

        variables, zone, sources = agroeco_zones.assembler_variables(latitude, longitude)
        zone_nom = agroeco_zones.ZONE_NOM_AFFICHAGE.get(zone, zone)
        maintenant = datetime.now(timezone.utc)

        # 1) AnalyseParcelle — persistance des 16 variables (remplace DonneesAgronomiques)
        analyse_doc = {
            "champId": champ_id,
            "dateAnalyse": maintenant,
            **agroeco_zones.vers_champs_analyse_parcelle(variables),
            "sourceDonnees": agroeco_zones.resumer_sources(sources),
        }
        analyse_id = await analyses_parcelles_svc.creer(analyse_doc)

        # 2) Prédiction multi-label
        resultats_tries = self.predire_top_k(variables, top_k=top_k)
        logger.info(
            f"[Multi-label] Prédiction réussie en {time.time() - debut:.3f}s — "
            f"zone : {zone} — top-1 : {resultats_tries[0][0]} ({resultats_tries[0][1]:.1%})"
        )

        # 3) Une RecommandationCulture par rang
        top_recommandations: list[RecommandationCultureV2Response] = []

        for rang, (code_culture, proba) in enumerate(resultats_tries, start=1):
            nom_fr = NOM_AFFICHAGE_PAR_CODE.get(code_culture, code_culture.capitalize())

            cultures_trouvees = await cultures_service.lister(
                filtres=[("nom", "==", nom_fr)], limite=1
            )
            culture_id = cultures_trouvees[0]["id"] if cultures_trouvees else None

            doc = {
                "cultureNom": nom_fr,
                "cultureCode": code_culture,
                "cultureId": culture_id,
                "analyseParcelleId": analyse_id,
                "champId": champ_id,
                "probabiliteAptitude": round(float(proba), 4),
                "rang": rang,
                "periodePlantation": PERIODES_PAR_CULTURE_V2.get(nom_fr, "À déterminer"),
                "rendementEstime": RENDEMENT_PAR_CULTURE_V2.get(nom_fr, 1.0),
                "conseil": CONSEILS_PAR_CULTURE_V2.get(nom_fr, "Consultez un expert local."),
                "besoinEauMm": BESOIN_EAU_PAR_CULTURE_V2.get(nom_fr, 400),
                "prixMarcheEstime": PRIX_MARCHE_PAR_CULTURE_V2.get(nom_fr, 200),
                "engraisConseilles": ENGRAIS_PAR_CULTURE_V2.get(nom_fr, []),
                "maladiesFrequentes": MALADIES_PAR_CULTURE_V2.get(nom_fr, []),
                "date": maintenant,
                "statutValidation": StatutValidation.EN_ATTENTE.value,
                "commentaireExpert": None,
                "dateValidation": None,
                "validateurId": None,
                # Champs internes (non modélisés dans le diagramme, utiles au
                # fonctionnement/à la comparaison mémoire) :
                "modeleVersion": MODELE_VERSION,
                "moteur": "MULTILABEL",
                "zoneAgroecologique": zone_nom,
                "type": "AUTOMATIQUE",
                "agriculteurId": utilisateur_id,
            }
            doc_id = await recommandations_svc.creer(doc)
            top_recommandations.append(
                RecommandationCultureV2Response(id=doc_id, **doc)
            )

        return ResultatRecommandationV2(
            champId=champ_id,
            analyseParcelleId=analyse_id,
            zoneAgroecologique=zone_nom,
            topRecommandations=top_recommandations,
            modeleVersion=MODELE_VERSION,
            dateAnalyse=maintenant,
        )

    # ──────────────────────────────────────────────────────────────────────
    # Cycle de validation par un expert (RecommandationCulture.validerParExpert())
    # ──────────────────────────────────────────────────────────────────────

    async def _lire_ou_404(self, recommandation_id: str) -> dict:
        reco = await recommandations_svc.lire(recommandation_id)
        if reco is None or reco.get("moteur") != "MULTILABEL":
            raise RessourceNonTrouveException("RecommandationCulture", recommandation_id)
        return reco

    async def valider(
        self, recommandation_id: str, validateur_id: str, commentaire: str | None = None
    ) -> RecommandationCultureV2Response:
        await self._lire_ou_404(recommandation_id)
        maj = {
            "statutValidation": StatutValidation.VALIDEE.value,
            "commentaireExpert": commentaire,
            "dateValidation": datetime.now(timezone.utc),
            "validateurId": validateur_id,
        }
        await recommandations_svc.mettre_a_jour(recommandation_id, maj)
        reco = await recommandations_svc.lire(recommandation_id)
        return RecommandationCultureV2Response(**reco)

    async def corriger(
        self,
        recommandation_id: str,
        validateur_id: str,
        commentaire: str,
        culture_corrigee_nom: str | None = None,
    ) -> RecommandationCultureV2Response:
        await self._lire_ou_404(recommandation_id)
        maj = {
            "statutValidation": StatutValidation.CORRIGEE.value,
            "commentaireExpert": commentaire,
            "dateValidation": datetime.now(timezone.utc),
            "validateurId": validateur_id,
        }
        if culture_corrigee_nom:
            maj["cultureNom"] = culture_corrigee_nom
        await recommandations_svc.mettre_a_jour(recommandation_id, maj)
        reco = await recommandations_svc.lire(recommandation_id)
        return RecommandationCultureV2Response(**reco)

    async def rejeter(
        self, recommandation_id: str, validateur_id: str, motif: str
    ) -> RecommandationCultureV2Response:
        await self._lire_ou_404(recommandation_id)
        maj = {
            "statutValidation": StatutValidation.REJETEE.value,
            "commentaireExpert": motif,
            "dateValidation": datetime.now(timezone.utc),
            "validateurId": validateur_id,
        }
        await recommandations_svc.mettre_a_jour(recommandation_id, maj)
        reco = await recommandations_svc.lire(recommandation_id)
        return RecommandationCultureV2Response(**reco)

    # ──────────────────────────────────────────────────────────────────────
    # Vue "carte" pour l'écran expert : regroupe les 1..3 RecommandationCulture
    # d'une même AnalyseParcelle (un top-3 = une décision de validation).
    # Chaque RecommandationCulture garde son propre statutValidation en base
    # (conforme au diagramme) ; les actions groupées appliquent simplement le
    # même statut à toutes les lignes d'une même AnalyseParcelle.
    # ──────────────────────────────────────────────────────────────────────

    async def _construire_snapshot(self, analyse_id: str, champ: dict) -> dict:
        analyse = await analyses_parcelles_svc.lire(analyse_id)
        if not analyse:
            return {}
        return {
            "azote": analyse.get("nTotal_g_kg"),
            "phosphore": analyse.get("pExtractible_ppm"),
            "potassium": analyse.get("kExtractible_ppm"),
            "ph": analyse.get("phEau"),
            "humidite": analyse.get("humiditeMoy"),
            "temperature": analyse.get("temperatureMoy"),
            "pluviometrie": analyse.get("pluieAnnuelle"),
            "typeSol": champ.get("typeSol"),
        }

    async def _construire_carte(self, analyse_id: str, membres: list[dict]) -> dict:
        """Construit la carte agrégée pour une AnalyseParcelle donnée."""
        membres = sorted(membres, key=lambda r: r.get("rang", 99))
        premier = membres[0]
        champ_id = premier.get("champId", "")
        champ = await champs_service.lire(champ_id) or {}
        agriculteur = await utilisateurs_service.lire(champ.get("agriculteurId", "")) or {}
        agriculteur_nom = f"{agriculteur.get('prenom', '')} {agriculteur.get('nom', '')}".strip()

        return {
            "id": analyse_id,
            "champId": champ_id,
            "champNom": champ.get("nom", "Champ"),
            "champRegion": premier.get("zoneAgroecologique", "Sénégal"),
            "agriculteurId": champ.get("agriculteurId", ""),
            "agriculteurNom": agriculteur_nom or "Agriculteur",
            "agriculteurTelephone": agriculteur.get("telephone", ""),
            "top_cultures": [
                {
                    "cultureNom": m.get("cultureNom"),
                    "score": m.get("probabiliteAptitude"),
                    "rendementEstime": m.get("rendementEstime"),
                    "periodePlantation": m.get("periodePlantation"),
                }
                for m in membres
            ],
            "snapshot": await self._construire_snapshot(analyse_id, champ),
            "statutValidation": premier.get("statutValidation", "EN_ATTENTE"),
            "dateGeneree": premier.get("date"),
            "commentaireExpert": premier.get("commentaireExpert"),
            "cultureCorrigee": (
                premier.get("cultureNom")
                if premier.get("statutValidation") == StatutValidation.CORRIGEE.value
                else None
            ),
            "dateValidation": premier.get("dateValidation"),
            "modeleIAVersion": premier.get("modeleVersion"),
        }

    async def lister_en_attente_groupees(self) -> list[dict]:
        """Une carte par AnalyseParcelle ayant au moins une RecommandationCulture EN_ATTENTE."""
        recos = await recommandations_svc.lister(
            filtres=[
                ("moteur", "==", "MULTILABEL"),
                ("statutValidation", "==", StatutValidation.EN_ATTENTE.value),
            ],
            ordre_par="date", decroissant=True, limite=200,
        )
        groupes: dict[str, list[dict]] = {}
        for r in recos:
            groupes.setdefault(r["analyseParcelleId"], []).append(r)

        cartes = [await self._construire_carte(aid, membres) for aid, membres in groupes.items()]
        cartes.sort(key=lambda c: c["dateGeneree"] or datetime.min, reverse=True)
        return cartes

    async def _membres_du_groupe(self, analyse_id: str) -> list[dict]:
        membres = await recommandations_svc.lister(
            filtres=[("analyseParcelleId", "==", analyse_id)], limite=10
        )
        if not membres:
            raise RessourceNonTrouveException("AnalyseParcelle", analyse_id)
        return membres

    async def valider_groupe(
        self, analyse_id: str, validateur_id: str, commentaire: str | None
    ) -> dict:
        membres = await self._membres_du_groupe(analyse_id)
        for m in membres:
            await self.valider(m["id"], validateur_id, commentaire)
        return await self._construire_carte(analyse_id, await self._membres_du_groupe(analyse_id))

    async def corriger_groupe(
        self, analyse_id: str, validateur_id: str, commentaire: str, culture_corrigee_nom: str | None
    ) -> dict:
        membres = await self._membres_du_groupe(analyse_id)
        membres_tries = sorted(membres, key=lambda r: r.get("rang", 99))
        for i, m in enumerate(membres_tries):
            # Seule la ligne de rang 1 reçoit le nom de la culture corrigée par l'expert.
            nom = culture_corrigee_nom if i == 0 else None
            await self.corriger(m["id"], validateur_id, commentaire, nom)
        return await self._construire_carte(analyse_id, await self._membres_du_groupe(analyse_id))

    async def rejeter_groupe(
        self, analyse_id: str, validateur_id: str, motif: str
    ) -> dict:
        membres = await self._membres_du_groupe(analyse_id)
        for m in membres:
            await self.rejeter(m["id"], validateur_id, motif)
        return await self._construire_carte(analyse_id, await self._membres_du_groupe(analyse_id))


recommandation_service_v2 = RecommandationServiceV2()
