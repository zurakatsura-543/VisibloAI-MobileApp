import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_logo.dart';
import '../../../app/widgets/app_primary_button.dart';
import '../../../app/widgets/app_social_button.dart';
import '../../../app/widgets/app_text_field.dart';
import '../controllers/onboarding_controller.dart';

class LoginView extends GetView<OnboardingController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headingStyle = AppTypography.section(
      fontSize: 30,
      fontWeight: FontWeight.w700,
    );
    final subtitleStyle = AppTypography.body(color: AppColors.mutedText);
    final fieldLabelStyle = AppTypography.label();
    final fieldValueStyle = AppTypography.body();
    final actionLinkStyle = AppTypography.button(
      fontSize: 14.5,
      color: AppColors.brandBlue,
      fontWeight: FontWeight.w600,
    );
    final buttonLabelStyle = AppTypography.button(color: AppColors.white);
    final socialButtonLabelStyle = AppTypography.button();
    final bodyStyle = AppTypography.body(
      fontSize: AppTypography.bodyTextCompact,
      color: AppColors.mutedText,
    );
    final secondaryLinkStyle = AppTypography.button(
      fontSize: AppTypography.bodyTextCompact,
      color: AppColors.brandBlue,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight - 64),
            child: IntrinsicHeight(
              child: Form(
                key: controller.loginFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLogo(iconSize: 40, fontSize: 35),
                    const SizedBox(height: 30),
                    Text('Sign in to your\nAccount', style: headingStyle),
                    const SizedBox(height: 14),
                    Text(
                      'Enter your email and password to log in',
                      style: subtitleStyle,
                    ),
                    const SizedBox(height: 28),
                    AppTextField(
                      label: 'Email',
                      controller: controller.loginEmailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: controller.validateEmail,
                      labelStyle: fieldLabelStyle,
                      textStyle: fieldValueStyle,
                    ),
                    const SizedBox(height: 18),
                    Obx(
                      () => AppTextField(
                        label: 'Password',
                        controller: controller.loginPasswordController,
                        obscureText: controller.obscureLoginPassword.value,
                        textInputAction: TextInputAction.done,
                        validator: controller.validatePassword,
                        suffixIcon: IconButton(
                          onPressed: controller.toggleLoginPassword,
                          icon: Icon(
                            controller.obscureLoginPassword.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.mutedText,
                            size: 20,
                          ),
                        ),
                        labelStyle: fieldLabelStyle,
                        textStyle: fieldValueStyle,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: controller.goToForgotPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.brandBlue,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot Password ?',
                          style: actionLinkStyle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Obx(
                      () => AppPrimaryButton(
                        label: 'Log In',
                        labelStyle: buttonLabelStyle,
                        isLoading: controller.isLoginLoading.value,
                        onPressed: () => controller.submitLogin(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.line)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Or', style: bodyStyle),
                        ),
                        const Expanded(child: Divider(color: AppColors.line)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Obx(
                      () => AppSocialButton(
                        label: 'Continue with Google',
                        assetPath: 'assets/icons/google_logo.svg',
                        labelStyle: socialButtonLabelStyle,
                        isLoading: controller.isGoogleSignInLoading.value,
                        onPressed: () => controller.continueWithGoogle(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Don’t have an account?  ', style: bodyStyle),
                          GestureDetector(
                            onTap: controller.goToSignUp,
                            child: Text('Sign Up', style: secondaryLinkStyle),
                          ),
                        ],
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
