import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/statistiques_globales_entity.dart';
import '../providers/admin_provider.dart';
import '../widgets/feature_card_admin.dart';
import '../widgets/kpi_admin_card.dart';
import '../widgets/system_status_card.dart';

/// Écran principal du tableau de bord Administrateur
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  static const Color _adminPrimary = Color(0xFF534AB7);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(adminConnecteProvider);
    if (admin == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final statsAsync = ref.watch(statistiquesProvider);
    final statutAsync = ref.watch(statutSystemeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _adminPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Administration KoobalaTech',
              style: AppTypography.textTheme.titleLarge!.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Bonjour, ${admin.prenom} ${admin.nom}',
              style: AppTypography.textTheme.bodySmall!.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: () => context.pushNamed('profilAdmin'),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                child: Text(
                  (admin.prenom.isNotEmpty ? admin.prenom[0] : admin.email.isNotEmpty ? admin.email[0] : 'A').toUpperCase() +
                  (admin.nom.isNotEmpty ? admin.nom[0] : '').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _adminPrimary,
        onRefresh: () async {
          ref.invalidate(statistiquesProvider);
          ref.invalidate(statutSystemeProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section KPI ──────────────────────────────────────
              Text(
                'Vue d\'ensemble',
                style: AppTypography.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              statsAsync.when(
                loading: () => _ShimmerKpi(),
                error: (_, __) => _ErreurKpi(
                  onRetry: () => ref.invalidate(statistiquesProvider),
                ),
                data: (state) => _GrilleKpi(stats: state.statistiques),
              ),

              const SizedBox(height: 20),

              // ── Section santé système ─────────────────────────────
              Text(
                'Santé du système',
                style: AppTypography.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              statutAsync.when(
                loading: () => _ShimmerStatut(),
                error: (_, __) => const SizedBox.shrink(),
                data: (statut) => SystemStatusCard(statut: statut),
              ),

              const SizedBox(height: 20),

              // ── Accès rapide ──────────────────────────────────────
              Text(
                'Accès rapide',
                style: AppTypography.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  FeatureCardAdmin(
                    titre: 'Statistiques',
                    sousTitre: 'Données globales',
                    icone: Icons.bar_chart_outlined,
                    couleur: AppColors.teal,
                    onTap: () => context.pushNamed('statistiques'),
                    index: 0,
                  ),
                  FeatureCardAdmin(
                    titre: 'Assignation',
                    sousTitre: 'Gérer les experts',
                    icone: Icons.assignment_ind_outlined,
                    couleur: _adminPrimary,
                    onTap: () => context.pushNamed('assignationExperts'),
                    index: 1,
                  ),
                  FeatureCardAdmin(
                    titre: 'Historique',
                    sousTitre: 'Journal système',
                    icone: Icons.history_outlined,
                    couleur: AppColors.amber,
                    onTap: () => context.pushNamed('historiqueSysteme'),
                    index: 2,
                  ),
                  FeatureCardAdmin(
                    titre: 'Utilisateurs',
                    sousTitre: 'Gérer les comptes',
                    icone: Icons.manage_accounts_outlined,
                    couleur: AppColors.primary,
                    onTap: () => context.pushNamed('gestionUtilisateurs'),
                    index: 3,
                  ),
                  FeatureCardAdmin(
                    titre: 'Champs',
                    sousTitre: 'Gérer les parcelles',
                    icone: Icons.terrain_outlined,
                    couleur: AppColors.primary,
                    onTap: () => context.pushNamed('gestionChamps'),
                    index: 4,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grille 2×2 des KPIs globaux
class _GrilleKpi extends StatelessWidget {
  const _GrilleKpi({required this.stats});

  final StatistiquesGlobalesEntity stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        KpiAdminCard(
          titre: 'Utilisateurs actifs',
          valeur: '${stats.totalUtilisateurs}',
          icone: Icons.group_outlined,
          couleur: AppColors.info,
        ),
        KpiAdminCard(
          titre: 'Agriculteurs inscrits',
          valeur: '${stats.totalAgriculteurs}',
          icone: Icons.agriculture_outlined,
          couleur: AppColors.primary,
        ),
        KpiAdminCard(
          titre: 'Experts actifs',
          valeur: '${stats.totalExperts}',
          icone: Icons.verified_user_outlined,
          couleur: const Color(0xFF534AB7),
        ),
        KpiAdminCard(
          titre: 'Interventions en cours',
          valeur: '${stats.interventionsEnCours}',
          icone: Icons.calendar_today_outlined,
          couleur: AppColors.amber,
        ),
      ],
    );
  }
}

// ── Widgets de chargement ────────────────────────────────────────────────

class _ShimmerKpi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          4,
          (_) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerStatut extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _ErreurKpi extends StatelessWidget {
  const _ErreurKpi({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 36),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
