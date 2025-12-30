import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/firebase_options.dart';
import 'package:support_chat/providers/auth_provider.dart';
import 'package:support_chat/utils/router/app_router.dart';
import 'package:support_chat/utils/router/routes_names.dart';
import 'package:support_chat/utils/constants/theme.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:support_chat/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.handleBackgroundMessage(message);
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Notification Service
    final notificationService = NotificationService();
    await notificationService.init();

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    if (kDebugMode) {
      print('Initialization error: $e');
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChatApp',
      theme: theme,
      onGenerateRoute: AppRouter.generateRoute,
      home: authState.when(
        data: (user) {
          if (user != null) {
            // User is logged in
            // Return a wrapper that builds the Home/BottomBar screen
            // or just the screen itself if it's not managed by the router here
            // but we want to use the router usually.
            // For simplicity and to keep the router working:
            return const AuthGate();
          }
          return const AuthGate(); // Both cases handled inside AuthGate
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) =>
            const Scaffold(body: Center(child: Text('Something went wrong'))),
      ),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // You might need to import your actual Home/BottomBar widget here
          // For now, I'll direct to the view corresponding to RoutesNames.bottomBar
          // but usually you'd return the widget itself.
          return AppRouter.getWidgetForRoute(RoutesNames.bottomBar);
        } else {
          return AppRouter.getWidgetForRoute(RoutesNames.loginScreen);
        }
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
