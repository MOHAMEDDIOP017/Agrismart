import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/diagnostic_expert_entity.dart';
import 'gravite_badge.dart';
import 'score_ia_indicator.dart';

/// Carte d'un diagnostic en attente dans la liste
class DiagnosticAttenteCard extends StatelessWidget {
  const DiagnosticAttenteCard({
    super.key,
    required this.diagnostic,
    required this.onTap,
    required this.onValider,
    required this.onCorrection,
  });

  final DiagnosticExpertEntity diagnostic;
  final VoidCallback onTap;
  final VoidCallback onValider;
  final VoidCallback onCorrection;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── En-tête ───────────────────────────────────────────
              Row(
                children: [
                  // Miniature image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: diagnostic.imageUrl != null
                        ? Image.network(
                            diagnostic.imageUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diagnostic.agriculteurNom,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${diagnostic.agriculteurVillage} · ${diagnostic.champNom}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            GraviteBadge(gravite: diagnostic.niveauGraviteIA, compact: true),
                            const SizedBox(width: 8),
                            Text(
                              diagnostic.tempsEcoule,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ── Diagnostic IA ─────────────────────────────────────
              Text(
                diagnostic.maladieIA.nom,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                diagnostic.maladieIA.nomScientifique,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 10),
              ScoreIaIndicator(score: diagnostic.scoreConfiance),
              const SizedBox(height: 12),
              // ── Actions ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onValider,
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Valider'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCorrection,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Corriger'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.amber,
                        side: const BorderSide(color: AppColors.amber),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_outlined, color: AppColors.textSecondary),
      );
}
