import '../../domain/entities/champ_entity.dart';

/// Modèle de données champ avec sérialisation JSON
class ChampModel extends ChampEntity {
  const ChampModel({
    required super.id,
    required super.nom,
    required super.superficie,
    required super.typeSol,
    required super.statut,
    super.culture,
    super.latitude,
    super.longitude,
    super.photoUrl,
    super.ph,
    super.azote,
    super.phosphore,
    super.potassium,
    super.humidite,
    required super.dateCreation,
    super.dateModification,
    super.userId,
  });

  factory ChampModel.fromJson(Map<String, dynamic> json) => ChampModel(
        id: (json['id'] as String?) ?? '',
        nom: json['nom'] as String,
        superficie: (json['superficie'] as num).toDouble(),
        // backend camelCase (typeSol) ou ancien snake_case (type_sol)
        typeSol: (json['typeSol'] ?? json['type_sol'] ?? 'Non spécifié') as String,
        statut: (json['statut'] as String?) ?? 'EN_COURS',
        culture: json['culture'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        photoUrl: (json['photoUrl'] ?? json['photo_url']) as String?,
        ph: (json['ph'] as num?)?.toDouble(),
        azote: (json['azote'] as num?)?.toDouble(),
        phosphore: (json['phosphore'] as num?)?.toDouble(),
        potassium: (json['potassium'] as num?)?.toDouble(),
        humidite: (json['humidite'] as num?)?.toDouble(),
        dateCreation: json['dateCreation'] != null
            ? DateTime.parse(json['dateCreation'] as String)
            : json['date_creation'] != null
                ? DateTime.parse(json['date_creation'] as String)
                : DateTime.now(),
        dateModification: (json['dateModification'] ?? json['date_modification']) != null
            ? DateTime.parse(
                (json['dateModification'] ?? json['date_modification']) as String)
            : null,
        userId: (json['agriculteurId'] ?? json['user_id']) as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'superficie': superficie,
        'type_sol': typeSol,
        'statut': statut,
        'culture': culture,
        'latitude': latitude,
        'longitude': longitude,
        'photo_url': photoUrl,
        'ph': ph,
        'azote': azote,
        'phosphore': phosphore,
        'potassium': potassium,
        'humidite': humidite,
        'date_creation': dateCreation.toIso8601String(),
        'date_modification': dateModification?.toIso8601String(),
        'user_id': userId,
      };

  // Format attendu par le backend (POST /champs)
  Map<String, dynamic> toCreateJson() => {
        'nom': nom,
        'superficie': superficie,
        'typeSol': typeSol,
        'latitude': latitude ?? 14.6937,
        'longitude': longitude ?? -17.4441,
        'adresse': 'Sénégal',
        if (culture != null) 'commentaire': culture,
      };

  ChampModel copyWith({
    String? nom,
    double? superficie,
    String? typeSol,
    String? statut,
    String? culture,
    double? latitude,
    double? longitude,
    String? photoUrl,
    double? ph,
    double? azote,
    double? phosphore,
    double? potassium,
    double? humidite,
  }) =>
      ChampModel(
        id: id,
        nom: nom ?? this.nom,
        superficie: superficie ?? this.superficie,
        typeSol: typeSol ?? this.typeSol,
        statut: statut ?? this.statut,
        culture: culture ?? this.culture,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        photoUrl: photoUrl ?? this.photoUrl,
        ph: ph ?? this.ph,
        azote: azote ?? this.azote,
        phosphore: phosphore ?? this.phosphore,
        potassium: potassium ?? this.potassium,
        humidite: humidite ?? this.humidite,
        dateCreation: dateCreation,
        dateModification: DateTime.now(),
        userId: userId,
      );
}
