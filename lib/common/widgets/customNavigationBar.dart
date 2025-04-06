import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../app/modules/dashboard/controllers/dashboard_controller.dart';
import '../appColors.dart';

class CustomNavigationBar extends StatelessWidget {
  final Function(int)? onItemTapped; // Optional callback for custom tap behavior

  const CustomNavigationBar({super.key, this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    // Simplified navigation items with a single icon
    final List<Map<String, String>> navItems = [
      {
        'label': 'Home',
        'icon': 'assets/images/navbar/home_icon.svg',
      },
      {
        'label': 'Recordings',
        'icon': 'assets/images/navbar/text_icon.svg',
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
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.transparent, // Transparent background
              borderRadius: BorderRadius.all(Radius.circular(50)),
            ),
            child: BottomNavigationBar(
              currentIndex: controller.currentIndex.value,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent, // Transparent background
              elevation: 0, // Removes shadow under navigation bar
              showSelectedLabels: true,
              showUnselectedLabels: false,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.black.withOpacity(0.6),
              selectedLabelStyle: const TextStyle(
                color: Colors.transparent, // Make selected label invisible
              ),
              unselectedLabelStyle: const TextStyle(
                color: Colors.transparent, // Make unselected label invisible
              ),
              onTap: (index) {
                // Use the custom onItemTapped callback if provided, otherwise use default behavior
                if (onItemTapped != null) {
                  onItemTapped!(index);
                } else {
                  controller.updateIndex(index);
                }
              },
              items: navItems.map((item) {
                return BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                    item['icon']!, // Use the single icon for all states
                    color: controller.currentIndex.value == navItems.indexOf(item)
                        ? Colors.black // Selected icon color: black
                        : Colors.black.withOpacity(0.6), // Unselected icon color: semi-transparent black
                    key: ValueKey('${item['label']}'), // Unique key for each icon
                  ),
                  label: item['label'],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}