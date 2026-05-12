import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/assignation_entity.dart';

/// Carte de sélection d'un expert lors d'une assignation
class ExpertSelectionCardAdmin extends StatelessWidget {
  const ExpertSelectionCardAdmin({
    super.key,
    required this.expert,
    required this.estSelectionne,
    required this.onSelectionner,
  });

  final ExpertDisponibleEntity expert;
  final bool estSelectionne;
  final VoidCallback onSelectionner;

  static const Color _violet = Color(0xFF534AB7);

  @override
  Widget build(BuildContext context) {
    final couleurBord =
        estSelectionne ? _violet : AppColors.border;
    return GestureDetector(
      onTap: onSelectionner,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: estSelectionne
              ? _violet.withValues(alpha: 0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: couleurBord,
            width: estSelectionne ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar + badge disponibilité
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _violet.withValues(alpha: 0.15),
                  child: Text(
                    _initiales(expert.nomComplet),
                    style: const TextStyle(
                      color: _violet,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: expert.estEnLigne
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expert.nomComplet,
                    style: AppTypography.textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    expert.specialite,
                    style: AppTypography.textTheme.bodySmall!.copyWith(
                      color: _violet,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Région
                      _Info(
                        icone: Icons.location_on_outlined,
                        texte: expert.region,
                      ),
                      const SizedBox(width: 10),
                      // Interventions en cours
                      _Info(
                        icone: Icons.work_outline,
                        texte: '${expert.interventionsEnCours} en cours',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Étoiles
                _EtoilesScore(score: expert.scoreEvaluation),
                const SizedBox(height: 4),
                Text(
                  expert.estEnLigne ? 'En ligne' : 'Hors ligne',
                  style: AppTypography.textTheme.labelSmall!.copyWith(
                    color: expert.estEnLigne
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
                if (estSelectionne) ...[
                  const SizedBox(height: 4),
                  const Icon(Icons.check_circle,
                      color: _violet, size: 18),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initiales(String nom) {
    final parts = nom.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          texte,
          style: AppTypography.textTheme.labelSmall!.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _EtoilesScore extends StatelessWidget {
  const _EtoilesScore({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, size: 13, color: Color(0xFFEF9F27)),
        const SizedBox(width: 2),
        Text(
          score.toStringAsFixed(1),
          style: AppTypography.textTheme.labelSmall!.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
