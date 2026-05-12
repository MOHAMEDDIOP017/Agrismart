import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/assets_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../providers/champ_provider.dart';
import '../widgets/statut_badge.dart';

/// Écran détail d'un champ avec Hero animation sur l'image
class ChampDetailScreen extends ConsumerWidget {
  const ChampDetailScreen({super.key, required this.champId});

  final String champId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final champAsync = ref.watch(champByIdProvider(champId));

    return Scaffold(
      body: champAsync.when(
        loading: () => const ShimmerList(count: 3, cardHeight: 120),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (champ) {
          if (champ == null) {
            return const Center(child: Text('Champ introuvable'));
          }

          return CustomScrollView(
            slivers: [
              // SliverAppBar avec Hero image
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                    onPressed: () => context.push('/home/champs/form?id=$champId'),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'champ_image_$champId',
                    child: CachedNetworkImage(
                      imageUrl: champ.photoUrl ?? AssetsConstants.fieldPlaceholder,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.terrain_rounded,
                          color: AppColors.primary,
                          size: 80,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    champ.nom,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                    ),
                  ),
                ),
              ),

              // Contenu
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statut + culture
                        Row(
                          children: [
                            StatutBadge(statut: champ.statut),
                            const SizedBox(width: 8),
                            if (champ.culture != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.grass_rounded, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      champ.culture!,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ).animate().fadeIn(duration: 400.ms),

                        const SizedBox(height: 20),

                        // Infos principales
                        const _SectionTitle(title: 'Informations'),
                        const SizedBox(height: 12),
                        _InfoGrid(champ: champ),

                        const SizedBox(height: 24),

                        // Données agronomiques
                        if (champ.ph != null) ...[
                          const _SectionTitle(title: 'Données agronomiques'),
                          const SizedBox(height: 12),
                          _AgroDataGrid(
                            ph: champ.ph,
                            azote: champ.azote,
                            phosphore: champ.phosphore,
                            potassium: champ.potassium,
                            humidite: champ.humidite,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Localisation
                        if (champ.latitude != null) ...[
                          const _SectionTitle(title: 'Localisation GPS'),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_rounded, color: AppColors.primary),
                                const SizedBox(width: 12),
                                Text(
                                  champ.localisation,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Dates
                        const _SectionTitle(title: 'Historique'),
                        const SizedBox(height: 12),
                        _TimelineItem(
                          label: 'Date de création',
                          date: DateFormatter.formatDate(champ.dateCreation),
                          icon: Icons.add_circle_outline,
                          color: AppColors.primary,
                        ),
                        if (champ.dateModification != null)
                          _TimelineItem(
                            label: 'Dernière modification',
                            date: DateFormatter.formatDate(champ.dateModification!),
                            icon: Icons.edit_outlined,
                            color: AppColors.amber,
                          ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.headlineSmall);
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.champ});

  final dynamic champ;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: [
        _InfoTile(icon: Icons.straighten_rounded, label: 'Superficie', value: champ.superficieFormatee),
        _InfoTile(icon: Icons.layers_outlined, label: 'Type de sol', value: champ.typeSol),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                Text(value, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgroDataGrid extends StatelessWidget {
  const _AgroDataGrid({
    this.ph,
    this.azote,
    this.phosphore,
    this.potassium,
    this.humidite,
  });

  final double? ph;
  final double? azote;
  final double? phosphore;
  final double? potassium;
  final double? humidite;

  Color get _phColor {
    if (ph == null) return AppColors.textSecondary;
    if (ph! < 4.5) return AppColors.danger;
    if (ph! < 6.0) return AppColors.amber;
    if (ph! < 7.5) return AppColors.primary;
    return AppColors.info;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // pH avec barre colorée
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _phColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _phColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('pH du sol', style: Theme.of(context).textTheme.labelMedium),
                  Text(
                    ph?.toStringAsFixed(1) ?? '--',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: _phColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (ph ?? 7) / 14,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(_phColor),
                    minHeight: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _NpkTile(label: 'Azote (N)', value: azote, unit: 'kg/ha', color: AppColors.primary)),
            const SizedBox(width: 10),
            Expanded(child: _NpkTile(label: 'Phosphore (P)', value: phosphore, unit: 'kg/ha', color: AppColors.amber)),
            const SizedBox(width: 10),
            Expanded(child: _NpkTile(label: 'Potassium (K)', value: potassium, unit: 'kg/ha', color: AppColors.coral)),
          ],
        ),
        const SizedBox(height: 10),
        _NpkTile(label: 'Humidité observée', value: humidite, unit: '%', color: AppColors.info, wide: true),
      ],
    );
  }
}

class _NpkTile extends StatelessWidget {
  const _NpkTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.wide = false,
  });

  final String label;
  final double? value;
  final String unit;
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value?.toStringAsFixed(0) ?? '--',
                style: TextStyle(
                  color: color,
                  fontSize: wide ? 22 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(unit, style: TextStyle(color: color, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.label,
    required this.date,
    required this.icon,
    required this.color,
  });

  final String label;
  final String date;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              Text(date, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0);
  }
}
