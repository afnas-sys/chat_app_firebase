// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:support_chat/features/home_screen/widget/chat_tile.dart';
import 'package:support_chat/providers/chat_provider.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/app_text.dart';
import 'package:support_chat/utils/constants/theme.dart';
import 'package:support_chat/utils/widgets/custom_text_form_field.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _clearSearch() {
    _searchController.clear();
    ref.read(chatSearchProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final filteredChats = ref.watch(filteredChatsProvider);
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
                    onChanged: (value) {
                      ref.read(chatSearchProvider.notifier).state = value;
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: filteredChats.isEmpty
                      ? Center(child: Text('No chat found'))
                      : ChatTile(
                          datas: filteredChats,
                          onChatClosed: _clearSearch,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
