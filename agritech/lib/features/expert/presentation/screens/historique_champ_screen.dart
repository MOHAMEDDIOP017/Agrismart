import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/statut_intervention.dart';
import '../providers/expert_provider.dart';
import '../../../../shared/widgets/widgets.dart';

/// Historique complet d'un champ — Interventions / Données agro
class HistoriqueChampScreen extends ConsumerStatefulWidget {
  const HistoriqueChampScreen({super.key, required this.champId});
  final String champId;

  @override
  ConsumerState<HistoriqueChampScreen> createState() =>
      _HistoriqueChampScreenState();
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
      backgroundColor: context.couleurs.fond,
      appBar: AppBar(
        backgroundColor: context.couleurs.primaireFonce,
        foregroundColor: Colors.white,
        title: champAsync.when(
          data: (c) => Text('Historique — ${c.nom}',
              style: AppTypography.police(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          loading: () => const Text('Historique'),
          error: (_, __) => const Text('Historique'),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              AppTypography.police(fontSize: 13, fontWeight: FontWeight.w600),
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
            error: (e, _) => EtatErreur(
              erreur: e,
              onReessayer: () =>
                  ref.invalidate(champSuperviseDetailProvider(widget.champId)),
            ),
            data: (champ) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (champ.dateDerniereDonnee != null)
                  Text(
                    'Dernière saisie : ${champ.dateDerniereDonnee!.day}/${champ.dateDerniereDonnee!.month}/${champ.dateDerniereDonnee!.year}',
                    style: AppTypography.police(
                        fontSize: 12, color: context.couleurs.texteSecondaire),
                  ),
                const SizedBox(height: 16),
                if (champ.ph != null) ...[
                  _agroRow('pH', champ.ph!.toStringAsFixed(1),
                      context.couleurs.info),
                  _agroRow('Azote (N)', '${champ.azote} kg/ha',
                      context.couleurs.primaire),
                  _agroRow('Phosphore (P)', '${champ.phosphore} kg/ha',
                      context.couleurs.secondaire),
                  _agroRow('Potassium (K)', '${champ.potassium} kg/ha',
                      context.couleurs.alerteElevee),
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
                Container(
                    width: 2, height: 40, color: context.couleurs.bordure),
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
                                style: AppTypography.police(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          if (trailing != null) trailing,
                        ],
                      ),
                      Text(subtitle,
                          style: AppTypography.police(
                              fontSize: 11,
                              color: context.couleurs.texteSecondaire)),
                      if (expandedContent != null) ...[
                        const SizedBox(height: 4),
                        Text(expandedContent,
                            style: AppTypography.police(
                                fontSize: 11,
                                color: context.couleurs.texteSecondaire),
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
                style: AppTypography.police(
                    fontSize: 13, color: context.couleurs.texteSecondaire)),
            Text(valeur,
                style: AppTypography.police(
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
            style: AppTypography.police(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: statut.couleur)),
      );

  Widget _emptyState(String msg) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 48, color: context.couleurs.texteSecondaire),
            const SizedBox(height: 12),
            Text(msg,
                style: AppTypography.police(
                    color: context.couleurs.texteSecondaire),
                textAlign: TextAlign.center),
          ],
        ),
      );
}
