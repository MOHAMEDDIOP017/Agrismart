import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/shared/notifications/fcm_service.dart';
import 'navigation/app_router.dart';
import 'navigation/destinations_notifications.dart';

/// Point d'entrée principal de l'application AgriSmart
class AgriSmartApp extends ConsumerStatefulWidget {
  const AgriSmartApp({super.key});

  @override
  ConsumerState<AgriSmartApp> createState() => _AgriSmartAppState();
}

class _AgriSmartAppState extends ConsumerState<AgriSmartApp> {
  StreamSubscription<Map<String, String>>? _abonnementNotifications;

  /// Notification reçue avant que la session ne soit connue.
  ///
  /// L'écran à ouvrir dépend du rôle. Si la notification arrive pendant que
  /// l'authentification se résout, ou avant une connexion, la destination est
  /// mise de côté et appliquée dès que le rôle est disponible. Sans cela, une
  /// notification touchée sur un téléphone verrouillé se perdrait au profit de
  /// l'écran de connexion.
  Map<String, String>? _notificationEnAttente;

  @override
  void initState() {
    super.initState();

    _abonnementNotifications =
        FcmService.instance.ouvertures.listen(_traiterNotification);

    // La notification qui a démarré l'application a été mise de côté par le
    // service, faute d'auditeur à ce moment-là.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initiale = FcmService.instance.consommerOuvertureInitiale();
      if (initiale != null) _traiterNotification(initiale);
    });
  }

  @override
  void dispose() {
    _abonnementNotifications?.cancel();
    super.dispose();
  }

  void _traiterNotification(Map<String, String> donnees) {
    final etat = ref.read(authProvider).valueOrNull;
    final role = etat?.user?.role;

    if (role == null || !(etat?.isAuthenticated ?? false)) {
      _notificationEnAttente = donnees;
      return;
    }

    final route = routeNotification(donnees, role);
    if (route != null) ref.read(routerProvider).go(route);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Applique la destination mise de côté dès que la session est établie.
    ref.listen(authProvider, (_, suivant) {
      final etat = suivant.valueOrNull;
      if (etat == null || !etat.isAuthenticated) return;
      final enAttente = _notificationEnAttente;
      if (enAttente == null) return;
      _notificationEnAttente = null;
      _traiterNotification(enAttente);
    });

    return MaterialApp.router(
      title: 'AgriSmart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // Le mode sombre suit le réglage du téléphone.
      //
      // Il attendait que les écrans cessent d'appeler les constantes statiques
      // d'`AppColors`, qu'une couleur figée à la compilation rendait aveugles
      // au mode d'affichage : un écran posant `AppColors.background` comme
      // fond de champ de saisie aurait gardé son fond crème sous un texte
      // devenu clair. Les 645 références restantes sont passées à
      // `context.couleurs`, et la classe a été supprimée.
      themeMode: ThemeMode.system,

      routerConfig: router,
      locale: const Locale('fr', 'FR'),

      // Borne la taille de texte entre 100 % et 200 %.
      //
      // La borne haute reprend le seuil de WCAG 1.4.4, qui demande qu'une
      // interface reste utilisable jusqu'à 200 %. Android permet d'aller
      // au-delà en combinant taille de police et taille d'affichage, ce qui
      // réduirait certains écrans à deux mots par ligne.
      //
      // La borne basse empêche de descendre sous la taille de référence. Toute
      // l'échelle typographique est construite sur un corps de 16 et un
      // plancher de 14 pour une lecture en extérieur ; autoriser une réduction
      // annulerait ce choix.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 2.0,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
