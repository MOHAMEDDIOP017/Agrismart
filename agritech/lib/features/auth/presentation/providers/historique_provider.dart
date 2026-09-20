import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/historique_activite_repository_impl.dart';
import '../../domain/entities/historique_activite_entity.dart';
import '../../domain/repositories/historique_activite_repository.dart';
import 'auth_provider.dart';

// ── Repository provider ──────────────────────────────────────────────────────

final historiqueRepositoryProvider =
    Provider<HistoriqueActiviteRepository>((ref) {
  return HistoriqueActiviteRepositoryImpl(ref.read(dioProvider));
});

// ── Historique de l'utilisateur connecté ────────────────────────────────────

final historiqueProvider =
    FutureProvider.autoDispose<List<HistoriqueActiviteEntity>>((ref) async {
  final userId = ref.read(authProvider).valueOrNull?.user?.id ?? '';
  if (userId.isEmpty) return [];
  return ref
      .read(historiqueRepositoryProvider)
      .getHistoriqueUtilisateur(userId);
});

/// Historique filtré par type d'action
final historiqueParTypeProvider = FutureProvider.autoDispose
    .family<List<HistoriqueActiviteEntity>, String>((ref, typeAction) async {
  final userId = ref.read(authProvider).valueOrNull?.user?.id ?? '';
  if (userId.isEmpty) return [];
  return ref
      .read(historiqueRepositoryProvider)
      .getHistoriqueParType(userId, typeAction);
});
