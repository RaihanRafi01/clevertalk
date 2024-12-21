import 'package:clevertalk/app/modules/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:clevertalk/app/modules/audio/views/audio_view.dart';
import 'package:clevertalk/app/modules/profile/views/profile_view.dart';
import 'package:clevertalk/app/modules/setting/views/setting_view.dart';
import 'package:clevertalk/app/modules/text/views/text_view.dart';
import 'package:clevertalk/app/modules/home/views/home_view.dart';
import 'package:get/get.dart';
import '../../../../common/appColors.dart';
import '../../../../common/widgets/customNavigationBar.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  Widget build(BuildContext context) {
    // Initialize the DashboardController
    final controller = Get.put(DashboardController());
    final homeController = Get.put(HomeController());
    homeController.fetchProfileData();

    // List of pages for navigation
    final List<Widget> _screens = [
      const HomeView(),
      const TextView(),
      const AudioView(),
      const SettingView(),
      const ProfileView(),
    ];

    return Scaffold(
      backgroundColor: AppColors.appColor,
      // Set the background color for the scaffold
      body: Stack(
        children: [
          // The main content of the screen inside SafeArea to avoid overlap with bottom nav
          SafeArea(
            child: Obx(() => _screens[controller.currentIndex.value]),
          ),

          // The custom navigation bar at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: const CustomNavigationBar(),
          ),
        ],
      ),
    );
  }
}
