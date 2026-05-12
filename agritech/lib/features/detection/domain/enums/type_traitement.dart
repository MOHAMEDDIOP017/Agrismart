import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Type de traitement recommandé pour une maladie
enum TypeTraitement {
  chimique,
  biologique,
  preventif,
  curatif;

  String get libelle {
    switch (this) {
      case TypeTraitement.chimique:
        return 'CHIMIQUE';
      case TypeTraitement.biologique:
        return 'BIOLOGIQUE';
      case TypeTraitement.preventif:
        return 'PRÉVENTIF';
      case TypeTraitement.curatif:
        return 'CURATIF';
    }
  }

  Color get couleur {
    switch (this) {
      case TypeTraitement.chimique:
        return AppColors.danger;
      case TypeTraitement.biologique:
        return AppColors.primary;
      case TypeTraitement.preventif:
        return AppColors.info;
      case TypeTraitement.curatif:
        return AppColors.amber;
    }
  }

  Color get couleurFond {
    switch (this) {
      case TypeTraitement.chimique:
        return AppColors.danger.withValues(alpha: 0.12);
      case TypeTraitement.biologique:
        return AppColors.primary.withValues(alpha: 0.12);
      case TypeTraitement.preventif:
        return AppColors.info.withValues(alpha: 0.12);
      case TypeTraitement.curatif:
        return AppColors.amber.withValues(alpha: 0.12);
    }
  }

  IconData get icone {
    switch (this) {
      case TypeTraitement.chimique:
        return Icons.science_outlined;
      case TypeTraitement.biologique:
        return Icons.eco_outlined;
      case TypeTraitement.preventif:
        return Icons.shield_outlined;
      case TypeTraitement.curatif:
        return Icons.medical_services_outlined;
    }
  }

  static TypeTraitement fromString(String value) {
    switch (value.toLowerCase()) {
      case 'chimique':
        return TypeTraitement.chimique;
      case 'biologique':
        return TypeTraitement.biologique;
      case 'preventif':
      case 'préventif':
        return TypeTraitement.preventif;
      case 'curatif':
        return TypeTraitement.curatif;
      default:
        return TypeTraitement.curatif;
    }
  }
}
