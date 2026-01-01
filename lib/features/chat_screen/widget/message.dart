import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:support_chat/providers/auth_provider.dart';
import 'package:support_chat/providers/chat_provider.dart';
import 'package:support_chat/utils/constants/app_colors.dart';

class Message extends ConsumerWidget {
  final String receiverId;
  const Message({super.key, required this.receiverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // USER REQUEST: Auto-mark as read whenever new messages arrive while chat is open
    ref.listen(chatMessagesProvider(receiverId), (previous, next) {
      if (next is AsyncData && next.value != null) {
        ref.read(chatServiceProvider).markAsRead(receiverId);
      }
    });

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
        data: (messages) => RefreshIndicator(
          onRefresh: () async {
            // Manual refresh of the provider
            ref.invalidate(chatMessagesProvider(receiverId));
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppColors.fifthColor,
          backgroundColor: AppColors.primaryColor,
          child: DashChat(
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
              showTime: true,
              timeFormat: DateFormat('hh:mm a'),
              bottom:
                  (
                    ChatMessage message,
                    ChatMessage? previousMessage,
                    ChatMessage? nextMessage,
                  ) {
                    final isMe = message.user.id == currentUser.id;
                    if (!isMe) {
                      return const SizedBox.shrink();
                    }

                    // Status Ticks logic
                    Widget statusIcon;
                    switch (message.status) {
                      case MessageStatus.read:
                        statusIcon = const Icon(
                          Icons.done_all,
                          size: 16,
                          color: Colors.blue,
                        );
                        break;
                      case MessageStatus.received:
                        statusIcon = const Icon(
                          Icons.done_all,
                          size: 16,
                          color: Colors.grey,
                        );
                        break;
                      case MessageStatus.pending:
                      default:
                        statusIcon = const Icon(
                          Icons.done,
                          size: 16,
                          color: Colors.grey,
                        );
                        break;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 2, right: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('hh:mm a').format(message.createdAt),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          statusIcon,
                        ],
                      ),
                    );
                  },
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
