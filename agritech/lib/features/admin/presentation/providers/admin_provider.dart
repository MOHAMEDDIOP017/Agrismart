import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/entities/assignation_entity.dart';
import '../../domain/entities/log_systeme_entity.dart';
import '../../domain/entities/statistiques_globales_entity.dart';
import '../../domain/entities/utilisateur_admin_entity.dart';
import '../../domain/enums/statut_assignation.dart';
import '../../domain/enums/statut_utilisateur.dart';
import '../../domain/enums/type_log.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../champs/data/models/champ_model.dart';
import '../../../champs/domain/entities/champ_entity.dart';
import '../../../../core/network/api_client.dart';
// ── Repository provider ───────────────────────────────────────────────────

final adminRepositoryProvider = Provider<AdminRepository>(
  (_) => AdminRepositoryImpl(),
);

// ── Profil Admin connecté ─────────────────────────────────────────────────

final adminConnecteProvider = Provider<UtilisateurAdminEntity?>((ref) {
  final auth = ref.watch(authProvider).valueOrNull?.user;
  if (auth == null) return null;
  return UtilisateurAdminEntity(
    id: auth.id,
    nom: auth.nom,
    prenom: auth.prenom,
    email: auth.email,
    telephone: auth.telephone,
    role: auth.role,
    statut: StatutUtilisateur.actif,
    region: auth.zoneGeographique,
    dateInscription: DateTime.now(),
    photoUrl: auth.photoUrl,
  );
});

// ── Statistiques globales ─────────────────────────────────────────────────

/// Période sélectionnée pour les statistiques
enum PeriodeStatistiques { aujourdhui, semaine, mois, annee }

extension PeriodeStatistiquesExt on PeriodeStatistiques {
  String get libelle {
    switch (this) {
      case PeriodeStatistiques.aujourdhui:
        return "Aujourd'hui";
      case PeriodeStatistiques.semaine:
        return 'Cette semaine';
      case PeriodeStatistiques.mois:
        return 'Ce mois';
      case PeriodeStatistiques.annee:
        return 'Cette année';
    }
  }

  String get valeur {
    switch (this) {
      case PeriodeStatistiques.aujourdhui:
        return 'jour';
      case PeriodeStatistiques.semaine:
        return 'semaine';
      case PeriodeStatistiques.mois:
        return 'mois';
      case PeriodeStatistiques.annee:
        return 'annee';
    }
  }
}

class StatistiquesState {
  const StatistiquesState({
    required this.statistiques,
    this.periode = PeriodeStatistiques.mois,
  });

  final StatistiquesGlobalesEntity statistiques;
  final PeriodeStatistiques periode;

  StatistiquesState copyWith({
    StatistiquesGlobalesEntity? statistiques,
    PeriodeStatistiques? periode,
  }) =>
      StatistiquesState(
        statistiques: statistiques ?? this.statistiques,
        periode: periode ?? this.periode,
      );
}

class StatistiquesNotifier extends AsyncNotifier<StatistiquesState> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  Future<StatistiquesState> build() async {
    final stats = await _repo.getStatistiquesGlobales('mois');
    return StatistiquesState(statistiques: stats);
  }

  Future<void> changerPeriode(PeriodeStatistiques periode) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(periode: periode));
    // Recharger les stats pour la nouvelle période
    final stats = await _repo.getStatistiquesGlobales(periode.valeur);
    state = AsyncData(current.copyWith(statistiques: stats, periode: periode));
  }

  Future<void> rafraichir() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final stats = await _repo.getStatistiquesGlobales('mois');
      return StatistiquesState(statistiques: stats);
    });
  }
}

final statistiquesProvider =
    AsyncNotifierProvider<StatistiquesNotifier, StatistiquesState>(
  StatistiquesNotifier.new,
);

// ── Statut du système ─────────────────────────────────────────────────────

final statutSystemeProvider = FutureProvider<StatutSysteme>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getStatutSysteme();
});

// ── Gestion utilisateurs ──────────────────────────────────────────────────

