import 'package:equatable/equatable.dart';

/// Entité représentant un champ agricole.
///
/// Ne porte que ce qui décrit la parcelle telle que l'exploitant la déclare :
/// identité, superficie, type de sol, position, photo, état courant.
///
/// Les variables agronomiques (pH, azote, phosphore, potassium) et climatiques
/// (humidité) en ont été retirées : elles ne sont plus saisies par
/// l'agriculteur mais collectées automatiquement côté serveur (SoilGrids,
/// NASA POWER) à chaque génération de recommandation, et persistées dans
/// `AnalyseParcelle` — une mesure datée, pas un attribut de la parcelle.
class ChampEntity extends Equatable {
  const ChampEntity({
    required this.id,
    required this.nom,
    required this.superficie,
    required this.typeSol,
    required this.adresse,
    required this.statut,
    this.culture,
    this.latitude,
    this.longitude,
    this.photoUrl,
    required this.dateCreation,
    this.dateModification,
    this.userId,
  });

  final String id;
  final String nom;
  final double superficie;
  final String typeSol;

  /// Adresse en clair de la parcelle (commune, village, repère local).
  ///
  /// Obligatoire, comme côté serveur (`ChampBase.adresse`). Jusqu'ici absente
  /// de l'entité, ce qui conduisait le client à envoyer « Sénégal » en dur
  /// pour tout champ créé depuis l'application : une valeur inventée, que
  /// l'agriculteur n'avait aucun moyen de corriger.
  ///
  /// À ne pas confondre avec (latitude, longitude), qui sert au moteur de
  /// recommandation : l'adresse est destinée à l'humain qui doit retrouver
  /// la parcelle, les coordonnées au calcul.
  final String adresse;

  final String statut;
  final String? culture;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final DateTime dateCreation;
  final DateTime? dateModification;
  final String? userId;

  String get superficieFormatee => '${superficie.toStringAsFixed(2)} ha';

  String get localisation => (latitude != null && longitude != null)
      ? '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}'
      : 'Position non définie';

  @override
  List<Object?> get props => [id, nom, superficie, statut];
}
