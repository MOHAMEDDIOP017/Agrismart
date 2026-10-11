import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Statut d'une assignation expert-intervention (vue Admin)
enum StatutAssignation {
  nonAssignee,
  planifiee,
  enCours,
  realisee,
  annulee;

  String get libelle {
    switch (this) {
      case StatutAssignation.nonAssignee:
        return 'NON ASSIGNÉE';
      case StatutAssignation.planifiee:
        return 'PLANIFIÉE';
      case StatutAssignation.enCours:
        return 'EN COURS';
      case StatutAssignation.realisee:
        return 'RÉALISÉE';
      case StatutAssignation.annulee:
        return 'ANNULÉE';
    }
  }

  Color get couleur {
    switch (this) {
      case StatutAssignation.nonAssignee:
        return AppPalette.encreDouce;
      case StatutAssignation.planifiee:
        return AppPalette.ocre;
      case StatutAssignation.enCours:
        return AppPalette.info;
      case StatutAssignation.realisee:
        return AppPalette.vert;
      case StatutAssignation.annulee:
        return AppPalette.erreur;
    }
  }

  Color get couleurFond {
    return couleur.withValues(alpha: 0.12);
  }

  IconData get icone {
    switch (this) {
      case StatutAssignation.nonAssignee:
        return Icons.person_off_outlined;
      case StatutAssignation.planifiee:
        return Icons.schedule_outlined;
      case StatutAssignation.enCours:
        return Icons.play_circle_outline;
      case StatutAssignation.realisee:
        return Icons.check_circle_outline;
      case StatutAssignation.annulee:
        return Icons.cancel_outlined;
    }
  }

  bool get estEnAttente => this == StatutAssignation.nonAssignee;
}
