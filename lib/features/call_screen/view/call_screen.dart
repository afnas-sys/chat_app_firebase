// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:support_chat/features/call_screen/call_tile/call_tile.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/app_text.dart';
import 'package:support_chat/utils/constants/theme.dart';
import 'package:support_chat/utils/widgets/custom_text_form_field.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allCalls = [
    {
      "user": "Alice",
      "image": AppImage.user1,
      'icon': Icons.arrow_outward,
      "date": "30 Aug 2025, 10:15 AM",
      'status': '12m 45s',
    },
    {
      "user": "Bob",
      "image": AppImage.user2,
      'icon': Icons.subdirectory_arrow_left_rounded,
      "date": "30 Aug 2025, 10:15 AM",
      'status': 'Missed',
    },
    {
      "user": "Charlie",
      "image": AppImage.user3,
      'icon': Icons.arrow_outward,
      "date": "30 Aug 2025, 10:15 AM",
      'status': 'Missed',
    },
    {
      "user": "Diana",
      "image": AppImage.user4,
      'icon': Icons.arrow_outward,
      "date": "30 Aug 2025, 10:15 AM",
      'status': 'Missed',
    },
    {
      "user": "Eve",
      "image": AppImage.user5,
      'icon': Icons.arrow_outward,
      "date": "30 Aug 2025, 10:15 AM",
      'status': 'Missed',
    },
    {
      "user": "Frank",
      "image": AppImage.user6,
      'icon': Icons.subdirectory_arrow_left_rounded,
      "date": "30 Aug 2025, 10:15 AM",
      'status': 'Missed',
    },
  ];

  List<Map<String, dynamic>> _filteredCalls = [];

  @override
  void initState() {
    super.initState();
    _filteredCalls = _allCalls; // show all initially
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCalls = _allCalls.where((call) {
        final name = call['user'].toString().toLowerCase();
        final status = call['status'].toString().toLowerCase();
        return name.contains(query) || status.contains(query);
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
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppText.chatTitle,
                      style: Theme.of(context).textTheme.titleLargePrimary,
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: SizedBox(
                        height: 44,
                        width: 44,
                        child: Image.asset(AppImage.profile, fit: BoxFit.cover),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Search box
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

                // Calls list
                Expanded(child: CallTile(datas: _filteredCalls)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
