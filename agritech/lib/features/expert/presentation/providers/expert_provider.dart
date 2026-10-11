import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/expert_repository_impl.dart';
import '../../domain/entities/champ_supervise_entity.dart';
import '../../domain/entities/conseil_entity.dart';
import '../../domain/entities/expert_entity.dart';
import '../../domain/entities/intervention_entity.dart';
import '../../domain/entities/recommandation_expert_entity.dart';
import '../../domain/enums/statut_intervention.dart';
import '../../domain/enums/type_conseil.dart';
import '../../domain/enums/type_intervention.dart';
import '../../domain/repositories/expert_repository.dart';
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

final profilExpertProvider =
    AsyncNotifierProvider<ProfilExpertNotifier, ExpertEntity>(
  ProfilExpertNotifier.new,
);

// ── Supervision champs ───────────────────────────────────────────────────────

class ChampsSupervisionNotifier
    extends AsyncNotifier<List<ChampSuperviseEntity>> {
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

final champsSupervisionProvider = AsyncNotifierProvider<
    ChampsSupervisionNotifier, List<ChampSuperviseEntity>>(
  ChampsSupervisionNotifier.new,
);

final champSuperviseDetailProvider =
    FutureProvider.family<ChampSuperviseEntity, String>(
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

final conseilsProvider =
    AsyncNotifierProvider<ConseilsNotifier, List<ConseilEntity>>(
  ConseilsNotifier.new,
);

/// KPI globaux du dashboard
final expertKpiProvider = Provider((ref) {
  final champs = ref.watch(champsSupervisionProvider).valueOrNull ?? [];
  final interventions = ref.watch(interventionsProvider).valueOrNull ?? [];
  final recommandations = ref.watch(recommandationsExpertProvider).valueOrNull;

  return {
    'champsSupervises': champs.length,
    'interventionsPlanifiees': interventions
        .where((i) => i.statut == StatutIntervention.planifiee)
        .length,
    'recommandationsEnAttente': recommandations?.nombreEnAttente ?? 0,
  };
});

// ── Recommandations cultures — boucle de validation expert ───────────────────

class RecommandationsExpertState {
  const RecommandationsExpertState({
    this.recommandations = const [],
    this.filtre = 'EN_ATTENTE',
  });

  final List<RecommandationExpertEntity> recommandations;

  /// 'EN_ATTENTE' | 'VALIDEE' | 'CORRIGEE' | 'REJETEE' | 'TOUTES'
  final String filtre;

  RecommandationsExpertState copyWith({
    List<RecommandationExpertEntity>? recommandations,
    String? filtre,
  }) =>
      RecommandationsExpertState(
        recommandations: recommandations ?? this.recommandations,
        filtre: filtre ?? this.filtre,
      );

  List<RecommandationExpertEntity> get filtrees => filtre == 'TOUTES'
      ? recommandations
      : recommandations.where((r) => r.statutValidation == filtre).toList();

  int get nombreEnAttente =>
      recommandations.where((r) => r.estEnAttente).length;
}

class RecommandationsExpertNotifier
    extends AsyncNotifier<RecommandationsExpertState> {
  ExpertRepository get _repo => ref.read(expertRepositoryProvider);

  @override
  Future<RecommandationsExpertState> build() async {
    final expertId = ref.read(expertIdProvider);
    final recos = await _repo.getRecommandationsEnAttente(expertId);
    return RecommandationsExpertState(recommandations: recos);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final expertId = ref.read(expertIdProvider);
    final recos = await _repo.getRecommandationsEnAttente(expertId);
    state = AsyncData(RecommandationsExpertState(recommandations: recos));
  }

  void setFiltre(String filtre) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(filtre: filtre));
  }

  Future<bool> valider({
    required String recoId,
    String? commentaire,
    bool notifierAgriculteur = true,
  }) async {
    try {
      final expertId = ref.read(expertIdProvider);
      final mis = await _repo.validerRecommandation(
        recoId: recoId,
        expertId: expertId,
        commentaire: commentaire,
        notifierAgriculteur: notifierAgriculteur,
      );
      _remplacerLocal(mis);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> corrigerOuRejeter({
    required String recoId,
    required String decision,
    required String commentaire,
    String? cultureCorrigee,
    bool notifierAgriculteur = true,
  }) async {
    try {
      final expertId = ref.read(expertIdProvider);
      final mis = await _repo.corrigerOuRejeterRecommandation(
        recoId: recoId,
        expertId: expertId,
        decision: decision,
        commentaire: commentaire,
        cultureCorrigee: cultureCorrigee,
        notifierAgriculteur: notifierAgriculteur,
      );
      _remplacerLocal(mis);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _remplacerLocal(RecommandationExpertEntity mis) {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated =
        current.recommandations.map((r) => r.id == mis.id ? mis : r).toList();
    state = AsyncData(current.copyWith(recommandations: updated));
  }
}

final recommandationsExpertProvider = AsyncNotifierProvider<
    RecommandationsExpertNotifier, RecommandationsExpertState>(
  RecommandationsExpertNotifier.new,
);
