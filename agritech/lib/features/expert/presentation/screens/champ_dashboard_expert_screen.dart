import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../navigation/expert_router.dart';
import '../providers/expert_provider.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../shared/widgets/widgets.dart';

/// Tableau de bord complet d'un champ vu par l'Expert
class ChampDashboardExpertScreen extends ConsumerWidget {
  const ChampDashboardExpertScreen({super.key, required this.champId});
  final String champId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final champAsync = ref.watch(champSuperviseDetailProvider(champId));
    final interventions = ref.watch(interventionsProvider).valueOrNull ?? [];
    final champInterventions = interventions
        .where((i) => i.champId == champId)
        .toList()
      ..sort((a, b) => a.dateIntervention.compareTo(b.dateIntervention));

    return Scaffold(
      backgroundColor: context.couleurs.fond,
      body: champAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EtatErreur(
          erreur: e,
          onReessayer: () =>
              ref.invalidate(champSuperviseDetailProvider(champId)),
        ),
        data: (champ) {
          final couleurSante = champ.scoresSante >= 70
              ? context.couleurs.primaire
              : champ.scoresSante >= 40
                  ? context.couleurs.secondaire
                  : context.couleurs.erreur;

          return CustomScrollView(
            slivers: [
              // ── SliverAppBar ────────────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: context.couleurs.primaireFonce,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    champ.nom,
                    style: AppTypography.police(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  background: champ.photoUrl != null
                      ? Image.network(champ.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: context.couleurs.primaireFonce))
                      : Container(color: context.couleurs.primaireFonce),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.white),
                    onPressed: () => context.goNamed(
                      ExpertRoutes.historiqueChampNom,
                      pathParameters: {'id': champId},
                    ),
                    tooltip: 'Historique',
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Section 1 : Identité ──────────────────
                    _sectionCard(
                      children: [
                        _infoRow(context, Icons.terrain_outlined, 'Superficie',
                            champ.superficieFormatee),
                        _infoRow(context, Icons.layers_outlined, 'Type de sol',
                            champ.typeSol),
                        if (champ.culture != null)
                          _infoRow(context, Icons.eco_outlined, 'Culture',
                              champ.culture!),
                        if (champ.periodeplantation != null)
                          _infoRow(context, Icons.calendar_month_outlined,
                              'Plantation', champ.periodeplantation!),
                        const Divider(height: 16),
                        _infoRow(context, Icons.person_outline, 'Agriculteur',
                            champ.agriculteurNom),
                        _infoRow(context, Icons.phone_outlined, 'Téléphone',
                            champ.agriculteurTelephone),
                        if (champ.latitude != null && champ.longitude != null)
                          _infoRow(context, Icons.location_on_outlined, 'GPS',
                              '${champ.latitude!.toStringAsFixed(4)}, ${champ.longitude!.toStringAsFixed(4)}'),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Section 2 : Score santé ───────────────
                    _sectionTitle(context, 'Score santé du champ'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: couleurSante.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: couleurSante.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Santé globale',
                                style: AppTypography.police(
                                    fontSize: 13,
                                    color: context.couleurs.texteSecondaire),
                              ),
                              Text(
                                '${champ.scoresSante}%',
                                style: AppTypography.police(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: couleurSante,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TweenAnimationBuilder<double>(
                            tween:
                                Tween(begin: 0, end: champ.scoresSante / 100),
                            duration: AppDurees.moyenne,
                            builder: (_, v, __) => LinearProgressIndicator(
                              value: v,
                              backgroundColor:
                                  couleurSante.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation(couleurSante),
                              minHeight: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Section 3 : Données agronomiques ─────
                    _sectionTitle(context, 'Données agronomiques'),
                    const SizedBox(height: 8),
                    if (champ.ph != null)
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.2,
                        children: [
                          _agroCard(context, 'pH', '${champ.ph}',
                              context.couleurs.info),
                          _agroCard(
                              context,
                              'Azote (N)',
                              '${champ.azote} kg/ha',
                              context.couleurs.primaire),
                          _agroCard(
                              context,
                              'Phosphore (P)',
                              '${champ.phosphore} kg/ha',
                              context.couleurs.secondaire),
                          _agroCard(
                              context,
                              'Potassium (K)',
                              '${champ.potassium} kg/ha',
                              context.couleurs.alerteElevee),
                          _agroCard(context, 'Humidité', '${champ.humidite}%',
                              Colors.blue),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              context.couleurs.bordure.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Aucune donnée agronomique saisie',
                          style: AppTypography.police(
                              color: context.couleurs.texteSecondaire),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // ── Section 4 : Interventions planifiées ──
                    _sectionTitle(context, 'Interventions planifiées'),
                    const SizedBox(height: 8),
                    if (champInterventions.isEmpty)
                      _emptyCard(context, 'Aucune intervention planifiée')
                    else
                      ...champInterventions.map((intv) => ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: intv.typeIntervention.couleur
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(intv.typeIntervention.icone,
                                  color: intv.typeIntervention.couleur,
                                  size: 20),
                            ),
                            title: Text(
                              intv.typeIntervention.libelle,
                              style: AppTypography.police(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              intv.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.police(fontSize: 11),
                            ),
                            trailing: Text(
                              '${intv.dateIntervention.day}/${intv.dateIntervention.month}',
                              style: AppTypography.police(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.couleurs.texteSecondaire,
                              ),
                            ),
                          )),

                    const SizedBox(height: 16),

                    // ── Boutons ───────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.goNamed(
                              ExpertRoutes.planifierInterventionNom,
                              queryParameters: {'champId': champId},
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.couleurs.primaire,
                              side:
                                  BorderSide(color: context.couleurs.primaire),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              textStyle: AppTypography.police(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            child: const Text('Planifier intervention'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.goNamed(
                              ExpertRoutes.historiqueChampNom,
                              pathParameters: {'id': champId},
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.couleurs.info,
                              side: BorderSide(color: context.couleurs.info),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              textStyle: AppTypography.police(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            child: const Text('Historique'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String t) => Text(
        t,
        style: AppTypography.police(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.couleurs.textePrincipal),
      );

  Widget _sectionCard({required List<Widget> children}) => Card(
        child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: children)),
      );

  Widget _infoRow(
          BuildContext context, IconData icon, String label, String valeur) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: context.couleurs.texteSecondaire),
            const SizedBox(width: 8),
            Text('$label : ',
                style: AppTypography.police(
                    fontSize: 12, color: context.couleurs.texteSecondaire)),
            Expanded(
              child: Text(valeur,
                  style: AppTypography.police(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  Widget _agroCard(
          BuildContext context, String label, String valeur, Color couleur) =>
      Container(
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
            Text(label,
                style: AppTypography.police(
                    fontSize: 11, color: context.couleurs.texteSecondaire)),
            Text(valeur,
                style: AppTypography.police(
                    fontSize: 14, fontWeight: FontWeight.bold, color: couleur)),
          ],
        ),
      );

  Widget _emptyCard(BuildContext context, String message) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.couleurs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.couleurs.bordure),
        ),
        child: Text(message,
            style:
                AppTypography.police(color: context.couleurs.texteSecondaire),
            textAlign: TextAlign.center),
      );
}
