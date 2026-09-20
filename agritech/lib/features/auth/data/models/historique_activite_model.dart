import '../../domain/entities/historique_activite_entity.dart';

class HistoriqueActiviteModel extends HistoriqueActiviteEntity {
  const HistoriqueActiviteModel({
    required super.id,
    required super.utilisateurId,
    required super.typeAction,
    required super.description,
    required super.dateAction,
  });

  factory HistoriqueActiviteModel.fromJson(Map<String, dynamic> json) =>
      HistoriqueActiviteModel(
        id: (json['id'] ?? '') as String,
        utilisateurId:
            (json['utilisateur_id'] ?? json['utilisateurId'] ?? '') as String,
        typeAction:
            (json['type_action'] ?? json['typeAction'] ?? '') as String,
        description: (json['description'] ?? '') as String,
        dateAction:
            _parseDate(json['date_action'] ?? json['dateAction']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'utilisateur_id': utilisateurId,
        'type_action': typeAction,
        'description': description,
        'date_action': dateAction.toIso8601String(),
      };

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
