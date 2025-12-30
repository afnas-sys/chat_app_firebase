// ignore_for_file: public_member_api_docs, sort_constructors_first, must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/features/chat_screen/widget/chat_appbar.dart';
import 'package:support_chat/features/chat_screen/widget/message.dart';
import 'package:support_chat/providers/chat_provider.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/widgets/glass_container.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> userData;
  const ChatScreen({super.key, required this.userData});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  @override
  void initState() {
    super.initState();
    // Mark messages as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final receiverId = widget.userData['uid'];
      if (receiverId != null) {
        ref.read(chatServiceProvider).markAsRead(receiverId);
      }
    });
  }

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
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ChatAppbar(userData: widget.userData),
              const SizedBox(height: 14),
              Expanded(
                child: GlassContainer(
                  child: Message(
                    receiverId: widget.userData['uid'] ?? 'dummy_id',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
