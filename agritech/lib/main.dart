import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/config/api_config.dart';
import 'features/shared/notifications/fcm_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR');
  Intl.defaultLocale = 'fr_FR';

  // Affiche la configuration réseau active (debug uniquement)
  ApiConfig.debugLog();

  // Initialisation Firebase avec les options explicites du projet koobalaTech-jf
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM : non bloquant — échec toléré si les services Google sont indisponibles
  try {
    await FcmService.instance.init();
  } catch (e) {
    debugPrint('[FCM] Init échouée (non bloquant) : $e');
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
      child: KoobalaTechApp(),
    ),
  );
}
