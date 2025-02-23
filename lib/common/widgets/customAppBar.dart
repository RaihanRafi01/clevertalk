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
      title: Text(
        title,
        style: h1.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (isSearch)
        // First SVG Icon Button
          IconButton(
            onPressed: onFirstIconPressed,
            icon: SvgPicture.asset(
              firstIcon,
              height: 24,
              width: 24,
            ),
          ),
        // Second SVG Icon Button with Badge
        Stack(
          children: [
            IconButton(
              onPressed: () async {
                print('notification pressed!');
                Get.to(() => NotificationSubscriptionView());
              },
              icon: SvgPicture.asset(
                secondIcon,
                height: 24,
                width: 24,
              ),
            ),
            // Badge with unread count
            Obx(() {
              final unreadCount = controller.getUnreadCount();
              if (unreadCount == 0) return const SizedBox.shrink(); // Hide badge if no unread notifications
              return Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black, // Customize badge color
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      '$unreadCount',
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
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}