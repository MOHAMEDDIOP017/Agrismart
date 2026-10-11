// Généré depuis google-services.json — projet agrismart-jf-f1879
// (même projet Firebase que le backend : Auth, Firestore et FCM partagés)
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
    apiKey: 'AIzaSyA3SDuHUM7DElkeMFoGU-ieLVj3hcxSM8I',
    appId: '1:201932176662:android:f2269ab85a6e302fb9e437',
    messagingSenderId: '201932176662',
    projectId: 'agrismart-jf-f1879',
    storageBucket: 'agrismart-jf-f1879.firebasestorage.app',
  );
}
