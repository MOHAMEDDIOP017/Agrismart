import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Niveau de gravité d'une maladie détectée
enum NiveauGravite {
  faible,
  modere,
  eleve,
  critique;

  String get libelle {
    switch (this) {
      case NiveauGravite.faible:
        return 'FAIBLE';
      case NiveauGravite.modere:
        return 'MODÉRÉ';
      case NiveauGravite.eleve:
        return 'ÉLEVÉ';
      case NiveauGravite.critique:
        return 'CRITIQUE';
    }
  }

  Color get couleur {
    switch (this) {
      case NiveauGravite.faible:
        return AppColors.alerteFaible;
      case NiveauGravite.modere:
        return AppColors.alerteModere;
      case NiveauGravite.eleve:
        return AppColors.alerteEleve;
      case NiveauGravite.critique:
        return AppColors.alerteCritique;
    }
  }

  Color get couleurFond {
    switch (this) {
      case NiveauGravite.faible:
        return AppColors.alerteFaible.withValues(alpha: 0.12);
      case NiveauGravite.modere:
        return AppColors.alerteModere.withValues(alpha: 0.12);
      case NiveauGravite.eleve:
        return AppColors.alerteEleve.withValues(alpha: 0.12);
      case NiveauGravite.critique:
        return AppColors.alerteCritique.withValues(alpha: 0.12);
    }
  }

  IconData get icone {
    switch (this) {
      case NiveauGravite.faible:
        return Icons.info_outline;
      case NiveauGravite.modere:
        return Icons.warning_amber_outlined;
      case NiveauGravite.eleve:
        return Icons.warning_outlined;
      case NiveauGravite.critique:
        return Icons.dangerous_outlined;
    }
  }

  static NiveauGravite fromString(String value) {
    switch (value.toLowerCase()) {
      case 'faible':
        return NiveauGravite.faible;
      case 'modere':
      case 'modéré':
        return NiveauGravite.modere;
      case 'eleve':
      case 'élevé':
        return NiveauGravite.eleve;
      case 'critique':
        return NiveauGravite.critique;
      default:
        return NiveauGravite.modere;
    }
  }
}
