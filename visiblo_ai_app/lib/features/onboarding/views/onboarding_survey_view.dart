import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_primary_button.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/onboarding_intro_layout.dart';

class OnboardingSurveyView extends StatefulWidget {
  const OnboardingSurveyView({super.key});

  @override
  State<OnboardingSurveyView> createState() => _OnboardingSurveyViewState();
}

class _OnboardingSurveyViewState extends State<OnboardingSurveyView> {
  bool _showSurveyQuestions = false;

  void _openSurveyQuestions() {
    setState(() {
      _showSurveyQuestions = true;
    });
  }

  void _backToIntro() {
    setState(() {
      _showSurveyQuestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _showSurveyQuestions
          ? _SurveyQuestionsScreen(
              key: const ValueKey('survey-questions'),
              onBack: _backToIntro,
            )
          : _SurveyIntroScreen(
              key: const ValueKey('survey-intro'),
              onGetStarted: _openSurveyQuestions,
            ),
    );
  }
}

class _SurveyIntroScreen extends StatelessWidget {
  const _SurveyIntroScreen({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();
    return Scaffold(
      body: SafeArea(
        child: OnboardingIntroLayout(
          onPressed: onGetStarted,
          onOpenTerms: controller.openTermsDocument,
          onOpenPrivacy: controller.openPrivacyPolicyDocument,
        ),
      ),
    );
  }
}

class _SurveyQuestionsScreen extends GetView<OnboardingController> {
  const _SurveyQuestionsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: onBack,
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
              const SizedBox(height: 8),
              Text(
                'Tell us a bit about\nyour business',
                style: AppTypography.section(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'These answers help VisibloAI set up your onboarding flow correctly.',
                style: AppTypography.body(color: AppColors.mutedText),
              ),
              const SizedBox(height: 26),
              _SurveyQuestion(
                title: 'What best describes your role?',
                value: controller.selectedSurveyRole,
                options: controller.surveyRoles,
                labelBuilder: controller.labelForSurveyRole,
              ),
              const SizedBox(height: 20),
              _SurveyQuestion(
                title: 'How much SEO experience do you have?',
                value: controller.selectedSurveySeoExperience,
                options: controller.surveySeoExperiences,
                labelBuilder: controller.labelForSurveySeoExperience,
              ),
              const SizedBox(height: 20),
              _SurveyQuestion(
                title: 'How large is your organization?',
                value: controller.selectedSurveyOrgSize,
                options: controller.surveyOrgSizes,
                labelBuilder: controller.labelForSurveyOrgSize,
              ),
              const SizedBox(height: 20),
              _SurveyQuestion(
                title: 'How did you hear about us?',
                value: controller.selectedSurveyHeardFrom,
                options: controller.surveyHeardFromValues,
                labelBuilder: controller.labelForSurveyHeardFrom,
              ),
              const SizedBox(height: 28),
              Obx(
                () => AppPrimaryButton(
                  label: 'Continue',
                  isLoading: controller.isSurveyLoading.value,
                  onPressed: controller.submitSurveyStep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurveyQuestion extends GetView<OnboardingController> {
  const _SurveyQuestion({
    required this.title,
    required this.value,
    required this.options,
    required this.labelBuilder,
  });

  final String title;
  final RxnString value;
  final List<String> options;
  final String Function(String) labelBuilder;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.button(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((option) {
              final isSelected = value.value == option;
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => value.value = option,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFFDDE4ED),
                    ),
                  ),
                  child: Text(
                    labelBuilder(option),
                    style: AppTypography.label(
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
