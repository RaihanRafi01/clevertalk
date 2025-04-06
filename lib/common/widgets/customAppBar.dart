import 'package:clevertalk/app/modules/notification_subscription/controllers/notification_subscription_controller.dart';
import 'package:clevertalk/app/modules/notification_subscription/views/notification_subscription_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../app/data/services/notification_services.dart';
import '../../app/modules/authentication/views/forgot_password_view.dart';
import '../customFont.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String firstIcon;
  final String secondIcon;
  final VoidCallback onFirstIconPressed;
  final VoidCallback onSecondIconPressed;
  final bool isSearch;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.isSearch = false,
    this.firstIcon = 'assets/images/home/search_icon.svg',
    this.secondIcon = 'assets/images/settings/notification_icon.svg',
    required this.onFirstIconPressed,
    required this.onSecondIconPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the NotificationSubscriptionController instance
    final NotificationSubscriptionController controller =
    Get.find<NotificationSubscriptionController>();

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSearch)
            // First Icon with GestureDetector
              GestureDetector(
                onTap: onFirstIconPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 8), // Adjust padding
                  child: SvgPicture.asset(
                    firstIcon,
                    height: 17,
                    width: 17,
                  ),
                ),
              ),
            // Second Icon with Badge
            Stack(
              children: [
                GestureDetector(
                  onTap: () async {
                    print('notification pressed!');
                    Get.to(() => NotificationSubscriptionView());
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 8), // Adjust padding
                    child: SvgPicture.asset(
                      secondIcon,
                      height: 17,
                      width: 17,
                    ),
                  ),
                ),
                // Badge with unread count
                Obx(() {
                  final unreadCount = controller.getUnreadCount();
                  if (unreadCount == 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
        const SizedBox(width: 8), // Optional: Add some padding to the right of the last icon
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}