import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/providers/auth_provider.dart';
// Providers agriculteur
import '../../../features/champs/presentation/providers/champ_provider.dart';
import '../../../features/notifications/presentation/providers/notifications_provider.dart';
import '../../../features/alertes/presentation/providers/alertes_provider.dart';
import '../../../features/auth/presentation/providers/historique_provider.dart';
import '../../../features/recommandations/presentation/providers/recommandation_provider.dart';
// Providers expert
import '../../../features/expert/presentation/providers/expert_provider.dart';
// Providers admin
import '../../../features/admin/presentation/providers/admin_provider.dart';

/// Service centralisé de déconnexion.
///
/// Règle le bug de double navigation :
///   - NE PAS appeler context.go('/login') depuis les screens
///   - Le _AuthListenable dans app_router.dart écoute authProvider et gère la
///     redirection automatiquement quand isAuthenticated passe à false
///
/// Invalide aussi tous les providers liés à l'utilisateur (agriculteur, expert,
/// admin) pour éviter les stale data à la reconnexion et les rebuilds
/// incontrôlés sur expertIdProvider qui surveille authProvider.
class DeconnexionService {
  static Future<void> deconnecter(WidgetRef ref) async {
    debugPrint('[Deconnexion] Debut...');

    // ── Providers agriculteur ────────────────────────────────────────────────
    ref.invalidate(champProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(alertesProvider);
    ref.invalidate(historiqueProvider);
    ref.invalidate(recommandationProvider);

    // ── Providers expert ─────────────────────────────────────────────────────
    // expertIdProvider surveille authProvider → passe à '' lors du logout.
    // Il faut invalider tous les providers qui l'utilisent avant que cela arrive.
    ref.invalidate(profilExpertProvider);
    ref.invalidate(champsSupervisionProvider);
    ref.invalidate(interventionsProvider);
    ref.invalidate(conseilsProvider);

    // ── Providers admin ──────────────────────────────────────────────────────
    ref.invalidate(statistiquesProvider);
    ref.invalidate(gestionUtilisateursProvider);
    ref.invalidate(assignationProvider);
    ref.invalidate(logsProvider);
    ref.invalidate(champsAdminProvider);

    debugPrint('[Deconnexion] Providers invalides');

    // Laisser un cycle de frame pour que les invalidations soient traitées
    await Future.delayed(const Duration(milliseconds: 100));

    // signOut Firebase + suppression SharedPreferences.
    // authProvider.isAuthenticated → false → _AuthListenable → go_router → /login
    await ref.read(authProvider.notifier).logout();

    debugPrint(
        '[Deconnexion] Terminee. Router redirige vers /login automatiquement.');
    // ⚠️ NE PAS appeler context.go('/login') — double navigation = crash en cascade.
  }
}
