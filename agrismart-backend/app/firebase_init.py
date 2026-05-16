"""Initialisation des services Firebase pour KoobalaTech (Auth + Firestore + FCM uniquement).

Note : le stockage des images est géré par MinIO, PAS par Firebase Storage.
"""

import os
import firebase_admin
from firebase_admin import credentials, messaging
from google.cloud.firestore import Client as FirestoreClient
from google.cloud import firestore as gcloud_firestore
import google.oauth2.service_account
import logging

from app.config import settings

logger = logging.getLogger(__name__)

# Instances globales des clients Firebase
_firestore_client: FirestoreClient | None = None
_firebase_app = None


def initialiser_firebase() -> None:
    """Initialise Firebase Admin SDK + Firestore en mode REST (évite les problèmes gRPC)."""
    global _firebase_app, _firestore_client

    if firebase_admin._apps:
        logger.info("Firebase déjà initialisé.")
        return

    try:
        cred = credentials.Certificate(settings.firebase_service_account_path)
        _firebase_app = firebase_admin.initialize_app(cred)

        google_creds = google.oauth2.service_account.Credentials.from_service_account_file(
            settings.firebase_service_account_path,
            scopes=["https://www.googleapis.com/auth/cloud-platform",
                    "https://www.googleapis.com/auth/datastore"],
        )

        # Force le transport REST via variable d'environnement (compatible toutes versions)
        os.environ.setdefault("FIRESTORE_PREFER_REST", "true")

        _firestore_client = gcloud_firestore.Client(
            project=settings.firebase_project_id,
            credentials=google_creds,
        )
        logger.info("Firebase (Auth + Firestore REST + FCM) initialisé avec succès.")

    except Exception as e:
        logger.error(f"Échec de l'initialisation Firebase : {e}")
        raise


def get_firestore() -> FirestoreClient:
    """Retourne le client Firestore initialisé."""
    if _firestore_client is None:
        raise RuntimeError("Firebase n'est pas initialisé. Appelez initialiser_firebase().")
    return _firestore_client


def get_messaging():
    """Retourne le module FCM (Firebase Cloud Messaging) pour l'envoi de notifications push."""
    return messaging
