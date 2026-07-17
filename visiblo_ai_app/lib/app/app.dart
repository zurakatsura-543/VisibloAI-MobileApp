import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      initialRoute: AppRoutes.welcome,
      initialBinding: OnboardingBinding(),
      getPages: AppPages.pages,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final fontFamily =
            Theme.of(context).textTheme.bodyMedium?.fontFamily ??
            AppTypography.fontFamily;
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.08)),
          child: DefaultTextStyle.merge(
            style: TextStyle(fontFamily: fontFamily),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
