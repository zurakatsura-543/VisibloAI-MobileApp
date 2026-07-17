import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_primary_button.dart';
import '../../../app/widgets/app_text_field.dart';
import '../controllers/onboarding_controller.dart';

class BusinessProfileView extends GetView<OnboardingController> {
  const BusinessProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight - 48),
            child: IntrinsicHeight(
              child: Form(
                key: controller.businessFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'What’s your business\nname?',
                      style: AppTypography.section(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This will be used across your account to\npersonalize your experience and reports.',
                      style: AppTypography.body(color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 22,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            label: 'Business Name',
                            hintText: 'Enter business name',
                            controller: controller.businessNameController,
                            validator: (value) => controller.validateRequired(
                              value,
                              fieldName: 'Business name',
                            ),
                            prefixIcon: const Icon(
                              Icons.storefront_outlined,
                              color: AppColors.mutedText,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'What industry are you in?',
                            style: AppTypography.label(),
                          ),
                          const SizedBox(height: 10),
                          Obx(
                            () => Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: controller.selectedIndustry.value,
                                onChanged: controller.selectIndustry,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.mutedText,
                                ),
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.apartment_outlined,
                                    color: AppColors.mutedText,
                                    size: 20,
                                  ),
                                  prefixIconConstraints: BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 24,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 18,
                                  ),
                                ),
                                style: AppTypography.body(),
                                hint: Text(
                                  'Select industry',
                                  style: AppTypography.body(
                                    fontSize: AppTypography.bodyTextCompact,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                                items: controller.industries
                                    .map(
                                      (industry) => DropdownMenuItem<String>(
                                        value: industry,
                                        child: Text(industry),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    AppPrimaryButton(
                      label: 'Continue',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => controller.submitBusinessProfile(),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Wrap(
                        children: [
                          Text(
                            'Already have an account?  ',
                            style: AppTypography.body(
                              fontSize: AppTypography.bodyTextCompact,
                              color: AppColors.mutedText,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Get.offAllNamed(AppRoutes.login),
                            child: Text(
                              'Login',
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
        ),
      ),
    );
  }
}
