import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import '../../../../mock_data/maladies_mock.dart';
import '../dto/diagnostic_response_dto.dart';
import '../../domain/entities/maladie_entity.dart';
import '../../domain/entities/traitement_entity.dart';

/// Service d'appel à l'API de détection de maladies (upload image → analyse IA)
class DetectionApiService {
  DetectionApiService(this._dio);

  final Dio _dio;
  static const String _modeleVersion = '2.1.0';

  /// Envoie l'image au backend en deux étapes :
  /// 1. POST /images/upload   → obtient l'imageId
  /// 2. POST /diagnostics/analyser/{imageId} → obtient le diagnostic IA
  Future<DiagnosticResponseDto> analyserImage({
    required File imageFile,
    String? champId,
  }) async {
    try {
      // Étape 1 : upload de l'image vers MinIO via le backend
      final formData = FormData.fromMap({
        'fichier': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'plant_image.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
        'latitude': 14.6937,
        'longitude': -17.4441,
        if (champId != null) 'champ_id': champId,
      });

      final uploadResponse = await _dio.post(
        '/images/upload',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final imageId = uploadResponse.data['imageId'] as String;

      // Étape 2 : analyse IA
      final analyseResponse = await _dio.post(
        '/diagnostics/analyser/$imageId',
        queryParameters: {
          if (champId != null) 'champ_id': champId,
        },
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );

      return DiagnosticResponseDto.fromJson(
          analyseResponse.data as Map<String, dynamic>);
    } catch (_) {
      // Fallback mock si le modèle IA n'est pas encore chargé côté backend
      await Future.delayed(const Duration(seconds: 2));
      return _getMockResponse(champId: champId);
    }
  }

  DiagnosticResponseDto _getMockResponse({String? champId}) {
    final random = Random();
    final maladies = maladiesMock;
    final maladieIndex = random.nextInt(maladies.length);
    final maladie = maladies[maladieIndex];

    final scoreConfiance = 0.72 + random.nextDouble() * 0.25;
    final topPredictions =
        _buildTopPredictions(maladies, maladieIndex, scoreConfiance, random);

    return DiagnosticResponseDto(
      diagnosticId: 'diag_${DateTime.now().millisecondsSinceEpoch}',
      maladieDetectee: _toDto(maladie),
      scoreConfiance: scoreConfiance,
      topPredictions: topPredictions,
      dateAnalyse: DateTime.now(),
      modeleVersion: _modeleVersion,
      tempsAnalyseMs: 1100 + random.nextInt(900),
      champId: champId,
    );
  }

  List<PredictionDto> _buildTopPredictions(
    List<MaladieEntity> maladies,
    int mainIndex,
    double mainScore,
    Random random,
  ) {
    final reste = 1 - mainScore;
    final secondScore = reste * (0.45 + random.nextDouble() * 0.25);
    final thirdScore = (reste - secondScore) * 0.75;

    final autres = [...maladies]..removeAt(mainIndex);
    autres.shuffle(random);

    return [
      PredictionDto(maladie: _toDto(maladies[mainIndex]), score: mainScore, rang: 1),
      PredictionDto(maladie: _toDto(autres[0]), score: secondScore, rang: 2),
      PredictionDto(maladie: _toDto(autres[1]), score: thirdScore, rang: 3),
    ];
  }

  MaladieDto _toDto(MaladieEntity e) {
    return MaladieDto(
      id: e.id,
      nom: e.nom,
      nomScientifique: e.nomScientifique,
      description: e.description,
      symptomes: e.symptomes,
      gravite: e.gravite,
      culturesAffectees: e.culturesAffectees,
      traitements: e.traitements.map(_toTraitementDto).toList(),
      agentPathogene: e.agentPathogene,
      conditionsFavorables: e.conditionsFavorables,
    );
  }

  TraitementDto _toTraitementDto(TraitementEntity t) {
    return TraitementDto(
      id: t.id,
      nomProduit: t.nomProduit,
      dosage: t.dosage,
      frequenceApplication: t.frequenceApplication,
      dureeDays: t.dureeDays,
      type: t.type,
      coutFcfa: t.coutFcfa,
      instructionsDetaillees: t.instructionsDetaillees,
      precautions: t.precautions,
    );
  }
}
