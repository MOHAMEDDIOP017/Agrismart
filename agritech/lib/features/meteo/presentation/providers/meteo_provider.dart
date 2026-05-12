import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../champs/presentation/providers/champ_provider.dart';
import '../../data/models/meteo_model.dart';

/// Météo du premier champ de l'utilisateur (OpenWeatherMap via backend).
/// Retourne null si l'utilisateur n'a pas encore de champ ou si l'API est indisponible.
final meteoProvider = FutureProvider<MeteoModel?>((ref) async {
  final champs = await ref.watch(champProvider.future);
  if (champs.isEmpty) return null;

  final dio = ref.read(dioProvider);
  final champId = champs.first.id;
  final resp = await dio.get('/meteo/actuelle/$champId');
  final meteoJson =
      (resp.data as Map<String, dynamic>)['meteo'] as Map<String, dynamic>;
  return MeteoModel.fromJson(meteoJson);
});
