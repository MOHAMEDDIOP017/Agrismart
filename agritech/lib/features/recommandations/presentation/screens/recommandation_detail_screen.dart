import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/recommandation_model.dart';

/// BottomSheet détail d'une recommandation de culture
class RecommandationDetailSheet extends StatelessWidget {
  const RecommandationDetailSheet({super.key, required this.recommandation});

  final RecommandationModel recommandation;

  Color get _scoreColor {
    final s = recommandation.scoreCompatibilite;
    if (s >= 85) return AppColors.primary;
    if (s >= 70) return AppColors.amber;
    return AppColors.coral;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Poignée
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(24),
                children: [
                  // En-tête
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recommandation.culture,
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              recommandation.periodeIdealePlantation,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Score
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _scoreColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _scoreColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          recommandation.scoreLabel,
                          style: TextStyle(
                            color: _scoreColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: 24),

                  // Statistiques rapides
                  _StatsGrid(recommandation: recommandation),

                  const SizedBox(height: 24),

                  // Conseils agronomiques
                  _Section(
                    title: 'Conseils agronomiques',
                    icon: Icons.tips_and_updates_rounded,
                    child: Text(
                      recommandation.conseilsAgronomiques,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Engrais conseillés
                  _Section(
                    title: 'Engrais conseillés',
                    icon: Icons.science_outlined,
                    child: Column(
                      children: recommandation.engAraisConseillesList
                          .map((e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.fiber_manual_record, size: 8, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text(e, style: Theme.of(context).textTheme.bodyMedium),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Maladies fréquentes
                  _Section(
                    title: 'Maladies fréquentes',
                    icon: Icons.bug_report_outlined,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: recommandation.maladiesFrequentes
                          .map((m) => Chip(
                                label: Text(m, style: const TextStyle(fontSize: 12)),
                                backgroundColor: AppColors.coral.withValues(alpha: 0.08),
                                side: BorderSide(color: AppColors.coral.withValues(alpha: 0.3)),
                              ))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Section post-récolte
                  ExpansionTile(
                    title: const Text('Informations post-récolte'),
                    leading: const Icon(Icons.store_rounded, color: AppColors.amber),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _PostRecolteRow(
                              label: 'Prix marché estimé',
                              value: recommandation.prixLabel,
                              icon: Icons.sell_outlined,
                            ),
                            const SizedBox(height: 12),
                            _PostRecolteRow(
                              label: 'Profit potentiel',
                              value: recommandation.profitLabel,
                              icon: Icons.trending_up_rounded,
                            ),
                            const SizedBox(height: 12),
                            const _PostRecolteRow(
                              label: 'Options',
                              value: 'Vente brute · Transformation',
                              icon: Icons.swap_horiz_rounded,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Bouton fermer
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: const Text('Fermer'),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.recommandation});

  final RecommandationModel recommandation;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (Icons.water_drop_outlined, 'Besoin en eau', recommandation.besoinEauLabel, AppColors.info),
      (Icons.trending_up_rounded, 'Rendement', recommandation.rendementLabel, AppColors.primary),
    ];
    return Row(
      children: stats
          .map((s) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: s == stats.last ? 0 : 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: s.$4.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: s.$4.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Icon(s.$1, color: s.$4, size: 22),
                      const SizedBox(height: 6),
                      Text(s.$3,
                          style: TextStyle(
                              color: s.$4,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text(s.$2,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _PostRecolteRow extends StatelessWidget {
  const _PostRecolteRow({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.amber),
        const SizedBox(width: 10),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: AppColors.textPrimary)),
      ],
    );
  }
}
