import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';

import 'app.dart';
// TODO: Uncomment after running `flutterfire configure`
// import 'firebase_options.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    debugPrint(details.toString());
  };

  // Initialize storage
  final storage = SecureStorageService();
  await storage.init();

  // Initialize Firebase
  // TODO: Uncomment after running `flutterfire configure` and
  //       placing google-services.json in android/app/
  // await FirebaseService.init(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // Initialize Crashlytics (requires Firebase Core)
  // TODO: Uncomment after Firebase is initialized
  // await CrashlyticsService.init();

  // Initialize offline database
  final database = AppDatabase();

  // Web: kembalian dari halaman masuk Google dibaca sebelum router dibuat.
  final googleWebSignIn = GoogleWebSignIn.forPlatform()?..capture();

  runApp(App(
    storage: storage,
    database: database,
    googleWebSignIn: googleWebSignIn,
  ));
}
