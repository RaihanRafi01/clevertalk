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
        'label': 'home'.tr,
        'icon': 'assets/images/navbar/home_icon.svg',
      },
      {
        'label': 'recordings'.tr,
        'icon': 'assets/images/navbar/text_icon.svg',
      },
      {
        'label': 'settings'.tr,
        'icon': 'assets/images/navbar/setting_icon.svg',
      },
      {
        'label': 'profile'.tr,
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
              showSelectedLabels: false,
              showUnselectedLabels: false,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.black.withOpacity(0.6),
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
                    item['icon']!,
                    color: Colors.black.withOpacity(0.6), // Unselected icon color
                    key: ValueKey('${item['label']}_unselected'),
                  ),
                  activeIcon: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        item['icon']!,
                        color: Colors.black, // Selected icon color
                        key: ValueKey('${item['label']}_selected'),
                      ),

                      SizedBox(
                        //width: 220, // Restrict width to encourage wrapping
                        child: Text(
                          item['label']!,
                          style: const TextStyle(
                            color: Colors.black, // Selected label color
                            fontSize: 9,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2, // Allow up to two lines
                          overflow: TextOverflow.ellipsis, // Handle overflow
                        ),
                      ),
                    ],
                  ),
                  label: '', // Empty label to use custom Text widget
                  tooltip: item['label'], // Optional: Use label as tooltip
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}