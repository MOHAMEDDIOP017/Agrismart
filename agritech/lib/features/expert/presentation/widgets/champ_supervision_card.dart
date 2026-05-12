import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/champ_supervise_entity.dart';

/// Carte de supervision d'un champ pour l'Expert
class ChampSupervisionCard extends StatelessWidget {
  const ChampSupervisionCard({
    super.key,
    required this.champ,
    required this.onTableauDeBord,
  });

  final ChampSuperviseEntity champ;
  final VoidCallback onTableauDeBord;

  Color get _couleurSante {
    if (champ.scoresSante >= 70) return AppColors.primary;
    if (champ.scoresSante >= 40) return AppColors.amber;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Image champ
          if (champ.photoUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                champ.photoUrl!,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imgPlaceholder(),
              ),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: _imgPlaceholder(),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        champ.nom,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatutBadge(statut: champ.statut),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${champ.agriculteurNom} · ${champ.superficieFormatee}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (champ.culture != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${champ.culture} · ${champ.typeSol}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
                if (champ.derniereAlerte != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_outlined,
                            size: 14, color: AppColors.danger),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            champ.derniereAlerte!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // Score santé
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Santé du champ',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      '${champ.scoresSante}%',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _couleurSante,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: champ.scoresSante / 100,
                    backgroundColor: _couleurSante.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(_couleurSante),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onTableauDeBord,
                    icon: const Icon(Icons.dashboard_outlined, size: 16),
                    label: const Text('Tableau de bord'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        height: 100,
        color: AppColors.border,
        child: const Center(child: Icon(Icons.terrain, color: AppColors.textSecondary, size: 36)),
      );
}

class _StatutBadge extends StatelessWidget {
  const _StatutBadge({required this.statut});
  final String statut;

  Color get _couleur {
    switch (statut) {
      case 'EN_COURS':
        return AppColors.primary;
      case 'EN_TRAITEMENT':
        return AppColors.coral;
      case 'RÉCOLTE':
        return AppColors.amber;
      case 'ABANDONNÉ':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _couleur.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          statut.replaceAll('_', ' '),
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _couleur,
          ),
        ),
      );
}
