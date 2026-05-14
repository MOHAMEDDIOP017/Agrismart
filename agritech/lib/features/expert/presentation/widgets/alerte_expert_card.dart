import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/alerte_zone_entity.dart';
import 'gravite_badge.dart';

/// Carte d'alerte zone pour l'Expert
class AlerteExpertCard extends StatelessWidget {
  const AlerteExpertCard({
    super.key,
    required this.alerte,
    required this.onPrendreEnCharge,
    required this.onVoirDiagnostic,
  });

  final AlerteZoneEntity alerte;
  final VoidCallback onPrendreEnCharge;
  final VoidCallback onVoirDiagnostic;

  Color get _couleurStatut {
    switch (alerte.statut) {
      case StatutAlerteZone.nonTraitee:
        return AppColors.danger;
      case StatutAlerteZone.enCours:
        return AppColors.amber;
      case StatutAlerteZone.resolue:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Barre latérale colorée
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: alerte.niveauGravite.couleur,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alerte.maladie,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        GraviteBadge(gravite: alerte.niveauGravite, compact: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${alerte.agriculteurNom} · ${alerte.champNom}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          alerte.tempsEcoule,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _couleurStatut.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            alerte.statut.libelle,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _couleurStatut,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (alerte.description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        alerte.description!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (alerte.statut != StatutAlerteZone.resolue)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onPrendreEnCharge,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                textStyle: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Prendre en charge'),
                            ),
                          ),
                        if (alerte.statut != StatutAlerteZone.resolue) const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onVoirDiagnostic,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.info,
                              side: const BorderSide(color: AppColors.info),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Voir diagnostic'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
