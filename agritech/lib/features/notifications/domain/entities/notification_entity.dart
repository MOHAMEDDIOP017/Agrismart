import 'package:equatable/equatable.dart';
import '../../../../core/enums/type_notification.dart';

/// Notification envoyée à un utilisateur (agriculteur ou expert)
class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.destinataireId,
    required this.type,
    required this.titre,
    required this.corps,
    this.urgent = false,
    required this.dateEnvoi,
    this.lu = false,
    this.dateLecture,
  });

  final String id;
  final String destinataireId;
  final TypeNotification type;
  final String titre;
  final String corps;
  final bool urgent;
  final DateTime dateEnvoi;
  final bool lu;
  final DateTime? dateLecture;

  @override
  List<Object?> get props => [id, destinataireId, dateEnvoi];
}
