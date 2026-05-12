import 'package:flutter/material.dart';

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
        return const Color(0xFF378ADD);
      case TypeLog.diagnostic:
        return const Color(0xFF1D9E75);
      case TypeLog.intervention:
        return const Color(0xFFEF9F27);
      case TypeLog.alerte:
        return const Color(0xFFD85A30);
      case TypeLog.erreur:
        return const Color(0xFFE53935);
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
