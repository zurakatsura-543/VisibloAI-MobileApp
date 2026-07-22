import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_logo.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/onboarding_intro_layout.dart';

class OnboardingSurveyView extends StatefulWidget {
  const OnboardingSurveyView({super.key});

  @override
  State<OnboardingSurveyView> createState() => _OnboardingSurveyViewState();
}

class _OnboardingSurveyViewState extends State<OnboardingSurveyView> {
  bool _showSurveyQuestions = false;
  int _currentQuestion = 0;
  String? _selectedRole;
  String? _selectedLocationType;

  void _openSurveyQuestions() {
    setState(() {
      _showSurveyQuestions = true;
      _currentQuestion = 0;
    });
  }

  void _backToIntro() {
    setState(() {
      _showSurveyQuestions = false;
      _currentQuestion = 0;
    });
  }

  void _goToNextQuestion() {
    if (_selectedRole == null) {
      Get.snackbar(
        'Select your role',
        'Please choose the option that best matches your role before continuing.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _currentQuestion = 1;
    });
  }

  Future<void> _submitTwoStepSurvey() async {
    if (_selectedLocationType == null) {
      Get.snackbar(
        'Select your setup',
        'Please choose whether you manage a single location or multiple locations.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final controller = Get.find<OnboardingController>();
    controller.selectedSurveyRole.value = _selectedRole;
    controller.selectedSurveySeoExperience.value = 'zero';
    controller.selectedSurveyHeardFrom.value = 'other';
    controller.selectedSurveyOrgSize.value = _selectedLocationType == 'single'
        ? 'solo'
        : '2-10';

    await controller.submitSurveyStep();
  }

  void _handleQuestionBack() {
    if (_currentQuestion == 0) {
      _backToIntro();
      return;
    }

    setState(() {
      _currentQuestion = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _showSurveyQuestions
          ? _SurveyQuestionFlow(
              key: ValueKey('survey-flow-$_currentQuestion'),
              currentQuestion: _currentQuestion,
              selectedRole: _selectedRole,
              selectedLocationType: _selectedLocationType,
              onBack: _handleQuestionBack,
              onRoleSelected: (value) {
                setState(() {
                  _selectedRole = value;
                });
              },
              onLocationTypeSelected: (value) {
                setState(() {
                  _selectedLocationType = value;
                });
              },
              onNext: _goToNextQuestion,
              onDone: _submitTwoStepSurvey,
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

class _SurveyQuestionFlow extends GetView<OnboardingController> {
  const _SurveyQuestionFlow({
    super.key,
    required this.currentQuestion,
    required this.selectedRole,
    required this.selectedLocationType,
    required this.onBack,
    required this.onRoleSelected,
    required this.onLocationTypeSelected,
    required this.onNext,
    required this.onDone,
  });

  final int currentQuestion;
  final String? selectedRole;
  final String? selectedLocationType;
  final VoidCallback onBack;
  final ValueChanged<String> onRoleSelected;
  final ValueChanged<String> onLocationTypeSelected;
  final VoidCallback onNext;
  final Future<void> Function() onDone;

  bool get isFirstQuestion => currentQuestion == 0;

  @override
  Widget build(BuildContext context) {
    final roleOptions = [
      _SurveyOptionData(
        value: 'business_owner',
        title: controller.labelForSurveyRole('business_owner'),
        icon: Icons.work_rounded,
        colors: const [Color(0xFFFFB347), Color(0xFFFF8A34)],
      ),
      _SurveyOptionData(
        value: 'agency',
        title: controller.labelForSurveyRole('agency'),
        icon: Icons.groups_rounded,
        colors: const [Color(0xFF4A8DFF), Color(0xFF2E66ED)],
      ),
      _SurveyOptionData(
        value: 'ceo',
        title: controller.labelForSurveyRole('ceo'),
        icon: Icons.person_rounded,
        colors: const [Color(0xFFBC64FF), Color(0xFF8D58F9)],
      ),
      _SurveyOptionData(
        value: 'marketing',
        title: controller.labelForSurveyRole('marketing'),
        icon: Icons.campaign_rounded,
        colors: const [Color(0xFF3ED7CD), Color(0xFF39B4BD)],
      ),
      _SurveyOptionData(
        value: 'other',
        title: controller.labelForSurveyRole('other'),
        icon: Icons.more_horiz_rounded,
        colors: const [Color(0xFFA0A9B8), Color(0xFF7F8794)],
      ),
    ];

    final locationOptions = [
      const _SurveyOptionData(
        value: 'single',
        title: 'Single Location',
        subtitle: 'I manage one business location.',
        icon: Icons.storefront_rounded,
        colors: [Color(0xFF4A8DFF), Color(0xFF2E66ED)],
      ),
      const _SurveyOptionData(
        value: 'multi',
        title: 'Multiple Locations',
        subtitle: 'I manage more than one business location.',
        icon: Icons.apartment_rounded,
        colors: [Color(0xFF3ED7CD), Color(0xFF39B4BD)],
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFEFF), Color(0xFFF6FBFF)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                top: 180,
                left: -46,
                child: _BackgroundGlow(
                  size: 144,
                  colors: [Color(0x1239B4BD), Color(0x08305DEB)],
                ),
              ),
              const Positioned(
                top: 240,
                right: -36,
                child: _BackgroundGlow(
                  size: 124,
                  colors: [Color(0x10305DEB), Color(0x0839B4BD)],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _BackButtonCircle(onPressed: onBack),
                        const Spacer(),
                        const AppLogo(iconSize: 34, centered: true),
                        const Spacer(),
                        const SizedBox(width: 42),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _QuestionProgress(
                      currentQuestion: currentQuestion + 1,
                      totalQuestions: 2,
                    ),
                    const SizedBox(height: 22),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: isFirstQuestion
                            ? _RoleQuestionScreen(
                                key: const ValueKey('role-question'),
                                selectedValue: selectedRole,
                                options: roleOptions,
                                onSelected: onRoleSelected,
                                onContinue: onNext,
                              )
                            : _LocationQuestionScreen(
                                key: const ValueKey('location-question'),
                                selectedValue: selectedLocationType,
                                options: locationOptions,
                                onSelected: onLocationTypeSelected,
                                onDone: onDone,
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
    );
  }
}

class _RoleQuestionScreen extends StatelessWidget {
  const _RoleQuestionScreen({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
    required this.onContinue,
  });

  final String? selectedValue;
  final List<_SurveyOptionData> options;
  final ValueChanged<String> onSelected;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const _SurveyBanner(
                  assetPath: 'assets/images/app-banner5a.png',
                  height: 220,
                  horizontalInset: -16,
                  verticalCrop: 0.90,
                ),
                const SizedBox(height: 10),
                Text(
                  'What best describes\nyour role in the business?',
                  textAlign: TextAlign.center,
                  style: AppTypography.section(
                    fontSize: 22,
                    height: 1.18,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This helps us personalize your experience in VisibloAI.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    fontSize: 14.5,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 20),
                ...options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SelectionCard(
                      data: option,
                      isSelected: selectedValue == option.value,
                      onTap: () => onSelected(option.value),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _SurveyActionButton(
          label: 'Next',
          icon: Icons.arrow_forward_rounded,
          onPressed: onContinue,
        ),
      ],
    );
  }
}

class _LocationQuestionScreen extends StatelessWidget {
  const _LocationQuestionScreen({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
    required this.onDone,
  });

  final String? selectedValue;
  final List<_SurveyOptionData> options;
  final ValueChanged<String> onSelected;
  final Future<void> Function() onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const _SurveyBanner(
                  assetPath: 'assets/images/app-banner5b.png',
                  height: 238,
                  horizontalInset: -18,
                  verticalCrop: 0.92,
                ),
                const SizedBox(height: 6),
                Text(
                  'How many locations does\nyour business operate?',
                  textAlign: TextAlign.center,
                  style: AppTypography.section(
                    fontSize: 22,
                    height: 1.18,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This helps us tailor the right tools for your business setup.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    fontSize: 14.5,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 22),
                ...options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _SelectionCard(
                      data: option,
                      isSelected: selectedValue == option.value,
                      onTap: () => onSelected(option.value),
                      isLarge: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Obx(
          () => _SurveyActionButton(
            label: 'Done',
            icon: Icons.check_rounded,
            onPressed: onDone,
            isLoading: Get.find<OnboardingController>().isSurveyLoading.value,
          ),
        ),
      ],
    );
  }
}

class _QuestionProgress extends StatelessWidget {
  const _QuestionProgress({
    required this.currentQuestion,
    required this.totalQuestions,
  });

  final int currentQuestion;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    final progress = currentQuestion / totalQuestions;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Container(
                height: 4,
                width: double.infinity,
                color: const Color(0xFFE6ECF6),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF245BEB), Color(0xFF39D0D3)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Question $currentQuestion of $totalQuestions',
          style: AppTypography.label(
            fontSize: 12,
            color: AppColors.mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
    this.isLarge = false,
  });

  final _SurveyOptionData data;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: isLarge ? 14 : 16,
            vertical: isLarge ? 14 : 13,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF3B77FF)
                  : const Color(0xFFE4EAF4),
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0x143B77FF)
                    : const Color(0x0B144C86),
                blurRadius: isSelected ? 18 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: isLarge ? 52 : 38,
                height: isLarge ? 52 : 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: data.colors,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14305DEB),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  data.icon,
                  color: AppColors.white,
                  size: isLarge ? 28 : 19,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: AppTypography.button(
                        fontSize: isLarge ? 18 : 15.2,
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (data.subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        data.subtitle!,
                        style: AppTypography.body(
                          fontSize: 13.5,
                          color: AppColors.mutedText,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2B66F6), Color(0xFF39B4BD)],
                        )
                      : null,
                  color: isSelected ? null : AppColors.white,
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : const Color(0xFFD7DFEC),
                    width: 1.4,
                  ),
                ),
                alignment: Alignment.center,
                child: isSelected
                    ? const Icon(
                        Icons.circle,
                        size: 8,
                        color: AppColors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurveyBanner extends StatelessWidget {
  const _SurveyBanner({
    required this.assetPath,
    required this.height,
    this.horizontalInset = 0,
    this.verticalCrop = 1,
  });

  final String assetPath;
  final double height;
  final double horizontalInset;
  final double verticalCrop;

  @override
  Widget build(BuildContext context) {
    final bleed = horizontalInset < 0 ? horizontalInset.abs() * 2 : 0.0;
    final outerPadding = horizontalInset > 0 ? horizontalInset : 0.0;
    final visibleHeight = height * verticalCrop;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: outerPadding),
      child: SizedBox(
        height: visibleHeight,
        width: double.infinity,
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.topCenter,
                child: Image.asset(
                  assetPath,
                  height: height,
                  width: constraints.maxWidth + bleed,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SurveyActionButton extends StatelessWidget {
  const _SurveyActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final FutureOr<void> Function()? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF245BEB), Color(0xFF39D0D3)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22305DEB),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading || onPressed == null
              ? null
              : () async {
                  await onPressed!.call();
                },
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: AppTypography.button(
                        fontSize: 18,
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(icon, color: AppColors.white, size: 22),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BackButtonCircle extends StatelessWidget {
  const _BackButtonCircle({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x14144C86),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.brandBlue,
          ),
        ),
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _SurveyOptionData {
  const _SurveyOptionData({
    required this.value,
    required this.title,
    required this.icon,
    required this.colors,
    this.subtitle,
  });

  final String value;
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Color> colors;
}
