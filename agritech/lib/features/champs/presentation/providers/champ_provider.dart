import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/champ_model.dart';
import '../../data/repositories/champ_repository_impl.dart';
import '../../domain/entities/champ_entity.dart';
import '../../domain/repositories/champ_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final champRepositoryProvider = Provider<ChampRepository>((ref) {
  final dio = ref.read(dioProvider);
  final authState = ref.read(authProvider).valueOrNull;
  final userId = authState?.user?.id ?? '';
  return ChampRepositoryImpl(dio, userId);
});

/// Notifier de gestion des champs
class ChampNotifier extends AsyncNotifier<List<ChampEntity>> {
  ChampRepository get _repo => ref.read(champRepositoryProvider);

  @override
  Future<List<ChampEntity>> build() async => _repo.getChamps();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.getChamps);
  }

  Future<bool> createChamp({
    required String nom,
    required double superficie,
    required String typeSol,
    required String statut,
    String? culture,
    double? latitude,
    double? longitude,
    String? photoUrl,
  }) async {
    try {
      final authState = ref.read(authProvider).valueOrNull;
      final userId = authState?.user?.id ?? '';

      final newChamp = ChampModel(
        id: '',
        nom: nom,
        superficie: superficie,
        typeSol: typeSol,
        statut: statut,
        culture: culture,
        latitude: latitude,
        longitude: longitude,
        photoUrl: photoUrl,
        dateCreation: DateTime.now(),
        userId: userId,
      );
      await _repo.createChamp(newChamp);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateChamp(ChampModel champ) async {
    try {
      await _repo.updateChamp(champ);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteChamp(String id) async {
    try {
      await _repo.deleteChamp(id);
      final current = state.valueOrNull ?? [];
      state = AsyncData(current.where((c) => c.id != id).toList());
      return true;
    } catch (_) {
      return false;
    }
  }
}

final champProvider = AsyncNotifierProvider<ChampNotifier, List<ChampEntity>>(
  ChampNotifier.new,
);

/// Provider pour un champ spécifique par ID
final champByIdProvider = FutureProvider.family<ChampEntity?, String>(
  (ref, id) async {
    final champs = await ref.watch(champProvider.future);
    try {
      return champs.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  },
);
