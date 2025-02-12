import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/routes/app_pages.dart';

Future<void> main() async {
  // Load SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
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
