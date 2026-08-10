import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';

enum ProductMode { googleBusiness, socialMedia }

class ProductModeController extends GetxController {
  final selectedMode = ProductMode.googleBusiness.obs;

  ProductMode get mode => selectedMode.value;

  bool get isGoogleBusiness => mode == ProductMode.googleBusiness;
  bool get isSocialMedia => mode == ProductMode.socialMedia;

  void selectMode(ProductMode mode) {
    if (selectedMode.value == mode) {
      return;
    }
    selectedMode.value = mode;
  }

  void selectModeForRoute(String route) {
    if (_socialRoutes.contains(route)) {
      selectMode(ProductMode.socialMedia);
      return;
    }
    selectMode(ProductMode.googleBusiness);
  }

  static const _socialRoutes = {
    AppRoutes.socialDashboard,
    AppRoutes.socialAccounts,
    AppRoutes.socialCreate,
    AppRoutes.socialCreatives,
    AppRoutes.socialCalendar,
    AppRoutes.socialScheduler,
    AppRoutes.socialPosts,
    AppRoutes.socialAnalytics,
    AppRoutes.socialReports,
    AppRoutes.socialProfile,
  };
}
