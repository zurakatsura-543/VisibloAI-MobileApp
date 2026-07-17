import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_primary_button.dart';
import '../controllers/onboarding_controller.dart';

class GoogleConnectView extends GetView<OnboardingController> {
  const GoogleConnectView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
          onPressed: controller.logout,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connect your Google\nBusiness Profile',
                style: AppTypography.section(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We’ll open Google so you can authorize access to your Business Profile locations. Once done, come back and continue.',
                style: AppTypography.body(color: AppColors.mutedText),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE3E8EF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'What happens next',
                      style: AppTypography.button(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '1. Open Google sign-in\n2. Allow access to GBP\n3. Return here and continue to location selection',
                      style: AppTypography.body(
                        color: AppColors.mutedText,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Obx(
                () => AppPrimaryButton(
                  label: 'Connect Google',
                  isLoading: controller.isGoogleConnectLaunching.value,
                  onPressed: controller.openGoogleConnectionFlow,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
