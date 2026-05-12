import '../../domain/entities/user_entity.dart';

/// Modèle de données utilisateur (sérialisation JSON)
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.telephone,
    super.zoneGeographique,
    super.role,
    super.photoUrl,
    super.nombreChamps,
    super.nombreDiagnostics,
    super.nombreRecommandations,
    super.nombreEvaluations,
    super.notificationsActives,
    super.actif,
    super.dateInscription,
    // Agriculteur
    super.adresse,
    super.villageVille,
    // Expert
    super.regionCouverture,
    super.specialite,
    super.anneesExperience,
    super.nbDiagnosticsValides,
    super.tauxPrecisionValidee,
    // Admin
    super.niveauAcces,
    super.dateCreation,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final entity = UserEntity.fromJson(json);
    return UserModel(
      id: entity.id,
      nom: entity.nom,
      prenom: entity.prenom,
      email: entity.email,
      telephone: entity.telephone,
      zoneGeographique: entity.zoneGeographique,
      role: entity.role,
      photoUrl: entity.photoUrl,
      nombreChamps: entity.nombreChamps,
      nombreDiagnostics: entity.nombreDiagnostics,
      nombreRecommandations: entity.nombreRecommandations,
      nombreEvaluations: entity.nombreEvaluations,
      notificationsActives: entity.notificationsActives,
      actif: entity.actif,
      dateInscription: entity.dateInscription,
      adresse: entity.adresse,
      villageVille: entity.villageVille,
      regionCouverture: entity.regionCouverture,
      specialite: entity.specialite,
      anneesExperience: entity.anneesExperience,
      nbDiagnosticsValides: entity.nbDiagnosticsValides,
      tauxPrecisionValidee: entity.tauxPrecisionValidee,
      niveauAcces: entity.niveauAcces,
      dateCreation: entity.dateCreation,
    );
  }

  /// Construit depuis la réponse du backend (alias de fromJson avec tolérance).
  factory UserModel.fromBackendJson(Map<String, dynamic> json) =>
      UserModel.fromJson(json);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
        'zone_geographique': zoneGeographique,
        'role': role.toJson(),
        'photo_url': photoUrl,
        'nombre_champs': nombreChamps,
        'nombre_diagnostics': nombreDiagnostics,
        'nombre_recommandations': nombreRecommandations,
        'nombre_evaluations': nombreEvaluations,
        'notifications_actives': notificationsActives,
        'actif': actif,
        if (dateInscription != null)
          'date_inscription': dateInscription!.toIso8601String(),
        if (adresse != null) 'adresse': adresse,
        if (villageVille != null) 'village_ville': villageVille,
        if (regionCouverture != null) 'region_couverture': regionCouverture,
        if (specialite != null) 'specialite': specialite,
        if (anneesExperience != null) 'annees_experience': anneesExperience,
        if (niveauAcces != null) 'niveau_acces': niveauAcces,
        if (dateCreation != null)
          'date_creation': dateCreation!.toIso8601String(),
      };

  UserModel copyWith({
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? zoneGeographique,
    RoleUtilisateur? role,
    String? photoUrl,
    bool? notificationsActives,
    bool? actif,
    int? nombreChamps,
    int? nombreDiagnostics,
    int? nombreRecommandations,
    int? nombreEvaluations,
    String? adresse,
    String? villageVille,
    String? regionCouverture,
    String? specialite,
    int? anneesExperience,
    int? niveauAcces,
  }) =>
      UserModel(
        id: id,
        nom: nom ?? this.nom,
        prenom: prenom ?? this.prenom,
        email: email ?? this.email,
        telephone: telephone ?? this.telephone,
        zoneGeographique: zoneGeographique ?? this.zoneGeographique,
        role: role ?? this.role,
        photoUrl: photoUrl ?? this.photoUrl,
        notificationsActives: notificationsActives ?? this.notificationsActives,
        actif: actif ?? this.actif,
        dateInscription: dateInscription,
        nombreChamps: nombreChamps ?? this.nombreChamps,
        nombreDiagnostics: nombreDiagnostics ?? this.nombreDiagnostics,
        nombreRecommandations:
            nombreRecommandations ?? this.nombreRecommandations,
        nombreEvaluations: nombreEvaluations ?? this.nombreEvaluations,
        adresse: adresse ?? this.adresse,
        villageVille: villageVille ?? this.villageVille,
        regionCouverture: regionCouverture ?? this.regionCouverture,
        specialite: specialite ?? this.specialite,
        anneesExperience: anneesExperience ?? this.anneesExperience,
        nbDiagnosticsValides: nbDiagnosticsValides,
        tauxPrecisionValidee: tauxPrecisionValidee,
        niveauAcces: niveauAcces ?? this.niveauAcces,
        dateCreation: dateCreation,
      );
}
