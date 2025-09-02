// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:support_chat/features/call_screen/call_tile/call_tile.dart';
import 'package:support_chat/features/home_screen/widget/chat_tile.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/app_text.dart';
import 'package:support_chat/utils/constants/theme.dart';
import 'package:support_chat/utils/widgets/custom_text_form_field.dart';

class CallScreen extends StatelessWidget {
  const CallScreen({super.key});

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppText.chatTitle,
                      style: Theme.of(context).textTheme.titleLargePrimary,
                    ),
                    ClipRRect(
                      child: SizedBox(
                        height: 44,
                        width: 44,
                        child: Image.asset(AppImage.profile, fit: BoxFit.cover),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.fourthColor,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.tertiaryColor),
                  ),
                  child: CustomTextFormField(
                    textColor: AppColors.primaryColor,
                    prefixWidget: const Icon(
                      FontAwesomeIcons.search,
                      color: AppColors.primaryColor,
                    ),
                    hintText: 'Search...',
                    hintColor: AppColors.tertiaryColor,
                  ),
                ),

                SizedBox(height: 10),
                //chat tile
                Expanded(child: CallTile()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
