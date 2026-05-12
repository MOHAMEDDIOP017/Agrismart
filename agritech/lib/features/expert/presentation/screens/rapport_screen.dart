import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/expert_provider.dart';

/// Génération et export de rapports d'activité Expert
class RapportScreen extends ConsumerStatefulWidget {
  const RapportScreen({super.key});

  @override
  ConsumerState<RapportScreen> createState() => _RapportScreenState();
}

class _RapportScreenState extends ConsumerState<RapportScreen> {
  DateTimeRange _periode = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  bool _generation = false;

  @override
  Widget build(BuildContext context) {
    final profilAsync = ref.watch(profilExpertProvider);
    final diagnosticsState = ref.watch(diagnosticsNotifier).valueOrNull;
    final interventions = ref.watch(interventionsProvider).valueOrNull ?? [];
    final conseils = ref.watch(conseilsProvider).valueOrNull ?? [];

    final totalDiags = diagnosticsState?.diagnostics.length ?? 0;
    final totalIntvs = interventions.length;
    final totalConseils = conseils.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Text('Rapports d\'activité',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Sélection période ──────────────────────────────────
          _sectionTitle('Période du rapport'),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final r = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                initialDateRange: _periode,
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primary,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (r != null) setState(() => _periode = r);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    '${DateFormat('d MMM yyyy', 'fr_FR').format(_periode.start)} '
                    '→ ${DateFormat('d MMM yyyy', 'fr_FR').format(_periode.end)}',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── KPI récapitulatifs ─────────────────────────────────
          _sectionTitle('Aperçu de la période'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: [
              _kpiRecap('Diagnostics traités', '$totalDiags', AppColors.info),
              _kpiRecap('Interventions', '$totalIntvs', AppColors.amber),
              _kpiRecap('Conseils envoyés', '$totalConseils', AppColors.primary),
              profilAsync.when(
                data: (e) => _kpiRecap('Taux précision IA',
                    e.tauxPrecisionFormate, AppColors.coral),
                loading: () => _kpiRecap('Taux précision IA', '—', AppColors.coral),
                error: (_, __) => _kpiRecap('Taux précision IA', '—', AppColors.coral),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Graphique BarChart ─────────────────────────────────
          _sectionTitle('Diagnostics par semaine'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 6,
                    barGroups: [
                      _barGroup(0, 3),
                      _barGroup(1, 5),
                      _barGroup(2, 2),
                      _barGroup(3, 4),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          getTitlesWidget: (v, _) => Text(
                            '${v.toInt()}',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            const labels = ['S1', 'S2', 'S3', 'S4'];
                            return Text(
                              labels[v.toInt() % 4],
                              style: GoogleFonts.poppins(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      drawHorizontalLine: true,
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: AppColors.border,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── PieChart répartition maladies ─────────────────────
          _sectionTitle('Répartition des maladies détectées'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: 35,
                            title: '35%',
                            color: AppColors.danger,
                            radius: 50,
                            titleStyle: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          PieChartSectionData(
                            value: 25,
                            title: '25%',
                            color: AppColors.amber,
                            radius: 50,
                            titleStyle: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          PieChartSectionData(
                            value: 20,
                            title: '20%',
                            color: AppColors.primary,
                            radius: 50,
                            titleStyle: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          PieChartSectionData(
                            value: 20,
                            title: '20%',
                            color: AppColors.info,
                            radius: 50,
                            titleStyle: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _legendItem('Mildiou', AppColors.danger, '35%'),
                        _legendItem('Anthracnose', AppColors.amber, '25%'),
                        _legendItem('Cercosporiose', AppColors.primary, '20%'),
                        _legendItem('Autres', AppColors.info, '20%'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Boutons export ─────────────────────────────────────
          _sectionTitle('Exporter le rapport'),
          const SizedBox(height: 10),
          if (_generation)
            Column(
              children: [
                LinearProgressIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 10),
                Text('Génération du rapport en cours...',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 20),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generation ? null : _exporterPDF,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Exporter PDF'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _generation ? null : _partager,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Partager'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y) => BarChartGroupData(
        x: x,
        barRods: [
          BarChartRodData(
            toY: y,
            color: AppColors.primary,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );

  Widget _kpiRecap(String label, String valeur, Color couleur) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: couleur.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(valeur,
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.bold, color: couleur)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );

  Widget _legendItem(String label, Color couleur, String pct) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: couleur, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
            Text(pct,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _sectionTitle(String t) => Text(
        t,
        style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
      );

  Future<void> _exporterPDF() async {
    setState(() => _generation = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _generation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rapport PDF généré avec succès !'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _partager() async {
    setState(() => _generation = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() => _generation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rapport prêt à partager.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
}
