import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_logo.dart';
import '../controllers/onboarding_controller.dart';

class GoogleConnectView extends StatefulWidget {
  const GoogleConnectView({super.key});

  @override
  State<GoogleConnectView> createState() => _GoogleConnectViewState();
}

class _GoogleConnectViewState extends State<GoogleConnectView> {
  final OnboardingController _controller = Get.find<OnboardingController>();
  Timer? _syncTimer;
  bool _awaitingSync = false;
  bool _syncInFlight = false;
  int _syncAttempts = 0;
  static const int _maxBackgroundSyncAttempts = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      _awaitingSync =
          args is Map<String, dynamic> && args['awaitingSync'] == true;
      if (_awaitingSync) {
        _startBackgroundSync();
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  void _startBackgroundSync() {
    _syncTimer?.cancel();
    _syncAttempts = 0;
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_syncInFlight) {
        return;
      }
      if (_syncAttempts >= _maxBackgroundSyncAttempts) {
        _syncTimer?.cancel();
        if (mounted) {
          setState(() {
            _awaitingSync = false;
          });
        }
        return;
      }

      _syncAttempts += 1;
      _syncInFlight = true;
      try {
        final connected = await _controller.refreshGoogleConnectionStatus(
          showErrorSnack: false,
          attempts: 1,
        );
        if (connected) {
          _syncTimer?.cancel();
        }
      } finally {
        _syncInFlight = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              left: -70,
              bottom: -30,
              child: _BackgroundGlow(
                size: 190,
                colors: [Color(0x1839B4BD), Color(0x10245BEB)],
              ),
            ),
            const Positioned(
              right: -72,
              top: 210,
              child: _BackgroundGlow(
                size: 170,
                colors: [Color(0x10245BEB), Color(0x1239B4BD)],
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: Get.back,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 42,
                          height: 42,
                        ),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.text,
                        ),
                      ),
                      const Spacer(),
                      const AppLogo(iconSize: 42, centered: true),
                      const Spacer(),
                      const SizedBox(width: 42),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Connect Your\nGoogle Account',
                    textAlign: TextAlign.center,
                    style: AppTypography.section(
                      fontSize: 31,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                      height: 1.14,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Sign in with the Google account where your business profiles are listed so we can fetch your Google Business Profiles and help you create social media posts faster.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body(
                      fontSize: 16,
                      color: AppColors.mutedText,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_awaitingSync)
                    Obx(
                      () => Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F8FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDCE8F8)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: _controller.isGoogleConnectRefreshing.value
                                  ? const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    )
                                  : const Icon(
                                      Icons.sync_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Google is connected. We are fetching your Business Profiles now.',
                                style: AppTypography.label(
                                  fontSize: 13.4,
                                  color: AppColors.brandBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE4ECF7)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x10144C86),
                          blurRadius: 22,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/app-banner6.png',
                          height: 200,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F8FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome_outlined,
                                color: Color(0xFF245BEB),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'We\'ll discover your business locations',
                                style: AppTypography.label(
                                  fontSize: 13.4,
                                  color: AppColors.brandBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE4ECF7)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF8FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Secure access only',
                                style: AppTypography.button(
                                  fontSize: 16,
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'for fetching your business locations.',
                                style: AppTypography.body(
                                  fontSize: 14.2,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE8FBF4),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF20B56B),
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Obx(
                    () => _GoogleConnectButton(
                      isLoading: _controller.isGoogleConnectLaunching.value,
                      isRefreshing: _controller.isGoogleConnectRefreshing.value,
                      onPressed: _controller.openGoogleConnectionFlow,
                      onRefreshPressed: () {
                        _controller.refreshGoogleConnectionStatus();
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Why do we need this?',
                    textAlign: TextAlign.center,
                    style: AppTypography.button(
                      fontSize: 16,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F7FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: AppColors.brandBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'We\'ll only use this to find and connect your Google Business Profiles.',
                          style: AppTypography.body(
                            fontSize: 14.5,
                            color: AppColors.mutedText,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleConnectButton extends StatelessWidget {
  const _GoogleConnectButton({
    required this.isLoading,
    required this.isRefreshing,
    required this.onPressed,
    required this.onRefreshPressed,
  });

  final bool isLoading;
  final bool isRefreshing;
  final VoidCallback onPressed;
  final VoidCallback onRefreshPressed;

  @override
  Widget build(BuildContext context) {
    final buttonLabel = isRefreshing
        ? 'Fetching Businesses...'
        : 'Continue with Google';

    final handler = isRefreshing ? onRefreshPressed : onPressed;

    return SizedBox(
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.brandBlue,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22144C86),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : handler,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: isLoading || isRefreshing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      buttonLabel,
                      style: AppTypography.button(
                        fontSize: 18,
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'G',
                        style: AppTypography.section(
                          fontSize: 22,
                          color: const Color(0xFF4285F4),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      buttonLabel,
                      style: AppTypography.button(
                        fontSize: 18,
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}
