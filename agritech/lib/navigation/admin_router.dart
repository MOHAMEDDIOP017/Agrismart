/// Chemins et noms des routes du module Administrateur
class AdminRoutes {
  // Shell Admin
  static const adminHome = '/admin';
  static const adminDashboard = '/admin/dashboard';
  static const adminUtilisateurs = '/admin/utilisateurs';
  static const adminAssignation = '/admin/assignation';
  static const adminStatistiques = '/admin/statistiques';

  // Routes plein écran hors shell
  static const adminHistorique = '/admin/historique';
  static const adminProfil = '/admin/profil';
  static const adminCreerUser = '/admin/utilisateurs/creer';
  static const adminModifierUser = '/admin/utilisateurs/:userId/modifier';
  static const adminNouvelleAssignation = '/admin/assignation/nouvelle';

  // Routes champs admin (plein écran)
  static const adminChamps = '/admin/champs';
  static const adminCreerChamp = '/admin/champs/creer';

  // Noms (pour goNamed)
  static const dashboardNom = 'adminDashboard';
  static const utilisateursNom = 'gestionUtilisateurs';
  static const assignationNom = 'assignationExperts';
  static const statistiquesNom = 'statistiques';
  static const historiqueNom = 'historiqueSysteme';
  static const profilNom = 'profilAdmin';
  static const creerUserNom = 'creerUser';
  static const modifierUserNom = 'modifierUser';
  static const nouvelleAssignationNom = 'nouvelleAssignation';
  static const champsNom = 'gestionChamps';
  static const creerChampNom = 'creerChampAdmin';
}
