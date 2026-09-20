import 'package:flutter/material.dart';

enum TypeNotification {
  recommandation,
  conseilExpert,
  interventionPlanifiee,
  alerte;

  String get libelle {
    switch (this) {
      case TypeNotification.recommandation:
        return 'Recommandation';
      case TypeNotification.conseilExpert:
        return 'Conseil Expert';
      case TypeNotification.interventionPlanifiee:
        return 'Intervention planifiée';
      case TypeNotification.alerte:
        return 'Alerte';
    }
  }

  IconData get icone {
    switch (this) {
      case TypeNotification.recommandation:
        return Icons.eco_outlined;
      case TypeNotification.conseilExpert:
        return Icons.chat_bubble_outline;
      case TypeNotification.interventionPlanifiee:
        return Icons.event_outlined;
      case TypeNotification.alerte:
        return Icons.warning_amber_outlined;
    }
  }

  Color get couleur {
    switch (this) {
      case TypeNotification.recommandation:
        return const Color(0xFF1D9E75);
      case TypeNotification.conseilExpert:
        return const Color(0xFF1976D2);
      case TypeNotification.interventionPlanifiee:
        return const Color(0xFFEF9F27);
      case TypeNotification.alerte:
        return const Color(0xFFE53935);
    }
  }

  static TypeNotification fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CONSEIL_EXPERT':
        return TypeNotification.conseilExpert;
      case 'INTERVENTION_PLANIFIEE':
        return TypeNotification.interventionPlanifiee;
      case 'ALERTE':
        return TypeNotification.alerte;
      default:
        return TypeNotification.recommandation;
    }
  }

  String toJson() {
    switch (this) {
      case TypeNotification.recommandation:
        return 'RECOMMANDATION';
      case TypeNotification.conseilExpert:
        return 'CONSEIL_EXPERT';
      case TypeNotification.interventionPlanifiee:
        return 'INTERVENTION_PLANIFIEE';
      case TypeNotification.alerte:
        return 'ALERTE';
    }
  }
}
