import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<List<NotificationEntity>> getNotificationsUtilisateur(String userId);
  Future<NotificationEntity> marquerLue(String id);
  Future<void> marquerToutesLues(String userId);
  Future<void> deleteNotification(String id);
}
