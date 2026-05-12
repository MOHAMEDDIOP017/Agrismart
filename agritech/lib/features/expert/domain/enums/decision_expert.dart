import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Décision de l'expert sur un diagnostic IA
enum DecisionExpert {
  correct,
  partiellement,
  incorrect;

  String get libelle {
    switch (this) {
      case DecisionExpert.correct:
        return 'Correct';
      case DecisionExpert.partiellement:
        return 'Partiellement correct';
      case DecisionExpert.incorrect:
        return 'Incorrect';
    }
  }

  Color get couleur {
    switch (this) {
      case DecisionExpert.correct:
        return AppColors.primary;
      case DecisionExpert.partiellement:
        return AppColors.amber;
      case DecisionExpert.incorrect:
        return AppColors.danger;
    }
  }

  Color get couleurFond {
    switch (this) {
      case DecisionExpert.correct:
        return AppColors.primary.withValues(alpha: 0.10);
      case DecisionExpert.partiellement:
        return AppColors.amber.withValues(alpha: 0.10);
      case DecisionExpert.incorrect:
        return AppColors.danger.withValues(alpha: 0.10);
    }
  }

  IconData get icone {
    switch (this) {
      case DecisionExpert.correct:
        return Icons.check_circle_outline;
      case DecisionExpert.partiellement:
        return Icons.remove_circle_outline;
      case DecisionExpert.incorrect:
        return Icons.cancel_outlined;
    }
  }

  /// Vrai si une correction est nécessaire
  bool get necessiteCorrection => this != DecisionExpert.correct;
}
