import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Type d'entrée dans le journal système
enum TypeLog {
  connexion,
  diagnostic,
  intervention,
  alerte,
  erreur;

  String get libelle {
    switch (this) {
      case TypeLog.connexion:
        return 'CONNEXION';
      case TypeLog.diagnostic:
        return 'DIAGNOSTIC';
      case TypeLog.intervention:
        return 'INTERVENTION';
      case TypeLog.alerte:
        return 'ALERTE';
      case TypeLog.erreur:
        return 'ERREUR';
    }
  }

  Color get couleur {
    switch (this) {
      case TypeLog.connexion:
        return AppPalette.info;
      case TypeLog.diagnostic:
        return AppPalette.succes;
      case TypeLog.intervention:
        return AppPalette.avertissement;
      case TypeLog.alerte:
        return AppPalette.alerteElevee;
      case TypeLog.erreur:
        return AppPalette.erreur;
    }
  }

  Color get couleurFond {
    return couleur.withValues(alpha: 0.12);
  }

  IconData get icone {
    switch (this) {
      case TypeLog.connexion:
        return Icons.login_outlined;
      case TypeLog.diagnostic:
        return Icons.biotech_outlined;
      case TypeLog.intervention:
        return Icons.engineering_outlined;
      case TypeLog.alerte:
        return Icons.warning_amber_outlined;
      case TypeLog.erreur:
        return Icons.error_outline;
    }
  }
}
