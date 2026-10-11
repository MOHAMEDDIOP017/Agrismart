import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../champs/presentation/providers/champ_provider.dart';

/// Dernière recommandation générée pour l'agriculteur, affichée sur le
/// tableau de bord.
///
/// Remplace la carte météo du dashboard : le cas d'utilisation météo temps
/// réel a été retiré du projet, le moteur de recommandation s'appuyant sur des
/// normales climatiques (NASA POWER) et non sur des prévisions.
class DerniereRecommandation {
  const DerniereRecommandation({
    required this.id,
    required this.champId,
    required this.champNom,
    required this.cultureNom,
    required this.aptitudePct,
    required this.periodePlantation,
    required this.zoneAgroecologique,
    required this.date,
  });

  final String id;
  final String champId;
  final String champNom;
  final String cultureNom;
  final int aptitudePct;
  final String periodePlantation;
  final String zoneAgroecologique;
  final DateTime date;

  String get aptitudeLabel => '$aptitudePct%';
}

/// Recommandation la plus récente du premier champ de l'agriculteur.
///
/// Renvoie `null` quand l'agriculteur n'a pas encore de champ ou qu'aucune
/// recommandation n'a été générée : le dashboard masque alors la carte, comme
/// il le faisait pour la météo indisponible.
final derniereRecommandationProvider =
    FutureProvider<DerniereRecommandation?>((ref) async {
  final champs = await ref.watch(champProvider.future);
  if (champs.isEmpty) return null;

  final champ = champs.first;
  final dio = ref.read(dioProvider);
  final resp = await dio.get(ApiEndpoints.recommandationsChampV2(champ.id));

  final data = resp.data as Map<String, dynamic>;
  final liste = data['recommandations'] as List? ?? [];
  if (liste.isEmpty) return null;

  // Le backend trie déjà par date décroissante ; on prend en plus le rang 1
  // (la culture la mieux notée du dernier top-3) s'il est présent.
  final items = liste.cast<Map<String, dynamic>>();
  final item = items.firstWhere(
    (r) => (r['rang'] as num?)?.toInt() == 1,
    orElse: () => items.first,
  );

  return DerniereRecommandation(
    id: (item['id'] as String?) ?? '',
    champId: champ.id,
    champNom: champ.nom,
    cultureNom: (item['cultureNom'] as String?) ?? 'Culture',
    aptitudePct: (((item['probabiliteAptitude'] as num?) ?? 0) * 100).round(),
    periodePlantation: (item['periodePlantation'] as String?) ?? '',
    zoneAgroecologique: (item['zoneAgroecologique'] as String?) ?? 'Sénégal',
    date: item['date'] != null
        ? DateTime.tryParse(item['date'].toString()) ?? DateTime.now()
        : DateTime.now(),
  );
});
