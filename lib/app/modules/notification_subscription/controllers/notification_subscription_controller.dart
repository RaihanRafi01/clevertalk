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

  // Function to add a new notification dynamically
  void addNotification(String jsonPayload) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonPayload);
      String? type = data['type'];
      String? message = data['message']; // Assuming message is passed
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
          isRead: false, // New notifications are unread by default
        ),
      );
    } catch (e) {
      print("Error parsing notification: $e");
    }
  }

  // Get unread notification count
  int getUnreadCount() {
    return notifications.where((notification) => !notification.isRead).length;
  }

  // Group notifications by date
  Map<String, List<NotificationModel>> groupNotificationsByDate() {
    Map<String, List<NotificationModel>> groupedNotifications = {};
    for (var notification in notifications) {
      groupedNotifications
          .putIfAbsent(notification.time, () => [])
          .add(notification);
    }
    return groupedNotifications;
  }

  // Mark all as read
  void markAllAsRead() {
    for (var notification in notifications) {
      notification.isRead = true; // Mark each notification as read
    }
    notifications.refresh(); // Trigger UI update
  }

  // Optional: Mark a single notification as read
  void markAsRead(int index) {
    if (index >= 0 && index < notifications.length) {
      notifications[index].isRead = true;
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
  bool isRead; // Added isRead property

  NotificationModel({
    required this.type,
    required this.message,
    required this.time,
    this.fileName,
    this.filePath,
    this.keyPoints,
    this.isRead = false, // Default to unread
  });
}