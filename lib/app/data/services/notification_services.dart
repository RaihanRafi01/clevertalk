/*
import 'package:clevertalk/app/modules/profile/views/profile_view.dart';
import 'package:clevertalk/app/modules/text/views/convert_to_text_view.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'dart:convert'; // Import for JSON encoding/decoding

import '../../modules/audio/views/summary_key_point_view.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize the notification service
  static Future<void> initialize() async {
    await requestNotificationPermission();

    // Android Initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    // Initialize the plugin
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          print("Notification Clicked: ${response.payload}");
          _handleNotificationClick(response.payload!);
        }
      },
    );
  }

  /// Request Notification Permission
  static Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      print('Notification permission granted');
    } else if (status.isDenied) {
      print('Notification permission denied.');
    } else if (status.isPermanentlyDenied) {
      print('Notification permission permanently denied. Open settings.');
      openAppSettings();
    }
  }

  /// Show notification with payload (Now handles keyPoints and fileName)
  static Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload, // Used to determine navigation
    String? keyPoints,
    String? fileName,
  }) async {
    // Create a JSON object as payload if keyPoints and fileName exist
    String jsonPayload = jsonEncode({
      'type': payload,
      'keyPoints': keyPoints,
      'fileName': fileName,
    });

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'channel_id_one', // Ensure this matches the channel ID in Manifest
      'Default Channel',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(id, title, body, details,
        payload: jsonPayload);
  }

  /// Handle notification click using GetX
  static void _handleNotificationClick(String payload) {
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      String? type = data['type'];
      String? keyPoints = data['keyPoints'];
      String? fileName = data['fileName'];

      if (type == "notification_page") {
        Get.to(ProfileView());
      } else if (type == "Summary") {
        Get.to(() => SummaryKeyPointView(
              keyPoints: keyPoints ?? "No Key Points",
              fileName: fileName ?? "Unknown File",
            ));
      } else if (type == "Conversion") {
        Get.to(() => ConvertToTextView(
              filePath: keyPoints ?? "No file path",
              fileName: fileName ?? "Unknown File",
            ));
      } else {
        print("Unknown payload type: $type");
      }
    } catch (e) {
      print("Error parsing notification payload: $e");
    }
  }
}
*/


import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

import '../../modules/audio/views/summary_key_point_view.dart';
import '../../modules/notification_subscription/controllers/notification_subscription_controller.dart';
import '../../modules/profile/views/profile_view.dart';
import '../../modules/text/views/convert_to_text_view.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await requestNotificationPermission();
    Get.put(NotificationSubscriptionController());
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          print("Notification Clicked: ${response.payload}");
          _handleNotificationClick(response.payload!);
        }
      },
    );
  }

  static Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      print('Notification permission granted');
    } else if (status.isDenied) {
      print('Notification permission denied.');
    } else if (status.isPermanentlyDenied) {
      print('Notification permission permanently denied. Open settings.');
      openAppSettings();
    }
  }

  static Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
    String? keyPoints,
    String? fileName,
    String? filePath,
  }) async {
    // Generate payload
    String jsonPayload = jsonEncode({
      'type': payload,
      'message': body,
      'time': DateTime.now().toLocal().toString().substring(11, 16), // HH:MM format
      'keyPoints': keyPoints,
      'fileName': fileName,
      'filePath': filePath,
    });

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel_id_one',
      'Default Channel',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    // Show notification in system tray
    await _notificationsPlugin.show(id, title, body, details, payload: jsonPayload);

    // **Update the UI with new notification**
    if (Get.isRegistered<NotificationSubscriptionController>()) {

      Get.find<NotificationSubscriptionController>().addNotification(jsonPayload);
    } else {
      print("NotificationSubscriptionController is not registered");
    }
  }


  static void _handleNotificationClick(String payload) {
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      String? type = data['type'];
      String? fileName = data['fileName'];
      String? filePath = data['filePath'];



      if (type == "notification_page") {
        Get.to(ProfileView());
      } else if (type == "Summary") {
        print('REGENERATE noti ::::: filePath ::::::::: $filePath');
        print('REGENERATE noti ::::: fileName ::::::::: $fileName');
        Get.to(() => SummaryKeyPointView(
          //keyPoints: keyPoints ?? "No Key Points",
          fileName: fileName ?? "Unknown File",
          filePath: filePath ?? "Unknown FilePath",
        ));
      } else if (type == "Conversion") {
        Get.to(() => ConvertToTextView(
          filePath: filePath ?? "No file path",
          fileName: fileName ?? "Unknown File",
        ));
      } else {
        print("Unknown payload type: $type");
      }
    } catch (e) {
      print("Error parsing notification payload: $e");
    }
  }
}

