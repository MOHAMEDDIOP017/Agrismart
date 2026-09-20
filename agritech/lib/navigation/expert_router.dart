/// Noms de routes nommées du module Expert
class ExpertRoutes {
  // Shell Expert (chemins)
  static const expertHome = '/expert';
  static const expertDashboard = '/expert/dashboard';
  static const expertChamps = '/expert/champs';
  static const expertChampDashboard = '/expert/champs/:id';
  static const expertConseils = '/expert/conseils';
  static const expertProfil = '/expert/profil';

  // Routes hors shell Expert (plein écran)
  static const expertNouveauConseil = '/expert/conseils/nouveau';
  static const expertRapport = '/expert/rapport';
  static const expertPlanifierIntervention = '/expert/intervention/planifier';
  static const expertHistoriqueChamp = '/expert/champs/:id/historique';

  // Recommandations cultures (boucle de validation)
  static const expertRecommandations = '/expert/recommandations';
  static const expertRecommandationDetail = '/expert/recommandations/:id';

  // Noms de routes (pour goNamed)
  static const dashboardNom = 'expert-dashboard';
  static const champsNom = 'expert-champs';
  static const champDashboardNom = 'expert-champ-dashboard';
  static const conseilsNom = 'expert-conseils';
  static const nouveauConseilNom = 'expert-nouveau-conseil';
  static const profilNom = 'expert-profil';
  static const rapportNom = 'expert-rapport';
  static const planifierInterventionNom = 'expert-planifier-intervention';
  static const historiqueChampNom = 'expert-historique-champ';
  static const recommandationsNom = 'expert-recommandations';
  static const recommandationDetailNom = 'expert-recommandation-detail';
}
