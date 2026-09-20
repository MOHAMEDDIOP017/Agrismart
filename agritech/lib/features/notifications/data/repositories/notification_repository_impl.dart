import 'package:dio/dio.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../../../core/enums/type_notification.dart';
import '../../../../core/network/api_endpoints.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<NotificationEntity>> getNotificationsUtilisateur(
      String userId) async {
    final response =
        await _dio.get(ApiEndpoints.notificationsUtilisateur(userId));
    final data = response.data;
    final list = (data is Map
            ? (data['notifications'] ?? data['items'] ?? data['data'])
            : data) as List? ??
        [];
    return list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<NotificationEntity> marquerLue(String id) async {
    final response =
        await _dio.put(ApiEndpoints.notificationMarquerLue(id));
    return _fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> marquerToutesLues(String userId) async {
    await _dio.put(ApiEndpoints.notificationsToutesLues(userId));
  }

  @override
  Future<void> deleteNotification(String id) async {
    await _dio.delete(ApiEndpoints.notificationById(id));
  }

  static NotificationEntity _fromJson(Map<String, dynamic> json) =>
      NotificationEntity(
        id: (json['id'] ?? '') as String,
        destinataireId:
            (json['destinataire_id'] ?? json['destinataireId'] ?? '') as String,
        type: TypeNotification.fromString(
            (json['type'] ?? 'RECOMMANDATION') as String),
        titre: (json['titre'] ?? '') as String,
        corps: (json['corps'] ?? json['message'] ?? '') as String,
        urgent: json['urgent'] as bool? ?? false,
        dateEnvoi: _parseDate(json['date_envoi'] ?? json['dateEnvoi']),
        lu: (json['lu'] ?? json['estLue'] ?? false) as bool,
        dateLecture:
            (json['date_lecture'] ?? json['dateLecture']) != null
                ? _parseDate(json['date_lecture'] ?? json['dateLecture'])
                : null,
      );

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
