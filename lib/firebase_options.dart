
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Esta configuração foi preparada para Flutter Web.',
        );
      default:
        throw UnsupportedError(
          'Plataforma não suportada.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBd1Al3daHhbTVzKaSPgN9WwMV0r9HKFYo',
    appId: '1:98571110854:web:0307d10423a200bc69cac7',
    messagingSenderId: '98571110854',
    projectId: 'compressorm',
    authDomain: 'compressorm.firebaseapp.com',
    storageBucket: 'compressorm.firebasestorage.app',
  );
}
