import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../navigation/expert_router.dart';
import '../providers/expert_provider.dart';
import '../widgets/kpi_card.dart';
import '../widgets/champ_supervision_card.dart';

/// Tableau de bord principal de l'Expert
class ExpertDashboardScreen extends ConsumerWidget {
  const ExpertDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilAsync = ref.watch(profilExpertProvider);
    final kpi = ref.watch(expertKpiProvider);
    final champsAsync = ref.watch(champsSupervisionProvider);

    return Scaffold(
      backgroundColor: context.couleurs.fond,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            backgroundColor: context.couleurs.primaireFonce,
            foregroundColor: Colors.white,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: context.couleurs.primaireFonce,
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
                              style: AppTypography.police(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${expert.nomComplet} · ${expert.regionCouverture}',
                              style: AppTypography.police(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Icône notification avec badge
                      _NotificationBadge(
                        count: kpi['recommandationsEnAttente'] ?? 0,
                        onTap: () =>
                            context.goNamed(ExpertRoutes.recommandationsNom),
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
                            style: AppTypography.police(
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
                      valeur: kpi['recommandationsEnAttente'] ?? 0,
                      libelle: 'Recommandations\nen attente',
                      icone: Icons.tips_and_updates_outlined,
                      couleur: context.couleurs.primaire,
                      estAlerte: true,
                    ),
                    KpiCard(
                      valeur: kpi['champsSupervises'] ?? 0,
                      libelle: 'Champs\nsupervisés',
                      icone: Icons.terrain_outlined,
                      couleur: context.couleurs.info,
                    ),
                    KpiCard(
                      valeur: kpi['interventionsPlanifiees'] ?? 0,
                      libelle: 'Interventions\nplanifiées',
                      icone: Icons.event_note_outlined,
                      couleur: context.couleurs.secondaire,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Champs supervisés ─────────────────────────────
                Text(
                  'Champs supervisés',
                  style: AppTypography.police(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.couleurs.textePrincipal,
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
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
}

/// Badge de notification avec compteur animé pulsant si > 0
class _NotificationBadge extends StatefulWidget {
  const _NotificationBadge({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  State<_NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<_NotificationBadge> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined,
              color: Colors.white, size: 26),
          if (widget.count > 0)
            Positioned(
              right: -4,
              top: -4,
              // La pastille ne clignote plus : elle battait sans fin sur un
              // écran qui reste ouvert, sans rien annoncer de nouveau. Le
              // chiffre suffit à dire qu'il y a du travail.
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
        ],
      ),
    );
  }
}
