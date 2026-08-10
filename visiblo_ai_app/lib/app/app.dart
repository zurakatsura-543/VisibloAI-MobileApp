import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../features/auth/controllers/product_mode_controller.dart';
import '../features/onboarding/bindings/onboarding_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_typography.dart';
import 'theme/app_theme.dart';

class VisibloAiApp extends StatelessWidget {
  const VisibloAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'VisibloAI',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.boot,
      initialBinding: OnboardingBinding(),
      getPages: AppPages.pages,
      theme: AppTheme.lightTheme,
      routingCallback: (routing) {
        final route = routing?.current;
        if (route == null || route.isEmpty) {
          return;
        }
        final productModeController = Get.isRegistered<ProductModeController>()
            ? Get.find<ProductModeController>()
            : Get.put(ProductModeController(), permanent: true);
        productModeController.selectModeForRoute(route);
      },
      builder: (context, child) {
        final fontFamily =
            Theme.of(context).textTheme.bodyMedium?.fontFamily ??
            AppTypography.fontFamily;
        return DefaultTextStyle.merge(
          style: TextStyle(fontFamily: fontFamily),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
