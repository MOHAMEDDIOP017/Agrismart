import '../entities/culture_en_champ_entity.dart';
import '../../../../core/enums/statut_culture.dart';

abstract class CultureEnChampRepository {
  Future<List<CultureEnChampEntity>> getCulturesEnChamp(String champId);
  Future<CultureEnChampEntity> getCultureEnChampById(String id);
  Future<CultureEnChampEntity> createCultureEnChamp(CultureEnChampEntity item);
  Future<CultureEnChampEntity> updateStatut(
    String id,
    StatutCulture statut, {
    double? rendementReel,
  });
  Future<void> deleteCultureEnChamp(String id);
}
