import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/expert_repository_impl.dart';
import '../../domain/entities/alerte_zone_entity.dart';
import '../../domain/entities/champ_supervise_entity.dart';
import '../../domain/entities/conseil_entity.dart';
import '../../domain/entities/diagnostic_expert_entity.dart';
import '../../domain/entities/expert_entity.dart';
import '../../domain/entities/intervention_entity.dart';
import '../../domain/enums/decision_expert.dart';
import '../../domain/enums/statut_intervention.dart';
import '../../domain/enums/type_conseil.dart';
import '../../domain/enums/type_intervention.dart';
import '../../../detection/domain/enums/type_traitement.dart';
import '../../domain/repositories/expert_repository.dart';
import '../../../detection/domain/enums/niveau_gravite.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ── Repository provider ──────────────────────────────────────────────────────

final expertRepositoryProvider = Provider<ExpertRepository>(
  (_) => ExpertRepositoryImpl(),
);

// ── Profil Expert ────────────────────────────────────────────────────────────

/// ID de l'expert connecté — utilise le vrai UID Firebase
final expertIdProvider = Provider<String>((ref) {
  final auth = ref.watch(authProvider).valueOrNull;
  return auth?.user?.id ?? '';
});

class ProfilExpertNotifier extends AsyncNotifier<ExpertEntity> {
  ExpertRepository get _repo => ref.read(expertRepositoryProvider);

  @override
  Future<ExpertEntity> build() async {
    final id = ref.read(expertIdProvider);
    return _repo.getProfilExpert(id);
  }

  Future<void> updateProfil(ExpertEntity expert) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.updateProfilExpert(expert));
  }
}

final profilExpertProvider = AsyncNotifierProvider<ProfilExpertNotifier, ExpertEntity>(
  ProfilExpertNotifier.new,
);

// ── Diagnostics en attente ───────────────────────────────────────────────────

/// Filtre actif pour les diagnostics
enum FiltreDiagnostic { tous, critique, eleve, modere, faible, aujourdhui, semaine }

class DiagnosticsState {
  const DiagnosticsState({
    this.diagnostics = const [],
    this.filtre = FiltreDiagnostic.tous,
    this.triParGravite = false,
  });

  final List<DiagnosticExpertEntity> diagnostics;
  final FiltreDiagnostic filtre;
  final bool triParGravite;

  DiagnosticsState copyWith({
    List<DiagnosticExpertEntity>? diagnostics,
    FiltreDiagnostic? filtre,
    bool? triParGravite,
  }) =>
      DiagnosticsState(
        diagnostics: diagnostics ?? this.diagnostics,
        filtre: filtre ?? this.filtre,
        triParGravite: triParGravite ?? this.triParGravite,
      );

  List<DiagnosticExpertEntity> get filtres {
    final now = DateTime.now();
    List<DiagnosticExpertEntity> liste = List.from(diagnostics);
    switch (filtre) {
      case FiltreDiagnostic.critique:
        liste = liste.where((d) => d.niveauGraviteIA == NiveauGravite.critique).toList();
      case FiltreDiagnostic.eleve:
        liste = liste.where((d) => d.niveauGraviteIA == NiveauGravite.eleve).toList();
      case FiltreDiagnostic.modere:
        liste = liste.where((d) => d.niveauGraviteIA == NiveauGravite.modere).toList();
      case FiltreDiagnostic.faible:
        liste = liste.where((d) => d.niveauGraviteIA == NiveauGravite.faible).toList();
      case FiltreDiagnostic.aujourdhui:
        liste = liste
            .where((d) => d.dateSoumission.day == now.day && d.dateSoumission.month == now.month)
            .toList();
      case FiltreDiagnostic.semaine:
        final uneSemaine = now.subtract(const Duration(days: 7));
        liste = liste.where((d) => d.dateSoumission.isAfter(uneSemaine)).toList();
      case FiltreDiagnostic.tous:
        break;
    }
    if (triParGravite) {
      liste.sort((a, b) => b.niveauGraviteIA.index.compareTo(a.niveauGraviteIA.index));
    } else {
      liste.sort((a, b) => b.dateSoumission.compareTo(a.dateSoumission));
    }
    return liste;
  }
}

