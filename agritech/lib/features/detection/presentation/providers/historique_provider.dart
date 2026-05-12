import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/diagnostic_entity.dart';
import 'detection_provider.dart';

/// Provider de l'historique des diagnostics
class HistoriqueNotifier extends AsyncNotifier<List<DiagnosticEntity>> {
  @override
  Future<List<DiagnosticEntity>> build() async {
    return ref.read(detectionRepositoryProvider).getHistoriqueDiagnostics();
  }

  Future<void> rafraichir() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(detectionRepositoryProvider).getHistoriqueDiagnostics(),
    );
  }

  Future<void> archiver(String id) async {
    await ref.read(detectionRepositoryProvider).archiverDiagnostic(id);
    final liste = state.valueOrNull ?? [];
    state = AsyncData(liste.where((d) => d.id != id).toList());
  }
}

final historiqueProvider =
    AsyncNotifierProvider<HistoriqueNotifier, List<DiagnosticEntity>>(
  HistoriqueNotifier.new,
);

/// Provider des 5 derniers diagnostics (pour la home screen)
final derniersDiagnosticsProvider = Provider<List<DiagnosticEntity>>((ref) {
  final liste = ref.watch(historiqueProvider).valueOrNull ?? [];
  return liste.take(5).toList();
});
