import 'package:equatable/equatable.dart';

/// Entité représentant un champ agricole
class ChampEntity extends Equatable {
  const ChampEntity({
    required this.id,
    required this.nom,
    required this.superficie,
    required this.typeSol,
    required this.statut,
    this.culture,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.ph,
    this.azote,
    this.phosphore,
    this.potassium,
    this.humidite,
    required this.dateCreation,
    this.dateModification,
    this.userId,
  });

  final String id;
  final String nom;
  final double superficie;
  final String typeSol;
  final String statut;
  final String? culture;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  // Données agronomiques
  final double? ph;
  final double? azote;
  final double? phosphore;
  final double? potassium;
  final double? humidite;
  final DateTime dateCreation;
  final DateTime? dateModification;
  final String? userId;

  String get superficieFormatee => '${superficie.toStringAsFixed(2)} ha';

  String get localisation => (latitude != null && longitude != null)
      ? '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}'
      : 'Position non définie';

  @override
  List<Object?> get props => [id, nom, superficie, statut];
}
