import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';

/// Gère l'enregistrement FCM et la réception des notifications push.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final Dio _dio = ApiClient().dio;

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
}
