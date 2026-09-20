import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../enums/statut_utilisateur.dart';

/// Entité utilisateur enrichie pour la gestion Admin
class UtilisateurAdminEntity extends Equatable {
  const UtilisateurAdminEntity({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.role,
    required this.statut,
    required this.region,
    required this.dateInscription,
    this.ville,
    this.photoUrl,
    this.specialite,
    this.anneesExperience,
    this.niveauAcces,
    this.nombreChamps = 0,
    this.nombreInterventions = 0,
  });

  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final RoleUtilisateur role;
  final StatutUtilisateur statut;
  final String region;
  final DateTime dateInscription;
  final String? ville;
  final String? photoUrl;
  /// Spécialité — uniquement pour les experts
  final String? specialite;
  /// Années d'expérience — uniquement pour les experts
  final int? anneesExperience;
  /// Niveau d'accès 1-3 — uniquement pour les admins
  final int? niveauAcces;
  final int nombreChamps;
  final int nombreInterventions;

  String get nomComplet => '$prenom $nom';

  bool get estActif => statut == StatutUtilisateur.actif;
  bool get estSuspendu => statut == StatutUtilisateur.suspendu;

  UtilisateurAdminEntity copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    RoleUtilisateur? role,
    StatutUtilisateur? statut,
    String? region,
    DateTime? dateInscription,
    String? ville,
    String? photoUrl,
    String? specialite,
    int? anneesExperience,
    int? niveauAcces,
    int? nombreChamps,
    int? nombreInterventions,
  }) {
    return UtilisateurAdminEntity(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      role: role ?? this.role,
      statut: statut ?? this.statut,
      region: region ?? this.region,
      dateInscription: dateInscription ?? this.dateInscription,
      ville: ville ?? this.ville,
      photoUrl: photoUrl ?? this.photoUrl,
      specialite: specialite ?? this.specialite,
      anneesExperience: anneesExperience ?? this.anneesExperience,
      niveauAcces: niveauAcces ?? this.niveauAcces,
      nombreChamps: nombreChamps ?? this.nombreChamps,
      nombreInterventions: nombreInterventions ?? this.nombreInterventions,
    );
  }

  @override
  List<Object?> get props => [id, email, statut];
}
