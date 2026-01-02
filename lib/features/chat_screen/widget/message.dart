import 'dart:io';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:support_chat/providers/auth_provider.dart';
import 'package:support_chat/providers/chat_provider.dart';
import 'package:support_chat/services/cloudinary_service.dart';
import 'package:support_chat/utils/constants/app_colors.dart';

class Message extends ConsumerWidget {
  final String receiverId;
  final bool isGroup;

  const Message({super.key, required this.receiverId, this.isGroup = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // USER REQUEST: Auto-mark as read whenever new messages arrive while chat is open
    final chatParams = ChatParams(receiverId: receiverId, isGroup: isGroup);

    ref.listen(chatMessagesProvider(chatParams), (previous, next) {
      if (next is AsyncData && next.value != null) {
        // Only mark as read for 1-on-1 for now? Or handle groups if implemented.
        // chatService.markAsRead(chatParams.receiverId); // markAsRead implementation needs check
        ref.read(chatServiceProvider).markAsRead(receiverId, isGroup: isGroup);
      }
    });

    final authState = ref.watch(authStateProvider);
    final messagesAsync = ref.watch(chatMessagesProvider(chatParams));
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
            ref.invalidate(chatMessagesProvider(chatParams));
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppColors.fifthColor,
          backgroundColor: AppColors.primaryColor,
          child: DashChat(
            currentUser: currentUser,
            messages: messages,
            onSend: (ChatMessage m) {
              chatService.sendMessage(receiverId, m, isGroup: isGroup);
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
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppColors.fourthColor,
                      builder: (context) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.camera_alt,
                                color: AppColors.fifthColor,
                              ),
                              title: const Text(
                                'Camera',
                                style: TextStyle(color: AppColors.primaryColor),
                              ),
                              onTap: () async {
                                Navigator.pop(context);
                                final service = ref.read(
                                  cloudinaryServiceProvider,
                                );
                                final File? file = await service.pickImage(
                                  ImageSource.camera,
                                );
                                if (file != null) {
                                  final url = await service.uploadFile(file);
                                  if (url != null) {
                                    final message = ChatMessage(
                                      user: currentUser,
                                      createdAt: DateTime.now(),
                                      medias: [
                                        ChatMedia(
                                          url: url,
                                          fileName: file.path.split('/').last,
                                          type: MediaType.image,
                                        ),
                                      ],
                                    );
                                    chatService.sendMessage(
                                      receiverId,
                                      message,
                                      isGroup: isGroup,
                                    );
                                  }
                                }
                              },
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.photo,
                                color: AppColors.fifthColor,
                              ),
                              title: const Text(
                                'Gallery',
                                style: TextStyle(color: AppColors.primaryColor),
                              ),
                              onTap: () async {
                                Navigator.pop(context);
                                final service = ref.read(
                                  cloudinaryServiceProvider,
                                );
                                final File? file = await service.pickImage(
                                  ImageSource.gallery,
                                );
                                if (file != null) {
                                  final url = await service.uploadFile(file);
                                  if (url != null) {
                                    final message = ChatMessage(
                                      user: currentUser,
                                      createdAt: DateTime.now(),
                                      medias: [
                                        ChatMedia(
                                          url: url,
                                          fileName: file.path.split('/').last,
                                          type: MediaType.image,
                                        ),
                                      ],
                                    );
                                    chatService.sendMessage(
                                      receiverId,
                                      message,
                                      isGroup: isGroup,
                                    );
                                  }
                                }
                              },
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.attach_file,
                                color: AppColors.fifthColor,
                              ),
                              title: const Text(
                                'File',
                                style: TextStyle(color: AppColors.primaryColor),
                              ),
                              onTap: () async {
                                Navigator.pop(context);
                                final service = ref.read(
                                  cloudinaryServiceProvider,
                                );
                                final File? file = await service.pickFile();
                                if (file != null) {
                                  final url = await service.uploadFile(file);
                                  if (url != null) {
                                    final message = ChatMessage(
                                      user: currentUser,
                                      createdAt: DateTime.now(),
                                      medias: [
                                        ChatMedia(
                                          url: url,
                                          fileName: file.path.split('/').last,
                                          type: MediaType.file,
                                        ),
                                      ],
                                    );
                                    chatService.sendMessage(
                                      receiverId,
                                      message,
                                      isGroup: isGroup,
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
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
