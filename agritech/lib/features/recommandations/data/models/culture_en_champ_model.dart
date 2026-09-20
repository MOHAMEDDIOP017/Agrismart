import '../../domain/entities/culture_en_champ_entity.dart';
import '../../../../core/enums/statut_culture.dart';

class CultureEnChampModel extends CultureEnChampEntity {
  const CultureEnChampModel({
    required super.id,
    required super.champId,
    required super.cultureId,
    required super.dateDebut,
    required super.dateFinPrevue,
    super.rendementReel,
    required super.statut,
  });

  factory CultureEnChampModel.fromJson(Map<String, dynamic> json) =>
      CultureEnChampModel(
        id: (json['id'] ?? '') as String,
        champId: (json['champ_id'] ?? json['champId'] ?? '') as String,
        cultureId: (json['culture_id'] ?? json['cultureId'] ?? '') as String,
        dateDebut: _parseDate(json['date_debut'] ?? json['dateDebut']),
        dateFinPrevue:
            _parseDate(json['date_fin_prevue'] ?? json['dateFinPrevue']),
        rendementReel:
            ((json['rendement_reel'] ?? json['rendementReel']) as num?)
                ?.toDouble(),
        statut: StatutCulture.fromString(
          (json['statut'] as String?) ?? 'PREVU',
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'champ_id': champId,
        'culture_id': cultureId,
        'date_debut': dateDebut.toIso8601String(),
        'date_fin_prevue': dateFinPrevue.toIso8601String(),
        'rendement_reel': rendementReel,
        'statut': statut.toJson(),
      };

  Map<String, dynamic> toCreateJson() => {
        'champ_id': champId,
        'culture_id': cultureId,
        'date_debut': dateDebut.toIso8601String(),
        'date_fin_prevue': dateFinPrevue.toIso8601String(),
        'statut': statut.toJson(),
      };

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
