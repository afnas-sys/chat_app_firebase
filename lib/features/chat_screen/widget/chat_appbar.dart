import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:support_chat/features/chat_screen/widget/custom_dialog.dart';
import 'package:support_chat/providers/auth_provider.dart';
import 'package:support_chat/providers/chat_provider.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/app_text.dart';
import 'package:support_chat/utils/constants/theme.dart';
import 'package:support_chat/features/chat_screen/view/add_group_members_screen.dart';
import 'package:support_chat/features/chat_screen/view/remove_group_members_screen.dart';
import 'package:support_chat/features/chat_screen/view/user_details_screen.dart';
import 'package:support_chat/services/cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';

class ChatAppbar extends ConsumerWidget implements PreferredSizeWidget {
  final Map<String, dynamic> userData;

  const ChatAppbar({super.key, required this.userData});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatService = ref.read(chatServiceProvider);
    final currentUserAsync = ref.watch(currentUserStreamProvider);
    final currentUserData = currentUserAsync.value;
    final List blockedUsers = currentUserData?['blockedUsers'] ?? [];
    final isBlocked = blockedUsers.contains(userData['uid']);

    // Parse online status
    String statusText = 'Offline';
    if (userData['isGroup'] == true) {
      statusText = 'Group';
    } else if (userData['isOnline'] == true) {
      statusText = 'Online';
    } else if (userData['lastSeen'] != null) {
      final lastSeen = (userData['lastSeen'] as Timestamp).toDate();
      statusText =
          'Last seen ${DateFormat('dd MMM, hh:mm a').format(lastSeen)}';
    }

    return Container(
      color: Colors.transparent,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // back button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(FontAwesomeIcons.angleLeft, size: 20),
          ),
          const SizedBox(width: 16),

