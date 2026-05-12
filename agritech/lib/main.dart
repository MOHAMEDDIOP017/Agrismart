import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/config/api_config.dart';
import 'features/shared/notifications/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Affiche la configuration réseau active (debug uniquement)
  ApiConfig.debugLog();

  // Initialisation Firebase (nécessite google-services.json dans android/app/)
  try {
    await Firebase.initializeApp();
    await FcmService.instance.init();
  } catch (_) {
    // Firebase non configuré — mode bypass backend actif
  }

  // Orientation portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Style de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: AgriSmartApp(),
    ),
  );
}
