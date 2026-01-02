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
import 'package:support_chat/utils/widgets/custom_elevated_button.dart';
import 'package:support_chat/features/chat_screen/view/add_group_members_screen.dart';
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
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 40,
              width: 40,
              child: _buildImage(userData['photoURL'] ?? userData['image']),
            ),
          ),
          const SizedBox(width: 10),

          // user name + status
          Expanded(
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
                    showDetailSheet(context, userData);
                  } else if (value == 'changeImage' &&
                      userData['isGroup'] == true) {
                    _changeGroupImage(context, ref, userData['uid']);
                  } else if (value == 'addMembers' &&
                      userData['isGroup'] == true) {
                    _addGroupMembers(context, userData);
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

  void showDetailSheet(BuildContext context, Map<String, dynamic> userData) {
    // Format dates
    String joinedDateStr = 'Unknown';
    if (userData['createdAt'] != null) {
      final joinedDate = (userData['createdAt'] as Timestamp).toDate();
      joinedDateStr = DateFormat('dd MMM yyyy').format(joinedDate);
    }

    String lastActiveStr = 'Unknown';
    if (userData['isOnline'] == true) {
      lastActiveStr = 'Online now';
    } else if (userData['lastSeen'] != null) {
      final lastSeen = (userData['lastSeen'] as Timestamp).toDate();
      lastActiveStr = DateFormat('dd MMM yyyy, hh:mm a').format(lastSeen);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 350,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Text(
                          'View User Details',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmallSecondary,
                        ),
                        const Spacer(),
                        Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.eleventhColor),
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              FontAwesomeIcons.xmark,
                              color: AppColors.eighthColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Two-column layout
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //! 1st column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User Name',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmallFifth,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                userData['displayName'] ??
                                    userData['user'] ??
                                    '',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMediumSecondary,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Mobile Number',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmallFifth,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                userData['mobile'] ?? 'Not Available',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMediumSecondary,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Last Active',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmallFifth,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                lastActiveStr,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMediumSecondary,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),

                        //! 2nd column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User ID',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmallFifth,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                userData['uid'] ?? '',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMediumSecondary,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Email',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmallFifth,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                userData['email'] ?? 'Not Available',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMediumSecondary,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Joined Date',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmallFifth,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                joinedDateStr,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMediumSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 34),
                    CustomElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      width: double.infinity,
                      hasBorder: true,
                      borderColor: AppColors.twelfthColor,
                      height: 48,
                      borderRadius: 30,
                      backgroundColor: AppColors.primaryColor,
                      child: Text(
                        'Back',
                        style: Theme.of(context).textTheme.bodyMediumSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
}
