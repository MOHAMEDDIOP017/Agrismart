import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/alerte_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AlertesNotifier extends AsyncNotifier<List<AlerteModel>> {
  late Dio _dio;

  @override
  Future<List<AlerteModel>> build() async {
    _dio = ref.read(dioProvider);
    final auth = ref.watch(authProvider);
    final userId = auth.valueOrNull?.user?.id;
    if (userId == null) return [];
    return _charger(userId);
  }

  Future<List<AlerteModel>> _charger(String userId) async {
    final resp =
        await _dio.get('/notifications/utilisateur/$userId?limite=50');
    final data = resp.data as Map<String, dynamic>;
    final list = (data['notifications'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(AlerteModel.fromNotificationJson)
        .toList();
    list.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    return list;
  }

  Future<void> rafraichir() async {
    final auth = ref.read(authProvider);
    final userId = auth.valueOrNull?.user?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _charger(userId));
  }

  Future<void> marquerLue(String alerteId) async {
    try {
      await _dio.patch('/notifications/$alerteId/marquer-lue');
      state = AsyncData(
        (state.valueOrNull ?? []).map((a) {
          return a.id == alerteId ? a.copyWith(isLue: true) : a;
        }).toList(),
      );
    } catch (_) {}
  }

  Future<void> marquerToutesLues() async {
    final nonLues =
        (state.valueOrNull ?? []).where((a) => !a.isLue).toList();
    for (final a in nonLues) {
      await marquerLue(a.id);
    }
  }
}

final alertesProvider =
    AsyncNotifierProvider<AlertesNotifier, List<AlerteModel>>(
  AlertesNotifier.new,
);

final alertesNonLuesCountProvider = Provider<int>((ref) {
  return ref.watch(alertesProvider).valueOrNull?.where((a) => !a.isLue).length ??
      0;
});
