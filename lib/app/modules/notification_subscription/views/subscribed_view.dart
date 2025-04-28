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
              'Your Subscription',
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
                    'Plan: ${homeController.package_name.value}',
                    style: h2.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Type: ${homeController.package_type.value}',
                    style: h2.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Details:',
                    style: h2.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enjoy all premium features including unlimited recording, transcription in 36+ languages, and more.',
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
                      text: 'Upgrade',
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
                      text: 'Downgrade',
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
              text: 'Cancel',
              onPressed: () {
                print("Cancel button pressed");
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Cancel Subscription', style: h2),
                    content: Text(
                        'Are you sure you want to cancel your subscription?',
                        style: h3),
                    actions: [
                      TextButton(
                        onPressed: () {
                          print("Cancel dialog: No pressed");
                          Navigator.pop(context);
                        },
                        child: Text('No',
                            style: h2.copyWith(color: AppColors.appColor)),
                      ),
                      TextButton(
                        onPressed: () {
                          print("Cancel dialog: Yes pressed");
                          Navigator.pop(context);
                          controller.cancelSubscription();
                        },
                        child: Text('Yes',
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