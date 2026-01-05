// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:support_chat/features/home_screen/widget/chat_tile.dart';
import 'package:support_chat/providers/auth_provider.dart';
import 'package:support_chat/providers/chat_provider.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/app_text.dart';
import 'package:support_chat/utils/constants/theme.dart';
import 'package:support_chat/utils/router/routes_names.dart';
import 'package:support_chat/utils/widgets/custom_text_form_field.dart';

import 'package:flutter/services.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Application'),
        content: const Text('Do you want to close the application?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              SystemNavigator.pop();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Mark messages as delivered when app opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatService = ref.read(chatServiceProvider);
      chatService.markAsDelivered();

      // Auto-refresh data on init
      ref.invalidate(currentUserDataProvider);
      ref.invalidate(userChatsProvider);
      ref.invalidate(usersSearchProvider);

      // chatService.fixLegacyChats(); // Auto-fix missing chats
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Trigger delivery update when user comes back to the app
      ref.read(chatServiceProvider).markAsDelivered();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(chatSearchProvider.notifier).state = '';
  }

  ImageProvider _getImageProvider(String? photo) {
    if (photo == null || photo.isEmpty) {
      return const AssetImage(AppImage.user1);
    }
    if (photo.startsWith('http')) {
      return NetworkImage(photo);
    }
    return AssetImage(photo);
  }

  @override
  Widget build(BuildContext context) {
    // Proactively mark new messages as delivered when the chat list updates
    ref.listen(userChatsProvider, (previous, next) {
      if (next is AsyncData) {
        ref.read(chatServiceProvider).markAsDelivered();
      }
    });

    final searchResults = ref.watch(usersSearchProvider);
    final searchQuery = ref.watch(chatSearchProvider);
    final currentUserData = ref.watch(currentUserDataProvider);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, RoutesNames.createGroupScreen);
          },
          backgroundColor: AppColors.primaryColor,
          child: const Icon(Icons.group_add, color: Colors.black),
        ),
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
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // YOUR PROFILE PICTURE
                          currentUserData.when(
                            data: (data) => GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context,
                                RoutesNames.profileScreen,
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundImage: _getImageProvider(
                                  data?['photoURL'] ?? data?['image'],
                                ),
                              ),
                            ),
                            loading: () => const CircleAvatar(
                              radius: 20,
                              child: CircularProgressIndicator(),
                            ),
                            error: (_, __) => const CircleAvatar(
                              radius: 20,
                              backgroundImage: AssetImage(AppImage.user1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppText.chatTitle,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLargePrimary,
                          ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        color: AppColors.fifthColor,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.primaryColor,
                        ),
                        onSelected: (value) {
                          if (value == 'profile') {
                            Navigator.pushNamed(
                              context,
                              RoutesNames.profileScreen,
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.person, size: 18),
                                SizedBox(width: 8),
                                Text('Profile Settings'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  //! SEARCH BAR
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.fourthColor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.tertiaryColor),
                    ),
                    child: CustomTextFormField(
                      controller: _searchController,
                      textColor: AppColors.primaryColor,
                      prefixWidget: const Icon(
                        FontAwesomeIcons.search,
                        color: AppColors.primaryColor,
                      ),
                      hintText: 'Search people by name...',
                      hintColor: AppColors.tertiaryColor,
                      onChanged: (value) {
                        ref.read(chatSearchProvider.notifier).state = value;
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        // Invalidate providers to force a refresh
                        ref.invalidate(currentUserDataProvider);
                        ref.invalidate(userChatsProvider);
                        ref.invalidate(usersSearchProvider);
                        // Give it a tiny delay for smooth animation
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      color: AppColors.fifthColor,
                      backgroundColor: AppColors.primaryColor,
                      child: searchQuery.trim().isEmpty
                          ? ref
                                .watch(userChatsProvider)
                                .when(
                                  data: (chats) => ref
                                      .watch(usersSearchProvider)
                                      .when(
                                        data: (recentUsers) {
                                          final chatIds = chats
                                              .map((c) => c['uid'])
                                              .toSet();
                                          final otherUsers = recentUsers
                                              .where(
                                                (u) =>
                                                    !chatIds.contains(u['uid']),
                                              )
                                              .map(
                                                (u) => {
                                                  ...u,
                                                  'source': 'user_directory',
                                                  'lastMessage':
                                                      null, // Explicitly null for clarity
                                                },
                                              )
                                              .toList();

                                          // Add source tag to chats
                                          final chatsWithSource = chats
                                              .map(
                                                (c) => {...c, 'source': 'chat'},
                                              )
                                              .toList();

                                          final allData = [
                                            ...chatsWithSource,
                                            ...otherUsers,
                                          ];

                                          if (allData.isEmpty) {
                                            return ListView(
                                              children: [
                                                SizedBox(
                                                  height:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.height *
                                                      0.4,
                                                  child: Center(
                                                    child: Text(
                                                      'No chats or users found',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMediumPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }

                                          return ChatTile(
                                            datas: allData,
                                            onChatClosed: _clearSearch,
                                          );
                                        },
                                        loading: () => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                        error: (err, stack) => Center(
                                          child: Text(
                                            'Error loading users: $err',
                                          ),
                                        ),
                                      ),
                                  loading: () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  error: (err, stack) => Center(
                                    child: Text(
                                      'Error loading chats: $err',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                )
                          : searchResults.when(
                              data: (users) => users.isEmpty
                                  ? ListView(
                                      // ListView allows RefreshIndicator to work on empty state
                                      children: [
                                        SizedBox(
                                          height:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.4,
                                          child: Center(
                                            child: Text(
                                              'No users found with that name',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMediumPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : ChatTile(
                                      datas: users,
                                      onChatClosed: _clearSearch,
                                    ),
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (err, stack) => Center(
                                child: Text(
                                  'Search error: $err',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
