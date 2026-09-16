import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/auth_screen_shell.dart';

class LoginView extends GetView<OnboardingController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final showAppleSignIn =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    return AuthScreenShell(
      title: 'Welcome Back',
      subtitle: 'Sign in to manage your business growth with AI.',
      child: Form(
        key: controller.loginFormKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 520;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthInputField(
                  hintText: 'Email address',
                  controller: controller.loginEmailController,
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: controller.validateEmail,
                ),
                const SizedBox(height: 14),
                Obx(
                  () => AuthInputField(
                    hintText: 'Password',
                    controller: controller.loginPasswordController,
                    icon: Icons.lock_outline_rounded,
                    obscureText: controller.obscureLoginPassword.value,
                    textInputAction: TextInputAction.done,
                    validator: controller.validatePassword,
                    suffixIcon: IconButton(
                      onPressed: controller.toggleLoginPassword,
                      icon: Icon(
                        controller.obscureLoginPassword.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.brandBlue,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Obx(
                  () => AuthBackgroundActionRow(
                    leading: InkWell(
                      onTap: controller.toggleRememberMe,
                      borderRadius: BorderRadius.circular(999),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            controller.rememberMe.value
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Remember me',
                            style: AppTypography.body(
                              fontSize: 14.2,
                              color: AppColors.brandBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: GestureDetector(
                      onTap: controller.goToForgotPassword,
                      child: Text(
                        'Forgot Password?',
                        style: AppTypography.body(
                          fontSize: 14.2,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Obx(
                  () => AuthPrimaryButton(
                    label: 'Log In',
                    isLoading: controller.isLoginLoading.value,
                    onPressed: controller.submitLogin,
                  ),
                ),
                const SizedBox(height: 18),
                const AuthOrDivider(),
                const SizedBox(height: 18),
                if (showAppleSignIn && constraints.maxWidth >= 300) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => AuthGoogleButton(
                            isLoading: controller.isGoogleSignInLoading.value,
                            onPressed: controller.continueWithGoogle,
                            compact: !isTablet,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(
                          () => AuthAppleButton(
                            isLoading: controller.isAppleSignInLoading.value,
                            onPressed: controller.continueWithApple,
                            compact: !isTablet,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Obx(
                    () => AuthGoogleButton(
                      isLoading: controller.isGoogleSignInLoading.value,
                      onPressed: controller.continueWithGoogle,
                    ),
                  ),
                  if (showAppleSignIn) ...[
                    const SizedBox(height: 12),
                    Obx(
                      () => AuthAppleButton(
                        isLoading: controller.isAppleSignInLoading.value,
                        onPressed: controller.continueWithApple,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 22),
                AuthBottomLink(
                  prompt: 'Don’t have an account? ',
                  action: 'Sign Up',
                  onTap: controller.goToSignUp,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
