import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';

// ── Provider : charge les experts depuis l'API ────────────────────────────────

final _expertsProvider = FutureProvider.autoDispose<List<_ExpertItem>>((ref) async {
  final dio = ApiClient().dio;
  final resp = await dio.get('/utilisateurs/experts');
  final liste = (resp.data['experts'] as List? ?? []).cast<Map<String, dynamic>>();
  return liste
      .where((e) => (e['actif'] as bool? ?? true))
      .map((e) => _ExpertItem(
            id: (e['id'] ?? '') as String,
            nom: (e['nom'] ?? '') as String,
            prenom: (e['prenom'] ?? '') as String,
            specialite: (e['specialite'] ?? 'Agronomie') as String,
            zone: (e['zone_geographique'] ?? 'Sénégal') as String,
          ))
      .where((e) => e.id.isNotEmpty)
      .toList();
});

// ── Widget principal ──────────────────────────────────────────────────────────

/// BottomSheet de sélection d'un expert agricole pour partager un diagnostic
class ExpertSelectionSheet extends ConsumerStatefulWidget {
  const ExpertSelectionSheet({required this.diagnosticId, super.key});

  final String diagnosticId;

  @override
  ConsumerState<ExpertSelectionSheet> createState() => _ExpertSelectionSheetState();
}

class _ExpertSelectionSheetState extends ConsumerState<ExpertSelectionSheet> {
  String? _expertSelectionneId;
  bool _envoiConfirme = false;
  bool _envoiEnCours = false;
  final _messageCtrl = TextEditingController();

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (_expertSelectionneId == null) return;
    // Capturer le messenger AVANT tout await (évite "deactivated widget" error)
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _envoiEnCours = true);

    try {
      final dio = ApiClient().dio;
      await dio.post(
        '/diagnostics/${widget.diagnosticId}/partager-expert',
        queryParameters: {'expert_id': _expertSelectionneId},
      );
      if (mounted) setState(() => _envoiConfirme = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      if (mounted) setState(() => _envoiEnCours = false);
      final detail = e.response?.data?['detail'] as String?;
      final message = (detail == 'Diagnostic introuvable.')
          ? 'Ce diagnostic n\'existe pas encore sur le serveur. Relancez une analyse en ligne.'
          : detail ?? 'Erreur lors de l\'envoi.';
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.danger),
      );
    } catch (_) {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expertsAsync = ref.watch(_expertsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _envoiConfirme
              ? _ConfirmationView()
              : Column(
                  children: [
                    _Handle(),
                    Expanded(
                      child: expertsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.wifi_off_outlined,
                                    size: 48, color: AppColors.textSecondary),
                                const SizedBox(height: 12),
                                Text(
                                  'Impossible de charger les experts.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => ref.invalidate(_expertsProvider),
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        data: (experts) => experts.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.person_search_outlined,
                                          size: 48, color: AppColors.textSecondary),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Aucun expert disponible pour le moment.',
                                        style: GoogleFonts.inter(
                                          color: AppColors.textSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView(
                                controller: scrollCtrl,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Partager avec un expert',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${experts.length} expert${experts.length > 1 ? 's' : ''} disponible${experts.length > 1 ? 's' : ''}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...experts.map((expert) => _ExpertCard(
                                        expert: expert,
                                        selectionne: _expertSelectionneId == expert.id,
                                        onTap: () => setState(
                                          () => _expertSelectionneId = expert.id,
                                        ),
                                      )),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _messageCtrl,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      hintText: 'Ajouter un message (optionnel)...',
                                      hintStyle: GoogleFonts.inter(
                                        color: AppColors.textSecondary,
                                      ),
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
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: (_expertSelectionneId != null && !_envoiEnCours)
                                        ? _envoyer
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      textStyle: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    child: _envoiEnCours
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text('Envoyer le diagnostic'),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ── Carte expert ──────────────────────────────────────────────────────────────

class _ExpertCard extends StatelessWidget {
  const _ExpertCard({
    required this.expert,
    required this.selectionne,
    required this.onTap,
  });

  final _ExpertItem expert;
  final bool selectionne;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selectionne
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectionne ? AppColors.primary : AppColors.border,
            width: selectionne ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                expert.initiales,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expert.nomComplet,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${expert.specialite} • ${expert.zone}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selectionne)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Vue de confirmation ───────────────────────────────────────────────────────

class _ConfirmationView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary, size: 64),
          const SizedBox(height: 16),
          Text(
            'Diagnostic envoyé !',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'L\'expert vous répondra dans les 24 heures.',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Poignée du sheet ──────────────────────────────────────────────────────────

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

// ── Modèle local ─────────────────────────────────────────────────────────────

class _ExpertItem {
  const _ExpertItem({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.specialite,
    required this.zone,
  });

  final String id;
  final String nom;
  final String prenom;
  final String specialite;
  final String zone;

  String get nomComplet => '$prenom $nom'.trim();

  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return '$p$n'.toUpperCase();
  }
}
