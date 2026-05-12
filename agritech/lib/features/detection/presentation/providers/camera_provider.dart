import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État complet de la caméra
@immutable
class CameraState {
  const CameraState({
    this.cameras = const [],
    this.controller,
    this.estInitialisee = false,
    this.indexCamera = 0,
    this.modeFlash = FlashMode.auto,
    this.niveauZoom = 1.0,
    this.zoomMin = 1.0,
    this.zoomMax = 5.0,
    this.imageCapturee,
    this.erreur,
  });

  final List<CameraDescription> cameras;
  final CameraController? controller;
  final bool estInitialisee;
  final int indexCamera;
  final FlashMode modeFlash;
  final double niveauZoom;
  final double zoomMin;
  final double zoomMax;
  final File? imageCapturee;
  final String? erreur;

  bool get aCamera => cameras.isNotEmpty;
  bool get peutCapturerPhoto => estInitialisee && controller != null;

  CameraState copyWith({
    List<CameraDescription>? cameras,
    CameraController? controller,
    bool? estInitialisee,
    int? indexCamera,
    FlashMode? modeFlash,
    double? niveauZoom,
    double? zoomMin,
    double? zoomMax,
    File? imageCapturee,
    String? erreur,
  }) {
    return CameraState(
      cameras: cameras ?? this.cameras,
      controller: controller ?? this.controller,
      estInitialisee: estInitialisee ?? this.estInitialisee,
      indexCamera: indexCamera ?? this.indexCamera,
      modeFlash: modeFlash ?? this.modeFlash,
      niveauZoom: niveauZoom ?? this.niveauZoom,
      zoomMin: zoomMin ?? this.zoomMin,
      zoomMax: zoomMax ?? this.zoomMax,
      imageCapturee: imageCapturee ?? this.imageCapturee,
      erreur: erreur,
    );
  }
}

/// Notifier de gestion de la caméra
class CameraNotifier extends AsyncNotifier<CameraState> {
  @override
  Future<CameraState> build() async {
    ref.onDispose(_disposerController);
    return _initialiserCameras();
  }

  Future<CameraState> _initialiserCameras() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return const CameraState(erreur: 'Aucune caméra disponible');
      }
      return CameraState(cameras: cameras);
    } catch (e) {
      return CameraState(erreur: 'Erreur d\'initialisation caméra : $e');
    }
  }

  /// Démarre le contrôleur caméra avec la caméra courante
  Future<void> demarrerCamera() async {
    final current = state.value;
    if (current == null || !current.aCamera) return;

    await _disposerController();

    final camera = current.cameras[current.indexCamera];
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      final zoomMin = await controller.getMinZoomLevel();
      final zoomMax = await controller.getMaxZoomLevel();
      await controller.setFlashMode(current.modeFlash);

      state = AsyncData(current.copyWith(
        controller: controller,
        estInitialisee: true,
        zoomMin: zoomMin,
        zoomMax: zoomMax,
        erreur: null,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(
        erreur: 'Erreur démarrage caméra : $e',
      ));
    }
  }

  /// Capture une photo
  Future<File?> capturerPhoto() async {
    final ctrl = state.value?.controller;
    if (ctrl == null || !ctrl.value.isInitialized) return null;

    try {
      final xFile = await ctrl.takePicture();
      final file = File(xFile.path);
      state = AsyncData(state.value!.copyWith(imageCapturee: file));
      return file;
    } catch (e) {
      return null;
    }
  }

  /// Bascule entre caméra avant et arrière
  Future<void> basculerCamera() async {
    final current = state.value;
    if (current == null || current.cameras.length < 2) return;

    final nouvelIndex = (current.indexCamera + 1) % current.cameras.length;
    state = AsyncData(current.copyWith(indexCamera: nouvelIndex, estInitialisee: false));
    await demarrerCamera();
  }

  /// Change le mode flash
  Future<void> changerFlash() async {
    final current = state.value;
    if (current == null) return;

    final prochainMode = _prochainModeFlash(current.modeFlash);
    await current.controller?.setFlashMode(prochainMode);
    state = AsyncData(current.copyWith(modeFlash: prochainMode));
  }

  /// Applique un niveau de zoom
  Future<void> setZoom(double zoom) async {
    final current = state.value;
    if (current == null || current.controller == null) return;

    final zoomClamp = zoom.clamp(current.zoomMin, current.zoomMax);
    await current.controller!.setZoomLevel(zoomClamp);
    state = AsyncData(current.copyWith(niveauZoom: zoomClamp));
  }

  FlashMode _prochainModeFlash(FlashMode actuel) {
    switch (actuel) {
      case FlashMode.auto:
        return FlashMode.always;
      case FlashMode.always:
        return FlashMode.off;
      case FlashMode.off:
        return FlashMode.auto;
      default:
        return FlashMode.auto;
    }
  }

  Future<void> _disposerController() async {
    final ctrl = state.value?.controller;
    if (ctrl != null && ctrl.value.isInitialized) {
      await ctrl.dispose();
    }
  }
}

final cameraProvider =
    AsyncNotifierProvider<CameraNotifier, CameraState>(CameraNotifier.new);
