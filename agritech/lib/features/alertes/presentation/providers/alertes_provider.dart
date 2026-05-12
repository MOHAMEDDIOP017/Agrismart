import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/alerte_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AlertesNotifier extends AsyncNotifier<List<AlerteModel>> {
  late Dio _dio;

  @override
  Future<List<AlerteModel>> build() async {
    _dio = ref.read(dioProvider);
    final auth = ref.watch(authProvider);
    final userId = auth.valueOrNull?.user?.id;
    if (userId == null) return [];
    return _charger(userId);
  }

  Future<List<AlerteModel>> _charger(String userId) async {
    final resp = await _dio.get('/diagnostics/agriculteur/$userId?limite=50');
    final data = resp.data as Map<String, dynamic>;
    final diagnostics = (data['diagnostics'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        // Garde uniquement ceux avec alerteEnvoyee=true OU gravité ELEVE/CRITIQUE
        .where((d) {
          final alerte = d['alerteEnvoyee'] as bool? ?? false;
          final g =
              (d['niveauGravite'] ?? d['niveauGraviteIA'] ?? '').toString().toUpperCase();
          return alerte || g == 'ELEVE' || g == 'CRITIQUE';
        })
        .map(_mapToAlerte)
        .toList();
    return diagnostics;
  }

  Future<void> rafraichir() async {
    final auth = ref.read(authProvider);
    final userId = auth.valueOrNull?.user?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _charger(userId));
  }

  static AlerteModel _mapToAlerte(Map<String, dynamic> d) {
    final graviteStr =
        (d['niveauGravite'] ?? d['niveauGraviteIA'] ?? 'MODERE').toString().toUpperCase();
    final niveau = switch (graviteStr) {
      'CRITIQUE' => 'CRITIQUE',
      'ELEVE' => 'ÉLEVÉ',
      'FAIBLE' => 'FAIBLE',
      _ => 'MODÉRÉ',
    };
    return AlerteModel(
      id: (d['id'] ?? '') as String,
      titre: 'Maladie détectée : ${d['maladieDetectee'] ?? 'Inconnue'}',
      description:
          'Score confiance : ${((d['scoreConfiance'] as num? ?? 0) * 100).toStringAsFixed(0)}%',
      champId: (d['champId'] ?? '') as String,
      champNom: (d['champNom'] ?? 'Champ') as String,
      niveau: niveau,
      maladieDetectee: (d['maladieDetectee'] ?? '') as String,
      traitementConseille: '',
      dateCreation:
          DateTime.tryParse(d['dateAnalyse']?.toString() ?? '') ?? DateTime.now(),
      imageUrl: d['imageUrl'] as String?,
      isLue: d['statut'] != 'EN_ATTENTE',
    );
  }
}

final alertesProvider =
    AsyncNotifierProvider<AlertesNotifier, List<AlerteModel>>(
  AlertesNotifier.new,
);
