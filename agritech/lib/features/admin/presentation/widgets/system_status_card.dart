import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/statistiques_globales_entity.dart';

/// Carte d'état de santé du système (API météo + Modèle IA)
class SystemStatusCard extends StatelessWidget {
  const SystemStatusCard({super.key, required this.statut});

  final StatutSysteme statut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart_outlined,
                  size: 18, color: Color(0xFF534AB7)),
              const SizedBox(width: 8),
              Text(
                'Santé du système',
                style: AppTypography.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _LigneStatut(
            label: 'API Météo',
            estOperationnel: statut.apiMeteoOperationnelle,
            detail:
                '${statut.tempsReponseApiMs}ms',
            icone: Icons.cloud_outlined,
          ),
          const SizedBox(height: 10),
          _LigneStatut(
            label: 'Modèle IA ${statut.versionModeleIA}',
            estOperationnel: statut.modeleIAOperationnel,
            detail:
                'Précision : ${statut.precisionModeleIA.toStringAsFixed(0)}%',
            icone: Icons.psychology_outlined,
          ),
        ],
      ),
    );
  }
}

class _LigneStatut extends StatelessWidget {
  const _LigneStatut({
    required this.label,
    required this.estOperationnel,
    required this.detail,
    required this.icone,
  });

  final String label;
  final bool estOperationnel;
  final String detail;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final couleur =
        estOperationnel ? AppColors.primary : AppColors.danger;
    final texteStatut =
        estOperationnel ? 'OPÉRATIONNEL' : 'HORS SERVICE';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: couleur.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icone, size: 16, color: couleur),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                detail,
                style: AppTypography.textTheme.labelSmall!.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Indicateur coloré + libellé statut
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: couleur.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: couleur,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                texteStatut,
                style: AppTypography.textTheme.labelSmall!.copyWith(
                  color: couleur,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
