import 'package:dio/dio.dart';
import '../../domain/entities/historique_activite_entity.dart';
import '../../domain/repositories/historique_activite_repository.dart';
import '../models/historique_activite_model.dart';
import '../../../../core/network/api_endpoints.dart';

class HistoriqueActiviteRepositoryImpl
    implements HistoriqueActiviteRepository {
  const HistoriqueActiviteRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<HistoriqueActiviteEntity>> getHistoriqueUtilisateur(
      String userId) async {
    final response =
        await _dio.get(ApiEndpoints.historiqueUtilisateur(userId));
    final data = response.data;
    final list = (data is Map
            ? (data['historique'] ?? data['items'] ?? data['data'])
            : data) as List? ??
        [];
    return list
        .map((e) =>
            HistoriqueActiviteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<HistoriqueActiviteEntity>> getHistoriqueParType(
      String userId, String typeAction) async {
    final response = await _dio.get(
      ApiEndpoints.historiqueUtilisateur(userId),
      queryParameters: {'type_action': typeAction},
    );
    final data = response.data;
    final list = (data is Map
            ? (data['historique'] ?? data['items'] ?? data['data'])
            : data) as List? ??
        [];
    return list
        .map((e) =>
            HistoriqueActiviteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
