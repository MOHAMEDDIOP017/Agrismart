abstract class ApiEndpoints {
  // Auth
  static const verifyToken = '/auth/verify-token';
  static const me = '/auth/me';

  // Champs
  static const champs = '/champs';
  static String champsAgriculteur(String id) => '/champs/agriculteur/$id';
  static String champById(String id) => '/champs/$id';
  static String champScoreSante(String id) => '/champs/$id/score-sante';

  // Recommandations
  static String genererRecommandations(String champId) =>
      '/recommandations/generer/$champId';
  static String recommandationsChamp(String champId) =>
      '/recommandations/champ/$champId';

  // Images
  static const uploadImage = '/images/upload';
  static String imageById(String id) => '/images/$id';
  static String imagesAgriculteur(String id) => '/images/agriculteur/$id';

  // Diagnostics
  static String analyserImage(String imageId) =>
      '/diagnostics/analyser/$imageId';
  static String diagnosticsAgriculteur(String id) =>
      '/diagnostics/agriculteur/$id';

  // Météo
  static String meteoActuelle(String champId) => '/meteo/actuelle/$champId';
  static String meteoPrevisions(String champId) =>
      '/meteo/previsions/$champId';

  // Notifications
  static String notificationsUtilisateur(String id) =>
      '/notifications/utilisateur/$id';
}
