import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../navigation/expert_router.dart';
import '../providers/expert_provider.dart';

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
      backgroundColor: AppColors.background,
      body: champAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (champ) {
          final couleurSante = champ.scoresSante >= 70
              ? AppColors.primary
              : champ.scoresSante >= 40
                  ? AppColors.amber
                  : AppColors.danger;

          return CustomScrollView(
            slivers: [
              // ── SliverAppBar ────────────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    champ.nom,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  background: champ.photoUrl != null
                      ? Image.network(champ.photoUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: AppColors.primaryDark))
                      : Container(color: AppColors.primaryDark),
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
                        _infoRow(Icons.terrain_outlined, 'Superficie', champ.superficieFormatee),
                        _infoRow(Icons.layers_outlined, 'Type de sol', champ.typeSol),
                        if (champ.culture != null)
                          _infoRow(Icons.eco_outlined, 'Culture', champ.culture!),
                        if (champ.periodeplantation != null)
                          _infoRow(Icons.calendar_month_outlined, 'Plantation', champ.periodeplantation!),
                        const Divider(height: 16),
                        _infoRow(Icons.person_outline, 'Agriculteur', champ.agriculteurNom),
                        _infoRow(Icons.phone_outlined, 'Téléphone', champ.agriculteurTelephone),
                        if (champ.latitude != null && champ.longitude != null)
                          _infoRow(Icons.location_on_outlined, 'GPS',
                              '${champ.latitude!.toStringAsFixed(4)}, ${champ.longitude!.toStringAsFixed(4)}'),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Section 2 : Score santé ───────────────
                    _sectionTitle('Score santé du champ'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: couleurSante.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: couleurSante.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Santé globale',
                                style: GoogleFonts.inter(
                                  fontSize: 13, color: AppColors.textSecondary),
                              ),
                              Text(
                                '${champ.scoresSante}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: couleurSante,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: champ.scoresSante / 100),
                            duration: const Duration(milliseconds: 900),
                            builder: (_, v, __) => LinearProgressIndicator(
                              value: v,
                              backgroundColor: couleurSante.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation(couleurSante),
                              minHeight: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Section 3 : Données agronomiques ─────
                    _sectionTitle('Données agronomiques'),
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
                          _agroCard('pH', '${champ.ph}', AppColors.info),
                          _agroCard('Azote (N)', '${champ.azote} kg/ha', AppColors.primary),
                          _agroCard('Phosphore (P)', '${champ.phosphore} kg/ha', AppColors.amber),
                          _agroCard('Potassium (K)', '${champ.potassium} kg/ha', AppColors.coral),
                          _agroCard('Humidité', '${champ.humidite}%', Colors.blue),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Aucune donnée agronomique saisie',
                          style: GoogleFonts.inter(color: AppColors.textSecondary),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // ── Section 4 : Interventions planifiées ──
                    _sectionTitle('Interventions planifiées'),
                    const SizedBox(height: 8),
                    if (champInterventions.isEmpty)
                      _emptyCard('Aucune intervention planifiée')
                    else
                      ...champInterventions.map((intv) => ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: intv.typeIntervention.couleur.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(intv.typeIntervention.icone,
                                  color: intv.typeIntervention.couleur, size: 20),
                            ),
                            title: Text(
                              intv.typeIntervention.libelle,
                              style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              intv.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 11),
                            ),
                            trailing: Text(
                              '${intv.dateIntervention.day}/${intv.dateIntervention.month}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
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
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              textStyle: GoogleFonts.poppins(
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
                              foregroundColor: AppColors.info,
                              side: const BorderSide(color: AppColors.info),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              textStyle: GoogleFonts.poppins(
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

  Widget _sectionTitle(String t) => Text(
        t,
        style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      );

  Widget _sectionCard({required List<Widget> children}) => Card(
        child: Padding(padding: const EdgeInsets.all(14), child: Column(children: children)),
      );

  Widget _infoRow(IconData icon, String label, String valeur) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text('$label : ',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            Expanded(
              child: Text(valeur,
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  Widget _agroCard(String label, String valeur, Color couleur) => Container(
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
                style:
                    GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            Text(valeur,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.bold, color: couleur)),
          ],
        ),
      );

  Widget _emptyCard(String message) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(message,
            style: GoogleFonts.inter(color: AppColors.textSecondary),
            textAlign: TextAlign.center),
      );
}
