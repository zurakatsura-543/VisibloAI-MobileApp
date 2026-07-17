import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_logo.dart';
import '../../../app/widgets/app_primary_button.dart';
import '../../../app/widgets/app_text_field.dart';
import '../controllers/onboarding_controller.dart';

class OtpVerificationView extends GetView<OnboardingController> {
  const OtpVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight - 56),
            child: IntrinsicHeight(
              child: Form(
                key: controller.otpFormKey,
                child: Obx(
                  () {
                    final isPasswordReset =
                        controller.pendingOtpFlow.value == 'PASSWORD_RESET';

                    return Column(
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
                          isPasswordReset
                              ? 'Reset your\npassword'
                              : 'Verify your\nemail',
                          style: AppTypography.section(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          isPasswordReset
                              ? 'Enter the 6-digit OTP sent to ${controller.pendingOtpEmail.value} and choose a secure new password.'
                              : 'Enter the 6-digit OTP sent to ${controller.pendingOtpEmail.value}.',
                          style: AppTypography.body(
                            color: AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: 30),
                        AppTextField(
                          label: 'OTP Code',
                          hintText: '6-digit code',
                          controller: controller.otpCodeController,
                          keyboardType: TextInputType.number,
                          textInputAction: isPasswordReset
                              ? TextInputAction.next
                              : TextInputAction.done,
                          validator: controller.validateOtpCode,
                        ),
                        if (isPasswordReset) ...[
                          const SizedBox(height: 18),
                          AppTextField(
                            label: 'New Password',
                            hintText: 'At least 8 chars, 1 uppercase, 1 number, 1 symbol',
                            controller: controller.resetPasswordController,
                            obscureText:
                                controller.obscureResetPassword.value,
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
                          AppTextField(
                            label: 'Confirm Password',
                            hintText: 'Re-enter your new password',
                            controller:
                                controller.confirmResetPasswordController,
                            obscureText:
                                controller.obscureConfirmResetPassword.value,
                            textInputAction: TextInputAction.done,
                            validator: controller.validateConfirmPassword,
                            suffixIcon: IconButton(
                              onPressed: () {
                                controller.obscureConfirmResetPassword.value =
                                    !controller
                                        .obscureConfirmResetPassword.value;
                              },
                              icon: Icon(
                                controller.obscureConfirmResetPassword.value
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        AppPrimaryButton(
                          label: isPasswordReset
                              ? 'Reset Password'
                              : 'Verify OTP',
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
