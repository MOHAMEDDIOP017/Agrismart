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
  final int nombreCorrections;
  final int nombreInterventions;
  final int nombreConseils;

  /// Taux de précision IA corrigée par l'expert (0.0 - 1.0)
  final double tauxPrecisionIA;

  String get nomComplet => '$prenom $nom';
  String get tauxPrecisionFormate =>
      '${(tauxPrecisionIA * 100).toStringAsFixed(1)}%';

  ExpertEntity copyWith({
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? regionCouverture,
    SpecialiteExpert? specialite,
    int? anneesExperience,
    String? photoUrl,
    bool? notificationsActives,
  }) =>
      ExpertEntity(
        id: id,
        nom: nom ?? this.nom,
        prenom: prenom ?? this.prenom,
        email: email ?? this.email,
        telephone: telephone ?? this.telephone,
        regionCouverture: regionCouverture ?? this.regionCouverture,
        specialite: specialite ?? this.specialite,
        anneesExperience: anneesExperience ?? this.anneesExperience,
        photoUrl: photoUrl ?? this.photoUrl,
        notificationsActives: notificationsActives ?? this.notificationsActives,
        nombreCorrections: nombreCorrections,
        nombreInterventions: nombreInterventions,
        nombreConseils: nombreConseils,
        tauxPrecisionIA: tauxPrecisionIA,
      );

  @override
  List<Object?> get props => [id, email];
}
