import 'package:get/get.dart';

import '../../onboarding/bindings/onboarding_binding.dart';
import '../controllers/account_settings_controller.dart';

class AccountSettingsBinding extends Bindings {
  @override
  void dependencies() {
    OnboardingBinding().dependencies();

    if (!Get.isRegistered<AccountSettingsController>()) {
      Get.lazyPut<AccountSettingsController>(
        AccountSettingsController.new,
        fenix: true,
      );
    }
  }
}
