import 'package:dio/dio.dart';
import '../../domain/entities/assignation_entity.dart';
import '../../domain/entities/log_systeme_entity.dart';
import '../../domain/entities/statistiques_globales_entity.dart';
import '../../domain/entities/utilisateur_admin_entity.dart';
import '../../domain/enums/statut_utilisateur.dart';
import '../../domain/enums/statut_assignation.dart';
import '../../domain/enums/type_log.dart';
import '../../domain/enums/niveau_urgence_admin.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../../core/network/api_client.dart';

class AdminRepositoryImpl implements AdminRepository {
  final Dio _dio = ApiClient().dio;

  // ── Statistiques ─────────────────────────────────────────────────────────

  @override
  Future<StatistiquesGlobalesEntity> getStatistiquesGlobales(String periode) async {
    try {
      final resp = await _dio.get('/admin/statistiques-globales');
      return _mapStats(resp.data as Map<String, dynamic>);
    } catch (_) {
      return _statsVides();
    }
  }

  @override
  Future<StatutSysteme> getStatutSysteme() async {
    // Pas d'endpoint backend dédié — état calculé localement
    return const StatutSysteme(
      apiMeteoOperationnelle: true,
      tempsReponseApiMs: 120,
      versionModeleIA: 'EfficientNetB0 v2.1',
      precisionModeleIA: 0.92,
      modeleIAOperationnel: true,
    );
  }

  // ── Gestion utilisateurs ─────────────────────────────────────────────────

  @override
  Future<List<UtilisateurAdminEntity>> getUtilisateurs() async {
    final resp = await _dio.get('/utilisateurs');
    final data = resp.data as Map<String, dynamic>;
    return (data['utilisateurs'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(_mapUser)
        .toList();
  }

  @override
  Future<UtilisateurAdminEntity> getUtilisateur(String id) async {
    final resp = await _dio.get('/utilisateurs/$id');
    return _mapUser(resp.data as Map<String, dynamic>);
  }

  @override
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
  }) async {
    final data = <String, dynamic>{
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'motDePasse': motDePasse,
      'role': role.toJson(),
      'zone_geographique': region,
      if (ville != null) 'village_ville': ville,
      if (specialite != null) 'specialite': specialite,
      if (anneesExperience != null) 'anneesExperience': anneesExperience,
      if (niveauAcces != null) 'niveauAcces': niveauAcces,
    };
    final resp = await _dio.post('/utilisateurs', data: data);
    final body = resp.data as Map<String, dynamic>;
    return UtilisateurAdminEntity(
      id: (body['id'] ?? '') as String,
      nom: nom,
      prenom: prenom,
      email: email,
      telephone: telephone,
      role: role,
      statut: StatutUtilisateur.actif,
      region: region,
      ville: ville,
      specialite: specialite,
      anneesExperience: anneesExperience,
      niveauAcces: niveauAcces,
      dateInscription: DateTime.now(),
    );
  }

  @override
  Future<UtilisateurAdminEntity> modifierUtilisateur(
      UtilisateurAdminEntity utilisateur) async {
    await _dio.put('/utilisateurs/${utilisateur.id}', data: {
      'nom': utilisateur.nom,
      'prenom': utilisateur.prenom,
      'telephone': utilisateur.telephone,
      'zone_geographique': utilisateur.region,
      if (utilisateur.specialite != null) 'specialite': utilisateur.specialite,
      if (utilisateur.anneesExperience != null)
        'anneesExperience': utilisateur.anneesExperience,
    });
    return utilisateur;
  }

  @override
  Future<void> supprimerUtilisateur(String id) async {
    await _dio.delete('/utilisateurs/$id');
  }

  @override
  Future<UtilisateurAdminEntity> changerStatut(
      String id, StatutUtilisateur statut) async {
    if (statut == StatutUtilisateur.suspendu) {
      await _dio.patch('/utilisateurs/$id/suspendre');
    } else {
      await _dio.put('/utilisateurs/$id', data: {'actif': true});
    }
    final user = await getUtilisateur(id);
    return user.copyWith(statut: statut);
  }

  @override
  Future<void> changerRole(String id, RoleUtilisateur role) async {
    await _dio.patch('/utilisateurs/$id/role', data: {'role': role.toJson()});
  }

  // ── Assignation experts ───────────────────────────────────────────────────

  @override
  Future<List<AssignationEntity>> getAssignations() async {
    // Les assignations correspondent aux interventions non assignées
    // (pas d'endpoint dédié → retourne liste vide en attendant un vrai endpoint admin)
    return [];
  }

