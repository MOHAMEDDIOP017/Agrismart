import 'package:equatable/equatable.dart';
import '../../../detection/domain/entities/maladie_entity.dart';
import '../../../detection/domain/entities/prediction_entity.dart';
import '../../../detection/domain/enums/niveau_gravite.dart';
import '../../../detection/domain/enums/statut_validation.dart';
import '../enums/decision_expert.dart';
import '../../../detection/domain/enums/type_traitement.dart';

/// Entité étendue d'un diagnostic soumis à un expert pour validation
class DiagnosticExpertEntity extends Equatable {
  const DiagnosticExpertEntity({
    required this.id,
    required this.agriculteurId,
    required this.agriculteurNom,
    required this.agriculteurTelephone,
    required this.agriculteurVillage,
    required this.champId,
    required this.champNom,
    required this.champSuperficie,
    required this.maladieIA,
    required this.scoreConfiance,
    required this.topPredictions,
    required this.niveauGraviteIA,
    required this.dateSoumission,
    required this.statut,
    this.imageUrl,
    this.commentaireAgriculteur,
    this.expertId,
    this.decisionExpert,
    this.maladieCorrigee,
    this.niveauGraviteCorrige,
    this.traitementRecommande,
    this.dosageTraitement,
    this.frequenceApplication,
    this.dureeTraitement,
    this.coutEstimeFCFA,
    this.typeTraitement,
    this.observationsExpert,
    this.commentaireValidation,
    this.notifierAgriculteur = false,
    this.dateValidation,
    this.modeleVersion = 'v2.1',
  });

  final String id;
  final String agriculteurId;
  final String agriculteurNom;
  final String agriculteurTelephone;
  final String agriculteurVillage;
  final String champId;
  final String champNom;
  final double champSuperficie;

  /// Résultat brut du modèle IA
  final MaladieEntity maladieIA;
  final double scoreConfiance;
  final List<PredictionEntity> topPredictions;
  final NiveauGravite niveauGraviteIA;

  final DateTime dateSoumission;
  final StatutValidation statut;
  final String? imageUrl;
  final String? commentaireAgriculteur;

  /// Données de validation/correction par l'expert
  final String? expertId;
  final DecisionExpert? decisionExpert;
  final MaladieEntity? maladieCorrigee;
  final NiveauGravite? niveauGraviteCorrige;
  final String? traitementRecommande;
  final String? dosageTraitement;
  final String? frequenceApplication;
  final int? dureeTraitement;
  final int? coutEstimeFCFA;
  final TypeTraitement? typeTraitement;
  final String? observationsExpert;
  final String? commentaireValidation;
  final bool notifierAgriculteur;
  final DateTime? dateValidation;
  final String modeleVersion;

  /// Score confiance en pourcentage (0-100)
  int get scoreConfiancePourcent => (scoreConfiance * 100).round();
  String get scoreConfianseFormate => '$scoreConfiancePourcent%';

  /// Durée écoulée depuis la soumission
  String get tempsEcoule {
    final diff = DateTime.now().difference(dateSoumission);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays} jours';
  }

  /// Gravité active (corrigée si disponible, sinon IA)
  NiveauGravite get graviteActive => niveauGraviteCorrige ?? niveauGraviteIA;

  /// Maladie active (corrigée si disponible, sinon IA)
  MaladieEntity get maladieActive => maladieCorrigee ?? maladieIA;

  /// L'IA est fiable si > 80%
  bool get iaFiable => scoreConfiance >= 0.80;

  /// Score incertain si < 50%
  bool get iaIncertaine => scoreConfiance < 0.50;

  @override
  List<Object?> get props => [id, dateSoumission];
}
