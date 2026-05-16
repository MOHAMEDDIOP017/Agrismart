import 'package:equatable/equatable.dart';
import '../enums/statut_validation.dart';
import 'maladie_entity.dart';
import 'prediction_entity.dart';

/// Entité centrale représentant un diagnostic de maladie
class DiagnosticEntity extends Equatable {
  const DiagnosticEntity({
    required this.id,
    required this.maladieDetectee,
    required this.scoreConfiance,
    required this.topPredictions,
    required this.dateAnalyse,
    required this.modeleVersion,
    required this.tempsAnalyseMs,
    this.champId,
    this.champNom,
    this.imageLocalPath,
    this.statut = StatutValidation.enAttente,
    this.evaluationUtilisateur,
    this.commentaireEvaluation,
    this.expertNom,
  });

  final String id;
  final MaladieEntity maladieDetectee;
  final double scoreConfiance;
  final List<PredictionEntity> topPredictions;
  final DateTime dateAnalyse;
  final String modeleVersion;
  final int tempsAnalyseMs;
  final String? champId;
  final String? champNom;
  final String? imageLocalPath;
  final StatutValidation statut;
  final String? evaluationUtilisateur;
  final String? commentaireEvaluation;
  final String? expertNom;

  String get scoreConfianseFormate => '${(scoreConfiance * 100).toStringAsFixed(0)}%';
  int get scoreConfiancePourcent => (scoreConfiance * 100).round();
  String get tempsAnalyseFormate => '${(tempsAnalyseMs / 1000).toStringAsFixed(1)} secondes';

  bool get estFiable => scoreConfiance >= 0.75;
  bool get estIncertain => scoreConfiance < 0.50;

  /// Vrai si le diagnostic existe réellement en base (ID non généré localement par le fallback mock).
  bool get estSauvegarde => !id.startsWith('diag_');

  @override
  List<Object?> get props => [id, dateAnalyse];
}
