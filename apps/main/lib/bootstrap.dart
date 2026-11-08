import 'package:flutter/material.dart';
import 'package:core/core.dart';

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

  runApp(App(storage: storage, database: database));
}
