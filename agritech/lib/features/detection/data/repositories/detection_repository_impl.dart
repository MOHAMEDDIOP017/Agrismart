import 'dart:io';
import '../../domain/entities/diagnostic_entity.dart';
import '../../domain/repositories/detection_repository.dart';
import '../services/detection_api_service.dart';
import '../services/image_preprocessing_service.dart';

/// Implémentation du repository de détection (mode mock)
class DetectionRepositoryImpl implements DetectionRepository {
  DetectionRepositoryImpl({
    required DetectionApiService apiService,
    required ImagePreprocessingService preprocessingService,
  })  : _apiService = apiService,
        _preprocessingService = preprocessingService;

  final DetectionApiService _apiService;
  final ImagePreprocessingService _preprocessingService;
  final List<DiagnosticEntity> _historique = [];

  @override
  Future<DiagnosticEntity> analyserImage({
    required File imageFile,
    String? champId,
  }) async {
    final processedImage = await _preprocessingService.preprocessImage(imageFile);
    final response = await _apiService.analyserImage(
      imageFile: processedImage,
      champId: champId,
    );
    final diagnostic = response.toEntity(imageLocalPath: imageFile.path);
    _historique.insert(0, diagnostic);
    return diagnostic;
  }

  @override
  Future<List<DiagnosticEntity>> getHistoriqueDiagnostics() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.from(_historique);
  }

  @override
  Future<DiagnosticEntity?> getDiagnosticById(String id) async {
    try {
      return _historique.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> soumettreEvaluation({
    required String diagnosticId,
    required String choix,
    String? commentaire,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // En production : POST /api/v1/diagnostics/:id/evaluation
  }

  @override
  Future<void> archiverDiagnostic(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _historique.removeWhere((d) => d.id == id);
  }

  @override
  Future<void> supprimerDiagnostic(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _historique.removeWhere((d) => d.id == id);
  }
}
