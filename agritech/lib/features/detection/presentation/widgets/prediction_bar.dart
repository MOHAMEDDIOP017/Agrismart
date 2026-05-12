import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/prediction_entity.dart';

/// Barre de probabilité animée pour une prédiction du modèle IA
class PredictionBar extends StatelessWidget {
  const PredictionBar({
    required this.prediction,
    required this.delaiAnimation,
    super.key,
  });

  final PredictionEntity prediction;
  final Duration delaiAnimation;

  Color get _couleurBarre {
    switch (prediction.rang) {
      case 1:
        return AppColors.primary;
      case 2:
        return AppColors.amber;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  prediction.maladie.nom,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: prediction.rang == 1
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                prediction.scoreFormate,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _couleurBarre,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: prediction.score),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (_, value, __) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(_couleurBarre),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
