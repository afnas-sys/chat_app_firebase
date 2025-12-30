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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).resetState();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ref
          .read(authNotifierProvider.notifier)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
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
                content: Text(data['message'] ?? 'Registration successful'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.displayMediumPrimary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sign up to get started',
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
                            controller: _nameController,
                            textColor: AppColors.primaryColor,
                            hintText: 'Enter Your Name',
                            hintColor: AppColors.tertiaryColor,
                            textSize: 14,
                            prefixWidget: const Icon(
                              FontAwesomeIcons.user,
                              size: 20,
                              color: AppColors.primaryColor,
                            ),
                            showBorder: false,
                            contentPadding: const EdgeInsets.all(1),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const Divider(),
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
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const Divider(),
                          CustomTextFormField(
                            controller: _confirmPasswordController,
                            textColor: AppColors.primaryColor,
                            hintText: 'Confirm Password',
                            hintColor: AppColors.tertiaryColor,
                            textSize: 14,
                            obscureText: _obscureConfirmPassword,
                            prefixWidget: const Icon(
                              FontAwesomeIcons.lock,
                              size: 20,
                              color: AppColors.primaryColor,
                            ),
                            suffixWidget: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              child: Icon(
                                _obscureConfirmPassword
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
                                return 'Please confirm password';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    CustomElevatedButton(
                      width: double.infinity,
                      height: 56,
                      borderRadius: 30,
                      hasBorder: false,
                      backgroundColor: AppColors.fifthColor,
                      onPressed: authState.isLoading ? null : _handleRegister,
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
                              'Sign Up',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMediumPrimary,
                            ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmallPrimary,
                            children: [
                              TextSpan(
                                text: 'Sign In',
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