/// Filtres disponibles pour la liste des utilisateurs
enum FiltreUtilisateur { tous, agriculteurs, experts, admins, suspendus, actifs }

extension FiltreUtilisateurExt on FiltreUtilisateur {
  String get libelle {
    switch (this) {
      case FiltreUtilisateur.tous:
        return 'Tous';
      case FiltreUtilisateur.agriculteurs:
        return 'Agriculteurs';
      case FiltreUtilisateur.experts:
        return 'Experts';
      case FiltreUtilisateur.admins:
        return 'Admins';
      case FiltreUtilisateur.suspendus:
        return 'Suspendus';
      case FiltreUtilisateur.actifs:
        return 'Actifs';
    }
  }
}

class GestionUtilisateursState {
  const GestionUtilisateursState({
    this.utilisateurs = const [],
    this.filtre = FiltreUtilisateur.tous,
    this.recherche = '',
  });

  final List<UtilisateurAdminEntity> utilisateurs;
  final FiltreUtilisateur filtre;
  final String recherche;

  GestionUtilisateursState copyWith({
    List<UtilisateurAdminEntity>? utilisateurs,
    FiltreUtilisateur? filtre,
    String? recherche,
  }) =>
      GestionUtilisateursState(
        utilisateurs: utilisateurs ?? this.utilisateurs,
        filtre: filtre ?? this.filtre,
        recherche: recherche ?? this.recherche,
      );

  List<UtilisateurAdminEntity> get filtres {
    List<UtilisateurAdminEntity> liste = List.from(utilisateurs);

    // Appliquer le filtre par rôle/statut
    switch (filtre) {
      case FiltreUtilisateur.agriculteurs:
        liste = liste.where((u) => u.role == RoleUtilisateur.agriculteur).toList();
      case FiltreUtilisateur.experts:
        liste = liste.where((u) => u.role == RoleUtilisateur.expert).toList();
      case FiltreUtilisateur.admins:
        liste = liste.where((u) => u.role == RoleUtilisateur.admin).toList();
      case FiltreUtilisateur.suspendus:
        liste = liste
            .where((u) => u.statut == StatutUtilisateur.suspendu)
            .toList();
      case FiltreUtilisateur.actifs:
        liste = liste
            .where((u) => u.statut == StatutUtilisateur.actif)
            .toList();
      case FiltreUtilisateur.tous:
        break;
    }

    // Appliquer la recherche textuelle
    if (recherche.isNotEmpty) {
      final q = recherche.toLowerCase();
      liste = liste
          .where((u) =>
              u.nomComplet.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.telephone.contains(q) ||
              u.region.toLowerCase().contains(q))
          .toList();
    }

    return liste;
  }
}

