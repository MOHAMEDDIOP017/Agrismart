import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../../../champs/presentation/providers/champ_provider.dart';
import '../../../champs/domain/entities/champ_entity.dart';
import '../providers/meteo_provider.dart';

class MeteoScreen extends ConsumerStatefulWidget {
  const MeteoScreen({super.key});

  @override
  ConsumerState<MeteoScreen> createState() => _MeteoScreenState();
}

class _MeteoScreenState extends ConsumerState<MeteoScreen> {
  String? _champIdSelectionne;

  @override
  Widget build(BuildContext context) {
    final champsAsync = ref.watch(champProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Météo locale'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(meteoParChampProvider);
              ref.invalidate(previsionsMeteoProvider);
            },
          ),
        ],
      ),
      body: champsAsync.when(
        loading: () => const ShimmerList(count: 4, cardHeight: 80),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
              const SizedBox(height: 12),
              Text('Erreur : $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(champProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (champs) {
          if (champs.isEmpty) {
            return const EmptyStateWidget(
              title: 'Aucun champ enregistré',
              message:
                  'Ajoutez un champ pour consulter la météo locale de votre zone.',
              icon: Icons.wb_sunny_outlined,
            );
          }

          // Sélection du premier champ par défaut
          _champIdSelectionne ??= champs.first.id;
          final champId = _champIdSelectionne!;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(meteoParChampProvider);
              ref.invalidate(previsionsMeteoProvider);
            },
            child: CustomScrollView(
              slivers: [
                // ─── Sélecteur de champ ────────────────────────────────
                SliverToBoxAdapter(
                  child: _ChampSelector(
                    champs: champs,
                    champIdSelectionne: champId,
                    onChanged: (id) =>
                        setState(() => _champIdSelectionne = id),
                  ).animate().fadeIn(duration: 300.ms),
                ),

                // ─── Météo actuelle ────────────────────────────────────
                SliverToBoxAdapter(
                  child: _MeteoActuelleSection(champId: champId),
                ),

                // ─── Prévisions 5 jours ───────────────────────────────
                SliverToBoxAdapter(
                  child: _PrevisionsSection(champId: champId),
                ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Sélecteur de champ ───────────────────────────────────────────────────

class _ChampSelector extends StatelessWidget {
  const _ChampSelector({
    required this.champs,
    required this.champIdSelectionne,
    required this.onChanged,
  });

  final List<ChampEntity> champs;
  final String champIdSelectionne;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Champ sélectionné',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.textSecondary, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: champs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final champ = champs[i];
                final selected = champ.id == champIdSelectionne;
                return GestureDetector(
                  onTap: () => onChanged(champ.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        champ.nom,
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.primary,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Météo actuelle ───────────────────────────────────────────────────────

class _MeteoActuelleSection extends ConsumerWidget {
  const _MeteoActuelleSection({required this.champId});
  final String champId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meteoAsync = ref.watch(meteoParChampProvider(champId));

    return meteoAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: ShimmerList(count: 1, cardHeight: 180),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Données météo indisponibles.\nVérifiez votre connexion ou la clé API.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (meteo) {
        if (meteo == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _CarteMeteoActuelle(meteo: meteo)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0),
        );
      },
    );
  }
}

class _CarteMeteoActuelle extends StatelessWidget {
  const _CarteMeteoActuelle({required this.meteo});
  final dynamic meteo;

  IconData get _icone {
    switch (meteo.icone as String) {
      case 'sunny':
        return Icons.wb_sunny_rounded;
      case 'rainy':
        return Icons.umbrella_rounded;
      case 'stormy':
        return Icons.thunderstorm_rounded;
      default:
        return Icons.cloud_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icone, color: Colors.white, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meteo.temperatureLabel as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    Text(
                      (meteo.description as String).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatMini(
                icon: Icons.water_drop_outlined,
                label: 'Humidité',
                value: meteo.humiditeLabel as String,
              ),
              _StatMini(
                icon: Icons.water_outlined,
                label: 'Pluvio.',
                value: meteo.pluviometrieLabel as String,
              ),
              _StatMini(
                icon: Icons.air_rounded,
                label: 'Vent',
                value: meteo.ventLabel as String,
              ),
              _StatMini(
                icon: Icons.thermostat_rounded,
                label: 'Min/Max',
                value:
                    '${(meteo.temperatureMin as double).toInt()}° / ${(meteo.temperatureMax as double).toInt()}°',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Prévisions ───────────────────────────────────────────────────────────

class _PrevisionsSection extends ConsumerWidget {
  const _PrevisionsSection({required this.champId});
  final String champId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previsionsAsync = ref.watch(previsionsMeteoProvider(champId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Prévisions 5 jours',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          previsionsAsync.when(
            loading: () => const ShimmerList(count: 5, cardHeight: 64),
            error: (e, _) => Text(
              'Prévisions indisponibles',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            data: (previsions) {
              if (previsions.isEmpty) {
                return const Text('Aucune prévision disponible');
              }
              return Column(
                children: previsions
                    .asMap()
                    .entries
                    .map((e) => _PrevisionTile(
                          prevision: e.value,
                          index: e.key,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PrevisionTile extends StatelessWidget {
  const _PrevisionTile({required this.prevision, required this.index});

  final Map<String, dynamic> prevision;
  final int index;

  IconData get _icone {
    final desc =
        (prevision['description'] as String? ?? '').toLowerCase();
    if (desc.contains('pluie') || desc.contains('averse')) {
      return Icons.umbrella_rounded;
    }
    if (desc.contains('orage')) return Icons.thunderstorm_rounded;
    if (desc.contains('nuage') || desc.contains('couvert')) {
      return Icons.cloud_rounded;
    }
    return Icons.wb_sunny_rounded;
  }

  Color get _iconeColor {
    final desc =
        (prevision['description'] as String? ?? '').toLowerCase();
    if (desc.contains('pluie') || desc.contains('averse')) {
      return AppColors.info;
    }
    if (desc.contains('orage')) return AppColors.coral;
    if (desc.contains('nuage') || desc.contains('couvert')) {
      return AppColors.textSecondary;
    }
    return AppColors.amber;
  }

  @override
  Widget build(BuildContext context) {
    final tempMax =
        ((prevision['temperature_max'] ?? prevision['temperature'] ?? 0) as num)
            .toInt();
    final tempMin =
        ((prevision['temperature_min'] ?? 0) as num).toInt();
    final pluvio =
        ((prevision['pluviometrie'] ?? 0) as num).toDouble();
    final label = prevision['date_label'] as String? ??
        prevision['dt_txt'] as String? ??
        '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(_icone, color: _iconeColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (pluvio > 0)
            Row(
              children: [
                const Icon(Icons.water_drop_outlined,
                    size: 14, color: AppColors.info),
                const SizedBox(width: 4),
                Text(
                  '${pluvio.toStringAsFixed(0)} mm',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.info),
                ),
                const SizedBox(width: 12),
              ],
            ),
          Text(
            '$tempMin°',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: 6),
          const Text('—'),
          const SizedBox(width: 6),
          Text(
            '$tempMax°C',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 80).ms, duration: 300.ms)
        .slideX(begin: 0.1, end: 0);
  }
}
