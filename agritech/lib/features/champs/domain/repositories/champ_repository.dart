import '../entities/champ_entity.dart';

/// Contrat du repository des champs agricoles
abstract class ChampRepository {
  Future<List<ChampEntity>> getChamps();
  Future<ChampEntity> getChampById(String id);
  Future<ChampEntity> createChamp(ChampEntity champ);
  Future<ChampEntity> updateChamp(ChampEntity champ);
  Future<void> deleteChamp(String id);
}
