import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../navigation/expert_router.dart';
import '../providers/expert_provider.dart';
import '../widgets/kpi_card.dart';
import '../widgets/diagnostic_urgent_card.dart';
import '../widgets/alerte_expert_card.dart';
import '../widgets/champ_supervision_card.dart';
import '../../domain/entities/alerte_zone_entity.dart';

/// Tableau de bord principal de l'Expert
class ExpertDashboardScreen extends ConsumerWidget {
  const ExpertDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilAsync = ref.watch(profilExpertProvider);
    final kpi = ref.watch(expertKpiProvider);
    final diagnosticsAsync = ref.watch(diagnosticsNotifier);
    final alertesAsync = ref.watch(alertesZoneProvider);
    final champsAsync = ref.watch(champsSupervisionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primaryDark,
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
                child: profilAsync.when(
                  data: (expert) => Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Tableau de bord Expert',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${expert.nomComplet} · ${expert.regionCouverture}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Icône notification avec badge
                      _NotificationBadge(
                        count: kpi['diagnosticsEnAttente'] ?? 0,
                        onTap: () => context.goNamed(ExpertRoutes.diagnosticsNom),
                      ),
                      const SizedBox(width: 8),
                      // Profil
                      GestureDetector(
                        onTap: () => context.goNamed(ExpertRoutes.profilNom),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white24,
                          child: Text(
                            expert.prenom[0] + expert.nom[0],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── KPI 2x2 ───────────────────────────────────────
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: [
                    KpiCard(
                      valeur: kpi['diagnosticsEnAttente'] ?? 0,
                      libelle: 'Diagnostics\nen attente',
                      icone: Icons.biotech_outlined,
                      couleur: AppColors.danger,
                      estAlerte: true,
                    ),
                    KpiCard(
                      valeur: kpi['champsSupervises'] ?? 0,
                      libelle: 'Champs\nsupervisés',
                      icone: Icons.terrain_outlined,
                      couleur: AppColors.info,
                    ),
                    KpiCard(
                      valeur: kpi['interventionsPlanifiees'] ?? 0,
                      libelle: 'Interventions\nplanifiées',
                      icone: Icons.event_note_outlined,
                      couleur: AppColors.amber,
                    ),
                    KpiCard(
                      valeur: kpi['alertesActives'] ?? 0,
                      libelle: 'Alertes actives\nma zone',
                      icone: Icons.warning_amber_outlined,
                      couleur: AppColors.coral,
                      estAlerte: true,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Diagnostics urgents ───────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Diagnostics urgents',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        diagnosticsAsync.when(
                          data: (s) => _CountBadge(
                            count: s.diagnostics.length,
                            couleur: AppColors.danger,
                          ),
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.goNamed(ExpertRoutes.diagnosticsNom),
                      child: Text(
                        'Voir tous',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                diagnosticsAsync.when(
                  data: (state) => state.diagnostics.isEmpty
                      ? _emptyCard('Tous les diagnostics ont été traités 👍')
                      : SizedBox(
                          height: 290,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: state.diagnostics.take(3).length,
                            itemBuilder: (_, i) {
                              final d = state.diagnostics[i];
                              return DiagnosticUrgentCard(
                                diagnostic: d,
                                onTap: () => context.goNamed(
                                  ExpertRoutes.diagnosticDetailNom,
                                  pathParameters: {'id': d.id},
                                ),
                                onValider: () => context.goNamed(
                                  ExpertRoutes.diagnosticDetailNom,
                                  pathParameters: {'id': d.id},
                                ),
                              );
                            },
                          ),
                        ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, __) => const SizedBox(),
                ),

                const SizedBox(height: 24),

                // ── Alertes zone ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Alertes actives — ma zone',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.goNamed(ExpertRoutes.alertesNom),
                      child: Text(
                        'Voir toutes',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                alertesAsync.when(
                  data: (alertes) {
                    final actives = alertes
                        .where((a) => a.statut != StatutAlerteZone.resolue)
                        .take(3)
                        .toList();
                    if (actives.isEmpty) {
                      return _emptyCard('Aucune alerte active dans votre zone');
                    }
                    return Column(
                      children: actives
                          .map((a) => AlerteExpertCard(
                                alerte: a,
                                onPrendreEnCharge: () =>
                                    ref.read(alertesZoneProvider.notifier).prendreEnCharge(a.id),
                                onVoirDiagnostic: () {
                                  if (a.diagnosticId != null) {
                                    context.goNamed(
                                      ExpertRoutes.diagnosticDetailNom,
                                      pathParameters: {'id': a.diagnosticId!},
                                    );
                                  }
                                },
                              ))
                          .toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox(),
                ),

                const SizedBox(height: 24),

                // ── Champs supervisés ─────────────────────────────
                Text(
                  'Champs supervisés',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                champsAsync.when(
                  data: (champs) => Column(
                    children: champs
                        .take(3)
                        .map((c) => ChampSupervisionCard(
                              champ: c,
                              onTableauDeBord: () => context.goNamed(
                                ExpertRoutes.champDashboardNom,
                                pathParameters: {'id': c.id},
                              ),
                            ))
                        .toList(),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox(),
                ),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) => Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            message,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
}

/// Badge de notification avec compteur animé pulsant si > 0
class _NotificationBadge extends StatefulWidget {
  const _NotificationBadge({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  State<_NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<_NotificationBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
          if (widget.count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: FadeTransition(
                opacity: Tween(begin: 0.5, end: 1.0).animate(_c),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${widget.count}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Badge compteur coloré
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.couleur});
  final int count;
  final Color couleur;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: couleur,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