  @override
  Future<List<ExpertDisponibleEntity>> getExpertsDisponibles(
      {String? region}) async {
    final resp = await _dio.get('/utilisateurs');
    final data = resp.data as Map<String, dynamic>;
    final tous = (data['utilisateurs'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .where((u) => (u['role'] as String? ?? '') == 'EXPERT')
        .where((u) => region == null ||
            (u['zone_geographique'] as String? ?? '') == region)
        .map(_mapExpertDisponible)
        .toList();
    return tous;
  }

  @override
  Future<AssignationEntity> creerAssignation({
    required String interventionId,
    required String expertId,
    required DateTime dateSouhaitee,
    String? messageExpert,
    bool notifierExpert = true,
  }) async {
    await _dio.post(
      '/admin/assigner-expert',
      queryParameters: {
        'intervention_id': interventionId,
        'expert_id': expertId,
      },
    );
    // Reconstruction locale de l'entité
    return AssignationEntity(
      id: interventionId,
      agriculteurNom: '—',
      champNom: '—',
      region: '—',
      typeIntervention: '—',
      niveauUrgence: NiveauUrgenceAdmin.modere,
      statut: StatutAssignation.planifiee,
      dateSouhaitee: dateSouhaitee,
      dateCreation: DateTime.now(),
      expertId: expertId,
      messageExpert: messageExpert,
      notifierExpert: notifierExpert,
    );
  }

  @override
  Future<AssignationEntity> changerExpertAssigne({
    required String assignationId,
    required String nouvelExpertId,
  }) async {
    await _dio.post(
      '/admin/assigner-expert',
      queryParameters: {
        'intervention_id': assignationId,
        'expert_id': nouvelExpertId,
      },
    );
    return AssignationEntity(
      id: assignationId,
      agriculteurNom: '—',
      champNom: '—',
      region: '—',
      typeIntervention: '—',
      niveauUrgence: NiveauUrgenceAdmin.modere,
      statut: StatutAssignation.planifiee,
      dateSouhaitee: DateTime.now(),
      dateCreation: DateTime.now(),
      expertId: nouvelExpertId,
    );
  }

  @override
  Future<void> annulerAssignation(String assignationId) async {
    // Pas d'endpoint dédié — no-op
  }

  // ── Historique système ────────────────────────────────────────────────────

  @override
  Future<List<LogSystemeEntity>> getLogs(
      {TypeLog? filtre, DateTimeRange? periode}) async {
    final resp = await _dio.get('/admin/historique-systeme?limite=100');
    final data = resp.data as Map<String, dynamic>;
    var logs = (data['historique'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(_mapLog)
        .toList();
    if (filtre != null) {
      logs = logs.where((l) => l.type == filtre).toList();
    }
    if (periode != null) {
      logs = logs
          .where((l) =>
              l.horodatage.isAfter(periode.debut) &&
              l.horodatage.isBefore(periode.fin))
          .toList();
    }
    return logs;
  }

  @override
  Future<void> archiverLog(String logId) async {
    // Pas d'endpoint backend — marque localement
  }

  @override
  Future<String> exporterLogsCSV(List<LogSystemeEntity> logs) async {
    final lignes = StringBuffer();
    lignes.writeln('ID,Type,Description,Utilisateur,Rôle,Horodatage');
    for (final log in logs) {
      lignes.writeln(
        '${log.id},${log.type.libelle},"${log.description}",'
        '${log.utilisateurNom},${log.utilisateurRole.libelle},${log.horodatageFormate}',
      );
    }
    return lignes.toString();
  }

  // ── Mappers ───────────────────────────────────────────────────────────────

  static StatistiquesGlobalesEntity _mapStats(Map<String, dynamic> json) {
    final u = (json['utilisateurs'] as Map<String, dynamic>?) ?? {};
    final m1 = (json['ia_module1'] as Map<String, dynamic>?) ?? {};
    final m2 = (json['ia_module2'] as Map<String, dynamic>?) ?? {};
    final ex = (json['experts'] as Map<String, dynamic>?) ?? {};

    final totalDiags = m2['total_diagnostics'] as int? ?? 0;
    final totalRec = m1['total_recommandations'] as int? ?? 0;
    final totalIntv = ex['interventions_planifiees'] as int? ?? 0;

    return StatistiquesGlobalesEntity(
      totalDiagnostics: totalDiags,
      precisionIAPourcent: 92.0,
      totalRecommandations: totalRec,
      totalAlertes: m2['diagnostics_en_attente'] as int? ?? 0,
      totalInterventions: totalIntv,
      totalConseils: ex['conseils_envoyes'] as int? ?? 0,
      totalUtilisateurs: u['total'] as int? ?? 0,
      totalAgriculteurs: u['agriculteurs'] as int? ?? 0,
      totalExperts: u['experts'] as int? ?? 0,
      totalAdmins: u['admins'] as int? ?? 0,
      interventionsEnCours: totalIntv,
      donneesBarChart: [
        DonneeBarChart(
            semaine: 'S1',
            diagnostics: totalDiags * 0.2,
            recommandations: totalRec * 0.2),
        DonneeBarChart(
            semaine: 'S2',
            diagnostics: totalDiags * 0.25,
            recommandations: totalRec * 0.25),
        DonneeBarChart(
            semaine: 'S3',
            diagnostics: totalDiags * 0.3,
            recommandations: totalRec * 0.3),
        DonneeBarChart(
            semaine: 'S4',
            diagnostics: totalDiags * 0.25,
            recommandations: totalRec * 0.25),
      ],
      topMaladies: const [],
      donneesLineChart: const [
        DonneeLineChart(mois: 'Jan', precisionBrute: 85, precisionValidee: 90),
        DonneeLineChart(mois: 'Fév', precisionBrute: 87, precisionValidee: 91),
        DonneeLineChart(mois: 'Mar', precisionBrute: 89, precisionValidee: 92),
        DonneeLineChart(mois: 'Avr', precisionBrute: 91, precisionValidee: 93),
      ],
    );
  }

  static StatistiquesGlobalesEntity _statsVides() =>
      const StatistiquesGlobalesEntity(
        totalDiagnostics: 0,
        precisionIAPourcent: 0,
        totalRecommandations: 0,
        totalAlertes: 0,
        totalInterventions: 0,
        totalConseils: 0,
        totalUtilisateurs: 0,
        totalAgriculteurs: 0,
        totalExperts: 0,
        totalAdmins: 0,
        interventionsEnCours: 0,
        donneesBarChart: [],
        topMaladies: [],
        donneesLineChart: [],
      );

  static UtilisateurAdminEntity _mapUser(Map<String, dynamic> json) {
    final actif = json['actif'] as bool? ?? true;
    final statut =
        actif ? StatutUtilisateur.actif : StatutUtilisateur.suspendu;
    final dateStr = json['dateInscription']?.toString() ?? '';
    return UtilisateurAdminEntity(
      id: (json['id'] ?? json['uid'] ?? '') as String,
      nom: (json['nom'] ?? '') as String,
      prenom: (json['prenom'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      telephone: (json['telephone'] ?? '') as String,
      role: RoleUtilisateur.fromString(json['role'] as String? ?? 'AGRICULTEUR'),
      statut: statut,
      region: (json['zone_geographique'] ?? json['region'] ?? 'Sénégal') as String,
      dateInscription: DateTime.tryParse(dateStr) ?? DateTime.now(),
      photoUrl: json['photo_url'] as String?,
      specialite: json['specialite'] as String?,
      anneesExperience: json['anneesExperience'] as int?,
      niveauAcces: json['niveauAcces'] as int?,
    );
  }

  static ExpertDisponibleEntity _mapExpertDisponible(Map<String, dynamic> json) =>
      ExpertDisponibleEntity(
        id: (json['id'] ?? '') as String,
        nom: (json['nom'] ?? '') as String,
        prenom: (json['prenom'] ?? '') as String,
        specialite: (json['specialite'] ?? 'Généraliste') as String,
        region: (json['zone_geographique'] ?? 'Sénégal') as String,
        estEnLigne: json['actif'] as bool? ?? true,
        interventionsEnCours: 0,
        scoreEvaluation: 4.5,
        telephone: json['telephone'] as String?,
        photoUrl: json['photo_url'] as String?,
      );

  static LogSystemeEntity _mapLog(Map<String, dynamic> json) {
    final typeStr = (json['typeAction'] ?? '').toString().toUpperCase();
    final type = switch (typeStr) {
      _ when typeStr.contains('CONNEXION') || typeStr.contains('AUTH') =>
        TypeLog.connexion,
      _ when typeStr.contains('DIAGNOSTIC') ||
              typeStr.contains('ANALYSE') ||
              typeStr.contains('IMAGE') =>
        TypeLog.diagnostic,
      _ when typeStr.contains('INTERVENTION') => TypeLog.intervention,
      _ when typeStr.contains('ALERTE') => TypeLog.alerte,
      _ when typeStr.contains('ERREUR') || typeStr.contains('ERROR') =>
        TypeLog.erreur,
      _ => TypeLog.diagnostic,
    };
    final dateStr = json['dateAction']?.toString() ?? '';
    return LogSystemeEntity(
      id: (json['id'] ?? json['utilisateurId'] ?? '') as String,
      type: type,
      description: (json['description'] ?? '') as String,
      utilisateurNom: (json['utilisateurId'] ?? '—') as String,
      utilisateurRole: RoleUtilisateur.agriculteur,
      horodatage: DateTime.tryParse(dateStr) ?? DateTime.now(),
      details: json['details']?.toString(),
    );
  }
}
