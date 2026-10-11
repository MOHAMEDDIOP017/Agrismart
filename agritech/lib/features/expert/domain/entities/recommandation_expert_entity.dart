import 'package:equatable/equatable.dart';

/// Score d'une culture dans le top recommandations IA
class CultureScoreEntity extends Equatable {
  const CultureScoreEntity({
    required this.nom,
    required this.score,
    required this.rang,
    this.rendementEstime,
    this.periodeIdealePlantation,
  });

  final String nom;

  /// Score de compatibilité 0.0-1.0
  final double score;
  final int rang;
  final double? rendementEstime;
  final String? periodeIdealePlantation;

  String get scoreLabel => '${(score * 100).round()}%';
  String get rendementLabel => rendementEstime != null
      ? '${rendementEstime!.toStringAsFixed(1)} t/ha'
      : '—';

  @override
  List<Object?> get props => [nom, rang];
}

/// Snapshot des données agronomiques au moment de la recommandation
class SnapshotAgronomique extends Equatable {
  const SnapshotAgronomique({
    this.azote,
    this.phosphore,
    this.potassium,
    this.ph,
    this.humidite,
    this.temperature,
    this.pluviometrie,
    this.typeSol,
  });

  final double? azote;
  final double? phosphore;
  final double? potassium;
  final double? ph;
  final double? humidite;
  final double? temperature;
  final double? pluviometrie;
  final String? typeSol;

  @override
  List<Object?> get props =>
      [azote, phosphore, potassium, ph, humidite, temperature, pluviometrie];
}

/// Entité d'une recommandation culture soumise à l'expert pour validation
class RecommandationExpertEntity extends Equatable {
  const RecommandationExpertEntity({
    required this.id,
    required this.champId,
    required this.champNom,
    required this.champRegion,
    required this.agriculteurId,
    required this.agriculteurNom,
    required this.agriculteurTelephone,
    required this.top3Cultures,
    required this.snapshot,
    required this.statutValidation,
    required this.dateGeneree,
    this.expertId,
    this.commentaireExpert,
    this.cultureCorrigee,
    this.dateValidation,
    this.modeleIAVersion,
  });

  final String id;
  final String champId;
  final String champNom;
  final String champRegion;
  final String agriculteurId;
  final String agriculteurNom;
  final String agriculteurTelephone;

  /// Top 3 cultures recommandées par l'IA (triées par score décroissant)
  final List<CultureScoreEntity> top3Cultures;

  /// Données d'entrée utilisées pour la recommandation
  final SnapshotAgronomique snapshot;

  /// EN_ATTENTE | VALIDEE | CORRIGEE | REJETEE
  final String statutValidation;

  final DateTime dateGeneree;
  final String? expertId;
  final String? commentaireExpert;

  /// Culture corrigée par l'expert (uniquement si statutValidation == CORRIGEE)
  final String? cultureCorrigee;
  final DateTime? dateValidation;
  final String? modeleIAVersion;

  // ── Accesseurs ──────────────────────────────────────────────────────────────

  CultureScoreEntity? get premiereCulture =>
      top3Cultures.isNotEmpty ? top3Cultures.first : null;

  bool get estEnAttente => statutValidation == 'EN_ATTENTE';
  bool get estValidee => statutValidation == 'VALIDEE';
  bool get estCorrigee => statutValidation == 'CORRIGEE';
  bool get estRejetee => statutValidation == 'REJETEE';

  String get statutLibelle => switch (statutValidation) {
        'EN_ATTENTE' => 'En attente',
        'VALIDEE' => 'Validée',
        'CORRIGEE' => 'Corrigée',
        'REJETEE' => 'Rejetée',
        _ => statutValidation,
      };

  String get tempsEcoule {
    final diff = DateTime.now().difference(dateGeneree);
    if (diff.inDays > 0) return 'il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inMinutes} min';
  }

  RecommandationExpertEntity copyWith({
    String? statutValidation,
    String? expertId,
    String? commentaireExpert,
    String? cultureCorrigee,
    DateTime? dateValidation,
  }) =>
      RecommandationExpertEntity(
        id: id,
        champId: champId,
        champNom: champNom,
        champRegion: champRegion,
        agriculteurId: agriculteurId,
        agriculteurNom: agriculteurNom,
        agriculteurTelephone: agriculteurTelephone,
        top3Cultures: top3Cultures,
        snapshot: snapshot,
        statutValidation: statutValidation ?? this.statutValidation,
        dateGeneree: dateGeneree,
        expertId: expertId ?? this.expertId,
        commentaireExpert: commentaireExpert ?? this.commentaireExpert,
        cultureCorrigee: cultureCorrigee ?? this.cultureCorrigee,
        dateValidation: dateValidation ?? this.dateValidation,
        modeleIAVersion: modeleIAVersion,
      );

  @override
  List<Object?> get props => [id, statutValidation];
}
