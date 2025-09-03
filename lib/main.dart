import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/utils/router/app_router.dart';
import 'package:support_chat/utils/router/routes_names.dart';
import 'package:support_chat/utils/constants/theme.dart';

void main() {
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Support Chat',
      theme: theme,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: RoutesNames.bottomBar,
    );
  }
}
