import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/detection_provider.dart';

/// Écran 7 — BottomSheet d'évaluation du diagnostic par l'utilisateur
class EvaluationDiagnosticSheet extends ConsumerStatefulWidget {
  const EvaluationDiagnosticSheet({required this.diagnosticId, super.key});

  final String diagnosticId;

  @override
  ConsumerState<EvaluationDiagnosticSheet> createState() =>
      _EvaluationDiagnosticSheetState();
}

class _EvaluationDiagnosticSheetState
    extends ConsumerState<EvaluationDiagnosticSheet> {
  String? _choixSelectionne;
  bool _enEnvoi = false;
  bool _envoiConfirme = false;
  final _commentaireCtrl = TextEditingController();

  @override
  void dispose() {
    _commentaireCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyerEvaluation() async {
    if (_choixSelectionne == null) return;
    setState(() => _enEnvoi = true);

    await ref.read(detectionProvider.notifier).soumettreEvaluation(
          diagnosticId: widget.diagnosticId,
          choix: _choixSelectionne!,
          commentaire: _commentaireCtrl.text.trim().isEmpty
              ? null
              : _commentaireCtrl.text.trim(),
        );

    setState(() {
      _enEnvoi = false;
      _envoiConfirme = true;
    });

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _envoiConfirme
              ? _MerciView()
              : ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    _Handle(),
                    const SizedBox(height: 4),
                    Text(
                      'Ce diagnostic était-il correct ?',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Votre retour améliore notre modèle IA',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Options d'évaluation
                    _OptionCard(
                      label: 'Correct',
                      sousTitre: 'Le diagnostic était juste',
                      icone: Icons.check_circle_outline,
                      couleur: AppColors.primary,
                      selectionne: _choixSelectionne == 'CORRECT',
                      onTap: () =>
                          setState(() => _choixSelectionne = 'CORRECT'),
                    ),
                    const SizedBox(height: 10),
                    _OptionCard(
                      label: 'Partiel',
                      sousTitre: 'Partiellement correct',
                      icone: Icons.remove_circle_outline,
                      couleur: AppColors.amber,
                      selectionne: _choixSelectionne == 'PARTIEL',
                      onTap: () =>
                          setState(() => _choixSelectionne = 'PARTIEL'),
                    ),
                    const SizedBox(height: 10),
                    _OptionCard(
                      label: 'Incorrect',
                      sousTitre: 'Mauvais diagnostic',
                      icone: Icons.cancel_outlined,
                      couleur: AppColors.coral,
                      selectionne: _choixSelectionne == 'INCORRECT',
                      onTap: () =>
                          setState(() => _choixSelectionne = 'INCORRECT'),
                    ),

                    // Commentaire (visible après sélection)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      child: _choixSelectionne != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _commentaireCtrl,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Commentaire optionnel — aidez-nous à améliorer l\'IA...',
                                    hintStyle: GoogleFonts.inter(
                                        color: AppColors.textSecondary,
                                        fontSize: 13),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _choixSelectionne != null && !_enEnvoi
                          ? _envoyerEvaluation
                          : null,
                      child: _enEnvoi
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Envoyer mon évaluation'),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _OptionCard extends StatefulWidget {
  const _OptionCard({
    required this.label,
    required this.sousTitre,
    required this.icone,
    required this.couleur,
    required this.selectionne,
    required this.onTap,
  });

  final String label;
  final String sousTitre;
  final IconData icone;
  final Color couleur;
  final bool selectionne;
  final VoidCallback onTap;

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    await _ctrl.forward();
    await _ctrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.selectionne
                ? widget.couleur.withValues(alpha: 0.1)
                : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  widget.selectionne ? widget.couleur : AppColors.border,
              width: widget.selectionne ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(widget.icone, color: widget.couleur, size: 28),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: widget.selectionne
                          ? widget.couleur
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    widget.sousTitre,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (widget.selectionne)
                Icon(Icons.check_circle, color: widget.couleur, size: 20)
                    .animate()
                    .scale(begin: const Offset(0, 0)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MerciView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: AppColors.primary, size: 60)
                .animate()
                .scale(begin: const Offset(0, 0), curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(
              'Merci !',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre retour aide à améliorer le modèle IA AgriSmart pour tous les agriculteurs.',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
