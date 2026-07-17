import 'package:get/get.dart';

import '../../onboarding/bindings/onboarding_binding.dart';
import '../controllers/gbp_manager_controller.dart';

class GbpManagerBinding extends Bindings {
  @override
  void dependencies() {
    OnboardingBinding().dependencies();

    if (!Get.isRegistered<GbpManagerController>()) {
      Get.lazyPut<GbpManagerController>(GbpManagerController.new, fenix: true);
    }
  }
}
