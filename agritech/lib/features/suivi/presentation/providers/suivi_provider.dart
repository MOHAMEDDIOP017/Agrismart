import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/culture_en_champ_model.dart';

/// Cultures en champ pour un champ donné (par champId).
final culturesEnChampProvider =
    FutureProvider.autoDispose.family<List<CultureEnChampModel>, String>(
  (ref, champId) async {
    if (champId.isEmpty) return [];
    final dio = ref.read(dioProvider);
    final resp = await dio.get('/cultures-en-champ/champ/$champId');
    final data = resp.data as Map<String, dynamic>;
    final list = (data['cultures'] as List? ?? []).cast<Map<String, dynamic>>();
    return list
        .map((json) =>
            CultureEnChampModel.fromJson({...json, 'id': json['id'] ?? ''}))
        .toList();
  },
);
