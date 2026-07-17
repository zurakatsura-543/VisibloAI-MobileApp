import 'package:get/get.dart';

import '../../auth/services/auth_api_service.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthApiService>()) {
      Get.put(AuthApiService(), permanent: true);
    }
    if (!Get.isRegistered<OnboardingController>()) {
      Get.put(OnboardingController(), permanent: true);
    }
  }
}
