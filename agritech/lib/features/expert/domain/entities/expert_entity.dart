import 'package:equatable/equatable.dart';
import '../enums/specialite_expert.dart';

/// Entité représentant un expert agronome
class ExpertEntity extends Equatable {
  const ExpertEntity({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.regionCouverture,
    required this.specialite,
    required this.anneesExperience,
    this.photoUrl,
    this.notificationsActives = true,
    this.nombreDiagnosticsValides = 0,
    this.nombreCorrections = 0,
    this.nombreInterventions = 0,
    this.nombreConseils = 0,
    this.tauxPrecisionIA = 0.0,
  });

  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String regionCouverture;
  final SpecialiteExpert specialite;
  final int anneesExperience;
  final String? photoUrl;
  final bool notificationsActives;
  final int nombreDiagnosticsValides;
  final int nombreCorrections;
  final int nombreInterventions;
  final int nombreConseils;

  /// Taux de précision IA corrigée par l'expert (0.0 - 1.0)
  final double tauxPrecisionIA;

  String get nomComplet => '$prenom $nom';
  String get tauxPrecisionFormate => '${(tauxPrecisionIA * 100).toStringAsFixed(1)}%';

  @override
  List<Object?> get props => [id, email];
}
