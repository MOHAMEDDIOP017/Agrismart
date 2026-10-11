import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';

/// Indicateur linéaire du score de confiance IA coloré selon le seuil
class ScoreIaIndicator extends StatelessWidget {
  const ScoreIaIndicator({
    super.key,
    required this.score,
    this.showLabel = true,
  });

  /// Score entre 0.0 et 1.0
  final double score;
  final bool showLabel;

  Color _couleur(BuildContext context) {
    if (score >= 0.80) return context.couleurs.primaire;
    if (score >= 0.50) return context.couleurs.secondaire;
    return context.couleurs.erreur;
  }

  String get _libelle {
    if (score >= 0.80) return 'Fiable';
    if (score >= 0.50) return 'Incertain';
    return 'Peu fiable';
  }

  @override
  Widget build(BuildContext context) {
    final pourcent = (score * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Score IA : $pourcent%',
                style: AppTypography.police(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _couleur(context),
                ),
              ),
              Text(
                _libelle,
                style: AppTypography.police(
                    fontSize: 11, color: _couleur(context)),
              ),
            ],
          ),
        if (showLabel) const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score),
            duration: AppDurees.moyenne,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              backgroundColor: _couleur(context).withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(_couleur(context)),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}
