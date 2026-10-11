import '../features/auth/domain/entities/user_entity.dart';
import 'admin_router.dart';
import 'app_router.dart';
import 'expert_router.dart';

/// Traduit une notification en écran à ouvrir.
///
/// L'audit avait trouvé que `FcmService` écrivait le titre du message dans la
/// console et s'arrêtait là : ni `getInitialMessage`, ni `onMessageOpenedApp`.
/// Ouvrir une notification ramenait donc à l'écran courant, et la personne
/// devait retrouver seule ce dont on venait de l'avertir.
///
/// Le serveur envoie quatre valeurs dans la charge utile, visibles dans
/// `notification_service.py` : `type`, `referenceId`, `urgent` et `notifId`.
///
/// Le `notifId` sert pour l'agriculteur, et c'est voulu : sa liste d'alertes
/// est construite à partir des notifications elles-mêmes, par
/// `AlerteModel.fromNotificationJson`. L'identifiant de l'alerte est donc
/// celui de la notification, là où `referenceId` désigne la ressource
/// d'origine, un conseil ou une intervention, qui n'a pas d'écran propre côté
/// agriculteur.
///
/// Fonction pure, sans dépendance à Flutter : elle se teste sans construire
/// d'interface, et c'est la partie où une erreur enverrait quelqu'un sur le
/// mauvais écran.
String? routeNotification(
  Map<String, String> donnees,
  RoleUtilisateur? role,
) {
  if (role == null) return null;

  final type = (donnees['type'] ?? '').toUpperCase();
  final reference = _nonVide(donnees['referenceId']);
  final notif = _nonVide(donnees['notifId']);

  switch (role) {
    case RoleUtilisateur.agriculteur:
      return _pourAgriculteur(type, notif);
    case RoleUtilisateur.expert:
      return _pourExpert(type, reference);
    case RoleUtilisateur.admin:
      // L'administrateur ne reçoit aucun de ces types. Le ramener à son
      // accueil vaut mieux que de le laisser sur l'écran courant sans
      // explication.
      return AdminRoutes.adminDashboard;
  }
}

String _pourAgriculteur(String type, String? notifId) {
  switch (type) {
    case 'RECOMMANDATION':
      // Les recommandations ne s'ouvrent pas une par une côté agriculteur :
      // l'écran présente le classement complet, qui est l'unité de lecture.
      return AppRoutes.recommandations;

    case 'CONSEIL_EXPERT':
    case 'INTERVENTION_PLANIFIEE':
    case 'ALERTE':
    default:
      if (notifId == null) return AppRoutes.alertes;
      return '${AppRoutes.alertes}/$notifId';
  }
}

String _pourExpert(String type, String? referenceId) {
  switch (type) {
    case 'RECOMMANDATION':
      if (referenceId == null) return ExpertRoutes.expertRecommandations;
      return '${ExpertRoutes.expertRecommandations}/$referenceId';

    case 'CONSEIL_EXPERT':
      return ExpertRoutes.expertConseils;

    case 'INTERVENTION_PLANIFIEE':
      return ExpertRoutes.expertChamps;

    default:
      return ExpertRoutes.expertRecommandations;
  }
}

/// Le serveur envoie une chaîne vide plutôt qu'une absence quand la référence
/// n'existe pas : `"referenceId": reference_id or ""`.
String? _nonVide(String? valeur) {
  if (valeur == null) return null;
  final propre = valeur.trim();
  return propre.isEmpty ? null : propre;
}
