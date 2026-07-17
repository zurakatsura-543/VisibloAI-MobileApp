import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppSocialButton extends StatelessWidget {
  const AppSocialButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.assetPath,
    this.labelStyle,
    this.height = 56,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final String assetPath;
  final TextStyle? labelStyle;
  final double height;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final resolvedLabelStyle =
        labelStyle ??
        Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: AppColors.text) ??
        AppTypography.button();

    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(assetPath, width: 20, height: 20),
                  const SizedBox(width: 12),
                  Text(label, style: resolvedLabelStyle),
                ],
              ),
      ),
    );
  }
}
