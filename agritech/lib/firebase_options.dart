// Généré depuis google-services.json — projet agrismart-jf
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
          'DefaultFirebaseOptions non configuré pour le Web.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
            'DefaultFirebaseOptions non configuré pour iOS.');
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions non supporté sur cette plateforme.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDXPVZCLO4GCkd_P_kWy5HOTqX-PPUoSeo',
    appId: '1:555192061987:android:58f5a826b5fa4677ef6196',
    messagingSenderId: '555192061987',
    projectId: 'agrismart-jf',
    storageBucket: 'agrismart-jf.firebasestorage.app',
  );
}
