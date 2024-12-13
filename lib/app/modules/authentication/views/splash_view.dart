import 'package:clevertalk/app/modules/authentication/views/authentication_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/appColors.dart';
import 'forgot_password_view.dart';

class SplashView extends GetView {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    // Schedule a delay for 3 seconds and navigate to the next screen
    Future.delayed(const Duration(seconds: 3), () {
      Get.off(()=> AuthenticationView()); // Replace '/home' with your desired route name
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
