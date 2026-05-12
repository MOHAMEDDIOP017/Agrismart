import 'package:equatable/equatable.dart';

/// Entité représentant un champ dans la vue supervision de l'expert
class ChampSuperviseEntity extends Equatable {
  const ChampSuperviseEntity({
    required this.id,
    required this.nom,
    required this.agriculteurId,
    required this.agriculteurNom,
    required this.agriculteurTelephone,
    required this.superficie,
    required this.typeSol,
    required this.statut,
    required this.region,
    required this.scoresSante,
    this.culture,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.ph,
    this.azote,
    this.phosphore,
    this.potassium,
    this.humidite,
    this.derniereAlerte,
    this.dateDerniereDonnee,
    this.periodeplantation,
  });

  final String id;
  final String nom;
  final String agriculteurId;
  final String agriculteurNom;
  final String agriculteurTelephone;
  final double superficie;
  final String typeSol;
  final String statut;
  final String region;

  /// Score santé du champ (0-100)
  final int scoresSante;

  final String? culture;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final double? ph;
  final double? azote;
  final double? phosphore;
  final double? potassium;
  final double? humidite;
  final String? derniereAlerte;
  final DateTime? dateDerniereDonnee;
  final String? periodeplantation;

  String get superficieFormatee => '${superficie.toStringAsFixed(1)} ha';

  /// Couleur de santé selon le score
  bool get estSain => scoresSante >= 70;
  bool get estEnAlerte => scoresSante < 40;

  @override
  List<Object?> get props => [id, nom];
}
