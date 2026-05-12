import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/image_preprocessing_service.dart';

/// Indicateur de qualité d'image avec couleur et message adaptatifs
class ImageQualityIndicator extends StatelessWidget {
  const ImageQualityIndicator({required this.resultat, super.key});

  final ImageQualityResult resultat;

  Color get _couleur {
    if (resultat.estBonne) return AppColors.primary;
    if (resultat.estAvertissement) return AppColors.amber;
    return AppColors.coral;
  }

  IconData get _icone {
    if (resultat.estBonne) return Icons.check_circle_outline;
    if (resultat.estAvertissement) return Icons.warning_amber_outlined;
    return Icons.error_outline;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _couleur.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(_icone, color: _couleur, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              resultat.message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _couleur,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (resultat.estBonne) ...[
            _BarreQualite(
              valeur: resultat.luminosite ?? 0,
              label: 'Lum.',
              couleur: _couleur,
            ),
            const SizedBox(width: 8),
            _BarreQualite(
              valeur: (resultat.nettete ?? 0).clamp(0, 1).toDouble(),
              label: 'Net.',
              couleur: _couleur,
            ),
          ],
        ],
      ),
    );
  }
}

class _BarreQualite extends StatelessWidget {
  const _BarreQualite({
    required this.valeur,
    required this.label,
    required this.couleur,
  });

  final double valeur;
  final String label;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9, color: couleur),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 36,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: valeur.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: couleur.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(couleur),
            ),
          ),
        ),
      ],
    );
  }
}
