import 'package:get/get.dart';

import '../../onboarding/bindings/onboarding_binding.dart';
import '../controllers/alert_center_controller.dart';

class AlertCenterBinding extends Bindings {
  @override
  void dependencies() {
    OnboardingBinding().dependencies();

    if (!Get.isRegistered<AlertCenterController>()) {
      Get.lazyPut<AlertCenterController>(
        AlertCenterController.new,
        fenix: true,
      );
    }
  }
}
