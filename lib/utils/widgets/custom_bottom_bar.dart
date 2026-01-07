import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:support_chat/features/expanse_manager/expanse_manager.dart';
import 'package:support_chat/features/home_screen/view/home_screen.dart';
import 'package:support_chat/features/ai_chat_screen/view/ai_chat_screen.dart';
import 'package:support_chat/features/note_screen/view/note_screen.dart';
import 'package:support_chat/features/status_screen/controller/status_controller.dart';
import 'package:support_chat/features/status_screen/view/status_screen.dart';
import 'package:support_chat/providers/auth_provider.dart';
import 'package:support_chat/providers/chat_provider.dart';
import 'package:support_chat/utils/constants/app_colors.dart';

class CustomBottomBar extends ConsumerStatefulWidget {
  const CustomBottomBar({super.key});

  @override
  ConsumerState<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends ConsumerState<CustomBottomBar> {
  int _currentIndex = 0;

  List<Widget> bodys = [
    HomeScreen(),
    StatusScreen(),
    NoteScreen(),
    ExpanseManager(),
    AiChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: bodys[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Color(0XFF5BBC9D),
          highlightColor: Color(0XFF5BBC9D),
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Consumer(
              builder: (context, ref, child) {
                final chats = ref.watch(userChatsProvider).value ?? [];
                final hasUnread = chats.any(
                  (chat) => (chat['unreadCount'] as int? ?? 0) > 0,
                );

                final statuses = ref.watch(statusStreamProvider).value ?? [];
                final currentUserId = ref.watch(authStateProvider).value?.uid;
                final hasNewStatus = statuses.any(
                  (s) =>
                      s.uid != currentUserId &&
                      !s.viewers.any((v) => v['uid'] == currentUserId),
                );

                return BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: const Color(0XFF5BBC9D),
                  elevation: 0,
                  selectedItemColor: AppColors.primaryColor,
                  unselectedItemColor: AppColors.tertiaryColor,
                  iconSize: 24,
                  mouseCursor: WidgetStateMouseCursor.clickable,
                  currentIndex: _currentIndex,
                  selectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  onTap: (i) {
                    if (i == 0) {
                      // Reset search when going to Home tab
                      ref.read(chatSearchProvider.notifier).state = '';
                    }
                    setState(() => _currentIndex = i);
                  },
                  items: [
                    BottomNavigationBarItem(
                      icon: Badge(
                        backgroundColor: Colors.green,
                        smallSize: 8,
                        isLabelVisible: hasUnread,
                        child: const Icon(FontAwesomeIcons.solidMessage),
                      ),
                      label: 'Message',
                    ),
                    BottomNavigationBarItem(
                      icon: Badge(
                        backgroundColor: Colors.green,
                        smallSize: 8,
                        isLabelVisible: hasNewStatus,
                        child: const Icon(FontAwesomeIcons.recordVinyl),
                      ),
                      label: 'Status',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(FontAwesomeIcons.book),
                      label: 'Notes',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(FontAwesomeIcons.moneyCheckDollar),
                      label: 'Expanse',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(FontAwesomeIcons.robot),
                      label: 'AI Chat',
                    ),
                  ],
                );
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(color: Color(0XFF5BBC9D)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
