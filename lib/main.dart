import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
import 'app/data/services/notification_services.dart';
import 'app/modules/audio/controllers/audio_controller.dart';
import 'app/routes/app_pages.dart';

Future<void> main() async {
  // Load SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await Firebase.initializeApp();
  final initialRoute = await AppPages.getInitialRoute();
  FlutterForegroundTask.initCommunicationPort();
  Get.put(AudioPlayerController(), permanent: true);

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // Set the default background color to white
      ),
    ),
  );
}