          // user image
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserDetailsScreen(userData: userData),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 40,
                width: 40,
                child: _buildImage(userData['photoURL'] ?? userData['image']),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // user name + status
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserDetailsScreen(userData: userData),
                ),
              ),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    userData['displayName'] ?? userData['user'] ?? 'User',
                    style: Theme.of(context).textTheme.titleMediumPrimary,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.bodySmallSecondary,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // actions
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {},
                icon: const Icon(FontAwesomeIcons.phone, size: 20),
              ),

              /// Ellipsis with PopupMenu
              PopupMenuButton<String>(
                icon: const Icon(FontAwesomeIcons.ellipsisVertical, size: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'details') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UserDetailsScreen(userData: userData),
                      ),
                    );
                  } else if (value == 'changeImage' &&
                      userData['isGroup'] == true) {
                    _changeGroupImage(context, ref, userData['uid']);
                  } else if (value == 'addMembers' &&
                      userData['isGroup'] == true) {
                    _addGroupMembers(context, userData);
                  } else if (value == 'removeMembers' &&
                      userData['isGroup'] == true) {
                    _removeGroupMembers(context, userData);
                  } else if (value == 'block') {
                    showDialog(
                      context: context,
                      builder: (context) => CustomDialog(
                        title: isBlocked
                            ? 'Unblock User'
                            : AppText.blockUserDialogTitle,
                        content: isBlocked
                            ? 'Are you sure you want to unblock this user?'
                            : AppText.blockUserDialogContent,
                        button1Text: AppText.dialogCancel,
                        button2Text: isBlocked
                            ? 'Unblock'
                            : AppText.blockUserDialogBlock,
                        button1Action: () {
                          Navigator.pop(context); // close dialog
                        },
                        button2Action: () {
                          Navigator.pop(context); // close dialog
                          if (isBlocked) {
                            chatService.unblockUser(userData['uid']);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User unblocked')),
                            );
                          } else {
                            chatService.blockUser(userData['uid']);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User blocked')),
                            );
                          }
                        },
                      ),
                    );
                  } else if (value == 'delete') {
                    showDialog(
                      context: context,
                      builder: (context) => CustomDialog(
                        title: AppText.deleteDialogTitle,
                        content: AppText.deleteDialogContent,
                        button1Text: AppText.dialogCancel,
                        button2Text: AppText.deleteDialogDelete,
                        button1Action: () {
                          Navigator.pop(context); // close dialog
                        },
                        button2Action: () {
                          Navigator.pop(context); // close dialog
                          chatService.deleteChat(userData['uid']);
                          Navigator.pop(context); // Go back to chat list
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chat deleted')),
                          );
                        },
                      ),
                    );
                  }
                },
                itemBuilder: (context) => userData['isGroup'] == true
                    ? [
                        // Group-specific options
                        PopupMenuItem(
                          value: 'changeImage',
                          child: ListTile(
                            leading: Icon(
                              FontAwesomeIcons.image,
                              size: 16,
                              color: AppColors.sixthColor,
                            ),
                            title: Text(
                              'Change Group Image',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmallTertiary,
                            ),
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem(
                          value: 'addMembers',
                          child: ListTile(
                            leading: Icon(
                              FontAwesomeIcons.userPlus,
                              size: 16,
                              color: AppColors.sixthColor,
                            ),
                            title: Text(
                              'Add Members',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmallTertiary,
                            ),
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem(
                          value: 'removeMembers',
                          child: ListTile(
                            leading: Icon(
                              FontAwesomeIcons.userMinus,
                              size: 16,
                              color: AppColors.sixthColor,
                            ),
                            title: Text(
                              'Remove Members',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmallTertiary,
                            ),
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              FontAwesomeIcons.trashCan,
                              color: AppColors.seventhColor,
                              size: 16,
                            ),
                            title: Text(
                              'Delete Group',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmallFourth,
                            ),
                          ),
                        ),
                      ]
                    : [
                        // 1-on-1 chat options
                        PopupMenuItem(
                          value: 'details',
                          child: ListTile(
                            leading: Icon(
                              FontAwesomeIcons.imagePortrait,
                              size: 16,
                              color: AppColors.sixthColor,
                            ),
                            title: Text(
                              'User Details',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmallTertiary,
                            ),
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem(
                          value: 'block',
                          child: ListTile(
                            leading: Icon(
                              isBlocked
                                  ? FontAwesomeIcons.check
                                  : FontAwesomeIcons.ban,
                              size: 16,
                              color: AppColors.sixthColor,
                            ),
                            title: Text(
                              isBlocked ? 'Unblock User' : 'Block User',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmallTertiary,
                            ),
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              FontAwesomeIcons.trashCan,
                              color: AppColors.seventhColor,
                              size: 16,
                            ),
                            title: Text(
                              'Delete Chat',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmallFourth,
                            ),
                          ),
                        ),
                      ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImage(dynamic imageSource) {
    if (imageSource == null || (imageSource is String && imageSource.isEmpty)) {
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

  void _changeGroupImage(
    BuildContext context,
    WidgetRef ref,
    String groupId,
  ) async {
    try {
      final cloudinaryService = ref.read(cloudinaryServiceProvider);
      final file = await cloudinaryService.pickImage(ImageSource.gallery);

      if (file == null) return;

      // Show loading
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );

      // Upload to Cloudinary
      final imageUrl = await cloudinaryService.uploadFile(
        file,
        folder: 'group_images',
      );

      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      // Update group image in Firestore
      await ref.read(chatServiceProvider).updateGroupImage(groupId, imageUrl);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group image updated successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog if open
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating image: $e')));
    }
  }

  void _addGroupMembers(BuildContext context, Map<String, dynamic> groupData) {
    final groupId = groupData['uid'] ?? groupData['id'];
    final groupName = groupData['displayName'] ?? 'Group';
    final existingMembers = List<String>.from(groupData['users'] ?? []);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddGroupMembersScreen(
          groupId: groupId,
          groupName: groupName,
          existingMemberIds: existingMembers,
        ),
      ),
    );
  }

  void _removeGroupMembers(
    BuildContext context,
    Map<String, dynamic> groupData,
  ) {
    final groupId = groupData['uid'] ?? groupData['id'];
    final groupName = groupData['displayName'] ?? 'Group';
    final existingMembers = List<String>.from(groupData['users'] ?? []);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RemoveGroupMembersScreen(
          groupId: groupId,
          groupName: groupName,
          existingMemberIds: existingMembers,
        ),
      ),
    );
  }
}
