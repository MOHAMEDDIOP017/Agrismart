import 'package:equatable/equatable.dart';
import '../enums/niveau_urgence_admin.dart';
import '../enums/statut_assignation.dart';

/// Entité représentant une assignation expert ↔ intervention (vue Admin)
class AssignationEntity extends Equatable {
  const AssignationEntity({
    required this.id,
    required this.agriculteurNom,
    required this.champNom,
    required this.region,
    required this.typeIntervention,
    required this.niveauUrgence,
    required this.statut,
    required this.dateSouhaitee,
    required this.dateCreation,
    this.expertId,
    this.expertNom,
    this.expertSpecialite,
    this.expertTelephone,
    this.expertRegion,
    this.expertDisponible,
    this.messageExpert,
    this.notifierExpert = true,
  });

  final String id;
  // Informations intervention
  final String agriculteurNom;
  final String champNom;
  final String region;
  final String typeIntervention;
  final NiveauUrgenceAdmin niveauUrgence;
  final StatutAssignation statut;
  final DateTime dateSouhaitee;
  final DateTime dateCreation;
  // Informations expert assigné (null si non assignée)
  final String? expertId;
  final String? expertNom;
  final String? expertSpecialite;
  final String? expertTelephone;
  final String? expertRegion;
  final bool? expertDisponible;
  // Paramètres de l'assignation
  final String? messageExpert;
  final bool notifierExpert;

  bool get estAssignee => expertId != null;

  AssignationEntity copyWith({
    StatutAssignation? statut,
    String? expertId,
    String? expertNom,
    String? expertSpecialite,
    String? expertTelephone,
    String? expertRegion,
    bool? expertDisponible,
    String? messageExpert,
    bool? notifierExpert,
  }) {
    return AssignationEntity(
      id: id,
      agriculteurNom: agriculteurNom,
      champNom: champNom,
      region: region,
      typeIntervention: typeIntervention,
      niveauUrgence: niveauUrgence,
      statut: statut ?? this.statut,
      dateSouhaitee: dateSouhaitee,
      dateCreation: dateCreation,
      expertId: expertId ?? this.expertId,
      expertNom: expertNom ?? this.expertNom,
      expertSpecialite: expertSpecialite ?? this.expertSpecialite,
      expertTelephone: expertTelephone ?? this.expertTelephone,
      expertRegion: expertRegion ?? this.expertRegion,
      expertDisponible: expertDisponible ?? this.expertDisponible,
      messageExpert: messageExpert ?? this.messageExpert,
      notifierExpert: notifierExpert ?? this.notifierExpert,
    );
  }

  @override
  List<Object?> get props => [id, statut, expertId];
}

/// Expert disponible pour une assignation
class ExpertDisponibleEntity extends Equatable {
  const ExpertDisponibleEntity({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.specialite,
    required this.region,
    required this.estEnLigne,
    required this.interventionsEnCours,
    required this.scoreEvaluation,
    this.telephone,
    this.photoUrl,
  });

  final String id;
  final String nom;
  final String prenom;
  final String specialite;
  final String region;
  final bool estEnLigne;
  final int interventionsEnCours;

  /// Score moyen sur 5
  final double scoreEvaluation;
  final String? telephone;
  final String? photoUrl;

  String get nomComplet => '$prenom $nom';

  @override
  List<Object?> get props => [id];
}
