import '../entities/historique_activite_entity.dart';

abstract class HistoriqueActiviteRepository {
  Future<List<HistoriqueActiviteEntity>> getHistoriqueUtilisateur(
      String userId);
  Future<List<HistoriqueActiviteEntity>> getHistoriqueParType(
      String userId, String typeAction);
}
