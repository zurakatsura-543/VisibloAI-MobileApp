import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

class VisibloBrandWordmark extends StatelessWidget {
  const VisibloBrandWordmark({
    super.key,
    this.iconSize = 24,
    this.fontSize = 18,
    this.showIcon = true,
  });

  final double iconSize;
  final double fontSize;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.brandBlue, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(iconSize * 0.34),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2239B4BD),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'V',
              style: AppTypography.label(
                fontSize: fontSize * 0.72,
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Visiblo',
                style: AppTypography.card(
                  fontSize: fontSize,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: 'AI',
                style: AppTypography.card(
                  fontSize: fontSize,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
