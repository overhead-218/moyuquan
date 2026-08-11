import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDEU9kjSVpcX9PISXYajFZBp1zGrTnRDH8',
    appId: '1:287589333211:web:c47c70aa27236e060074fe',
    messagingSenderId: '287589333211',
    projectId: 'moyuquan-11e19',
    authDomain: 'moyuquan-11e19.firebaseapp.com',
    storageBucket: 'moyuquan-11e19.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDEU9kjSVpcX9PISXYajFZBp1zGrTnRDH8',
    appId: '1:287589333211:android:PLACEHOLDER',
    messagingSenderId: '287589333211',
    projectId: 'moyuquan-11e19',
    storageBucket: 'moyuquan-11e19.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDEU9kjSVpcX9PISXYajFZBp1zGrTnRDH8',
    appId: '1:287589333211:ios:PLACEHOLDER',
    messagingSenderId: '287589333211',
    projectId: 'moyuquan-11e19',
    storageBucket: 'moyuquan-11e19.firebasestorage.app',
    iosBundleId: 'com.fishing.fishingApp',
  );
}
