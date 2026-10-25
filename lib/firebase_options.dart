import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Generated for package: com.gasflow.tracker.gas_tracker
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
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDummyProductionReadyApiKeyForFirebase',
    appId: '1:102938475612:web:6179b29cbdfc136365fa91',
    messagingSenderId: '102938475612',
    projectId: 'lanka-gas-tracker',
    authDomain: 'lanka-gas-tracker.firebaseapp.com',
    storageBucket: 'lanka-gas-tracker.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCCrx46_a4Wuyc7BlPBYPigPhJPF1AxrMU',
    appId: '1:542945871024:android:b48ca4f062f512dc082775',
    messagingSenderId: '542945871024',
    projectId: 'chat-3af33',
    storageBucket: 'chat-3af33.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDummyProductionReadyApiKeyForFirebase',
    appId: '1:102938475612:ios:6179b29cbdfc136365fa91',
    messagingSenderId: '102938475612',
    projectId: 'lanka-gas-tracker',
    storageBucket: 'lanka-gas-tracker.appspot.com',
    iosBundleId: 'com.gasflow.tracker.gasTracker',
  );
}
