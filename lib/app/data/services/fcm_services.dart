import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationServices1 {

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Background message handler
  Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Background message received: ${message.notification?.title}');
  }

  FirebaseMessaging messaging = FirebaseMessaging.instance;





  // void firebaseInit(){
  //   FirebaseMessaging.onMessage.listen((message) {
  //
  //   },);
  // }

  Future<String> getDeviceToken() async {
    String? token = await messaging.getToken();
    print('DEVICE token :::::::::::::::::::::::::::    $token');
    return token!;
  }



}