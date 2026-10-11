"""
Tests du Module IA — Recommandation de cultures (moteur multi-label v2) et
agent conversationnel.

Remplace l'ancienne suite de tests du moteur SVM v1 (retiré : ses artefacts
`.pkl` n'ont jamais été présents dans le dépôt, la comparaison prévue pour le
mémoire n'était pas réalisable). Suit le même style que `test_auth.py`
(fixtures `mock_firebase`/`client`, `unittest.mock.patch`, aucun appel réseau
ni Firestore réel).
"""

import pytest
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch


# ─── Fixtures partagées (même pattern que test_auth.py) ───────────────────────

@pytest.fixture
def mock_firebase():
    with patch("app.firebase_init.initialiser_firebase") as mock_init, \
         patch("app.firebase_init.get_firestore") as mock_fs:
        mock_init.return_value = None
        mock_fs.return_value = MagicMock()
        yield mock_init, mock_fs


@pytest.fixture
def client(mock_firebase):
    from main import app
    from fastapi.testclient import TestClient
    return TestClient(app)


@pytest.fixture
def token_agriculteur():
    """
    Patch `verifier_token_firebase` pour simuler un token Bearer valide.

    Cible `app.core.dependencies.verifier_token_firebase` (le nom importé dans
    le module qui l'appelle), pas `app.core.security.verifier_token_firebase` :
    `dependencies.py` fait `from app.core.security import verifier_token_firebase`,
    ce qui crée une référence locale que patcher le module source ne retargete pas.
    """
    with patch("app.core.dependencies.verifier_token_firebase") as mock_verifier:
        mock_verifier.return_value = {"uid": "agri1", "email": "a@agrismart.sn", "role": "AGRICULTEUR"}
        yield mock_verifier


@pytest.fixture
def sans_bypass_dev():
    """
    Force `dev_bypass_auth=False` le temps du test : évite que la valeur de
    l'environnement local (`.env`, hors dépôt) ne rende les tests "401 sans
    token" non déterministes.
    """
    from app.config import settings
    with patch.object(settings, "dev_bypass_auth", False):
        yield


AUTH_HEADER = {"Authorization": "Bearer token_fictif"}


# ─── Service : RecommandationServiceV2.predire_top_k ───────────────────────────

class TestRecommandationServiceV2Predict:
    """Tests du moteur multi-label avec un pipeline factice (pas de vrai .joblib)."""

    @pytest.fixture
    def service_avec_pipeline_factice(self):
        """
        Instance de service avec un pipeline scikit-learn simulé :
        3 variables, 3 cultures, une probabilité déterministe par estimateur
        (permet de vérifier le tri décroissant sans dépendre du vrai modèle).
        """
        from app.services.recommandation_service_v2 import RecommandationServiceV2

        service = RecommandationServiceV2()
        service._modele_charge = True
        service._features = ["a", "b", "c"]
        service._classes = ["riz", "mil", "mais"]

        scaler = MagicMock()
        scaler.transform.side_effect = lambda x: x  # identité

        def estimateur(proba_classe_1: float):
            import numpy as np
            est = MagicMock()
            est.predict_proba.return_value = np.array([[1 - proba_classe_1, proba_classe_1]])
            return est

        # riz le plus adapté, puis mil, puis maïs
        clf = MagicMock()
        clf.estimators_ = [estimateur(0.9), estimateur(0.5), estimateur(0.1)]

        service._pipeline = MagicMock()
        service._pipeline.named_steps = {"scaler": scaler, "clf": clf}
        return service

    def test_predire_top_k_trie_par_probabilite_decroissante(self, service_avec_pipeline_factice):
        resultats = service_avec_pipeline_factice.predire_top_k(
            {"a": 1.0, "b": 2.0, "c": 3.0}, top_k=3
        )
        assert [code for code, _ in resultats] == ["riz", "mil", "mais"]
        assert resultats[0][1] == pytest.approx(0.9)
        assert all(0 <= proba <= 1 for _, proba in resultats)

    def test_predire_top_k_respecte_la_limite(self, service_avec_pipeline_factice):
        resultats = service_avec_pipeline_factice.predire_top_k(
            {"a": 1.0, "b": 2.0, "c": 3.0}, top_k=2
        )
        assert len(resultats) == 2

    def test_predire_top_k_variables_manquantes_leve_exception(self, service_avec_pipeline_factice):
        from app.core.exceptions import ModeleIAIndisponibleException

        with pytest.raises(ModeleIAIndisponibleException):
            service_avec_pipeline_factice.predire_top_k({"a": 1.0}, top_k=3)

    def test_predire_top_k_sans_modele_leve_exception(self):
        from app.core.exceptions import ModeleIAIndisponibleException
        from app.services.recommandation_service_v2 import RecommandationServiceV2

        service = RecommandationServiceV2()
        # models_ia/modele_final.joblib existe dans ce dépôt : on force explicitement
        # l'état "non chargé" pour simuler son absence sans dépendre du disque.
        service._charger_modele = lambda: None
        service._modele_charge = False

        with pytest.raises(ModeleIAIndisponibleException):
            service.predire_top_k({"a": 1.0, "b": 2.0, "c": 3.0}, top_k=3)


