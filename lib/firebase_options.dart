import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAhsXPEgIkS0yTs8PNOUFf60ZxMpAldW9g',
    appId: 'YOUR_WEB_APP_ID', // Replace this with the App ID of your Firebase Web App
    messagingSenderId: '12890089792',
    projectId: 'homei-mobile',
    authDomain: 'homei-mobile.firebaseapp.com',
    databaseURL: 'https://homei-mobile-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'homei-mobile.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAhsXPEgIkS0yTs8PNOUFf60ZxMpAldW9g',
    appId: '1:12890089792:android:6bfb722f2b73a24fe572a5',
    messagingSenderId: '12890089792',
    projectId: 'homei-mobile',
    databaseURL: 'https://homei-mobile-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'homei-mobile.firebasestorage.app',
  );
}
