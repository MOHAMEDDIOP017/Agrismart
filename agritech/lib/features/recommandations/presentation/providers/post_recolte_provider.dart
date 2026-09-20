import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

/// Génère et récupère les scénarios post-récolte pour une recommandation sauvegardée.
/// Le paramètre est le Firestore ID de la recommandation culture.
final postRecolteProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, recommandationId) async {
  if (recommandationId.isEmpty || recommandationId.startsWith('reco_')) {
    // ID local (non sauvegardé) — pas de call backend
    return [];
  }
  final dio = ref.read(dioProvider);
  final resp =
      await dio.post('/recommandations/$recommandationId/post-recolte');
  final data = resp.data as Map<String, dynamic>;
  return (data['scenarios'] as List? ?? []).cast<Map<String, dynamic>>();
});
