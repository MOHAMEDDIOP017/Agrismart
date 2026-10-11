/// Constantes globales de l'application AgriSmart
class AppConstants {
  AppConstants._();

  static const String appName = 'AgriSmart';
  static const String appVersion = '1.0.0';

  // URL de base API (mock)
  static const String baseUrl = 'https://api.agrismart.sn/v1';

  // Clés SharedPreferences
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserData = 'user_data';

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

  /// Nom wolof des cultures du modèle de recommandation, par nom français.
  ///
  /// Source : `NOM_WOLOF_PAR_CODE` du backend (app/services/
  /// recommandation_service_v2.py), qui l'utilise pour les messages bilingues
  /// de l'agent conversationnel mais ne l'expose pas dans la réponse de
  /// l'API — d'où cette table côté client.
  ///
  /// Indexée sur le nom FRANÇAIS affiché, et non sur le code de classe du
  /// modèle : quand un expert corrige une recommandation, le nom change mais
  /// le code reste celui de la prédiction initiale. Une table indexée sur le
  /// code afficherait donc le nom wolof de la mauvaise culture.
  ///
  /// Limitée aux 8 cultures que le modèle sait prédire. Pour toute autre
  /// culture, la recherche ne renvoie rien et l'interface n'affiche aucun
  /// nom wolof, plutôt qu'une traduction approximative.
  static const Map<String, String> nomsWolofCultures = {
    'Arachide': 'gerte',
    'Maïs': 'mbóq',
    'Manioc': 'ñambi',
    'Mil': 'dugub',
    'Niébé': 'ñebbe',
    'Riz': 'ceeb',
    'Sorgho': 'bàkka',
    'Tomate': 'tamaate',
  };

  /// Nom wolof d'une culture, ou `null` si le modèle ne la connaît pas.
  ///
  /// Les écrans passent par cette recherche plutôt que d'indexer la table
  /// directement : l'absence de traduction est un cas normal, que l'interface
  /// traite en n'affichant rien plutôt qu'une approximation.
  static String? nomWolof(String nomFrancais) =>
      nomsWolofCultures[nomFrancais.trim()];

  // URLs images Unsplash (cultures)
  static const Map<String, String> imagesCultures = {
    'Mil': 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400',
    'Sorgho':
        'https://images.unsplash.com/photo-1601493700631-2b16ec4b4716?w=400',
    'Maïs': 'https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=400',
    'Arachide':
        'https://images.unsplash.com/photo-1567306226416-28f0efdc88ce?w=400',
    'Niébé':
        'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=400',
    'Sésame':
        'https://images.unsplash.com/photo-1607305387299-a3d9611cd469?w=400',
    'Tomate': 'https://images.unsplash.com/photo-1561155707-5c8ffa0ba8f1?w=400',
    'Oignon':
        'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=400',
    'Riz': 'https://images.unsplash.com/photo-1618197345682-e5b35f3f618b?w=400',
    'Manioc':
        'https://images.unsplash.com/photo-1597733336794-12d05021d510?w=400',
    'Coton':
        'https://images.unsplash.com/photo-1595435742645-c29e85f0d82a?w=400',
    'Igname':
        'https://images.unsplash.com/photo-1609501676725-7186f017a4b7?w=400',
  };
}
