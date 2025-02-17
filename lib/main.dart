import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/data/services/notification_services.dart';
import 'app/routes/app_pages.dart';

Future<void> main() async {
  // Load SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  //await Firebase.initializeApp();
  final initialRoute = await AppPages.getInitialRoute();

  runApp(
    GetMaterialApp(
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // Set the default background color to white
      ),
    ),
  );
}
