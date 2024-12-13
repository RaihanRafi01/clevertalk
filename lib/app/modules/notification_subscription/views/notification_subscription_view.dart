import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/notification_subscription_controller.dart';

class NotificationSubscriptionView
    extends GetView<NotificationSubscriptionController> {
  const NotificationSubscriptionView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NotificationSubscriptionView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'NotificationSubscriptionView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
