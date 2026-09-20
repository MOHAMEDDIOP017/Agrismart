import '../entities/intervention_entity.dart';
import '../entities/conseil_entity.dart';
import '../entities/champ_supervise_entity.dart';
import '../entities/expert_entity.dart';
import '../entities/recommandation_expert_entity.dart';
import '../enums/type_intervention.dart';
import '../enums/type_conseil.dart';

/// Interface du repository Expert
abstract class ExpertRepository {
  // ── Profil ───────────────────────────────────────────────────────
  Future<ExpertEntity> getProfilExpert(String expertId);
  Future<ExpertEntity> updateProfilExpert(ExpertEntity expert);

  // ── Supervision champs ───────────────────────────────────────────
  Future<List<ChampSuperviseEntity>> getChampsSupervises(String expertId);
  Future<ChampSuperviseEntity> getChampDetail(String champId);

  // ── Interventions ────────────────────────────────────────────────
  Future<List<InterventionEntity>> getInterventions(String expertId);
  Future<InterventionEntity> planifierIntervention({
    required String expertId,
    required String champId,
    required TypeIntervention type,
    required DateTime date,
    required String description,
    String? heure,
    double dureeHeures = 1.0,
    List<String> materiel = const [],
    bool notifierAgriculteur = true,
  });

  // ── Conseils ─────────────────────────────────────────────────────
  Future<List<ConseilEntity>> getConseils(String expertId);
  Future<ConseilEntity> envoyerConseil({
    required String expertId,
    required String agriculteurId,
    required String champId,
    required TypeConseil type,
    required String titre,
    required String corps,
    bool estUrgent = false,
    String? imageUrl,
  });

  // ── Recommandations cultures (boucle de validation expert) ───────
  Future<List<RecommandationExpertEntity>> getRecommandationsEnAttente(
      String expertId);

  Future<RecommandationExpertEntity> validerRecommandation({
    required String recoId,
    required String expertId,
    String? commentaire,
    bool notifierAgriculteur = true,
  });

  Future<RecommandationExpertEntity> corrigerOuRejeterRecommandation({
    required String recoId,
    required String expertId,
    required String decision, // 'CORRIGEE' ou 'REJETEE'
    required String commentaire,
    String? cultureCorrigee,
    bool notifierAgriculteur = true,
  });
}
