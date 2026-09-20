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
        mock_verifier.return_value = {"uid": "agri1", "email": "a@koobalatec.sn", "role": "AGRICULTEUR"}
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
            "app.routers.agent.agent_service.chat",
            return_value={"reponse": "Le mil est bien adapté.", "outils_utilises": []},
        ):
            response = client.post(
                "/agent/chat", json={"message": "Que planter à Kaolack ?"}, headers=AUTH_HEADER
            )

        assert response.status_code == 200
        data = response.json()
        assert data["reponse"] == "Le mil est bien adapté."
        assert data["conversationId"]
        assert mock_persister.await_count == 2  # message utilisateur + réponse agent
