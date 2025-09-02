import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:support_chat/features/chat_screen/widget/custom_dialog.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/app_text.dart';
import 'package:support_chat/utils/router/routes_names.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          title: 'Logout',
          content: 'are you sure you want to log out?',
          button1Text: AppText.dialogCancel,
          button2Text: 'Logout',
          button2Icon: FontAwesomeIcons.rightFromBracket,
          button1Action: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RoutesNames.homeScreen,
              (_) => false,
            );
          },
          button2Action: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RoutesNames.loginScreen,
              (_) => false,
            );
          },
        ),
      ),
    );
  }
}
