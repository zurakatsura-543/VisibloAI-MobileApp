import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/onboarding_controller.dart';
import 'visiblo_splash_view.dart';

class AuthBootView extends StatefulWidget {
  const AuthBootView({super.key});

  @override
  State<AuthBootView> createState() => _AuthBootViewState();
}

class _AuthBootViewState extends State<AuthBootView> {
  final OnboardingController _controller = Get.find<OnboardingController>();

  @override
  Widget build(BuildContext context) {
    return VisibloSplashView(
      logoWidth: 310.0,
      onAnimationComplete: () {
        _controller.bootstrapAuthFlow();
      },
    );
  }
}
