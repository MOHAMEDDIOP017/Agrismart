import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Chip représentant un symptôme observé, avec fadeIn décalé
class SymptomeChip extends StatelessWidget {
  const SymptomeChip({
    required this.symptome,
    required this.index,
    super.key,
  });

  final String symptome;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fiber_manual_record,
              size: 7, color: AppColors.primary.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
          Text(
            symptome,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 80 * index))
        .fadeIn(duration: 300.ms)
        .slideX(begin: -0.1, end: 0);
  }
}
