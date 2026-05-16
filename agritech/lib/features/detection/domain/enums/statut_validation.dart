import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Statut de validation d'un diagnostic par un expert
enum StatutValidation {
  enAttente,
  valideExpert,
  corrige,
  rejete,
  autoConfirme;

  String get libelle {
    switch (this) {
      case StatutValidation.enAttente:
        return 'EN ATTENTE';
      case StatutValidation.valideExpert:
        return 'VALIDÉ EXPERT';
      case StatutValidation.corrige:
        return 'CORRIGÉ';
      case StatutValidation.rejete:
        return 'REJETÉ';
      case StatutValidation.autoConfirme:
        return 'AUTO-CONFIRMÉ';
    }
  }

  Color get couleur {
    switch (this) {
      case StatutValidation.enAttente:
        return AppColors.textSecondary;
      case StatutValidation.valideExpert:
        return AppColors.primary;
      case StatutValidation.corrige:
        return AppColors.amber;
      case StatutValidation.rejete:
        return AppColors.danger;
      case StatutValidation.autoConfirme:
        return AppColors.info;
    }
  }

  Color get couleurFond {
    switch (this) {
      case StatutValidation.enAttente:
        return AppColors.textSecondary.withValues(alpha: 0.12);
      case StatutValidation.valideExpert:
        return AppColors.primary.withValues(alpha: 0.12);
      case StatutValidation.corrige:
        return AppColors.amber.withValues(alpha: 0.12);
      case StatutValidation.rejete:
        return AppColors.danger.withValues(alpha: 0.12);
      case StatutValidation.autoConfirme:
        return AppColors.info.withValues(alpha: 0.12);
    }
  }

  IconData get icone {
    switch (this) {
      case StatutValidation.enAttente:
        return Icons.hourglass_empty;
      case StatutValidation.valideExpert:
        return Icons.verified_outlined;
      case StatutValidation.corrige:
        return Icons.edit_outlined;
      case StatutValidation.rejete:
        return Icons.cancel_outlined;
      case StatutValidation.autoConfirme:
        return Icons.auto_awesome_outlined;
    }
  }

  static StatutValidation fromString(String value) {
    switch (value) {
      case 'EN_ATTENTE':
        return StatutValidation.enAttente;
      case 'VALIDE_EXPERT':
        return StatutValidation.valideExpert;
      case 'CORRIGE':
        return StatutValidation.corrige;
      case 'REJETE':
        return StatutValidation.rejete;
      case 'AUTO_CONFIRME':
        return StatutValidation.autoConfirme;
      default:
        return StatutValidation.enAttente;
    }
  }

  String toJson() {
    switch (this) {
      case StatutValidation.enAttente:
        return 'EN_ATTENTE';
      case StatutValidation.valideExpert:
        return 'VALIDE_EXPERT';
      case StatutValidation.corrige:
        return 'CORRIGE';
      case StatutValidation.rejete:
        return 'REJETE';
      case StatutValidation.autoConfirme:
        return 'AUTO_CONFIRME';
    }
  }
}
