import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/notification_model.dart';

class NotificationsNotifier
    extends AsyncNotifier<List<NotificationModel>> {
  late Dio _dio;

  @override
  Future<List<NotificationModel>> build() async {
    _dio = ref.read(dioProvider);
    final auth = ref.watch(authProvider);
    final userId = auth.valueOrNull?.user?.id;
    if (userId == null) return [];
    return _charger(userId);
  }

  Future<List<NotificationModel>> _charger(String userId) async {
    final response =
        await _dio.get('/notifications/utilisateur/$userId?limite=50');
    final data = response.data as Map<String, dynamic>;
    final list = (data['notifications'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
    return list;
  }

  Future<void> rafraichir() async {
    final auth = ref.read(authProvider);
    final userId = auth.valueOrNull?.user?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _charger(userId));
  }

  Future<void> marquerLue(String notifId) async {
    try {
      await _dio.patch('/notifications/$notifId/marquer-lue');
      state = AsyncData(
        (state.valueOrNull ?? []).map((n) {
          return n.id == notifId
              ? NotificationModel(
                  id: n.id,
                  titre: n.titre,
                  corps: n.corps,
                  type: n.type,
                  dateEnvoi: n.dateEnvoi,
                  estLue: true,
                  referenceId: n.referenceId,
                )
              : n;
        }).toList(),
      );
    } catch (_) {}
  }

  int get nonLuesCount =>
      (state.valueOrNull ?? []).where((n) => !n.estLue).length;
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  NotificationsNotifier.new,
);

final nonLuesCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider);
  return notifs.valueOrNull?.where((n) => !n.estLue).length ?? 0;
});
