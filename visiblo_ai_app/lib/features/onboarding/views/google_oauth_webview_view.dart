import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../auth/services/auth_api_service.dart';
import '../controllers/onboarding_controller.dart';

class GoogleOAuthWebViewView extends StatefulWidget {
  const GoogleOAuthWebViewView({super.key});

  @override
  State<GoogleOAuthWebViewView> createState() => _GoogleOAuthWebViewViewState();
}

class _GoogleOAuthWebViewViewState extends State<GoogleOAuthWebViewView> {
  final OnboardingController _controller = Get.find<OnboardingController>();
  final AuthApiService _authApiService = Get.find<AuthApiService>();

  bool _isRunning = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runGoogleAuthFlow();
    });
  }

  Future<void> _runGoogleAuthFlow() async {
    if (!_isRunning) {
      return;
    }

    setState(() {
      _isRunning = true;
      _errorMessage = null;
    });

    try {
      final authUrl = await _authApiService.getGoogleConnectUrl();
      final hintedUrl = _applyLoginHint(authUrl, _preferredLoginHint());

      final callbackUrl = await FlutterWebAuth2.authenticate(
        url: hintedUrl,
        callbackUrlScheme: 'visibloai',
      );

      // Browser auto-closed via deep link callback — process it
      await _controller.finalizeGoogleConnectionCallback(callbackUrl);
    } catch (error) {
      if (!mounted) {
        return;
      }

      // User pressed back or browser couldn't redirect properly.
      // Check if Google got connected anyway (backend may have stored tokens).
      debugPrint('OAuth browser closed/cancelled. Checking connection status...');
      try {
        await _controller.continueAfterGoogleConnection();
        // If we reach here, continueAfterGoogleConnection navigated away.
        return;
      } catch (_) {
        // Google is still not connected — show the original error.
      }

      setState(() {
        _isRunning = false;
        _errorMessage = _humanizeError(error);
      });
    }
  }

  String _preferredLoginHint() {
    final candidates = <String>[
      _controller.signUpEmailController.text,
      _controller.loginEmailController.text,
      _controller.forgotPasswordEmailController.text,
      _controller.currentUser.value?.email ?? '',
    ];

    for (final candidate in candidates) {
      final normalized = candidate.trim().toLowerCase();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }

    return '';
  }

  String _applyLoginHint(String authUrl, String loginHint) {
    if (loginHint.isEmpty) {
      return authUrl;
    }

    final uri = Uri.tryParse(authUrl);
    if (uri == null) {
      return authUrl;
    }

    final updatedQueryParameters = Map<String, String>.from(uri.queryParameters)
      ..['login_hint'] = loginHint;

    return uri.replace(queryParameters: updatedQueryParameters).toString();
  }

  String _humanizeError(Object error) {
    final message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }
    if (message.startsWith('PlatformException(CANCELED')) {
      return 'Google sign-in was canceled before it completed.';
    }
    if (message.contains('access_denied')) {
      return 'Google sign-in was canceled before it completed.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          'Connect Google Business',
          style: AppTypography.button(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _errorMessage == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 18),
                      Text(
                        'Opening Google Business authorization...',
                        textAlign: TextAlign.center,
                        style: AppTypography.button(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Authorize Business Profile access and we will return you to the app as soon as that step completes.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body(
                          color: AppColors.mutedText,
                          height: 1.5,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Google Business connection could not finish.',
                        textAlign: TextAlign.center,
                        style: AppTypography.button(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: AppTypography.body(color: AppColors.mutedText),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _runGoogleAuthFlow,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
