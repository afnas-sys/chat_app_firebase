import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:support_chat/features/call_screen/view/call_screen.dart';
import 'package:support_chat/features/home_screen/view/home_screen.dart';
import 'package:support_chat/features/logout_screen/logout_screen.dart';
import 'package:support_chat/features/status_screen/view/status_screen.dart';
import 'package:support_chat/providers/chat_provider.dart';
import 'package:support_chat/utils/constants/app_colors.dart';

class CustomBottomBar extends StatefulWidget {
  const CustomBottomBar({super.key});

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar> {
  int _currentIndex = 0;
  List<Widget> bodys = [
    HomeScreen(),
    StatusScreen(),
    CallScreen(),
    LogoutScreen(),
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
                return BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Color(0XFF5BBC9D),
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
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(FontAwesomeIcons.solidMessage),
                      label: 'Message',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(FontAwesomeIcons.recordVinyl),
                      label: 'Status',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(FontAwesomeIcons.phone),
                      label: 'Call',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(FontAwesomeIcons.arrowRightFromBracket),
                      label: 'Log out',
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
