import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final TextEditingController _servicesController = TextEditingController();
  final TextEditingController _customCategoryController =
      TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<String> _businessPhotoPaths = <String>[];

  String _locationSetup = 'single_location';
  String _industryCategory = '';
  String _brandVoice = 'Professional';
  String _primaryLanguage = 'English';
  String _secondaryLanguage = 'None';
  String _postingFrequency = '5 posts/week';
  String _approvalMode = 'Approve calendar';
  final Set<String> _goals = <String>{
    'Generate enquiries',
    'Promote services',
    'Improve profile activity',
  };
  final List<String> _servicesToPromote = <String>[];
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    _servicesController.addListener(() {
      if (_showValidationErrors) setState(() {});
    });
  }

  @override
  void dispose() {
    _servicesController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  List<String> _services() {
    final typed = _servicesController.text
        .split(RegExp(r'[,;\n]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);
    return <String>{..._servicesToPromote, ...typed}.toList(growable: false);
  }

  String _industryValue() {
    if (_industryCategory == 'Other') {
      return _customCategoryController.text.trim();
    }
    return _industryCategory.trim();
  }

  Future<void> _submit() async {
    setState(() => _showValidationErrors = true);
    await _controller.submitAiBusinessSetup(
      locationSetup: _locationSetup,
      industryCategory: _industryValue(),
      services: _services(),
      targetCustomers: const ['Local customers'],
      goals: _goals.toList(growable: false),
      brandVoice: _brandVoice,
      primaryLanguage: _primaryLanguage,
      secondaryLanguage: _secondaryLanguage,
      postingFrequency: _postingFrequency,
      approvalMode: _approvalMode,
      businessImagePaths: _businessPhotoPaths,
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
                        _IndustryPicker(
                          value: _industryCategory,
                          customController: _customCategoryController,
                          onChanged: (value) => setState(() {
                            _industryCategory = value;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Section(
                    title: 'Services To Promote',
                    subtitle:
                        'GBP will fetch your listed services after connection. Add anything extra or missing here manually.',
                    child: _ServiceBuilder(
                      controller: _servicesController,
                      services: _servicesToPromote,
                      suggestions: _serviceSuggestions(_industryValue()),
                      onAdd: _addService,
                      onRemove: (value) =>
                          setState(() => _servicesToPromote.remove(value)),
                      showRequiredHint:
                          _showValidationErrors && _services().isEmpty,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Section(
                    title: 'Show AI Your Business',
                    subtitle:
                        'Add up to 15 real photos. VisibloAI will use them in your future calendar posts instead of generic visuals.',
                    child: _BusinessPhotoPicker(
                      imagePaths: _businessPhotoPaths,
                      onAdd: _pickBusinessPhotos,
                      onRemove: (path) => setState(
                        () => _businessPhotoPaths.remove(path),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Section(
                    title: 'Content Goals',
                    subtitle:
                        'Choose the intent VisibloAI should optimize for.',
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
                    subtitle:
                        'Controls caption style, CTA tone and local language mix.',
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
                    subtitle: 'You can change this later from the AI calendar.',
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

  Future<void> _pickBusinessPhotos() async {
    final remaining = 15 - _businessPhotoPaths.length;
    if (remaining <= 0) {
      Get.snackbar(
        'Photo limit reached',
        'You can add up to 15 business photos.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final selected = await _imagePicker.pickMultiImage(
      imageQuality: 88,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (selected.isEmpty || !mounted) return;

    setState(() {
      final known = _businessPhotoPaths.toSet();
      for (final image in selected) {
        if (known.add(image.path) && _businessPhotoPaths.length < 15) {
          _businessPhotoPaths.add(image.path);
        }
      }
    });
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

  void _addService(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return;
    setState(() {
      if (!_servicesToPromote.contains(cleaned)) {
        _servicesToPromote.add(cleaned);
      }
      _servicesController.clear();
    });
  }
}

class _BusinessPhotoPicker extends StatelessWidget {
  const _BusinessPhotoPicker({
    required this.imagePaths,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> imagePaths;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final canAdd = imagePaths.length < 15;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canAdd ? onAdd : null,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(imagePaths.isEmpty ? 'Add business photos' : 'Add more photos'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandBlue,
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: Color(0xFFBFD5FF)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${imagePaths.length}/15',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
        if (imagePaths.isEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Examples: storefront, team, products, services, interior, completed work or logo.',
            style: GoogleFonts.manrope(
              fontSize: 11.7,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedText,
            ),
          ),
        ] else ...[
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: imagePaths.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
            ),
            itemBuilder: (context, index) {
              final path = imagePaths[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(path), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => onRemove(path),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
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
    this.onSubmitted,
    this.hasError = false,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final ValueChanged<String>? onSubmitted;
  final bool hasError;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.next,
      style: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: hasError ? const Color(0xFF0EA5A6) : AppColors.brandBlue,
        ),
        helperText: helperText,
        helperMaxLines: 2,
        helperStyle: GoogleFonts.manrope(
          fontSize: 11.5,
          height: 1.25,
          fontWeight: FontWeight.w700,
          color: hasError ? const Color(0xFF0F766E) : AppColors.mutedText,
        ),
        filled: true,
        fillColor: hasError ? const Color(0xFFEFFFFF) : const Color(0xFFF7FAFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFF0EA5A6) : AppColors.line,
            width: hasError ? 1.4 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF106CFF), width: 1.4),
        ),
      ),
    );
  }
}

class _IndustryPicker extends StatelessWidget {
  const _IndustryPicker({
    required this.value,
    required this.customController,
    required this.onChanged,
  });

  final String value;
  final TextEditingController customController;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DropdownRow(
          label: 'Industry / category',
          value: value.isEmpty ? null : value,
          options: _industryOptions,
          icon: Icons.category_outlined,
          hint: 'Choose your business type',
          onChanged: onChanged,
        ),
        if (value == 'Other') ...[
          const SizedBox(height: 12),
          _TextInput(
            controller: customController,
            label: 'Enter industry',
            hint: 'e.g. Interior designer, coaching center',
            icon: Icons.edit_note_rounded,
          ),
        ],
      ],
    );
  }
}

class _ServiceBuilder extends StatelessWidget {
  const _ServiceBuilder({
    required this.controller,
    required this.services,
    required this.suggestions,
    required this.onAdd,
    required this.onRemove,
    required this.showRequiredHint,
  });

  final TextEditingController controller;
  final List<String> services;
  final List<String> suggestions;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final bool showRequiredHint;

  @override
  Widget build(BuildContext context) {
    final visibleSuggestions = suggestions
        .where((value) => !services.contains(value))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _TextInput(
                controller: controller,
                label: 'Main service / product',
                hint: 'e.g. Hair spa, bridal makeup, dental implants',
                icon: Icons.sell_outlined,
                onSubmitted: onAdd,
                hasError: showRequiredHint,
                helperText: showRequiredHint
                    ? 'Add at least one service to guide AI posts.'
                    : 'Separate multiple services with commas, or tap quick picks.',
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => onAdd(controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF106CFF),
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Icon(Icons.add_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _GbpServiceNotice(showRequiredHint: showRequiredHint),
        if (visibleSuggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Quick picks',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: visibleSuggestions
                .map(
                  (value) => ActionChip(
                    label: Text(value),
                    avatar: const Icon(Icons.add_rounded, size: 16),
                    onPressed: () => onAdd(value),
                    backgroundColor: const Color(0xFFF7FAFF),
                    side: const BorderSide(color: AppColors.line),
                    labelStyle: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        if (services.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: services
                .map(
                  (value) => InputChip(
                    label: Text(value),
                    selected: true,
                    onDeleted: () => onRemove(value),
                    deleteIconColor: AppColors.white,
                    selectedColor: const Color(0xFF106CFF),
                    checkmarkColor: AppColors.white,
                    labelStyle: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _GbpServiceNotice extends StatelessWidget {
  const _GbpServiceNotice({required this.showRequiredHint});

  final bool showRequiredHint;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: showRequiredHint
            ? const Color(0xFFEFFFFF)
            : const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: showRequiredHint ? const Color(0xFF0EA5A6) : AppColors.line,
          width: showRequiredHint ? 1.4 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            showRequiredHint
                ? Icons.error_outline_rounded
                : Icons.storefront_outlined,
            size: 18,
            color: showRequiredHint
                ? const Color(0xFF0F766E)
                : AppColors.brandBlue,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              showRequiredHint
                  ? 'This part is empty. Add one service now, even if GBP will import more later.'
                  : 'After Google Business Profile connection, VisibloAI will also fetch your GBP services and products.',
              style: GoogleFonts.manrope(
                fontSize: 11.8,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: showRequiredHint
                    ? const Color(0xFF0F766E)
                    : AppColors.mutedText,
              ),
            ),
          ),
        ],
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
    this.hint,
  });

  final String label;
  final String? value;
  final List<String> options;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      hint: hint == null ? null : Text(hint!),
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

const _industryOptions = <String>[
  'Salon / spa',
  'Dental clinic',
  'Healthcare clinic',
  'Restaurant / cafe',
  'Gym / fitness',
  'Retail store',
  'Real estate',
  'Automotive',
  'Education / coaching',
  'Home services',
  'Legal / finance',
  'Other',
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

List<String> _serviceSuggestions(String industry) {
  final normalized = industry.toLowerCase();
  if (normalized.contains('salon') || normalized.contains('spa')) {
    return const ['Haircut', 'Hair colour', 'Facial', 'Bridal makeup'];
  }
  if (normalized.contains('dental')) {
    return const ['Root canal', 'Dental implants', 'Teeth whitening', 'Braces'];
  }
  if (normalized.contains('health') || normalized.contains('clinic')) {
    return const ['Consultation', 'Health checkup', 'Diagnostics', 'Follow-up'];
  }
  if (normalized.contains('restaurant') || normalized.contains('cafe')) {
    return const ['Dine-in', 'Takeaway', 'Catering', 'Special offers'];
  }
  if (normalized.contains('gym') || normalized.contains('fitness')) {
    return const [
      'Personal training',
      'Weight loss',
      'Strength training',
      'Group classes',
    ];
  }
  if (normalized.contains('real estate')) {
    return const ['Property sales', 'Rentals', 'Site visits', 'Consultation'];
  }
  if (normalized.contains('automotive')) {
    return const ['Car service', 'Repairs', 'Detailing', 'Inspection'];
  }
  return const [
    'Core service',
    'Premium service',
    'Seasonal offer',
    'Consultation',
  ];
}
