import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:support_chat/features/chat_screen/widget/custom_dialog.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_text.dart';
import 'package:support_chat/utils/constants/theme.dart';

class ChatAppbar extends StatelessWidget implements PreferredSizeWidget {
  final Map<String, dynamic> userData;

  const ChatAppbar({super.key, required this.userData});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
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
              child: Image.asset(userData['image'], fit: BoxFit.cover),
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
                  userData['user'] ?? '',
                  style: Theme.of(context).textTheme.titleMediumPrimary,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  userData['isOnline'] ?? 'last seen recently',
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
                  } else if (value == 'block') {
                    showDialog(
                      context: context,
                      builder: (context) => CustomDialog(
                        title: AppText.blockUserDialogTitle,
                        content: AppText.blockUserDialogContent,
                        button1Text: AppText.dialogCancel,
                        button2Text: AppText.blockUserDialogBlock,
                        button1Action: () {
                          Navigator.pop(context); // close dialog
                        },
                        button2Action: () {
                          Navigator.pop(context); // close dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User blocked')),
                          );
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User blocked')),
                          );
                        },
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
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
                        style: Theme.of(context).textTheme.bodySmallTertiary,
                      ),
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'block',
                    child: ListTile(
                      leading: Icon(
                        FontAwesomeIcons.ban,
                        size: 16,
                        color: AppColors.sixthColor,
                      ),
                      title: Text(
                        'Block User',
                        style: Theme.of(context).textTheme.bodySmallTertiary,
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
                        style: Theme.of(context).textTheme.bodySmallFourth,
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
              maxHeight:
                  MediaQuery.of(context).size.height *
                  0.8, // Max 80% of screen height
              maxWidth: 350, // Optional: adjust width
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
                        Spacer(),
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
                    SizedBox(height: 20),

                    // Two-column layout
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1st column
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
                              SizedBox(height: 6),
                              Text(
                                userData['user'] ?? '',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMediumSecondary,
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Mobile Number',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmallFifth,
                              ),
                              SizedBox(height: 6),
                              Text(
                                userData['mobile'] ?? '+91 5635256789',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMediumSecondary,
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Last Active',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmallFifth,
                              ),
                              SizedBox(height: 6),
                              Text(
                                userData['lastActive'] ??
                                    '30 Aug 2025, 09:30 AM',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMediumSecondary,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 20),

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
                              SizedBox(height: 6),
                              Text('U-633425788'),
                              SizedBox(height: 20),
                              Text(
                                'Email',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmallFifth,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'rahul.sharma@example.com',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMediumSecondary,
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Joined Date',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmallFifth,
                              ),
                              SizedBox(height: 6),
                              Text(
                                '30 Aug 2025',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMediumSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
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
}
