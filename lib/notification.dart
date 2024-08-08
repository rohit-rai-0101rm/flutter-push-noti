import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationSetUp {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initializeNotification() async {
    AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'high_importance_channel',
        channelName: 'Chat notifications',
        importance: NotificationImportance.Max,
        vibrationPattern: highVibrationPattern,
        channelShowBadge: true,
        channelDescription: 'Chat notifications.',
      ),
    ]);

    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  void configurePushNotifications(BuildContext context) async {
    await initializeNotification();

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (Platform.isIOS) getIOSPermission();

    FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("Received message: ${message.messageId}");
      if (message.notification != null) {
        // Notification details are available
        print("Notification Title: ${message.notification!.title}");
        print("Notification Body: ${message.notification!.body}");
        await createOrderNotifications(
          title: message.notification!.title,
          body: message.notification!.body,
        );
      }
      if (message.data.isNotEmpty) {
        // Data payload is available
        print("Data Payload: ${message.data}");
      }
    });
  }

  Future<void> createOrderNotifications({String? title, String? body}) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'high_importance_channel',
        title: title ?? "Notification",
        body: body ?? "",
      ),
    );
    print('Created notification with title: $title and body: $body');
  }

  void eventListenerCallback(BuildContext context) {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    );
  }

  void getIOSPermission() {
    _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }
}

@pragma("vm:entry-point")
Future<dynamic> myBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class NotificationController {
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedNotification receivedNotification) async {
    // Handle notification action
    print("Notification action received: ${receivedNotification.payload}");
  }
}
