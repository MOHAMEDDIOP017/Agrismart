import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/diagnostic_entity.dart';
import 'gravite_badge.dart';

/// Mini-card horizontale pour l'historique récent sur la home screen
class DiagnosticMiniCard extends StatelessWidget {
  const DiagnosticMiniCard({
    required this.diagnostic,
    required this.onTap,
    super.key,
  });

  final DiagnosticEntity diagnostic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFormate =
        DateFormat('dd/MM', 'fr_FR').format(diagnostic.dateAnalyse);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vignette image ou placeholder
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: diagnostic.imageLocalPath != null
                  ? Image.asset(
                      diagnostic.imageLocalPath!,
                      height: 80,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _Placeholder(),
                    )
                  : _Placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diagnostic.maladieDetectee.nom,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        diagnostic.scoreConfianseFormate,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        dateFormate,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GraviteBadge(
                      gravite: diagnostic.maladieDetectee.gravite,
                      compact: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      width: double.infinity,
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Icon(
        Icons.eco_outlined,
        color: AppColors.primary,
        size: 32,
      ),
    );
  }
}
