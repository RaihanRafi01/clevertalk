import 'package:clevertalk/common/localization/localization_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
import 'app/data/services/notification_services.dart';
import 'app/modules/audio/controllers/audio_controller.dart';
import 'app/routes/app_pages.dart';
import 'common/localization/app_translations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await Firebase.initializeApp();

  // Initialize LocalizationController and load saved language
  final LocalizationController localizationController = Get.put(LocalizationController());
  await localizationController.loadSavedLanguage(); // Ensure saved language is loaded

  final initialRoute = await AppPages.getInitialRoute();
  FlutterForegroundTask.initCommunicationPort();
  Get.put(AudioPlayerController(), permanent: true);

  runApp(
    GetMaterialApp(
      translations: AppTranslations(),
      locale: localizationController.getCurrentLocale(), // Use saved locale
      fallbackLocale: const Locale('en', 'US'),
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
    ),
  );
}