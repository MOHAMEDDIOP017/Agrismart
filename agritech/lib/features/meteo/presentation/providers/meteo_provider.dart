import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../champs/presentation/providers/champ_provider.dart';
import '../../data/models/meteo_model.dart';

/// Météo du premier champ (widget dashboard — compatibilité ascendante).
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

/// Météo actuelle pour un champ donné (par champId).
final meteoParChampProvider =
    FutureProvider.family<MeteoModel?, String>((ref, champId) async {
  if (champId.isEmpty) return null;
  final dio = ref.read(dioProvider);
  final resp = await dio.get('/meteo/actuelle/$champId');
  final data = resp.data as Map<String, dynamic>;
  final meteoJson = data['meteo'] as Map<String, dynamic>?;
  if (meteoJson == null) return null;
  return MeteoModel.fromJson(meteoJson);
});

/// Prévisions 5 jours pour un champ donné (tranches 3h groupées par jour).
final previsionsMeteoProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, champId) async {
  if (champId.isEmpty) return [];
  final dio = ref.read(dioProvider);
  final resp = await dio.get('/meteo/previsions/$champId?jours=5');
  final data = resp.data as Map<String, dynamic>;
  final tranches = (data['previsions'] as List? ?? [])
      .cast<Map<String, dynamic>>();

  // Regroupe par jour : garde une tranche par jour (celle de midi ou la première)
  final Map<String, Map<String, dynamic>> parJour = {};
  for (final t in tranches) {
    final dt = t['dt_txt'] as String? ?? '';
    final jour = dt.isNotEmpty ? dt.substring(0, 10) : '';
    if (jour.isEmpty) continue;
    if (!parJour.containsKey(jour)) {
      parJour[jour] = t;
    } else if (dt.contains('12:00')) {
      parJour[jour] = t; // préfère la tranche de midi
    }
  }

  return parJour.entries.take(5).map((e) {
    final t = e.value;
    final dt = DateTime.tryParse(e.key) ?? DateTime.now();
    const jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const mois = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    final label = '${jours[dt.weekday - 1]} ${dt.day} ${mois[dt.month - 1]}';

    final main = t['main'] as Map<String, dynamic>? ?? {};
    final weather = (t['weather'] as List?)?.firstOrNull as Map<String, dynamic>? ?? {};
    final rain = t['rain'] as Map<String, dynamic>? ?? {};

    return {
      'date_label': label,
      'temperature': (main['temp'] as num?)?.toDouble() ?? 0.0,
      'temperature_min': (main['temp_min'] as num?)?.toDouble() ?? 0.0,
      'temperature_max': (main['temp_max'] as num?)?.toDouble() ?? 0.0,
      'humidite': (main['humidity'] as num?)?.toInt() ?? 0,
      'description': (weather['description'] as String? ?? '').toLowerCase(),
      'pluviometrie': (rain['3h'] as num?)?.toDouble() ?? 0.0,
      'dt_txt': e.key,
    };
  }).toList();
});
