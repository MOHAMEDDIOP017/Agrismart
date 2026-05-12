"""Service d'authentification et de gestion des utilisateurs Firebase."""

import logging
from datetime import datetime, timezone
from typing import Optional

import firebase_admin.auth as firebase_auth

from app.services.firestore_service import utilisateurs_service
from app.core.exceptions import UtilisateurNonTrouveException, AuthentificationEchoueeException
from app.core import cache as redis_cache
from app.models.enums import RoleUtilisateur
from app.config import settings

logger = logging.getLogger(__name__)


class AuthService:
    """Gère l'authentification et les profils utilisateurs dans Firestore."""

    async def verifier_ou_creer_utilisateur(self, token_data: dict) -> dict:
        """
        Vérifie si l'utilisateur existe en Firestore, le crée sinon.
        Synchronise les Custom Claims Firebase avec le rôle Firestore (seulement si nécessaire).
        Le profil est mis en cache Redis (TTL = redis_ttl_profil).

        Args:
            token_data: Token Firebase décodé (contient uid, email, etc.)

        Returns:
            Profil complet de l'utilisateur depuis Firestore.
        """
        uid = token_data["uid"]
        cache_key = redis_cache.profil_cache_key(uid)

        utilisateur = await redis_cache.get_cached(cache_key)
        if utilisateur:
            return utilisateur

        utilisateur = await utilisateurs_service.lire(uid)

        if utilisateur is None:
            # Premier login via verify-token → toujours AGRICULTEUR
            profil = {
                "email": token_data.get("email", ""),
                "nom": token_data.get("name", "").split(" ")[-1] if token_data.get("name") else "",
                "prenom": token_data.get("name", "").split(" ")[0] if token_data.get("name") else "",
                "telephone": token_data.get("phone_number", ""),
                "role": RoleUtilisateur.AGRICULTEUR.value,
                "actif": True,
                "dateInscription": datetime.now(timezone.utc),
            }
            await utilisateurs_service.creer_avec_id(uid, profil)
            utilisateur = {"id": uid, **profil}
            logger.info(f"Nouveau profil créé pour l'utilisateur {uid}")

            # Claims forcés uniquement à la création
            try:
                firebase_auth.set_custom_user_claims(uid, {"role": profil["role"]})
            except Exception as e:
                logger.warning(f"Impossible de poser les Claims pour {uid} : {e}")
        else:
            # Synchronise les claims seulement si le rôle dans le token diffère de Firestore
            role_firestore = utilisateur.get("role", RoleUtilisateur.AGRICULTEUR.value)
            role_token = token_data.get("role") or token_data.get("claims", {}).get("role")
            if role_token != role_firestore:
                try:
                    firebase_auth.set_custom_user_claims(uid, {"role": role_firestore})
                    logger.debug(f"Custom Claims synchronisés pour {uid} : role={role_firestore}")
                except Exception as e:
                    logger.warning(f"Impossible de synchroniser les Claims pour {uid} : {e}")

        await redis_cache.set_cached(cache_key, utilisateur, settings.redis_ttl_profil)
        return utilisateur

    async def obtenir_utilisateur(self, uid: str) -> dict:
        """Retourne le profil d'un utilisateur par UID (avec cache Redis)."""
        cache_key = redis_cache.profil_cache_key(uid)
        cached = await redis_cache.get_cached(cache_key)
        if cached:
            return cached
        utilisateur = await utilisateurs_service.lire(uid)
        if utilisateur is None:
            raise UtilisateurNonTrouveException(uid)
        await redis_cache.set_cached(cache_key, utilisateur, settings.redis_ttl_profil)
        return utilisateur

    async def mettre_a_jour_profil(self, uid: str, donnees: dict) -> dict:
        """Met à jour le profil d'un utilisateur dans Firestore et invalide le cache."""
        await utilisateurs_service.mettre_a_jour(uid, donnees)
        await redis_cache.delete_cached(redis_cache.profil_cache_key(uid))
        return await self.obtenir_utilisateur(uid)

    async def suspendre_utilisateur(self, uid: str) -> dict:
        """Désactive un utilisateur (admin uniquement)."""
        await utilisateurs_service.mettre_a_jour(uid, {"actif": False})
        # Révoque également les sessions Firebase actives
        try:
            firebase_auth.revoke_refresh_tokens(uid)
            logger.info(f"Sessions Firebase révoquées pour {uid}")
        except Exception as e:
            logger.warning(f"Impossible de révoquer les sessions de {uid} : {e}")
        return await self.obtenir_utilisateur(uid)

    async def definir_role(self, uid: str, role: RoleUtilisateur) -> None:
        """
        Définit le rôle d'un utilisateur dans Firebase Custom Claims et Firestore.
        """
        # Custom claims Firebase (récupérés lors de la vérification du token)
        firebase_auth.set_custom_user_claims(uid, {"role": role.value})
        await utilisateurs_service.mettre_a_jour(uid, {"role": role.value})
        logger.info(f"Rôle '{role.value}' défini pour l'utilisateur {uid}")

    async def creer_utilisateur_complet(self, data: dict) -> dict:
        """
        Crée un utilisateur complet :
        1. Compte Firebase Auth
        2. Custom Claim avec le rôle
        3. Document Firestore avec champs spécifiques au rôle
        """
        role_str = data.get("role", "AGRICULTEUR").upper()
        try:
            role_enum = RoleUtilisateur(role_str)
        except ValueError:
            raise ValueError(f"Rôle invalide : {role_str}")

        # 1. Créer le compte Firebase Auth
        fb_user = firebase_auth.create_user(
            email=data["email"],
            password=data["motDePasse"],
            display_name=f"{data.get('prenom', '')} {data.get('nom', '')}".strip(),
        )
        uid = fb_user.uid

        # 2. Définir le Custom Claim rôle
        firebase_auth.set_custom_user_claims(uid, {"role": role_enum.value})

        # 3. Construire le document Firestore
        doc = {
            "id": uid,
            "nom": data.get("nom", ""),
            "prenom": data.get("prenom", ""),
            "email": data["email"],
            "telephone": data.get("telephone", ""),
            "role": role_enum.value,
            "zone_geographique": data.get("zone_geographique", ""),
            "actif": True,
            "dateInscription": datetime.now(timezone.utc),
        }

        if role_enum == RoleUtilisateur.AGRICULTEUR:
            doc.update({
                "adresse": data.get("adresse", ""),
                "village_ville": data.get("village_ville", ""),
            })
        elif role_enum == RoleUtilisateur.EXPERT:
            doc.update({
                "specialite": data.get("specialite", ""),
                "anneesExperience": data.get("anneesExperience", 0),
                "nbDiagnosticsValides": 0,
                "tauxPrecisionValidee": 0.0,
            })
        elif role_enum == RoleUtilisateur.ADMIN:
            doc.update({
                "niveauAcces": data.get("niveauAcces", 2),
                "dateCreation": datetime.now(timezone.utc),
            })

        await utilisateurs_service.creer_avec_id(uid, doc)
        logger.info(f"Utilisateur {uid} créé avec le rôle {role_enum.value}")
        return {"id": uid, "role": role_enum.value, "email": data["email"]}

    async def lister_utilisateurs(self, limite: int = 100) -> list[dict]:
        """Liste tous les utilisateurs (admin uniquement)."""
        return await utilisateurs_service.lister(limite=limite)

    async def supprimer_utilisateur(self, uid: str) -> bool:
        """Supprime un utilisateur de Firebase Auth et Firestore."""
        try:
            firebase_auth.delete_user(uid)
        except Exception as e:
            logger.warning(f"Impossible de supprimer l'utilisateur Firebase {uid} : {e}")
        await utilisateurs_service.supprimer(uid)
        logger.info(f"Utilisateur {uid} supprimé.")
        return True


auth_service = AuthService()
