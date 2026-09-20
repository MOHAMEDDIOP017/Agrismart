import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/culture_repository_impl.dart';
import '../../data/repositories/culture_en_champ_repository_impl.dart';
import '../../domain/entities/culture_entity.dart';
import '../../domain/entities/culture_en_champ_entity.dart';
import '../../domain/repositories/culture_repository.dart';
import '../../domain/repositories/culture_en_champ_repository.dart';
import '../../../../core/enums/statut_culture.dart';

// ── Repository providers ─────────────────────────────────────────────────────

final cultureRepositoryProvider = Provider<CultureRepository>(
  (ref) => CultureRepositoryImpl(ref.read(dioProvider)),
);

final cultureEnChampRepositoryProvider =
    Provider<CultureEnChampRepository>(
  (ref) => CultureEnChampRepositoryImpl(ref.read(dioProvider)),
);

// ── Cultures (référentiel) ───────────────────────────────────────────────────

final culturesProvider =
    FutureProvider<List<CultureEntity>>((ref) async {
  return ref.read(cultureRepositoryProvider).getCultures();
});

final cultureByIdProvider =
    FutureProvider.autoDispose.family<CultureEntity?, String>(
  (ref, id) async {
    try {
      return await ref.read(cultureRepositoryProvider).getCultureById(id);
    } catch (_) {
      return null;
    }
  },
);

// ── Cultures en champ ────────────────────────────────────────────────────────

class CulturesEnChampNotifier extends AutoDisposeFamilyAsyncNotifier<
    List<CultureEnChampEntity>, String> {
  CultureEnChampRepository get _repo =>
      ref.read(cultureEnChampRepositoryProvider);

  @override
  Future<List<CultureEnChampEntity>> build(String champId) async =>
      _repo.getCulturesEnChamp(champId);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getCulturesEnChamp(arg));
  }

  Future<bool> creer(CultureEnChampEntity item) async {
    try {
      await _repo.createCultureEnChamp(item);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changerStatut(
    String id,
    StatutCulture statut, {
    double? rendementReel,
  }) async {
    try {
      final updated =
          await _repo.updateStatut(id, statut, rendementReel: rendementReel);
      final current = state.valueOrNull ?? [];
      state = AsyncData(
          current.map((c) => c.id == id ? updated : c).toList());
      return true;
    } catch (_) {
      return false;
    }
  }
}

final culturesEnChampProvider = AsyncNotifierProvider.autoDispose
    .family<CulturesEnChampNotifier, List<CultureEnChampEntity>, String>(
  CulturesEnChampNotifier.new,
);

// NB : la génération/validation des recommandations de cultures (moteur
// multi-label v2) et le calcul post-récolte sont gérés ailleurs, branchés
// sur les vrais endpoints /recommandations/v2/* et /recommandations/{id}/post-recolte :
// voir `recommandation_provider.dart` (écran agriculteur) et
// `post_recolte_provider.dart` (scénarios vente/transformation). Cette
// section hébergeait une pile Clean Architecture parallèle, jamais branchée
// à un écran et encore façonnée pour le moteur v1 SVM retiré (`score` au
// lieu de `probabiliteAptitude`/`rang`) — retirée pour éviter la confusion.
