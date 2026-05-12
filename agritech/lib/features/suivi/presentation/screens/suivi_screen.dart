import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../champs/presentation/providers/champ_provider.dart';
import '../../../champs/presentation/widgets/statut_badge.dart';

/// Écran suivi état des champs avec vue liste/grille
class SuiviScreen extends ConsumerStatefulWidget {
  const SuiviScreen({super.key});

  @override
  ConsumerState<SuiviScreen> createState() => _SuiviScreenState();
}

class _SuiviScreenState extends ConsumerState<SuiviScreen> {
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final champs = ref.watch(champProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi des champs'),
        actions: [
          // Toggle liste / grille
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ToggleButtons(
              isSelected: [!_isGridView, _isGridView],
              onPressed: (i) => setState(() => _isGridView = i == 1),
              borderRadius: BorderRadius.circular(8),
              selectedColor: AppColors.primary,
              fillColor: AppColors.primary.withValues(alpha: 0.15),
              color: AppColors.textSecondary,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
              children: const [
                Icon(Icons.list_rounded, size: 20),
                Icon(Icons.grid_view_rounded, size: 20),
              ],
            ),
          ),
        ],
      ),
      body: champs.isEmpty
          ? const EmptyStateWidget(
              title: 'Aucun champ suivi',
              message: 'Ajoutez des champs pour suivre leur état.',
              icon: Icons.terrain_outlined,
            )
          : Column(
              children: [
                // Légende des statuts
                _StatutLegend(),
                const Divider(height: 1),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isGridView
                        ? _GridView(champs: champs, key: const ValueKey('grid'))
                        : _ListView(champs: champs, key: const ValueKey('list')),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Légende des statuts ─────────────────────────────────────────────────
class _StatutLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final statuts = [
      (AppConstants.statutPrevu, AppColors.statusPrevu, 'Prévu'),
      (AppConstants.statutEnCours, AppColors.statusEnCours, 'En cours'),
      (AppConstants.statutRecolte, AppColors.statusRecolte, 'Récolte'),
      (AppConstants.statutEnTraitement, AppColors.statusEnTraitement, 'Traitement'),
      (AppConstants.statutAbandonne, AppColors.statusAbandonne, 'Abandonné'),
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: statuts
            .map((s) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration:
                              BoxDecoration(color: s.$2, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(s.$3,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ─── Vue liste ───────────────────────────────────────────────────────────
class _ListView extends StatelessWidget {
  const _ListView({super.key, required this.champs});
  final List<dynamic> champs;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: champs.length,
      itemBuilder: (context, i) => _ChampSuiviListTile(champ: champs[i], index: i),
    );
  }
}

// ─── Vue grille ──────────────────────────────────────────────────────────
class _GridView extends StatelessWidget {
  const _GridView({super.key, required this.champs});
  final List<dynamic> champs;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: champs.length,
      itemBuilder: (context, i) => _ChampSuiviGridCard(champ: champs[i], index: i),
    );
  }
}

// ─── Tuile liste ─────────────────────────────────────────────────────────
class _ChampSuiviListTile extends StatelessWidget {
  const _ChampSuiviListTile({required this.champ, required this.index});
  final dynamic champ;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.terrain_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(champ.nom,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  '${champ.superficie} ha · ${champ.typeSol}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                if (champ.culture != null)
                  Text(
                    champ.culture!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.primary),
                  ),
              ],
            ),
          ),
          StatutBadge(statut: champ.statut),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 80).ms, duration: 350.ms)
        .slideX(begin: 0.1, end: 0);
  }
}

// ─── Card grille ─────────────────────────────────────────────────────────
class _ChampSuiviGridCard extends StatelessWidget {
  const _ChampSuiviGridCard({required this.champ, required this.index});
  final dynamic champ;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.terrain_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 10),
          Text(champ.nom,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
            '${champ.superficie} ha',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          StatutBadge(statut: champ.statut, small: true),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 80).ms, duration: 350.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }
}
