import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/recommandation_model.dart';

/// Carte d'une culture recommandée par l'IA
class CultureCard extends StatelessWidget {
  const CultureCard({
    super.key,
    required this.recommandation,
    required this.index,
    required this.onTap,
  });

  final RecommandationModel recommandation;
  final int index;
  final VoidCallback onTap;

  Color get _scoreColor {
    final s = recommandation.scoreCompatibilite;
    if (s >= 85) return AppColors.primary;
    if (s >= 70) return AppColors.amber;
    return AppColors.coral;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Image culture
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: recommandation.imageUrl ?? '',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.grass_rounded, color: AppColors.primary, size: 32),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommandation.culture,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          recommandation.periodeIdealePlantation,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.trending_up_rounded, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          recommandation.rendementLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Score circulaire animé
              _ScoreCircle(
                score: recommandation.scoreCompatibilite,
                color: _scoreColor,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 150).ms, duration: 400.ms)
        .slideY(begin: 0.25, end: 0);
  }
}

class _ScoreCircle extends StatelessWidget {
  const _ScoreCircle({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            builder: (_, value, __) => CircularProgressIndicator(
              value: value,
              strokeWidth: 5,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text(
            '$score%',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
