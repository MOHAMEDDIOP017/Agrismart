import 'dart:io';
import 'package:flutter/foundation.dart';

/// Configuration centralisée de l'URL du backend AgriSmart.
///
/// ⚠️ Quand l'IP change (nouveau réseau Wi-Fi) :
///   1. Exécuter dans PowerShell : ipconfig
///   2. Trouver "Carte réseau sans fil Wi-Fi → Adresse IPv4"
///   3. Mettre à jour [_wifiPcIp] ci-dessous
///   4. Mettre à jour aussi network_security_config.xml (même IP)
///   5. Hot reload Flutter (R dans le terminal flutter run)
class ApiConfig {
  // ── À mettre à jour si l'IP Wi-Fi du PC change ───────────────────────────
  static const String _wifiPcIp = '10.86.209.5';
  // ──────────────────────────────────────────────────────────────────────────

  static const int _port = 8000;

  /// Passer à true uniquement pour le déploiement en production.
  static const bool _isProduction = false;

  /// URL du backend déployé (à configurer avant la mise en production).
  static const String _productionUrl = 'https://api.agrismart.example.com';

  /// URL de base du backend selon la plateforme et le mode.
  static String get baseUrl {
    if (_isProduction) return _productionUrl;

    // Web (Chrome desktop) — même machine que le backend
    if (kIsWeb) return 'http://localhost:$_port';

    try {
      if (Platform.isAndroid) {
        // Émulateur Android : décommenter la ligne suivante et commenter la suivante
        // return 'http://10.0.2.2:$_port';
        return 'http://$_wifiPcIp:$_port';
      }
      if (Platform.isIOS) {
        // iOS simulateur (même machine) ou iPhone physique sur Wi-Fi
        return 'http://$_wifiPcIp:$_port';
      }
    } catch (_) {
      // Platform.isX non disponible sur web/desktop — déjà géré au-dessus
    }

    return 'http://localhost:$_port';
  }

  /// Affiche la configuration active dans la console Flutter (debug uniquement).
  static void debugLog() {
    if (!kDebugMode) return;
    final platform = kIsWeb ? 'Web' : Platform.operatingSystem;
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('  AgriSmart — Configuration réseau');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('  Plateforme  : $platform');
    debugPrint('  Mode        : ${_isProduction ? "Production" : "Développement"}');
    debugPrint('  URL backend : $baseUrl');
    debugPrint('═══════════════════════════════════════════════');
  }
}
