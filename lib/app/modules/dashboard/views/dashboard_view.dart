import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../common/appColors.dart';
import '../../../../common/widgets/customNavigationBar.dart';
import '../../home/controllers/home_controller.dart';
import '../../notification_subscription/controllers/subscription_controller.dart';
import '../controllers/dashboard_controller.dart';
import 'package:clevertalk/app/modules/home/views/home_view.dart';
import 'package:clevertalk/app/modules/audio/views/audio_view.dart';
import 'package:clevertalk/app/modules/setting/views/setting_view.dart';
import 'package:clevertalk/app/modules/profile/views/profile_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  Widget build(BuildContext context) {
    // Initialize the DashboardController as permanent
    final controller = Get.put(DashboardController(), permanent: true);
    final homeController = Get.put(HomeController());
    homeController.fetchProfileData();
    final subscriptionController = Get.put(SubscriptionController(), permanent: true);
    subscriptionController.fetchPackages();
    // Check for navigation argument and update index if provided
    if (Get.arguments != null && Get.arguments is int) {
      controller.updateIndex(Get.arguments as int);
    }

    final List<Widget> _screens = [
      const HomeView(),
      const AudioView(),
      const SettingView(),
      const ProfileView(),
    ];

    return Scaffold(
      backgroundColor: AppColors.appColor,
      body: Stack(
        children: [
          SafeArea(
            child: Obx(() => _screens[controller.currentIndex.value]),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: CustomNavigationBar(),
          ),
        ],
      ),
    );
  }
}