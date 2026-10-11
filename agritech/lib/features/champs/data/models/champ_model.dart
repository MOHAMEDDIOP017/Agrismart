import '../../domain/entities/champ_entity.dart';

/// Modèle de données champ avec sérialisation JSON
class ChampModel extends ChampEntity {
  const ChampModel({
    required super.id,
    required super.nom,
    required super.superficie,
    required super.typeSol,
    required super.adresse,
    required super.statut,
    super.culture,
    super.latitude,
    super.longitude,
    super.photoUrl,
    required super.dateCreation,
    super.dateModification,
    super.userId,
  });

  factory ChampModel.fromJson(Map<String, dynamic> json) => ChampModel(
        id: (json['id'] as String?) ?? '',
        nom: json['nom'] as String,
        superficie: (json['superficie'] as num).toDouble(),
        // backend camelCase (typeSol) ou ancien snake_case (type_sol)
        typeSol:
            (json['typeSol'] ?? json['type_sol'] ?? 'Non spécifié') as String,
        // Repli sur une chaîne vide : un document ancien sans adresse doit
        // rester lisible et modifiable, pas faire échouer la liste entière.
        adresse: (json['adresse'] as String?) ?? '',
        statut: (json['statut'] as String?) ?? 'EN_COURS',
        culture: json['culture'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        photoUrl: (json['photoUrl'] ?? json['photo_url']) as String?,
        // Les anciens documents Firestore peuvent encore porter ph, azote,
        // phosphore, potassium et humidite : ces cles ne sont plus lues, donc
        // simplement ignorees. Aucune migration de donnees n'est necessaire.
        dateCreation: json['dateCreation'] != null
            ? DateTime.parse(json['dateCreation'] as String)
            : json['date_creation'] != null
                ? DateTime.parse(json['date_creation'] as String)
                : DateTime.now(),
        dateModification:
            (json['dateModification'] ?? json['date_modification']) != null
                ? DateTime.parse((json['dateModification'] ??
                    json['date_modification']) as String)
                : null,
        userId: (json['agriculteurId'] ?? json['user_id']) as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'superficie': superficie,
        'type_sol': typeSol,
        'adresse': adresse,
        'statut': statut,
        'culture': culture,
        'latitude': latitude,
        'longitude': longitude,
        'photo_url': photoUrl,
        'date_creation': dateCreation.toIso8601String(),
        'date_modification': dateModification?.toIso8601String(),
        'user_id': userId,
      };

  /// Format attendu par le backend (POST et PUT /champs).
  ///
  /// `adresse` était auparavant codée en dur à « Sénégal » pour tous les
  /// champs, et `culture` était détournée vers `commentaire` — deux valeurs
  /// que le serveur enregistrait sans que personne ne les relise. L'adresse
  /// est désormais celle que saisit l'agriculteur.
  ///
  /// `culture` n'est volontairement plus transmise : le modèle `Champ` du
  /// backend ne la déclare pas, et l'y glisser sous le nom `commentaire`
  /// revenait à perdre l'information (elle était écrite dans un champ que le
  /// client relit sous un autre nom, donc toujours nulle à l'affichage).
  Map<String, dynamic> toCreateJson() => {
        'nom': nom,
        'superficie': superficie,
        'typeSol': typeSol,
        'latitude': latitude ?? 14.6937,
        'longitude': longitude ?? -17.4441,
        'adresse': adresse,
      };

  ChampModel copyWith({
    String? nom,
    double? superficie,
    String? typeSol,
    String? adresse,
    String? statut,
    String? culture,
    double? latitude,
    double? longitude,
    String? photoUrl,
  }) =>
      ChampModel(
        id: id,
        nom: nom ?? this.nom,
        superficie: superficie ?? this.superficie,
        typeSol: typeSol ?? this.typeSol,
        adresse: adresse ?? this.adresse,
        statut: statut ?? this.statut,
        culture: culture ?? this.culture,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        photoUrl: photoUrl ?? this.photoUrl,
        dateCreation: dateCreation,
        dateModification: DateTime.now(),
        userId: userId,
      );
}
