import '../entities/assignation_entity.dart';
import '../entities/log_systeme_entity.dart';
import '../entities/statistiques_globales_entity.dart';
import '../entities/utilisateur_admin_entity.dart';
import '../enums/type_log.dart';
import '../../domain/enums/statut_utilisateur.dart';
import '../../../auth/domain/entities/user_entity.dart';

/// Contrat du repository pour le module Administrateur
abstract class AdminRepository {
  // ── Statistiques ─────────────────────────────────────────────────────────
  Future<StatistiquesGlobalesEntity> getStatistiquesGlobales(String periode);
  Future<StatutSysteme> getStatutSysteme();

  // ── Gestion utilisateurs ─────────────────────────────────────────────────
  Future<List<UtilisateurAdminEntity>> getUtilisateurs();
  Future<UtilisateurAdminEntity> getUtilisateur(String id);
  Future<UtilisateurAdminEntity> creerUtilisateur({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String motDePasse,
    required RoleUtilisateur role,
    required String region,
    String? ville,
    String? specialite,
    int? anneesExperience,
    int? niveauAcces,
  });
  Future<UtilisateurAdminEntity> modifierUtilisateur(UtilisateurAdminEntity utilisateur);
  Future<void> supprimerUtilisateur(String id);
  Future<UtilisateurAdminEntity> changerStatut(String id, StatutUtilisateur statut);
  Future<void> changerRole(String id, RoleUtilisateur role);

  // ── Assignation experts ───────────────────────────────────────────────────
  Future<List<AssignationEntity>> getAssignations();
  Future<List<ExpertDisponibleEntity>> getExpertsDisponibles({String? region});
  Future<AssignationEntity> creerAssignation({
    required String interventionId,
    required String expertId,
    required DateTime dateSouhaitee,
    String? messageExpert,
    bool notifierExpert = true,
  });
  Future<AssignationEntity> changerExpertAssigne({
    required String assignationId,
    required String nouvelExpertId,
  });
  Future<void> annulerAssignation(String assignationId);

  // ── Historique système ────────────────────────────────────────────────────
  Future<List<LogSystemeEntity>> getLogs({TypeLog? filtre, DateTimeRange? periode});
  Future<void> archiverLog(String logId);
  Future<String> exporterLogsCSV(List<LogSystemeEntity> logs);
}

/// Plage de dates pour filtrer les logs
class DateTimeRange {
  const DateTimeRange({required this.debut, required this.fin});
  final DateTime debut;
  final DateTime fin;
}
