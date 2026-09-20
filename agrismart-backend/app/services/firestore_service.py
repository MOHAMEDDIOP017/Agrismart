"""Service d'abstraction CRUD générique pour Firestore."""

import asyncio
import logging
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from typing import Any, Optional

from google.cloud.firestore import Client as FirestoreClient
from google.cloud.firestore_v1 import DocumentSnapshot

from app.firebase_init import get_firestore

logger = logging.getLogger(__name__)


_executor = ThreadPoolExecutor(max_workers=4)
FIRESTORE_TIMEOUT = 10.0  # secondes


class FirestoreService:
    """Service générique d'accès CRUD aux collections Firestore."""

    def __init__(self, collection: str):
        self.collection = collection
        self._db: Optional[FirestoreClient] = None

    @property
    def db(self) -> FirestoreClient:
        if self._db is None:
            self._db = get_firestore()
        return self._db

    def _ref(self):
        return self.db.collection(self.collection)

    async def _run(self, fn):
        """Exécute une fonction Firestore synchrone dans un thread avec timeout."""
        loop = asyncio.get_event_loop()
        try:
            return await asyncio.wait_for(
                loop.run_in_executor(_executor, fn),
                timeout=FIRESTORE_TIMEOUT,
            )
        except asyncio.TimeoutError:
            raise RuntimeError(
                f"[{self.collection}] Firestore timeout ({FIRESTORE_TIMEOUT}s) — "
                "vérifiez la connexion réseau vers firestore.googleapis.com"
            )

    async def creer(self, donnees: dict) -> str:
        donnees["dateCreation"] = datetime.now(timezone.utc)
        def _fn():
            _, doc_ref = self._ref().add(donnees)
            return doc_ref.id
        doc_id = await self._run(_fn)
        logger.info(f"[{self.collection}] Document créé : {doc_id}")
        return doc_id

    async def creer_avec_id(self, doc_id: str, donnees: dict) -> str:
        donnees["dateCreation"] = datetime.now(timezone.utc)
        await self._run(lambda: self._ref().document(doc_id).set(donnees))
        logger.info(f"[{self.collection}] Document créé avec ID imposé : {doc_id}")
        return doc_id

    async def lire(self, doc_id: str) -> Optional[dict]:
        doc = await self._run(lambda: self._ref().document(doc_id).get())
        if not doc.exists:
            logger.debug(f"[{self.collection}] Document {doc_id} introuvable.")
            return None
        return {"id": doc.id, **doc.to_dict()}

    async def lister(
        self,
        filtres: Optional[list[tuple]] = None,
        limite: int = 100,
        ordre_par: Optional[str] = None,
        decroissant: bool = False,
    ) -> list[dict]:
        query = self._ref()
        if filtres:
            for champ, op, valeur in filtres:
                query = query.where(champ, op, valeur)
        query = query.limit(limite)

        def _fetch():
            return [{"id": doc.id, **doc.to_dict()} for doc in query.stream()]

        resultats = await self._run(_fetch)
        if ordre_par:
            _DT_MIN = datetime.min.replace(tzinfo=timezone.utc)
            is_datetime_field = any(isinstance(d.get(ordre_par), datetime) for d in resultats)
            if is_datetime_field:
                def _sort_key(d):
                    val = d.get(ordre_par)
                    return val if isinstance(val, datetime) else _DT_MIN
            else:
                def _sort_key(d):
                    val = d.get(ordre_par)
                    return str(val) if val is not None else ""
            resultats.sort(key=_sort_key, reverse=decroissant)
        return resultats

    async def mettre_a_jour(self, doc_id: str, donnees: dict) -> bool:
        donnees["dateMiseAJour"] = datetime.now(timezone.utc)
        await self._run(lambda: self._ref().document(doc_id).update(donnees))
        logger.info(f"[{self.collection}] Document {doc_id} mis à jour.")
        return True

    async def remplacer(self, doc_id: str, donnees: dict) -> bool:
        donnees["dateMiseAJour"] = datetime.now(timezone.utc)
        await self._run(lambda: self._ref().document(doc_id).set(donnees))
        logger.info(f"[{self.collection}] Document {doc_id} remplacé.")
        return True

    async def supprimer(self, doc_id: str) -> bool:
        await self._run(lambda: self._ref().document(doc_id).delete())
        logger.info(f"[{self.collection}] Document {doc_id} supprimé.")
        return True

    async def existe(self, doc_id: str) -> bool:
        doc = await self._run(lambda: self._ref().document(doc_id).get())
        return doc.exists

    async def compter(self, filtres: Optional[list[tuple]] = None) -> int:
        """Compte les documents via l'API Aggregate Firestore (sans fetch de données)."""
        query = self._ref()
        if filtres:
            for champ, op, valeur in filtres:
                query = query.where(champ, op, valeur)

        def _count():
            result = query.count().get()
            return int(result[0][0].value)

        return await self._run(_count)


# ─── Instances pré-configurées par collection ─────────────────────────────────

utilisateurs_service = FirestoreService("users")
champs_service = FirestoreService("champs")
cultures_service = FirestoreService("cultures")
culture_en_champ_svc = FirestoreService("cultureEnChamp")
recommandations_svc = FirestoreService("recommandationsCulture")
recommandations_pr_svc = FirestoreService("recommandationsPostRecolte")
interventions_svc = FirestoreService("interventions")
conseils_svc = FirestoreService("conseils")

# Diagramme UML — nouvelles entités
zones_agroecologiques_svc = FirestoreService("zonesAgroecologiques")
analyses_parcelles_svc = FirestoreService("analysesParcelles")
messages_chat_svc = FirestoreService("messagesChat")
notifications_svc = FirestoreService("notifications")
historique_svc = FirestoreService("historiqueActivites")
