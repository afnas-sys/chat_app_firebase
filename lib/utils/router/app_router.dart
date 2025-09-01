import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:support_chat/features/home_screen/view/home_screen.dart';
import 'package:support_chat/features/login_screen/login_screen.dart';
import 'package:support_chat/utils/router/routes_names.dart';
import 'package:support_chat/utils/widgets/custom_bottom_bar.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutesNames.loginScreen:
        return _buildPageTransition(
          const LoginScreen(),
          settings,
          PageTransitionType.fade,
        );
      case RoutesNames.bottomBar:
        return _buildPageTransition(
          const CustomBottomBar(),
          settings,
          PageTransitionType.fade,
        );
      case RoutesNames.homeScreen:
        return _buildPageTransition(
          const HomeScreen(),
          settings,
          PageTransitionType.fade,
        );
      default:
        return _buildPageTransition(
          const LoginScreen(),
          settings,
          PageTransitionType.fade,
        );
    }
  }

  static PageTransition _buildPageTransition(
    Widget page,
    RouteSettings settings,
    PageTransitionType type,
  ) {
    return PageTransition(
      child: page,
      type: type,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
      settings: settings,
    );
  }
}
