// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:support_chat/features/chat_screen/view/chat_screen.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatTile extends StatelessWidget {
  final List<Map<String, dynamic>> datas;
  final VoidCallback? onChatClosed;
  const ChatTile({super.key, required this.datas, required this.onChatClosed});

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "";

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return "";
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateToCheck == today) {
      return DateFormat('hh:mm a').format(dateTime);
    } else if (dateToCheck == today.subtract(const Duration(days: 1))) {
      return "Yesterday";
    } else {
      return DateFormat('dd/MM/yy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (context, index) =>
          const Padding(padding: EdgeInsets.only(left: 80), child: Divider()),
      itemCount: datas.length,
      itemBuilder: (context, index) {
        final data = datas[index];

        // Map Firestore keys to UI expected keys if necessary
        String name = data["displayName"] ?? data["user"] ?? "Unknown";
        if (name.trim().isEmpty) name = "Unknown";

        final image = data["photoURL"] ?? data["image"] ?? AppImage.user1;
        // WhatsApp-style highlights
        final unreadCount = data['unreadCount'] ?? 0;
        final hasUnread = unreadCount > 0;

        // Force use of lastMessage check
        String? latestMsg = data["lastMessage"] ?? data["message"];

        if (latestMsg == null || latestMsg.trim().isEmpty) {
          latestMsg = "Tap to chat";
        } else {
          // Check if current user sent the last message (requires lastSenderId from ChatService)
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          final lastSenderId = data['lastSenderId'];
          if (currentUserId != null && lastSenderId == currentUserId) {
            latestMsg = "You: $latestMsg";
          }
        }

        final timeString = _formatTimestamp(
          data["lastMessageTime"] ?? data["time"],
        );

        final isOnline = data["isOnline"] == true ? "Online" : "Offline";

        final userData = {
          ...data,
          "uid": data["uid"],
          "user": name,
          "image": image,
          "isOnline": isOnline,
        };

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (index) => ChatScreen(userData: userData),
                ),
              ).then((_) {
                if (onChatClosed != null) onChatClosed!();
              });
            },
            borderRadius: BorderRadius.circular(12),
            hoverColor: AppColors.primaryColor.withOpacity(0.05),
            splashColor: AppColors.fifthColor.withOpacity(0.1),
            highlightColor: AppColors.fifthColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Leading: Avatar
                  GestureDetector(
                    onTap: () =>
                        _showProfileDialog(context, name, image, userData),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: SizedBox(
                        height: 52,
                        width: 52,
                        child: _buildImage(image),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Body: Name, Message, Time, Badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Name + Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMediumPrimary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (timeString.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  timeString,
                                  style: hasUnread
                                      ? Theme.of(
                                          context,
                                        ).textTheme.bodySmallPrimary.copyWith(
                                          color: AppColors.fifthColor,
                                          fontWeight: FontWeight.bold,
                                        )
                                      : Theme.of(
                                          context,
                                        ).textTheme.bodySmallSecondary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Bottom Row: Message + Badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                latestMsg,
                                style: hasUnread
                                    ? Theme.of(
                                        context,
                                      ).textTheme.bodySmallPrimary.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      )
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodySmallSecondary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasUnread)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                height: 22,
                                constraints: const BoxConstraints(minWidth: 22),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.green,
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmallPrimary
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showProfileDialog(
    BuildContext context,
    String name,
    dynamic image,
    Map<String, dynamic> userData,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: Hero(tag: 'profile_$name', child: _buildImage(image)),
                ),
                Container(
                  width: 250,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              width: 250,
              height: 50,
              color: AppColors.primaryColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.message, color: AppColors.fifthColor),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(userData: userData),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.call, color: AppColors.fifthColor),
                    onPressed: () {
                      Navigator.pop(context);
                      // Add call logic if needed
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.info_outline, color: AppColors.fifthColor),
                    onPressed: () {
                      Navigator.pop(context);
                      // Add info logic if needed
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(dynamic imageSource) {
    if (imageSource == null) {
      return Image.asset(AppImage.user1, fit: BoxFit.cover);
    }

    if (imageSource is String) {
      if (imageSource.startsWith('http')) {
        return Image.network(
          imageSource,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Image.asset(AppImage.user1, fit: BoxFit.cover),
        );
      }
      return Image.asset(imageSource, fit: BoxFit.cover);
    }

    return Image.asset(AppImage.user1, fit: BoxFit.cover);
  }
}
