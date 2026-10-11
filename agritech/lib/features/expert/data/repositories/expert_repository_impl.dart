import 'package:dio/dio.dart';
import '../../domain/entities/intervention_entity.dart';
import '../../domain/entities/conseil_entity.dart';
import '../../domain/entities/champ_supervise_entity.dart';
import '../../domain/entities/expert_entity.dart';
import '../../domain/entities/recommandation_expert_entity.dart';
import '../../domain/enums/statut_intervention.dart';
import '../../domain/enums/type_conseil.dart';
import '../../domain/enums/type_intervention.dart';
import '../../domain/enums/specialite_expert.dart';
import '../../domain/repositories/expert_repository.dart';
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

  // ── Champs supervisés ────────────────────────────────────────────────────

  @override
  Future<List<ChampSuperviseEntity>> getChampsSupervises(
      String expertId) async {
    // Récupère les interventions de l'expert, extrait les champIds uniques
    try {
      final resp = await _dio.get('/interventions/expert/$expertId');
      final data = resp.data as Map<String, dynamic>;
      final interventions =
          (data['interventions'] as List? ?? []).cast<Map<String, dynamic>>();

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
      agriculteurId = (champResp.data['agriculteurId'] ?? '') as String;
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

  // ── Mappers ───────────────────────────────────────────────────────────────

  static ExpertEntity _mapExpert(Map<String, dynamic> json) => ExpertEntity(
        id: (json['id'] ?? json['uid'] ?? '') as String,
        nom: (json['nom'] ?? '') as String,
        prenom: (json['prenom'] ?? '') as String,
        email: (json['email'] ?? '') as String,
        telephone: (json['telephone'] ?? '') as String,
        regionCouverture: (json['zone_geographique'] ?? 'Sénégal') as String,
        specialite: SpecialiteExpert.fromString(
            json['specialite'] as String? ?? 'GENERALISTE'),
        anneesExperience: json['anneesExperience'] as int? ?? 0,
        photoUrl: json['photo_url'] as String?,
      );

  static ChampSuperviseEntity _mapChamp(Map<String, dynamic> json) =>
      ChampSuperviseEntity(
        id: (json['id'] ?? '') as String,
        nom: (json['nom'] ?? '') as String,
        agriculteurId: (json['agriculteurId'] ?? '') as String,
        agriculteurNom: (json['agriculteurNom'] ?? 'Agriculteur') as String,
        agriculteurTelephone: (json['agriculteurTelephone'] ?? '') as String,
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
    final statutStr = (json['statut'] ?? 'PLANIFIEE').toString().toUpperCase();
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
      dateCreation: DateTime.tryParse(json['dateCreation']?.toString() ?? ''),
    );
  }

  static ConseilEntity _mapConseil(Map<String, dynamic> json) {
    final typeStr = (json['typeConseil'] ?? 'AUTRE').toString().toUpperCase();
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
      dateCreation: DateTime.tryParse(json['dateEnvoi']?.toString() ?? '') ??
          DateTime.now(),
      estUrgent: json['urgent'] as bool? ?? false,
      dateLecture: json['dateLecture'] != null
          ? DateTime.tryParse(json['dateLecture'].toString())
          : null,
    );
  }

  // ── Recommandations cultures ───────────────────────────────────────────────

  // NB : `expertId` n'est plus envoyé au backend — le validateur est déduit
  // du token Firebase (Depends(get_utilisateur_courant)) côté serveur. Le
  // paramètre est conservé dans la signature (appelant inchangé) mais ignoré
  // pour la requête HTTP elle-même, uniquement utilisé dans les fallbacks
  // locaux ci-dessous.
  @override
  Future<List<RecommandationExpertEntity>> getRecommandationsEnAttente(
      String expertId) async {
    try {
      final resp = await _dio.get('/recommandations/v2/en-attente');
      final data = resp.data as Map<String, dynamic>;
      return (data['recommandations'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(_mapRecommandationExpert)
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<RecommandationExpertEntity> validerRecommandation({
    required String recoId,
    required String expertId,
    String? commentaire,
    bool notifierAgriculteur = true,
  }) async {
    try {
      final resp = await _dio.post(
        '/recommandations/v2/analyses/$recoId/valider',
        data: {
          'commentaire': commentaire ?? 'Recommandation validée par l\'expert.',
        },
      );
      return _mapRecommandationExpert(resp.data as Map<String, dynamic>);
    } on DioException {
      // Fallback : retourne une entité avec le statut mis à jour localement
      return RecommandationExpertEntity(
        id: recoId,
        champId: '',
        champNom: '',
        champRegion: '',
        agriculteurId: '',
        agriculteurNom: '',
        agriculteurTelephone: '',
        top3Cultures: const [],
        snapshot: const SnapshotAgronomique(),
        statutValidation: 'VALIDEE',
        dateGeneree: DateTime.now(),
        expertId: expertId,
        commentaireExpert: commentaire,
        dateValidation: DateTime.now(),
      );
    }
  }

  @override
  Future<RecommandationExpertEntity> corrigerOuRejeterRecommandation({
    required String recoId,
    required String expertId,
    required String decision,
    required String commentaire,
    String? cultureCorrigee,
    bool notifierAgriculteur = true,
  }) async {
    final endpoint = decision == 'CORRIGEE'
        ? '/recommandations/v2/analyses/$recoId/corriger'
        : '/recommandations/v2/analyses/$recoId/rejeter';

    try {
      final resp = await _dio.post(endpoint, data: {
        if (decision == 'CORRIGEE') 'commentaire': commentaire,
        if (decision == 'CORRIGEE' && cultureCorrigee != null)
          'cultureCorrigeeNom': cultureCorrigee,
        if (decision != 'CORRIGEE') 'motif': commentaire,
      });
      return _mapRecommandationExpert(resp.data as Map<String, dynamic>);
    } on DioException {
      return RecommandationExpertEntity(
        id: recoId,
        champId: '',
        champNom: '',
        champRegion: '',
        agriculteurId: '',
        agriculteurNom: '',
        agriculteurTelephone: '',
        top3Cultures: const [],
        snapshot: const SnapshotAgronomique(),
        statutValidation: decision,
        dateGeneree: DateTime.now(),
        expertId: expertId,
        commentaireExpert: commentaire,
        cultureCorrigee: cultureCorrigee,
        dateValidation: DateTime.now(),
      );
    }
  }

  static RecommandationExpertEntity _mapRecommandationExpert(
      Map<String, dynamic> json) {
    final cultures =
        (json['top_cultures'] ?? json['predictions'] as List?) ?? [];
    final top3 = (cultures as List)
        .cast<Map<String, dynamic>>()
        .asMap()
        .entries
        .take(3)
        .map((e) => CultureScoreEntity(
              nom: (e.value['cultureNom'] ?? e.value['culture'] ?? '—')
                  .toString(),
              score: ((e.value['score'] ?? 0.0) as num).toDouble(),
              rang: e.key + 1,
              rendementEstime: (e.value['rendementEstime'] as num?)?.toDouble(),
              periodeIdealePlantation: e.value['periodePlantation'] as String?,
            ))
        .toList();

    final snap = (json['snapshot'] ?? json['donnees_entree'] as Map?) ?? {};
    final snapshot = SnapshotAgronomique(
      azote: (snap['azote'] ?? snap['N'] as num?)?.toDouble(),
      phosphore: (snap['phosphore'] ?? snap['P'] as num?)?.toDouble(),
      potassium: (snap['potassium'] ?? snap['K'] as num?)?.toDouble(),
      ph: (snap['ph'] ?? snap['pH'] as num?)?.toDouble(),
      humidite: (snap['humidite'] as num?)?.toDouble(),
      temperature: (snap['temperature'] as num?)?.toDouble(),
      pluviometrie: (snap['pluviometrie'] as num?)?.toDouble(),
      typeSol: snap['typeSol'] as String?,
    );

    return RecommandationExpertEntity(
      id: (json['id'] ?? '') as String,
      champId: (json['champId'] ?? '') as String,
      champNom: (json['champNom'] ?? 'Champ') as String,
      champRegion:
          (json['region'] ?? json['champRegion'] ?? 'Sénégal') as String,
      agriculteurId: (json['agriculteurId'] ?? '') as String,
      agriculteurNom: (json['agriculteurNom'] ?? 'Agriculteur') as String,
      agriculteurTelephone: (json['agriculteurTelephone'] ?? '') as String,
      top3Cultures: top3,
      snapshot: snapshot,
      statutValidation:
          (json['statutValidation'] ?? json['statut'] ?? 'EN_ATTENTE')
              .toString()
              .toUpperCase(),
      dateGeneree: DateTime.tryParse(json['dateGeneree']?.toString() ?? '') ??
          DateTime.now(),
      expertId: json['expertId'] as String?,
      commentaireExpert: json['commentaireExpert'] as String?,
      cultureCorrigee: json['cultureCorrigee'] as String?,
      dateValidation:
          DateTime.tryParse(json['dateValidation']?.toString() ?? ''),
      modeleIAVersion: json['modeleIAVersion'] as String?,
    );
  }
}
