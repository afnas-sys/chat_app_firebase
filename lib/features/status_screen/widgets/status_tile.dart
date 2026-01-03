import 'package:flutter/material.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/theme.dart';

class StatusTile extends StatelessWidget {
  final String userName;
  final String time;
  final String? profilePic;
  final bool isSeen;
  final bool isMe;
  final int statusCount;
  final VoidCallback? onTap;
  final VoidCallback? onAddTap;

  final Widget? trailing;

  const StatusTile({
    super.key,
    required this.userName,
    required this.time,
    this.profilePic,
    this.isSeen = false,
    this.isMe = false,
    this.statusCount = 0,
    this.onTap,
    this.onAddTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ListTile(
        leading: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isMe && statusCount == 0
                      ? Colors.transparent
                      : (isSeen ? Colors.grey : AppColors.primaryColor),
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage:
                      (profilePic != null && profilePic!.isNotEmpty)
                      ? (profilePic!.startsWith('http')
                            ? NetworkImage(profilePic!)
                            : AssetImage(profilePic!) as ImageProvider)
                      : const AssetImage(AppImage.user1),
                ),
              ),
            ),
            if (isMe)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onAddTap,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.black, size: 16),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          userName,
          style: Theme.of(context).textTheme.titleMediumPrimary,
        ),
        subtitle: Text(
          time,
          style: Theme.of(context).textTheme.bodyMediumFourth,
        ),
        trailing: trailing,
      ),
    );
  }
}
