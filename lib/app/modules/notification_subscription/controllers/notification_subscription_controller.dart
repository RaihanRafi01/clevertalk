import 'package:get/get.dart';
import 'dart:convert';

class NotificationSubscriptionController extends GetxController {
  var notifications = <NotificationModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications(); // Load stored notifications (if needed)
  }

  void loadNotifications() {
    // In a real-world app, fetch from local storage or API
    notifications.value = [];
  }

  void addNotification(String jsonPayload) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonPayload);
      String? type = data['type'];
      String? message = data['message'];
      String? time = data['time'] ?? "Just now";
      String? fileName = data['fileName'];
      String? filePath = data['filePath'];
      String? keyPoints = data['keyPoints'];

      notifications.insert(
        0,
        NotificationModel(
          type: type ?? "General",
          message: message ?? "New notification received",
          time: time!,
          fileName: fileName,
          filePath: filePath,
          keyPoints: keyPoints,
          isRead: false,
        ),
      );
    } catch (e) {
      print("Error parsing notification: $e");
    }
  }

  int getUnreadCount() {
    return notifications.where((notification) => !notification.isRead).length;
  }

  Map<String, List<NotificationModel>> groupNotificationsByDate() {
    Map<String, List<NotificationModel>> groupedNotifications = {};
    for (var notification in notifications) {
      groupedNotifications
          .putIfAbsent(notification.time, () => [])
          .add(notification);
    }
    return groupedNotifications;
  }

  void markAllAsRead() {
    for (var notification in notifications) {
      notification.isRead = true;
    }
    notifications.refresh();
  }

  void markAsRead(int index) {
    if (index >= 0 && index < notifications.length) {
      notifications[index].isRead = true;
      notifications.refresh();
    }
  }

  // New method to delete a notification
  void deleteNotification(int index) {
    if (index >= 0 && index < notifications.length) {
      notifications.removeAt(index);
      notifications.refresh(); // Trigger UI update
    }
  }
}

class NotificationModel {
  final String type;
  final String message;
  final String time;
  final String? fileName;
  final String? filePath;
  final String? keyPoints;
  bool isRead;

  NotificationModel({
    required this.type,
    required this.message,
    required this.time,
    this.fileName,
    this.filePath,
    this.keyPoints,
    this.isRead = false,
  });
}