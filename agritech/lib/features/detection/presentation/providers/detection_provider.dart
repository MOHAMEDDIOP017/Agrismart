import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/detection_repository_impl.dart';
import '../../data/services/detection_api_service.dart';
import '../../data/services/image_preprocessing_service.dart';
import '../../domain/entities/diagnostic_entity.dart';
import '../../domain/repositories/detection_repository.dart';

// ---- Providers d'infrastructure ----

final imagePreprocessingServiceProvider = Provider<ImagePreprocessingService>(
  (_) => ImagePreprocessingService(),
);

final detectionApiServiceProvider = Provider<DetectionApiService>(
  (ref) => DetectionApiService(ref.read(dioProvider)),
);

final detectionRepositoryProvider = Provider<DetectionRepository>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  return DetectionRepositoryImpl(
    apiService: ref.read(detectionApiServiceProvider),
    preprocessingService: ref.read(imagePreprocessingServiceProvider),
    userId: userId,
  );
});

// ---- Étapes du flux d'analyse ----

enum DetectionStep {
  idle,
  preprocessing,
  extraction,
  analyse,
  finalisation,
  done,
  error,
}

// ---- État de la détection ----

@immutable
class DetectionState {
  const DetectionState({
    this.step = DetectionStep.idle,
    this.imageFile,
    this.progression = 0.0,
    this.messageEtape = '',
    this.resultat,
    this.erreur,
  });

  final DetectionStep step;
  final File? imageFile;
  final double progression;
  final String messageEtape;
  final DiagnosticEntity? resultat;
  final String? erreur;

  bool get estEnCours => step != DetectionStep.idle &&
      step != DetectionStep.done &&
      step != DetectionStep.error;

  DetectionState copyWith({
    DetectionStep? step,
    File? imageFile,
    double? progression,
    String? messageEtape,
    DiagnosticEntity? resultat,
    String? erreur,
  }) {
    return DetectionState(
      step: step ?? this.step,
      imageFile: imageFile ?? this.imageFile,
      progression: progression ?? this.progression,
      messageEtape: messageEtape ?? this.messageEtape,
      resultat: resultat ?? this.resultat,
      erreur: erreur ?? this.erreur,
    );
  }
}

// ---- Notifier principal ----

class DetectionNotifier extends AsyncNotifier<DetectionState> {
  @override
  Future<DetectionState> build() async => const DetectionState();

  DetectionRepository get _repo => ref.read(detectionRepositoryProvider);

  /// Lance le flux complet d'analyse en 4 phases
  Future<void> lancerAnalyse({
    required File imageFile,
    String? champId,
  }) async {
    // Phase 1 : Prétraitement
    state = AsyncData(state.value!.copyWith(
      step: DetectionStep.preprocessing,
      imageFile: imageFile,
      progression: 0.0,
      messageEtape: 'Prétraitement de l\'image...',
      erreur: null,
    ));
    await Future.delayed(const Duration(milliseconds: 1500));

    // Phase 2 : Extraction des caractéristiques
    state = AsyncData(state.value!.copyWith(
      step: DetectionStep.extraction,
      progression: 0.27,
      messageEtape: 'Extraction des caractéristiques visuelles...',
    ));
    await Future.delayed(const Duration(milliseconds: 1800));

    // Phase 3 : Appel API + analyse IA
    state = AsyncData(state.value!.copyWith(
      step: DetectionStep.analyse,
      progression: 0.55,
      messageEtape: 'Consultation du modèle IA...',
    ));

    try {
      final diagnostic = await _repo.analyserImage(
        imageFile: imageFile,
        champId: champId,
      );

      // Phase 4 : Finalisation
      state = AsyncData(state.value!.copyWith(
        step: DetectionStep.finalisation,
        progression: 0.88,
        messageEtape: 'Diagnostic prêt !',
      ));
      await Future.delayed(const Duration(milliseconds: 1000));

      state = AsyncData(state.value!.copyWith(
        step: DetectionStep.done,
        progression: 1.0,
        resultat: diagnostic,
      ));
    } catch (e) {
      state = AsyncData(state.value!.copyWith(
        step: DetectionStep.error,
        erreur: 'Erreur lors de l\'analyse : ${e.toString()}',
      ));
    }
  }

  /// Soumet l'évaluation de l'utilisateur sur un diagnostic
  Future<void> soumettreEvaluation({
    required String diagnosticId,
    required String choix,
    String? commentaire,
  }) async {
    await _repo.soumettreEvaluation(
      diagnosticId: diagnosticId,
      choix: choix,
      commentaire: commentaire,
    );
  }

  /// Réinitialise l'état pour un nouveau diagnostic
  void reinitialiser() {
    state = const AsyncData(DetectionState());
  }
}

final detectionProvider =
    AsyncNotifierProvider<DetectionNotifier, DetectionState>(
  DetectionNotifier.new,
);
