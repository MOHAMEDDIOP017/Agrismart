import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../champs/domain/entities/champ_entity.dart';
import '../../../champs/presentation/providers/champ_provider.dart';
import '../../data/models/culture_en_champ_model.dart';
import '../providers/suivi_provider.dart';
import '../../../../shared/widgets/widgets.dart';

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
              color: context.couleurs.primaire.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ToggleButtons(
              isSelected: [!_isGridView, _isGridView],
              onPressed: (i) => setState(() => _isGridView = i == 1),
              borderRadius: BorderRadius.circular(8),
              selectedColor: context.couleurs.primaire,
              fillColor: context.couleurs.primaire.withValues(alpha: 0.15),
              color: context.couleurs.texteSecondaire,
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
        error: (e, _) => EtatErreur(
          erreur: e,
          onReessayer: () => ref.invalidate(champProvider),
        ),
        data: (champs) {
          if (champs.isEmpty) {
            return const EtatVide(
              titre: 'Aucun champ suivi',
              message: 'Ajoutez des champs pour suivre leur état.',
              sujet: SujetIllustration.parcelle,
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
      (AppConstants.statutPrevu, context.couleurs.statutPrevu, 'Prévu'),
      (AppConstants.statutEnCours, context.couleurs.statutEnCours, 'En cours'),
      (AppConstants.statutRecolte, context.couleurs.statutRecolte, 'Récolte'),
      (
        AppConstants.statutEnTraitement,
        context.couleurs.statutEnTraitement,
        'Traitement'
      ),
      (
        AppConstants.statutAbandonne,
        context.couleurs.statutAbandonne,
        'Abandonné'
      ),
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
                              ?.copyWith(
                                  color: context.couleurs.texteSecondaire)),
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
      itemBuilder: (context, i) => ApparitionCascade(
        index: i,
        child: _ChampSuiviListTile(champ: champs[i], index: i),
      ),
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
      itemBuilder: (context, i) => ApparitionCascade(
        index: i,
        child: _ChampSuiviGridCard(champ: champs[i], index: i),
      ),
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
        color: context.couleurs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.couleurs.bordure),
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
                  color: context.couleurs.primaire.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.terrain_rounded,
                    color: context.couleurs.primaire, size: 24),
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
                            color: context.couleurs.texteSecondaire,
                          ),
                    ),
                  ],
                ),
              ),
              BadgeStatut.statutChamp(champ.statut),
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
    );
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
        color: context.couleurs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.couleurs.bordure),
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
              color: context.couleurs.primaire.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.terrain_rounded,
                color: context.couleurs.primaire, size: 22),
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
                ?.copyWith(color: context.couleurs.texteSecondaire),
          ),
          if (activeCulture != null) ...[
            const SizedBox(height: 6),
            Text(
              activeCulture.cultureName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.couleurs.primaire,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: activeCulture.progression,
              backgroundColor: context.couleurs.primaire.withValues(alpha: 0.1),
              color: context.couleurs.primaire,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
          const Spacer(),
          BadgeStatut.statutChamp(champ.statut),
        ],
      ),
    );
  }
}

// ─── Ligne mini culture ───────────────────────────────────────────────────
class _CultureMiniRow extends StatelessWidget {
  const _CultureMiniRow({required this.culture});
  final CultureEnChampModel culture;

  Color _couleurStatut(BuildContext context) {
    switch (culture.statutCycle) {
      case 'EN_COURS':
        return context.couleurs.primaire;
      case 'RECOLTE':
        return context.couleurs.succes;
      case 'ABANDONNE':
        return context.couleurs.erreur;
      default:
        return context.couleurs.texteSecondaire;
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
              Icon(Icons.grass_rounded,
                  size: 14, color: _couleurStatut(context)),
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
                  color: _couleurStatut(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  culture.statutLabel,
                  style: TextStyle(
                    color: _couleurStatut(context),
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
                    backgroundColor:
                        _couleurStatut(context).withValues(alpha: 0.1),
                    color: _couleurStatut(context),
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
                      ?.copyWith(color: context.couleurs.texteSecondaire),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
