import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

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

  Color get _couleur {
    if (score >= 0.80) return AppColors.primary;
    if (score >= 0.50) return AppColors.amber;
    return AppColors.danger;
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
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _couleur,
                ),
              ),
              Text(
                _libelle,
                style: GoogleFonts.inter(fontSize: 11, color: _couleur),
              ),
            ],
          ),
        if (showLabel) const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score),
            duration: const Duration(milliseconds: 900),
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              backgroundColor: _couleur.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(_couleur),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}
