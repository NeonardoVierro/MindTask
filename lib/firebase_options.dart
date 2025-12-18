// File: lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform tidak didukung');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAcFa33_vTO1J5VX-VqhaiXJUtWomR5f-Q',
    appId: '1:823131186330:web:abcdef1234567890',
    messagingSenderId: '823131186330',
    projectId: 'todo-list-app-5600c',
    storageBucket: 'todo-list-app-5600c.firebasestorage.app',
    authDomain: 'todo-list-app-5600c.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAcFa33_vTO1J5VX-VqhaiXJUtWomR5f-Q',
    appId: '1:823131186330:android:1473a97222c1f888caab23',
    messagingSenderId: '823131186330',
    projectId: 'todo-list-app-5600c',
    storageBucket: 'todo-list-app-5600c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAcFa33_vTO1J5VX-VqhaiXJUtWomR5f-Q',
    appId: '1:823131186330:ios:abcdef1234567890',
    messagingSenderId: '823131186330',
    projectId: 'todo-list-app-5600c',
    storageBucket: 'todo-list-app-5600c.firebasestorage.app',
  );
}