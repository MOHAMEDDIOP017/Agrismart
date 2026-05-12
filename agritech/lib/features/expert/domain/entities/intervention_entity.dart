import 'package:equatable/equatable.dart';
import '../enums/statut_intervention.dart';
import '../enums/type_intervention.dart';

/// Entité représentant une intervention terrain planifiée par un expert
class InterventionEntity extends Equatable {
  const InterventionEntity({
    required this.id,
    required this.expertId,
    required this.champId,
    required this.champNom,
    required this.agriculteurNom,
    required this.typeIntervention,
    required this.statut,
    required this.dateIntervention,
    required this.description,
    this.heureEstimee,
    this.dureeEstimeeHeures = 1.0,
    this.materielNecessaire = const [],
    this.notifierAgriculteur = true,
    this.notesRealisation,
    this.dateCreation,
  });

  final String id;
  final String expertId;
  final String champId;
  final String champNom;
  final String agriculteurNom;
  final TypeIntervention typeIntervention;
  final StatutIntervention statut;
  final DateTime dateIntervention;
  final String description;
  final String? heureEstimee;
  final double dureeEstimeeHeures;
  final List<String> materielNecessaire;
  final bool notifierAgriculteur;
  final String? notesRealisation;
  final DateTime? dateCreation;

  bool get estPassee => dateIntervention.isBefore(DateTime.now());
  bool get estAujourdhui {
    final now = DateTime.now();
    return dateIntervention.year == now.year &&
        dateIntervention.month == now.month &&
        dateIntervention.day == now.day;
  }

  @override
  List<Object?> get props => [id, dateIntervention];
}
