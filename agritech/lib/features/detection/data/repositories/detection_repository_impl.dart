import 'dart:io';
import '../../domain/entities/diagnostic_entity.dart';
import '../../domain/repositories/detection_repository.dart';
import '../services/detection_api_service.dart';
import '../services/image_preprocessing_service.dart';

class DetectionRepositoryImpl implements DetectionRepository {
  DetectionRepositoryImpl({
    required DetectionApiService apiService,
    required ImagePreprocessingService preprocessingService,
    String? userId,
  })  : _apiService = apiService,
        _preprocessingService = preprocessingService,
        _userId = userId;

  final DetectionApiService _apiService;
  final ImagePreprocessingService _preprocessingService;
  final String? _userId;
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
    if (_userId != null) {
      try {
        return await _apiService.getHistorique(_userId);
      } catch (_) {
        return List.from(_historique);
      }
    }
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
    try {
      await _apiService.evaluerDiagnostic(
        diagnosticId: diagnosticId,
        choix: choix,
        commentaire: commentaire,
      );
    } catch (_) {
      // Évaluation non bloquante
    }
  }

  @override
  Future<void> archiverDiagnostic(String id) async {
    _historique.removeWhere((d) => d.id == id);
  }

  @override
  Future<void> supprimerDiagnostic(String id) async {
    _historique.removeWhere((d) => d.id == id);
  }
}
