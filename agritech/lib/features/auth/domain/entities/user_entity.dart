import 'package:equatable/equatable.dart';

/// Rôles disponibles dans l'application
enum RoleUtilisateur {
  agriculteur,
  expert,
  admin;

  String get libelle {
    switch (this) {
      case RoleUtilisateur.agriculteur:
        return 'Agriculteur';
      case RoleUtilisateur.expert:
        return 'Expert Agronome';
      case RoleUtilisateur.admin:
        return 'Administrateur';
    }
  }

  String get description {
    switch (this) {
      case RoleUtilisateur.agriculteur:
        return 'Gère ses champs, consulte des recommandations';
      case RoleUtilisateur.expert:
        return 'Supervise les champs, conseille les agriculteurs, valide les recommandations';
      case RoleUtilisateur.admin:
        return 'Gère les utilisateurs, consulte les statistiques globales';
    }
  }

  static RoleUtilisateur fromString(String value) {
    switch (value.toUpperCase()) {
      case 'EXPERT':
        return RoleUtilisateur.expert;
      case 'ADMIN':
        return RoleUtilisateur.admin;
      default:
        return RoleUtilisateur.agriculteur;
    }
  }

  String toJson() => name.toUpperCase();
}

/// Entité utilisateur — tous rôles (attributs communs + spécifiques optionnels)
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    this.zoneGeographique = '',
    this.role = RoleUtilisateur.agriculteur,
    this.photoUrl,
    this.nombreChamps = 0,
    this.nombreRecommandations = 0,
    this.nombreEvaluations = 0,
    this.notificationsActives = true,
    this.actif = true,
    this.dateInscription,
    // Agriculteur
    this.adresse,
    this.villageVille,
    // Expert
    this.regionCouverture,
    this.specialite,
    this.anneesExperience,
    // Admin
    this.niveauAcces,
    this.dateCreation,
  });

  // ── Attributs communs ────────────────────────────────────────────────────
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String zoneGeographique;
  final RoleUtilisateur role;
  final String? photoUrl;
  final int nombreChamps;
  final int nombreRecommandations;
  final int nombreEvaluations;
  final bool notificationsActives;
  final bool actif;
  final DateTime? dateInscription;

  // ── Attributs Agriculteur ────────────────────────────────────────────────
  final String? adresse;
  final String? villageVille;

  // ── Attributs Expert ────────────────────────────────────────────────────
  final String? regionCouverture;
  final String? specialite;
  final int? anneesExperience;

  // ── Attributs Admin ─────────────────────────────────────────────────────
  final int? niveauAcces;
  final DateTime? dateCreation;

  // ── Accesseurs ──────────────────────────────────────────────────────────
  String get nomComplet => '$prenom $nom';
  bool get estExpert => role == RoleUtilisateur.expert;
  bool get estAgriculteur => role == RoleUtilisateur.agriculteur;
  bool get estAdmin => role == RoleUtilisateur.admin;

  /// Route d'accueil selon le rôle de l'utilisateur
  String get routeHome {
    switch (role) {
      case RoleUtilisateur.admin:
        return '/admin/dashboard';
      case RoleUtilisateur.expert:
        // La file de validation, et non l'ancien tableau de bord : c'est la
        // tâche première du rôle, et elle n'avait aucune entrée de navigation.
        return '/expert/recommandations';
      case RoleUtilisateur.agriculteur:
        return '/home/dashboard';
    }
  }

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: (json['id'] ?? json['uid'] ?? '') as String,
      nom: (json['nom'] ?? '') as String,
      prenom: (json['prenom'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      telephone: (json['telephone'] ?? '') as String,
      zoneGeographique: (json['zone_geographique'] ??
          json['zoneGeographique'] ??
          '') as String,
      role:
          RoleUtilisateur.fromString(json['role'] as String? ?? 'AGRICULTEUR'),
      photoUrl: json['photo_url'] as String?,
      actif: json['actif'] as bool? ?? true,
      dateInscription:
          _parseDate(json['date_inscription'] ?? json['dateInscription']),
      // Agriculteur
      adresse: json['adresse'] as String?,
      villageVille: (json['village_ville'] ?? json['villageVille']) as String?,
      // Expert
      regionCouverture:
          (json['region_couverture'] ?? json['regionCouverture']) as String?,
      specialite: json['specialite'] as String?,
      anneesExperience:
          (json['annees_experience'] ?? json['anneesExperience']) as int?,
      // Admin
      niveauAcces: (json['niveau_acces'] ?? json['niveauAcces']) as int?,
      dateCreation: _parseDate(json['date_creation'] ?? json['dateCreation']),
      // Statistiques
      nombreChamps: json['nombre_champs'] as int? ?? 0,
      nombreRecommandations: json['nombre_recommandations'] as int? ?? 0,
      nombreEvaluations: json['nombre_evaluations'] as int? ?? 0,
      notificationsActives: json['notifications_actives'] as bool? ?? true,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  @override
  List<Object?> get props => [id, email, telephone, role];
}
