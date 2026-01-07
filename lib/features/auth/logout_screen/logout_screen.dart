import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:support_chat/features/chat_screen/widget/custom_dialog.dart';
import 'package:support_chat/providers/auth_provider.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/app_text.dart';
import 'package:support_chat/utils/router/routes_names.dart';

class LogoutScreen extends ConsumerWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImage.appBg),
            fit: BoxFit.cover,
          ),
        ),
        child: CustomDialog(
          title: AppText.logoutDialogTitle,
          content: AppText.logoutDialogContent,
          button1Text: AppText.dialogCancel,
          button2Text: AppText.logoutDialogTitle,
          button2Icon: FontAwesomeIcons.rightFromBracket,
          button1Action: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RoutesNames.bottomBar,
              (_) => false,
            );
          },
          button2Action: () async {
            // Sign out from Firebase
            await ref.read(authNotifierProvider.notifier).signOut();

            // Navigate to login screen
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                RoutesNames.loginScreen,
                (_) => false,
              );
            }
          },
        ),
      ),
    );
  }
}
