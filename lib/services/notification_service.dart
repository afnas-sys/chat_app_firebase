// ignore_for_file: avoid_print

import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:support_chat/features/chat_screen/view/chat_screen.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? _navigatorKey;
  static String? activeChatId;

  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'High Importance Notifications';
  static const String _channelDesc =
      'This channel is used for important notifications.';

  Future<void> init(GlobalKey<NavigatorState> navKey) async {
    _navigatorKey = navKey;
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
        if (response.payload != null) {
          _handleMessageNavigation(response.payload!);
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
        print('Foreground message received: ${message.data}');
      }

      // Don't show notification if the user is already in this chat
      final messageChatId = message.data['chatId'];
      if (messageChatId != null && messageChatId == activeChatId) {
        if (kDebugMode) {
          print(
            'Suppressing notification: User is already in chat $messageChatId',
          );
        }
        return;
      }

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // If notification is null, we try to use data to build it
      String title =
          notification?.title ?? message.data['displayName'] ?? 'New Message';
      String body =
          notification?.body ??
          message.data['body'] ??
          'You have a new message';

      if (!kIsWeb) {
        try {
          _localNotifications.show(
            message.hashCode,
            title,
            body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channelId,
                _channelName,
                channelDescription: _channelDesc,
                importance: Importance.max,
                priority: Priority.high,
                icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: jsonEncode(message.data),
          );
        } catch (e) {
          if (kDebugMode) print('Error showing local notification: $e');
        }
      }
    });

    // 5. Handle background/terminated state when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('App opened from notification: ${message.notification?.title}');
      }
      _handleMessage(message);
    });

    // Check if app was opened from a terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // 6. Log the FCM token (Non-blocking)
    getToken();

    // 7. Listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
    });
  }

  Future<String?> getToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          log('FCM TOKEN: $token');
        }
        await _saveTokenToFirestore(token);
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (kDebugMode) {
        print('FCM Token synced with Firestore for user: ${user.uid}');
      }
    }
  }

  static void _handleMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat') {
      _handleNavigation(message.data);
    }
  }

  static void _handleMessageNavigation(String payload) {
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      _handleNavigation(data);
    } catch (e) {
      if (kDebugMode) print('Error decoding notification payload: $e');
    }
  }

  static void _handleNavigation(Map<String, dynamic> data) {
    if (_navigatorKey?.currentState == null) return;

    final String? chatId = data['chatId'];
    final String? receiverId = data['receiverId'];
    final bool isGroup = data['isGroup'] == 'true' || data['isGroup'] == true;
    final String? displayName = data['displayName'];

    if (chatId != null && receiverId != null) {
      _navigatorKey!.currentState!.push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            userData: {
              'uid': receiverId,
              'chatId': chatId,
              'isGroup': isGroup,
              'displayName': displayName ?? 'User',
            },
          ),
        ),
      );
    }
  }

  // Set up background handler (MUST be a top-level function)
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Background message received: ${message.notification?.title}');
    }
  }
}
