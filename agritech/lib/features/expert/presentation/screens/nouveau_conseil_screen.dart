import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/type_conseil.dart';
import '../providers/expert_provider.dart';

/// Formulaire de création d'un nouveau conseil
class NouveauConseilScreen extends ConsumerStatefulWidget {
  const NouveauConseilScreen({super.key});

  @override
  ConsumerState<NouveauConseilScreen> createState() => _NouveauConseilScreenState();
}

class _NouveauConseilScreenState extends ConsumerState<NouveauConseilScreen> {
  final _formKey = GlobalKey<FormState>();
  TypeConseil _type = TypeConseil.culture;
  String? _agriculteurId;
  String? _champId;
  final _titreCtrl = TextEditingController();
  final _corpsCtrl = TextEditingController();
  bool _estUrgent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titreCtrl.dispose();
    _corpsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final champsAsync = ref.watch(champsSupervisionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Text('Nouveau conseil',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Section 1 : Destinataire ────────────────────────
            _sectionTitle('1. Destinataire'),
            const SizedBox(height: 10),
            champsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox(),
              data: (champs) => DropdownButtonFormField<String>(
                decoration: _inputDeco('Sélectionner un champ / agriculteur'),
                value: _champId,
                items: champs
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            '${c.nom} — ${c.agriculteurNom}',
                            style: GoogleFonts.inter(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  final c = champs.firstWhere((ch) => ch.id == v);
                  setState(() {
                    _champId = v;
                    _agriculteurId = c.agriculteurId;
                  });
                },
                validator: (v) => v == null ? 'Sélectionnez un champ' : null,
              ),
            ),

            const SizedBox(height: 20),

            // ── Section 2 : Type ────────────────────────────────
            _sectionTitle('2. Type de conseil'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TypeConseil.values
                  .map((t) => GestureDetector(
                        onTap: () => setState(() => _type = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _type == t
                                ? t.couleur.withValues(alpha: 0.15)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _type == t ? t.couleur : AppColors.border,
                              width: _type == t ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(t.icone, size: 14, color: t.couleur),
                              const SizedBox(width: 6),
                              Text(t.libelle,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: t.couleur)),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 20),

            // ── Section 3 : Contenu ─────────────────────────────
            _sectionTitle('3. Contenu du conseil'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _titreCtrl,
              decoration: _inputDeco('Titre du conseil'),
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Le titre est requis' : null,
            ),
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _estUrgent
                    ? AppColors.danger.withValues(alpha: 0.04)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextFormField(
                controller: _corpsCtrl,
                maxLines: 6,
                decoration: _inputDeco('Rédigez votre conseil...').copyWith(
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Le conseil doit comporter au moins 10 caractères'
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Marquer comme urgent',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      Text('L\'agriculteur recevra une alerte prioritaire',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _estUrgent,
                  activeColor: AppColors.danger,
                  onChanged: (v) => setState(() => _estUrgent = v),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Bouton envoyer ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _envoyer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                child: Text(_isLoading ? 'Envoi en cours...' : 'Envoyer le conseil'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  Widget _sectionTitle(String t) => Text(
        t,
        style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
      );

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final ok = await ref.read(conseilsProvider.notifier).envoyer(
          agriculteurId: _agriculteurId ?? 'usr_002',
          champId: _champId ?? 'champ_010',
          type: _type,
          titre: _titreCtrl.text.trim(),
          corps: _corpsCtrl.text.trim(),
          estUrgent: _estUrgent,
        );
    if (mounted) {
      setState(() => _isLoading = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conseil envoyé avec succès !'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop();
      }
    }
  }
}
