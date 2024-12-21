import 'package:clevertalk/app/modules/dashboard/views/dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../common/appColors.dart';
import '../../home/views/home_view.dart';
import 'authentication_view.dart';

class SplashView extends GetView {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    // Check login status and navigate accordingly
    Future.delayed(const Duration(seconds: 3), () async {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (isLoggedIn) {
        Get.off(() => const DashboardView()); // Navigate to the Home screen if logged in
      } else {
        Get.off(() => AuthenticationView()); // Navigate to the Authentication screen if not logged in
      }
    });

    return Scaffold(
      body: Container(
        color: AppColors.appColor, // Full background color
        child: const Center(
          child: Text(
            'CLEVERTALK',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Text color for better visibility
            ),
          ),
        ),
      ),
    );
  }
}
