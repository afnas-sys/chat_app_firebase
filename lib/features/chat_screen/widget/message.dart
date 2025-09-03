// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:support_chat/utils/constants/app_colors.dart';

class Message extends StatefulWidget {
  const Message({super.key});

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {
  final ChatUser currentUser = ChatUser(id: "1", firstName: "Me");
  final ChatUser otherUser = ChatUser(id: "2", firstName: "Friend");

  List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();

    // Dummy messages
    messages = [
      ChatMessage(
        text: "Hey! How are you?",
        user: otherUser,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      ChatMessage(
        text: "I'm good, what about you?",
        user: currentUser,
        createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.fourthColor,
      child: DashChat(
        currentUser: currentUser,
        messages: messages,
        onSend: (ChatMessage m) {
          setState(() {
            messages.insert(0, m);
          });
        },
        messageOptions: MessageOptions(
          currentUserContainerColor: AppColors.fifthColor,
          containerColor: AppColors.primaryColor,
          textColor: AppColors.eighthColor,
          currentUserTextColor: AppColors.primaryColor,
        ),
        inputOptions: InputOptions(
          autocorrect: true,
          alwaysShowSend: false,
          sendButtonBuilder: (VoidCallback onSend) {
            return IconButton(
              onPressed: onSend,
              icon: Icon(Icons.send, size: 24, color: AppColors.ninthColor),
            );
          },
          inputDecoration: InputDecoration(
            hintText: "Write your message",
            filled: true,
            fillColor: AppColors.primaryColor,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 16,
            ),
            prefixIcon: IconButton(
              icon: Icon(
                FontAwesomeIcons.paperclip,
                color: AppColors.sixthColor,
                size: 24,
              ),
              onPressed: () {
                // Handle attach
              },
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        scrollToBottomOptions: const ScrollToBottomOptions(),
      ),
    );
  }
}
