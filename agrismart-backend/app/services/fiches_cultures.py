"""
Fiches techniques de référence par culture (conseils, périodes, rendement,
besoin en eau, prix marché, engrais, maladies fréquentes).

Ces données sont indépendantes du moteur de prédiction : elles servent à
enrichir une culture prédite (par son nom) avec des informations agronomiques
pratiques. Utilisées par `recommandation_service_v2.py` (moteur multi-label
actif) et `culture_service.py` (seed du référentiel Culture).

Historique : ces dicts vivaient dans `recommandation_service.py` (moteur SVM
v1), retiré du projet — ses artefacts (`svm_crop.pkl`, `scaler_crop.pkl`,
`label_encoder_crop.pkl`) n'ont jamais été présents dans le dépôt, rendant la
comparaison SVM vs multi-label prévue pour le mémoire impossible en pratique.
Seules les données de référence, réutilisées par le moteur v2, ont été
conservées ici.
"""

# ──────────────────────────────────────────────────────────────────────────
# Données agronomiques par culture (référentiel commun v1/v2)
# ──────────────────────────────────────────────────────────────────────────

CONSEILS_PAR_CULTURE: dict[str, str] = {
    "Arachide": "Enrichit le sol en azote. Rotation recommandée avec le mil. "
                "Sol sableux bien drainé, pH 5.5–7.0.",
    "Maïs":     "Forte demande en eau et en azote. Réservez les zones irriguées "
                "ou à pluviométrie > 600 mm. Apport d'urée recommandé.",
    "Mil":      "Culture résistante à la sécheresse, idéale pour les zones sahéliennes. "
                "Semez en juin-juillet dès les premières pluies.",
    "Niébé":    "Légumineuse fixatrice d'azote, excellente en association. "
                "Bonne tolérance à la chaleur et aux sols pauvres.",
    "Oignon":   "Marché porteur. Privilégiez les variétés locales (Galmi violet). "
                "Irrigation régulière indispensable.",
    "Riz":      "Requis : plaine inondable ou périmètre irrigué. "
                "Zone casamançaise et vallée du fleuve Sénégal idéales.",
    "Sorgho":   "Adapté aux sols pauvres et aux périodes de sécheresse prolongée. "
                "Excellente culture de sécurité alimentaire.",
    "Tomate":   "Nécessite un suivi phytosanitaire régulier. "
                "Préférez la saison sèche en irrigué pour limiter les maladies fongiques.",
}

PERIODES_PAR_CULTURE: dict[str, str] = {
    "Arachide": "Juin - Juillet",
    "Maïs":     "Juin - Août",
    "Mil":      "Juin - Juillet",
    "Niébé":    "Juillet - Août",
    "Oignon":   "Novembre - Janvier",
    "Riz":      "Juillet - Août (hivernage)",
    "Sorgho":   "Juin - Août",
    "Tomate":   "Octobre - Décembre (saison sèche)",
}

RENDEMENT_PAR_CULTURE: dict[str, float] = {
    "Arachide": 1.2,
    "Maïs":     2.0,
    "Mil":      0.8,
    "Niébé":    0.6,
    "Oignon":  20.0,
    "Riz":      3.5,
    "Sorgho":   1.0,
    "Tomate":  15.0,
}

# Besoins en eau (mm/saison) — source ISRA / FAO Sénégal
BESOIN_EAU_PAR_CULTURE: dict[str, int] = {
    "Arachide": 500,
    "Maïs":     600,
    "Mil":      350,
    "Niébé":    400,
    "Oignon":   550,
    "Riz":     1200,
    "Sorgho":   400,
    "Tomate":   600,
}

# Prix marché estimés (FCFA/kg) — source ANSD / marchés ruraux sénégalais
PRIX_MARCHE_PAR_CULTURE: dict[str, int] = {
    "Arachide": 300,
    "Maïs":     175,
    "Mil":      250,
    "Niébé":    350,
    "Oignon":   200,
    "Riz":      400,
    "Sorgho":   200,
    "Tomate":   150,
}

# Engrais recommandés par culture (pratiques ISRA Sénégal)
ENGRAIS_PAR_CULTURE: dict[str, list[str]] = {
    "Arachide": ["Phosphate naturel 100 kg/ha", "Dolomie 200 kg/ha"],
    "Maïs":     ["Urée 46% 100 kg/ha", "NPK 15-15-15 150 kg/ha"],
    "Mil":      ["Fumure organique 5 t/ha", "Phosphate de Tilemsi 100 kg/ha"],
    "Niébé":    ["Inoculant rhizobium", "Phosphate naturel 50 kg/ha"],
    "Oignon":   ["NPK 17-17-17 300 kg/ha", "Urée 100 kg/ha", "Sulfate de potasse 50 kg/ha"],
    "Riz":      ["Urée 46% 100 kg/ha", "DAP 50 kg/ha", "Chlorure de potassium 60 kg/ha"],
    "Sorgho":   ["Fumure organique 3 t/ha", "NPK 14-18-18 100 kg/ha"],
    "Tomate":   ["NPK 12-24-12 200 kg/ha", "Calcium-Bore en foliaire"],
}

# Maladies fréquentes par culture au Sénégal
MALADIES_PAR_CULTURE: dict[str, list[str]] = {
    "Arachide": ["Cercosporiose", "Rosette de l'arachide"],
    "Maïs":     ["Helminthosporiose", "Rouille commune du maïs"],
    "Mil":      ["Mildiou du mil", "Charbon du mil"],
    "Niébé":    ["Virus de la mosaïque du niébé", "Anthracnose"],
    "Oignon":   ["Mildiou de l'oignon", "Fusariose basale"],
    "Riz":      ["Pyriculariose du riz", "Bactériose du riz"],
    "Sorgho":   ["Charbon couvert", "Anthracnose du sorgho"],
    "Tomate":   ["Mildiou de la tomate", "Alternariose", "Fusariose"],
}
