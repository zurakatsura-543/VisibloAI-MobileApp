import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_logo.dart';
import '../../../app/widgets/app_primary_button.dart';
import '../../../app/widgets/app_text_field.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/auth_screen_shell.dart';

class OtpVerificationView extends GetView<OnboardingController> {
  const OtpVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Obx(() {
      final isPasswordReset = controller.pendingOtpFlow.value == 'PASSWORD_RESET';
      if (isPasswordReset) {
        return _PasswordResetOtpView(controller: controller, screenHeight: screenHeight);
      }

      return _SignupOtpView(controller: controller);
    });
  }
}

class _SignupOtpView extends StatelessWidget {
  const _SignupOtpView({required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      showBackButton: true,
      onBack: Get.back,
      title: 'Verify your email',
      subtitle: 'We sent a 6-digit verification code to\n${_maskEmail(controller.pendingOtpEmail.value)}',
      bannerAssetPath: 'assets/images/app-banner3.png',
      bannerHeight: 244,
      child: Form(
        key: controller.otpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: controller.otpCodeController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              validator: controller.validateOtpCode,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              textAlign: TextAlign.center,
              style: AppTypography.section(
                fontSize: 30,
                height: 1.1,
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w700,
                letterSpacing: 10,
              ),
              decoration: InputDecoration(
                hintText: '000000',
                counterText: '',
                hintStyle: AppTypography.section(
                  fontSize: 30,
                  height: 1.1,
                  color: const Color(0xFFB8C5D8),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 10,
                ),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 18,
                ),
                enabledBorder: _otpBorder(),
                focusedBorder: _otpBorder(color: const Color(0xFF6C7BFF), width: 1.7),
                errorBorder: _otpBorder(color: Colors.red.shade300, width: 1.5),
                focusedErrorBorder: _otpBorder(
                  color: Colors.red.shade300,
                  width: 1.5,
                ),
                border: _otpBorder(),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Didn’t receive the code?',
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 15.2,
                color: AppColors.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: controller.isResendOtpLoading.value
                    ? null
                    : controller.resendSignupOtp,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: controller.isResendOtpLoading.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Resend OTP',
                        style: AppTypography.body(
                          fontSize: 15.5,
                          color: const Color(0xFF2F5DFF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => Get.offAllNamed(AppRoutes.signUp),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Back to Sign Up',
                  style: AppTypography.body(
                    fontSize: 15.5,
                    color: const Color(0xFF2F5DFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Obx(
              () => AuthPrimaryButton(
                label: 'Verify Email',
                isLoading: controller.isOtpLoading.value,
                onPressed: controller.submitOtpVerification,
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FE),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE8EDFB)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F3FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      color: Color(0xFF5A6CFF),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Please check your spam folder',
                          style: AppTypography.body(
                            fontSize: 15,
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'If you can’t find the email, request a fresh OTP.',
                          style: AppTypography.body(
                            fontSize: 13.4,
                            color: AppColors.mutedText,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _otpBorder({
    Color color = const Color(0xFFD9E2F6),
    double width = 1.25,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _PasswordResetOtpView extends StatelessWidget {
  const _PasswordResetOtpView({
    required this.controller,
    required this.screenHeight,
  });

  final OnboardingController controller;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight - 56),
            child: IntrinsicHeight(
              child: Form(
                key: controller.otpFormKey,
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
                    const Center(child: AppLogo(iconSize: 58, centered: true)),
                    const SizedBox(height: 24),
                    Text(
                      'Reset your\npassword',
                      style: AppTypography.section(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Enter the 6-digit OTP sent to ${controller.pendingOtpEmail.value} and choose a secure new password.',
                      style: AppTypography.body(color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 30),
                    AppTextField(
                      label: 'OTP Code',
                      hintText: '6-digit code',
                      controller: controller.otpCodeController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: controller.validateOtpCode,
                    ),
                    const SizedBox(height: 18),
                    Obx(
                      () => AppTextField(
                        label: 'New Password',
                        hintText:
                            'At least 8 chars, 1 uppercase, 1 number, 1 symbol',
                        controller: controller.resetPasswordController,
                        obscureText: controller.obscureResetPassword.value,
                        textInputAction: TextInputAction.next,
                        validator: controller.validatePassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            controller.obscureResetPassword.value =
                                !controller.obscureResetPassword.value;
                          },
                          icon: Icon(
                            controller.obscureResetPassword.value
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller.resetPasswordController,
                      builder: (context, value, _) {
                        final password = value.text;
                        final strength = _getPasswordStrength(password);
                        final rules = _buildPasswordRules(password);

                        if (password.isEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Password rules',
                                style: AppTypography.label(
                                  color: AppColors.mutedText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...rules.map(
                                (rule) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: _PasswordRuleRow(
                                    label: rule.label,
                                    satisfied: rule.satisfied,
                                    idle: true,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: strength.progress,
                                      minHeight: 6,
                                      backgroundColor: AppColors.line,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        strength.color,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  strength.label,
                                  style: AppTypography.label(
                                    color: strength.color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...rules.map(
                              (rule) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _PasswordRuleRow(
                                  label: rule.label,
                                  satisfied: rule.satisfied,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Obx(
                      () => AppTextField(
                        label: 'Confirm Password',
                        hintText: 'Re-enter your new password',
                        controller: controller.confirmResetPasswordController,
                        obscureText:
                            controller.obscureConfirmResetPassword.value,
                        textInputAction: TextInputAction.done,
                        validator: controller.validateConfirmPassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            controller.obscureConfirmResetPassword.value =
                                !controller.obscureConfirmResetPassword.value;
                          },
                          icon: Icon(
                            controller.obscureConfirmResetPassword.value
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller.confirmResetPasswordController,
                      builder: (context, confirmValue, _) {
                        final confirmPassword = confirmValue.text;
                        final password = controller.resetPasswordController.text;

                        if (confirmPassword.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final matches = confirmPassword == password;
                        return Row(
                          children: [
                            Icon(
                              matches
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 18,
                              color: matches
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                matches
                                    ? 'Confirm password matches your new password.'
                                    : 'Confirm password does not match your new password yet.',
                                style: AppTypography.label(
                                  color: matches
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFEF4444),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    AppPrimaryButton(
                      label: 'Reset Password',
                      isLoading: controller.isOtpLoading.value,
                      onPressed: controller.submitOtpVerification,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: controller.isResendOtpLoading.value
                          ? null
                          : controller.resendSignupOtp,
                      child: controller.isResendOtpLoading.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Resend OTP',
                              style: AppTypography.button(
                                color: AppColors.brandBlue,
                                fontWeight: FontWeight.w700,
                              ),
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

String _maskEmail(String email) {
  final normalized = email.trim();
  if (!normalized.contains('@')) {
    return normalized;
  }

  final parts = normalized.split('@');
  final local = parts.first;
  final domain = parts.last;
  if (local.length <= 2) {
    return '${local[0]}*****@$domain';
  }
  return '${local.substring(0, 2)}*****@$domain';
}

_PasswordStrength _getPasswordStrength(String password) {
  if (password.isEmpty) {
    return const _PasswordStrength(
      label: 'Start typing',
      color: AppColors.mutedText,
      progress: 0,
    );
  }

  var score = 0;
  if (password.length >= 8) score++;
  if (RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'[0-9]').hasMatch(password)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;

  if (score <= 1) {
    return const _PasswordStrength(
      label: 'Weak password',
      color: Color(0xFFEF4444),
      progress: 0.25,
    );
  }
  if (score <= 2) {
    return const _PasswordStrength(
      label: 'Fair password',
      color: Color(0xFFF59E0B),
      progress: 0.5,
    );
  }
  if (score <= 3) {
    return const _PasswordStrength(
      label: 'Good password',
      color: Color(0xFF22C55E),
      progress: 0.75,
    );
  }
  return const _PasswordStrength(
    label: 'Strong password',
    color: Color(0xFF16A34A),
    progress: 1,
  );
}

List<_PasswordRule> _buildPasswordRules(String password) {
  return [
    _PasswordRule(
      label: 'Minimum 8 characters',
      satisfied: password.length >= 8,
    ),
    _PasswordRule(
      label: 'At least 1 uppercase letter',
      satisfied: RegExp(r'[A-Z]').hasMatch(password),
    ),
    _PasswordRule(
      label: 'At least 1 number',
      satisfied: RegExp(r'[0-9]').hasMatch(password),
    ),
    _PasswordRule(
      label: 'At least 1 special character',
      satisfied: RegExp(r'[^A-Za-z0-9]').hasMatch(password),
    ),
  ];
}

class _PasswordRule {
  const _PasswordRule({
    required this.label,
    required this.satisfied,
  });

  final String label;
  final bool satisfied;
}

class _PasswordStrength {
  const _PasswordStrength({
    required this.label,
    required this.color,
    required this.progress,
  });

  final String label;
  final Color color;
  final double progress;
}

class _PasswordRuleRow extends StatelessWidget {
  const _PasswordRuleRow({
    required this.label,
    required this.satisfied,
    this.idle = false,
  });

  final String label;
  final bool satisfied;
  final bool idle;

  @override
  Widget build(BuildContext context) {
    final color = idle
        ? AppColors.mutedText
        : satisfied
        ? const Color(0xFF16A34A)
        : const Color(0xFFEF4444);

    return Row(
      children: [
        Icon(
          satisfied ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.body(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
