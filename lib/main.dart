import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/routes/app_pages.dart';

Future<void> main() async {
  // Load SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;


  runApp(
    GetMaterialApp(
      initialRoute: isLoggedIn ? Routes.HOME : Routes.AUTHENTICATION,
      getPages: AppPages.routes,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // Set the default background color to white
      ),
    ),
  );
}
