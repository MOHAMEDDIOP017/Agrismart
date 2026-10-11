import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';

/// Gère l'enregistrement FCM et la réception des notifications push.
///
/// Ce service ne navigue pas lui-même : il expose les ouvertures de
/// notification sous forme de flux, et c'est l'application qui décide de
/// l'écran à ouvrir, puisqu'elle seule connaît le rôle de la personne
/// connectée. Voir `routeNotification` dans
/// `lib/navigation/destinations_notifications.dart`.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  /// Construit à la première utilisation, et non à la création du service.
  ///
  /// `FirebaseMessaging.instance` lève une exception tant que
  /// `Firebase.initializeApp` n'a pas été appelé. En champ d'instance, la
  /// simple mention de `FcmService.instance` suffisait donc à faire échouer
  /// l'application là où Firebase n'est pas configuré : en test, et sur un
  /// poste de développement sans `google-services.json`. L'abonnement au flux
  /// d'ouvertures, lui, ne demande rien à Firebase.
  FirebaseMessaging? _messagerie;
  FirebaseMessaging get _fcm => _messagerie ??= FirebaseMessaging.instance;

  Dio? _client;
  Dio get _dio => _client ??= ApiClient().dio;

  final StreamController<Map<String, String>> _ouvertures =
      StreamController<Map<String, String>>.broadcast();

  /// Notifications ouvertes par l'utilisateur, alors que l'application
  /// tournait en arrière-plan.
  Stream<Map<String, String>> get ouvertures => _ouvertures.stream;

  /// Notification qui a démarré l'application, quand elle était fermée.
  ///
  /// Conservée plutôt que publiée sur le flux : `init()` s'exécute dans
  /// `main()`, avant que l'interface n'existe, donc avant qu'un auditeur ait
  /// pu s'abonner. L'application la réclame une fois construite.
  Map<String, String>? _ouvertureInitiale;

  /// Rend la notification de démarrage, puis l'oublie, pour qu'une
  /// reconstruction de l'interface ne rouvre pas le même écran.
  Map<String, String>? consommerOuvertureInitiale() {
    final ouverture = _ouvertureInitiale;
    _ouvertureInitiale = null;
    return ouverture;
  }

  Future<void> init() async {
    try {
      // Demande la permission (iOS / Android 13+)
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      // Enregistre le token FCM sur le backend
      final token = await _fcm.getToken();
      if (token != null) await _enregistrerToken(token);

      // Écoute les renouvellements de token
      _fcm.onTokenRefresh.listen(_enregistrerToken);

      // Messages reçus quand l'app est au premier plan
      FirebaseMessaging.onMessage.listen(_onMessageForegrond);

      // Notification touchée alors que l'application était en arrière-plan.
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _ouvertures.add(_donnees(message));
      });

      // Notification qui a lancé l'application depuis un état fermé.
      final initiale = await _fcm.getInitialMessage();
      if (initiale != null) _ouvertureInitiale = _donnees(initiale);
    } catch (e) {
      // Firebase non configuré (google-services.json absent) — mode dev
      debugPrint('[FCM] Non disponible : $e');
    }
  }

  Future<void> _enregistrerToken(String token) async {
    try {
      await _dio.patch('/utilisateurs/me/fcm-token', data: {'fcmToken': token});
    } catch (_) {}
  }

  void _onMessageForegrond(RemoteMessage message) {
    debugPrint('[FCM] Message reçu : ${message.notification?.title}');
    // Les écrans qui écoutent notificationsProvider se rafraîchiront
    // au prochain appel de rafraichir(). Une intégration plus poussée
    // peut utiliser un StreamController global ici.
  }

  /// Normalise la charge utile en chaînes.
  ///
  /// Le serveur envoie déjà tout en texte, `{k: str(v) for k, v in ...}`, mais
  /// la bibliothèque type les valeurs en `Object?`.
  Map<String, String> _donnees(RemoteMessage message) {
    return message.data.map(
      (cle, valeur) => MapEntry(cle, valeur?.toString() ?? ''),
    );
  }
}
