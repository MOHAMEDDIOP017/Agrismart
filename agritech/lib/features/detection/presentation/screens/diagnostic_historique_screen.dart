import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../navigation/app_router.dart';
import '../../domain/entities/diagnostic_entity.dart';
import '../providers/historique_provider.dart';
import '../widgets/gravite_badge.dart';

/// Écran 6 — Historique complet des diagnostics avec filtres
class DiagnosticHistoriqueScreen extends ConsumerStatefulWidget {
  const DiagnosticHistoriqueScreen({super.key});

  @override
  ConsumerState<DiagnosticHistoriqueScreen> createState() =>
      _DiagnosticHistoriqueScreenState();
}

class _DiagnosticHistoriqueScreenState
    extends ConsumerState<DiagnosticHistoriqueScreen> {
  String _filtreActif = 'Tous';
  String _triActif = 'Plus récent';

  static const _filtres = ['Tous', 'Cette semaine', 'Ce mois'];
  static const _tris = ['Plus récent', 'Plus ancien', 'Par gravité'];

  List<DiagnosticEntity> _appliquerFiltreEtTri(
      List<DiagnosticEntity> liste) {
    final maintenant = DateTime.now();
    List<DiagnosticEntity> filtree = switch (_filtreActif) {
      'Cette semaine' => liste
          .where((d) =>
              maintenant.difference(d.dateAnalyse).inDays <= 7)
          .toList(),
      'Ce mois' => liste
          .where((d) =>
              d.dateAnalyse.month == maintenant.month &&
              d.dateAnalyse.year == maintenant.year)
          .toList(),
      _ => List.from(liste),
    };

    switch (_triActif) {
      case 'Plus ancien':
        filtree.sort((a, b) => a.dateAnalyse.compareTo(b.dateAnalyse));
      case 'Par gravité':
        filtree.sort((a, b) => b.maladieDetectee.gravite.index
            .compareTo(a.maladieDetectee.gravite.index));
      default:
        filtree.sort((a, b) => b.dateAnalyse.compareTo(a.dateAnalyse));
    }

    return filtree;
  }

  @override
  Widget build(BuildContext context) {
    final historiqueAsync = ref.watch(historiqueProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Historique des diagnostics',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Trier',
            initialValue: _triActif,
            onSelected: (val) => setState(() => _triActif = val),
            itemBuilder: (_) => _tris
                .map((t) => PopupMenuItem(value: t, child: Text(t)))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chips de filtre
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filtres.map((f) {
                  final actif = _filtreActif == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: actif,
                      onSelected: (_) => setState(() => _filtreActif = f),
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: actif
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                            actif ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Liste des diagnostics
          Expanded(
            child: historiqueAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (liste) {
                final filtree = _appliquerFiltreEtTri(liste);
                if (filtree.isEmpty) {
                  return _EtatVide(filtre: _filtreActif);
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      ref.read(historiqueProvider.notifier).rafraichir(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtree.length,
                    itemBuilder: (_, i) {
                      return Dismissible(
                        key: ValueKey(filtree[i].id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.archive_outlined,
                                  color: AppColors.textSecondary),
                              SizedBox(height: 4),
                              Text('Archiver',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        onDismissed: (_) => ref
                            .read(historiqueProvider.notifier)
                            .archiver(filtree[i].id),
                        child: _DiagnosticHistoriqueCard(
                          diagnostic: filtree[i],
                          onTap: () => context.push(
                            AppRoutes.diagnosticResult,
                            extra: filtree[i],
                          ),
                        )
                            .animate(delay: Duration(milliseconds: 60 * i))
                            .fadeIn()
                            .slideY(begin: 0.08, end: 0),
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

class _DiagnosticHistoriqueCard extends StatelessWidget {
  const _DiagnosticHistoriqueCard({
    required this.diagnostic,
    required this.onTap,
  });

  final DiagnosticEntity diagnostic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy • HH:mm', 'fr_FR');
    final maladie = diagnostic.maladieDetectee;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            // Vignette image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 64,
                height: 64,
                color: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.eco_outlined,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          maladie.nom,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        diagnostic.scoreConfianseFormate,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fmt.format(diagnostic.dateAnalyse),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (diagnostic.champNom != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.terrain_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          diagnostic.champNom!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      GraviteBadge(
                          gravite: maladie.gravite, compact: true),
                      const SizedBox(width: 8),
                      _StatutBadge(statut: diagnostic.statut),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _StatutBadge extends StatelessWidget {
  const _StatutBadge({required this.statut});

  final dynamic statut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: statut.couleurFond,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statut.icone, size: 10, color: statut.couleur),
          const SizedBox(width: 3),
          Text(
            statut.libelle,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: statut.couleur,
            ),
          ),
        ],
      ),
    );
  }
}

class _EtatVide extends StatelessWidget {
  const _EtatVide({required this.filtre});

  final String filtre;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            filtre == 'Tous'
                ? 'Aucun diagnostic pour l\'instant'
                : 'Aucun diagnostic pour "$filtre"',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prenez une photo pour commencer',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