class GestionUtilisateursNotifier
    extends AsyncNotifier<GestionUtilisateursState> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  Future<GestionUtilisateursState> build() async {
    final utilisateurs = await _repo.getUtilisateurs();
    return GestionUtilisateursState(utilisateurs: utilisateurs);
  }

  Future<void> rafraichir() async {
    final current = state.valueOrNull;
    final utilisateurs = await _repo.getUtilisateurs();
    state = AsyncData(
      (current ?? const GestionUtilisateursState()).copyWith(
        utilisateurs: utilisateurs,
      ),
    );
  }

  void setFiltre(FiltreUtilisateur filtre) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(filtre: filtre));
  }

  void setRecherche(String recherche) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(recherche: recherche));
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> creerUtilisateur({
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
    try {
      final nouvel = await _repo.creerUtilisateur(
        nom: nom,
        prenom: prenom,
        email: email,
        telephone: telephone,
        motDePasse: motDePasse,
        role: role,
        region: region,
        ville: ville,
        specialite: specialite,
        anneesExperience: anneesExperience,
        niveauAcces: niveauAcces,
      );
      final current = state.valueOrNull ?? const GestionUtilisateursState();
      state = AsyncData(current.copyWith(
        utilisateurs: [nouvel, ...current.utilisateurs],
      ));
      return null;
    } on DioException catch (e) {
      return e.error?.toString() ?? e.message ?? 'Erreur réseau. Vérifiez votre connexion.';
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> modifierUtilisateur(UtilisateurAdminEntity utilisateur) async {
    try {
      final mis = await _repo.modifierUtilisateur(utilisateur);
      final current = state.valueOrNull ?? const GestionUtilisateursState();
      state = AsyncData(current.copyWith(
        utilisateurs: current.utilisateurs
            .map((u) => u.id == mis.id ? mis : u)
            .toList(),
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> supprimerUtilisateur(String id) async {
    try {
      await _repo.supprimerUtilisateur(id);
      final current = state.valueOrNull ?? const GestionUtilisateursState();
      state = AsyncData(current.copyWith(
        utilisateurs: current.utilisateurs.where((u) => u.id != id).toList(),
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changerStatut(String id, StatutUtilisateur statut) async {
    try {
      final mis = await _repo.changerStatut(id, statut);
      final current = state.valueOrNull ?? const GestionUtilisateursState();
      state = AsyncData(current.copyWith(
        utilisateurs: current.utilisateurs
            .map((u) => u.id == mis.id ? mis : u)
            .toList(),
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changerRole(String id, RoleUtilisateur role) async {
    try {
      await _repo.changerRole(id, role);
      final current = state.valueOrNull ?? const GestionUtilisateursState();
      state = AsyncData(current.copyWith(
        utilisateurs: current.utilisateurs
            .map((u) => u.id == id ? u.copyWith(role: role) : u)
            .toList(),
      ));
      return true;
    } catch (_) {
      return false;
    }
  }
}

final gestionUtilisateursProvider =
    AsyncNotifierProvider<GestionUtilisateursNotifier, GestionUtilisateursState>(
  GestionUtilisateursNotifier.new,
);

/// Utilisateur unique par ID (pour l'écran de modification)
final utilisateurDetailProvider =
    FutureProvider.family<UtilisateurAdminEntity, String>((ref, id) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getUtilisateur(id);
});

// ── Assignation experts ───────────────────────────────────────────────────

enum FiltreAssignation { enAttente, assignees }

class AssignationState {
  const AssignationState({
    this.assignations = const [],
    this.filtre = FiltreAssignation.enAttente,
  });

  final List<AssignationEntity> assignations;
  final FiltreAssignation filtre;

  AssignationState copyWith({
    List<AssignationEntity>? assignations,
    FiltreAssignation? filtre,
  }) =>
      AssignationState(
        assignations: assignations ?? this.assignations,
        filtre: filtre ?? this.filtre,
      );

  List<AssignationEntity> get filtrees {
    switch (filtre) {
      case FiltreAssignation.enAttente:
        return assignations
            .where((a) => a.statut == StatutAssignation.nonAssignee)
            .toList();
      case FiltreAssignation.assignees:
        return assignations
            .where((a) => a.statut != StatutAssignation.nonAssignee)
            .toList();
    }
  }
}

class AssignationNotifier extends AsyncNotifier<AssignationState> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  Future<AssignationState> build() async {
    final assignations = await _repo.getAssignations();
    return AssignationState(assignations: assignations);
  }

  void setFiltre(FiltreAssignation filtre) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(filtre: filtre));
  }

  Future<bool> creerAssignation({
    required String interventionId,
    required String expertId,
    required DateTime dateSouhaitee,
    String? messageExpert,
    bool notifierExpert = true,
  }) async {
    try {
      final mise = await _repo.creerAssignation(
        interventionId: interventionId,
        expertId: expertId,
        dateSouhaitee: dateSouhaitee,
        messageExpert: messageExpert,
        notifierExpert: notifierExpert,
      );
      final current = state.valueOrNull ?? const AssignationState();
      state = AsyncData(current.copyWith(
        assignations: current.assignations
            .map((a) => a.id == mise.id ? mise : a)
            .toList(),
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changerExpert({
    required String assignationId,
    required String nouvelExpertId,
  }) async {
    try {
      final mise = await _repo.changerExpertAssigne(
        assignationId: assignationId,
        nouvelExpertId: nouvelExpertId,
      );
      final current = state.valueOrNull ?? const AssignationState();
      state = AsyncData(current.copyWith(
        assignations: current.assignations
            .map((a) => a.id == mise.id ? mise : a)
            .toList(),
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> annuler(String assignationId) async {
    try {
      await _repo.annulerAssignation(assignationId);
      final current = state.valueOrNull ?? const AssignationState();
      state = AsyncData(current.copyWith(
        assignations: current.assignations
            .map((a) => a.id == assignationId
                ? a.copyWith(statut: StatutAssignation.annulee)
                : a)
            .toList(),
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> rafraichir() async {
    final assignations = await _repo.getAssignations();
    final current = state.valueOrNull ?? const AssignationState();
    state = AsyncData(current.copyWith(assignations: assignations));
  }
}

final assignationProvider =
    AsyncNotifierProvider<AssignationNotifier, AssignationState>(
  AssignationNotifier.new,
);

/// Experts disponibles pour une assignation (filtrables par région)
final expertsDisponiblesProvider =
    FutureProvider.family<List<ExpertDisponibleEntity>, String?>(
        (ref, region) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getExpertsDisponibles(region: region);
});

// ── Historique système ────────────────────────────────────────────────────

class LogsState {
  const LogsState({
    this.logs = const [],
    this.filtre,
    this.plageDate,
    this.rechercheActive = false,
  });

  final List<LogSystemeEntity> logs;
  final TypeLog? filtre;
  final DateTimeRange? plageDate;
  final bool rechercheActive;

  LogsState copyWith({
    List<LogSystemeEntity>? logs,
    TypeLog? filtre,
    bool clearFiltre = false,
    DateTimeRange? plageDate,
    bool clearPlageDate = false,
    bool? rechercheActive,
  }) =>
      LogsState(
        logs: logs ?? this.logs,
        filtre: clearFiltre ? null : (filtre ?? this.filtre),
        plageDate: clearPlageDate ? null : (plageDate ?? this.plageDate),
        rechercheActive: rechercheActive ?? this.rechercheActive,
      );

  List<LogSystemeEntity> get filtres {
    var liste = logs.where((l) => !l.estArchive).toList();
    if (filtre != null) {
      liste = liste.where((l) => l.type == filtre).toList();
    }
    if (plageDate != null) {
      liste = liste
          .where((l) =>
              !l.horodatage.isBefore(plageDate!.debut) &&
              !l.horodatage.isAfter(plageDate!.fin))
          .toList();
    }
    return liste;
  }
}

class LogsNotifier extends AsyncNotifier<LogsState> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  Future<LogsState> build() async {
    final logs = await _repo.getLogs();
    return LogsState(logs: logs);
  }

  void setFiltre(TypeLog? filtre) {
    final current = state.valueOrNull;
    if (current == null) return;
    if (filtre == null) {
      state = AsyncData(current.copyWith(clearFiltre: true));
    } else {
      state = AsyncData(current.copyWith(filtre: filtre));
    }
  }

  void setPlageDate(DateTimeRange? plage) {
    final current = state.valueOrNull;
    if (current == null) return;
    if (plage == null) {
      state = AsyncData(current.copyWith(clearPlageDate: true));
    } else {
      state = AsyncData(current.copyWith(plageDate: plage));
    }
  }

  /// Pratique pour l'UI : évite d'importer DateTimeRange du domaine dans les écrans.
  void setPlageFromDates(DateTime debut, DateTime fin) =>
      setPlageDate(DateTimeRange(debut: debut, fin: fin));

  void effacerPlage() => setPlageDate(null);

  Future<void> archiverLog(String logId) async {
    await _repo.archiverLog(logId);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      logs: current.logs
          .map((l) => l.id == logId ? l.copyWith(estArchive: true) : l)
          .toList(),
    ));
  }

  Future<String> exporterCSV() async {
    final current = state.valueOrNull;
    if (current == null) return '';
    return _repo.exporterLogsCSV(current.filtres);
  }

  Future<void> rafraichir() async {
    final logs = await _repo.getLogs();
    final current = state.valueOrNull ?? const LogsState();
    state = AsyncData(current.copyWith(logs: logs));
  }
}

final logsProvider = AsyncNotifierProvider<LogsNotifier, LogsState>(
  LogsNotifier.new,
);

// ── KPIs globaux pour le dashboard ───────────────────────────────────────

final kpiAdminProvider = Provider<Map<String, int>>((ref) {
  final stats = ref.watch(statistiquesProvider).valueOrNull?.statistiques;
  if (stats == null) {
    return {
      'totalUtilisateurs': 0,
      'totalAgriculteurs': 0,
      'totalExperts': 0,
      'interventionsEnCours': 0,
    };
  }
  return {
    'totalUtilisateurs': stats.totalUtilisateurs,
    'totalAgriculteurs': stats.totalAgriculteurs,
    'totalExperts': stats.totalExperts,
    'interventionsEnCours': stats.interventionsEnCours,
  };
});

// ── Gestion des champs (vue admin) ───────────────────────────────────────

class ChampsAdminState {
  const ChampsAdminState({
    this.champs = const [],
    this.recherche = '',
  });

  final List<ChampEntity> champs;
  final String recherche;

  List<ChampEntity> get filtres {
    if (recherche.isEmpty) return champs;
    final q = recherche.toLowerCase();
    return champs
        .where((c) =>
            c.nom.toLowerCase().contains(q) ||
            (c.culture?.toLowerCase().contains(q) ?? false) ||
            c.typeSol.toLowerCase().contains(q))
        .toList();
  }

  ChampsAdminState copyWith({List<ChampEntity>? champs, String? recherche}) =>
      ChampsAdminState(
        champs: champs ?? this.champs,
        recherche: recherche ?? this.recherche,
      );
}

class ChampsAdminNotifier extends AsyncNotifier<ChampsAdminState> {
  @override
  Future<ChampsAdminState> build() async {
    final champs = await _fetchChamps();
    return ChampsAdminState(champs: champs);
  }

  Future<List<ChampEntity>> _fetchChamps() async {
    final dio = ref.read(dioProvider);
    final resp = await dio.get('/champs');
    final data = resp.data as Map<String, dynamic>;
    return (data['champs'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(ChampModel.fromJson)
        .toList();
  }

  void setRecherche(String recherche) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(recherche: recherche));
  }

  Future<bool> creerChamp({
    required String nom,
    required double superficie,
    required String typeSol,
    double? latitude,
    double? longitude,
    String? culture,
    String? agriculteurId,
  }) async {
    try {
      final dio = ref.read(dioProvider);
      final body = <String, dynamic>{
        'nom': nom,
        'superficie': superficie,
        'typeSol': typeSol,
        'latitude': latitude ?? 14.6937,
        'longitude': longitude ?? -17.4441,
        'adresse': 'Sénégal',
        if (culture != null) 'commentaire': culture,
        if (agriculteurId != null) 'agriculteurId': agriculteurId,
      };
      final resp = await dio.post('/champs', data: body);
      final nouveau = ChampModel.fromJson(resp.data as Map<String, dynamic>);
      final current = state.valueOrNull ?? const ChampsAdminState();
      state = AsyncData(current.copyWith(champs: [nouveau, ...current.champs]));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> supprimerChamp(String id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/champs/$id');
      _retirerLocal(id);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _retirerLocal(String id) {
    final current = state.valueOrNull ?? const ChampsAdminState();
    state = AsyncData(current.copyWith(
      champs: current.champs.where((c) => c.id != id).toList(),
    ));
  }

  Future<void> rafraichir() async {
    final champs = await _fetchChamps();
    final current = state.valueOrNull ?? const ChampsAdminState();
    state = AsyncData(current.copyWith(champs: champs));
  }

}

final champsAdminProvider =
    AsyncNotifierProvider<ChampsAdminNotifier, ChampsAdminState>(
  ChampsAdminNotifier.new,
);
