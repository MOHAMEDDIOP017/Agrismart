import '../entities/culture_entity.dart';

abstract class CultureRepository {
  Future<List<CultureEntity>> getCultures();
  Future<CultureEntity> getCultureById(String id);
  Future<CultureEntity> createCulture(CultureEntity culture);
  Future<CultureEntity> updateCulture(CultureEntity culture);
  Future<void> deleteCulture(String id);
}
