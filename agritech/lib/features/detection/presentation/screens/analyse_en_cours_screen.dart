import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../navigation/app_router.dart';
import '../providers/detection_provider.dart';
import '../widgets/scan_line_animation.dart';

/// Écran 4 — Animation de scan IA en 4 phases pendant l'analyse
class AnalyseEnCoursScreen extends ConsumerStatefulWidget {
  const AnalyseEnCoursScreen({
    required this.imageFile,
    this.champId,
    super.key,
  });

  final File imageFile;
  final String? champId;

  @override
  ConsumerState<AnalyseEnCoursScreen> createState() =>
      _AnalyseEnCoursScreenState();
}

class _AnalyseEnCoursScreenState extends ConsumerState<AnalyseEnCoursScreen> {
  bool _analyseDemarree = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _demarrer());
  }

  Future<void> _demarrer() async {
    if (_analyseDemarree) return;
    _analyseDemarree = true;
    await ref.read(detectionProvider.notifier).lancerAnalyse(
          imageFile: widget.imageFile,
          champId: widget.champId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final detectionAsync = ref.watch(detectionProvider);

    ref.listen<AsyncValue<DetectionState>>(detectionProvider, (_, next) {
      next.whenData((state) {
        if (state.step == DetectionStep.done && state.resultat != null) {
          context.pushReplacement(
            AppRoutes.diagnosticResult,
            extra: state.resultat,
          );
        }
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFF060E0B),
      body: detectionAsync.when(
        loading: () => const _PhaseWidget(
          message: 'Initialisation...',
          progression: 0,
          phase: DetectionStep.preprocessing,
          imageFile: null,
        ),
        error: (e, _) => _ErreurWidget(message: e.toString()),
        data: (state) => _PhaseWidget(
          message: state.messageEtape,
          progression: state.progression,
          phase: state.step,
          imageFile: widget.imageFile,
        ),
      ),
    );
  }
}

class _PhaseWidget extends StatelessWidget {
  const _PhaseWidget({
    required this.message,
    required this.progression,
    required this.phase,
    required this.imageFile,
  });

  final String message;
  final double progression;
  final DetectionStep phase;
  final File? imageFile;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Titre
            Text(
              'Analyse en cours...',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 8),

            Text(
              'Modèle IA AgriSmart v2.1',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 32),

            // Image avec animation selon la phase
            Expanded(
              child: Center(
                child: _ImagePhase(phase: phase, imageFile: imageFile),
              ),
            ),

            const SizedBox(height: 24),

            // Message de l'étape courante
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                message,
                key: ValueKey(message),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // Barre de progression globale
            _BarreProgression(progression: progression),

            const SizedBox(height: 16),

            // Étapes visuelles
            _EtapesRow(phaseActuelle: phase),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ImagePhase extends StatelessWidget {
  const _ImagePhase({required this.phase, required this.imageFile});

  final DetectionStep phase;
  final File? imageFile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Image de base
          if (imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                imageFile!,
                width: 260,
                height: 260,
                fit: BoxFit.cover,
              ),
            ).animate().fadeIn(duration: 600.ms)
          else
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.eco, size: 80, color: AppColors.primary),
            ),

          // Phase 1 : grille qui s'étend
          if (phase == DetectionStep.preprocessing)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(
                  painter: _GridPainter(),
                ),
              ),
            ),

          // Phase 2 : points lumineux (feature extraction)
          if (phase == DetectionStep.extraction)
            Positioned.fill(
              child: _PointsLumineux(),
            ),

          // Phase 3 : scan line + overlay IA
          if (phase == DetectionStep.analyse)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: const ScanLineAnimation(child: SizedBox.expand()),
              ),
            ),

          // Phase 4 : checkmark final
          if (phase == DetectionStep.finalisation ||
              phase == DetectionStep.done)
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.primary,
                size: 80,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.7, 0.7)),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1D9E75).withValues(alpha: 0.35)
      ..strokeWidth = 1;

    const step = 26.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _PointsLumineux extends StatefulWidget {
  @override
  State<_PointsLumineux> createState() => _PointsLumineuxState();
}

class _PointsLumineuxState extends State<_PointsLumineux>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _random = Random(42);
  late List<Offset> _positions;

  @override
  void initState() {
    super.initState();
    _positions = List.generate(
      18,
      (_) => Offset(
        0.05 + _random.nextDouble() * 0.90,
        0.05 + _random.nextDouble() * 0.90,
      ),
    );
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return CustomPaint(
          painter: _PointsPainter(_positions, _ctrl.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _PointsPainter extends CustomPainter {
  const _PointsPainter(this.positions, this.t);

  final List<Offset> positions;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < positions.length; i++) {
      final opacity = ((t + i * 0.13) % 1.0);
      paint.color =
          const Color(0xFF1D9E75).withValues(alpha: (0.3 + opacity * 0.7));
      canvas.drawCircle(
        Offset(positions[i].dx * size.width, positions[i].dy * size.height),
        3 + opacity * 3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PointsPainter old) => old.t != t;
}

class _BarreProgression extends StatelessWidget {
  const _BarreProgression({required this.progression});

  final double progression;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progression',
              style: GoogleFonts.inter(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
            ),
            Text(
              '${(progression * 100).toInt()}%',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progression),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (_, val, __) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: val,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EtapesRow extends StatelessWidget {
  const _EtapesRow({required this.phaseActuelle});

  final DetectionStep phaseActuelle;

  static const _etapes = [
    (DetectionStep.preprocessing, 'Prétraitement', Icons.tune),
    (DetectionStep.extraction, 'Extraction', Icons.grain),
    (DetectionStep.analyse, 'Analyse IA', Icons.psychology_outlined),
    (DetectionStep.finalisation, 'Résultat', Icons.check_circle_outline),
  ];

  bool _estFait(DetectionStep etape) {
    final ordre = [
      DetectionStep.preprocessing,
      DetectionStep.extraction,
      DetectionStep.analyse,
      DetectionStep.finalisation,
      DetectionStep.done,
    ];
    final indexActuel = ordre.indexOf(phaseActuelle);
    final indexEtape = ordre.indexOf(etape);
    return indexEtape < indexActuel;
  }

  bool _estActif(DetectionStep etape) => phaseActuelle == etape;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _etapes.map((e) {
        final fait = _estFait(e.$1);
        final actif = _estActif(e.$1);
        final couleur = fait || actif
            ? AppColors.primary
            : Colors.white.withValues(alpha: 0.3);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (fait || actif)
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: couleur, width: 1.5),
              ),
              child: Icon(e.$3, size: 16, color: couleur),
            ),
            const SizedBox(height: 4),
            Text(
              e.$2,
              style: GoogleFonts.inter(fontSize: 10, color: couleur),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _ErreurWidget extends StatelessWidget {
  const _ErreurWidget({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60, color: AppColors.coral),
            const SizedBox(height: 16),
            Text(
              'Erreur d\'analyse',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
