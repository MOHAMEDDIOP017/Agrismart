import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/champ_entity.dart';
import '../../domain/repositories/champ_repository.dart';
import '../models/champ_model.dart';

class ChampRepositoryImpl implements ChampRepository {
  ChampRepositoryImpl(this._dio, this._userId);

  final Dio _dio;
  final String _userId;

  @override
  Future<List<ChampEntity>> getChamps() async {
    final response = await _dio.get(ApiEndpoints.champsAgriculteur(_userId));
    final data = response.data as Map<String, dynamic>;
    final list = data['champs'] as List? ?? [];
    return list
        .map((e) => ChampModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ChampEntity> getChampById(String id) async {
    final response = await _dio.get(ApiEndpoints.champById(id));
    return ChampModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ChampEntity> createChamp(ChampEntity champ) async {
    final model = champ as ChampModel;
    final response = await _dio.post(
      ApiEndpoints.champs,
      data: model.toCreateJson(),
    );
    return ChampModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ChampEntity> updateChamp(ChampEntity champ) async {
    final model = champ as ChampModel;
    final response = await _dio.put(
      ApiEndpoints.champById(champ.id),
      data: model.toCreateJson(),
    );
    return ChampModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteChamp(String id) async {
    await _dio.delete(ApiEndpoints.champById(id));
  }
}
