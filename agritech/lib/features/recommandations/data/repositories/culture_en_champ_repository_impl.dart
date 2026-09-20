import 'package:dio/dio.dart';
import '../../domain/entities/culture_en_champ_entity.dart';
import '../../domain/repositories/culture_en_champ_repository.dart';
import '../models/culture_en_champ_model.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/enums/statut_culture.dart';

class CultureEnChampRepositoryImpl implements CultureEnChampRepository {
  const CultureEnChampRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<CultureEnChampEntity>> getCulturesEnChamp(
      String champId) async {
    final response = await _dio.get(ApiEndpoints.culturesEnChamp(champId));
    final data = response.data;
    final list = (data is Map
            ? (data['cultures'] ?? data['items'] ?? data['data'])
            : data) as List? ??
        [];
    return list
        .map((e) => CultureEnChampModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CultureEnChampEntity> getCultureEnChampById(String id) async {
    final response =
        await _dio.get('${ApiEndpoints.culturesEnChampBase}/$id');
    return CultureEnChampModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  @override
  Future<CultureEnChampEntity> createCultureEnChamp(
      CultureEnChampEntity item) async {
    final response = await _dio.post(
      ApiEndpoints.creerCultureEnChamp,
      data: {
        'champ_id': item.champId,
        'culture_id': item.cultureId,
        'date_debut': item.dateDebut.toIso8601String(),
        'date_fin_prevue': item.dateFinPrevue.toIso8601String(),
        'statut': item.statut.toJson(),
      },
    );
    return CultureEnChampModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  @override
  Future<CultureEnChampEntity> updateStatut(
    String id,
    StatutCulture statut, {
    double? rendementReel,
  }) async {
    final response = await _dio.put(
      ApiEndpoints.statutCultureEnChamp(id),
      data: {
        'statut': statut.toJson(),
        if (rendementReel != null) 'rendement_reel': rendementReel,
      },
    );
    return CultureEnChampModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteCultureEnChamp(String id) async {
    await _dio.delete('${ApiEndpoints.culturesEnChampBase}/$id');
  }
}
