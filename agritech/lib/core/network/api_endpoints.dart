abstract class ApiEndpoints {
  // Auth
  static const verifyToken = '/auth/verify-token';
  static const me = '/auth/me';

  // Champs
  static const champs = '/champs';
  static String champsAgriculteur(String id) => '/champs/agriculteur/$id';
  static String champById(String id) => '/champs/$id';
  static String champScoreSante(String id) => '/champs/$id/score-sante';

  // Recommandations v2 — moteur multi-label (16 variables, 8 cultures)
  static String genererRecommandationsV2(String champId) =>
      '/recommandations/v2/generer/$champId';
  static String recommandationsChampV2(String champId) =>
      '/recommandations/v2/champ/$champId';

  // Agent conversationnel IA (chat bilingue FR/Wolof)
  static const agentChat = '/agent/chat';

  // Météo
  static String meteoActuelle(String champId) => '/meteo/actuelle/$champId';
  static String meteoPrevisions(String champId) =>
      '/meteo/previsions/$champId';

  // Notifications
  static String notificationsUtilisateur(String id) =>
      '/notifications/utilisateur/$id';

  // Suivi cultures en champ
  static String culturesEnChamp(String champId) =>
      '/cultures-en-champ/champ/$champId';
  static const creerCultureEnChamp = '/cultures-en-champ/';
  static String statutCultureEnChamp(String cultureId) =>
      '/cultures-en-champ/$cultureId/statut';

  // Post-récolte
  static String postRecolte(String recommandationId) =>
      '/recommandations/$recommandationId/post-recolte';
  static String postRecolteParCulture(String cultureId) =>
      '/recommandations/post-recolte/culture/$cultureId';

  // Cultures (référentiel)
  static const cultures = '/cultures';
  static String cultureById(String id) => '/cultures/$id';

  // Cultures en champ
  static const culturesEnChampBase = '/cultures-en-champ';

  // Notifications — actions
  static String notificationById(String id) => '/notifications/$id';
  static String notificationMarquerLue(String id) =>
      '/notifications/$id/lue';
  static String notificationsToutesLues(String userId) =>
      '/notifications/utilisateur/$userId/tout-lire';

  // Historique activité
  static String historiqueUtilisateur(String userId) =>
      '/historique/utilisateur/$userId';
}
