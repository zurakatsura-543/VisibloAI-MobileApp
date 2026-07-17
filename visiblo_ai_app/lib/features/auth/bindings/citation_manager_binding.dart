import 'package:get/get.dart';

import '../../onboarding/bindings/onboarding_binding.dart';
import '../controllers/citation_manager_controller.dart';

class CitationManagerBinding extends Bindings {
  @override
  void dependencies() {
    OnboardingBinding().dependencies();

    if (!Get.isRegistered<CitationManagerController>()) {
      Get.lazyPut<CitationManagerController>(
        CitationManagerController.new,
        fenix: true,
      );
    }
  }
}
