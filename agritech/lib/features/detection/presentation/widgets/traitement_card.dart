import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/traitement_entity.dart';

/// Card d'un traitement recommandé avec détails d'application
class TraitementCard extends StatelessWidget {
  const TraitementCard({required this.traitement, super.key});

  final TraitementEntity traitement;

  @override
  Widget build(BuildContext context) {
    final type = traitement.type;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: type.couleurFond,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(type.icone, color: type.couleur, size: 20),
          ),
          title: Text(
            traitement.nomProduit,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Wrap(
            spacing: 6,
            children: [
              _InfoChip(label: traitement.dosage, icone: Icons.science_outlined),
              _InfoChip(
                  label: traitement.dureeFormatee, icone: Icons.schedule_outlined),
              _TypeBadge(type: type),
            ],
          ),
          children: [
            if (traitement.instructionsDetaillees != null) ...[
              _DetailRow(
                titre: 'Application',
                contenu: traitement.instructionsDetaillees!,
                icone: Icons.info_outline,
                couleur: AppColors.info,
              ),
              const SizedBox(height: 8),
            ],
            _DetailRow(
              titre: 'Fréquence',
              contenu: traitement.frequenceApplication,
              icone: Icons.repeat_outlined,
              couleur: AppColors.primary,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.payments_outlined,
                    size: 16, color: AppColors.amber),
                const SizedBox(width: 6),
                Text(
                  'Coût estimé : ${traitement.coutFormate}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.amber,
                  ),
                ),
              ],
            ),
            if (traitement.precautions != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                titre: 'Précautions',
                contenu: traitement.precautions!,
                icone: Icons.warning_amber_outlined,
                couleur: AppColors.coral,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icone});

  final String label;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 11, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final dynamic type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: type.couleurFond,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        type.libelle,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: type.couleur,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.titre,
    required this.contenu,
    required this.icone,
    required this.couleur,
  });

  final String titre;
  final String contenu;
  final IconData icone;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 15, color: couleur),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$titre : ',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: contenu,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
