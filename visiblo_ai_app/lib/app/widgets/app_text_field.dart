import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.textInputAction,
    this.labelStyle,
    this.textStyle,
    this.hintStyle,
    this.contentPadding,
  });

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;
  final TextStyle? labelStyle;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final resolvedLabelStyle =
        labelStyle ??
        textTheme.labelMedium?.copyWith(color: AppColors.text) ??
        AppTypography.label();
    final resolvedTextStyle =
        textStyle ??
        textTheme.bodyLarge?.copyWith(color: AppColors.text) ??
        AppTypography.body();
    final resolvedHintStyle =
        hintStyle ??
        textTheme.bodyMedium?.copyWith(color: AppColors.mutedText) ??
        AppTypography.body(
          fontSize: AppTypography.bodyTextCompact,
          color: AppColors.mutedText,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: resolvedLabelStyle),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          textInputAction: textInputAction,
          style: resolvedTextStyle,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: resolvedHintStyle,
            filled: true,
            fillColor: AppColors.white,
            contentPadding:
                contentPadding ??
                const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            prefixIcon: prefixIcon,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 24,
            ),
            suffixIcon: suffixIcon,
            enabledBorder: _border(),
            focusedBorder: _border(color: AppColors.primary),
            errorBorder: _border(color: Colors.red.shade300),
            focusedErrorBorder: _border(color: Colors.red.shade300),
            border: _border(),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border({Color color = AppColors.border}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );
  }
}
