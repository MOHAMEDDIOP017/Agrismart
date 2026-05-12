import 'package:equatable/equatable.dart';
import '../../../detection/domain/enums/niveau_gravite.dart';

/// Statut d'une alerte zone
enum StatutAlerteZone {
  nonTraitee,
  enCours,
  resolue;

  String get libelle {
    switch (this) {
      case StatutAlerteZone.nonTraitee:
        return 'NON TRAITÉE';
      case StatutAlerteZone.enCours:
        return 'EN COURS';
      case StatutAlerteZone.resolue:
        return 'RÉSOLUE';
    }
  }
}

/// Entité représentant une alerte active dans la zone de l'expert
class AlerteZoneEntity extends Equatable {
  const AlerteZoneEntity({
    required this.id,
    required this.agriculteurId,
    required this.agriculteurNom,
    required this.champId,
    required this.champNom,
    required this.maladie,
    required this.niveauGravite,
    required this.statut,
    required this.dateEmission,
    required this.region,
    this.diagnosticId,
    this.description,
    this.expertEnChargeId,
  });

  final String id;
  final String agriculteurId;
  final String agriculteurNom;
  final String champId;
  final String champNom;
  final String maladie;
  final NiveauGravite niveauGravite;
  final StatutAlerteZone statut;
  final DateTime dateEmission;
  final String region;
  final String? diagnosticId;
  final String? description;
  final String? expertEnChargeId;

  String get tempsEcoule {
    final diff = DateTime.now().difference(dateEmission);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays} jours';
  }

  bool get estCritique => niveauGravite == NiveauGravite.critique;
  bool get estTraitee => statut == StatutAlerteZone.resolue;

  @override
  List<Object?> get props => [id, dateEmission];
}
