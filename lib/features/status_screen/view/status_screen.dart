// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:support_chat/features/status_screen/controller/status_controller.dart';
import 'package:support_chat/features/status_screen/view/status_view_screen.dart';
import 'package:support_chat/features/status_screen/widgets/status_tile.dart';
import 'package:support_chat/models/status_model.dart';
import 'package:support_chat/services/auth_service.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/theme.dart';
import 'package:support_chat/utils/widgets/custom_text_form_field.dart';
import 'package:image_picker/image_picker.dart';

class StatusScreen extends ConsumerStatefulWidget {
  const StatusScreen({super.key});

  @override
  ConsumerState<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends ConsumerState<StatusScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final statusAsyncValue = ref.watch(statusStreamProvider);
    final currentUser = AuthService().currentUser;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //! Search
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.fourthColor,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.tertiaryColor),
                  ),
                  child: CustomTextFormField(
                    textColor: AppColors.primaryColor,
                    controller: _searchController,
                    hintText: 'Search',
                    prefixWidget: const Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: AppColors.primaryColor,
                    ),
                    suffixWidget: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.primaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    hintColor: AppColors.tertiaryColor,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              //!My Status / Add Status
              statusAsyncValue.when(
                data: (statuses) {
                  // Filter my statuses
                  final myStatuses = statuses
                      .where((s) => s.uid == currentUser?.uid)
                      .toList();
                  // Sort by timestamp descending (newest first)
                  myStatuses.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                  final hasStatus = myStatuses.isNotEmpty;
                  final latestMyStatus = hasStatus ? myStatuses.first : null;

                  return Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: AppColors.tertiaryColor),
                    ),
                    child: StatusTile(
                      userName: 'My Status',
                      time: hasStatus
                          ? 'Tap to view updates'
                          : 'Tap to add status',
                      isMe: true,
                      statusCount: myStatuses.length,
                      profilePic: currentUser
                          ?.photoURL, // We might need to fetch this better if not in auth
                      onTap: () {
                        if (hasStatus) {
                          // myStatuses is sorted descending (Newest first).
                          // To view stories chronologically, we want Oldest first.
                          final myStatusesAsc = myStatuses.reversed.toList();
                          _viewStatus(context, myStatusesAsc, 0);
                        } else {
                          _addStatus(context, ref);
                        }
                      },
                      onAddTap: () => _addStatus(context, ref),
                      trailing: hasStatus
                          ? IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: AppColors.primaryColor,
                              ),
                              onPressed: () {
                                if (myStatuses.length > 1) {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return Container(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'Select Status to Delete',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Flexible(
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                itemCount: myStatuses.length,
                                                itemBuilder: (context, index) {
                                                  final status =
                                                      myStatuses[index];
                                                  final dt = status.timestamp;
                                                  final timeStr =
                                                      "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
                                                  return ListTile(
                                                    leading: CircleAvatar(
                                                      backgroundImage:
                                                          NetworkImage(
                                                            status.imageUrl,
                                                          ),
                                                    ),
                                                    title: Text(
                                                      status.caption.isNotEmpty
                                                          ? status.caption
                                                          : 'Status',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    subtitle: Text(timeStr),
                                                    trailing: IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (ctx) => AlertDialog(
                                                            title: const Text(
                                                              "Delete this status?",
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      ctx,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      "Cancel",
                                                                    ),
                                                              ),
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                    ctx,
                                                                  );
                                                                  ref
                                                                      .read(
                                                                        statusControllerProvider,
                                                                      )
                                                                      .deleteStatus(
                                                                        context,
                                                                        status
                                                                            .statusId,
                                                                      );
                                                                },
                                                                child:
                                                                    const Text(
                                                                      "Delete",
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Status'),
                                      content: const Text(
                                        'Are you sure you want to delete this status?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            ref
                                                .read(statusControllerProvider)
                                                .deleteStatus(
                                                  context,
                                                  latestMyStatus!.statusId,
                                                );
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            )
                          : null,
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),

              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'STATUS',
                  style: Theme.of(context).textTheme.titleSmallPrimary,
                ),
              ),

              //! Status List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.tertiaryColor),
                  ),
                  child: statusAsyncValue.when(
                    data: (statuses) {
                      // Filter other users' statuses
                      final otherStatuses = statuses
                          .where((s) => s.uid != currentUser?.uid)
                          .toList();

                      // Group by User UID to show one tile per user?
                      // Wait, standard WhatsApp behavior: one row per user, tap to see their story.
                      // If user has multiple stories, they play in sequence.
                      // The requirements say "user can put their status story... add a add button... status tile bottom of the list"
                      // And "if someone saw status marked that as viewed list".
                      // So we need to group by user.

                      final Map<String, List<Status>> groupedStatuses = {};
                      for (var s in otherStatuses) {
                        if (!groupedStatuses.containsKey(s.uid)) {
                          groupedStatuses[s.uid] = [];
                        }
                        groupedStatuses[s.uid]!.add(s);
                      }

                      // Create list of User items to display
                      List<Map<String, dynamic>> statusList = [];
                      groupedStatuses.forEach((uid, userStatuses) {
                        // Sort by timestamp
                        userStatuses.sort(
                          (a, b) => a.timestamp.compareTo(b.timestamp),
                        );

                        // Check if all viewed
                        bool allViewed = userStatuses.every(
                          (s) => s.viewers.any(
                            (v) => v['uid'] == currentUser?.uid,
                          ),
                        );
                        DateTime latestTime = userStatuses.last.timestamp;

                        statusList.add({
                          'uid': uid,
                          'statuses': userStatuses,
                          'allViewed': allViewed,
                          'latestTime': latestTime,
                          'username': userStatuses
                              .first
                              .username, // Assumption: name is consistent
                          'profilePic': userStatuses.first.profilePic,
                        });
                      });

                      // Apply search filter
                      if (_searchQuery.isNotEmpty) {
                        statusList = statusList.where((item) {
                          final username =
                              (item['username'] as String?)?.toLowerCase() ??
                              '';
                          return username.contains(_searchQuery);
                        }).toList();
                      }

                      // Sort: Unviewed first, then Viewed. Within that, by latestTime descending.
                      statusList.sort((a, b) {
                        if (a['allViewed'] != b['allViewed']) {
                          return a['allViewed']
                              ? 1
                              : -1; // Viewed goes to bottom
                        }
                        return (b['latestTime'] as DateTime).compareTo(
                          a['latestTime'] as DateTime,
                        );
                      });

                      if (statusList.isEmpty) {
                        return Center(
                          child: Text(
                            _searchQuery.isNotEmpty
                                ? 'No statuses found for "$_searchQuery"'
                                : 'No recent updates',
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: statusList.length,
                        itemBuilder: (context, index) {
                          final item = statusList[index];
                          final List<Status> userStatuses = item['statuses'];
                          final bool isSeen = item['allViewed'];

                          // Convert timestamp to time ago string
                          final timeDiff = DateTime.now().difference(
                            item['latestTime'],
                          );
                          String timeStr;
                          if (timeDiff.inMinutes < 60) {
                            timeStr = '${timeDiff.inMinutes}m ago';
                          } else {
                            timeStr = '${timeDiff.inHours}h ago';
                          }

                          return StatusTile(
                            userName: item['username'],
                            time: timeStr,
                            profilePic: item['profilePic'],
                            isSeen: isSeen,
                            onTap: () {
                              // Find the first UNSEEN status to start viewing from
                              // Or just start from the beginning if all seen?
                              // Standard behavior: start from first unseen.
                              Status? firstUnseen;
                              int initialIndex = 0;
                              for (int i = 0; i < userStatuses.length; i++) {
                                var s = userStatuses[i];
                                bool viewed = s.viewers.any(
                                  (v) => v['uid'] == currentUser?.uid,
                                );
                                if (!viewed) {
                                  firstUnseen = s;
                                  initialIndex = i;
                                  break;
                                }
                              }
                              // If all seen, view the first one
                              if (firstUnseen == null) {
                                firstUnseen = userStatuses.first;
                                initialIndex = 0;
                              }

                              _viewStatus(context, userStatuses, initialIndex);
                            },
                          );
                        },
                        separatorBuilder: (context, index) {
                          return Divider(color: AppColors.tertiaryColor);
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addStatus(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && context.mounted) {
      // Ideally show a preview screen to add caption.
      // For this MVP, we will just use a dialog to get caption
      String caption = '';
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Add Caption"),
            content: TextField(
              onChanged: (val) => caption = val,
              decoration: const InputDecoration(hintText: "Type a caption..."),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Uploading status...")));

        await ref
            .read(statusControllerProvider)
            .addStatus(context, File(image.path), caption);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Status uploaded!")));
      }
    }
  }

  void _viewStatus(
    BuildContext context,
    List<Status> statuses,
    int initialIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StatusViewScreen(statuses: statuses, initialIndex: initialIndex),
      ),
    );
  }
}
