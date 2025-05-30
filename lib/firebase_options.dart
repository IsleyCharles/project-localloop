// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyABMPzxCVUroSyEznKgvEEMU9-mIiBJXI8',
    appId: '1:693648893064:web:867201cfa6c85be5a1eb3d',
    messagingSenderId: '693648893064',
    projectId: 'localloop-20504',
    authDomain: 'localloop-20504.firebaseapp.com',
    storageBucket: 'localloop-20504.appspot.com', // ✅ Fixed
    measurementId: 'G-GNKM9QWTQ5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyACndxDlww3pALPs5YHp0s6PFeV4rXV8GY',
    appId: '1:693648893064:android:7aa5767b8a24a33fa1eb3d',
    messagingSenderId: '693648893064',
    projectId: 'localloop-20504',
    storageBucket: 'localloop-20504.appspot.com', // ✅ Fixed
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDwq6jD3fMkMjM1GJDkFRffZXhZsH0L-0w',
    appId: '1:693648893064:ios:406d4216f2ff3879a1eb3d',
    messagingSenderId: '693648893064',
    projectId: 'localloop-20504',
    storageBucket: 'localloop-20504.appspot.com', // ✅ Fixed
    iosBundleId: 'com.example.localloop',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDwq6jD3fMkMjM1GJDkFRffZXhZsH0L-0w',
    appId: '1:693648893064:ios:406d4216f2ff3879a1eb3d',
    messagingSenderId: '693648893064',
    projectId: 'localloop-20504',
    storageBucket: 'localloop-20504.appspot.com', // ✅ Fixed
    iosBundleId: 'com.example.localloop',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyABMPzxCVUroSyEznKgvEEMU9-mIiBJXI8',
    appId: '1:693648893064:web:37b542d62d85102ea1eb3d',
    messagingSenderId: '693648893064',
    projectId: 'localloop-20504',
    authDomain: 'localloop-20504.firebaseapp.com',
    storageBucket: 'localloop-20504.appspot.com', // ✅ Fixed
    measurementId: 'G-D4EJZL92P8',
  );
}
