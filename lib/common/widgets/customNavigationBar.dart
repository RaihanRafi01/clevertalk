import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../app/modules/dashboard/controllers/dashboard_controller.dart';
import '../appColors.dart';

class CustomNavigationBar extends StatelessWidget {
  const CustomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    // Simplified navigation items with a single icon
    final List<Map<String, String>> navItems = [
      {
        'label': 'Home',
        'icon': 'assets/images/navbar/home_icon.svg',
      },
      /*{
        'label': 'Text',
        'icon': 'assets/images/navbar/text_icon.svg',
      },*/
      {
        'label': 'Audio',
        'icon': 'assets/images/navbar/audio_icon.svg',
      },
      {
        'label': 'Setting',
        'icon': 'assets/images/navbar/setting_icon.svg',
      },
      {
        'label': 'Profile',
        'icon': 'assets/images/navbar/profile_icon.svg',
      },
    ];

    return Obx(
          () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.appColor,
            borderRadius: const BorderRadius.all(Radius.circular(50)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent, // Transparent background
            elevation: 0, // Removes shadow under navigation bar
            showSelectedLabels: true,
            showUnselectedLabels: false,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withOpacity(0.6),
            onTap: controller.updateIndex,
            items: navItems.map((item) {
              return BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  item['icon']!, // Use the single icon for all states
                  color: controller.currentIndex.value == navItems.indexOf(item)
                      ? Colors.white
                      : Colors.white.withOpacity(0.6), // Highlight selected icon
                  key: ValueKey('${item['label']}'), // Unique key for each icon
                ),
                label: item['label'],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
