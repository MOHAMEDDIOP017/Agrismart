import 'package:dio/dio.dart';
import '../../domain/entities/diagnostic_expert_entity.dart';
import '../../domain/entities/intervention_entity.dart';
import '../../domain/entities/conseil_entity.dart';
import '../../domain/entities/alerte_zone_entity.dart';
import '../../domain/entities/champ_supervise_entity.dart';
import '../../domain/entities/expert_entity.dart';
import '../../domain/enums/decision_expert.dart';
import '../../domain/enums/statut_intervention.dart';
import '../../domain/enums/type_conseil.dart';
import '../../domain/enums/type_intervention.dart';
import '../../domain/enums/specialite_expert.dart';
import '../../domain/repositories/expert_repository.dart';
import '../../../detection/domain/entities/maladie_entity.dart';
import '../../../detection/domain/entities/prediction_entity.dart';
import '../../../detection/domain/enums/niveau_gravite.dart';
import '../../../detection/domain/enums/statut_validation.dart';
import '../../../detection/domain/enums/type_traitement.dart';
import '../../../../core/network/api_client.dart';

class ExpertRepositoryImpl implements ExpertRepository {
  final Dio _dio = ApiClient().dio;

  // ── Profil Expert ─────────────────────────────────────────────────────────

  @override
  Future<ExpertEntity> getProfilExpert(String expertId) async {
    final resp = await _dio.get('/utilisateurs/$expertId');
    return _mapExpert(resp.data as Map<String, dynamic>);
  }

  @override
  Future<ExpertEntity> updateProfilExpert(ExpertEntity expert) async {
    await _dio.put('/utilisateurs/${expert.id}', data: {
      'nom': expert.nom,
      'prenom': expert.prenom,
      'telephone': expert.telephone,
      'zone_geographique': expert.regionCouverture,
      'specialite': expert.specialite.libelle.toUpperCase(),
      'anneesExperience': expert.anneesExperience,
    });
    return expert;
  }

  // ── Diagnostics ───────────────────────────────────────────────────────────

  @override
  Future<List<DiagnosticExpertEntity>> getDiagnosticsEnAttente(String expertId) async {
    final resp = await _dio.get('/diagnostics/en-attente?limite=30');
    final data = resp.data as Map<String, dynamic>;
    return (data['diagnostics'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(_mapDiagnostic)
        .toList();
  }

  @override
  Future<DiagnosticExpertEntity> getDiagnosticDetail(String diagnosticId) async {
    final resp = await _dio.get('/diagnostics/$diagnosticId');
    return _mapDiagnostic(resp.data as Map<String, dynamic>);
  }

  @override
  Future<DiagnosticExpertEntity> validerDiagnostic({
    required String diagnosticId,
    required String expertId,
    String? commentaire,
    bool notifierAgriculteur = true,
  }) async {
    await _dio.post('/diagnostics/$diagnosticId/valider', data: {
      'maladieId': null,
      'commentaireExpert': commentaire ?? 'Diagnostic validé.',
    });
    final diag = await getDiagnosticDetail(diagnosticId);
    // Retourne le diagnostic mis à jour avec le statut validé
    return DiagnosticExpertEntity(
      id: diag.id,
      agriculteurId: diag.agriculteurId,
      agriculteurNom: diag.agriculteurNom,
      agriculteurTelephone: diag.agriculteurTelephone,
      agriculteurVillage: diag.agriculteurVillage,
      champId: diag.champId,
      champNom: diag.champNom,
      champSuperficie: diag.champSuperficie,
      maladieIA: diag.maladieIA,
      scoreConfiance: diag.scoreConfiance,
      topPredictions: diag.topPredictions,
      niveauGraviteIA: diag.niveauGraviteIA,
      dateSoumission: diag.dateSoumission,
      statut: StatutValidation.valideExpert,
      imageUrl: diag.imageUrl,
      expertId: expertId,
      decisionExpert: DecisionExpert.correct,
      commentaireValidation: commentaire,
      notifierAgriculteur: notifierAgriculteur,
      dateValidation: DateTime.now(),
    );
  }

  @override
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
  }) async {
    await _dio.post('/diagnostics/$diagnosticId/corriger', data: {
      'maladieIdCorrecte': maladieCorrIgeeId,
      'commentaireExpert': observations ?? traitementRecommande,
    });
    final diag = await getDiagnosticDetail(diagnosticId);
    return DiagnosticExpertEntity(
      id: diag.id,
      agriculteurId: diag.agriculteurId,
      agriculteurNom: diag.agriculteurNom,
      agriculteurTelephone: diag.agriculteurTelephone,
      agriculteurVillage: diag.agriculteurVillage,
      champId: diag.champId,
      champNom: diag.champNom,
      champSuperficie: diag.champSuperficie,
      maladieIA: diag.maladieIA,
      scoreConfiance: diag.scoreConfiance,
      topPredictions: diag.topPredictions,
      niveauGraviteIA: diag.niveauGraviteIA,
      dateSoumission: diag.dateSoumission,
      statut: StatutValidation.valideExpert,
      imageUrl: diag.imageUrl,
      expertId: expertId,
      decisionExpert: decision,
      niveauGraviteCorrige: niveauGravite,
      traitementRecommande: traitementRecommande,
      dosageTraitement: dosage,
      frequenceApplication: frequence,
      dureeTraitement: dureeJours,
      coutEstimeFCFA: coutFCFA,
      typeTraitement: typeTraitement,
      observationsExpert: observations,
      notifierAgriculteur: notifierAgriculteur,
      dateValidation: DateTime.now(),
    );
  }

