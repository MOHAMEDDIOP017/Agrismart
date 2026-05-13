import firebase_admin
from firebase_admin import credentials, firestore

if not firebase_admin._apps:
    cred = credentials.Certificate("./firebase_service_account.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

# Supprimer les faux utilisateurs de développement
fake_ids = ["admin_001", "usr_001"]
for uid in fake_ids:
    doc = db.collection("users").document(uid).get()
    if doc.exists:
        db.collection("users").document(uid).delete()
        print(f"Supprime: {uid}")
    else:
        print(f"Absent (deja propre): {uid}")

print("Nettoyage termine.")
