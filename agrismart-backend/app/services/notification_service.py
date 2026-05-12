"""Service de notifications push via Firebase Cloud Messaging (FCM)."""

import logging
from datetime import datetime, timezone
from typing import Optional

from firebase_admin import messaging

from app.services.firestore_service import notifications_svc, utilisateurs_service
from app.models.enums import TypeNotification

logger = logging.getLogger(__name__)


class NotificationService:
    """Gère l'envoi et la persistance des notifications push FCM."""

    async def envoyer_notification(
        self,
        destinataire_id: str,
        type_notif: TypeNotification,
        titre: str,
        corps: str,
        reference_id: Optional[str] = None,
        urgent: bool = False,
    ) -> str:
        """
        Enregistre une notification en Firestore et l'envoie via FCM si un token est disponible.

        Args:
            destinataire_id: UID Firestore du destinataire.
            type_notif: Type de la notification.
            titre: Titre court de la notification.
            corps: Corps du message.
            reference_id: ID de la ressource liée (diagnostic, recommandation, etc.).
            urgent: Si True, la notification est marquée comme haute priorité.

        Returns:
            ID Firestore de la notification créée.
        """
        maintenant = datetime.now(timezone.utc)

        # Persistance Firestore
        notif_doc = {
            "destinataireId": destinataire_id,
            "type": type_notif.value,
            "titre": titre,
            "corps": corps,
            "referenceId": reference_id,
            "urgent": urgent,
            "dateEnvoi": maintenant,
            "lu": False,
            "dateLecture": None,
        }
        notif_id = await notifications_svc.creer(notif_doc)
        logger.info(f"Notification {notif_id} créée pour l'utilisateur {destinataire_id}")

        # Récupération du token FCM de l'utilisateur
        utilisateur = await utilisateurs_service.lire(destinataire_id)
        fcm_token = utilisateur.get("fcmToken") if utilisateur else None

        if fcm_token:
            await self._envoyer_via_fcm(
                fcm_token=fcm_token,
                titre=titre,
                corps=corps,
                donnees={
                    "type": type_notif.value,
                    "referenceId": reference_id or "",
                    "urgent": str(urgent).lower(),
                    "notifId": notif_id,
                },
                urgent=urgent,
            )
        else:
            logger.debug(
                f"Pas de token FCM pour l'utilisateur {destinataire_id} "
                f"— notification sauvegardée uniquement en Firestore."
            )

        return notif_id

    async def _envoyer_via_fcm(
        self,
        fcm_token: str,
        titre: str,
        corps: str,
        donnees: dict,
        urgent: bool = False,
    ) -> None:
        """Envoie un message push via Firebase Cloud Messaging."""
        try:
            priorite = "high" if urgent else "normal"

            message = messaging.Message(
                notification=messaging.Notification(title=titre, body=corps),
                data={k: str(v) for k, v in donnees.items()},
                token=fcm_token,
                android=messaging.AndroidConfig(
                    priority=priorite,
                    notification=messaging.AndroidNotification(
                        sound="default",
                        click_action="FLUTTER_NOTIFICATION_CLICK",
                    ),
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(sound="default"),
                    ),
                ),
            )

            reponse = messaging.send(message)
            logger.info(f"FCM envoyé avec succès : {reponse}")

        except messaging.UnregisteredError:
            logger.warning(f"Token FCM non enregistré : {fcm_token[:20]}...")
        except messaging.InvalidArgumentError as e:
            logger.error(f"Argument FCM invalide : {e}")
        except Exception as e:
            logger.error(f"Erreur FCM inattendue : {e}")

    async def envoyer_alerte_maladie(
        self,
        agriculteur_id: str,
        nom_maladie: str,
        diagnostic_id: str,
        gravite: str,
    ) -> str:
        """Raccourci pour envoyer une alerte de maladie détectée."""
        emoji_gravite = {"CRITIQUE": "🚨", "ELEVE": "⚠️", "MODERE": "📋", "FAIBLE": "ℹ️"}
        icone = emoji_gravite.get(gravite, "⚠️")

        return await self.envoyer_notification(
            destinataire_id=agriculteur_id,
            type_notif=TypeNotification.ALERTE_MALADIE,
            titre=f"{icone} Maladie détectée : {nom_maladie}",
            corps=f"Une maladie de gravité {gravite.lower()} a été détectée sur votre champ. Consultez le diagnostic pour les recommandations de traitement.",
            reference_id=diagnostic_id,
            urgent=gravite in ["CRITIQUE", "ELEVE"],
        )

    async def marquer_lue(self, notif_id: str, utilisateur_id: str) -> bool:
        """Marque une notification comme lue."""
        await notifications_svc.mettre_a_jour(
            notif_id,
            {"lu": True, "dateLecture": datetime.now(timezone.utc)},
        )
        return True

    async def obtenir_non_lues(self, utilisateur_id: str) -> list[dict]:
        """Retourne les notifications non lues d'un utilisateur."""
        return await notifications_svc.lister(
            filtres=[
                ("destinataireId", "==", utilisateur_id),
                ("lu", "==", False),
            ],
            ordre_par="dateEnvoi",
            decroissant=True,
            limite=50,
        )


notification_service = NotificationService()
