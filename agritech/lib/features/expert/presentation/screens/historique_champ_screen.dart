import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/statut_intervention.dart';
import '../providers/expert_provider.dart';
/// Historique complet d'un champ — Interventions / Données agro
class HistoriqueChampScreen extends ConsumerStatefulWidget {
  const HistoriqueChampScreen({super.key, required this.champId});
  final String champId;

  @override
  ConsumerState<HistoriqueChampScreen> createState() => _HistoriqueChampScreenState();
}

class _HistoriqueChampScreenState extends ConsumerState<HistoriqueChampScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final champAsync = ref.watch(champSuperviseDetailProvider(widget.champId));
    final interventions = ref.watch(interventionsProvider).valueOrNull ?? [];
    final champIntvs = interventions
        .where((i) => i.champId == widget.champId)
        .toList()
      ..sort((a, b) => b.dateIntervention.compareTo(a.dateIntervention));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: champAsync.when(
          data: (c) => Text('Historique — ${c.nom}',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          loading: () => const Text('Historique'),
          error: (_, __) => const Text('Historique'),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Interventions'),
            Tab(text: 'Données agro'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── Onglet Interventions ──────────────────────────────
          champIntvs.isEmpty
              ? _emptyState('Aucune intervention pour ce champ')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: champIntvs.length,
                  itemBuilder: (_, i) {
                    final intv = champIntvs[i];
                    return _timelineItem(
                      couleur: intv.statut.couleur,
                      leading: Icon(intv.typeIntervention.icone,
                          color: intv.typeIntervention.couleur, size: 18),
                      title: intv.typeIntervention.libelle,
                      subtitle:
                          '${intv.dateIntervention.day}/${intv.dateIntervention.month}/${intv.dateIntervention.year}',
                      trailing: _statutChip(intv.statut),
                      expandedContent: intv.description,
                    );
                  },
                ),

          // ── Onglet Données agronomiques ───────────────────────
          champAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (champ) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (champ.dateDerniereDonnee != null)
                  Text(
                    'Dernière saisie : ${champ.dateDerniereDonnee!.day}/${champ.dateDerniereDonnee!.month}/${champ.dateDerniereDonnee!.year}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                const SizedBox(height: 16),
                if (champ.ph != null) ...[
                  _agroRow('pH', champ.ph!.toStringAsFixed(1), AppColors.info),
                  _agroRow('Azote (N)', '${champ.azote} kg/ha', AppColors.primary),
                  _agroRow('Phosphore (P)', '${champ.phosphore} kg/ha', AppColors.amber),
                  _agroRow('Potassium (K)', '${champ.potassium} kg/ha', AppColors.coral),
                  _agroRow('Humidité', '${champ.humidite}%', Colors.blue),
                ] else
                  _emptyState('Aucune donnée agronomique disponible'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem({
    required Color couleur,
    required Widget leading,
    required String title,
    required String subtitle,
    Widget? trailing,
    String? expandedContent,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne timeline
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: leading),
                ),
                Container(width: 2, height: 40, color: AppColors.border),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(title,
                                style: GoogleFonts.poppins(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          if (trailing != null) trailing,
                        ],
                      ),
                      Text(subtitle,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textSecondary)),
                      if (expandedContent != null) ...[
                        const SizedBox(height: 4),
                        Text(expandedContent,
                            style: GoogleFonts.inter(
                                fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _agroRow(String label, String valeur, Color couleur) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: couleur.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary)),
            Text(valeur,
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.bold, color: couleur)),
          ],
        ),
      );

  Widget _statutChip(StatutIntervention statut) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: statut.couleurFond,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(statut.libelle,
            style: GoogleFonts.poppins(
                fontSize: 9, fontWeight: FontWeight.w600, color: statut.couleur)),
      );

  Widget _emptyState(String msg) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(msg,
                style: GoogleFonts.inter(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      );
}
