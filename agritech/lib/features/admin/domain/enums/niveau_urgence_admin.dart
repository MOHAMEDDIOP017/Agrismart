import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Niveau d'urgence d'une intervention (vue Admin)
enum NiveauUrgenceAdmin {
  critique,
  eleve,
  modere,
  faible;

  String get libelle {
    switch (this) {
      case NiveauUrgenceAdmin.critique:
        return 'CRITIQUE';
      case NiveauUrgenceAdmin.eleve:
        return 'ÉLEVÉ';
      case NiveauUrgenceAdmin.modere:
        return 'MODÉRÉ';
      case NiveauUrgenceAdmin.faible:
        return 'FAIBLE';
    }
  }

  Color get couleur {
    switch (this) {
      case NiveauUrgenceAdmin.critique:
        return AppPalette.erreur;
      case NiveauUrgenceAdmin.eleve:
        return AppPalette.alerteElevee;
      case NiveauUrgenceAdmin.modere:
        return AppPalette.ocre;
      case NiveauUrgenceAdmin.faible:
        return AppPalette.info;
    }
  }

  Color get couleurFond {
    return couleur.withValues(alpha: 0.12);
  }

  IconData get icone {
    switch (this) {
      case NiveauUrgenceAdmin.critique:
        return Icons.priority_high;
      case NiveauUrgenceAdmin.eleve:
        return Icons.keyboard_double_arrow_up;
      case NiveauUrgenceAdmin.modere:
        return Icons.remove;
      case NiveauUrgenceAdmin.faible:
        return Icons.keyboard_double_arrow_down;
    }
  }
}
