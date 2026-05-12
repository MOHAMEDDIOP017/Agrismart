import 'package:equatable/equatable.dart';
import 'maladie_entity.dart';

/// Entité représentant une prédiction du modèle IA pour une maladie
class PredictionEntity extends Equatable {
  const PredictionEntity({
    required this.maladie,
    required this.score,
    required this.rang,
  });

  final MaladieEntity maladie;
  final double score;
  final int rang;

  String get scoreFormate => '${(score * 100).toStringAsFixed(1)}%';
  int get scorePourcent => (score * 100).round();

  @override
  List<Object?> get props => [maladie.id, score, rang];
}
