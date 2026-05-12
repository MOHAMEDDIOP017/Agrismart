import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../navigation/app_router.dart';
import '../providers/camera_provider.dart';
import '../widgets/detection_frame.dart';
import '../widgets/scan_line_animation.dart';

/// Écran 2 — Caméra personnalisée avec animations de guidage
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  bool _afficherSliderZoom = false;
  double _zoomBase = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraProvider.notifier).demarrerCamera();
    });
  }

  Future<void> _capturer() async {
    final file = await ref.read(cameraProvider.notifier).capturerPhoto();
    if (file != null && mounted) {
      context.push(AppRoutes.imagePreview, extra: file);
    }
  }

  Future<void> _ouvrirGalerie() async {
    final xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (xFile != null && mounted) {
      context.push(AppRoutes.imagePreview, extra: File(xFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final camState = ref.watch(cameraProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: camState.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _ErreurCamera(message: e.toString()),
        data: (state) {
          if (state.erreur != null) {
            return _ErreurCamera(message: state.erreur!);
          }
          if (!state.estInitialisee || state.controller == null) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          return _CameraBody(
            camState: state,
            afficherSliderZoom: _afficherSliderZoom,
            zoomBase: _zoomBase,
            onCapture: _capturer,
            onFlip: () => ref.read(cameraProvider.notifier).basculerCamera(),
            onFlash: () => ref.read(cameraProvider.notifier).changerFlash(),
            onScaleStart: (details) {
              _zoomBase = state.niveauZoom;
            },
            onScaleUpdate: (details) {
              final nouveau = (_zoomBase * details.scale)
                  .clamp(state.zoomMin, state.zoomMax);
              ref.read(cameraProvider.notifier).setZoom(nouveau);
              setState(() => _afficherSliderZoom = true);
            },
            onZoomChange: (val) =>
                ref.read(cameraProvider.notifier).setZoom(val),
            onGallery: _ouvrirGalerie,
          );
        },
      ),
    );
  }
}

class _CameraBody extends StatelessWidget {
  const _CameraBody({
    required this.camState,
    required this.afficherSliderZoom,
    required this.zoomBase,
    required this.onCapture,
    required this.onFlip,
    required this.onFlash,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onZoomChange,
    required this.onGallery,
  });

  final CameraState camState;
  final bool afficherSliderZoom;
  final double zoomBase;
  final VoidCallback onCapture;
  final VoidCallback onFlip;
  final VoidCallback onFlash;
  final void Function(ScaleStartDetails) onScaleStart;
  final void Function(ScaleUpdateDetails) onScaleUpdate;
  final void Function(double) onZoomChange;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: onScaleStart,
      onScaleUpdate: onScaleUpdate,
      child: Stack(
        children: [
          // Preview caméra plein écran
          Positioned.fill(
            child: CameraPreview(camState.controller!),
          ),

          // Animation de scan en boucle
          const Positioned.fill(
            child: ScanLineAnimation(child: SizedBox.expand()),
          ),

          // Cadre de guidage animé
          const Positioned.fill(
            child: DetectionFrame(),
          ),

          // Texte de guidage centré
          Positioned(
            top: MediaQuery.of(context).size.height * 0.75,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Centrez la feuille dans le cadre',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),

          // Slider de zoom (apparaît après pinch)
          if (afficherSliderZoom)
            Positioned(
              bottom: 160,
              left: 40,
              right: 40,
              child: Row(
                children: [
                  Text(
                    '${camState.zoomMin.toStringAsFixed(1)}x',
                    style:
                        GoogleFonts.inter(color: Colors.white, fontSize: 11),
                  ),
                  Expanded(
                    child: Slider(
                      value: camState.niveauZoom,
                      min: camState.zoomMin,
                      max: camState.zoomMax,
                      onChanged: onZoomChange,
                      activeColor: AppColors.primary,
                      inactiveColor: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  Text(
                    '${camState.niveauZoom.toStringAsFixed(1)}x',
                    style:
                        GoogleFonts.inter(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),

          // Bouton retour (haut gauche)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 22),
              onPressed: () => context.pop(),
            ),
          ),

          // Bouton flash (haut droit)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: _FlashButton(modeFlash: camState.modeFlash, onTap: onFlash),
          ),

          // Contrôles bas de page
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _ControlesBas(
              onCapture: onCapture,
              onFlip: onFlip,
              onGallery: onGallery,
              aDeuxCameras: camState.cameras.length > 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashButton extends StatefulWidget {
  const _FlashButton({required this.modeFlash, required this.onTap});

  final FlashMode modeFlash;
  final VoidCallback onTap;

  @override
  State<_FlashButton> createState() => _FlashButtonState();
}

class _FlashButtonState extends State<_FlashButton> {
  IconData get _icone {
    switch (widget.modeFlash) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.off:
        return Icons.flash_off;
      default:
        return Icons.flash_auto;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: IconButton(
        key: ValueKey(widget.modeFlash),
        icon: Icon(_icone, color: Colors.white, size: 26),
        onPressed: widget.onTap,
      ),
    );
  }
}

class _ControlesBas extends StatelessWidget {
  const _ControlesBas({
    required this.onCapture,
    required this.onFlip,
    required this.onGallery,
    required this.aDeuxCameras,
  });

  final VoidCallback onCapture;
  final VoidCallback onFlip;
  final VoidCallback onGallery;
  final bool aDeuxCameras;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.85),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bouton galerie
          IconButton(
            onPressed: onGallery,
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_library_outlined,
                  color: Colors.white, size: 24),
            ),
          ),

          // Bouton capture principal
          _BoutonCapture(onTap: onCapture),

          // Bouton switch caméra
          if (aDeuxCameras)
            _BoutonSwitch(onTap: onFlip)
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _BoutonCapture extends StatefulWidget {
  const _BoutonCapture({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_BoutonCapture> createState() => _BoutonCaptureState();
}

class _BoutonCaptureState extends State<_BoutonCapture>
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
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
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
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoutonSwitch extends StatefulWidget {
  const _BoutonSwitch({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_BoutonSwitch> createState() => _BoutonSwitchState();
}

class _BoutonSwitchState extends State<_BoutonSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _rotation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _onTap,
      icon: RotationTransition(
        turns: _rotation,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child:
              const Icon(Icons.flip_camera_ios_outlined, color: Colors.white),
        ),
      ),
    );
  }
}

class _ErreurCamera extends StatelessWidget {
  const _ErreurCamera({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Caméra indisponible',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
