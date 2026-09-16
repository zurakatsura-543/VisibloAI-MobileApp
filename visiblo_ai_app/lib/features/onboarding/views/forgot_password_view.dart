import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_logo.dart';
import '../../../app/widgets/app_primary_button.dart';
import '../../../app/widgets/app_text_field.dart';
import '../controllers/onboarding_controller.dart';

class ForgotPasswordView extends GetView<OnboardingController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
          child: Form(
            key: controller.forgotPasswordFormKey,
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
                const SizedBox(height: 10),
                const AppLogo(iconSize: 28, fontSize: 24),
                const SizedBox(height: 28),
                Text(
                  'Forgot your\npassword?',
                  style: AppTypography.section(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Enter the email linked to your account and we will send a 6-digit OTP for password reset.',
                  style: AppTypography.body(color: AppColors.mutedText),
                ),
                const SizedBox(height: 30),
                AppTextField(
                  label: 'Email',
                  controller: controller.forgotPasswordEmailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: controller.validateEmail,
                ),
                const SizedBox(height: 22),
                Obx(
                  () => AppPrimaryButton(
                    label: 'Send reset OTP',
                    isLoading: controller.isForgotPasswordLoading.value,
                    onPressed: controller.submitForgotPassword,
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Remember your password?  ',
                        style: AppTypography.body(
                          fontSize: AppTypography.bodyTextCompact,
                          color: AppColors.mutedText,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.offNamed(AppRoutes.login),
                        child: Text(
                          'Log In',
                          style: AppTypography.button(
                            fontSize: AppTypography.bodyTextCompact,
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