# ─── Router : /recommandations/v2 ──────────────────────────────────────────────

class TestRecommandationsV2Router:

    def test_generer_sans_token_retourne_401(self, client, sans_bypass_dev):
        response = client.post("/recommandations/v2/generer/champ1")
        assert response.status_code == 401

    def test_generer_champ_inexistant_retourne_404(self, client, token_agriculteur):
        with patch("app.routers.recommandations_v2.champs_service.lire", AsyncMock(return_value=None)):
            response = client.post("/recommandations/v2/generer/champ_inexistant", headers=AUTH_HEADER)
        assert response.status_code == 404

    def test_generer_recommandations_v2_succes(self, client, token_agriculteur):
        from app.models.recommandation_culture_v2 import (
            RecommandationCultureV2Response, ResultatRecommandationV2,
        )
        from app.models.enums import StatutValidation

        maintenant = datetime.now(timezone.utc)
        reco = RecommandationCultureV2Response(
            id="reco1", cultureNom="Riz", cultureCode="riz",
            analyseParcelleId="analyse1", champId="champ1",
            probabiliteAptitude=0.87, rang=1,
            periodePlantation="Juillet - Août", rendementEstime=3.5,
            conseil="Zone irriguée recommandée.", date=maintenant,
            statutValidation=StatutValidation.EN_ATTENTE,
        )
        resultat = ResultatRecommandationV2(
            champId="champ1", analyseParcelleId="analyse1",
            zoneAgroecologique="Vallée du Fleuve", topRecommandations=[reco],
            modeleVersion="multilabel_rf_v2.0.0", dateAnalyse=maintenant,
        )

        with patch(
            "app.routers.recommandations_v2.champs_service.lire",
            AsyncMock(return_value={"id": "champ1", "agriculteurId": "agri1"}),
        ), patch(
            "app.routers.recommandations_v2.recommandation_service_v2.generer_recommandations",
            AsyncMock(return_value=resultat),
        ), patch(
            "app.routers.recommandations_v2.notification_service.envoyer_notification",
            AsyncMock(),
        ), patch(
            "app.routers.recommandations_v2.historique_service.enregistrer",
            AsyncMock(),
        ):
            response = client.post("/recommandations/v2/generer/champ1", headers=AUTH_HEADER)

        assert response.status_code == 201
        data = response.json()
        assert data["zoneAgroecologique"] == "Vallée du Fleuve"
        assert len(data["topRecommandations"]) == 1
        top = data["topRecommandations"][0]
        assert top["rang"] == 1
        assert top["probabiliteAptitude"] == pytest.approx(0.87)


# ─── Router : /agent/chat ───────────────────────────────────────────────────────

class TestAgentChatRouter:

    def test_chat_sans_token_retourne_401(self, client, sans_bypass_dev):
        response = client.post("/agent/chat", json={"message": "Que planter à Kaolack ?"})
        assert response.status_code == 401

    def test_chat_succes_persiste_les_messages(self, client, token_agriculteur):
        with patch(
            "app.routers.agent.message_chat_service.construire_historique_openai",
            AsyncMock(return_value=[]),
        ), patch(
            "app.routers.agent.message_chat_service.persister",
            AsyncMock(return_value="msg1"),
        ) as mock_persister, patch(
            # `agent_service.chat` est désormais une coroutine (l'outil de
            # recommandation lit Firestore) : le mock doit être awaitable.
            "app.routers.agent.agent_service.chat",
            AsyncMock(return_value={"reponse": "Le mil est bien adapté.", "outils_utilises": []}),
        ):
            response = client.post(
                "/agent/chat", json={"message": "Que planter à Kaolack ?"}, headers=AUTH_HEADER
            )

        assert response.status_code == 200
        data = response.json()
        assert data["reponse"] == "Le mil est bien adapté."
        assert data["conversationId"]
        assert mock_persister.await_count == 2  # message utilisateur + réponse agent


