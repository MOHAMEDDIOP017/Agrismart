import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/enums/type_log.dart';
import '../providers/admin_provider.dart';
import '../widgets/log_systeme_card.dart';

/// Écran d'historique et de journalisation du système
class HistoriqueSystemeScreen extends ConsumerWidget {
  const HistoriqueSystemeScreen({super.key});

  static const Color _adminPrimary = Color(0xFF534AB7);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etatAsync = ref.watch(logsProvider);
    final notifier = ref.read(logsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _adminPrimary,
        title: const Text(
          'Historique du système',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            tooltip: 'Exporter CSV',
            onPressed: () => _exporterCSV(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(logsProvider.notifier).rafraichir(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filtres par type de log ─────────────────────────────
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: etatAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (etat) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Filtre "Tous"
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Tous'),
                        selected: etat.filtre == null,
                        onSelected: (_) => notifier.setFiltre(null),
                        selectedColor:
                            _adminPrimary.withValues(alpha: 0.15),
                        checkmarkColor: _adminPrimary,
                        labelStyle: TextStyle(
                          color: etat.filtre == null
                              ? _adminPrimary
                              : AppColors.textSecondary,
                          fontWeight: etat.filtre == null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    // Filtres par type
                    ...TypeLog.values.map((t) {
                      final sel = etat.filtre == t;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: Icon(t.icone,
                              size: 14,
                              color: sel ? t.couleur : AppColors.textSecondary),
                          label: Text(t.libelle),
                          selected: sel,
                          onSelected: (_) =>
                              notifier.setFiltre(sel ? null : t),
                          selectedColor: t.couleur.withValues(alpha: 0.12),
                          checkmarkColor: t.couleur,
                          labelStyle: TextStyle(
                            color: sel ? t.couleur : AppColors.textSecondary,
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // ── Liste des logs ──────────────────────────────────────
          Expanded(
            child: etatAsync.when(
              loading: () => _ShimmerLogs(),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.danger, size: 48),
                    const SizedBox(height: 12),
                    Text('Erreur : $e'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(logsProvider),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (etat) {
                final logs = etat.filtres;
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history,
                            size: 64,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun log à afficher',
                          style: AppTypography.textTheme.titleSmall,
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: _adminPrimary,
                  onRefresh: notifier.rafraichir,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: logs.length,
                    itemBuilder: (_, i) => LogSystemeCard(
                      log: logs[i],
                      onArchiver: () =>
                          notifier.archiverLog(logs[i].id),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exporterCSV(BuildContext context, WidgetRef ref) async {
    final csv = await ref.read(logsProvider.notifier).exporterCSV();
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Export CSV généré'),
          content: Text(
            csv.length > 200
                ? '${csv.substring(0, 200)}...\n\n(${csv.split('\n').length} lignes)'
                : csv,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    }
  }
}

class _ShimmerLogs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (_, __) => Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
