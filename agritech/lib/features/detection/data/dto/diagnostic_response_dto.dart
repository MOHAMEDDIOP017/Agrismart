import '../../domain/entities/diagnostic_entity.dart';
import '../../domain/entities/prediction_entity.dart';
import '../../domain/entities/maladie_entity.dart';
import '../../domain/entities/traitement_entity.dart';
import '../../domain/enums/niveau_gravite.dart';
import '../../domain/enums/type_traitement.dart';
import '../../domain/enums/statut_validation.dart';

/// DTO de la réponse complète du modèle IA de détection
class DiagnosticResponseDto {
  const DiagnosticResponseDto({
    required this.diagnosticId,
    required this.maladieDetectee,
    required this.scoreConfiance,
    required this.topPredictions,
    required this.dateAnalyse,
    required this.modeleVersion,
    required this.tempsAnalyseMs,
    this.champId,
  });

  final String diagnosticId;
  final MaladieDto maladieDetectee;
  final double scoreConfiance;
  final List<PredictionDto> topPredictions;
  final DateTime dateAnalyse;
  final String modeleVersion;
  final int tempsAnalyseMs;
  final String? champId;

  factory DiagnosticResponseDto.fromJson(Map<String, dynamic> json) {
    return DiagnosticResponseDto(
      diagnosticId: json['diagnostic_id'] as String,
      maladieDetectee: MaladieDto.fromJson(
          json['maladie_detectee'] as Map<String, dynamic>),
      scoreConfiance: (json['score_confiance'] as num).toDouble(),
      topPredictions: (json['top_predictions'] as List)
          .map((e) => PredictionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      dateAnalyse: DateTime.parse(json['date_analyse'] as String),
      modeleVersion: json['modele_version'] as String,
      tempsAnalyseMs: json['temps_analyse_ms'] as int,
      champId: json['champ_id'] as String?,
    );
  }

  /// Convertit le DTO en entité métier
  DiagnosticEntity toEntity({String? champNom, String? imageLocalPath}) {
    return DiagnosticEntity(
      id: diagnosticId,
      maladieDetectee: maladieDetectee.toEntity(),
      scoreConfiance: scoreConfiance,
      topPredictions: topPredictions.map((p) => p.toEntity()).toList(),
      dateAnalyse: dateAnalyse,
      modeleVersion: modeleVersion,
      tempsAnalyseMs: tempsAnalyseMs,
      champId: champId,
      champNom: champNom,
      imageLocalPath: imageLocalPath,
      statut: StatutValidation.enAttente,
    );
  }
}

/// DTO d'une maladie retournée par l'API
class MaladieDto {
  const MaladieDto({
    required this.id,
    required this.nom,
    required this.nomScientifique,
    required this.description,
    required this.symptomes,
    required this.gravite,
    required this.culturesAffectees,
    this.traitements = const [],
    this.agentPathogene,
    this.conditionsFavorables,
  });

  final String id;
  final String nom;
  final String nomScientifique;
  final String description;
  final List<String> symptomes;
  final NiveauGravite gravite;
  final List<String> culturesAffectees;
  final List<TraitementDto> traitements;
  final String? agentPathogene;
  final String? conditionsFavorables;

  factory MaladieDto.fromJson(Map<String, dynamic> json) {
    return MaladieDto(
      id: json['id'] as String,
      nom: json['nom'] as String,
      nomScientifique: json['nom_scientifique'] as String,
      description: json['description'] as String,
      symptomes: List<String>.from(json['symptomes'] as List),
      gravite: NiveauGravite.fromString(json['gravite'] as String),
      culturesAffectees:
          List<String>.from(json['cultures_affectees'] as List),
      traitements: json['traitements'] != null
          ? (json['traitements'] as List)
              .map((e) => TraitementDto.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      agentPathogene: json['agent_pathogene'] as String?,
      conditionsFavorables: json['conditions_favorables'] as String?,
    );
  }

  MaladieEntity toEntity() {
    return MaladieEntity(
      id: id,
      nom: nom,
      nomScientifique: nomScientifique,
      description: description,
      symptomes: symptomes,
      gravite: gravite,
      culturesAffectees: culturesAffectees,
      traitements: traitements.map((t) => t.toEntity()).toList(),
      agentPathogene: agentPathogene,
      conditionsFavorables: conditionsFavorables,
    );
  }
}

/// DTO d'une prédiction individuelle du modèle
class PredictionDto {
  const PredictionDto({
    required this.maladie,
    required this.score,
    required this.rang,
  });

  final MaladieDto maladie;
  final double score;
  final int rang;

  factory PredictionDto.fromJson(Map<String, dynamic> json) {
    return PredictionDto(
      maladie: MaladieDto.fromJson(json['maladie'] as Map<String, dynamic>),
      score: (json['score'] as num).toDouble(),
      rang: json['rang'] as int,
    );
  }

  PredictionEntity toEntity() {
    return PredictionEntity(
      maladie: maladie.toEntity(),
      score: score,
      rang: rang,
    );
  }
}

/// DTO d'un traitement recommandé
class TraitementDto {
  const TraitementDto({
    required this.id,
    required this.nomProduit,
    required this.dosage,
    required this.frequenceApplication,
    required this.dureeDays,
    required this.type,
    required this.coutFcfa,
    this.instructionsDetaillees,
    this.precautions,
  });

  final String id;
  final String nomProduit;
  final String dosage;
  final String frequenceApplication;
  final int dureeDays;
  final TypeTraitement type;
  final int coutFcfa;
  final String? instructionsDetaillees;
  final String? precautions;

  factory TraitementDto.fromJson(Map<String, dynamic> json) {
    return TraitementDto(
      id: json['id'] as String,
      nomProduit: json['nom_produit'] as String,
      dosage: json['dosage'] as String,
      frequenceApplication: json['frequence_application'] as String,
      dureeDays: json['duree_days'] as int,
      type: TypeTraitement.fromString(json['type'] as String),
      coutFcfa: json['cout_fcfa'] as int,
      instructionsDetaillees: json['instructions_detaillees'] as String?,
      precautions: json['precautions'] as String?,
    );
  }

  TraitementEntity toEntity() {
    return TraitementEntity(
      id: id,
      nomProduit: nomProduit,
      dosage: dosage,
      frequenceApplication: frequenceApplication,
      dureeDays: dureeDays,
      type: type,
      coutFcfa: coutFcfa,
      instructionsDetaillees: instructionsDetaillees,
      precautions: precautions,
    );
  }
}
