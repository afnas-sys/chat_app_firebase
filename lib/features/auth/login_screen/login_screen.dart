import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:support_chat/providers/auth_provider.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/theme.dart';
import 'package:support_chat/utils/router/routes_names.dart';
import 'package:support_chat/utils/widgets/custom_elevated_button.dart';
import 'package:support_chat/utils/widgets/custom_text_form_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).resetState();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authNotifierProvider.notifier)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Listen to auth state changes
    ref.listen<AsyncValue<Map<String, dynamic>>>(authNotifierProvider, (
      previous,
      next,
    ) {
      next.when(
        data: (data) {
          if (data['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Login successful'),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate to home screen
            Navigator.pushReplacementNamed(context, RoutesNames.bottomBar);
          }
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: Colors.red,
            ),
          );
        },
        loading: () {},
      );
    });

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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'WELCOME!',
                      style: Theme.of(context).textTheme.displayMediumPrimary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Start chatting and stay connected 💬',
                      style: Theme.of(context).textTheme.titleSmallPrimary,
                    ),
                    const SizedBox(height: 40),
                    Container(
                      width: double.infinity,
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
                            controller: _emailController,
                            textColor: AppColors.primaryColor,
                            hintText: 'Enter Email Address',
                            hintColor: AppColors.tertiaryColor,
                            textSize: 14,
                            keyboardType: TextInputType.emailAddress,
                            prefixWidget: const Icon(
                              FontAwesomeIcons.envelope,
                              size: 20,
                              color: AppColors.primaryColor,
                            ),
                            showBorder: false,
                            contentPadding: const EdgeInsets.all(1),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter email address';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const Divider(),
                          CustomTextFormField(
                            controller: _passwordController,
                            textColor: AppColors.primaryColor,
                            hintText: 'Enter Password',
                            hintColor: AppColors.tertiaryColor,
                            textSize: 14,
                            obscureText: _obscurePassword,
                            prefixWidget: const Icon(
                              FontAwesomeIcons.lock,
                              size: 20,
                              color: AppColors.primaryColor,
                            ),
                            suffixWidget: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              child: Icon(
                                _obscurePassword
                                    ? FontAwesomeIcons.eyeSlash
                                    : FontAwesomeIcons.eye,
                                color: AppColors.primaryColor,
                                size: 20,
                              ),
                            ),
                            showBorder: false,
                            contentPadding: const EdgeInsets.all(1),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter password';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            RoutesNames.forgotPasswordScreen,
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: Theme.of(context).textTheme.titleSmallPrimary
                              .copyWith(
                                color: AppColors.fifthColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    CustomElevatedButton(
                      width: double.infinity,
                      height: 56,
                      borderRadius: 30,
                      hasBorder: false,
                      backgroundColor: AppColors.fifthColor,
                      onPressed: authState.isLoading ? null : _handleLogin,
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.primaryColor,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Sign in',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMediumPrimary,
                            ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            RoutesNames.registerScreen,
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmallPrimary,
                            children: [
                              TextSpan(
                                text: 'Sign Up',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmallPrimary
                                    .copyWith(
                                      color: AppColors.fifthColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
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
      ),
    );
  }
}
