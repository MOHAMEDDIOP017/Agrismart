import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/enums/statut_utilisateur.dart';
import '../../domain/enums/statut_assignation.dart';

/// Badge de statut d'un compte utilisateur
class StatutUtilisateurBadge extends StatelessWidget {
  const StatutUtilisateurBadge({super.key, required this.statut});

  final StatutUtilisateur statut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: statut.couleurFond,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statut.couleur.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statut.icone, size: 11, color: statut.couleur),
          const SizedBox(width: 4),
          Text(
            statut.libelle,
            style: AppTypography.textTheme.labelSmall!.copyWith(
              color: statut.couleur,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge de statut d'une assignation expert-intervention
class StatutAssignationBadge extends StatelessWidget {
  const StatutAssignationBadge({super.key, required this.statut});

  final StatutAssignation statut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: statut.couleurFond,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statut.couleur.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statut.icone, size: 11, color: statut.couleur),
          const SizedBox(width: 4),
          Text(
            statut.libelle,
            style: AppTypography.textTheme.labelSmall!.copyWith(
              color: statut.couleur,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
