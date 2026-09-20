import 'package:dio/dio.dart';
import '../../domain/entities/culture_entity.dart';
import '../../domain/repositories/culture_repository.dart';
import '../models/culture_model.dart';
import '../../../../core/network/api_endpoints.dart';

class CultureRepositoryImpl implements CultureRepository {
  const CultureRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<CultureEntity>> getCultures() async {
    final response = await _dio.get(ApiEndpoints.cultures);
    final data = response.data;
    final list = (data is Map
            ? (data['cultures'] ?? data['items'] ?? data['data'])
            : data) as List? ??
        [];
    return list
        .map((e) => CultureModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CultureEntity> getCultureById(String id) async {
    final response = await _dio.get(ApiEndpoints.cultureById(id));
    return CultureModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CultureEntity> createCulture(CultureEntity culture) async {
    final response = await _dio.post(
      ApiEndpoints.cultures,
      data: _toCreateJson(culture),
    );
    return CultureModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CultureEntity> updateCulture(CultureEntity culture) async {
    final response = await _dio.put(
      ApiEndpoints.cultureById(culture.id),
      data: _toCreateJson(culture),
    );
    return CultureModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteCulture(String id) async {
    await _dio.delete(ApiEndpoints.cultureById(id));
  }

  Map<String, dynamic> _toCreateJson(CultureEntity c) => {
        'nom': c.nom,
        'variete': c.variete,
        'cycle_maturation': c.cycleMaturation,
        'besoins_hydriques': c.besoinsHydriques,
        'rendement_moyen': c.rendementMoyen,
        'ph_optimal': c.phOptimal,
        'n_optimal': c.nOptimal,
        'p_optimal': c.pOptimal,
        'k_optimal': c.kOptimal,
        'temp_min': c.tempMin,
        'temp_max': c.tempMax,
        'humidite_min': c.humiditeMin,
        'humidite_max': c.humiditeMax,
        'pluvio_min': c.pluvioMin,
        'pluvio_max': c.pluvioMax,
        'prix_moyen_marche': c.prixMoyenMarche,
      };
}
