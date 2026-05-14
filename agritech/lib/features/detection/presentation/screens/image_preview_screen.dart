import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../navigation/app_router.dart';
import '../../../champs/presentation/providers/champ_provider.dart';
import '../../data/services/image_preprocessing_service.dart';
import '../widgets/image_quality_indicator.dart';

/// Écran 3 — Prévisualisation de l'image avant analyse IA
class ImagePreviewScreen extends ConsumerStatefulWidget {
  const ImagePreviewScreen({required this.imageFile, super.key});

  final File imageFile;

  @override
  ConsumerState<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends ConsumerState<ImagePreviewScreen> {
  ImageQualityResult? _qualite;
  bool _enEvaluation = true;
  String? _champIdSelectionne;

  @override
  void initState() {
    super.initState();
    _evaluerQualite();
  }

  Future<void> _evaluerQualite() async {
    final service = ImagePreprocessingService();
    final resultat = await service.evaluerQualite(widget.imageFile);
    if (mounted) {
      setState(() {
        _qualite = resultat;
        _enEvaluation = false;
      });
    }
  }

  void _lancerAnalyse() {
    context.push(
      AppRoutes.analyseEnCours,
      extra: {
        'imageFile': widget.imageFile,
        'champId': _champIdSelectionne,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final champsAsync = ref.watch(champProvider);
    final peutAnalyser = _qualite?.peutAnalyser ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image plein écran avec zoom/pan
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Bouton retour
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 22),
              onPressed: () => context.pop(),
            ),
          ),

          // Overlay bas — contrôles
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.92),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicateur qualité
                  if (_enEvaluation)
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Évaluation de la qualité...',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    )
                  else if (_qualite != null)
                    ImageQualityIndicator(resultat: _qualite!),

                  const SizedBox(height: 14),

                  // Sélection du champ concerné
                  champsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (champs) {
                      if (champs.isEmpty) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: DropdownButton<String>(
                          value: _champIdSelectionne,
                          hint: Text(
                            'Quel champ est concerné ? (optionnel)',
                            style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13),
                          ),
                          dropdownColor: const Color(0xFF1A2E28),
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          iconEnabledColor: Colors.white,
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 13),
                          items: champs
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.nom),
                                  ))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _champIdSelectionne = val),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Boutons Reprendre / Analyser
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Reprendre'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: peutAnalyser ? _lancerAnalyse : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor:
                                AppColors.primary.withValues(alpha: 0.4),
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Analyser'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