class DiagnosticsNotifier extends AsyncNotifier<DiagnosticsState> {
  ExpertRepository get _repo => ref.read(expertRepositoryProvider);

  @override
  Future<DiagnosticsState> build() async {
    final expertId = ref.read(expertIdProvider);
    final diagnostics = await _repo.getDiagnosticsEnAttente(expertId);
    return DiagnosticsState(diagnostics: diagnostics);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final expertId = ref.read(expertIdProvider);
    final diagnostics = await _repo.getDiagnosticsEnAttente(expertId);
    state = AsyncData(DiagnosticsState(diagnostics: diagnostics));
  }

  void setFiltre(FiltreDiagnostic filtre) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(filtre: filtre));
  }

  void toggleTri() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(triParGravite: !current.triParGravite));
  }

  Future<bool> validerDiagnostic({
    required String diagnosticId,
    String? commentaire,
    bool notifierAgriculteur = true,
  }) async {
    try {
      final expertId = ref.read(expertIdProvider);
      await _repo.validerDiagnostic(
        diagnosticId: diagnosticId,
        expertId: expertId,
        commentaire: commentaire,
        notifierAgriculteur: notifierAgriculteur,
      );
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejeterDiagnostic({
    required String diagnosticId,
    required String motifRejet,
  }) async {
    try {
      final expertId = ref.read(expertIdProvider);
      await _repo.rejeterDiagnostic(
        diagnosticId: diagnosticId,
        expertId: expertId,
        motifRejet: motifRejet,
      );
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> corrigerDiagnostic({
    required String diagnosticId,
    required DecisionExpert decision,
    required String maladieId,
    required NiveauGravite niveauGravite,
    required String traitement,
    String? dosage,
    String? frequence,
    int? duree,
    int? cout,
    TypeTraitement? typeTraitement,
    String? observations,
    bool notifierAgriculteur = true,
  }) async {
    try {
      final expertId = ref.read(expertIdProvider);
      await _repo.corrigerDiagnostic(
        diagnosticId: diagnosticId,
        expertId: expertId,
        decision: decision,
        maladieCorrIgeeId: maladieId,
        niveauGravite: niveauGravite,
        traitementRecommande: traitement,
        dosage: dosage,
        frequence: frequence,
        dureeJours: duree,
        coutFCFA: cout,
        typeTraitement: typeTraitement,
        observations: observations,
        notifierAgriculteur: notifierAgriculteur,
      );
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final diagnosticsNotifier = AsyncNotifierProvider<DiagnosticsNotifier, DiagnosticsState>(
  DiagnosticsNotifier.new,
);

/// Diagnostic unique par ID
final diagnosticDetailProvider = FutureProvider.family<DiagnosticExpertEntity, String>(
  (ref, id) async {
    final repo = ref.read(expertRepositoryProvider);
    return repo.getDiagnosticDetail(id);
  },
);

/// Nombre de diagnostics urgents (gravité CRITIQUE ou ÉLEVÉ)
final nombreDiagnosticsUrgentsProvider = Provider<int>((ref) {
  final state = ref.watch(diagnosticsNotifier).valueOrNull;
  if (state == null) return 0;
  return state.diagnostics
      .where((d) =>
          d.niveauGraviteIA == NiveauGravite.critique ||
          d.niveauGraviteIA == NiveauGravite.eleve)
      .length;
});

// ── Supervision champs ───────────────────────────────────────────────────────

class ChampsSupervisionNotifier extends AsyncNotifier<List<ChampSuperviseEntity>> {
  ExpertRepository get _repo => ref.read(expertRepositoryProvider);

  @override
  Future<List<ChampSuperviseEntity>> build() async {
    final expertId = ref.read(expertIdProvider);
    return _repo.getChampsSupervises(expertId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final expertId = ref.read(expertIdProvider);
      return _repo.getChampsSupervises(expertId);
    });
  }
}

final champsSupervisionProvider =
    AsyncNotifierProvider<ChampsSupervisionNotifier, List<ChampSuperviseEntity>>(
  ChampsSupervisionNotifier.new,
);

final champSuperviseDetailProvider = FutureProvider.family<ChampSuperviseEntity, String>(
  (ref, champId) async {
    final repo = ref.read(expertRepositoryProvider);
    return repo.getChampDetail(champId);
  },
);

// ── Interventions ────────────────────────────────────────────────────────────

class InterventionsNotifier extends AsyncNotifier<List<InterventionEntity>> {
  ExpertRepository get _repo => ref.read(expertRepositoryProvider);

  @override
  Future<List<InterventionEntity>> build() async {
    final expertId = ref.read(expertIdProvider);
    return _repo.getInterventions(expertId);
  }

  Future<bool> planifier({
    required String champId,
    required TypeIntervention type,
    required DateTime date,
    required String description,
    String? heure,
    double duree = 1.0,
    List<String> materiel = const [],
    bool notifier = true,
  }) async {
    try {
      final expertId = ref.read(expertIdProvider);
      final nouvelle = await _repo.planifierIntervention(
        expertId: expertId,
        champId: champId,
        type: type,
        date: date,
        description: description,
        heure: heure,
        dureeHeures: duree,
        materiel: materiel,
        notifierAgriculteur: notifier,
      );
      final current = state.valueOrNull ?? [];
      state = AsyncData([nouvelle, ...current]);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final interventionsProvider =
    AsyncNotifierProvider<InterventionsNotifier, List<InterventionEntity>>(
  InterventionsNotifier.new,
);

// ── Conseils ─────────────────────────────────────────────────────────────────

class ConseilsNotifier extends AsyncNotifier<List<ConseilEntity>> {
  ExpertRepository get _repo => ref.read(expertRepositoryProvider);

  @override
  Future<List<ConseilEntity>> build() async {
    final expertId = ref.read(expertIdProvider);
    return _repo.getConseils(expertId);
  }

  Future<bool> envoyer({
    required String agriculteurId,
    required String champId,
    required TypeConseil type,
    required String titre,
    required String corps,
    bool estUrgent = false,
    String? imageUrl,
  }) async {
    try {
      final expertId = ref.read(expertIdProvider);
      final conseil = await _repo.envoyerConseil(
        expertId: expertId,
        agriculteurId: agriculteurId,
        champId: champId,
        type: type,
        titre: titre,
        corps: corps,
        estUrgent: estUrgent,
        imageUrl: imageUrl,
      );
      final current = state.valueOrNull ?? [];
      state = AsyncData([conseil, ...current]);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final conseilsProvider = AsyncNotifierProvider<ConseilsNotifier, List<ConseilEntity>>(
  ConseilsNotifier.new,
);

// ── Alertes zone ─────────────────────────────────────────────────────────────

class AlertesZoneNotifier extends AsyncNotifier<List<AlerteZoneEntity>> {
  ExpertRepository get _repo => ref.read(expertRepositoryProvider);

  @override
  Future<List<AlerteZoneEntity>> build() async {
    final expertId = ref.read(expertIdProvider);
    return _repo.getAlertesZone(expertId);
  }

  Future<bool> prendreEnCharge(String alerteId) async {
    try {
      final expertId = ref.read(expertIdProvider);
      final updated = await _repo.prendreEnChargeAlerte(
        alerteId: alerteId,
        expertId: expertId,
      );
      final current = state.valueOrNull ?? [];
      state = AsyncData(
        current.map((a) => a.id == alerteId ? updated : a).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final alertesZoneProvider = AsyncNotifierProvider<AlertesZoneNotifier, List<AlerteZoneEntity>>(
  AlertesZoneNotifier.new,
);

/// KPI globaux du dashboard
final expertKpiProvider = Provider((ref) {
  final diagnostics = ref.watch(diagnosticsNotifier).valueOrNull?.diagnostics ?? [];
  final champs = ref.watch(champsSupervisionProvider).valueOrNull ?? [];
  final interventions = ref.watch(interventionsProvider).valueOrNull ?? [];
  final alertes = ref.watch(alertesZoneProvider).valueOrNull ?? [];

  return {
    'diagnosticsEnAttente': diagnostics.length,
    'champsSupervises': champs.length,
    'interventionsPlanifiees':
        interventions.where((i) => i.statut == StatutIntervention.planifiee).length,
    'alertesActives':
        alertes.where((a) => a.statut != StatutAlerteZone.resolue).length,
  };
});
