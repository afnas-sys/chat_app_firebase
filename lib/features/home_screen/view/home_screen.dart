// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:support_chat/features/home_screen/widget/chat_tile.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/app_text.dart';
import 'package:support_chat/utils/constants/theme.dart';
import 'package:support_chat/utils/widgets/custom_text_form_field.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allChats = [
    {
      "user": "Alice",
      "image": AppImage.user1,
      "message": "Hey",
      'time': '2 min Ago',
      'msgCount': '3',
      'isOnline': 'Online',
    },
    {
      "user": "Bob",
      "image": AppImage.user2,
      "message": "How are you",
      'time': '2 min Ago',
      'msgCount': '3',
      'isOnline': 'Offline',
    },
    {
      "user": "Charlie",
      "image": AppImage.user3,
      "message": "Can we talk right now",
      'time': '2 min Ago',
      'isOnline': 'Offline',
    },
    {
      "user": "Diana",
      "image": AppImage.user4,
      "message": "10000 Received",
      'time': '2 min Ago',
      'isOnline': 'Online',
    },
    {
      "user": "Eve",
      "image": AppImage.user5,
      "message": "Are you okay",
      'time': '2 min Ago',
      'isOnline': 'Offline',
    },
    {
      "user": "Frank",
      "image": AppImage.user6,
      "message": "Congrats",
      'time': '2 min Ago',
      'isOnline': 'Online',
    },
    {
      "user": "John",
      "image": AppImage.user7,
      "message": "I will see you soon",
      'time': '2 min Ago',
      'isOnline': 'Online',
    },
    {
      "user": "Charlie",
      "image": AppImage.user3,
      "message": "Can we talk right now",
      'time': '2 min Ago',
      'isOnline': 'Offline',
    },
    {
      "user": "Diana",
      "image": AppImage.user4,
      "message": "10000 Received",
      'time': '2 min Ago',
      'isOnline': 'Online',
    },
  ];

  List<Map<String, dynamic>> _filteredChats = [];

  @override
  void initState() {
    super.initState();
    _filteredChats = _allChats; // initially show all
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredChats = _allChats.where((chat) {
        final name = chat['user'].toString().toLowerCase();
        final message = chat['message'].toString().toLowerCase();
        return name.contains(query) || message.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppText.chatTitle,
                  style: Theme.of(context).textTheme.titleLargePrimary,
                ),
                const SizedBox(height: 16),
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
                    hintText: 'Search...',
                    hintColor: AppColors.tertiaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(child: ChatTile(datas: _filteredChats)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
