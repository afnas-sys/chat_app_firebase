import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:support_chat/providers/auth_provider.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/theme.dart';
import 'package:support_chat/utils/widgets/custom_elevated_button.dart';
import 'package:support_chat/utils/widgets/custom_text_form_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

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
    super.dispose();
  }

  void _handleResetPassword() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authNotifierProvider.notifier)
          .resetPassword(_emailController.text.trim());
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
            setState(() {
              _emailSent = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Password reset email sent'),
                backgroundColor: Colors.green,
              ),
            );
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
                      'Forgot Password?',
                      style: Theme.of(context).textTheme.displayMediumPrimary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _emailSent
                          ? 'Check your email for password reset instructions'
                          : 'Enter your email address to reset your password',
                      style: Theme.of(context).textTheme.titleSmallPrimary,
                    ),
                    const SizedBox(height: 40),
                    if (!_emailSent) ...[
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
                        child: CustomTextFormField(
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
                      ),
                      const SizedBox(height: 30),
                      CustomElevatedButton(
                        width: double.infinity,
                        height: 56,
                        borderRadius: 30,
                        hasBorder: false,
                        backgroundColor: AppColors.fifthColor,
                        onPressed: authState.isLoading
                            ? null
                            : _handleResetPassword,
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
                                'Reset Password',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMediumPrimary,
                              ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.fourthColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.tertiaryColor),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              FontAwesomeIcons.circleCheck,
                              size: 64,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Email Sent!',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLargePrimary
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'We\'ve sent password reset instructions to ${_emailController.text}',
                              textAlign: TextAlign.center,
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmallPrimary,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Please check your email and follow the instructions to reset your password.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmallPrimary
                                  .copyWith(fontSize: 12),
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
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Back to Login',
                          style: Theme.of(context).textTheme.bodyMediumPrimary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (!_emailSent)
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              text: 'Remember your password? ',
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
