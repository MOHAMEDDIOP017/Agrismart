import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/enums/statut_validation.dart';

/// Modèle d'une recommandation de culture par l'IA
class RecommandationModel extends Equatable {
  const RecommandationModel({
    required this.id,
    this.savedId,
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
    this.zoneAgroecologique,
    this.sourcesDonnees = const {},
    this.rang,
    this.statutValidation = StatutValidation.enAttente,
  });

  final String id;

  /// ID Firestore de la recommandation sauvegardée (null si non encore persisté)
  final String? savedId;
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

  /// Zone agroécologique de la parcelle (« Bassin arachidier »...), calculée
  /// côté serveur depuis la position du champ. Elle détermine les moyennes de
  /// référence appliquées quand une source externe ne répond pas.
  final String? zoneAgroecologique;

  /// Origine de chaque bloc de variables du modèle : mesure temps réel
  /// (SoilGrids, NASA POWER) ou moyenne de la zone agroécologique.
  ///
  /// Renvoyée au niveau de l'enveloppe de réponse et non par recommandation :
  /// les trois cultures d'un même top-3 partagent la même AnalyseParcelle,
  /// donc la même origine de données. Vide pour une recommandation relue
  /// depuis l'historique, où seule la zone est connue.
  final Map<String, String> sourcesDonnees;

  /// Place de la culture dans le top-k, telle que le moteur l'a décidée
  /// (`RecommandationCulture.rang` côté backend, 1 = la mieux adaptée).
  ///
  /// Distincte de la position dans la liste affichée : l'interface utilisait
  /// jusqu'ici l'index de rendu, qui coïncide tant que rien n'est trié ni
  /// filtré, mais divergerait en silence dès que ce serait le cas.
  final int? rang;

  /// Statut du cycle de validation par un expert. Une recommandation est
  /// produite EN_ATTENTE : l'agriculteur doit pouvoir distinguer une sortie
  /// brute du modèle d'une recommandation qu'un agronome a relue.
  final StatutValidation statutValidation;

  /// Nom wolof de la culture, ou `null` si elle ne figure pas dans la table.
  String? get nomWolof => AppConstants.nomsWolofCultures[culture];

  String get scoreLabel => '$scoreCompatibilite%';
  String get rendementLabel => '${rendementEstime.toStringAsFixed(1)} t/ha';
  String get besoinEauLabel => '$besoinEau mm/saison';
  String get prixLabel => '$prixMarcheEstime FCFA/kg';
  String get profitLabel => '$profitPotentiel FCFA/ha';

  /// Construit un RecommandationModel depuis une RecommandationCultureV2Response
  /// (moteur multi-label /recommandations/v2, diagramme UML) — même forme que
  /// [fromPrediction], mais le score vient de `probabiliteAptitude` (0-1,
  /// aptitude indépendante par culture) et l'id est le vrai id Firestore
  /// (nécessaire pour les actions de validation expert).
  factory RecommandationModel.fromPredictionV2(
    Map<String, dynamic> json,
    String champId,
    int index, {
    // Porté par l'enveloppe `ResultatRecommandationV2`, pas par chaque
    // recommandation : une seule AnalyseParcelle pour tout le top-3.
    Map<String, String> sourcesDonnees = const {},
  }) {
    final cultureNom = json['cultureNom'] as String;
    final probabiliteAptitude = (json['probabiliteAptitude'] as num).toDouble();
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
      id: json['id'] as String,
      savedId: json['id'] as String,
      champId: champId,
      culture: cultureNom,
      scoreCompatibilite: (probabiliteAptitude * 100).round(),
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
      zoneAgroecologique: json['zoneAgroecologique'] as String?,
      sourcesDonnees: sourcesDonnees,
      // Repli sur la position de rendu si le backend ne renvoie pas le rang.
      rang: (json['rang'] as num?)?.toInt() ?? index + 1,
      statutValidation: StatutValidation.fromString(
          (json['statutValidation'] as String?) ?? ''),
    );
  }

  /// Construit un RecommandationModel depuis une PredictionCulture retournée par le backend
  factory RecommandationModel.fromPrediction(
    Map<String, dynamic> json,
    String champId,
    int index, {
    String? savedId,
  }) {
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
      savedId: savedId,
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
  List<Object?> get props => [id, savedId, champId, culture];
}
