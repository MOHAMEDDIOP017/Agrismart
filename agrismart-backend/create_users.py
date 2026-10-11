"""
Script de création des comptes de référence KoobalaTech (un par rôle).

Crée — ou met à jour si l'email existe déjà — un agriculteur, un expert et un
administrateur : compte Firebase Auth, custom claim `role`, et document dans la
collection Firestore `users`.

Le script est idempotent : le relancer ne crée pas de doublon, il réaligne le
mot de passe, le claim et le document sur les valeurs ci-dessous.

Usage :
    cd agrismart-backend
    set PWD_AGRICULTEUR=...       (PowerShell : $env:PWD_AGRICULTEUR = "...")
    set PWD_EXPERT=...
    set PWD_ADMIN=...
    python create_users.py

Prérequis :
    - firebase_service_account.json présent dans le répertoire courant
    - variables d'environnement PWD_AGRICULTEUR, PWD_EXPERT et PWD_ADMIN
    - pip install firebase-admin
"""

import os
import sys
from datetime import datetime, timezone

FIREBASE_SA = "./firebase_service_account.json"
COLLECTION = "users"

# ── Comptes à créer ─────────────────────────────────────────────────────────
# Les clés en snake_case (zone_geographique, village_ville) sont celles que lit
# réellement l'API ; les clés en camelCase suivent les modèles Pydantic.
#
# Les mots de passe ne sont pas écrits ici : ce fichier est versionné dans un
# dépôt public, et un mot de passe écrit dans le code y reste lisible même
# après avoir été retiré, puisque l'historique Git garde chaque version.
# Chaque compte nomme donc la variable d'environnement où lire le sien.
COMPTES = [
    {
        "email": "agriculteur@koobalatec.sn",
        "var_mdp": "PWD_AGRICULTEUR",
        "nom": "Ndiaye",
        "prenom": "Moussa",
        "telephone": "+221 77 900 00 11",
        "role": "AGRICULTEUR",
        "extra": {
            "zone_geographique": "Thiès",
            "adresse": "Quartier Randoulène",
            "village_ville": "Thiès",
            "nombre_champs": 0,
            "nombre_recommandations": 0,
            "nombre_evaluations": 0,
            "notifications_actives": True,
        },
    },
    {
        "email": "expert@koobalatec.sn",
        "var_mdp": "PWD_EXPERT",
        "nom": "Sarr",
        "prenom": "Aminata",
        "telephone": "+221 77 900 00 22",
        "role": "EXPERT",
        "extra": {
            "zone_geographique": "Kaolack",
            "specialite": "Phytopathologie",
            "regionCouverture": "Bassin arachidier",
            "anneesExperience": 8,
            "nbDiagnosticsValides": 0,
            "tauxPrecisionValidee": 0.0,
            "notifications_actives": True,
        },
    },
    {
        "email": "admin@koobalatec.sn",
        "var_mdp": "PWD_ADMIN",
        "nom": "Diop",
        "prenom": "Fatou",
        "telephone": "+221 77 900 00 01",
        "role": "ADMIN",
        "extra": {
            "zone_geographique": "Dakar",
            "niveauAcces": 3,  # 1 = lecture seule | 2 = standard | 3 = super admin
            "notifications_actives": True,
        },
    },
]
# ────────────────────────────────────────────────────────────────────────────


def creer_compte(auth, db, compte: dict) -> dict:
    """Crée ou met à jour un compte Auth + son document Firestore."""
    email = compte["email"]
    mot_de_passe = os.environ[compte["var_mdp"]]
    display_name = f"{compte['prenom']} {compte['nom']}"

    # ── Firebase Auth ────────────────────────────────────────────────────────
    try:
        user = auth.get_user_by_email(email)
        auth.update_user(
            user.uid,
            password=mot_de_passe,
            display_name=display_name,
            email_verified=True,
        )
        etat = "mis a jour"
    except auth.UserNotFoundError:
        user = auth.create_user(
            email=email,
            password=mot_de_passe,
            display_name=display_name,
            email_verified=True,
        )
        etat = "cree"

    uid = user.uid

    # ── Custom claim : lu par le backend pour les controles de role ──────────
    auth.set_custom_user_claims(uid, {"role": compte["role"]})

    # ── Document Firestore ───────────────────────────────────────────────────
    maintenant = datetime.now(timezone.utc)
    existant = db.collection(COLLECTION).document(uid).get()
    date_inscription = maintenant
    if existant.exists:
        date_inscription = existant.to_dict().get("dateInscription", maintenant)

    doc = {
        "id": uid,
        "nom": compte["nom"],
        "prenom": compte["prenom"],
        "email": email,
        "telephone": compte["telephone"],
        "role": compte["role"],
        "actif": True,
        "dateInscription": date_inscription,
        "dateCreation": maintenant,
        **compte["extra"],
    }
    db.collection(COLLECTION).document(uid).set(doc, merge=True)

    return {"uid": uid, "etat": etat, "email": email, "role": compte["role"]}


def main():
    # Les trois variables sont vérifiées d'un coup, avant le premier appel à
    # Firebase : un script qui crée l'agriculteur puis s'arrête faute du mot
    # de passe de l'expert laisserait les comptes à moitié alignés.
    manquantes = [c["var_mdp"] for c in COMPTES if not os.environ.get(c["var_mdp"])]
    if manquantes:
        print("[ERREUR]  Variables d'environnement non definies : "
              + ", ".join(manquantes))
        print('    PowerShell : $env:PWD_ADMIN = "VotreMotDePasse"')
        print("    Bash       : export PWD_ADMIN='VotreMotDePasse'")
        sys.exit(1)

    try:
        import firebase_admin
        from firebase_admin import credentials, auth, firestore
    except ImportError:
        print("[ERREUR] firebase-admin n'est pas installe. Executez : pip install firebase-admin")
        sys.exit(1)

    if not firebase_admin._apps:
        try:
            cred = credentials.Certificate(FIREBASE_SA)
            app = firebase_admin.initialize_app(cred)
        except Exception as e:
            print(f"[ERREUR] Initialisation Firebase impossible : {e}")
            print(f"         Verifiez que '{FIREBASE_SA}' existe et est valide.")
            sys.exit(1)
    else:
        app = firebase_admin.get_app()

    print(f"[OK] Firebase Admin initialise sur le projet : {app.project_id}")
    db = firestore.client()

    resultats = []
    for compte in COMPTES:
        try:
            r = creer_compte(auth, db, compte)
            print(f"[OK] {r['role']:<12} {r['email']:<28} {r['etat']} -> {r['uid']}")
            resultats.append(r)
        except Exception as e:
            print(f"[ERREUR] {compte['role']} ({compte['email']}) : {type(e).__name__} {e}")

    if not resultats:
        sys.exit(1)

    print()
    print("=" * 74)
    print("  COMPTES DISPONIBLES")
    print("=" * 74)
    for r in resultats:
        print(f"  {r['role']:<12} {r['email']:<28} {r['uid']}")
    print("=" * 74)
    print("  Mots de passe : ceux des variables PWD_AGRICULTEUR, PWD_EXPERT")
    print("  et PWD_ADMIN. Ils ne sont pas reaffiches ici.")


if __name__ == "__main__":
    main()