# ─── Endpoint de recommandation avec un modèle simulé ─────────────────────────
# Contrairement à TestRecommandationsV2Router ci-dessus, qui remplace tout le
# service par un mock, cette classe traverse la vraie chaîne :
#   router -> recommandation_service_v2.generer_recommandations
#          -> agroeco_zones.assembler_variables (collecteurs simulés)
#          -> prédiction (pipeline scikit-learn simulé)
#          -> persistance AnalyseParcelle + RecommandationCulture (Firestore simulé)
# Seuls le réseau, Firestore et le fichier .joblib sont simulés : la logique
# métier traversée est bien celle qui tourne en production.

def _pipeline_factice(probabilites: list[float]):
    """Pipeline scikit-learn simulé : un estimateur binaire par culture."""
    import numpy as np

    scaler = MagicMock()
    scaler.transform.side_effect = lambda x: x  # identité, pas de normalisation

    def estimateur(proba_classe_1: float):
        est = MagicMock()
        est.predict_proba.return_value = np.array([[1 - proba_classe_1, proba_classe_1]])
        return est

    clf = MagicMock()
    clf.estimators_ = [estimateur(p) for p in probabilites]

    pipeline = MagicMock()
    pipeline.named_steps = {"scaler": scaler, "clf": clf}
    return pipeline


@pytest.fixture
def modele_simule():
    """
    Injecte un modèle simulé dans le singleton `recommandation_service_v2`,
    avec les 16 vraies variables attendues par modele_final.joblib, puis
    restaure l'état initial du service à la fin du test.
    """
    from app.services import agroeco_zones
    from app.services.recommandation_service_v2 import recommandation_service_v2

    etat_initial = (
        recommandation_service_v2._pipeline,
        recommandation_service_v2._classes,
        recommandation_service_v2._features,
        recommandation_service_v2._modele_charge,
    )

    # Mil le plus apte, puis arachide, puis sorgho, puis riz.
    recommandation_service_v2._classes = ["mil", "arachide", "sorgho", "riz"]
    recommandation_service_v2._features = list(agroeco_zones.CLE_ML_VERS_ANALYSE_PARCELLE)
    recommandation_service_v2._pipeline = _pipeline_factice([0.93, 0.81, 0.64, 0.12])
    recommandation_service_v2._modele_charge = True

    yield recommandation_service_v2

    (
        recommandation_service_v2._pipeline,
        recommandation_service_v2._classes,
        recommandation_service_v2._features,
        recommandation_service_v2._modele_charge,
    ) = etat_initial


