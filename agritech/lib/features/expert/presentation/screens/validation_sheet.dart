import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// BottomSheet de validation rapide d'un diagnostic IA
class ValidationSheet extends StatefulWidget {
  const ValidationSheet({
    super.key,
    required this.diagnosticId,
    required this.onConfirmer,
    this.maladieNom,
    this.scoreConfiance,
  });

  final String diagnosticId;
  final Future<void> Function(String? commentaire, bool notifier) onConfirmer;
  final String? maladieNom;
  final int? scoreConfiance;

  @override
  State<ValidationSheet> createState() => _ValidationSheetState();
}

class _ValidationSheetState extends State<ValidationSheet> {
  final _commentaireCtrl = TextEditingController();
  bool _notifier = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentaireCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Poignée
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  // Titre
                  Text(
                    'Confirmer la validation',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vous confirmez que le diagnostic IA est correct',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Récapitulatif
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        if (widget.maladieNom != null)
                          _recapRow('Maladie', widget.maladieNom!),
                        if (widget.scoreConfiance != null)
                          _recapRow('Confiance IA', '${widget.scoreConfiance}%'),
                        _recapRow(
                          'Votre décision',
                          'VALIDÉ',
                          couleurValeur: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Commentaire
                  Text(
                    'Commentaire expert (optionnel)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentaireCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Ajoutez vos observations...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Toggle notif
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Envoyer le traitement à l\'agriculteur',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Notification automatique',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _notifier,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _notifier = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bouton confirmer
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirmer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Confirmer la validation'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recapRow(String label, String valeur, {Color? couleurValeur}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
            Text(
              valeur,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: couleurValeur ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );

  Future<void> _confirmer() async {
    setState(() => _isLoading = true);
    await widget.onConfirmer(
      _commentaireCtrl.text.trim().isEmpty ? null : _commentaireCtrl.text.trim(),
      _notifier,
    );
    if (mounted) setState(() => _isLoading = false);
  }
}
