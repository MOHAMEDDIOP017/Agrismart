"""Test rapide du modèle SVM de recommandation de cultures."""
import os
import sys

# Ajouter le répertoire courant au PYTHONPATH
sys.path.insert(0, os.path.dirname(__file__))

from dotenv import load_dotenv
load_dotenv()

import numpy as np


def test():
    from app.services.recommandation_service import recommandation_service as service

    # Déclenchement du chargement lazy
    service._charger_modeles()

    if not service._modeles_charges:
        print("❌ Modèle SVM non chargé — mode dégradé heuristique activé")
        print("   Vérifier que les fichiers existent dans models_ia/ :")
        print("   - models_ia/svm_crop.pkl")
        print("   - models_ia/scaler_crop.pkl")
        print("   - models_ia/label_encoder_crop.pkl")
        return

    version = service._version_modele
    cultures = list(service._label_encoder.classes_)
    print(f"✅ Modèle chargé : SVM {version}")
    print(f"   Accuracy test : {service._metadata.get('test_accuracy', '?'):.2%}")
    print(f"   Cultures connues ({len(cultures)}) : {cultures}")

    def predire(n, p, k, temp, humidite, ph, pluvio, label=""):
        """Prédit la culture recommandée avec le SVM."""
        features = np.array([[n, p, k, temp, humidite, ph, pluvio]])
        features_norm = service._scaler.transform(features)
        probas = service._modele.predict_proba(features_norm)[0]
        classes = service._label_encoder.classes_
        resultats = sorted(zip(classes, probas), key=lambda x: x[1], reverse=True)

        print(f"\n🌱 {label}")
        print(f"   Features : N={n} P={p} K={k} | T={temp}°C Hum={humidite}% pH={ph} Pluvio={pluvio}mm")
        print(f"   → Culture recommandée : {resultats[0][0]} ({resultats[0][1]:.2%})")
        print(f"   → Top 3 :")
        for i, (culture, score) in enumerate(resultats[:3], 1):
            print(f"      {i}. {culture:<12s} → {score:.2%}")

    # Cas typique du Bassin arachidier (Kaolack, Thiès)
    predire(
        n=15, p=22, k=15,
        temp=30, humidite=45, ph=6.0, pluvio=540,
        label="Bassin arachidier (conditions typiques arachide)"
    )

    # Casamance — conditions rizicoles
    predire(
        n=80, p=40, k=40,
        temp=28, humidite=80, ph=6.2, pluvio=1200,
        label="Casamance (conditions typiques riz)"
    )

    # Zone sahélienne sèche — mil ou sorgho
    predire(
        n=10, p=10, k=10,
        temp=35, humidite=30, ph=6.5, pluvio=320,
        label="Zone sahélienne sèche (conditions typiques mil/sorgho)"
    )

    # Niayes — maraîchage (oignon/tomate)
    predire(
        n=60, p=50, k=80,
        temp=25, humidite=70, ph=7.0, pluvio=400,
        label="Niayes (conditions maraîchage oignon/tomate)"
    )

    print("\n✅ Test SVM terminé — modèle opérationnel")


if __name__ == "__main__":
    test()
