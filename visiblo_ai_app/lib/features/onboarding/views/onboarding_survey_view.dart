import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/widgets/app_logo.dart';
import '../../../app/widgets/app_primary_button.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingSurveyView extends StatefulWidget {
  const OnboardingSurveyView({super.key});

  @override
  State<OnboardingSurveyView> createState() => _OnboardingSurveyViewState();
}

class _OnboardingSurveyViewState extends State<OnboardingSurveyView> {
  final OnboardingController _controller = Get.find<OnboardingController>();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _servicesController = TextEditingController();

  String _locationSetup = 'single_location';
  String _brandVoice = 'Professional';
  String _primaryLanguage = 'English';
  String _secondaryLanguage = 'None';
  String _postingFrequency = '5 posts/week';
  String _approvalMode = 'Approve calendar';
  final Set<String> _targetCustomers = <String>{'Local customers'};
  final Set<String> _goals = <String>{
    'Generate enquiries',
    'Promote services',
    'Improve profile activity',
  };

  @override
  void dispose() {
    _categoryController.dispose();
    _servicesController.dispose();
    super.dispose();
  }

  List<String> _services() {
    return _servicesController.text
        .split(RegExp(r'[,;\n]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  Future<void> _submit() async {
    await _controller.submitAiBusinessSetup(
      locationSetup: _locationSetup,
      industryCategory: _categoryController.text,
      services: _services(),
      targetCustomers: _targetCustomers.toList(growable: false),
      goals: _goals.toList(growable: false),
      brandVoice: _brandVoice,
      primaryLanguage: _primaryLanguage,
      secondaryLanguage: _secondaryLanguage,
      postingFrequency: _postingFrequency,
      approvalMode: _approvalMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: -110,
              right: -90,
              child: _Glow(color: Color(0x2625C2C9), size: 240),
            ),
            const Positioned(
              bottom: -130,
              left: -110,
              child: _Glow(color: Color(0x26245BEB), size: 260),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Get.back();
                            } else {
                              Get.offAllNamed(AppRoutes.login);
                            }
                          },
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          constraints: const BoxConstraints(
                            minWidth: 34,
                            minHeight: 34,
                          ),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      const AppLogo(iconSize: 46, centered: true),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Teach VisibloAI Your Business',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandBlue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'These details become the starting knowledge for your AI marketing manager. You can improve them later.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 14.5,
                      height: 1.42,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _Section(
                    title: 'Business Basics',
                    child: Column(
                      children: [
                        _SegmentedChoice(
                          value: _locationSetup,
                          options: const {
                            'single_location': 'Single location',
                            'multi_location': 'Multiple locations',
                          },
                          onChanged: (value) =>
                              setState(() => _locationSetup = value),
                        ),
                        const SizedBox(height: 14),
                        _TextInput(
                          controller: _categoryController,
                          label: 'Industry / category',
                          hint: 'Dentist, salon, cafe, gym, real estate...',
                          icon: Icons.category_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Section(
                    title: 'Services To Promote',
                    subtitle: 'Add comma-separated services or products.',
                    child: _TextInput(
                      controller: _servicesController,
                      label: 'Main services / products',
                      hint: 'Root canal, dental implants, teeth whitening',
                      icon: Icons.sell_outlined,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Section(
                    title: 'Target Customers',
                    child: _ChipWrap(
                      selected: _targetCustomers,
                      options: _customerOptions,
                      onChanged: (value) =>
                          setState(() => _toggle(_targetCustomers, value)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Section(
                    title: 'Content Goals',
                    child: _ChipWrap(
                      selected: _goals,
                      options: _goalOptions,
                      onChanged: (value) =>
                          setState(() => _toggle(_goals, value)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Section(
                    title: 'Voice & Language',
                    child: Column(
                      children: [
                        _DropdownRow(
                          label: 'Brand voice',
                          value: _brandVoice,
                          options: _voiceOptions,
                          icon: Icons.record_voice_over_outlined,
                          onChanged: (value) =>
                              setState(() => _brandVoice = value),
                        ),
                        const SizedBox(height: 12),
                        _DropdownRow(
                          label: 'Primary language',
                          value: _primaryLanguage,
                          options: _languageOptions,
                          icon: Icons.translate_rounded,
                          onChanged: (value) =>
                              setState(() => _primaryLanguage = value),
                        ),
                        const SizedBox(height: 12),
                        _DropdownRow(
                          label: 'Secondary language',
                          value: _secondaryLanguage,
                          options: const ['None', ..._languageOptions],
                          icon: Icons.language_rounded,
                          onChanged: (value) =>
                              setState(() => _secondaryLanguage = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Section(
                    title: 'Automation Preference',
                    child: Column(
                      children: [
                        _DropdownRow(
                          label: 'Posting frequency',
                          value: _postingFrequency,
                          options: _frequencyOptions,
                          icon: Icons.calendar_month_outlined,
                          onChanged: (value) =>
                              setState(() => _postingFrequency = value),
                        ),
                        const SizedBox(height: 12),
                        _DropdownRow(
                          label: 'Approval mode',
                          value: _approvalMode,
                          options: _approvalOptions,
                          icon: Icons.fact_check_outlined,
                          onChanged: (value) =>
                              setState(() => _approvalMode = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Obx(
                    () => AppPrimaryButton(
                      label: 'Save AI Setup',
                      icon: Icons.auto_awesome_rounded,
                      isLoading: _controller.isSurveyLoading.value,
                      onPressed: _submit,
                      height: 58,
                      backgroundColor: const Color(0xFF106CFF),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'VisibloAI will use this only to prepare safer posts, review replies, keywords and business suggestions.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 11.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedText,
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

  void _toggle(Set<String> target, String value) {
    if (target.contains(value)) {
      if (target.length > 1) {
        target.remove(value);
      }
    } else {
      target.add(value);
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D144C86),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                height: 1.32,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedText,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      style: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.brandBlue),
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: const Color(0xFFF7FAFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF106CFF), width: 1.4),
        ),
      ),
    );
  }
}

class _SegmentedChoice extends StatelessWidget {
  const _SegmentedChoice({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.entries
          .map((entry) {
            final selected = value == entry.key;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: entry.key == options.keys.first ? 8 : 0,
                  left: entry.key == options.keys.last ? 8 : 0,
                ),
                child: InkWell(
                  onTap: () => onChanged(entry.key),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFEAF4FF)
                          : const Color(0xFFF7FAFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF106CFF)
                            : AppColors.line,
                      ),
                    ),
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: selected
                            ? AppColors.brandBlue
                            : AppColors.mutedText,
                      ),
                    ),
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  final Set<String> selected;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => onChanged(option),
              checkmarkColor: AppColors.white,
              selectedColor: const Color(0xFF106CFF),
              backgroundColor: const Color(0xFFF7FAFF),
              side: BorderSide(
                color: isSelected ? const Color(0xFF106CFF) : AppColors.line,
              ),
              labelStyle: GoogleFonts.manrope(
                fontSize: 12.3,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.white : AppColors.text,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.options,
    required this.icon,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: options
          .map(
            (option) =>
                DropdownMenuItem<String>(value: option, child: Text(option)),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      style: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.brandBlue),
        filled: true,
        fillColor: const Color(0xFFF7FAFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF106CFF), width: 1.4),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 90, spreadRadius: 36),
          ],
        ),
      ),
    );
  }
}

const _customerOptions = <String>[
  'Local customers',
  'Families',
  'Working professionals',
  'Students',
  'Business owners',
  'Women',
  'Homeowners',
  'Parents',
];

const _goalOptions = <String>[
  'Generate enquiries',
  'Promote services',
  'Promote offers',
  'Build trust',
  'Educate customers',
  'Improve profile activity',
  'Increase calls',
  'Increase bookings',
  'Increase website traffic',
  'Seasonal promotions',
];

const _voiceOptions = <String>[
  'Professional',
  'Friendly',
  'Premium',
  'Simple',
  'Local',
  'Educational',
  'Sales Focused',
];

const _languageOptions = <String>[
  'English',
  'Hindi',
  'Hinglish',
  'Marathi',
  'Gujarati',
  'Bengali',
  'Tamil',
  'Telugu',
  'Kannada',
  'Malayalam',
  'Punjabi',
];

const _frequencyOptions = <String>[
  '3 posts/week',
  '5 posts/week',
  '7 posts/week',
];

const _approvalOptions = <String>[
  'Review every post',
  'Approve calendar',
  'Full auto later',
];
