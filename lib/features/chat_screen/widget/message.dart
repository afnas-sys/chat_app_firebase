import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:support_chat/main.dart';
import 'package:support_chat/providers/auth_provider.dart';
import 'package:support_chat/providers/chat_provider.dart';
import 'package:support_chat/services/cloudinary_service.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/features/chat_screen/view/full_screen_image.dart';
import 'package:support_chat/services/media_service.dart';

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
              onTapMedia: (ChatMedia media) async {
                if (media.type == MediaType.image) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImage(imageUrl: media.url),
                    ),
                  );
                } else if (media.type == MediaType.file) {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading ${media.fileName}...'),
                      ),
                    );

                    await ref
                        .read(mediaServiceProvider)
                        .downloadAndSaveMedia(
                          media.url,
                          media.fileName,
                          isImage: false,
                        );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${media.fileName} downloaded to Downloads folder!',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to download: $e')),
                      );
                    }
                  }
                }
              },
              messageTextBuilder: (message, previousMessage, nextMessage) {
                return SelectableText(
                  message.text,
                  style: TextStyle(
                    color: message.user.id == currentUser.id
                        ? AppColors.primaryColor
                        : AppColors.eighthColor,
                  ),
                );
              },
              onLongPressMessage: (ChatMessage message) {
                final isMe = message.user.id == currentUser.id;
                final messageId = message.customProperties?['id'];

                if (messageId == null) return;

                showModalBottomSheet(
                  context: context,
                  backgroundColor: AppColors.fifthColor,
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          title: const Text(
                            'Delete for me',
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            // Store old data for Undo?
                            // For "Delete for me", it's just updating "deletedFor" array.
                            // Undo means removing from that array.

                            try {
                              await chatService.deleteMessageForMe(
                                receiverId,
                                messageId,
                                isGroup: isGroup,
                              );

                              if (scaffoldMessengerKey.currentState != null) {
                                scaffoldMessengerKey.currentState!
                                    .hideCurrentSnackBar();
                                scaffoldMessengerKey.currentState!.showSnackBar(
                                  SnackBar(
                                    content: const Text('Message deleted'),
                                    duration: const Duration(minutes: 1),
                                    backgroundColor: AppColors.fifthColor,
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      textColor: Colors.white,
                                      onPressed: () async {
                                        // Restore logic
                                        // Removing currentUserId from deletedFor
                                        final currentUserId = ref
                                            .read(authStateProvider)
                                            .value!
                                            .uid;
                                        await ref
                                            .read(chatServiceProvider)
                                            .restoreMessageForMe(
                                              receiverId,
                                              messageId,
                                              currentUserId,
                                              isGroup: isGroup,
                                            );
                                      },
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (scaffoldMessengerKey.currentState != null) {
                                scaffoldMessengerKey.currentState!.showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                        ),
                        if (isMe)
                          ListTile(
                            leading: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            title: const Text(
                              'Delete for everyone',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () async {
                              Navigator.pop(context);

                              try {
                                // We need to capture the current document data to restore it
                                final chatId = isGroup
                                    ? receiverId
                                    : ref
                                          .read(chatServiceProvider)
                                          .getChatId(
                                            currentUser.id,
                                            receiverId,
                                          );
                                final doc = await FirebaseFirestore.instance
                                    .collection('chats')
                                    .doc(chatId)
                                    .collection('messages')
                                    .doc(messageId)
                                    .get();
                                final oldData = doc.data();

                                await chatService.deleteMessageForEveryone(
                                  receiverId,
                                  messageId,
                                  isGroup: isGroup,
                                );

                                if (scaffoldMessengerKey.currentState != null &&
                                    oldData != null) {
                                  scaffoldMessengerKey.currentState!
                                      .hideCurrentSnackBar();
                                  scaffoldMessengerKey.currentState!
                                      .showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Message deleted for all',
                                          ),
                                          duration: const Duration(minutes: 1),
                                          backgroundColor: AppColors.fifthColor,
                                          action: SnackBarAction(
                                            label: 'Undo',
                                            textColor: Colors.white,
                                            onPressed: () async {
                                              await ref
                                                  .read(chatServiceProvider)
                                                  .restoreMessage(
                                                    receiverId,
                                                    messageId,
                                                    oldData,
                                                    isGroup: isGroup,
                                                  );
                                            },
                                          ),
                                        ),
                                      );
                                }
                              } catch (e) {
                                if (scaffoldMessengerKey.currentState != null) {
                                  scaffoldMessengerKey.currentState!
                                      .showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
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
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            color: AppColors.fifthColor,
                          ),
                          child: Wrap(
                            runSpacing: 6,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: AppColors.fourteenthColor,
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.camera_alt,
                                    color: AppColors.primaryColor,
                                  ),
                                  title: const Text(
                                    'Camera',
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
                                    ),
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
                                      final url = await service.uploadFile(
                                        file,
                                      );
                                      if (url != null) {
                                        final message = ChatMessage(
                                          user: currentUser,
                                          createdAt: DateTime.now(),
                                          medias: [
                                            ChatMedia(
                                              url: url,
                                              fileName: file.path
                                                  .split('/')
                                                  .last,
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
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: AppColors.fourteenthColor,
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.photo,
                                    color: AppColors.primaryColor,
                                  ),
                                  title: const Text(
                                    'Gallery',
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
                                    ),
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
                                      final url = await service.uploadFile(
                                        file,
                                      );
                                      if (url != null) {
                                        final message = ChatMessage(
                                          user: currentUser,
                                          createdAt: DateTime.now(),
                                          medias: [
                                            ChatMedia(
                                              url: url,
                                              fileName: file.path
                                                  .split('/')
                                                  .last,
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
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: AppColors.fourteenthColor,
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.attach_file,
                                    color: AppColors.primaryColor,
                                  ),
                                  title: const Text(
                                    'File',
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final service = ref.read(
                                      cloudinaryServiceProvider,
                                    );
                                    final File? file = await service.pickFile();
                                    if (file != null) {
                                      final url = await service.uploadFile(
                                        file,
                                      );
                                      if (url != null) {
                                        final message = ChatMessage(
                                          user: currentUser,
                                          createdAt: DateTime.now(),
                                          medias: [
                                            ChatMedia(
                                              url: url,
                                              fileName: file.path
                                                  .split('/')
                                                  .last,
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
                              ),
                            ],
                          ),
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
              inputTextStyle: TextStyle(color: AppColors.eighthColor),
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
