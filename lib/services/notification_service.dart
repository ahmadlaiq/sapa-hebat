import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('🌙 Handling a background message: ${message.messageId}');
    print('🌙 Title: ${message.notification?.title}');
    print('🌙 Body: ${message.notification?.body}');
    print('🌙 Data: ${message.data}');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('✅ User granted permission');
      }
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      if (kDebugMode) {
        print('⚠️ User granted provisional permission');
      }
    } else {
      if (kDebugMode) {
        print('❌ User declined or has not accepted permission');
      }
    }

    // Get FCM Token
    String? token = await _messaging.getToken();
    if (kDebugMode) {
      print('🔥 FCM Token: $token');
    }

    // Handle token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print('🔄 New FCM Token: $newToken');
        // TODO: Save newToken to database if needed
      }
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('🔔 Got a message whilst in the foreground!');
        print('🔔 Title: ${message.notification?.title}');
        print('🔔 Body: ${message.notification?.body}');
        print('🔔 Data: ${message.data}');

        if (message.notification != null) {
          print('🔔 Message contained a notification: ${message.notification}');
        }
      }
    });

    // Handle notification open (from background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('📲 Notification caused app to open!');
        print('📲 Data: ${message.data}');
      }
    });
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // TODO: Replace with your actual Server Key from Firebase Console -> Project Settings -> Cloud Messaging (Legacy)
  static const String _serverKey = 'YOUR_SERVER_KEY_HERE';

  Future<void> sendNotification({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (tokens.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode(<String, dynamic>{
          'registration_ids': tokens,
          'notification': <String, dynamic>{'title': title, 'body': body},
          'data':
              data ??
              <String, dynamic>{
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'type': 'activity_update',
              },
          'priority': 'high',
        }),
      );

      if (kDebugMode) {
        print('📤 Sent notification status: ${response.statusCode}');
        print('📤 Response body: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending notification: $e');
      }
    }
  }
}
