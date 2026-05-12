import '../features/detection/domain/entities/maladie_entity.dart';
import '../features/detection/domain/entities/traitement_entity.dart';
import '../features/detection/domain/enums/niveau_gravite.dart';
import '../features/detection/domain/enums/type_traitement.dart';

/// Mock data de 8 maladies réalistes adaptées à l'Afrique de l'Ouest
final List<MaladieEntity> maladiesMock = [
  // 1. Mildiou
  const MaladieEntity(
    id: 'mil_001',
    nom: 'Mildiou',
    nomScientifique: 'Plasmopara viticola',
    description:
        'Maladie fongique causant des taches huileuses vert-jaunâtre sur le dessus des feuilles et un duvet blanc-grisâtre en dessous. Très répandue en saison humide.',
    symptomes: [
      'Taches huileuses vert-jaunâtre',
      'Duvet blanc en dessous des feuilles',
      'Jaunissement foliaire',
      'Nécrose brune',
      'Chute prématurée des feuilles',
    ],
    gravite: NiveauGravite.eleve,
    culturesAffectees: ['Tomate', 'Pomme de terre', 'Oignon', 'Mil'],
    agentPathogene: 'Oomycète (faux champignon)',
    conditionsFavorables: 'Humidité > 80%, température 15-25°C, pluies fréquentes',
    traitements: [
      TraitementEntity(
        id: 'trt_mil_001',
        nomProduit: 'Mancozèbe 80 WP',
        dosage: '2,5 kg/ha',
        frequenceApplication: 'Tous les 7-10 jours',
        dureeDays: 21,
        type: TypeTraitement.chimique,
        coutFcfa: 4500,
        instructionsDetaillees:
            'Diluer dans 200L d\'eau. Pulvériser le matin ou le soir. Alterner avec d\'autres fongicides pour éviter les résistances.',
        precautions: 'Porter des gants et un masque. Ne pas pulvériser par vent fort.',
      ),
      TraitementEntity(
        id: 'trt_mil_002',
        nomProduit: 'Cuivre (Bouillie bordelaise)',
        dosage: '3 kg/ha',
        frequenceApplication: 'Tous les 14 jours',
        dureeDays: 28,
        type: TypeTraitement.biologique,
        coutFcfa: 3200,
        instructionsDetaillees:
            'Mélanger avec de l\'eau. Application en prévention avant les pluies.',
        precautions: 'Ne pas appliquer par temps chaud (>30°C).',
      ),
    ],
  ),

  // 2. Cercosporiose
  const MaladieEntity(
    id: 'cer_001',
    nom: 'Cercosporiose',
    nomScientifique: 'Cercospora beticola',
    description:
        'Champignon causant des taches circulaires avec un centre gris ou blanc et une bordure brune ou rouge. Très commune sur les légumineuses en Afrique de l\'Ouest.',
    symptomes: [
      'Taches circulaires à centre gris',
      'Bordure brun-rouge',
      'Jaunissement autour des taches',
      'Défoliation progressive',
    ],
    gravite: NiveauGravite.modere,
    culturesAffectees: ['Arachide', 'Niébé', 'Sésame', 'Haricot'],
    agentPathogene: 'Champignon ascomycète',
    conditionsFavorables: 'Températures 25-35°C, humidité relative > 70%',
    traitements: [
      TraitementEntity(
        id: 'trt_cer_001',
        nomProduit: 'Carbendazime 50 SC',
        dosage: '1,5 L/ha',
        frequenceApplication: 'Tous les 10-14 jours',
        dureeDays: 21,
        type: TypeTraitement.chimique,
        coutFcfa: 5800,
        instructionsDetaillees:
            'Diluer dans 300L d\'eau et pulvériser uniformément. Commencer dès l\'apparition des premiers symptômes.',
        precautions: 'Éviter le contact avec la peau et les yeux.',
      ),
      TraitementEntity(
        id: 'trt_cer_002',
        nomProduit: 'Neem (Azadirachtine)',
        dosage: '5 L/ha',
        frequenceApplication: 'Tous les 7 jours',
        dureeDays: 28,
        type: TypeTraitement.biologique,
        coutFcfa: 2800,
        instructionsDetaillees:
            'Extraire l\'huile de neem et diluer à 1%. Appliquer le soir pour éviter la dégradation par UV.',
      ),
    ],
  ),

  // 3. Anthracnose
  const MaladieEntity(
    id: 'ant_001',
    nom: 'Anthracnose',
    nomScientifique: 'Colletotrichum gloeosporioides',
    description:
        'Maladie fongique très répandue en zone tropicale. Cause des lésions sombres et déprimées sur les feuilles, tiges et fruits. Peut provoquer des pertes importantes en post-récolte.',
    symptomes: [
      'Lésions sombres déprimées',
      'Taches noires sur fruits',
      'Pourriture des fruits',
      'Chancres sur tiges',
      'Mortalité des jeunes plants',
    ],
    gravite: NiveauGravite.critique,
    culturesAffectees: ['Manguier', 'Tomate', 'Piment', 'Maïs', 'Haricot'],
    agentPathogene: 'Champignon deutéromycète',
    conditionsFavorables: 'Températures 25-30°C, pluies abondantes, blessures mécaniques',
    traitements: [
      TraitementEntity(
        id: 'trt_ant_001',
        nomProduit: 'Thiophanate-méthyl 70 WP',
        dosage: '1 kg/ha',
        frequenceApplication: 'Tous les 7-10 jours',
        dureeDays: 14,
        type: TypeTraitement.curatif,
        coutFcfa: 7200,
        instructionsDetaillees:
            'Traitement précoce indispensable. Pulvériser sur toutes les parties de la plante.',
        precautions: 'Respecter un délai avant récolte de 14 jours.',
      ),
      TraitementEntity(
        id: 'trt_ant_002',
        nomProduit: 'Trichoderma harzianum',
        dosage: '4 kg/ha',
        frequenceApplication: 'Tous les 14 jours',
        dureeDays: 21,
        type: TypeTraitement.biologique,
        coutFcfa: 4200,
        instructionsDetaillees:
            'Appliquer au sol et en folaire. Efficace en prévention et en début d\'infection.',
      ),
    ],
  ),

  // 4. Rouille
  const MaladieEntity(
    id: 'rus_001',
    nom: 'Rouille',
    nomScientifique: 'Puccinia sorghi',
    description:
        'Maladie causée par des champignons du genre Puccinia. Forme des pustules orange-brun caractéristiques sur les feuilles. Très contagieuse en conditions venteuses.',
    symptomes: [
      'Pustules orange-brun sur feuilles',
      'Poudre rouille visible',
      'Jaunissement des feuilles atteintes',
      'Défoliation en cas d\'attaque sévère',
    ],
    gravite: NiveauGravite.eleve,
    culturesAffectees: ['Maïs', 'Sorgho', 'Mil', 'Blé', 'Soja'],
    agentPathogene: 'Champignon basidiomycète',
    conditionsFavorables: 'Températures fraîches 15-22°C, rosée nocturne, vent',
    traitements: [
      TraitementEntity(
        id: 'trt_rus_001',
        nomProduit: 'Propiconazole 25 EC',
        dosage: '0,5 L/ha',
        frequenceApplication: 'Tous les 14 jours',
        dureeDays: 21,
        type: TypeTraitement.chimique,
        coutFcfa: 6500,
        instructionsDetaillees:
            'Appliquer dès l\'apparition des premières pustules. Couvrir uniformément le feuillage.',
        precautions: 'Ne pas mélanger avec d\'autres produits alcalins.',
      ),
      TraitementEntity(
        id: 'trt_rus_002',
        nomProduit: 'Soufre micronisé',
        dosage: '3 kg/ha',
        frequenceApplication: 'Tous les 10 jours',
        dureeDays: 30,
        type: TypeTraitement.preventif,
        coutFcfa: 1800,
        instructionsDetaillees: 'Application en poudrage ou en bouillie. Préventif efficace.',
        precautions: 'Ne pas appliquer par chaleur > 30°C (risque de brûlures).',
      ),
    ],
  ),

  // 5. Bactériose vasculaire
  const MaladieEntity(
    id: 'bac_001',
    nom: 'Bactériose vasculaire',
    nomScientifique: 'Xanthomonas campestris',
    description:
        'Infection bactérienne affectant le système vasculaire des plantes. Cause un flétrissement progressif avec brunissement des vaisseaux. Se propage par l\'eau et les outils.',
    symptomes: [
      'Lésions aqueuses marginales',
      'Brunissement vasculaire',
      'Flétrissement progressif',
      'Exsudat bactérien jaune',
    ],
    gravite: NiveauGravite.faible,
    culturesAffectees: ['Chou', 'Navet', 'Tomate', 'Poivron'],
    agentPathogene: 'Bactérie gram-négative',
    conditionsFavorables: 'Blessures, humidité, températures 25-35°C',
    traitements: [
      TraitementEntity(
        id: 'trt_bac_001',
        nomProduit: 'Cuivre hydroxyde (Kocide)',
        dosage: '2 kg/ha',
        frequenceApplication: 'Tous les 7 jours',
        dureeDays: 14,
        type: TypeTraitement.curatif,
        coutFcfa: 3800,
        instructionsDetaillees:
            'Appliquer en prévention et dès les premiers symptômes. Désinfecter les outils.',
      ),
    ],
  ),

  // 6. Fusariose
  const MaladieEntity(
    id: 'fus_001',
    nom: 'Fusariose',
    nomScientifique: 'Fusarium oxysporum',
    description:
        'Maladie tellurique grave causant un flétrissement vasculaire. La plante se fane progressivement malgré un sol humide. Survit dans le sol plusieurs années.',
    symptomes: [
      'Flétrissement unilatéral',
      'Jaunissement des feuilles basses',
      'Brunissement vasculaire rougeâtre',
      'Racines brunes',
      'Mort de la plante',
    ],
    gravite: NiveauGravite.critique,
    culturesAffectees: ['Tomate', 'Aubergine', 'Melon', 'Concombre', 'Sésame'],
    agentPathogene: 'Champignon tellurique',
    conditionsFavorables: 'Sol pauvre, stresshydrique, pH acide, températures 25-32°C',
    traitements: [
      TraitementEntity(
        id: 'trt_fus_001',
        nomProduit: 'Trichoderma asperellum',
        dosage: '5 kg/ha',
        frequenceApplication: 'À la plantation puis mensuel',
        dureeDays: 60,
        type: TypeTraitement.biologique,
        coutFcfa: 5500,
        instructionsDetaillees:
            'Trempage racinaire avant transplantation. Application en sol traitement.',
      ),
      TraitementEntity(
        id: 'trt_fus_002',
        nomProduit: 'Rotation culturale',
        dosage: 'N/A',
        frequenceApplication: 'Annuelle',
        dureeDays: 365,
        type: TypeTraitement.preventif,
        coutFcfa: 0,
        instructionsDetaillees:
            'Alterner avec céréales ou légumineuses. Éviter cultures sensibles pendant 3-4 ans.',
      ),
    ],
  ),

  // 7. Oïdium
  const MaladieEntity(
    id: 'oid_001',
    nom: 'Oïdium',
    nomScientifique: 'Erysiphe cichoracearum',
    description:
        'Maladie fongique formant un feutrage blanc poudreux caractéristique sur les organes verts. Prospère en conditions sèches et chaudes contrairement aux autres champignons.',
    symptomes: [
      'Feutrage blanc poudreux',
      'Déformation des jeunes feuilles',
      'Jaunissement sous le mycélium',
      'Nécrose en cas d\'attaque sévère',
    ],
    gravite: NiveauGravite.modere,
    culturesAffectees: ['Courgette', 'Concombre', 'Piment', 'Aubergine', 'Haricot'],
    agentPathogene: 'Champignon ectoparasite obligatoire',
    conditionsFavorables: 'Temps sec, températures 18-30°C, forte amplitude thermique',
    traitements: [
      TraitementEntity(
        id: 'trt_oid_001',
        nomProduit: 'Soufre mouillable',
        dosage: '2,5 kg/ha',
        frequenceApplication: 'Tous les 10-14 jours',
        dureeDays: 28,
        type: TypeTraitement.preventif,
        coutFcfa: 2200,
        instructionsDetaillees:
            'Très efficace en prévention. Appliquer tôt le matin. Couvrir toute la plante.',
        precautions: 'Délai avant récolte : 2 jours. Éviter la chaleur.',
      ),
      TraitementEntity(
        id: 'trt_oid_002',
        nomProduit: 'Hexaconazole 5 SC',
        dosage: '0,8 L/ha',
        frequenceApplication: 'Tous les 14 jours',
        dureeDays: 21,
        type: TypeTraitement.chimique,
        coutFcfa: 4800,
        instructionsDetaillees: 'Traitement curatif efficace. Alterner avec le soufre.',
      ),
    ],
  ),

  // 8. Alternariose
  const MaladieEntity(
    id: 'alt_001',
    nom: 'Alternariose',
    nomScientifique: 'Alternaria solani',
    description:
        'Maladie fongique causant des taches brunes concentriques caractéristiques en forme de cible. Affecte particulièrement les feuilles âgées en bas de la plante.',
    symptomes: [
      'Taches brunes concentriques (cible)',
      'Halos jaunes autour des taches',
      'Attaque des feuilles basses en premier',
      'Taches sur tiges et fruits',
    ],
    gravite: NiveauGravite.eleve,
    culturesAffectees: ['Tomate', 'Pomme de terre', 'Aubergine', 'Carotte'],
    agentPathogene: 'Champignon hyphomycète',
    conditionsFavorables: 'Alternance humidité/sécheresse, températures 20-30°C, plantes affaiblies',
    traitements: [
      TraitementEntity(
        id: 'trt_alt_001',
        nomProduit: 'Chlorothalonil 75 WP',
        dosage: '2 kg/ha',
        frequenceApplication: 'Tous les 7-10 jours',
        dureeDays: 21,
        type: TypeTraitement.chimique,
        coutFcfa: 5200,
        instructionsDetaillees:
            'Commencer les traitements dès la nouaison. Protéger surtout le bas de la plante.',
        precautions: 'Délai avant récolte : 7 jours. Alterner les matières actives.',
      ),
      TraitementEntity(
        id: 'trt_alt_002',
        nomProduit: 'Mancozèbe + Cuivre',
        dosage: '2 kg/ha + 1 kg/ha',
        frequenceApplication: 'Tous les 14 jours',
        dureeDays: 28,
        type: TypeTraitement.preventif,
        coutFcfa: 4000,
        instructionsDetaillees:
            'Association synergique pour une protection élargie. Appliquer en prévention.',
      ),
    ],
  ),
];
