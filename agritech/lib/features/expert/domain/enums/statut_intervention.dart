import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Statut d'une intervention terrain planifiée
enum StatutIntervention {
  planifiee,
  realisee,
  annulee;

  String get libelle {
    switch (this) {
      case StatutIntervention.planifiee:
        return 'PLANIFIÉE';
      case StatutIntervention.realisee:
        return 'RÉALISÉE';
      case StatutIntervention.annulee:
        return 'ANNULÉE';
    }
  }

  Color get couleur {
    switch (this) {
      case StatutIntervention.planifiee:
        return AppPalette.ocre;
      case StatutIntervention.realisee:
        return AppPalette.vert;
      case StatutIntervention.annulee:
        return AppPalette.encreDouce;
    }
  }

  Color get couleurFond {
    switch (this) {
      case StatutIntervention.planifiee:
        return AppPalette.ocre.withValues(alpha: 0.12);
      case StatutIntervention.realisee:
        return AppPalette.vert.withValues(alpha: 0.12);
      case StatutIntervention.annulee:
        return AppPalette.encreDouce.withValues(alpha: 0.12);
    }
  }

  IconData get icone {
    switch (this) {
      case StatutIntervention.planifiee:
        return Icons.schedule_outlined;
      case StatutIntervention.realisee:
        return Icons.check_circle_outline;
      case StatutIntervention.annulee:
        return Icons.cancel_outlined;
    }
  }
}
