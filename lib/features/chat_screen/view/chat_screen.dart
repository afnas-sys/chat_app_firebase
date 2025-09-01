// ignore_for_file: public_member_api_docs, sort_constructors_first, must_be_immutable

import 'package:flutter/material.dart';
import 'package:support_chat/features/chat_screen/widget/chat_appbar.dart';
import 'package:support_chat/features/chat_screen/widget/message.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/widgets/glass_container.dart';

class ChatScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  const ChatScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImage.appBg),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 44),
            ChatAppbar(userData: userData),
            const SizedBox(height: 14),
            GlassContainer(child: Message()),
          ],
        ),
      ),
    );
  }
}
