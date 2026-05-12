import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class DonneesAgroNotifier extends AsyncNotifier<void> {
  late Dio _dio;

  @override
  Future<void> build() async {
    _dio = ref.read(dioProvider);
  }

  Future<void> sauvegarder({
    required String champId,
    required double ph,
    required double azote,
    required double phosphore,
    required double potassium,
    required double humidite,
    String? observations,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _dio.post('/donnees-agronomiques', data: {
        'champId': champId,
        'phSol': ph,
        'tauxAzote': azote,
        'tauxPhosphore': phosphore,
        'tauxPotassium': potassium,
        'humiditeObservee': humidite,
        if (observations != null && observations.isNotEmpty)
          'observations': observations,
      });
    });
  }
}

final donneesAgroProvider =
    AsyncNotifierProvider<DonneesAgroNotifier, void>(DonneesAgroNotifier.new);
