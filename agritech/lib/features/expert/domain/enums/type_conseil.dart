import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Type de conseil envoyé par l'expert à un agriculteur
enum TypeConseil {
  culture,
  traitement,
  irrigation,
  recolte,
  autre;

  String get libelle {
    switch (this) {
      case TypeConseil.culture:
        return 'CULTURE';
      case TypeConseil.traitement:
        return 'TRAITEMENT';
      case TypeConseil.irrigation:
        return 'IRRIGATION';
      case TypeConseil.recolte:
        return 'RÉCOLTE';
      case TypeConseil.autre:
        return 'AUTRE';
    }
  }

  Color get couleur {
    switch (this) {
      case TypeConseil.culture:
        return AppColors.primary;
      case TypeConseil.traitement:
        return AppColors.coral;
      case TypeConseil.irrigation:
        return AppColors.info;
      case TypeConseil.recolte:
        return AppColors.amber;
      case TypeConseil.autre:
        return AppColors.textSecondary;
    }
  }

  IconData get icone {
    switch (this) {
      case TypeConseil.culture:
        return Icons.eco_outlined;
      case TypeConseil.traitement:
        return Icons.medication_outlined;
      case TypeConseil.irrigation:
        return Icons.water_drop_outlined;
      case TypeConseil.recolte:
        return Icons.agriculture_outlined;
      case TypeConseil.autre:
        return Icons.info_outline;
    }
  }
}
