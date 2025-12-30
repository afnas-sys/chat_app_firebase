// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:support_chat/features/chat_screen/view/chat_screen.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/theme.dart';

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
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('hh:mm a').format(dateTime); // Today
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime); // Day of week
    } else {
      return DateFormat('dd/MM/yy').format(dateTime); // Older
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
        final latestMsg =
            data["lastMessage"] ??
            data["message"] ??
            data["email"] ??
            "No message";

        final timeString = _formatTimestamp(
          data["lastMessageTime"] ?? data["time"],
        );

        final isOnline = data["isOnline"] == true ? "Online" : "Offline";

        // WhatsApp-style highlights
        final unreadCount = data['unreadCount'] ?? 0;
        final hasUnread = unreadCount > 0;

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
            child: ListTile(
              leading: GestureDetector(
                onTap: () => _showProfileDialog(context, name, image, userData),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: SizedBox(
                    height: 52,
                    width: 52,
                    child: _buildImage(image),
                  ),
                ),
              ),
              title: Text(
                name,
                style: Theme.of(context).textTheme.titleMediumPrimary,
              ),
              subtitle: Text(
                latestMsg,
                style: hasUnread
                    ? Theme.of(context).textTheme.bodySmallPrimary.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      )
                    : Theme.of(context).textTheme.bodySmallSecondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (timeString.isNotEmpty)
                        Text(
                          timeString,
                          style: hasUnread
                              ? Theme.of(
                                  context,
                                ).textTheme.bodySmallPrimary.copyWith(
                                  color: AppColors.fifthColor,
                                  fontWeight: FontWeight.bold,
                                )
                              : Theme.of(context).textTheme.bodySmallSecondary,
                        ),
                      const SizedBox(height: 6),
                      if (hasUnread)
                        Container(
                          height: 22,
                          constraints: const BoxConstraints(minWidth: 22),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: AppColors.fifthColor,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: Theme.of(context).textTheme.bodySmallPrimary
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
