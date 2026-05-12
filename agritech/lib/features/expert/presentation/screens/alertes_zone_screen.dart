import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../navigation/expert_router.dart';
import '../../../detection/domain/enums/niveau_gravite.dart';
import '../../domain/entities/alerte_zone_entity.dart';
import '../providers/expert_provider.dart';
import '../widgets/alerte_expert_card.dart';

/// Liste des alertes actives dans la région de l'Expert
class AlertesZoneScreen extends ConsumerStatefulWidget {
  const AlertesZoneScreen({super.key});

  @override
  ConsumerState<AlertesZoneScreen> createState() => _AlertesZoneScreenState();
}

class _AlertesZoneScreenState extends ConsumerState<AlertesZoneScreen> {
  String _filtre = 'Toutes';

  static const _filtres = ['Toutes', 'CRITIQUE', 'ÉLEVÉ', 'MODÉRÉ', 'Non traitées'];

  @override
  Widget build(BuildContext context) {
    final alertesAsync = ref.watch(alertesZoneProvider);
    final profilAsync = ref.watch(profilExpertProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            profilAsync.when(
              data: (e) => Text(
                'Alertes — ${e.regionCouverture}',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              loading: () => const Text('Alertes'),
              error: (_, __) => const Text('Alertes'),
            ),
            alertesAsync.when(
              data: (a) {
                final actives = a.where((x) => x.statut != StatutAlerteZone.resolue).length;
                return Text('$actives alertes actives',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white70));
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // FilterChips
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
                            label: Text(f,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _filtre == f
                                        ? Colors.white
                                        : AppColors.textPrimary)),
                            selected: _filtre == f,
                            onSelected: (_) => setState(() => _filtre = f),
                            selectedColor: AppColors.primaryDark,
                            backgroundColor: AppColors.surface,
                            side: BorderSide(
                                color: _filtre == f
                                    ? AppColors.primaryDark
                                    : AppColors.border),
                            showCheckmark: false,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),

          // Liste
          Expanded(
            child: alertesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (alertes) {
                var filtered = List.of(alertes);
                switch (_filtre) {
                  case 'CRITIQUE':
                    filtered = filtered
                        .where((a) => a.niveauGravite == NiveauGravite.critique)
                        .toList();
                  case 'ÉLEVÉ':
                    filtered = filtered
                        .where((a) => a.niveauGravite == NiveauGravite.eleve)
                        .toList();
                  case 'MODÉRÉ':
                    filtered = filtered
                        .where((a) => a.niveauGravite == NiveauGravite.modere)
                        .toList();
                  case 'Non traitées':
                    filtered = filtered
                        .where((a) => a.statut == StatutAlerteZone.nonTraitee)
                        .toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 64, color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text('Aucune alerte pour ce filtre',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(alertesZoneProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final a = filtered[i];
                      return AlerteExpertCard(
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
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
