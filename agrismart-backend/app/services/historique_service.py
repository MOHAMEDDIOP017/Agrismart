"""Service de gestion de l'historique des activités."""

import logging
from datetime import datetime, timezone
from typing import Optional

from app.services.firestore_service import historique_svc

logger = logging.getLogger(__name__)


class HistoriqueService:
    """Enregistre et consulte l'historique des actions utilisateurs."""

    async def enregistrer(
        self,
        utilisateur_id: str,
        type_action: str,
        description: str,
        reference_id: Optional[str] = None,
        details: Optional[dict] = None,
    ) -> str:
        """
        Enregistre une action dans l'historique.

        Args:
            utilisateur_id: UID de l'utilisateur qui a effectué l'action.
            type_action: Code court de l'action (ex: 'UPLOAD_IMAGE', 'ANALYSE_IA').
            description: Description lisible de l'action.
            reference_id: ID de la ressource concernée (optionnel).
            details: Données supplémentaires en JSON (optionnel).

        Returns:
            ID Firestore de l'entrée d'historique.
        """
        doc = {
            "utilisateurId": utilisateur_id,
            "typeAction": type_action,
            "description": description,
            "referenceId": reference_id,
            "dateAction": datetime.now(timezone.utc),
            "details": details or {},
        }
        doc_id = await historique_svc.creer(doc)
        logger.debug(f"Historique enregistré : {type_action} par {utilisateur_id}")
        return doc_id

    async def obtenir_historique_utilisateur(
        self, utilisateur_id: str, limite: int = 50
    ) -> list[dict]:
        """Retourne l'historique d'un utilisateur (du plus récent au plus ancien)."""
        return await historique_svc.lister(
            filtres=[("utilisateurId", "==", utilisateur_id)],
            ordre_par="dateAction",
            decroissant=True,
            limite=limite,
        )

    async def obtenir_historique_global(self, limite: int = 100) -> list[dict]:
        """Retourne l'historique global du système (admin uniquement)."""
        return await historique_svc.lister(
            ordre_par="dateAction",
            decroissant=True,
            limite=limite,
        )


historique_service = HistoriqueService()
