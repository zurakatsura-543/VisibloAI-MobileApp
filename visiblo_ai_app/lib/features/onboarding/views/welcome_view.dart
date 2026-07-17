import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/onboarding_intro_layout.dart';

class WelcomeView extends GetView<OnboardingController> {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              OnboardingIntroLayout(
                onPressed: controller.continueFromWelcome,
                onOpenTerms: controller.openTermsDocument,
                onOpenPrivacy: controller.openPrivacyPolicyDocument,
              ),
              if (controller.isAuthBootstrapping.value)
                Positioned(
                  top: 18,
                  right: 18,
                  child: Container(
                    width: 22,
                    height: 22,
                    padding: const EdgeInsets.all(2),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
