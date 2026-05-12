import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/assignation_entity.dart';
import '../providers/admin_provider.dart';
import '../widgets/intervention_admin_card.dart';
import 'assignation_detail_sheet.dart';

/// Écran de gestion des assignations expert ↔ intervention
class AssignationExpertsScreen extends ConsumerStatefulWidget {
  const AssignationExpertsScreen({super.key});

  @override
  ConsumerState<AssignationExpertsScreen> createState() =>
      _AssignationExpertsScreenState();
}

class _AssignationExpertsScreenState
    extends ConsumerState<AssignationExpertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const Color _adminPrimary = Color(0xFF534AB7);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final etatAsync = ref.watch(assignationProvider);
    final notifier = ref.read(assignationProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _adminPrimary,
        title: const Text(
          'Assignation des experts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          onTap: (i) => notifier.setFiltre(
            i == 0
                ? FiltreAssignation.enAttente
                : FiltreAssignation.assignees,
          ),
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: etatAsync.when(
            loading: () => const [
              Tab(text: 'En attente'),
              Tab(text: 'Assignées'),
            ],
            error: (_, __) => const [
              Tab(text: 'En attente'),
              Tab(text: 'Assignées'),
            ],
            data: (etat) {
              final enAttente = etat.assignations
                  .where((a) => a.statut.estEnAttente)
                  .length;
              return [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('En attente'),
                      if (enAttente > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$enAttente',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Assignées'),
              ];
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('nouvelleAssignation'),
        backgroundColor: _adminPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouvelle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: etatAsync.when(
        loading: () => _ShimmerListe(),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (etat) => TabBarView(
          controller: _tabCtrl,
          children: [
            // ── Onglet En attente ─────────────────────────────────
            _ListeInterventions(
              interventions: etat.filtrees,
              estEnAttente: true,
              onAssigner: (a) => _ouvrirDetail(context, a),
              onVoirDetail: (a) => _ouvrirDetail(context, a),
            ),
            // ── Onglet Assignées ──────────────────────────────────
            _ListeInterventions(
              interventions: etat.filtrees,
              estEnAttente: false,
              onAssigner: (a) => _ouvrirDetail(context, a),
              onVoirDetail: (a) => _ouvrirDetail(context, a),
            ),
          ],
        ),
      ),
    );
  }

  void _ouvrirDetail(BuildContext context, AssignationEntity assignation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssignationDetailSheet(assignation: assignation),
    );
  }
}

class _ListeInterventions extends StatelessWidget {
  const _ListeInterventions({
    required this.interventions,
    required this.estEnAttente,
    required this.onAssigner,
    required this.onVoirDetail,
  });

  final List<AssignationEntity> interventions;
  final bool estEnAttente;
  final ValueChanged<AssignationEntity> onAssigner;
  final ValueChanged<AssignationEntity> onVoirDetail;

  @override
  Widget build(BuildContext context) {
    if (interventions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              estEnAttente
                  ? Icons.assignment_turned_in_outlined
                  : Icons.assignment_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              estEnAttente
                  ? 'Aucune intervention en attente'
                  : 'Aucune intervention assignée',
              style: AppTypography.textTheme.titleSmall,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF534AB7),
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: interventions.length,
        itemBuilder: (_, i) {
          final a = interventions[i];
          return estEnAttente
              ? InterventionNonAssigneeCard(
                  assignation: a,
                  onAssigner: () => onAssigner(a),
                )
              : InterventionAssigneeCard(
                  assignation: a,
                  onVoirDetail: () => onVoirDetail(a),
                );
        },
      ),
    );
  }
}

class _ShimmerListe extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          height: 140,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
