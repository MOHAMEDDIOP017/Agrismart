import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../champs/domain/entities/champ_entity.dart';
import '../../../champs/presentation/providers/champ_provider.dart';
import '../../../champs/presentation/widgets/statut_badge.dart';
import '../../data/models/culture_en_champ_model.dart';
import '../providers/suivi_provider.dart';

/// Écran suivi état des champs — cultures plantées, cycle, progression
class SuiviScreen extends ConsumerStatefulWidget {
  const SuiviScreen({super.key});

  @override
  ConsumerState<SuiviScreen> createState() => _SuiviScreenState();
}

class _SuiviScreenState extends ConsumerState<SuiviScreen> {
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final champsAsync = ref.watch(champProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi des champs'),
        actions: [
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
      body: champsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (champs) {
          if (champs.isEmpty) {
            return const EmptyStateWidget(
              title: 'Aucun champ suivi',
              message: 'Ajoutez des champs pour suivre leur état.',
              icon: Icons.terrain_outlined,
            );
          }
          return Column(
            children: [
              _StatutLegend(),
              const Divider(height: 1),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(champProvider);
                    for (final c in champs) {
                      ref.invalidate(culturesEnChampProvider(c.id));
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isGridView
                        ? _GridView(champs: champs, key: const ValueKey('grid'))
                        : _ListView(
                            champs: champs, key: const ValueKey('list')),
                  ),
                ),
              ),
            ],
          );
        },
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
                          decoration: BoxDecoration(
                              color: s.$2, shape: BoxShape.circle)),
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
  final List<ChampEntity> champs;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: champs.length,
      itemBuilder: (context, i) =>
          _ChampSuiviListTile(champ: champs[i], index: i),
    );
  }
}

// ─── Vue grille ──────────────────────────────────────────────────────────
class _GridView extends StatelessWidget {
  const _GridView({super.key, required this.champs});
  final List<ChampEntity> champs;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: champs.length,
      itemBuilder: (context, i) =>
          _ChampSuiviGridCard(champ: champs[i], index: i),
    );
  }
}

// ─── Tuile liste ─────────────────────────────────────────────────────────
class _ChampSuiviListTile extends ConsumerWidget {
  const _ChampSuiviListTile({required this.champ, required this.index});
  final ChampEntity champ;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final culturesAsync = ref.watch(culturesEnChampProvider(champ.id));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.terrain_rounded,
                    color: AppColors.primary, size: 24),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              StatutBadge(statut: champ.statut),
            ],
          ),
          // ── Cultures depuis le backend ──────────────────────────
          culturesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (cultures) {
              if (cultures.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  ...cultures.map((c) => _CultureMiniRow(culture: c)),
                ],
              );
            },
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 80).ms, duration: 350.ms)
        .slideX(begin: 0.1, end: 0);
  }
}

// ─── Card grille ─────────────────────────────────────────────────────────
class _ChampSuiviGridCard extends ConsumerWidget {
  const _ChampSuiviGridCard({required this.champ, required this.index});
  final ChampEntity champ;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final culturesAsync = ref.watch(culturesEnChampProvider(champ.id));
    final cultures = culturesAsync.valueOrNull ?? [];
    final activeCulture =
        cultures.where((c) => c.statutCycle == 'EN_COURS').firstOrNull;

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
            child: const Icon(Icons.terrain_rounded,
                color: AppColors.primary, size: 22),
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
          if (activeCulture != null) ...[
            const SizedBox(height: 6),
            Text(
              activeCulture.cultureName,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: activeCulture.progression,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              color: AppColors.primary,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
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

// ─── Ligne mini culture ───────────────────────────────────────────────────
class _CultureMiniRow extends StatelessWidget {
  const _CultureMiniRow({required this.culture});
  final CultureEnChampModel culture;

  Color get _couleurStatut {
    switch (culture.statutCycle) {
      case 'EN_COURS':
        return AppColors.primary;
      case 'RECOLTE':
        return AppColors.success;
      case 'ABANDONNE':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grass_rounded, size: 14, color: _couleurStatut),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  culture.cultureName,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _couleurStatut.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  culture.statutLabel,
                  style: TextStyle(
                    color: _couleurStatut,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (culture.dureeCycleDays != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: culture.progression,
                    backgroundColor: _couleurStatut.withValues(alpha: 0.1),
                    color: _couleurStatut,
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'J+${culture.joursEcoules}/${culture.dureeCycleDays}j',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
