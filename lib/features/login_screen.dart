import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:support_chat/features/chat_screen.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/app_text.dart';
import 'package:support_chat/utils/constants/theme.dart';
import 'package:support_chat/utils/router/routes_names.dart';
import 'package:support_chat/utils/widgets/custom_elevated_button.dart';
import 'package:support_chat/utils/widgets/custom_text_form_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<LoginScreen> {
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppText.loginTitle,
                    style: Theme.of(context).textTheme.displayMediumPrimary,
                  ),
                  SizedBox(height: 10),
                  Text(
                    AppText.loginSubtitle,
                    style: Theme.of(context).textTheme.titleSmallPrimary,
                  ),
                  SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    height: 158,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.fourthColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.tertiaryColor),
                    ),
                    child: Column(
                      children: [
                        CustomTextFormField(
                          textColor: AppColors.primaryColor,
                          hintText: 'Enter Mobile Number',
                          hintColor: AppColors.tertiaryColor,
                          textSize: 14,
                          prefixWidget: Icon(
                            FontAwesomeIcons.phone,
                            size: 20,
                            color: AppColors.primaryColor,
                          ),
                          // backgroundColor: Colors.red,frer
                          showBorder: false,
                          contentPadding: const EdgeInsets.all(1),
                        ),
                        //  SizedBox(height: 22),
                        Divider(),

                        CustomTextFormField(
                          textColor: AppColors.primaryColor,
                          hintText: 'Enter Password',
                          hintColor: AppColors.tertiaryColor,
                          textSize: 14,
                          prefixWidget: Icon(
                            FontAwesomeIcons.lock,
                            size: 20,
                            color: AppColors.primaryColor,
                          ),
                          suffixWidget: Icon(
                            FontAwesomeIcons.eye,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                          // backgroundColor: Colors.red,frer
                          showBorder: false,
                          contentPadding: const EdgeInsets.all(1),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                  CustomElevatedButton(
                    width: double.infinity,
                    height: 56,
                    borderRadius: 30,
                    hasBorder: false,
                    backgroundColor: AppColors.fifthColor,
                    onPressed: () {
                      Navigator.pushNamed(context, RoutesNames.bottomBar);
                    },
                    child: Text(
                      'Sign in',
                      style: Theme.of(context).textTheme.bodyMediumPrimary,
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
