import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_constants.dart';

/// Modèle d'une recommandation de culture par l'IA
class RecommandationModel extends Equatable {
  const RecommandationModel({
    required this.id,
    required this.champId,
    required this.culture,
    required this.scoreCompatibilite,
    required this.periodeIdealePlantation,
    required this.rendementEstime,
    required this.besoinEau,
    required this.engAraisConseillesList,
    required this.maladiesFrequentes,
    required this.conseilsAgronomiques,
    required this.prixMarcheEstime,
    required this.profitPotentiel,
    this.imageUrl,
    required this.dateGeneree,
  });

  final String id;
  final String champId;
  final String culture;
  final int scoreCompatibilite;
  final String periodeIdealePlantation;
  final double rendementEstime;
  final int besoinEau;
  final List<String> engAraisConseillesList;
  final List<String> maladiesFrequentes;
  final String conseilsAgronomiques;
  final int prixMarcheEstime;
  final int profitPotentiel;
  final String? imageUrl;
  final DateTime dateGeneree;

  String get scoreLabel => '$scoreCompatibilite%';
  String get rendementLabel => '${rendementEstime.toStringAsFixed(1)} t/ha';
  String get besoinEauLabel => '$besoinEau mm/saison';
  String get prixLabel => '$prixMarcheEstime FCFA/kg';
  String get profitLabel => '$profitPotentiel FCFA/ha';

  /// Construit un RecommandationModel depuis une PredictionCulture retournée par le backend
  factory RecommandationModel.fromPrediction(
    Map<String, dynamic> json,
    String champId,
    int index,
  ) {
    final cultureNom = json['cultureNom'] as String;
    final score = (json['score'] as num).toDouble();
    final rendement = (json['rendementEstime'] as num).toDouble();
    final prix = (json['prixMarcheEstime'] as num?)?.toInt() ?? 200;
    final eau = (json['besoinEauMm'] as num?)?.toInt() ?? 400;

    final engrais = (json['engraisConseilles'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    final maladies = (json['maladiesFrequentes'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    return RecommandationModel(
      id: 'reco_${DateTime.now().millisecondsSinceEpoch}_$index',
      champId: champId,
      culture: cultureNom,
      scoreCompatibilite: (score * 100).round(),
      periodeIdealePlantation: json['periodePlantation'] as String,
      rendementEstime: rendement,
      besoinEau: eau,
      engAraisConseillesList: engrais,
      maladiesFrequentes: maladies,
      conseilsAgronomiques: json['conseil'] as String,
      prixMarcheEstime: prix,
      profitPotentiel: (rendement * 1000 * prix).round(),
      imageUrl: AppConstants.imagesCultures[cultureNom],
      dateGeneree: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, champId, culture];
}
