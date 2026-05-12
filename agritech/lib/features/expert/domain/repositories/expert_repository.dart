import '../entities/diagnostic_expert_entity.dart';
import '../entities/intervention_entity.dart';
import '../entities/conseil_entity.dart';
import '../entities/alerte_zone_entity.dart';
import '../entities/champ_supervise_entity.dart';
import '../entities/expert_entity.dart';
import '../enums/decision_expert.dart';
import '../../../detection/domain/enums/type_traitement.dart';
import '../enums/type_intervention.dart';
import '../enums/type_conseil.dart';
import '../../../detection/domain/enums/niveau_gravite.dart';

/// Interface du repository Expert
abstract class ExpertRepository {
  // ── Profil ───────────────────────────────────────────────────────
  Future<ExpertEntity> getProfilExpert(String expertId);
  Future<ExpertEntity> updateProfilExpert(ExpertEntity expert);

  // ── Diagnostics ──────────────────────────────────────────────────
  Future<List<DiagnosticExpertEntity>> getDiagnosticsEnAttente(String expertId);
  Future<DiagnosticExpertEntity> getDiagnosticDetail(String diagnosticId);

  Future<DiagnosticExpertEntity> validerDiagnostic({
    required String diagnosticId,
    required String expertId,
    String? commentaire,
    bool notifierAgriculteur = true,
  });

  Future<DiagnosticExpertEntity> corrigerDiagnostic({
    required String diagnosticId,
    required String expertId,
    required DecisionExpert decision,
    required String maladieCorrIgeeId,
    required NiveauGravite niveauGravite,
    required String traitementRecommande,
    String? dosage,
    String? frequence,
    int? dureeJours,
    int? coutFCFA,
    TypeTraitement? typeTraitement,
    String? observations,
    bool notifierAgriculteur = true,
  });

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

  // ── Alertes zone ─────────────────────────────────────────────────
  Future<List<AlerteZoneEntity>> getAlertesZone(String expertId);
  Future<AlerteZoneEntity> prendreEnChargeAlerte({
    required String alerteId,
    required String expertId,
  });
}
