import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Statut d'un compte utilisateur dans la plateforme
enum StatutUtilisateur {
  actif,
  suspendu,
  enAttente;

  String get libelle {
    switch (this) {
      case StatutUtilisateur.actif:
        return 'ACTIF';
      case StatutUtilisateur.suspendu:
        return 'SUSPENDU';
      case StatutUtilisateur.enAttente:
        return 'EN ATTENTE';
    }
  }

  Color get couleur {
    switch (this) {
      case StatutUtilisateur.actif:
        return const Color(0xFF1D9E75);
      case StatutUtilisateur.suspendu:
        return AppColors.danger;
      case StatutUtilisateur.enAttente:
        return AppColors.amber;
    }
  }

  Color get couleurFond {
    switch (this) {
      case StatutUtilisateur.actif:
        return const Color(0xFF1D9E75).withValues(alpha: 0.12);
      case StatutUtilisateur.suspendu:
        return AppColors.danger.withValues(alpha: 0.12);
      case StatutUtilisateur.enAttente:
        return AppColors.amber.withValues(alpha: 0.12);
    }
  }

  IconData get icone {
    switch (this) {
      case StatutUtilisateur.actif:
        return Icons.check_circle_outline;
      case StatutUtilisateur.suspendu:
        return Icons.block_outlined;
      case StatutUtilisateur.enAttente:
        return Icons.hourglass_empty_outlined;
    }
  }
}