class TestEndpointRecommandationModeleSimule:

    CHAMP_KAOLACK = {
        "id": "champ1", "nom": "Parcelle Nord", "agriculteurId": "agri1",
        "latitude": 14.1520, "longitude": -16.0726,   # Bassin arachidier
    }

    def _appeler(self, client, sol_indisponible: bool):
        """POST /recommandations/v2/generer/champ1 avec toute la chaîne simulée."""
        from app.services import agroeco_zones
        from app.core.exceptions import SourceDonneesIndisponibleException

        climat = {
            "temperature_moy_C": 29.1, "temperature_max_mois_C": 35.2,
            "temperature_min_mois_C": 22.8, "humidite_moy_pct": 52.0,
            "pluie_annuelle_mm": 701.4, "pluie_hivernage_mm": 688.0,
        }
        sol = {
            "N_total_g_kg": 0.80, "pH_eau": 6.40, "clay_pct": 15.0,
            "sand_pct": 69.0, "silt_pct": 16.0, "carbone_org_g_kg": 8.2,
        }
        collecteur_sol = (
            patch.object(agroeco_zones, "collecter_sol_soilgrids",
                         side_effect=SourceDonneesIndisponibleException("SoilGrids KO"))
            if sol_indisponible
            else patch.object(agroeco_zones, "collecter_sol_soilgrids", return_value=sol)
        )

        analyses_creees, recos_creees = [], []

        async def _creer_analyse(doc):
            analyses_creees.append(doc)
            return "analyse1"

        async def _creer_reco(doc):
            recos_creees.append(doc)
            return f"reco{len(recos_creees)}"

        with collecteur_sol, \
             patch.object(agroeco_zones, "collecter_climat_nasa_power", return_value=climat), \
             patch("app.routers.recommandations_v2.champs_service.lire",
                   AsyncMock(return_value=self.CHAMP_KAOLACK)), \
             patch("app.services.recommandation_service_v2.champs_service.lire",
                   AsyncMock(return_value=self.CHAMP_KAOLACK)), \
             patch("app.services.recommandation_service_v2.analyses_parcelles_svc.creer",
                   _creer_analyse), \
             patch("app.services.recommandation_service_v2.cultures_service.lister",
                   AsyncMock(return_value=[])), \
             patch("app.services.recommandation_service_v2.recommandations_svc.creer",
                   _creer_reco), \
             patch("app.routers.recommandations_v2.notification_service.envoyer_notification",
                   AsyncMock()), \
             patch("app.routers.recommandations_v2.historique_service.enregistrer",
                   AsyncMock()):
            reponse = client.post("/recommandations/v2/generer/champ1", headers=AUTH_HEADER)

        return reponse, analyses_creees, recos_creees

    def test_endpoint_retourne_le_top_3_trie(self, client, token_agriculteur, modele_simule):
        reponse, _, _ = self._appeler(client, sol_indisponible=False)

        assert reponse.status_code == 201
        data = reponse.json()
        assert data["champId"] == "champ1"
        assert data["zoneAgroecologique"] == "Bassin arachidier"

        top = data["topRecommandations"]
        assert len(top) == 3  # top_k par défaut, sur 4 cultures disponibles
        assert [r["cultureNom"] for r in top] == ["Mil", "Arachide", "Sorgho"]
        assert [r["rang"] for r in top] == [1, 2, 3]
        assert top[0]["probabiliteAptitude"] == pytest.approx(0.93)
        # Aptitudes indépendantes (multi-label) : elles ne somment pas à 1.
        assert sum(r["probabiliteAptitude"] for r in top) > 1

    def test_endpoint_enrichit_avec_la_fiche_technique(self, client, token_agriculteur, modele_simule):
        reponse, _, _ = self._appeler(client, sol_indisponible=False)
        premier = reponse.json()["topRecommandations"][0]

        assert premier["periodePlantation"] == "Juin - Juillet"      # fiche Mil
        assert premier["rendementEstime"] == pytest.approx(0.8)
        assert "Mildiou du mil" in premier["maladiesFrequentes"]
        assert premier["statutValidation"] == "EN_ATTENTE"

    def test_endpoint_expose_la_tracabilite_des_donnees(self, client, token_agriculteur, modele_simule):
        """SoilGrids indisponible : la réponse HTTP doit le dire à l'utilisateur."""
        reponse, _, _ = self._appeler(client, sol_indisponible=True)

        assert reponse.status_code == 201
        data = reponse.json()
        assert data["sourcesDonnees"]["sol"] == "moyenne de zone"
        assert data["sourcesDonnees"]["climat"] == "NASA POWER (temps réel)"
        assert "sol=moyenne de zone" in data["sourceDonnees"]

    def test_analyse_parcelle_persistee_avec_les_16_variables(self, client, token_agriculteur, modele_simule):
        """L'AnalyseParcelle enregistrée porte les 16 variables et leur origine."""
        from app.services import agroeco_zones

        _, analyses, _ = self._appeler(client, sol_indisponible=True)

        assert len(analyses) == 1
        analyse = analyses[0]
        for attribut in agroeco_zones.CLE_ML_VERS_ANALYSE_PARCELLE.values():
            assert attribut in analyse
        assert analyse["champId"] == "champ1"
        assert "sol=moyenne de zone" in analyse["sourceDonnees"]

    def test_recommandations_persistees_rattachees_a_l_analyse(self, client, token_agriculteur, modele_simule):
        _, _, recos = self._appeler(client, sol_indisponible=False)

        assert len(recos) == 3
        assert {r["analyseParcelleId"] for r in recos} == {"analyse1"}
        assert [r["rang"] for r in recos] == [1, 2, 3]
        assert all(r["moteur"] == "MULTILABEL" for r in recos)
        assert all(r["agriculteurId"] == "agri1" for r in recos)

    def test_endpoint_sans_modele_retourne_503(self, client, token_agriculteur, modele_simule):
        """Modèle absent : erreur explicite, pas de recommandation silencieuse."""
        modele_simule._modele_charge = False
        modele_simule._charger_modele = lambda: None

        reponse, _, _ = self._appeler(client, sol_indisponible=False)
        assert reponse.status_code == 503
