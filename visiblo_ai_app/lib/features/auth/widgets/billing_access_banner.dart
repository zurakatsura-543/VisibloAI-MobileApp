import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/services/platform_billing_policy.dart';

class BillingAccessBanner extends StatelessWidget {
  const BillingAccessBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimaryTap,
    this.icon = Icons.workspace_premium_rounded,
    this.badge,
    this.secondaryLabel,
    this.onSecondaryTap,
    this.accentColor = const Color(0xFF1AA6B7),
    this.surfaceColor = const Color(0xFFF5FCFD),
    this.borderColor = const Color(0xFFCFEFF3),
  });

  final String eyebrow;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimaryTap;
  final IconData icon;
  final String? badge;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryTap;
  final Color accentColor;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final displayedPrimaryLabel = PlatformBillingPolicy.usesSupportActivation
        ? 'Plan support'
        : primaryLabel;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2746),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: AppTypography.label(
                        fontSize: 11.2,
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: AppTypography.card(
                        fontSize: 17.6,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if ((badge ?? '').trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    badge!,
                    style: AppTypography.button(
                      fontSize: 11.5,
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTypography.body(
              fontSize: 13.2,
              color: const Color(0xFF567089),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onPrimaryTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    displayedPrimaryLabel,
                    style: AppTypography.button(
                      fontSize: 13.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if ((secondaryLabel ?? '').trim().isNotEmpty &&
                  onSecondaryTap != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSecondaryTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentColor,
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      secondaryLabel!,
                      style: AppTypography.button(
                        fontSize: 13.2,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> showBillingAccessSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String primaryLabel,
  required VoidCallback onPrimaryTap,
  String? secondaryLabel,
  VoidCallback? onSecondaryTap,
  String? badge,
  IconData icon = Icons.workspace_premium_rounded,
}) async {
  final displayedPrimaryLabel = PlatformBillingPolicy.usesSupportActivation
      ? 'Plan support'
      : primaryLabel;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x220F2746),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8F8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.card(
                        fontSize: 18.4,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    splashRadius: 18,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if ((badge ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: AppTypography.button(
                      fontSize: 11.6,
                      color: AppColors.brandBlue,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                message,
                style: AppTypography.body(
                  fontSize: 13.6,
                  color: const Color(0xFF587088),
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        onPrimaryTap();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        displayedPrimaryLabel,
                        style: AppTypography.button(
                          fontSize: 13.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if ((secondaryLabel ?? '').trim().isNotEmpty &&
                      onSecondaryTap != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          onSecondaryTap();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.brandBlue,
                          side: const BorderSide(color: Color(0xFFD9E5EF)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          secondaryLabel!,
                          style: AppTypography.button(
                            fontSize: 13.4,
                            color: AppColors.brandBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
