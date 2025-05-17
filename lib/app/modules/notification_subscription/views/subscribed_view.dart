import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/subscription_controller.dart';
import 'subscription_view.dart';

class SubscribedView extends GetView<SubscriptionController> {
  const SubscribedView({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();

    return Scaffold(
      appBar: CustomAppBar(
        title: "CLEVERTALK",
        onFirstIconPressed: () {
          print("First icon pressed");
        },
        onSecondIconPressed: () {
          print("Second icon pressed");
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'your_subscription'.tr,
              style: h1.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'plan'.tr}${homeController.package_name.value}',
                    style: h2.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${'type'.tr}${homeController.package_type.value}',
                    style: h2.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'details_label'.tr,
                    style: h2.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'subscription_details'.tr,
                    style: h2.copyWith(fontSize: 14),
                  ),
                ],
              )),
            ),
            const SizedBox(height: 20),
            // Use Obx for allowedActions
            Obx(() {
              final allowedActions = controller.allowedActions.value;
              return Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'upgrade'.tr,
                      onPressed: allowedActions['upgrade']!
                          ? () {
                        print("Upgrade button pressed");
                        try {
                          Get.to(() => const SubscriptionView());
                          print("Navigated to SubscriptionView");
                        } catch (e) {
                          print("Navigation error: $e");
                        }
                      }
                          : null,
                      isDisabled: !allowedActions['upgrade']!,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'downgrade'.tr,
                      onPressed: allowedActions['downgrade']!
                          ? () {
                        print("Downgrade button pressed");
                        try {
                          Get.to(() => const SubscriptionView());
                          print("Navigated to SubscriptionView");
                        } catch (e) {
                          print("Navigation error: $e");
                        }
                      }
                          : null,
                      isDisabled: !allowedActions['downgrade']!,
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 20),
            CustomButton(
              text: 'cancel'.tr,
              onPressed: () {
                print("Cancel button pressed");
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('cancel_subscription'.tr, style: h2), // Localized dialog title
                    content: Text(
                        'cancel_subscription_confirm'.tr, // Localized dialog content
                        style: h3),
                    actions: [
                      TextButton(
                        onPressed: () {
                          print("Cancel dialog: No pressed");
                          Navigator.pop(context);
                        },
                        child: Text('no'.tr,
                            style: h2.copyWith(color: AppColors.appColor)),
                      ),
                      TextButton(
                        onPressed: () {
                          print("Cancel dialog: Yes pressed");
                          Navigator.pop(context);
                          controller.cancelSubscription();
                        },
                        child: Text('yes'.tr,
                            style: h2.copyWith(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}