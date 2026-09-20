import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/recommandation_model.dart';
import '../providers/post_recolte_provider.dart';

/// BottomSheet détail d'une recommandation de culture
class RecommandationDetailSheet extends ConsumerWidget {
  const RecommandationDetailSheet({super.key, required this.recommandation});

  final RecommandationModel recommandation;

  Color get _scoreColor {
    final s = recommandation.scoreCompatibilite;
    if (s >= 85) return AppColors.primary;
    if (s >= 70) return AppColors.amber;
    return AppColors.coral;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

                  // Section post-récolte statique (estimations locales)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.store_rounded,
                                  color: AppColors.amber, size: 18),
                              const SizedBox(width: 8),
                              Text('Estimations post-récolte',
                                  style: Theme.of(context).textTheme.titleLarge),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _PostRecolteRow(
                            label: 'Prix marché estimé',
                            value: recommandation.prixLabel,
                            icon: Icons.sell_outlined,
                          ),
                          const SizedBox(height: 8),
                          _PostRecolteRow(
                            label: 'Profit potentiel',
                            value: recommandation.profitLabel,
                            icon: Icons.trending_up_rounded,
                          ),
                          if (recommandation.savedId != null) ...[
                            const SizedBox(height: 16),
                            _PostRecolteButton(savedId: recommandation.savedId!),
                          ],
                        ],
                      ),
                    ),
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

/// Bouton + affichage des scénarios post-récolte depuis le backend.
class _PostRecolteButton extends ConsumerStatefulWidget {
  const _PostRecolteButton({required this.savedId});
  final String savedId;

  @override
  ConsumerState<_PostRecolteButton> createState() => _PostRecolteButtonState();
}

class _PostRecolteButtonState extends ConsumerState<_PostRecolteButton> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return AppButton(
        label: 'Analyse post-récolte détaillée',
        icon: Icons.agriculture_rounded,
        isOutlined: true,
        color: AppColors.amber,
        onPressed: () => setState(() => _expanded = true),
      );
    }

    final scenariosAsync = ref.watch(postRecolteProvider(widget.savedId));
    return scenariosAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(
        'Impossible de charger les scénarios : $e',
        style: const TextStyle(color: AppColors.danger, fontSize: 12),
      ),
      data: (scenarios) {
        if (scenarios.isEmpty) {
          return Text(
            'Aucun scénario disponible.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: scenarios.map((s) => _ScenarioCard(scenario: s)).toList(),
        );
      },
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.scenario});
  final Map<String, dynamic> scenario;

  @override
  Widget build(BuildContext context) {
    final type = scenario['typeRec'] as String? ?? '';
    final isTransfo = type == 'TRANSFORMATION';
    final profit = (scenario['profitPotentiel'] as num? ?? 0).toInt();
    final cout = (scenario['coutTransformation'] as num? ?? 0).toInt();
    final score = ((scenario['score'] as num? ?? 0) * 100).round();
    final color = isTransfo ? AppColors.primary : AppColors.amber;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isTransfo ? Icons.precision_manufacturing_outlined : Icons.sell_outlined,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isTransfo ? 'Transformation' : 'Vente brute',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Score $score%',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoLigne(label: 'Profit potentiel', value: '$profit FCFA'),
          if (isTransfo && cout > 0)
            _InfoLigne(label: 'Coût transformation', value: '$cout FCFA'),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.15, end: 0);
  }
}

class _InfoLigne extends StatelessWidget {
  const _InfoLigne({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall),
        ],
      ),
    );
  }
}
