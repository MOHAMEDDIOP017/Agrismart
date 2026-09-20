import 'package:equatable/equatable.dart';
import '../../../../core/enums/statut_culture.dart';

/// Suivi d'une culture semée dans un champ spécifique
class CultureEnChampEntity extends Equatable {
  const CultureEnChampEntity({
    required this.id,
    required this.champId,
    required this.cultureId,
    required this.dateDebut,
    required this.dateFinPrevue,
    this.rendementReel,
    required this.statut,
  });

  final String id;
  final String champId;
  final String cultureId;
  final DateTime dateDebut;
  final DateTime dateFinPrevue;
  final double? rendementReel;
  final StatutCulture statut;

  bool get estEnCours => statut == StatutCulture.enCours;
  bool get estTerminee =>
      statut == StatutCulture.recolte || statut == StatutCulture.abandonne;

  @override
  List<Object?> get props => [id, champId, cultureId];
}
