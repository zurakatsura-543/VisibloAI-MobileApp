import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_logo.dart';

import '../../../app/theme/app_responsive.dart';

class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.bannerAssetPath = 'assets/images/app-banner2.png',
    this.bannerHeight = 216,
    this.showBanner = false,
    this.showBackButton = false,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String bannerAssetPath;
  final double bannerHeight;
  final bool showBanner;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final width = MediaQuery.sizeOf(context).width;
    final isTabletLandscape = width >= 768 && context.isLandscape;
    final isTabletPortrait = width >= 600 && !context.isLandscape;

    if (isTabletLandscape) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: Row(
          children: [
            // Left Hero Banner Column
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFEAF8FA),
                      Color(0xFFD6F2F5),
                      Color(0xFFC7ECF2),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const AppLogo(iconSize: 72, fontSize: 34, centered: true),
                        const SizedBox(height: 24),
                        Text(
                          'Grow Your Business with AI',
                          textAlign: TextAlign.center,
                          style: AppTypography.section(
                            fontSize: 32,
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Automate reviews, AI content, local SEO & customer interactions in one place.',
                          textAlign: TextAlign.center,
                          style: AppTypography.body(
                            fontSize: 16.5,
                            color: AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: Center(
                            child: Image.asset(
                              bannerAssetPath,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Right Auth Form Column
            Expanded(
              flex: 6,
              child: Scaffold(
                backgroundColor: AppColors.white,
                body: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(40, 24, 40, bottomInset + 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 540),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (showBackButton)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  onPressed: onBack,
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: AppColors.text,
                                    size: 26,
                                  ),
                                ),
                              ),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: AppTypography.section(
                                fontSize: 32,
                                color: AppColors.brandBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: AppTypography.body(
                                fontSize: 16,
                                color: AppColors.mutedText,
                              ),
                            ),
                            const SizedBox(height: 24),
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Tablet Portrait layout
    final formMaxWidth = isTabletPortrait ? 620.0 : 430.0;

    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const _AuthBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;
                final topPadding = isTabletPortrait ? 28.0 : 16.0;
                final bottomPadding = isTabletPortrait ? 28.0 : 18.0;
                final effectiveMinHeight =
                    availableHeight - topPadding - bottomPadding - bottomInset;

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    context.responsiveHorizontalPadding,
                    topPadding,
                    context.responsiveHorizontalPadding,
                    bottomInset + bottomPadding,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: formMaxWidth,
                        minHeight: effectiveMinHeight > 0 ? effectiveMinHeight : 0,
                      ),
                      child: Container(
                        padding: isTabletPortrait
                            ? const EdgeInsets.all(32)
                            : EdgeInsets.zero,
                        decoration: isTabletPortrait
                            ? BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x120F2746),
                                    blurRadius: 28,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                                border: Border.all(color: const Color(0xFFE8EEF5)),
                              )
                            : null,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showBackButton)
                                  SizedBox(
                                    height: 38,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: IconButton(
                                        onPressed: onBack,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints.tightFor(
                                          width: 38,
                                          height: 38,
                                        ),
                                        icon: const Icon(
                                          Icons.arrow_back_rounded,
                                          color: AppColors.text,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Center(
                                  child: AppLogo(
                                    iconSize: isTabletPortrait ? 56 : 48,
                                    fontSize: isTabletPortrait ? 28 : 24,
                                    centered: true,
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.section(
                                      fontSize: isTabletPortrait ? 30 : 26,
                                      height: 1.15,
                                      color: AppColors.brandBlue,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    subtitle,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.body(
                                      fontSize: isTabletPortrait ? 16.0 : 14.5,
                                      color: AppColors.mutedText,
                                      height: 1.38,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (showBanner && bannerAssetPath.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Center(
                                      child: Image.asset(
                                        bannerAssetPath,
                                        height: isTabletPortrait
                                            ? bannerHeight * 0.75
                                            : bannerHeight * 0.55,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: isTabletPortrait ? 24 : 18),
                                  child,
                                ],
                              ),
                            ),
                            const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AuthInputField extends StatelessWidget {
  const AuthInputField({
    super.key,
    required this.hintText,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.textInputAction,
  });

  final String hintText;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTabletOrLarger;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      textInputAction: textInputAction,
      style: AppTypography.body(
        fontSize: isTablet ? 17.5 : 16.0,
        color: AppColors.brandBlue,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.body(
          fontSize: isTablet ? 17.0 : 15.5,
          color: const Color(0xFF7E8BA2),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 18,
          vertical: isTablet ? 20 : 18,
        ),
        prefixIcon: Icon(icon, size: isTablet ? 24 : 22, color: AppColors.brandBlue),
        prefixIconConstraints: BoxConstraints(minWidth: isTablet ? 54 : 50),
        suffixIcon: suffixIcon,
        enabledBorder: _border(),
        focusedBorder: _border(color: const Color(0xFF8ADBE4)),
        errorBorder: _border(color: Colors.red.shade300),
        focusedErrorBorder: _border(color: Colors.red.shade300),
        border: _border(),
      ),
    );
  }

  OutlineInputBorder _border({Color color = const Color(0xFFD7E4F1)}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTabletOrLarger;

    return Container(
      height: isTablet ? 62 : 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0A4C93),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF114B92), Color(0xFF0B4C92)],
        ),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: AppTypography.button(
                  fontSize: isTablet ? 18.5 : 17.0,
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class AuthGoogleButton extends StatelessWidget {
  const AuthGoogleButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    this.compact = false,
  });

  final VoidCallback onPressed;
  final bool isLoading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTabletOrLarger;
    final labelText = compact ? 'Google' : 'Continue with Google';

    return SizedBox(
      height: isTablet ? 56 : 50,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white,
          side: const BorderSide(color: Color(0xFF8CC6FF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/google_logo.svg',
                    width: isTablet ? 22 : 20,
                    height: isTablet ? 22 : 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      labelText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.button(
                        fontSize: isTablet ? 16.5 : 14.5,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class AuthAppleButton extends StatelessWidget {
  const AuthAppleButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    this.compact = false,
  });

  final VoidCallback onPressed;
  final bool isLoading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTabletOrLarger;
    final labelText = compact ? 'Apple' : 'Sign in with Apple';

    return SizedBox(
      height: isTablet ? 56 : 50,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.black,
          side: const BorderSide(color: Colors.black),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.apple,
                    size: isTablet ? 22 : 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      labelText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.button(
                        fontSize: isTablet ? 16.5 : 14.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTabletOrLarger;

    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFD9E5F0))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or',
            style: AppTypography.body(
              fontSize: isTablet ? 16.5 : 15.0,
              color: AppColors.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFD9E5F0))),
      ],
    );
  }
}

class AuthAgreementRow extends StatelessWidget {
  const AuthAgreementRow({
    super.key,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTabletOrLarger;

    final bodyStyle = AppTypography.body(
      fontSize: isTablet ? 15.5 : 14.2,
      color: const Color(0xFF5D6A83),
      fontWeight: FontWeight.w500,
    );
    final linkStyle = AppTypography.body(
      fontSize: isTablet ? 15.5 : 14.2,
      color: AppColors.primary,
      fontWeight: FontWeight.w500,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1.5),
          child: Icon(
            Icons.check_box_rounded,
            size: isTablet ? 23 : 21,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: bodyStyle,
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms',
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()..onTap = onTermsTap,
                ),
                const TextSpan(text: ' & '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()..onTap = onPrivacyTap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AuthBottomLink extends StatelessWidget {
  const AuthBottomLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTabletOrLarger;

    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            prompt,
            style: AppTypography.body(
              fontSize: isTablet ? 17.0 : 15.5,
              color: const Color(0xFF6A758C),
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              style: AppTypography.body(
                fontSize: isTablet ? 17.0 : 15.5,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthBackgroundActionRow extends StatelessWidget {
  const AuthBackgroundActionRow({
    super.key,
    required this.leading,
    required this.trailing,
  });

  final Widget leading;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(children: [leading, const Spacer(), trailing]);
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 90,
          left: -100,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0x334ED8E7),
                  const Color(0x114ED8E7),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 150,
          right: -80,
          child: Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0x22144C86),
                  const Color(0x09144C86),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -4,
          child: Container(
            height: 62,
            decoration: const BoxDecoration(
              color: Color(0xFFC9F1F4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(120)),
            ),
          ),
        ),
      ],
    );
  }
}
