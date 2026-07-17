import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_primary_button.dart';
import '../controllers/onboarding_controller.dart';

class BusinessLocationView extends GetView<OnboardingController> {
  const BusinessLocationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Form(
            key: controller.locationFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: Get.back,
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
                const SizedBox(height: 10),
                Text(
                  'Where is your business\nlocated?',
                  style: AppTypography.section(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This helps us tailor local insights.',
                  style: AppTypography.body(color: AppColors.mutedText),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x10000000),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LocationDropdownField(
                        label: 'City',
                        valueListenable: controller.selectedCity,
                        hintText: 'Select City',
                        icon: Icons.location_city_rounded,
                        items: controller.cities,
                        onChanged: controller.selectCity,
                      ),
                      const SizedBox(height: 14),
                      _LocationDropdownField(
                        label: 'Country',
                        valueListenable: controller.selectedCountry,
                        hintText: 'Select Country',
                        icon: Icons.public_rounded,
                        items: controller.countries,
                        onChanged: controller.selectCountry,
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: AppColors.line, height: 1),
                      const SizedBox(height: 18),
                      _LocationDropdownField(
                        label: 'What’s your time zone?',
                        valueListenable: controller.selectedTimeZone,
                        hintText: 'Select time zone',
                        icon: Icons.schedule_rounded,
                        items: controller.timeZones,
                        onChanged: controller.selectTimeZone,
                        prominentLabel: true,
                      ),
                      const SizedBox(height: 18),
                      const _MapPreviewCard(),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Obx(
                  () => AppPrimaryButton(
                    label: 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    isLoading: controller.isRegistrationLoading.value,
                    onPressed: () => controller.submitBusinessLocation(),
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

class _LocationDropdownField extends StatelessWidget {
  const _LocationDropdownField({
    required this.label,
    required this.valueListenable,
    required this.hintText,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.prominentLabel = false,
  });

  final String label;
  final RxnString valueListenable;
  final String hintText;
  final IconData icon;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool prominentLabel;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.label(
              fontSize: prominentLabel ? 15 : AppTypography.smallLabel,
              fontWeight: prominentLabel ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: valueListenable.value,
              onChanged: onChanged,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.mutedText,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: AppColors.mutedText, size: 20),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 24,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
              ),
              style: AppTypography.body(),
              hint: Text(
                hintText,
                style: AppTypography.body(
                  fontSize: AppTypography.bodyTextCompact,
                  color: AppColors.mutedText,
                ),
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E7ED)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(
            'assets/images/location_map_preview.svg',
            fit: BoxFit.cover,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00FFFFFF), Color(0x2FFFFFFF)],
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 12,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2F5F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    size: 13,
                    color: Color(0xFF15756E),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Localized Analytics',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15756E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
