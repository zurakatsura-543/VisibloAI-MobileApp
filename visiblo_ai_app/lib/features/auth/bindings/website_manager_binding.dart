import 'package:get/get.dart';

import '../../onboarding/bindings/onboarding_binding.dart';
import '../controllers/website_manager_controller.dart';

class WebsiteManagerBinding extends Bindings {
  @override
  void dependencies() {
    OnboardingBinding().dependencies();

    if (!Get.isRegistered<WebsiteManagerController>()) {
      Get.lazyPut<WebsiteManagerController>(
        WebsiteManagerController.new,
        fenix: true,
      );
    }
  }
}
