import 'package:equatable/equatable.dart';

/// Trace d'action effectuée par un utilisateur (audit log)
class HistoriqueActiviteEntity extends Equatable {
  const HistoriqueActiviteEntity({
    required this.id,
    required this.utilisateurId,
    required this.typeAction,
    required this.description,
    required this.dateAction,
  });

  final String id;
  final String utilisateurId;
  final String typeAction;
  final String description;
  final DateTime dateAction;

  @override
  List<Object?> get props => [id, utilisateurId, dateAction];
}
