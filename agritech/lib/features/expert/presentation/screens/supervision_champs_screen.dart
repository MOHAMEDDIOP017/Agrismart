import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../navigation/expert_router.dart';
import '../providers/expert_provider.dart';
import '../widgets/champ_supervision_card.dart';
import '../../../../shared/widgets/widgets.dart';

/// Vue de supervision de tous les champs de la région de l'Expert
class SupervisionChampsScreen extends ConsumerStatefulWidget {
  const SupervisionChampsScreen({super.key});

  @override
  ConsumerState<SupervisionChampsScreen> createState() =>
      _SupervisionChampsScreenState();
}

class _SupervisionChampsScreenState
    extends ConsumerState<SupervisionChampsScreen> {
  String _filtre = 'Tous';
  bool _modeMap = false;

  static const _filtres = ['Tous', 'Alertes actives', 'En traitement', 'Sains'];

  @override
  Widget build(BuildContext context) {
    final champsAsync = ref.watch(champsSupervisionProvider);
    final profilAsync = ref.watch(profilExpertProvider);

    return Scaffold(
      backgroundColor: context.couleurs.fond,
      appBar: AppBar(
        backgroundColor: context.couleurs.primaireFonce,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mes champs supervisés',
              style: AppTypography.police(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            profilAsync.when(
              data: (e) => Text(
                '${e.regionCouverture} · ${champsAsync.valueOrNull?.length ?? 0} champs',
                style:
                    AppTypography.police(fontSize: 11, color: Colors.white70),
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
            color: context.couleurs.surface,
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
                              style: AppTypography.police(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _filtre == f
                                    ? Colors.white
                                    : context.couleurs.textePrincipal,
                              ),
                            ),
                            selected: _filtre == f,
                            onSelected: (_) => setState(() => _filtre = f),
                            selectedColor: context.couleurs.primaireFonce,
                            backgroundColor: context.couleurs.surface,
                            side: BorderSide(
                              color: _filtre == f
                                  ? context.couleurs.primaireFonce
                                  : context.couleurs.bordure,
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
              child: _modeMap ? _buildMapView() : _buildListView(champsAsync),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(AsyncValue champsAsync) {
    return champsAsync.when(
      loading: () => _shimmerList(),
      error: (e, _) => EtatErreur(
        erreur: e,
        onReessayer: () => ref.invalidate(champsSupervisionProvider),
      ),
      data: (champs) {
        var filtered = List.of(champs);
        switch (_filtre) {
          case 'Alertes actives':
            filtered = filtered.where((c) => c.derniereAlerte != null).toList();
          case 'En traitement':
            filtered =
                filtered.where((c) => c.statut == 'EN_TRAITEMENT').toList();
          case 'Sains':
            filtered = filtered.where((c) => c.scoresSante >= 70).toList();
        }
        if (filtered.isEmpty) {
          return Center(
            child: Text(
              'Aucun champ pour ce filtre',
              style:
                  AppTypography.police(color: context.couleurs.texteSecondaire),
            ),
          );
        }
        return RefreshIndicator(
          color: context.couleurs.primaire,
          onRefresh: () =>
              ref.read(champsSupervisionProvider.notifier).refresh(),
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
          Icon(Icons.map_outlined,
              size: 64, color: context.couleurs.texteSecondaire),
          const SizedBox(height: 16),
          Text(
            'Carte interactive',
            style: AppTypography.police(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.couleurs.textePrincipal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Activez flutter_map dans le projet\npour afficher les marqueurs GPS.',
            style: AppTypography.police(
              fontSize: 13,
              color: context.couleurs.texteSecondaire,
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
