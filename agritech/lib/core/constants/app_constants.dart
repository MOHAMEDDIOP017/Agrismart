/// Constantes globales de l'application KoobalaTech
class AppConstants {
  AppConstants._();

  static const String appName = 'KoobalaTech';
  static const String appVersion = '1.0.0';

  // URL de base API (mock)
  static const String baseUrl = 'https://api.koobalatec.sn/v1';

  // Clés SharedPreferences
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserData = 'user_data';

  // Durées d'animation
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 400);
  static const Duration animSlow = Duration(milliseconds: 600);
  static const Duration animStagger = Duration(milliseconds: 100);

  // Villes du Sénégal
  static const List<String> villesSenegal = [
    'Dakar',
    'Thiès',
    'Kaolack',
    'Ziguinchor',
    'Saint-Louis',
    'Tambacounda',
    'Diourbel',
    'Fatick',
    'Kolda',
    'Matam',
    'Louga',
    'Sédhiou',
    'Kédougou',
    'Kaffrine',
  ];

  // Types de sol
  static const List<String> typesSol = [
    'Latéritique',
    'Sableux',
    'Argileux',
    'Limoneux',
    'Argilo-sableux',
  ];

  // Cultures disponibles
  static const List<String> cultures = [
    'Mil',
    'Sorgho',
    'Maïs',
    'Arachide',
    'Niébé',
    'Sésame',
    'Coton',
    'Manioc',
    'Igname',
    'Tomate',
    'Oignon',
    'Riz',
  ];

  // Niveaux d'alerte
  static const String alerteCritique = 'CRITIQUE';
  static const String alerteEleve = 'ÉLEVÉ';
  static const String alerteModere = 'MODÉRÉ';
  static const String alerteFaible = 'FAIBLE';

  // Statuts champs
  static const String statutPrevu = 'PRÉVU';
  static const String statutEnCours = 'EN_COURS';
  static const String statutRecolte = 'RÉCOLTE';
  static const String statutEnTraitement = 'EN_TRAITEMENT';
  static const String statutAbandonne = 'ABANDONNÉ';

  // URLs images Unsplash (cultures)
  static const Map<String, String> imagesCultures = {
    'Mil': 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400',
    'Sorgho': 'https://images.unsplash.com/photo-1601493700631-2b16ec4b4716?w=400',
    'Maïs': 'https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=400',
    'Arachide': 'https://images.unsplash.com/photo-1567306226416-28f0efdc88ce?w=400',
    'Niébé': 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=400',
    'Sésame': 'https://images.unsplash.com/photo-1607305387299-a3d9611cd469?w=400',
    'Tomate': 'https://images.unsplash.com/photo-1561155707-5c8ffa0ba8f1?w=400',
    'Oignon': 'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=400',
    'Riz': 'https://images.unsplash.com/photo-1618197345682-e5b35f3f618b?w=400',
    'Manioc': 'https://images.unsplash.com/photo-1597733336794-12d05021d510?w=400',
    'Coton': 'https://images.unsplash.com/photo-1595435742645-c29e85f0d82a?w=400',
    'Igname': 'https://images.unsplash.com/photo-1609501676725-7186f017a4b7?w=400',
  };
}
