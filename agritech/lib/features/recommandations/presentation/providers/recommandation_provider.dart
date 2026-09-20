import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../data/models/recommandation_model.dart';

class RecommandationState {
  const RecommandationState({
    this.recommandations = const [],
    this.isLoading = false,
    this.isAnalysing = false,
    this.champIdSelectionne,
    this.error,
    this.progressMessage,
  });

  final List<RecommandationModel> recommandations;
  final bool isLoading;
  final bool isAnalysing;
  final String? champIdSelectionne;
  final String? error;
  final String? progressMessage;

  RecommandationState copyWith({
    List<RecommandationModel>? recommandations,
    bool? isLoading,
    bool? isAnalysing,
    String? champIdSelectionne,
    String? error,
    String? progressMessage,
  }) =>
      RecommandationState(
        recommandations: recommandations ?? this.recommandations,
        isLoading: isLoading ?? this.isLoading,
        isAnalysing: isAnalysing ?? this.isAnalysing,
        champIdSelectionne: champIdSelectionne ?? this.champIdSelectionne,
        error: error,
        progressMessage: progressMessage,
      );
}

class RecommandationNotifier extends Notifier<RecommandationState> {
  @override
  RecommandationState build() => const RecommandationState();

  void selectChamp(String champId) {
    state = state.copyWith(champIdSelectionne: champId);
  }

  Future<void> analyserAvecIA(String champId) async {
    state = state.copyWith(
      isAnalysing: true,
      recommandations: [],
      champIdSelectionne: champId,
      progressMessage: 'Analyse des données du sol...',
      error: null,
    );

    try {
      await Future.delayed(const Duration(milliseconds: 800));
      state = state.copyWith(progressMessage: 'Consultation du modèle IA...');

      final dio = ref.read(dioProvider);
      // Moteur v2 (seul moteur actif) : classifieur multi-label (16 variables
      // sol/climat/NDVI dérivées de la position du champ, 8 cultures dont
      // Manioc, aptitude indépendante par culture). L'ancien moteur SVM et son
      // endpoint /recommandations/generer ont été retirés du backend.
      final response = await dio.post(
        ApiEndpoints.genererRecommandationsV2(champId),
      );

      state = state.copyWith(progressMessage: 'Génération des recommandations...');
      await Future.delayed(const Duration(milliseconds: 400));

      final data = response.data as Map<String, dynamic>;
      final topRecos = (data['topRecommandations'] as List)
          .asMap()
          .entries
          .map((e) => RecommandationModel.fromPredictionV2(
                e.value as Map<String, dynamic>,
                champId,
                e.key,
              ))
          .toList();

      state = RecommandationState(
        recommandations: topRecos,
        isAnalysing: false,
        champIdSelectionne: champId,
      );
    } catch (e) {
      state = RecommandationState(
        isAnalysing: false,
        champIdSelectionne: champId,
        error: 'Erreur lors de l\'analyse IA : ${e.toString()}',
      );
    }
  }

  Future<void> chargerHistorique(String champId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(dioProvider);
      // Historique du moteur v2 (RecommandationCulture, diagramme UML) — seul
      // moteur actif, l'ancien endpoint v1 a été retiré du backend.
      final response = await dio.get(
        ApiEndpoints.recommandationsChampV2(champId),
      );
      final data = response.data as Map<String, dynamic>;
      final list = data['recommandations'] as List? ?? [];

      final recos = list.asMap().entries.map((e) {
        final item = e.value as Map<String, dynamic>;
        final rendement = (item['rendementEstime'] as num? ?? 0).toDouble();
        final prix = (item['prixMarcheEstime'] as num?)?.toInt() ?? 200;
        final eau = (item['besoinEauMm'] as num?)?.toInt() ?? 400;
        final engrais = (item['engraisConseilles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [];
        final maladies = (item['maladiesFrequentes'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [];
        final score = ((item['probabiliteAptitude'] as num? ?? 0) * 100).round();
        return RecommandationModel(
          id: (item['id'] as String?) ?? 'reco_${e.key}',
          champId: champId,
          culture: (item['cultureNom'] as String?) ??
              (item['cultureRecommandeeId'] as String?) ??
              'Culture',
          scoreCompatibilite: score,
          periodeIdealePlantation: (item['periodePlantation'] as String?) ?? '',
          rendementEstime: rendement,
          besoinEau: eau,
          engAraisConseillesList: engrais,
          maladiesFrequentes: maladies,
          conseilsAgronomiques: (item['conseil'] as String?) ?? '',
          prixMarcheEstime: prix,
          profitPotentiel: (rendement * 1000 * prix).round(),
          dateGeneree: item['date'] != null
              ? DateTime.tryParse(item['date'].toString()) ?? DateTime.now()
              : DateTime.now(),
        );
      }).toList();

      state = state.copyWith(
        recommandations: recos,
        isLoading: false,
        champIdSelectionne: champId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger l\'historique : ${e.toString()}',
      );
    }
  }
}

final recommandationProvider =
    NotifierProvider<RecommandationNotifier, RecommandationState>(
  RecommandationNotifier.new,
);
