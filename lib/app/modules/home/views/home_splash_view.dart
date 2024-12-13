import 'package:clevertalk/app/modules/home/views/home_view.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

class HomeSplashView extends GetView {
  const HomeSplashView({super.key});
  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      Get.offAll(()=> HomeView()); // Replace '/home' with your desired route name
    });
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/images/home/home_splash.png'),
            SizedBox(height: 50),
            const Text(
              'Welcome to our family',
              style: TextStyle(fontSize: 26),
            ),
          ],
        ),
      ),
    );
  }
}
