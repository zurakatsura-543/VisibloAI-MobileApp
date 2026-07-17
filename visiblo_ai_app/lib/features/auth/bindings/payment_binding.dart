import 'package:get/get.dart';

import '../../onboarding/bindings/onboarding_binding.dart';
import '../controllers/payment_controller.dart';

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    OnboardingBinding().dependencies();

    if (!Get.isRegistered<PaymentController>()) {
      Get.lazyPut<PaymentController>(PaymentController.new, fenix: true);
    }
  }
}
