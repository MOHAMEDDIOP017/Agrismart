import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/assignation_entity.dart';
import '../providers/admin_provider.dart';
import '../widgets/expert_selection_card_admin.dart';
import '../widgets/statut_badge_admin.dart';

/// BottomSheet de détail d'une assignation (DraggableScrollableSheet)
class AssignationDetailSheet extends ConsumerStatefulWidget {
  const AssignationDetailSheet({super.key, required this.assignation});

  final AssignationEntity assignation;

  @override
  ConsumerState<AssignationDetailSheet> createState() =>
      _AssignationDetailSheetState();
}

class _AssignationDetailSheetState
    extends ConsumerState<AssignationDetailSheet> {
  static const Color _adminPrimary = Color(0xFF534AB7);

  bool _modeChangementExpert = false;
  String? _nouvelExpertId;

  @override
  Widget build(BuildContext context) {
    final expertsAsync =
        ref.watch(expertsDisponiblesProvider(widget.assignation.region));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Poignée
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // En-tête
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.assignment_ind_outlined,
                      color: _adminPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Détail assignation',
                    style: AppTypography.textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  StatutAssignationBadge(statut: widget.assignation.statut),
                ],
              ),
            ),
            const Divider(height: 20),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  // ── Section intervention ──────────────────────
                  const _SectionTitre(
                      titre: 'Intervention',
                      icone: Icons.engineering_outlined),
                  const SizedBox(height: 10),
                  _InfoRow(
                      label: 'Agriculteur',
                      valeur: widget.assignation.agriculteurNom),
                  _InfoRow(
                      label: 'Champ',
                      valeur: widget.assignation.champNom),
                  _InfoRow(
                      label: 'Région',
                      valeur: widget.assignation.region),
                  _InfoRow(
                      label: 'Type',
                      valeur: widget.assignation.typeIntervention),
                  _InfoRow(
                      label: 'Urgence',
                      valeur: widget.assignation.niveauUrgence.libelle),
                  _InfoRow(
                    label: 'Date souhaitée',
                    valeur: _dateFormatee(widget.assignation.dateSouhaitee),
                  ),

                  const SizedBox(height: 20),

                  // ── Section expert ────────────────────────────
                  if (widget.assignation.estAssignee &&
                      !_modeChangementExpert) ...[
                    const _SectionTitre(
                        titre: 'Expert assigné',
                        icone: Icons.verified_user_outlined),
                    const SizedBox(height: 10),
                    _CarteExpertAssigne(assignation: widget.assignation),
                    const SizedBox(height: 16),
                  ],

                  // ── Mode changement d'expert ───────────────────
                  if (_modeChangementExpert) ...[
                    const _SectionTitre(
                        titre: 'Choisir un nouvel expert',
                        icone: Icons.swap_horiz),
                    const SizedBox(height: 10),
                    expertsAsync.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator()),
                      error: (e, _) =>
                          Text('Erreur : $e'),
                      data: (experts) => Column(
                        children: experts.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ExpertSelectionCardAdmin(
                              expert: e,
                              estSelectionne: _nouvelExpertId == e.id,
                              onSelectionner: () =>
                                  setState(() => _nouvelExpertId = e.id),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() {
                              _modeChangementExpert = false;
                              _nouvelExpertId = null;
                            }),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _nouvelExpertId == null
                                ? null
                                : () => _confirmerChangementExpert(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _adminPrimary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Confirmer'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Actions ───────────────────────────────────
                  if (!_modeChangementExpert) ...[
                    const _SectionTitre(
                        titre: 'Actions', icone: Icons.touch_app_outlined),
                    const SizedBox(height: 12),
                    if (widget.assignation.estAssignee)
                      _BoutonAction(
                        icone: Icons.swap_horiz,
                        label: 'Changer d\'expert',
                        couleur: _adminPrimary,
                        onTap: () =>
                            setState(() => _modeChangementExpert = true),
                      ),
                    const SizedBox(height: 8),
                    if (widget.assignation.expertTelephone != null)
                      _BoutonAction(
                        icone: Icons.phone_outlined,
                        label: 'Contacter l\'expert',
                        couleur: AppColors.primary,
                        onTap: () {
                          // url_launcher tel: — simulé
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Appel : ${widget.assignation.expertTelephone}',
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 8),
                    _BoutonAction(
                      icone: Icons.cancel_outlined,
                      label: 'Annuler l\'assignation',
                      couleur: AppColors.danger,
                      onTap: () => _confirmerAnnulation(context),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmerChangementExpert(BuildContext context) async {
    if (_nouvelExpertId == null) return;
    final ok = await ref.read(assignationProvider.notifier).changerExpert(
          assignationId: widget.assignation.id,
          nouvelExpertId: _nouvelExpertId!,
        );
    if (ok && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expert changé avec succès'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _confirmerAnnulation(BuildContext context) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annuler l\'assignation ?'),
        content: const Text(
            'L\'expert sera notifié et l\'intervention passera en statut non assignée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
    if (confirme == true && context.mounted) {
      await ref
          .read(assignationProvider.notifier)
          .annuler(widget.assignation.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  String _dateFormatee(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── Widgets locaux ────────────────────────────────────────────────────────

class _SectionTitre extends StatelessWidget {
  const _SectionTitre({required this.titre, required this.icone});

  final String titre;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 16, color: const Color(0xFF534AB7)),
        const SizedBox(width: 6),
        Text(
          titre,
          style: AppTypography.textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF534AB7),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.valeur});

  final String label;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTypography.textTheme.bodySmall!.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valeur,
              style: AppTypography.textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteExpertAssigne extends StatelessWidget {
  const _CarteExpertAssigne({required this.assignation});

  final AssignationEntity assignation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF534AB7).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF534AB7).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
                const Color(0xFF534AB7).withValues(alpha: 0.15),
            child: Text(
              _initiales(assignation.expertNom ?? ''),
              style: const TextStyle(
                color: Color(0xFF534AB7),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignation.expertNom ?? 'Expert',
                  style: AppTypography.textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (assignation.expertSpecialite != null)
                  Text(
                    assignation.expertSpecialite!,
                    style: AppTypography.textTheme.bodySmall!.copyWith(
                      color: const Color(0xFF534AB7),
                    ),
                  ),
                if (assignation.expertRegion != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        assignation.expertRegion!,
                        style: AppTypography.textTheme.labelSmall!.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Indicateur disponibilité
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: (assignation.expertDisponible ?? false)
                  ? AppColors.primary
                  : AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  String _initiales(String nom) {
    final parts = nom.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }
}

class _BoutonAction extends StatelessWidget {
  const _BoutonAction({
    required this.icone,
    required this.label,
    required this.couleur,
    required this.onTap,
  });

  final IconData icone;
  final String label;
  final Color couleur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icone, color: couleur, size: 18),
        label: Text(label, style: TextStyle(color: couleur)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: couleur.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
