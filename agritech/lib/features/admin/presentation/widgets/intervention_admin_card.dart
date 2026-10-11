import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/assignation_entity.dart';
import 'statut_badge_admin.dart';

/// Carte d'intervention non encore assignée
class InterventionNonAssigneeCard extends StatelessWidget {
  const InterventionNonAssigneeCard({
    super.key,
    required this.assignation,
    required this.onAssigner,
  });

  final AssignationEntity assignation;
  final VoidCallback onAssigner;

  @override
  Widget build(BuildContext context) {
    final urgence = assignation.niveauUrgence;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.couleurs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: urgence.couleur.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: urgence.couleur.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : agriculteur + badge urgence
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignation.agriculteurNom,
                      style: AppTypography.textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.grass_outlined,
                            size: 12, color: context.couleurs.texteSecondaire),
                        const SizedBox(width: 4),
                        Text(
                          '${assignation.champNom} • ${assignation.region}',
                          style: AppTypography.textTheme.bodySmall!.copyWith(
                            color: context.couleurs.texteSecondaire,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Badge urgence
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: urgence.couleurFond,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: urgence.couleur.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(urgence.icone, size: 12, color: urgence.couleur),
                    const SizedBox(width: 4),
                    Text(
                      urgence.libelle,
                      style: AppTypography.textTheme.labelSmall!.copyWith(
                        color: urgence.couleur,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Type intervention + date souhaitée
          Row(
            children: [
              _Chip(
                icone: Icons.engineering_outlined,
                texte: assignation.typeIntervention,
                couleur: context.couleurs.info,
              ),
              const SizedBox(width: 8),
              _Chip(
                icone: Icons.calendar_today_outlined,
                texte: _dateFormatee(assignation.dateSouhaitee),
                couleur: context.couleurs.texteSecondaire,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bouton assigner
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAssigner,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF534AB7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              child: const Text('Assigner un expert'),
            ),
          ),
        ],
      ),
    );
  }

  String _dateFormatee(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// Carte d'intervention déjà assignée à un expert
class InterventionAssigneeCard extends StatelessWidget {
  const InterventionAssigneeCard({
    super.key,
    required this.assignation,
    required this.onVoirDetail,
  });

  final AssignationEntity assignation;
  final VoidCallback onVoirDetail;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onVoirDetail,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.couleurs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.couleurs.bordure),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expert assigné
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      const Color(0xFF534AB7).withValues(alpha: 0.15),
                  child: Text(
                    _initiales(assignation.expertNom ?? ''),
                    style: const TextStyle(
                      color: Color(0xFF534AB7),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignation.expertNom ?? 'Expert',
                        style: AppTypography.textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (assignation.expertSpecialite != null)
                        Text(
                          assignation.expertSpecialite!,
                          style: AppTypography.textTheme.labelSmall!.copyWith(
                            color: context.couleurs.texteSecondaire,
                          ),
                        ),
                    ],
                  ),
                ),
                StatutAssignationBadge(statut: assignation.statut),
              ],
            ),
            const Divider(height: 16),
            // Agriculteur + champ
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 13, color: context.couleurs.texteSecondaire),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${assignation.agriculteurNom} • ${assignation.champNom}',
                    style: AppTypography.textTheme.bodySmall!.copyWith(
                      color: context.couleurs.texteSecondaire,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: context.couleurs.texteSecondaire),
                const SizedBox(width: 4),
                Text(
                  _dateFormatee(assignation.dateSouhaitee),
                  style: AppTypography.textTheme.labelSmall!.copyWith(
                    color: context.couleurs.texteSecondaire,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initiales(String nom) {
    final parts = nom.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  String _dateFormatee(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.icone, required this.texte, required this.couleur});

  final IconData icone;
  final String texte;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 13, color: couleur),
        const SizedBox(width: 4),
        Text(
          texte,
          style: AppTypography.textTheme.labelSmall!.copyWith(
            color: couleur,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
