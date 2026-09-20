import 'package:equatable/equatable.dart';

/// Statistiques globales de la plateforme (vue Admin)
class StatistiquesGlobalesEntity extends Equatable {
  const StatistiquesGlobalesEntity({
    required this.totalRecommandations,
    required this.totalAlertes,
    required this.totalInterventions,
    required this.totalConseils,
    required this.totalUtilisateurs,
    required this.totalAgriculteurs,
    required this.totalExperts,
    required this.totalAdmins,
    required this.interventionsEnCours,
    required this.donneesBarChart,
    this.totalChamps = 0,
    this.topCulturesRecommandees = const [],
  });

  // KPIs principaux
  final int totalRecommandations;
  final int totalAlertes;
  final int totalInterventions;
  final int totalConseils;

  // Répartition utilisateurs
  final int totalUtilisateurs;
  final int totalAgriculteurs;
  final int totalExperts;
  final int totalAdmins;
  final int interventionsEnCours;

  /// Nombre total de champs enregistrés
  final int totalChamps;

  /// Top cultures les plus recommandées par l'IA
  final List<CultureStatReco> topCulturesRecommandees;

  /// Données pour le BarChart hebdomadaire [semaine → recommandations]
  final List<DonneeBarChart> donneesBarChart;

  @override
  List<Object?> get props => [totalRecommandations, totalUtilisateurs];
}

/// Culture recommandée avec son nombre de recommandations
class CultureStatReco extends Equatable {
  const CultureStatReco({
    required this.nom,
    required this.nombreRecommandations,
    required this.maxRecommandations,
  });

  final String nom;
  final int nombreRecommandations;
  final int maxRecommandations;

  double get progression =>
      maxRecommandations > 0 ? nombreRecommandations / maxRecommandations : 0;

  @override
  List<Object?> get props => [nom];
}

/// Point de données pour le graphique à barres
class DonneeBarChart extends Equatable {
  const DonneeBarChart({
    required this.semaine,
    required this.recommandations,
  });

  final String semaine;
  final double recommandations;

  @override
  List<Object?> get props => [semaine];
}

/// Statut des services système
class StatutSysteme extends Equatable {
  const StatutSysteme({
    required this.apiMeteoOperationnelle,
    required this.tempsReponseApiMs,
    required this.versionModeleIA,
    required this.precisionModeleIA,
    required this.modeleIAOperationnel,
  });

  final bool apiMeteoOperationnelle;
  final int tempsReponseApiMs;
  final String versionModeleIA;
  final double precisionModeleIA;
  final bool modeleIAOperationnel;

  @override
  List<Object?> get props => [apiMeteoOperationnelle, modeleIAOperationnel];
}
