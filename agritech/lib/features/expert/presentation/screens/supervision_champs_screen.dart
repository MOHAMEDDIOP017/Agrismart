import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../navigation/expert_router.dart';
import '../providers/expert_provider.dart';
import '../widgets/champ_supervision_card.dart';

/// Vue de supervision de tous les champs de la région de l'Expert
class SupervisionChampsScreen extends ConsumerStatefulWidget {
  const SupervisionChampsScreen({super.key});

  @override
  ConsumerState<SupervisionChampsScreen> createState() =>
      _SupervisionChampsScreenState();
}

class _SupervisionChampsScreenState extends ConsumerState<SupervisionChampsScreen> {
  String _filtre = 'Tous';
  bool _modeMap = false;

  static const _filtres = ['Tous', 'Alertes actives', 'En traitement', 'Sains'];

  @override
  Widget build(BuildContext context) {
    final champsAsync = ref.watch(champsSupervisionProvider);
    final profilAsync = ref.watch(profilExpertProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mes champs supervisés',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            profilAsync.when(
              data: (e) => Text(
                '${e.regionCouverture} · ${champsAsync.valueOrNull?.length ?? 0} champs',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
        actions: [
          // Toggle ListView / Map
          IconButton(
            icon: Icon(
              _modeMap ? Icons.list_alt : Icons.map_outlined,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _modeMap = !_modeMap),
            tooltip: _modeMap ? 'Mode liste' : 'Mode carte',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── FilterChips ──────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filtres
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              f,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _filtre == f ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            selected: _filtre == f,
                            onSelected: (_) => setState(() => _filtre = f),
                            selectedColor: AppColors.primaryDark,
                            backgroundColor: AppColors.surface,
                            side: BorderSide(
                              color: _filtre == f ? AppColors.primaryDark : AppColors.border,
                            ),
                            showCheckmark: false,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),

          // ── Contenu ──────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _modeMap
                  ? _buildMapView()
                  : _buildListView(champsAsync),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(AsyncValue champsAsync) {
    return champsAsync.when(
      loading: () => _shimmerList(),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (champs) {
        var filtered = List.of(champs);
        switch (_filtre) {
          case 'Alertes actives':
            filtered = filtered.where((c) => c.derniereAlerte != null).toList();
          case 'En traitement':
            filtered = filtered.where((c) => c.statut == 'EN_TRAITEMENT').toList();
          case 'Sains':
            filtered = filtered.where((c) => c.scoresSante >= 70).toList();
        }
        if (filtered.isEmpty) {
          return Center(
            child: Text(
              'Aucun champ pour ce filtre',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(champsSupervisionProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: filtered.length,
            itemBuilder: (_, i) => ChampSupervisionCard(
              champ: filtered[i],
              onTableauDeBord: () => context.goNamed(
                ExpertRoutes.champDashboardNom,
                pathParameters: {'id': filtered[i].id},
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Carte interactive',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Activez flutter_map dans le projet\npour afficher les marqueurs GPS.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _shimmerList() => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (_, __) => Container(
            height: 200,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
}
