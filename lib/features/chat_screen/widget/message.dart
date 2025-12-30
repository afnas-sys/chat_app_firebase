import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:support_chat/providers/auth_provider.dart';
import 'package:support_chat/providers/chat_provider.dart';
import 'package:support_chat/utils/constants/app_colors.dart';

class Message extends ConsumerWidget {
  final String receiverId;
  const Message({super.key, required this.receiverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final messagesAsync = ref.watch(chatMessagesProvider(receiverId));
    final chatService = ref.watch(chatServiceProvider);

    final currentUser = ChatUser(
      id: authState.value?.uid ?? '1',
      firstName: authState.value?.displayName ?? 'Me',
      profileImage: authState.value?.photoURL,
    );

    return Container(
      color: AppColors.fourthColor,
      child: messagesAsync.when(
        data: (messages) => DashChat(
          currentUser: currentUser,
          messages: messages,
          onSend: (ChatMessage m) {
            chatService.sendMessage(receiverId, m);
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
          scrollToBottomOptions: ScrollToBottomOptions(),
        ),
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.fifthColor),
        ),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
