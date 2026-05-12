import 'package:equatable/equatable.dart';

/// Statistiques globales de la plateforme (vue Admin)
class StatistiquesGlobalesEntity extends Equatable {
  const StatistiquesGlobalesEntity({
    required this.totalDiagnostics,
    required this.precisionIAPourcent,
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
    required this.topMaladies,
    required this.donneesLineChart,
  });

  // KPIs principaux
  final int totalDiagnostics;
  final double precisionIAPourcent;
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

  /// Données pour le BarChart hebdomadaire [semaine → {diagnostics, recommandations}]
  final List<DonneeBarChart> donneesBarChart;

  /// Top 5 maladies détectées ce mois
  final List<MaladieStat> topMaladies;

  /// Données pour le LineChart d'évolution de la précision IA
  final List<DonneeLineChart> donneesLineChart;

  @override
  List<Object?> get props => [totalDiagnostics, precisionIAPourcent];
}

/// Point de données pour le graphique à barres
class DonneeBarChart extends Equatable {
  const DonneeBarChart({
    required this.semaine,
    required this.diagnostics,
    required this.recommandations,
  });

  final String semaine;
  final double diagnostics;
  final double recommandations;

  @override
  List<Object?> get props => [semaine];
}

/// Maladie avec son nombre de détections pour le classement
class MaladieStat extends Equatable {
  const MaladieStat({
    required this.nom,
    required this.nombreDetections,
    required this.maxDetections,
  });

  final String nom;
  final int nombreDetections;
  /// Maximum pour calculer la barre de progression
  final int maxDetections;

  double get progression => nombreDetections / maxDetections;

  @override
  List<Object?> get props => [nom];
}

/// Point de données pour le graphique d'évolution de précision IA
class DonneeLineChart extends Equatable {
  const DonneeLineChart({
    required this.mois,
    required this.precisionBrute,
    required this.precisionValidee,
  });

  final String mois;
  final double precisionBrute;
  final double precisionValidee;

  @override
  List<Object?> get props => [mois];
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
