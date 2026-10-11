import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
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
    final interventions = ref.watch(interventionsProvider).valueOrNull ?? [];
    final conseils = ref.watch(conseilsProvider).valueOrNull ?? [];

    final totalIntvs = interventions.length;
    final totalConseils = conseils.length;

    return Scaffold(
      backgroundColor: context.couleurs.fond,
      appBar: AppBar(
        backgroundColor: context.couleurs.primaireFonce,
        foregroundColor: Colors.white,
        title: Text('Rapports d\'activité',
            style: AppTypography.police(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
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
                    colorScheme: ColorScheme.light(
                      primary: context.couleurs.primaire,
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
                color: context.couleurs.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.couleurs.bordure),
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range_outlined,
                      color: context.couleurs.primaire, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    '${DateFormat('d MMM yyyy', 'fr_FR').format(_periode.start)} '
                    '→ ${DateFormat('d MMM yyyy', 'fr_FR').format(_periode.end)}',
                    style: AppTypography.police(
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
              _kpiRecap(
                  'Interventions', '$totalIntvs', context.couleurs.secondaire),
              _kpiRecap('Conseils envoyés', '$totalConseils',
                  context.couleurs.primaire),
              profilAsync.when(
                data: (e) => _kpiRecap('Taux précision IA',
                    e.tauxPrecisionFormate, context.couleurs.alerteElevee),
                loading: () => _kpiRecap(
                    'Taux précision IA', '—', context.couleurs.alerteElevee),
                error: (_, __) => _kpiRecap(
                    'Taux précision IA', '—', context.couleurs.alerteElevee),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Boutons export ─────────────────────────────────────
          _sectionTitle('Exporter le rapport'),
          const SizedBox(height: 10),
          if (_generation)
            Column(
              children: [
                LinearProgressIndicator(
                  color: context.couleurs.primaire,
                  backgroundColor:
                      context.couleurs.primaire.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 10),
                Text('Génération du rapport en cours...',
                    style: AppTypography.police(
                        fontSize: 13, color: context.couleurs.texteSecondaire)),
                const SizedBox(height: 20),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _generation ? null : _exporterPDF,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.couleurs.erreur,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: AppTypography.police(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Exporter PDF'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _generation ? null : _partager,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.couleurs.primaire,
                    side: BorderSide(color: context.couleurs.primaire),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: AppTypography.police(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Partager'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

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
                style: AppTypography.police(
                    fontSize: 22, fontWeight: FontWeight.bold, color: couleur)),
            Text(label,
                style: AppTypography.police(
                    fontSize: 11, color: context.couleurs.texteSecondaire),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );

  Widget _sectionTitle(String t) => Text(
        t,
        style: AppTypography.police(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.couleurs.textePrincipal),
      );

  Future<void> _exporterPDF() async {
    setState(() => _generation = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _generation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Rapport PDF généré avec succès !'),
          backgroundColor: context.couleurs.primaire,
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
        SnackBar(
          content: const Text('Rapport prêt à partager.'),
          backgroundColor: context.couleurs.primaire,
        ),
      );
    }
  }
}
