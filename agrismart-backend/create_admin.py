"""
Script de création du compte Administrateur initial AgriSmart.

Usage :
    cd agrismart-backend
    python create_admin.py

Prérequis :
    - firebase_service_account.json présent dans le répertoire courant
    - pip install firebase-admin
"""

import sys
from datetime import datetime, timezone

# ── Paramètres du compte admin à créer ──────────────────────────────────────
ADMIN_EMAIL     = "admin@agrismart.sn"
ADMIN_PASSWORD  = "Admin2026!"
ADMIN_NOM       = "Diop"
ADMIN_PRENOM    = "Fatou"
ADMIN_TELEPHONE = "+221 77 900 00 01"
ADMIN_ZONE      = "Dakar"
ADMIN_NIVEAU    = 3        # 1 = Lecture seule | 2 = Standard | 3 = Super admin
FIREBASE_SA     = "./firebase_service_account.json"
COLLECTION      = "users"
# ────────────────────────────────────────────────────────────────────────────


def main():
    try:
        import firebase_admin
        from firebase_admin import credentials, auth, firestore
    except ImportError:
        print("[ERREUR]  firebase-admin n'est pas installé.")
        print("    Exécutez : pip install firebase-admin")
        sys.exit(1)

    # Initialisation Firebase Admin SDK
    if not firebase_admin._apps:
        try:
            cred = credentials.Certificate(FIREBASE_SA)
            firebase_admin.initialize_app(cred)
            print("[OK]  Firebase Admin SDK initialisé.")
        except Exception as e:
            print(f"[ERREUR]  Impossible d'initialiser Firebase : {e}")
            print(f"    Vérifiez que '{FIREBASE_SA}' existe et est valide.")
            sys.exit(1)

    db = firestore.client()

    # ── Étape 1 : Créer ou récupérer le compte Firebase Auth ────────────────
    uid = None
    try:
        user = auth.get_user_by_email(ADMIN_EMAIL)
        uid = user.uid
        print(f"[INFO]   Compte Firebase existant trouvé : {uid}")
        # Mettre à jour le mot de passe si le compte existe déjà
        auth.update_user(uid, password=ADMIN_PASSWORD,
                         display_name=f"{ADMIN_PRENOM} {ADMIN_NOM}")
        print("[OK]  Mot de passe et nom d'affichage mis à jour.")
    except auth.UserNotFoundError:
        user = auth.create_user(
            email=ADMIN_EMAIL,
            password=ADMIN_PASSWORD,
            display_name=f"{ADMIN_PRENOM} {ADMIN_NOM}",
            email_verified=True,
        )
        uid = user.uid
        print(f"[OK]  Compte Firebase Auth créé : {uid}")

    # ── Étape 2 : Poser le Custom Claim role=ADMIN ───────────────────────────
    auth.set_custom_user_claims(uid, {"role": "ADMIN"})
    print("[OK]  Custom Claim { role: 'ADMIN' } posé sur Firebase Auth.")

    # ── Étape 3 : Créer / mettre à jour le document Firestore ────────────────
    doc_data = {
        "id": uid,
        "nom": ADMIN_NOM,
        "prenom": ADMIN_PRENOM,
        "email": ADMIN_EMAIL,
        "telephone": ADMIN_TELEPHONE,
        "role": "ADMIN",
        "zone_geographique": ADMIN_ZONE,
        "actif": True,
        "niveauAcces": ADMIN_NIVEAU,
        "dateInscription": datetime.now(timezone.utc),
        "dateCreation": datetime.now(timezone.utc),
    }

    db.collection(COLLECTION).document(uid).set(doc_data)
    print(f"[OK]  Document Firestore créé dans la collection '{COLLECTION}'.")

    # ── Résumé ───────────────────────────────────────────────────────────────
    print()
    print("=" * 50)
    print("  COMPTE ADMIN CRÉÉ AVEC SUCCÈS")
    print("=" * 50)
    print(f"  Email    : {ADMIN_EMAIL}")
    print(f"  Mot de passe : {ADMIN_PASSWORD}")
    print(f"  UID      : {uid}")
    print(f"  Rôle     : ADMIN (niveau {ADMIN_NIVEAU})")
    print("=" * 50)
    print()
    print("Vous pouvez maintenant vous connecter dans l'app avec ces identifiants.")


if __name__ == "__main__":
    main()
