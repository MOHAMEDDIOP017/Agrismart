import 'package:equatable/equatable.dart';
import '../enums/niveau_gravite.dart';
import 'traitement_entity.dart';

/// Entité représentant une maladie de plante
class MaladieEntity extends Equatable {
  const MaladieEntity({
    required this.id,
    required this.nom,
    required this.nomScientifique,
    required this.description,
    required this.symptomes,
    required this.gravite,
    required this.culturesAffectees,
    this.traitements = const [],
    this.imageUrl,
    this.agentPathogene,
    this.conditionsFavorables,
  });

  final String id;
  final String nom;
  final String nomScientifique;
  final String description;
  final List<String> symptomes;
  final NiveauGravite gravite;
  final List<String> culturesAffectees;
  final List<TraitementEntity> traitements;
  final String? imageUrl;
  final String? agentPathogene;
  final String? conditionsFavorables;

  @override
  List<Object?> get props => [id, nom];
}
