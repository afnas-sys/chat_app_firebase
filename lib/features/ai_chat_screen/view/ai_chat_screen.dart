import 'dart:io';
import 'dart:typed_data';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:support_chat/services/gemini_service.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/theme.dart';
import 'package:support_chat/providers/auth_provider.dart';

import 'package:flutter_markdown/flutter_markdown.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final ChatUser _geminiUser = ChatUser(
    id: '2',
    firstName: 'Gemini',
    profileImage: 'assets/images/chatting.png',
  );

  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages.insert(
      0,
      ChatMessage(
        text: "Hello! I'm Gemini AI. How can I help you today?",
        user: _geminiUser,
        createdAt: DateTime.now(),
      ),
    );
  }

  void _sendMessage(ChatMessage chatMessage) async {
    setState(() {
      _messages.insert(0, chatMessage);
    });

    String response = '';
    if (chatMessage.medias != null && chatMessage.medias!.isNotEmpty) {
      List<Uint8List> images = [];
      for (var media in chatMessage.medias!) {
        if (media.type == MediaType.image) {
          final file = File(media.url);
          images.add(await file.readAsBytes());
        }
      }
      response = await ref
          .read(geminiServiceProvider)
          .getResponseWithImage(chatMessage.text, images);
    } else {
      response = await ref
          .read(geminiServiceProvider)
          .getResponse(chatMessage.text);
    }

    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          text: response,
          user: _geminiUser,
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _pickImage(ChatUser user) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ChatMessage message = ChatMessage(
        text: "What is in this image?",
        user: user,
        createdAt: DateTime.now(),
        medias: [
          ChatMedia(
            url: image.path,
            fileName: image.name,
            type: MediaType.image,
          ),
        ],
      );
      _sendMessage(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserData = ref.watch(currentUserDataProvider);

    return currentUserData.when(
      data: (data) {
        final user = ChatUser(
          id: data?['uid'] ?? '1',
          firstName: data?['name'] ?? 'User',
          profileImage: data?['photoURL'] ?? data?['image'],
        );
        return _buildChat(user);
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildChat(ChatUser user) {
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
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Text(
                      'AI Assistant',
                      style: Theme.of(context).textTheme.titleLargePrimary,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.image,
                        color: AppColors.primaryColor,
                      ),
                      onPressed: () => _pickImage(user),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: DashChat(
                  currentUser: user,
                  onSend: _sendMessage,
                  messages: _messages,
                  messageOptions: MessageOptions(
                    showOtherUsersAvatar: true,
                    showTime: true,
                    containerColor: AppColors.fifthColor,
                    textColor: Colors.white,
                    currentUserContainerColor: AppColors.primaryColor,
                    currentUserTextColor: AppColors
                        .eighthColor, // Using eighthColor for black text
                    messageTextBuilder:
                        (
                          ChatMessage message,
                          ChatMessage? previousMessage,
                          ChatMessage? nextMessage,
                        ) {
                          bool isMine = message.user.id == user.id;
                          return MarkdownBody(
                            data: message.text,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                color: isMine ? Colors.black : Colors.white,
                                fontSize: 15,
                              ),
                              strong: TextStyle(
                                color: isMine ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              h1: TextStyle(
                                color: isMine ? Colors.black : Colors.white,
                              ),
                              h2: TextStyle(
                                color: isMine ? Colors.black : Colors.white,
                              ),
                              h3: TextStyle(
                                color: isMine ? Colors.black : Colors.white,
                              ),
                              listBullet: TextStyle(
                                color: isMine ? Colors.black : Colors.white,
                              ),
                            ),
                          );
                        },
                  ),
                  inputOptions: InputOptions(
                    alwaysShowSend: true,
                    sendButtonBuilder: (onSend) => IconButton(
                      icon: Icon(Icons.send, color: AppColors.fifthColor),
                      onPressed: onSend,
                    ),
                    inputDecoration: InputDecoration(
                      hintText: 'Ask Gemini anything...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: AppColors.fourthColor,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: AppColors.fifthColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: AppColors.fifthColor),
                      ),
                    ),
                    trailing: [],
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
