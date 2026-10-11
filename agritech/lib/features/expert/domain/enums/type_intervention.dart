import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Type d'intervention terrain
enum TypeIntervention {
  diagnostic,
  traitement,
  conseil,
  suivi;

  String get libelle {
    switch (this) {
      case TypeIntervention.diagnostic:
        return 'DIAGNOSTIC';
      case TypeIntervention.traitement:
        return 'TRAITEMENT';
      case TypeIntervention.conseil:
        return 'CONSEIL';
      case TypeIntervention.suivi:
        return 'SUIVI';
    }
  }

  Color get couleur {
    switch (this) {
      case TypeIntervention.diagnostic:
        return AppPalette.info;
      case TypeIntervention.traitement:
        return AppPalette.alerteElevee;
      case TypeIntervention.conseil:
        return AppPalette.vert;
      case TypeIntervention.suivi:
        return AppPalette.ocre;
    }
  }

  IconData get icone {
    switch (this) {
      case TypeIntervention.diagnostic:
        return Icons.biotech_outlined;
      case TypeIntervention.traitement:
        return Icons.medication_outlined;
      case TypeIntervention.conseil:
        return Icons.chat_bubble_outline;
      case TypeIntervention.suivi:
        return Icons.timeline_outlined;
    }
  }
}
