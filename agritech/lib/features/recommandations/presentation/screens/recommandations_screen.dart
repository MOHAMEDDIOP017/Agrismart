import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../champs/presentation/providers/champ_provider.dart';
import '../providers/recommandation_provider.dart';
import '../widgets/culture_card.dart';
import 'recommandation_detail_screen.dart';

/// Écran principal des recommandations IA
class RecommandationsScreen extends ConsumerWidget {
  const RecommandationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recommandationProvider);
    final champsAsync = ref.watch(champProvider);
    final champs = champsAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Recommandations IA')),
      body: state.isAnalysing
          ? _AnalysisProgress(message: state.progressMessage ?? '')
          : state.recommandations.isEmpty
              ? _SelectionView(
                  champs: champs,
                  champSelectionne: state.champIdSelectionne,
                  onSelect: (id) =>
                      ref.read(recommandationProvider.notifier).selectChamp(id),
                  onAnalyse: () {
                    final id = state.champIdSelectionne;
                    if (id != null) {
                      ref
                          .read(recommandationProvider.notifier)
                          .analyserAvecIA(id);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Veuillez sélectionner un champ')),
                      );
                    }
                  },
                )
              : _ResultsView(
                  state: state,
                  onReset: () => ref.invalidate(recommandationProvider),
                ),
    );
  }
}

// ─── Vue sélection champ ────────────────────────────────────────────────
class _SelectionView extends StatelessWidget {
  const _SelectionView({
    required this.champs,
    required this.champSelectionne,
    required this.onSelect,
    required this.onAnalyse,
  });

  final List<dynamic> champs;
  final String? champSelectionne;
  final void Function(String) onSelect;
  final VoidCallback onAnalyse;

  @override
  Widget build(BuildContext context) {
    if (champs.isEmpty) {
      return const EmptyStateWidget(
        title: 'Aucun champ disponible',
        message: 'Ajoutez un champ pour obtenir des recommandations.',
        icon: Icons.terrain_outlined,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_rounded, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analyse IA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Sélectionnez un champ pour obtenir les meilleures cultures adaptées à votre sol.',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 24),
          Text('Choisir un champ',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),

          ...champs.map((champ) => RadioListTile<String>(
                title: Text(champ.nom),
                subtitle: Text('${champ.superficie} ha · ${champ.typeSol}'),
                value: champ.id,
                groupValue: champSelectionne,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: champSelectionne == champ.id
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : null,
                onChanged: (v) => v != null ? onSelect(v) : null,
              ).animate().fadeIn(delay: (champs.indexOf(champ) * 80).ms)),

          const SizedBox(height: 32),
          AppButton(
            label: 'Analyser avec l\'IA',
            onPressed: onAnalyse,
            icon: Icons.psychology_rounded,
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

// ─── Animation d'analyse IA ─────────────────────────────────────────────
class _AnalysisProgress extends StatelessWidget {
  const _AnalysisProgress({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: AppColors.primary,
                size: 60,
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.1, 1.1),
                  duration: 800.ms,
                )
                .then()
                .scale(
                  begin: const Offset(1.1, 1.1),
                  end: const Offset(0.9, 0.9),
                  duration: 800.ms,
                ),
            const SizedBox(height: 32),
            const LinearProgressIndicator(
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                message,
                key: ValueKey(message),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Vue résultats ───────────────────────────────────────────────────────
class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.state, required this.onReset});

  final RecommandationState state;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Bandeau résultats
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: AppColors.primary.withValues(alpha: 0.07),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${state.recommandations.length} cultures recommandées',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: onReset,
                child: const Text('Réanalyser'),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: state.recommandations.length,
            itemBuilder: (context, index) => CultureCard(
              recommandation: state.recommandations[index],
              index: index,
              onTap: () => _showDetail(context, state.recommandations[index]),
            ),
          ),
        ),
      ],
    );
  }

  void _showDetail(BuildContext context, dynamic recommandation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecommandationDetailSheet(recommandation: recommandation),
    );
  }
}
