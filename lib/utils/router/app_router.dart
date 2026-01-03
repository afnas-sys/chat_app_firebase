import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:support_chat/features/home_screen/view/home_screen.dart';
import 'package:support_chat/features/login_screen/login_screen.dart';
import 'package:support_chat/features/register_screen/register_screen.dart';
import 'package:support_chat/features/forgot_password_screen/forgot_password_screen.dart';
import 'package:support_chat/features/home_screen/view/profile_screen.dart';
import 'package:support_chat/features/group_screen.dart/create_group_screen.dart';
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
      case RoutesNames.registerScreen:
        return _buildPageTransition(
          const RegisterScreen(),
          settings,
          PageTransitionType.fade,
        );
      case RoutesNames.forgotPasswordScreen:
        return _buildPageTransition(
          const ForgotPasswordScreen(),
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
      case RoutesNames.profileScreen:
        return _buildPageTransition(
          const ProfileScreen(),
          settings,
          PageTransitionType.fade,
        );
      case RoutesNames.createGroupScreen:
        return _buildPageTransition(
          const CreateGroupScreen(),
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

  static Widget getWidgetForRoute(String routeName) {
    switch (routeName) {
      case RoutesNames.loginScreen:
        return const LoginScreen();
      case RoutesNames.registerScreen:
        return const RegisterScreen();
      case RoutesNames.forgotPasswordScreen:
        return const ForgotPasswordScreen();
      case RoutesNames.bottomBar:
        return const CustomBottomBar();
      case RoutesNames.homeScreen:
        return const HomeScreen();
      case RoutesNames.profileScreen:
        return const ProfileScreen();
      case RoutesNames.createGroupScreen:
        return const CreateGroupScreen();
      default:
        return const LoginScreen();
    }
  }
}
