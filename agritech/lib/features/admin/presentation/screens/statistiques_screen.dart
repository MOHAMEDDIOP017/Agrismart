import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/statistiques_globales_entity.dart';
import '../providers/admin_provider.dart';
import '../widgets/kpi_admin_card.dart';

/// Écran des statistiques globales de la plateforme (vue Admin)
class StatistiquesScreen extends ConsumerWidget {
  const StatistiquesScreen({super.key});

  static const Color _adminPrimary = Color(0xFF534AB7);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etatAsync = ref.watch(statistiquesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _adminPrimary,
        title: const Text(
          'Statistiques globales',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref
                .read(statistiquesProvider.notifier)
                .rafraichir(),
          ),
        ],
      ),
      body: etatAsync.when(
        loading: () => _ShimmerStats(),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (etat) => _ContenuStats(etat: etat, ref: ref),
      ),
    );
  }
}

class _ContenuStats extends StatelessWidget {
  const _ContenuStats({required this.etat, required this.ref});

  final StatistiquesState etat;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final stats = etat.statistiques;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Sélecteur de période ────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PeriodeStatistiques.values.map((p) {
                final sel = etat.periode == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(p.libelle),
                    selected: sel,
                    onSelected: (_) => ref
                        .read(statistiquesProvider.notifier)
                        .changerPeriode(p),
                    selectedColor:
                        const Color(0xFF534AB7).withValues(alpha: 0.15),
                    checkmarkColor: const Color(0xFF534AB7),
                    labelStyle: TextStyle(
                      color: sel
                          ? const Color(0xFF534AB7)
                          : AppColors.textSecondary,
                      fontWeight:
                          sel ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── KPIs détaillés ───────────────────────────────────────
          const _SectionTitre(titre: 'Indicateurs clés'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              KpiAdminCard(
                titre: 'Recommandations',
                valeur: '${stats.totalRecommandations}',
                icone: Icons.tips_and_updates_outlined,
                couleur: AppColors.primary,
              ),
              KpiAdminCard(
                titre: 'Champs enregistrés',
                valeur: '${stats.totalChamps}',
                icone: Icons.terrain_outlined,
                couleur: AppColors.primary,
              ),
              KpiAdminCard(
                titre: 'Interventions réalisées',
                valeur: '${stats.totalInterventions}',
                icone: Icons.engineering_outlined,
                couleur: AppColors.amber,
              ),
              KpiAdminCard(
                titre: 'Conseils envoyés',
                valeur: '${stats.totalConseils}',
                icone: Icons.chat_outlined,
                couleur: AppColors.info,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Top cultures recommandées ─────────────────────────────
          if (stats.topCulturesRecommandees.isNotEmpty) ...[
            const _SectionTitre(titre: 'Cultures les plus recommandées'),
            const SizedBox(height: 12),
            ...stats.topCulturesRecommandees
                .map((c) => _CultureRecoCard(culture: c)),
            const SizedBox(height: 20),
          ],

          // ── BarChart — Activité hebdomadaire ─────────────────────
          const _SectionTitre(titre: 'Activité par semaine'),
          const SizedBox(height: 12),
          _CarteGraphique(
            child: _BarChartActivite(donnees: stats.donneesBarChart),
          ),

          const SizedBox(height: 20),

          // ── PieChart — Répartition utilisateurs ──────────────────
          const _SectionTitre(titre: 'Répartition des utilisateurs'),
          const SizedBox(height: 12),
          _CarteGraphique(
            child: _PieChartUtilisateurs(stats: stats),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Graphiques ──────────────────────────────────────────────────────────

class _BarChartActivite extends StatelessWidget {
  const _BarChartActivite({required this.donnees});

  final List<DonneeBarChart> donnees;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: donnees.asMap().entries.map((e) {
            final i = e.key;
            final d = e.value;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: d.recommandations,
                  color: AppColors.amber,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Text(
                  donnees[v.toInt()].semaine,
                  style: AppTypography.textTheme.labelSmall!
                      .copyWith(fontSize: 10),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: AppTypography.textTheme.labelSmall!
                      .copyWith(fontSize: 9),
                ),
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }
}

class _PieChartUtilisateurs extends StatelessWidget {
  const _PieChartUtilisateurs({required this.stats});

  final StatistiquesGlobalesEntity stats;

  @override
  Widget build(BuildContext context) {
    final total = stats.totalUtilisateurs;
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: stats.totalAgriculteurs.toDouble(),
                  color: AppColors.primary,
                  title:
                      '${((stats.totalAgriculteurs / total) * 100).toInt()}%',
                  titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                  radius: 60,
                ),
                PieChartSectionData(
                  value: stats.totalExperts.toDouble(),
                  color: const Color(0xFF534AB7),
                  title:
                      '${((stats.totalExperts / total) * 100).toInt()}%',
                  titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                  radius: 60,
                ),
                PieChartSectionData(
                  value: stats.totalAdmins.toDouble(),
                  color: const Color(0xFF888780),
                  title:
                      '${((stats.totalAdmins / total) * 100).toInt()}%',
                  titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                  radius: 60,
                ),
              ],
              centerSpaceRadius: 40,
              sectionsSpace: 3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legende(couleur: AppColors.primary,
                label: 'Agriculteurs (${stats.totalAgriculteurs})'),
            const SizedBox(width: 16),
            _Legende(couleur: const Color(0xFF534AB7),
                label: 'Experts (${stats.totalExperts})'),
            const SizedBox(width: 16),
            _Legende(couleur: const Color(0xFF888780),
                label: 'Admins (${stats.totalAdmins})'),
          ],
        ),
      ],
    );
  }
}

// ── Widgets utilitaires ───────────────────────────────────────────────────

class _SectionTitre extends StatelessWidget {
  const _SectionTitre({required this.titre});

  final String titre;

  @override
  Widget build(BuildContext context) {
    return Text(
      titre,
      style: AppTypography.textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _CarteGraphique extends StatelessWidget {
  const _CarteGraphique({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Legende extends StatelessWidget {
  const _Legende({required this.couleur, required this.label});

  final Color couleur;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: couleur, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: AppTypography.textTheme.labelSmall!.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            )),
      ],
    );
  }
}

class _ShimmerStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            4,
            (_) => Container(
              height: 120,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top cultures recommandées ─────────────────────────────────────────────

class _CultureRecoCard extends StatelessWidget {
  const _CultureRecoCard({required this.culture});

  final CultureStatReco culture;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grass_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  culture.nom,
                  style: AppTypography.textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${culture.nombreRecommandations}',
                style: AppTypography.textTheme.labelSmall!.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'reco.',
                style: AppTypography.textTheme.labelSmall!.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: culture.progression,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