  // ── Champs supervisés ────────────────────────────────────────────────────

  @override
  Future<List<ChampSuperviseEntity>> getChampsSupervises(String expertId) async {
    // Récupère les interventions de l'expert, extrait les champIds uniques
    try {
      final resp = await _dio.get('/interventions/expert/$expertId');
      final data = resp.data as Map<String, dynamic>;
      final interventions = (data['interventions'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      final champIds = interventions
          .map((i) => i['champId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      final champs = <ChampSuperviseEntity>[];
      for (final champId in champIds) {
        try {
          final champResp = await _dio.get('/champs/$champId');
          champs.add(_mapChamp(champResp.data as Map<String, dynamic>));
        } catch (_) {}
      }
      return champs;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ChampSuperviseEntity> getChampDetail(String champId) async {
    final resp = await _dio.get('/champs/$champId');
    return _mapChamp(resp.data as Map<String, dynamic>);
  }

  // ── Interventions ─────────────────────────────────────────────────────────

  @override
  Future<List<InterventionEntity>> getInterventions(String expertId) async {
    final resp = await _dio.get('/interventions/expert/$expertId');
    final data = resp.data as Map<String, dynamic>;
    return (data['interventions'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(_mapIntervention)
        .toList();
  }

  @override
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
  }) async {
    // Récupère agriculteurId depuis le champ
    String agriculteurId = '';
    try {
      final champResp = await _dio.get('/champs/$champId');
      agriculteurId =
          (champResp.data['agriculteurId'] ?? '') as String;
    } catch (_) {}

    final resp = await _dio.post('/interventions', data: {
      'champId': champId,
      'expertId': expertId,
      'agriculteurId': agriculteurId,
      'typeIntervention': type.name.toUpperCase(),
      'description': description,
      'dateInterventionPrevue': date.toIso8601String(),
      'dureeEstimeeHeures': dureeHeures,
      'materielNecessaire': materiel,
      'statut': 'PLANIFIEE',
    });
    return _mapIntervention(resp.data as Map<String, dynamic>);
  }

  // ── Conseils ──────────────────────────────────────────────────────────────

  @override
  Future<List<ConseilEntity>> getConseils(String expertId) async {
    final resp = await _dio.get('/conseils/expert/$expertId');
    final data = resp.data as Map<String, dynamic>;
    return (data['conseils'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(_mapConseil)
        .toList();
  }

  @override
  Future<ConseilEntity> envoyerConseil({
    required String expertId,
    required String agriculteurId,
    required String champId,
    required TypeConseil type,
    required String titre,
    required String corps,
    bool estUrgent = false,
    String? imageUrl,
  }) async {
    final resp = await _dio.post('/conseils', data: {
      'expertId': expertId,
      'agriculteurId': agriculteurId,
      'champId': champId,
      'typeConseil': type.libelle.toUpperCase(),
      'titre': titre,
      'contenu': corps,
      'urgent': estUrgent,
      if (imageUrl != null) 'pieceJointeUrl': imageUrl,
    });
    return _mapConseil(resp.data as Map<String, dynamic>);
  }

  // ── Alertes zone ──────────────────────────────────────────────────────────

  @override
  Future<List<AlerteZoneEntity>> getAlertesZone(String expertId) async {
    // Les alertes zone = diagnostics EN_ATTENTE avec gravité ELEVE ou CRITIQUE
    final resp = await _dio.get('/diagnostics/en-attente?limite=50');
    final data = resp.data as Map<String, dynamic>;
    return (data['diagnostics'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .where((d) {
          final g = (d['niveauGravite'] ?? d['niveauGraviteIA'] ?? '').toString().toUpperCase();
          return g == 'ELEVE' || g == 'CRITIQUE';
        })
        .map(_mapAlerte)
        .toList();
  }

  @override
  Future<AlerteZoneEntity> prendreEnChargeAlerte({
    required String alerteId,
    required String expertId,
  }) async {
    // Valider le diagnostic = prendre en charge l'alerte
    await _dio.post('/diagnostics/$alerteId/valider', data: {
      'maladieId': null,
      'commentaireExpert': 'Prise en charge par l\'expert.',
    });
    final diag = await getDiagnosticDetail(alerteId);
    return AlerteZoneEntity(
      id: diag.id,
      agriculteurId: diag.agriculteurId,
      agriculteurNom: diag.agriculteurNom,
      champId: diag.champId,
      champNom: diag.champNom,
      maladie: diag.maladieIA.nom,
      niveauGravite: diag.niveauGraviteIA,
      statut: StatutAlerteZone.enCours,
      dateEmission: diag.dateSoumission,
      region: 'Sénégal',
      diagnosticId: diag.id,
      expertEnChargeId: expertId,
    );
  }

  // ── Mappers ───────────────────────────────────────────────────────────────

  static ExpertEntity _mapExpert(Map<String, dynamic> json) => ExpertEntity(
        id: (json['id'] ?? json['uid'] ?? '') as String,
        nom: (json['nom'] ?? '') as String,
        prenom: (json['prenom'] ?? '') as String,
        email: (json['email'] ?? '') as String,
        telephone: (json['telephone'] ?? '') as String,
        regionCouverture:
            (json['zone_geographique'] ?? 'Sénégal') as String,
        specialite: SpecialiteExpert.fromString(
            json['specialite'] as String? ?? 'GENERALISTE'),
        anneesExperience: json['anneesExperience'] as int? ?? 0,
        photoUrl: json['photo_url'] as String?,
      );

  static DiagnosticExpertEntity _mapDiagnostic(Map<String, dynamic> json) {
    final graviteStr =
        (json['niveauGravite'] ?? json['niveauGraviteIA'] ?? 'MODERE') as String;
    final maladie = _maladiePlaceholder(
      (json['maladieDetectee'] ?? 'Maladie inconnue') as String,
      graviteStr,
    );
    final top = json['topPredictions'] as List? ?? [];
    return DiagnosticExpertEntity(
      id: (json['id'] ?? '') as String,
      agriculteurId: (json['agriculteurId'] ?? '') as String,
      agriculteurNom: (json['agriculteurNom'] ?? 'Agriculteur') as String,
      agriculteurTelephone: (json['agriculteurTelephone'] ?? '') as String,
      agriculteurVillage: (json['agriculteurVillage'] ?? 'Sénégal') as String,
      champId: (json['champId'] ?? '') as String,
      champNom: (json['champNom'] ?? 'Champ') as String,
      champSuperficie: ((json['champSuperficie'] ?? 1.0) as num).toDouble(),
      maladieIA: maladie,
      scoreConfiance:
          ((json['scoreConfiance'] ?? 0.0) as num).toDouble(),
      topPredictions: _mapPredictions(top),
      niveauGraviteIA: NiveauGravite.fromString(graviteStr),
      dateSoumission:
          DateTime.tryParse(json['dateAnalyse']?.toString() ?? '') ??
              DateTime.now(),
      statut: StatutValidation.fromString(
          json['statut'] as String? ?? 'EN_ATTENTE'),
      imageUrl: json['imageUrl'] as String?,
      expertId: json['expertId'] as String?,
      commentaireValidation: json['commentaireExpert'] as String?,
    );
  }

  static MaladieEntity _maladiePlaceholder(String nom, String niveau) =>
      MaladieEntity(
        id: nom.toLowerCase().replaceAll(' ', '_'),
        nom: nom,
        nomScientifique: '',
        description: '',
        symptomes: const [],
        gravite: NiveauGravite.fromString(niveau),
        culturesAffectees: const [],
      );

  static List<PredictionEntity> _mapPredictions(List<dynamic> top) =>
      top.asMap().entries.map((e) {
        final pred = e.value as Map<String, dynamic>;
        final nom = (pred['maladie'] ?? pred['nom'] ?? 'Inconnu') as String;
        final score =
            ((pred['score'] ?? pred['scoreConfiance'] ?? 0.0) as num).toDouble();
        return PredictionEntity(
          maladie: _maladiePlaceholder(nom, 'MODERE'),
          score: score,
          rang: e.key + 1,
        );
      }).toList();

  static ChampSuperviseEntity _mapChamp(Map<String, dynamic> json) =>
      ChampSuperviseEntity(
        id: (json['id'] ?? '') as String,
        nom: (json['nom'] ?? '') as String,
        agriculteurId: (json['agriculteurId'] ?? '') as String,
        agriculteurNom: (json['agriculteurNom'] ?? 'Agriculteur') as String,
        agriculteurTelephone:
            (json['agriculteurTelephone'] ?? '') as String,
        superficie: ((json['superficie'] ?? 1.0) as num).toDouble(),
        typeSol: (json['typeSol'] ?? '') as String,
        statut: (json['statut'] ?? 'EN_COURS') as String,
        region: (json['adresse'] ?? 'Sénégal') as String,
        scoresSante: 75,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  static InterventionEntity _mapIntervention(Map<String, dynamic> json) {
    final typeStr =
        (json['typeIntervention'] ?? 'SUIVI').toString().toUpperCase();
    final type = switch (typeStr) {
      'DIAGNOSTIC' => TypeIntervention.diagnostic,
      'TRAITEMENT' => TypeIntervention.traitement,
      'CONSEIL' => TypeIntervention.conseil,
      _ => TypeIntervention.suivi,
    };
    final statutStr =
        (json['statut'] ?? 'PLANIFIEE').toString().toUpperCase();
    final statut = switch (statutStr) {
      'REALISEE' => StatutIntervention.realisee,
      'ANNULEE' => StatutIntervention.annulee,
      _ => StatutIntervention.planifiee,
    };
    return InterventionEntity(
      id: (json['id'] ?? '') as String,
      expertId: (json['expertId'] ?? '') as String,
      champId: (json['champId'] ?? '') as String,
      champNom: (json['champNom'] ?? 'Champ') as String,
      agriculteurNom: (json['agriculteurNom'] ?? 'Agriculteur') as String,
      typeIntervention: type,
      statut: statut,
      dateIntervention:
          DateTime.tryParse(json['dateInterventionPrevue']?.toString() ?? '') ??
              DateTime.now(),
      description: (json['description'] ?? '') as String,
      dureeEstimeeHeures:
          ((json['dureeEstimeeHeures'] ?? 1.0) as num).toDouble(),
      materielNecessaire:
          (json['materielNecessaire'] as List? ?? []).cast<String>(),
      notesRealisation: json['rapportIntervention'] as String?,
      dateCreation:
          DateTime.tryParse(json['dateCreation']?.toString() ?? ''),
    );
  }

  static ConseilEntity _mapConseil(Map<String, dynamic> json) {
    final typeStr =
        (json['typeConseil'] ?? 'AUTRE').toString().toUpperCase();
    final type = switch (typeStr) {
      'CULTURE' => TypeConseil.culture,
      'TRAITEMENT' => TypeConseil.traitement,
      'IRRIGATION' => TypeConseil.irrigation,
      'RECOLTE' => TypeConseil.recolte,
      _ => TypeConseil.autre,
    };
    final lu = json['lu'] as bool? ?? false;
    return ConseilEntity(
      id: (json['id'] ?? '') as String,
      expertId: (json['expertId'] ?? '') as String,
      agriculteurId: (json['agriculteurId'] ?? '') as String,
      agriculteurNom: (json['agriculteurNom'] ?? 'Agriculteur') as String,
      champId: (json['champId'] ?? '') as String,
      champNom: (json['champNom'] ?? 'Champ') as String,
      typeConseil: type,
      titre: (json['titre'] ?? '') as String,
      corps: (json['contenu'] ?? json['corps'] ?? '') as String,
      statut: lu ? StatutConseil.lu : StatutConseil.envoye,
      dateCreation:
          DateTime.tryParse(json['dateEnvoi']?.toString() ?? '') ?? DateTime.now(),
      estUrgent: json['urgent'] as bool? ?? false,
      dateLecture: json['dateLecture'] != null
          ? DateTime.tryParse(json['dateLecture'].toString())
          : null,
    );
  }

  static AlerteZoneEntity _mapAlerte(Map<String, dynamic> json) {
    final graviteStr =
        (json['niveauGravite'] ?? json['niveauGraviteIA'] ?? 'ELEVE') as String;
    return AlerteZoneEntity(
      id: (json['id'] ?? '') as String,
      agriculteurId: (json['agriculteurId'] ?? '') as String,
      agriculteurNom: (json['agriculteurNom'] ?? 'Agriculteur') as String,
      champId: (json['champId'] ?? '') as String,
      champNom: (json['champNom'] ?? 'Champ') as String,
      maladie: (json['maladieDetectee'] ?? 'Maladie inconnue') as String,
      niveauGravite: NiveauGravite.fromString(graviteStr),
      statut: StatutAlerteZone.nonTraitee,
      dateEmission:
          DateTime.tryParse(json['dateAnalyse']?.toString() ?? '') ??
              DateTime.now(),
      region: 'Sénégal',
      diagnosticId: json['id'] as String?,
      description: json['maladieDetectee'] as String?,
      expertEnChargeId: json['expertId'] as String?,
    );
  }
}
