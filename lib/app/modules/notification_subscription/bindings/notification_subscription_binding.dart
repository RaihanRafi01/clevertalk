import 'package:get/get.dart';

import '../controllers/notification_subscription_controller.dart';

class NotificationSubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationSubscriptionController>(
      () => NotificationSubscriptionController(),
    );
  }
}
