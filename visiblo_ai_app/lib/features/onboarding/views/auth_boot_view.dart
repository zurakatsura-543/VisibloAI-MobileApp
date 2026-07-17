import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/widgets/app_logo.dart';
import '../controllers/onboarding_controller.dart';

class AuthBootView extends StatefulWidget {
  const AuthBootView({super.key});

  @override
  State<AuthBootView> createState() => _AuthBootViewState();
}

class _AuthBootViewState extends State<AuthBootView> {
  final OnboardingController _controller = Get.find<OnboardingController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.bootstrapAuthFlow();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(iconSize: 54, fontSize: 28, centered: true),
              SizedBox(height: 20),
              CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
