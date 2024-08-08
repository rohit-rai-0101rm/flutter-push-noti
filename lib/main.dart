import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'notification.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final String? token = await FirebaseMessaging.instance.getToken();
  print('Token: $token');

  // Initialize Firebase Messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission for iOS
  if (Platform.isIOS) {
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Notification'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final NotificationSetUp _noti = NotificationSetUp();
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    getFcmTokenAndSendToServer();
    _noti.configurePushNotifications(context);
    _noti.eventListenerCallback(context);
  }

  Future<void> getFcmTokenAndSendToServer() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Retrieve the FCM token
    String? token = await messaging.getToken();

    if (token != null) {
      print("FCM Token: $token");

      // Send the token to your backend
      await sendTokenToServer(token);
    } else {
      print("Failed to get FCM token");
    }
  }

  Future<void> sendTokenToServer(String token) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.23:3000/save-token'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'token': token,
      }),
    );

    if (response.statusCode == 200) {
      print("Token successfully sent to server");
    } else {
      print("Failed to send token to server");
    }
  }

  Future<void> sendNotification() async {
    final String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      final response = await http.post(
        Uri.parse('http://192.168.1.23:3000/send-notification'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'token': token,
          'title': 'Title 30july',
          'body': 'Body 30july',
          'data': {'key1': 'value1', 'key2': 'value2'},
        }),
      );

      if (response.statusCode == 200) {
        print("Notification successfully sent");
      } else {
        print("Failed to send notification");
      }
    } else {
      print("Failed to get FCM token");
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // const Text('You have pushed the button this many times:'),
            // Text(
            //   '$_counter',
            //   style: Theme.of(context).textTheme.headlineMedium,
            // ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendNotification,
              child: const Text('Send Notification'),
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
