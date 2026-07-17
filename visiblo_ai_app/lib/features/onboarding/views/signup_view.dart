import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_logo.dart';
import '../../../app/widgets/app_primary_button.dart';
import '../../../app/widgets/app_social_button.dart';
import '../../../app/widgets/app_text_field.dart';
import '../controllers/onboarding_controller.dart';

class SignUpView extends GetView<OnboardingController> {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final headingStyle = AppTypography.section(
      fontSize: 30,
      fontWeight: FontWeight.w700,
    );
    final subtitleStyle = AppTypography.body(color: AppColors.mutedText);
    final fieldLabelStyle = AppTypography.label();
    final fieldValueStyle = AppTypography.body();
    final buttonLabelStyle = AppTypography.button(color: AppColors.white);
    final socialButtonLabelStyle = AppTypography.button();
    final bodyStyle = AppTypography.body(
      fontSize: AppTypography.bodyTextCompact,
      color: AppColors.mutedText,
    );
    final linkStyle = AppTypography.button(
      fontSize: AppTypography.bodyTextCompact,
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
    );
    final secondaryLinkStyle = AppTypography.button(
      fontSize: AppTypography.bodyTextCompact,
      color: AppColors.brandBlue,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight - 48),
            child: IntrinsicHeight(
              child: Form(
                key: controller.signUpFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: Get.back,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: 40,
                      ),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const AppLogo(iconSize: 40, fontSize: 35),
                    const SizedBox(height: 28),
                    Text('Start your 7-day free\ntrial!', style: headingStyle),
                    const SizedBox(height: 14),
                    Text(
                      'Create an account to continue!',
                      style: subtitleStyle,
                    ),
                    const SizedBox(height: 28),
                    AppTextField(
                      label: 'Full Name',
                      controller: controller.fullNameController,
                      textInputAction: TextInputAction.next,
                      validator: (value) => controller.validateRequired(
                        value,
                        fieldName: 'Full name',
                      ),
                      labelStyle: fieldLabelStyle,
                      textStyle: fieldValueStyle,
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: 'Email',
                      controller: controller.signUpEmailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: controller.validateEmail,
                      labelStyle: fieldLabelStyle,
                      textStyle: fieldValueStyle,
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: 'Phone (optional)',
                      controller: controller.signUpPhoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      labelStyle: fieldLabelStyle,
                      textStyle: fieldValueStyle,
                    ),
                    const SizedBox(height: 18),
                    Obx(
                      () => AppTextField(
                        label: 'Create a password',
                        controller: controller.signUpPasswordController,
                        obscureText: controller.obscureSignUpPassword.value,
                        textInputAction: TextInputAction.done,
                        validator: controller.validatePassword,
                        suffixIcon: IconButton(
                          onPressed: controller.toggleSignUpPassword,
                          icon: Icon(
                            controller.obscureSignUpPassword.value
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
                    const SizedBox(height: 22),
                    Obx(
                      () => AppPrimaryButton(
                        label: 'Try for free',
                        labelStyle: buttonLabelStyle,
                        isLoading: controller.isSignUpLoading.value,
                        onPressed: controller.submitSignUp,
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
                    const SizedBox(height: 10),
                    Text(
                      'For Google-linked businesses, use Google sign-in. No password is needed there.',
                      style: AppTypography.body(
                        fontSize: AppTypography.bodyTextCompact,
                        color: AppColors.mutedText,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          style: bodyStyle,
                          children: [
                            const TextSpan(
                              text: 'By signing up, you agree to our ',
                            ),
                            TextSpan(
                              text: 'terms of use',
                              style: linkStyle,
                              recognizer: TapGestureRecognizer()
                                ..onTap = controller.openTermsDocument,
                            ),
                            const TextSpan(text: ' and\n'),
                            TextSpan(
                              text: 'privacy policy',
                              style: linkStyle,
                              recognizer: TapGestureRecognizer()
                                ..onTap = controller.openPrivacyPolicyDocument,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Already have an account?  ', style: bodyStyle),
                          GestureDetector(
                            onTap: () => Get.offAllNamed(AppRoutes.login),
                            child: Text('Login', style: secondaryLinkStyle),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
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
