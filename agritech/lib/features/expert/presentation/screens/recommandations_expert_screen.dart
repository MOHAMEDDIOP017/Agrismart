import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../navigation/expert_router.dart';
import '../../domain/entities/recommandation_expert_entity.dart';
import '../providers/expert_provider.dart';

/// Liste des recommandations cultures soumises à la validation de l'Expert
class RecommandationsExpertScreen extends ConsumerStatefulWidget {
  const RecommandationsExpertScreen({super.key});

  @override
  ConsumerState<RecommandationsExpertScreen> createState() =>
      _RecommandationsExpertScreenState();
}

class _RecommandationsExpertScreenState
    extends ConsumerState<RecommandationsExpertScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  static const _filtres = [
    ('EN_ATTENTE', 'En attente'),
    ('VALIDEE', 'Validées'),
    ('CORRIGEE', 'Corrigées'),
    ('REJETEE', 'Rejetées'),
  ];

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(recommandationsExpertProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Text(
              'Recommandations cultures',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            async.when(
              data: (s) => s.nombreEnAttente > 0
                  ? _Badge(count: s.nombreEnAttente)
                  : const SizedBox(),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () =>
                ref.read(recommandationsExpertProvider.notifier).refresh(),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle:
              GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.poppins(fontSize: 12),
          onTap: (i) => ref
              .read(recommandationsExpertProvider.notifier)
              .setFiltre(_filtres[i].$1),
          tabs: _filtres
              .map((f) => async.when(
                    data: (s) {
                      final nb = s.recommandations
                          .where((r) => r.statutValidation == f.$1)
                          .length;
                      return Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(f.$2),
                            if (nb > 0) ...[
                              const SizedBox(width: 6),
                              _Badge(count: nb, small: true),
                            ],
                          ],
                        ),
                      );
                    },
                    loading: () => Tab(text: f.$2),
                    error: (_, __) => Tab(text: f.$2),
                  ))
              .toList(),
        ),
      ),
      body: async.when(
        loading: () => _Shimmer(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.danger, size: 48),
              const SizedBox(height: 12),
              Text('Erreur : $e',
                  style: GoogleFonts.inter(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(recommandationsExpertProvider.notifier).refresh(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (state) {
          final liste = state.filtrees;
          if (liste.isEmpty) return _Vide(filtre: state.filtre);
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () =>
                ref.read(recommandationsExpertProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: liste.length,
              itemBuilder: (_, i) => _RecoCard(
                reco: liste[i],
                onTap: () => context.goNamed(
                  ExpertRoutes.recommandationDetailNom,
                  pathParameters: {'id': liste[i].id},
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Carte de recommandation ──────────────────────────────────────────────────

class _RecoCard extends StatelessWidget {
  const _RecoCard({required this.reco, required this.onTap});
  final RecommandationExpertEntity reco;
  final VoidCallback onTap;

  static const _statutColors = {
    'EN_ATTENTE': AppColors.amber,
    'VALIDEE': AppColors.primary,
    'CORRIGEE': AppColors.info,
    'REJETEE': AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final couleurStatut =
        _statutColors[reco.statutValidation] ?? AppColors.textSecondary;
    final premiere = reco.premiereCulture;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: reco.estEnAttente
              ? AppColors.amber.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── En-tête ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reco.champNom,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${reco.agriculteurNom} · ${reco.champRegion}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: couleurStatut.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      reco.statutLibelle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: couleurStatut,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Top culture n°1 ────────────────────────────────
              if (premiere != null)
                Row(
                  children: [
                    const Icon(Icons.eco_outlined,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        premiere.nom,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      premiere.scoreLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 8),

              // ── Top 3 barres de score ──────────────────────────
              ...reco.top3Cultures.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          c.nom,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: c.score),
                          duration: const Duration(milliseconds: 600),
                          builder: (_, v, __) => LinearProgressIndicator(
                            value: v,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation(
                              c.rang == 1 ? AppColors.primary : AppColors.info,
                            ),
                            minHeight: 5,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.scoreLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Pied : snapshot + horodatage ───────────────────
              Row(
                children: [
                  if (reco.snapshot.ph != null)
                    _Chip('pH ${reco.snapshot.ph!.toStringAsFixed(1)}'),
                  if (reco.snapshot.azote != null)
                    _Chip('N ${reco.snapshot.azote!.toStringAsFixed(0)}'),
                  if (reco.snapshot.humidite != null)
                    _Chip('H ${reco.snapshot.humidite!.toStringAsFixed(0)}%'),
                  const Spacer(),
                  Text(
                    reco.tempsEcoule,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),

              // Motif de correction/rejet si rempli
              if (reco.commentaireExpert != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Note expert : ${reco.commentaireExpert}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, this.small = false});
  final int count;
  final bool small;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: small ? 5 : 7, vertical: small ? 1 : 3),
        decoration: const BoxDecoration(
          color: AppColors.danger,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$count',
          style: TextStyle(
            color: Colors.white,
            fontSize: small ? 9 : 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}

class _Vide extends StatelessWidget {
  const _Vide({required this.filtre});
  final String filtre;

  static const _msgs = {
    'EN_ATTENTE': 'Aucune recommandation en attente',
    'VALIDEE': 'Aucune recommandation validée',
    'CORRIGEE': 'Aucune recommandation corrigée',
    'REJETEE': 'Aucune recommandation rejetée',
  };

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 56,
                color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              _msgs[filtre] ?? 'Aucune recommandation',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Revenez plus tard.',
              style:
                  GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
}

class _Shimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (_, __) => Container(
            height: 180,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
}
