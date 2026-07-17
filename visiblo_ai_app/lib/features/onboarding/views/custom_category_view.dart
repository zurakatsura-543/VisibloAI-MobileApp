import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_primary_button.dart';
import '../../../app/widgets/app_text_field.dart';
import '../controllers/onboarding_controller.dart';

class CustomCategoryView extends GetView<OnboardingController> {
  const CustomCategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Form(
            key: controller.customCategoryFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: Get.back,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.text,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Add Your\nBusiness Category',
                  style: AppTypography.section(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tell us what type of business you run so we can save a custom category for your account.',
                  style: AppTypography.body(color: AppColors.mutedText),
                ),
                const SizedBox(height: 28),
                AppTextField(
                  label: 'Category Name',
                  hintText: 'Enter your category',
                  controller: controller.customCategoryNameController,
                  textInputAction: TextInputAction.next,
                  validator: (value) => controller.validateRequired(
                    value,
                    fieldName: 'Category name',
                  ),
                ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Short Description',
                  hintText: 'Describe your service type',
                  controller: controller.customCategorySubtitleController,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 28),
                AppPrimaryButton(
                  label: 'Add Category',
                  onPressed: controller.saveCustomCategory,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
