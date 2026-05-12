import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/decision_expert.dart';
import '../providers/expert_provider.dart';
import '../widgets/gravite_badge.dart';
import '../widgets/score_ia_indicator.dart';
import 'validation_sheet.dart';
import 'correction_sheet.dart';

/// Vue complète d'un diagnostic pour décision de l'Expert
class DiagnosticDetailExpertScreen extends ConsumerStatefulWidget {
  const DiagnosticDetailExpertScreen({super.key, required this.diagnosticId});
  final String diagnosticId;

  @override
  ConsumerState<DiagnosticDetailExpertScreen> createState() =>
      _DiagnosticDetailExpertScreenState();
}

class _DiagnosticDetailExpertScreenState
    extends ConsumerState<DiagnosticDetailExpertScreen> {
  DecisionExpert? _decisionSelectee;
  final _observationsCtrl = TextEditingController();

  @override
  void dispose() {
    _observationsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diagAsync = ref.watch(
      diagnosticDetailProvider(widget.diagnosticId),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: diagAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (diag) => CustomScrollView(
          slivers: [
            // ── SliverAppBar avec image ──────────────────────────
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: diag.imageUrl != null
                    ? Image.network(
                        diag.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.primaryDark,
                          child: const Icon(Icons.image_outlined,
                              size: 64, color: Colors.white30),
                        ),
                      )
                    : Container(color: AppColors.primaryDark),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () => _showValidation(context),
                  icon: const Icon(Icons.check_circle_outline,
                      size: 18, color: Colors.white),
                  label: Text('Valider',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                TextButton.icon(
                  onPressed: () => _showCorrection(context),
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.amber),
                  label: Text('Corriger',
                      style: GoogleFonts.poppins(
                          color: Colors.amber, fontWeight: FontWeight.w600)),
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Section 1 : Informations soumission ─────────
                  _sectionTitle('Informations soumission'),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _infoRow(Icons.person_outline, 'Agriculteur',
                              '${diag.agriculteurNom} · ${diag.agriculteurVillage}'),
                          _infoRow(Icons.phone_outlined, 'Téléphone',
                              diag.agriculteurTelephone),
                          _infoRow(Icons.terrain_outlined, 'Champ',
                              '${diag.champNom} (${diag.champSuperficie.toStringAsFixed(1)} ha)'),
                          _infoRow(Icons.schedule_outlined, 'Soumis',
                              diag.tempsEcoule),
                          if (diag.commentaireAgriculteur != null)
                            _infoRow(Icons.comment_outlined, 'Commentaire',
                                diag.commentaireAgriculteur!),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Section 2 : Résultat IA ──────────────────────
                  _sectionTitle('Résultat du modèle IA'),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      diag.maladieIA.nom,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      diag.maladieIA.nomScientifique,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GraviteBadge(gravite: diag.niveauGraviteIA),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ScoreIaIndicator(score: diag.scoreConfiance),
                          const SizedBox(height: 16),
                          // Top prédictions
                          Text(
                            'Top prédictions',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...diag.topPredictions.map((p) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        p.maladie.nom,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0, end: p.score),
                                        duration: const Duration(milliseconds: 800),
                                        builder: (_, v, __) => LinearProgressIndicator(
                                          value: v,
                                          backgroundColor:
                                              AppColors.border,
                                          valueColor: const AlwaysStoppedAnimation(
                                            AppColors.info,
                                          ),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 36,
                                      child: Text(
                                        '${(p.score * 100).round()}%',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Section 3 : Analyse Expert ──────────────────
                  _sectionTitle('Votre analyse'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.amber.withValues(alpha: 0.3)),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Le diagnostic IA est-il correct ?',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...DecisionExpert.values.map((d) => GestureDetector(
                              onTap: () => setState(() => _decisionSelectee = d),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _decisionSelectee == d
                                      ? d.couleurFond
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _decisionSelectee == d
                                        ? d.couleur
                                        : AppColors.border,
                                    width: _decisionSelectee == d ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(d.icone, color: d.couleur, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      d.libelle,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: d.couleur,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _observationsCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Observations de l\'Expert...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _decisionSelectee == null
            ? null
            : () {
                if (_decisionSelectee == DecisionExpert.correct) {
                  _showValidation(context);
                } else {
                  _showCorrection(context);
                }
              },
        backgroundColor: _decisionSelectee == null
            ? AppColors.border
            : AppColors.primary,
        label: Text(
          'Soumettre ma décision',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        icon: const Icon(Icons.send_outlined, color: Colors.white),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );

  Widget _infoRow(IconData icon, String label, String valeur) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              '$label : ',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            Expanded(
              child: Text(
                valeur,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );

  void _showValidation(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ValidationSheet(
        diagnosticId: widget.diagnosticId,
        onConfirmer: (commentaire, notifier) async {
          final ok = await ref
              .read(diagnosticsNotifier.notifier)
              .validerDiagnostic(
                diagnosticId: widget.diagnosticId,
                commentaire: commentaire,
                notifierAgriculteur: notifier,
              );
          if (ok && ctx.mounted) {
            Navigator.pop(ctx);
            ctx.pop();
          }
        },
      ),
    );
  }

  void _showCorrection(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CorrectionSheet(
        diagnosticId: widget.diagnosticId,
        notifier: ref.read(diagnosticsNotifier.notifier),
        onDone: () {
          if (ctx.mounted) {
            Navigator.pop(ctx);
            ctx.pop();
          }
        },
      ),
    );
  }
}
