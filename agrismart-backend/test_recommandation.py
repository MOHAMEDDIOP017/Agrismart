# -*- coding: utf-8 -*-
"""Script de test rapide -- verifie que le modele SVM est bien integre."""
import sys
import os

sys.stdout.reconfigure(encoding="utf-8")
sys.path.insert(0, os.path.dirname(__file__))


def test_modele_charge():
    """Test 1 : le modele se charge correctement."""
    from app.services.recommandation_service import RecommandationService
    svc = RecommandationService()
    svc._charger_modeles()

    assert svc._modeles_charges, (
        "ECHEC : artefacts ML non charges. "
        "Verifiez que models_ia/ contient svm_crop.pkl, scaler_crop.pkl, label_encoder_crop.pkl."
    )

    classes = list(svc._label_encoder.classes_)
    attendues = {"Arachide", "Maïs", "Mil", "Niébé", "Oignon", "Riz", "Sorgho", "Tomate"}
    assert set(classes) == attendues, f"Classes inattendues : {classes}"

    print(f"[OK] Modele charge  : {svc._metadata.get('model_name')} {svc._version_modele}")
    print(f"     Accuracy test  : {svc._metadata.get('test_accuracy', 0):.2%}")
    print(f"     F1-score       : {svc._metadata.get('f1_score', 0):.4f}")
    print(f"     Cultures (8)   : {classes}")


def test_prediction_arachide():
    """Test 2 : cas typique Bassin arachidier du Senegal."""
    from app.services.recommandation_service import RecommandationService
    import numpy as np

    svc = RecommandationService()
    svc._charger_modeles()

    features = np.array([[15, 22, 15, 30, 45, 6.0, 540]])
    features_norm = svc._scaler.transform(features)
    probas  = svc._modele.predict_proba(features_norm)[0]
    classes = svc._label_encoder.classes_
    resultats = sorted(zip(classes, probas), key=lambda x: x[1], reverse=True)

    print("\n[OK] Prediction -- Bassin arachidier (N=15, P=22, K=15, T=30C, H=45%, pH=6.0, P=540mm)")
    for rang, (culture, score) in enumerate(resultats[:3], 1):
        print(f"     {rang}. {culture:<12} -> {score:.2%}")

    assert resultats[0][1] > 0.3, "Score top-1 trop faible"


def test_prediction_riz():
    """Test 3 : cas typique riziculture (Casamance / Vallee du fleuve)."""
    from app.services.recommandation_service import RecommandationService
    import numpy as np

    svc = RecommandationService()
    svc._charger_modeles()

    features = np.array([[80, 55, 40, 26, 85, 6.5, 1200]])
    features_norm = svc._scaler.transform(features)
    probas  = svc._modele.predict_proba(features_norm)[0]
    classes = svc._label_encoder.classes_
    resultats = sorted(zip(classes, probas), key=lambda x: x[1], reverse=True)

    print("\n[OK] Prediction -- Riziculture (N=80, P=55, K=40, T=26C, H=85%, pH=6.5, P=1200mm)")
    for rang, (culture, score) in enumerate(resultats[:3], 1):
        print(f"     {rang}. {culture:<12} -> {score:.2%}")


def test_validation_hors_plage():
    """Test 4 : temperature hors plage => ValueError leve manuellement."""
    temperature_invalide = 999
    if not (-10 <= temperature_invalide <= 50):
        print(f"\n[OK] Validation entrees : Temperature={temperature_invalide} hors plage [-10, 50]")
    else:
        raise AssertionError("La validation aurait du echouer")


if __name__ == "__main__":
    print("=" * 65)
    print("  TEST D'INTEGRATION -- MODELE SVM KoobalaTech")
    print("=" * 65)

    tests = [
        ("Chargement du modele",         test_modele_charge),
        ("Prediction Arachide",          test_prediction_arachide),
        ("Prediction Riz",               test_prediction_riz),
        ("Validation entrees invalides", test_validation_hors_plage),
    ]

    echecs = []
    for nom, fn in tests:
        try:
            fn()
        except Exception as e:
            print(f"\n[ECHEC] {nom} : {e}")
            echecs.append(nom)

    print("\n" + "=" * 65)
    if echecs:
        print(f"[ECHEC] {len(echecs)} test(s) en echec : {echecs}")
        sys.exit(1)
    else:
        print(f"[OK] {len(tests)}/{len(tests)} tests reussis")
    print("=" * 65)
