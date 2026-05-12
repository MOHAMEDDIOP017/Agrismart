import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../navigation/expert_router.dart';
import '../providers/expert_provider.dart';
import '../widgets/diagnostic_attente_card.dart';
import 'validation_sheet.dart';
import 'correction_sheet.dart';

/// Liste complète des diagnostics IA en attente de validation
class DiagnosticsEnAttenteScreen extends ConsumerWidget {
  const DiagnosticsEnAttenteScreen({super.key});

  static const _filtres = [
    (FiltreDiagnostic.tous, 'Tous'),
    (FiltreDiagnostic.critique, 'CRITIQUE'),
    (FiltreDiagnostic.eleve, 'ÉLEVÉ'),
    (FiltreDiagnostic.modere, 'MODÉRÉ'),
    (FiltreDiagnostic.faible, 'FAIBLE'),
    (FiltreDiagnostic.aujourdhui, 'Aujourd\'hui'),
    (FiltreDiagnostic.semaine, 'Cette semaine'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diagnosticsNotifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Text(
              'Diagnostics en attente',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            state.when(
              data: (s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${s.diagnostics.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: state.when(
              data: (s) => Icon(
                s.triParGravite ? Icons.filter_list : Icons.filter_list_off,
                color: Colors.white,
              ),
              loading: () => const Icon(Icons.filter_list, color: Colors.white),
              error: (_, __) => const Icon(Icons.filter_list, color: Colors.white),
            ),
            tooltip: 'Trier par gravité',
            onPressed: () => ref.read(diagnosticsNotifier.notifier).toggleTri(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── FilterChips ────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: state.when(
                data: (s) => Row(
                  children: _filtres
                      .map((f) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                f.$2,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: s.filtre == f.$1
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              selected: s.filtre == f.$1,
                              onSelected: (_) => ref
                                  .read(diagnosticsNotifier.notifier)
                                  .setFiltre(f.$1),
                              selectedColor: AppColors.primaryDark,
                              backgroundColor: AppColors.surface,
                              side: BorderSide(
                                color: s.filtre == f.$1
                                    ? AppColors.primaryDark
                                    : AppColors.border,
                              ),
                              showCheckmark: false,
                            ),
                          ))
                      .toList(),
                ),
                loading: () => const SizedBox(height: 40),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ),

          // ── Liste diagnostics ──────────────────────────────────
          Expanded(
            child: state.when(
              loading: () => _shimmerList(),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (s) {
                final liste = s.filtres;
                if (liste.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 64, color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Tous les diagnostics ont été traités !',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Revenez plus tard pour de nouveaux diagnostics.',
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
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      ref.read(diagnosticsNotifier.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: liste.length,
                    itemBuilder: (_, i) {
                      final d = liste[i];
                      return DiagnosticAttenteCard(
                        diagnostic: d,
                        onTap: () => context.goNamed(
                          ExpertRoutes.diagnosticDetailNom,
                          pathParameters: {'id': d.id},
                        ),
                        onValider: () => _showValidation(context, ref, d.id),
                        onCorrection: () => _showCorrection(context, ref, d.id),
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

  void _showValidation(BuildContext ctx, WidgetRef ref, String id) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ValidationSheet(
        diagnosticId: id,
        onConfirmer: (commentaire, notifier) async {
          final ok = await ref.read(diagnosticsNotifier.notifier).validerDiagnostic(
                diagnosticId: id,
                commentaire: commentaire,
                notifierAgriculteur: notifier,
              );
          if (ok && ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showCorrection(BuildContext ctx, WidgetRef ref, String diagnosticId) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CorrectionSheet(
        diagnosticId: diagnosticId,
        notifier: ref.read(diagnosticsNotifier.notifier),
        onDone: () {
          if (ctx.mounted) Navigator.pop(ctx);
        },
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
            height: 160,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
}
