import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_responsive.dart';
import '../../../app/theme/app_typography.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/auth_screen_shell.dart';

class SignUpView extends GetView<OnboardingController> {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      showBackButton: true,
      onBack: Get.back,
      title: 'Create Your Account',
      subtitle: 'Start your business growth journey with AI.',
      child: Form(
        key: controller.signUpFormKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 520;

            final fullNameField = AuthInputField(
              hintText: 'Full name',
              controller: controller.fullNameController,
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (value) => controller.validateRequired(
                value,
                fieldName: 'Full name',
              ),
            );

            final emailField = AuthInputField(
              hintText: 'Email address',
              controller: controller.signUpEmailController,
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: controller.validateEmail,
            );

            final phoneField = Obx(
              () => _PhoneNumberField(
                country: _supportedPhoneCountries.firstWhere(
                  (country) =>
                      country.isoCode ==
                      controller.selectedSignUpPhoneCountryIso.value,
                  orElse: () => _supportedPhoneCountries.first,
                ),
                controller: controller.signUpPhoneController,
                onCountrySelected: (country) {
                  controller.updateSignUpPhoneCountry(
                    isoCode: country.isoCode,
                    name: country.name,
                    dialCode: country.dialCode,
                  );
                },
                validator: (value) => _validatePhoneNumber(
                  value,
                  _supportedPhoneCountries.firstWhere(
                    (country) =>
                        country.isoCode ==
                        controller.selectedSignUpPhoneCountryIso.value,
                    orElse: () => _supportedPhoneCountries.first,
                  ),
                ),
              ),
            );

            final passwordField = Obx(
              () => AuthInputField(
                hintText: 'Password',
                controller: controller.signUpPasswordController,
                icon: Icons.lock_outline_rounded,
                obscureText: controller.obscureSignUpPassword.value,
                textInputAction: TextInputAction.next,
                validator: controller.validatePassword,
                suffixIcon: IconButton(
                  onPressed: controller.toggleSignUpPassword,
                  icon: Icon(
                    controller.obscureSignUpPassword.value
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.brandBlue,
                    size: 22,
                  ),
                ),
              ),
            );

            final confirmPasswordField = Obx(
              () => AuthInputField(
                hintText: 'Confirm password',
                controller: controller.signUpConfirmPasswordController,
                icon: Icons.lock_outline_rounded,
                obscureText: controller.obscureSignUpConfirmPassword.value,
                textInputAction: TextInputAction.done,
                validator: controller.validateSignUpConfirmPassword,
                suffixIcon: IconButton(
                  onPressed: controller.toggleSignUpConfirmPassword,
                  icon: Icon(
                    controller.obscureSignUpConfirmPassword.value
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.brandBlue,
                    size: 22,
                  ),
                ),
              ),
            );

            final passwordRulesWidget = ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller.signUpPasswordController,
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
                        style: AppTypography.label(color: AppColors.mutedText),
                      ),
                      const SizedBox(height: 8),
                      if (isTablet)
                        Wrap(
                          spacing: 16,
                          runSpacing: 6,
                          children: rules
                              .map(
                                (rule) => _PasswordRuleRow(
                                  label: rule.label,
                                  satisfied: rule.satisfied,
                                  idle: true,
                                ),
                              )
                              .toList(),
                        )
                      else
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
                    if (isTablet)
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: rules
                            .map(
                              (rule) => _PasswordRuleRow(
                                label: rule.label,
                                satisfied: rule.satisfied,
                              ),
                            )
                            .toList(),
                      )
                    else
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
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isTablet) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: fullNameField),
                      const SizedBox(width: 14),
                      Expanded(child: emailField),
                    ],
                  ),
                  const SizedBox(height: 14),
                  phoneField,
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: passwordField),
                      const SizedBox(width: 14),
                      Expanded(child: confirmPasswordField),
                    ],
                  ),
                  const SizedBox(height: 10),
                  passwordRulesWidget,
                ] else ...[
                  fullNameField,
                  const SizedBox(height: 14),
                  emailField,
                  const SizedBox(height: 14),
                  phoneField,
                  const SizedBox(height: 14),
                  passwordField,
                  const SizedBox(height: 10),
                  passwordRulesWidget,
                  const SizedBox(height: 14),
                  confirmPasswordField,
                ],
                const SizedBox(height: 14),
                AuthAgreementRow(
                  onTermsTap: controller.openTermsDocument,
                  onPrivacyTap: controller.openPrivacyPolicyDocument,
                ),
                const SizedBox(height: 16),
                Obx(
                  () => AuthPrimaryButton(
                    label: 'Sign Up',
                    isLoading: controller.isSignUpLoading.value,
                    onPressed: controller.submitSignUp,
                  ),
                ),
                const SizedBox(height: 18),
                const AuthOrDivider(),
                const SizedBox(height: 18),
                if (isTablet && Theme.of(context).platform == TargetPlatform.iOS) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => AuthGoogleButton(
                            isLoading: controller.isGoogleSignInLoading.value,
                            onPressed: controller.continueWithGoogle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Obx(
                          () => AuthAppleButton(
                            isLoading: controller.isAppleSignInLoading.value,
                            onPressed: controller.continueWithApple,
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
                  if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                    const SizedBox(height: 12),
                    Obx(
                      () => AuthAppleButton(
                        isLoading: controller.isAppleSignInLoading.value,
                        onPressed: controller.continueWithApple,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 18),
                AuthBottomLink(
                  prompt: 'Already have an account? ',
                  action: 'Log In',
                  onTap: () => Get.offAllNamed(AppRoutes.login),
                ),
                const SizedBox(height: 12),
                Text(
                  'For Google-linked businesses, use Google sign-in. No password is needed there.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    fontSize: 13.2,
                    color: AppColors.mutedText,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

const _supportedPhoneCountries = <_PhoneCountry>[
  _PhoneCountry(
    isoCode: 'IN',
    flag: '🇮🇳',
    name: 'India',
    dialCode: '+91',
    localLength: 10,
  ),
  _PhoneCountry(
    isoCode: 'SA',
    flag: '🇸🇦',
    name: 'Saudi Arabia',
    dialCode: '+966',
    localLength: 9,
  ),
  _PhoneCountry(
    isoCode: 'AE',
    flag: '🇦🇪',
    name: 'UAE',
    dialCode: '+971',
    localLength: 9,
  ),
  _PhoneCountry(
    isoCode: 'QA',
    flag: '🇶🇦',
    name: 'Qatar',
    dialCode: '+974',
    localLength: 8,
  ),
  _PhoneCountry(
    isoCode: 'KW',
    flag: '🇰🇼',
    name: 'Kuwait',
    dialCode: '+965',
    localLength: 8,
  ),
  _PhoneCountry(
    isoCode: 'BH',
    flag: '🇧🇭',
    name: 'Bahrain',
    dialCode: '+973',
    localLength: 8,
  ),
  _PhoneCountry(
    isoCode: 'OM',
    flag: '🇴🇲',
    name: 'Oman',
    dialCode: '+968',
    localLength: 8,
  ),
  _PhoneCountry(
    isoCode: 'US',
    flag: '🇺🇸',
    name: 'United States',
    dialCode: '+1',
    localLength: 10,
  ),
  _PhoneCountry(
    isoCode: 'CA',
    flag: '🇨🇦',
    name: 'Canada',
    dialCode: '+1',
    localLength: 10,
  ),
  _PhoneCountry(
    isoCode: 'ZA',
    flag: '🇿🇦',
    name: 'South Africa',
    dialCode: '+27',
    localLength: 9,
  ),
];

String? _validatePhoneNumber(String? value, _PhoneCountry country) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) {
    return null;
  }

  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == country.localLength + 1 && digits.startsWith('0')) {
    digits = digits.substring(1);
  }

  if (digits.length != country.localLength) {
    return 'Enter a valid ${country.localLength}-digit mobile number';
  }

  if (country.isoCode == 'IN' && !RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
    return 'Enter a valid Indian mobile number';
  }

  return null;
}

class _PhoneCountry {
  const _PhoneCountry({
    required this.isoCode,
    required this.flag,
    required this.name,
    required this.dialCode,
    required this.localLength,
  });

  final String isoCode;
  final String flag;
  final String name;
  final String dialCode;
  final int localLength;
}

class _PhoneNumberField extends StatelessWidget {
  const _PhoneNumberField({
    required this.country,
    required this.controller,
    required this.onCountrySelected,
    required this.validator,
  });

  final _PhoneCountry country;
  final TextEditingController controller;
  final ValueChanged<_PhoneCountry> onCountrySelected;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTabletOrLarger;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showCountryPicker(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: isTablet ? 62 : 58,
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 14 : 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD7E4F1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF4FD),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    country.isoCode,
                    style: AppTypography.body(
                      fontSize: isTablet ? 13.5 : 12.0,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  country.dialCode,
                  style: AppTypography.body(
                    fontSize: isTablet ? 16.0 : 14.4,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.brandBlue,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AuthInputField(
            hintText: 'Mobile number',
            controller: controller,
            icon: Icons.smartphone_rounded,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: validator,
          ),
        ),
      ],
    );
  }

  Future<void> _showCountryPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<_PhoneCountry>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            itemCount: _supportedPhoneCountries.length,
            separatorBuilder: (_, _) => const Divider(
              height: 1,
              color: Color(0xFFE7EEF7),
            ),
            itemBuilder: (context, index) {
              final item = _supportedPhoneCountries[index];
              return ListTile(
                onTap: () => Navigator.of(context).pop(item),
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF4FD),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.isoCode,
                    style: AppTypography.body(
                      fontSize: 13,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  item.name,
                  style: AppTypography.body(
                    fontSize: 15.5,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Text(
                  item.dialCode,
                  style: AppTypography.body(
                    fontSize: 14.5,
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (selected != null) {
      onCountrySelected(selected);
    }
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
