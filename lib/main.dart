import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/firebase_options.dart';
import 'package:support_chat/providers/auth_provider.dart';
import 'package:support_chat/utils/router/app_router.dart';
import 'package:support_chat/utils/router/routes_names.dart';
import 'package:support_chat/utils/constants/theme.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:support_chat/services/notification_service.dart';
import 'package:support_chat/services/connectivity_service.dart';
import 'package:support_chat/providers/reminder_provider.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'dart:async';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

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

    // Initialize Connectivity Service (Online/Offline Status)
    ConnectivityService().initialize();

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    if (kDebugMode) {
      print('Initialization error: $e');
    }
  }
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // White icons for Android
      statusBarBrightness: Brightness.dark, // White icons for iOS
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // White icons for Android
        statusBarBrightness: Brightness.dark, // White icons for iOS
      ),
      child: MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        title: 'ChatApp',
        theme: theme,
        builder: (context, child) {
          return GlobalReminderListener(child: child!);
        },
        onGenerateRoute: AppRouter.generateRoute,
        home: authState.when(
          data: (user) {
            if (user != null) {
              return const AuthGate();
            }
            return const AuthGate();
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, __) =>
              const Scaffold(body: Center(child: Text('Something went wrong'))),
        ),
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

class GlobalReminderListener extends ConsumerStatefulWidget {
  final Widget child;
  const GlobalReminderListener({super.key, required this.child});

  @override
  ConsumerState<GlobalReminderListener> createState() =>
      _GlobalReminderListenerState();
}

class _GlobalReminderListenerState
    extends ConsumerState<GlobalReminderListener> {
  Timer? _reminderTimer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _reminderTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkReminders();
    });
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }

  void _checkReminders() async {
    final auth = ref.read(authStateProvider).value;
    if (auth == null) return;

    final reminders = await ref
        .read(reminderServiceProvider)
        .getActiveReminders()
        .first;
    final now = DateTime.now();

    for (final reminder in reminders) {
      if (reminder.dateTime.isBefore(now) ||
          reminder.dateTime.isAtSameMomentAs(now)) {
        await ref.read(reminderServiceProvider).markAsShown(reminder.id);

        scaffoldMessengerKey.currentState?.showMaterialBanner(
          MaterialBanner(
            backgroundColor: AppColors.fifthColor,
            elevation: 10,
            content: Text(
              'REMINDER: ${reminder.message}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  scaffoldMessengerKey.currentState
                      ?.hideCurrentMaterialBanner();
                },
                child: const Text(
                  'DISMISS',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
