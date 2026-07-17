import 'package:get/get.dart';

import '../../onboarding/bindings/onboarding_binding.dart';
import '../controllers/review_poster_controller.dart';

class ReviewPosterBinding extends Bindings {
  @override
  void dependencies() {
    OnboardingBinding().dependencies();

    if (!Get.isRegistered<ReviewPosterController>()) {
      Get.lazyPut<ReviewPosterController>(
        ReviewPosterController.new,
        fenix: true,
      );
    }
  }
}
