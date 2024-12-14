import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../controllers/notification_subscription_controller.dart';

class NotificationSubscriptionView extends GetView<NotificationSubscriptionController> {
  const NotificationSubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isSearch: true,
        title: "CLEVERTALK",
        onFirstIconPressed: () {
          // Action for the first button
          print("First icon pressed");
        },
        onSecondIconPressed: () {
          // Action for the second button
          print("Second icon pressed");
        },
      ),
      body: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today',
                    style: h4.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  NotificationCard(
                    message: 'Please reconnect your device within 2 days or your subscription pack will be canceled.',
                    time: '09:10 PM',
                  ),
                  NotificationCard(
                    message: 'Please reconnect your device within 2 days or your subscription pack will be canceled.',
                    time: '09:10 PM',
                  ),
                  NotificationCard(
                    message: 'Please reconnect your device within 2 days or your subscription pack will be canceled.',
                    time: '09:10 PM',
                  ),
                  NotificationCard(
                    message: 'Please reconnect your device within 2 days or your subscription pack will be canceled.',
                    time: '09:10 PM',
                  ),
                  NotificationCard(
                    message: 'Please reconnect your device within 2 days or your subscription pack will be canceled.',
                    time: '09:10 PM',
                  ),
                  NotificationCard(
                    message: 'Please reconnect your device within 2 days or your subscription pack will be canceled.',
                    time: '09:10 PM',
                  ),

                  const SizedBox(height: 20),
                  Text(
                    'Yesterday',
                    style: h4.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  NotificationCard(
                    message: 'We are currently offering a 10% discount on our device. When you purchase the device, you will also get free lifetime premium access to the app.',
                    time: '09:10 PM',
                  ),
                ],
              ),
            ),
          ),
          // Fixed button at the bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomButton(
              text: 'Read All',
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String message;
  final String time;

  const NotificationCard({Key? key, required this.message, required this.time})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.appColor2,
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: h4.copyWith(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                time,
                style: h4.copyWith(fontSize: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
