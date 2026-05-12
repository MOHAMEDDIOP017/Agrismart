/// Noms de routes nommées du module Expert
class ExpertRoutes {
  // Shell Expert (chemins)
  static const expertHome = '/expert';
  static const expertDashboard = '/expert/dashboard';
  static const expertDiagnostics = '/expert/diagnostics';
  static const expertDiagnosticDetail = '/expert/diagnostics/:id';
  static const expertChamps = '/expert/champs';
  static const expertChampDashboard = '/expert/champs/:id';
  static const expertConseils = '/expert/conseils';
  static const expertProfil = '/expert/profil';

  // Routes hors shell Expert (plein écran)
  static const expertNouveauConseil = '/expert/conseils/nouveau';
  static const expertAlertes = '/expert/alertes';
  static const expertRapport = '/expert/rapport';
  static const expertPlanifierIntervention = '/expert/intervention/planifier';
  static const expertHistoriqueChamp = '/expert/champs/:id/historique';

  // Noms de routes (pour goNamed)
  static const dashboardNom = 'expert-dashboard';
  static const diagnosticsNom = 'expert-diagnostics';
  static const diagnosticDetailNom = 'expert-diagnostic-detail';
  static const champsNom = 'expert-champs';
  static const champDashboardNom = 'expert-champ-dashboard';
  static const conseilsNom = 'expert-conseils';
  static const nouveauConseilNom = 'expert-nouveau-conseil';
  static const profilNom = 'expert-profil';
  static const alertesNom = 'expert-alertes';
  static const rapportNom = 'expert-rapport';
  static const planifierInterventionNom = 'expert-planifier-intervention';
  static const historiqueChampNom = 'expert-historique-champ';
}
