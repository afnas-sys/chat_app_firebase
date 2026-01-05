// ignore_for_file: avoid_print

import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'High Importance Notifications';
  static const String _channelDesc =
      'This channel is used for important notifications.';

  Future<void> init() async {
    // 1. Request permissions (especially for iOS)
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
        print('User granted permission');
      }
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      if (kDebugMode) {
        print('User granted provisional permission');
      }
    } else {
      if (kDebugMode) {
        print('User declined or has not accepted permission');
      }
    }

    // 2. Initialize local notifications for Android foreground
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings (no special settings needed usually for default)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle when user taps on a local notification
        if (kDebugMode) {
          print('Local notification tapped: ${response.payload}');
        }
      },
    );

    // 3. Create Android notification channel
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }

    // 4. Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Foreground message received: ${message.notification?.title}');
      }

      // Show local notification even in foreground
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDesc,
              importance: Importance.max,
              priority: Priority.high,
              icon: android.smallIcon ?? '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // 5. Handle background/terminated state when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('App opened from notification: ${message.notification?.title}');
      }
      // Navigate to specific screen if needed
    });

    // 6. Log the FCM token (Non-blocking)
    getToken();
  }

  Future<String?> getToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          log('FCM TOKEN: $token');
        }

        // Sync token with Firestore if user is logged in
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'fcmToken': token,
                'lastTokenUpdate': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
          if (kDebugMode) {
            print('FCM Token synced with Firestore for user: ${user.uid}');
          }
        }
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  // Set up background handler (MUST be a top-level function)
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Background message received: ${message.notification?.title}');
    }
  }
}
