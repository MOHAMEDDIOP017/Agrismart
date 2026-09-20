import 'package:equatable/equatable.dart';

/// Référentiel d'une culture (variété, exigences agronomiques, économie)
class CultureEntity extends Equatable {
  const CultureEntity({
    required this.id,
    required this.nom,
    required this.variete,
    required this.cycleMaturation,
    required this.besoinsHydriques,
    required this.rendementMoyen,
    required this.phOptimal,
    required this.nOptimal,
    required this.pOptimal,
    required this.kOptimal,
    required this.tempMin,
    required this.tempMax,
    required this.humiditeMin,
    required this.humiditeMax,
    required this.pluvioMin,
    required this.pluvioMax,
    required this.prixMoyenMarche,
  });

  final String id;
  final String nom;
  final String variete;

  /// Durée du cycle en jours
  final int cycleMaturation;
  final String besoinsHydriques;
  final double rendementMoyen;

  // Plages optimales
  final double phOptimal;
  final double nOptimal;
  final double pOptimal;
  final double kOptimal;
  final double tempMin;
  final double tempMax;
  final double humiditeMin;
  final double humiditeMax;
  final double pluvioMin;
  final double pluvioMax;
  final double prixMoyenMarche;

  String get nomComplet => variete.isEmpty ? nom : '$nom ($variete)';

  @override
  List<Object?> get props => [id, nom, variete];
}
