import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_logo.dart';
import '../../../app/widgets/app_primary_button.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../../onboarding/models/google_business_location.dart';
import '../controllers/payment_controller.dart';
import '../models/payment_models.dart';
import '../models/subscription_payment_record.dart';
import '../widgets/auth_navigation_shell.dart';

class PaymentView extends GetView<PaymentController> {
  const PaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final liveProfile = controller.remoteProfile.value;
      if (liveProfile != null && controller.requiresIntroActivationPayment) {
        return _TrialUnlockView(controller: controller);
      }

      if (liveProfile != null &&
          (controller.requiresRenewalPayment ||
              controller.hasExternalBillingTarget)) {
        return _ExpiredRenewalView(controller: controller);
      }

      return AuthNavigationShell(
        currentTab: AuthTab.payment,
        backgroundColor: const Color(0xFFF5F7FB),
        child: _PaymentContent(controller: controller),
      );
    });
  }
}

class _TrialUnlockView extends StatelessWidget {
  const _TrialUnlockView({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFF),
      body: SafeArea(
        child: Obx(() {
          final isLoading =
              controller.isLoading.value &&
              controller.remoteProfile.value == null;
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (Get.previousRoute.isNotEmpty) {
                          Get.back();
                          return;
                        }
                        Get.offAllNamed(AppRoutes.locationSelection);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: 40,
                      ),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.text,
                      ),
                    ),
                    const Spacer(),
                    const AppLogo(iconSize: 42, centered: true),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Unlock Your 7-Day Trial',
                  style: GoogleFonts.manrope(
                    fontSize: 29,
                    height: 1.08,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Pay a one-time fee of Rs 99 to access VisibloAI and start your 7-day trial.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    height: 1.45,
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFF93C9FF)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x11003F70),
                        blurRadius: 26,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 11,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹99',
                              style: GoogleFonts.manrope(
                                fontSize: 42,
                                height: 0.95,
                                color: AppColors.brandBlue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '7-Day Trial Access',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: GoogleFonts.manrope(
                                fontSize: 15.8,
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF9FB),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.sell_outlined,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'One-time payment',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                      style: GoogleFonts.manrope(
                                        fontSize: 11.8,
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 98,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: const Color(0xFFE1E8F2),
                      ),
                      Expanded(
                        flex: 13,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Image.asset(
                            'assets/images/app-banner7.png',
                            height: 152,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SelectedBusinessCard(controller: controller),
                const SizedBox(height: 18),
                _TrialBenefitsCard(controller: controller),
                const SizedBox(height: 18),
                _SecureCheckoutNote(),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x24359FC4),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: AppPrimaryButton(
                    label: 'Pay Rs 99 & Start Trial',
                    icon: Icons.arrow_forward_rounded,
                    isLoading: controller.isSelectedPlanBusy,
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    onPressed: controller.checkoutSelectedPlan,
                    labelStyle: GoogleFonts.manrope(
                      fontSize: 18.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Get.bottomSheet<void>(
                        _TrialPlanDetailsSheet(controller: controller),
                        isScrollControlled: true,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.brandBlue,
                    ),
                    label: Text(
                      'View plan details',
                      style: GoogleFonts.manrope(
                        fontSize: 14.5,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'You can cancel anytime. No hidden charges.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 12.8,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (controller.errorMessage.value != null) ...[
                  const SizedBox(height: 14),
                  _FeedbackBanner(
                    message: controller.errorMessage.value!,
                    isError: true,
                    onDismiss: controller.clearError,
                  ),
                ],
                if (controller.infoMessage.value != null) ...[
                  const SizedBox(height: 14),
                  _FeedbackBanner(
                    message: controller.infoMessage.value!,
                    onDismiss: controller.clearInfo,
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ExpiredRenewalView extends StatelessWidget {
  const _ExpiredRenewalView({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFF),
      body: SafeArea(
        child: Obx(() {
          final isLoading =
              controller.isLoading.value &&
              controller.remoteProfile.value == null;
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (Get.previousRoute.isNotEmpty) {
                          Get.back();
                          return;
                        }
                        Get.offAllNamed(AppRoutes.locationSelection);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: 40,
                      ),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.text,
                      ),
                    ),
                    const Spacer(),
                    const AppLogo(iconSize: 42, centered: true),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFFFC8C8)),
                      ),
                      child: Text(
                        'PLAN EXPIRED',
                        style: GoogleFonts.manrope(
                          fontSize: 10.5,
                          color: const Color(0xFFFF3B30),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Continue your visibility engine',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    height: 1.08,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  '${_expiredAgoLabel(controller.hasExternalBillingTarget ? null : controller.renewalDate)}. Pick up where you left off.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14.5,
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${controller.selectedBusinessName} is the expired business.',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 12.8,
                    color: const Color(0xFF0D7F95),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                _ExpiredRenewalHero(controller: controller),
                const SizedBox(height: 14),
                _ExpiredBillingCycleToggle(controller: controller),
                const SizedBox(height: 14),
                _ExpiredPaymentModeSelector(controller: controller),
                const SizedBox(height: 12),
                _ExpiredLockedBanner(controller: controller),
                const SizedBox(height: 12),
                _ExpiredPlanSummaryCard(controller: controller),
                const SizedBox(height: 12),
                _ExpiredPriceBreakdown(controller: controller),
                const SizedBox(height: 10),
                _ExpiredCouponRow(controller: controller),
                const SizedBox(height: 10),
                _ExpiredRestoreButton(controller: controller),
                const SizedBox(height: 14),
                _ExpiredTrustRow(),
                const SizedBox(height: 18),
                _ExpiredPlanActions(controller: controller),
                const SizedBox(height: 10),
                Text(
                  'You can cancel anytime. No hidden charges.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 12.2,
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (controller.errorMessage.value != null) ...[
                  const SizedBox(height: 14),
                  _FeedbackBanner(
                    message: controller.errorMessage.value!,
                    isError: true,
                    onDismiss: controller.clearError,
                  ),
                ],
                if (controller.infoMessage.value != null) ...[
                  const SizedBox(height: 14),
                  _FeedbackBanner(
                    message: controller.infoMessage.value!,
                    onDismiss: controller.clearInfo,
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ExpiredRenewalHero extends StatelessWidget {
  const _ExpiredRenewalHero({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final plan = controller.selectedPlan;
      final cycle = controller.selectedBillingCycle.value;
      final isYearly = cycle == 'yearly';
      final savings = plan.annualSavingsInr();

      return Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 18, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF8FC6FF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14003F70),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 11,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatInr(controller.estimatedTotalInr),
                      maxLines: 1,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 38,
                        height: 0.95,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_renewalPlanTitle(plan)} Renewal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14.5,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isYearly
                        ? '12-month access • yearly billing'
                        : '1-month access • monthly billing',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 12.4,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isYearly && savings > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9FCF7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sell_outlined,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Save ${_formatInr(savings)} yearly',
                            style: GoogleFonts.manrope(
                              fontSize: 11.4,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 1,
              height: 104,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: const Color(0xFFE1E8F2),
            ),
            Expanded(
              flex: 8,
              child: Image.asset(
                'assets/images/app-banner7.png',
                height: 126,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ExpiredBillingCycleToggle extends StatelessWidget {
  const _ExpiredBillingCycleToggle({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedCycle = controller.selectedBillingCycle.value;
      return Center(
        child: Container(
          width: 230,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F3F8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ExpiredCyclePill(
                  label: 'Monthly',
                  selected: selectedCycle == 'monthly',
                  onTap: () => controller.setBillingCycle('monthly'),
                ),
              ),
              Expanded(
                child: _ExpiredCyclePill(
                  label: 'Yearly',
                  badge: '-20%',
                  selected: selectedCycle == 'yearly',
                  onTap: () => controller.setBillingCycle('yearly'),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _ExpiredCyclePill extends StatelessWidget {
  const _ExpiredCyclePill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x18003F70),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12.8,
                color: selected ? AppColors.brandBlue : AppColors.mutedText,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2FAF5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.manrope(
                    fontSize: 9.5,
                    color: const Color(0xFF0F8C7E),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExpiredPaymentModeSelector extends StatelessWidget {
  const _ExpiredPaymentModeSelector({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedMode = controller.selectedBillingMode.value;
      return Row(
        children: [
          Expanded(
            child: _ExpiredModeCard(
              icon: Icons.credit_card_rounded,
              title: 'Pay manually',
              subtitle: 'One-time checkout for the selected billing cycle.',
              selected: selectedMode == 'MANUAL',
              enabled: true,
              onTap: () => controller.setBillingMode('MANUAL'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ExpiredModeCard(
              icon: Icons.verified_user_outlined,
              title: 'Enable AutoPay',
              subtitle:
                  'Creates a Razorpay subscription mandate for recurring charges.',
              selected: selectedMode == 'AUTOPAY',
              enabled: true,
              onTap: () => controller.setBillingMode('AUTOPAY'),
            ),
          ),
        ],
      );
    });
  }
}

class _ExpiredModeCard extends StatelessWidget {
  const _ExpiredModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 104),
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF4FEFF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF169CFF) : const Color(0xFFE0E7F0),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: enabled ? AppColors.primary : AppColors.mutedText,
                ),
                const Spacer(),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: selected
                      ? const Color(0xFF0E73FF)
                      : const Color(0xFFB8C3D2),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12.8,
                color: enabled ? AppColors.brandBlue : AppColors.mutedText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 11.5,
                height: 1.28,
                color: AppColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpiredLockedBanner extends StatelessWidget {
  const _ExpiredLockedBanner({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAEA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD47A)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE2A8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: Color(0xFFF39C12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Business access is locked',
                  style: GoogleFonts.manrope(
                    fontSize: 12.6,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${controller.selectedBusinessName} is locked until billing is restored.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 10.8,
                    height: 1.18,
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'RESTORE_ACCESS',
            style: GoogleFonts.manrope(
              fontSize: 9.2,
              color: const Color(0xFFD88400),
              fontWeight: FontWeight.w900,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFD88400),
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _ExpiredPlanSummaryCard extends StatelessWidget {
  const _ExpiredPlanSummaryCard({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final plan = controller.selectedPlan;
      final features = plan.features.take(4).toList(growable: false);

      return Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: _cardDecoration(
          border: Border.all(color: const Color(0xFFE1E9F2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: AppColors.brandBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _renewalPlanTitle(plan),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 17,
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007FA5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'YOUR PLAN',
                          style: GoogleFonts.manrope(
                            fontSize: 7.8,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _renewalPlanSubtitle(plan),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 11.4,
                      height: 1.22,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      for (var index = 0; index < features.length; index += 2)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: index + 2 < features.length ? 8 : 0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _ExpiredFeatureCheck(
                                  label: _shortFeature(features[index]),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: index + 1 < features.length
                                    ? _ExpiredFeatureCheck(
                                        label: _shortFeature(
                                          features[index + 1],
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ExpiredPriceBreakdown extends StatelessWidget {
  const _ExpiredPriceBreakdown({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final plan = controller.selectedPlan;
      final isYearly = controller.selectedBillingCycle.value == 'yearly';
      final subtotal = controller.estimatedDiscountedSubtotalInr;
      final originalYearly = plan.monthlyPriceInr * 12;
      final savings = isYearly ? plan.annualSavingsInr() : 0;

      return Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: _cardDecoration(
          border: Border.all(color: const Color(0xFFE1E9F2)),
        ),
        child: Column(
          children: [
            _ExpiredAmountRow(
              label:
                  '${_renewalPlanTitle(plan)} (${isYearly ? '12 months' : '1 month'})',
              value: _formatInr(subtotal),
              strikedValue: isYearly && originalYearly > subtotal
                  ? _formatInr(originalYearly)
                  : null,
            ),
            const SizedBox(height: 9),
            _ExpiredAmountRow(
              label: 'GST (18%)',
              value: _formatInr(controller.estimatedGstInr),
              info: true,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 9),
              child: Divider(height: 1, color: Color(0xFFE5ECF4)),
            ),
            _ExpiredAmountRow(
              label: 'Total',
              value: _formatInr(controller.estimatedTotalInr),
              large: true,
            ),
            if (savings > 0) ...[
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'You save ${_formatInr(savings)}',
                  style: GoogleFonts.manrope(
                    fontSize: 10.6,
                    color: const Color(0xFF019878),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _ExpiredFeatureCheck extends StatelessWidget {
  const _ExpiredFeatureCheck({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 15,
          height: 15,
          margin: const EdgeInsets.only(top: 1),
          decoration: const BoxDecoration(
            color: Color(0xFFE8F8F0),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 11,
            color: Color(0xFF21A564),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 10.8,
              height: 1.2,
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpiredAmountRow extends StatelessWidget {
  const _ExpiredAmountRow({
    required this.label,
    required this.value,
    this.strikedValue,
    this.info = false,
    this.large = false,
  });

  final String label;
  final String value;
  final String? strikedValue;
  final bool info;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: large ? 15.2 : 12.6,
                    color: AppColors.brandBlue,
                    fontWeight: large ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
              if (info) ...[
                const SizedBox(width: 5),
                const Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: Color(0xFF90A0B7),
                ),
              ],
            ],
          ),
        ),
        if (strikedValue != null) ...[
          Text(
            strikedValue!,
            style: GoogleFonts.manrope(
              fontSize: 10.8,
              color: const Color(0xFF9AA7BA),
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: large ? 25 : 12.8,
            height: 1,
            color: AppColors.brandBlue,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ExpiredCouponRow extends StatelessWidget {
  const _ExpiredCouponRow({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final couponResult = controller.couponResult.value;
      if (controller.selectedBillingMode.value == 'AUTOPAY') {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FCFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFEAF2)),
          ),
          child: Text(
            'Coupon discounts are available on manual checkout only. Use AutoPay when you want recurring renewals without re-entering payment details.',
            style: GoogleFonts.manrope(
              fontSize: 11.5,
              height: 1.35,
              color: const Color(0xFF08758B),
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      }

      if (couponResult != null) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FBF6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC4EAD4)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.local_offer_rounded,
                color: Color(0xFF1D8F58),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${couponResult.coupon?.code ?? controller.couponCode.value} applied',
                  style: GoogleFonts.manrope(
                    fontSize: 12.2,
                    color: const Color(0xFF126B42),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: controller.removeCoupon,
                child: const Text('Remove'),
              ),
            ],
          ),
        );
      }

      final canApplyCoupon =
          !controller.isApplyingCoupon.value &&
          controller.couponCode.value.trim().isNotEmpty;

      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.couponCodeController,
              textCapitalization: TextCapitalization.characters,
              decoration: _couponInputDecoration().copyWith(
                hintText: 'Have a coupon code?',
                prefixIcon: const Icon(
                  Icons.sell_outlined,
                  size: 18,
                  color: Color(0xFF8EA0B7),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: canApplyCoupon ? controller.applyCoupon : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: const Color(0xFFE9EFF6),
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF9AA8BA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.isApplyingCoupon.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Apply',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ],
      );
    });
  }
}

class _ExpiredRestoreButton extends StatelessWidget {
  const _ExpiredRestoreButton({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isAutopay = controller.selectedBillingMode.value == 'AUTOPAY';
      final cycleLabel = controller.selectedBillingCycle.value == 'yearly'
          ? 'Yearly'
          : 'Monthly';
      final label = controller.couponResult.value?.skipPayment == true
          ? 'Restore Access'
          : isAutopay
          ? 'Start AutoPay - $cycleLabel'
          : 'Pay ${_formatInr(controller.estimatedTotalInr)} & Restore Access';

      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D62FF), Color(0xFF08BFA8)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2A0D8BE8),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: controller.isSelectedPlanBusy
              ? null
              : controller.checkoutSelectedPlan,
          icon: controller.isSelectedPlanBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.1,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.lock_outline_rounded, size: 22),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.manrope(
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    });
  }
}

class _ExpiredTrustRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = <({IconData icon, String label, Color color})>[
      (
        icon: Icons.verified_user_outlined,
        label: 'Secure checkout',
        color: Color(0xFF00A978),
      ),
      (
        icon: Icons.shield_outlined,
        label: 'Razorpay verified',
        color: Color(0xFF2C7BFF),
      ),
      (
        icon: Icons.receipt_long_outlined,
        label: 'GST invoice',
        color: Color(0xFF2C7BFF),
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(items[index].icon, size: 16, color: items[index].color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    items[index].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 10.8,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (index != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _ExpiredPlanActions extends StatelessWidget {
  const _ExpiredPlanActions({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showExpiredPlanPicker(context, controller),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            label: const Text('Want a different plan?'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              side: const BorderSide(color: Color(0xFFBFEAF2)),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: GoogleFonts.manrope(
                fontSize: 12.8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _openPricingComparison,
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            label: const Text('Compare all features'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandBlue,
              side: const BorderSide(color: Color(0xFFD8E2EC)),
              backgroundColor: const Color(0xFFF8FAFD),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: GoogleFonts.manrope(
                fontSize: 12.8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void _showExpiredPlanPicker(
  BuildContext context,
  PaymentController controller,
) {
  Get.bottomSheet(
    _ExpiredPlanPickerSheet(controller: controller),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

Future<void> _openPricingComparison() async {
  final uri = Uri.parse('https://www.visibloai.com/pricing');
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened) {
    Get.snackbar(
      'Unable to open pricing',
      'Please visit www.visibloai.com/pricing to compare all features.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

class _ExpiredPlanPickerSheet extends StatelessWidget {
  const _ExpiredPlanPickerSheet({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
        decoration: const BoxDecoration(
          color: Color(0xFFFAFCFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Obx(() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5DFEA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose a renewal plan',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Selected plan updates the expired checkout immediately.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 12.6,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: controller.plans.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final plan = controller.plans[index];
                    return _ExpiredSelectablePlanCard(
                      controller: controller,
                      plan: plan,
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ExpiredSelectablePlanCard extends StatelessWidget {
  const _ExpiredSelectablePlanCard({
    required this.controller,
    required this.plan,
  });

  final PaymentController controller;
  final BillingPlanDefinition plan;

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedPlanCode.value == plan.code;
    final isYearly = controller.selectedBillingCycle.value == 'yearly';
    final subtotal = plan.subtotalFor(controller.selectedBillingCycle.value);
    final gst = (subtotal * 0.18).round();
    final total = subtotal + gst;
    final originalYearly = plan.monthlyPriceInr * 12;
    final accent = _planAccentColor(plan.code);

    return InkWell(
      onTap: () {
        controller.selectPlan(plan.code);
        Get.back();
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : const Color(0xFFE1E9F2),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D003F70),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _renewalPlanTitle(plan),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (plan.recommended && !selected)
                  _PlanMiniBadge(label: 'MOST POPULAR', color: accent),
                if (selected) _PlanMiniBadge(label: 'SELECTED', color: accent),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              plan.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 12.2,
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isYearly && originalYearly > subtotal) ...[
                  Text(
                    _formatInr(originalYearly),
                    style: GoogleFonts.manrope(
                      fontSize: 11.8,
                      color: const Color(0xFF9AA7BA),
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  isYearly
                      ? _formatInr(plan.yearlyMonthlyPriceInr)
                      : _formatInr(plan.monthlyPriceInr),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 26,
                    height: 0.95,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '/mo',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Total: ${_formatInr(total)} incl. GST',
              style: GoogleFonts.manrope(
                fontSize: 11.4,
                color: const Color(0xFF7D8CA4),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 13),
            for (final feature in plan.features.take(5)) ...[
              _ExpiredFeatureCheck(label: _shortFeature(feature)),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanMiniBadge extends StatelessWidget {
  const _PlanMiniBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 8.5,
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SelectedBusinessCard extends StatelessWidget {
  const _SelectedBusinessCard({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    final onboardingController = Get.find<OnboardingController>();

    return Obx(() {
      final GoogleBusinessLocation? selectedLocation =
          onboardingController.activatedGoogleLocation.value;
      final selectedName = (selectedLocation?.title.trim().isNotEmpty ?? false)
          ? selectedLocation!.title.trim()
          : controller.selectedBusinessName;
      final selectedAddress =
          (selectedLocation?.conciseAddress.trim().isNotEmpty ?? false)
          ? selectedLocation!.conciseAddress.trim()
          : controller.selectedBusinessLocationLabel;
      final logoUrl = (selectedLocation?.logoUrl.trim().isNotEmpty ?? false)
          ? selectedLocation!.logoUrl.trim()
          : controller.selectedBusinessLogoUrl.trim();
      final initials = selectedName.isNotEmpty
          ? selectedName.characters.first.toUpperCase()
          : 'B';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: _cardDecoration(
          border: Border.all(color: const Color(0xFFE1E9F2)),
        ),
        child: Row(
          children: [
            _SelectedBusinessLogo(
              logoUrl: logoUrl,
              localPath: controller.currentUser?.businessPhotoPath.trim() ?? '',
              initials: initials,
              businessName: selectedName,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Business',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: const Color(0xFF7C889C),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 17.8,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Color(0xFF98A3B5),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          selectedAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 13.2,
                            color: AppColors.mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ],
        ),
      );
    });
  }
}

class _BusinessLogoFallback extends StatelessWidget {
  const _BusinessLogoFallback({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF245BEB), Color(0xFF39B4BD)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.manrope(
          fontSize: 28,
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SelectedBusinessLogo extends StatelessWidget {
  const _SelectedBusinessLogo({
    required this.logoUrl,
    required this.localPath,
    required this.initials,
    required this.businessName,
  });

  final String logoUrl;
  final String localPath;
  final String initials;
  final String businessName;

  @override
  Widget build(BuildContext context) {
    final hasLocalFile =
        localPath.isNotEmpty && !(Uri.tryParse(localPath)?.hasScheme ?? false);
    final hasRemoteUrl = logoUrl.isNotEmpty;
    final localIsRemote =
        localPath.isNotEmpty &&
        (localPath.startsWith('http://') || localPath.startsWith('https://'));
    final isAimbeat = businessName.toLowerCase().contains('aimbeat');

    Widget fallback() => _BusinessLogoFallback(initials: initials);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 64,
        height: 64,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: hasRemoteUrl
            ? Padding(
                padding: EdgeInsets.all(isAimbeat ? 8 : 0),
                child: Image.network(
                  logoUrl,
                  width: 64,
                  height: 64,
                  fit: isAimbeat ? BoxFit.contain : BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback(),
                ),
              )
            : localIsRemote
            ? Padding(
                padding: EdgeInsets.all(isAimbeat ? 8 : 0),
                child: Image.network(
                  localPath,
                  width: 64,
                  height: 64,
                  fit: isAimbeat ? BoxFit.contain : BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback(),
                ),
              )
            : hasLocalFile
            ? Padding(
                padding: EdgeInsets.all(isAimbeat ? 8 : 0),
                child: Image.file(
                  File(localPath),
                  width: 64,
                  height: 64,
                  fit: isAimbeat ? BoxFit.contain : BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback(),
                ),
              )
            : fallback(),
      ),
    );
  }
}

class _TrialBenefitsCard extends StatelessWidget {
  const _TrialBenefitsCard({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    final features = controller.selectedPlan.features
        .take(4)
        .toList(growable: false);
    final labels = <String>[
      'Access full\napp features',
      'Generate AI\nsocial posts',
      'Multi-platform\npublishing',
      'Manage your\nbusiness profile',
    ];
    final icons = <IconData>[
      Icons.dashboard_customize_outlined,
      Icons.auto_awesome_outlined,
      Icons.send_outlined,
      Icons.person_outline_rounded,
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: _cardDecoration(
        border: Border.all(color: const Color(0xFFE1E9F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What you\'ll get with your trial',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 18.5,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(4, (index) {
              final label = index < labels.length
                  ? labels[index]
                  : (index < features.length ? features[index] : '');
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      right: index == 3
                          ? BorderSide.none
                          : const BorderSide(color: Color(0xFFE7EDF5)),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: index.isEven
                                ? const [Color(0xFFF1F7FF), Color(0xFFE8FBFF)]
                                : const [Color(0xFFEFFFF7), Color(0xFFF4FDFF)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          icons[index],
                          color: index == 1 || index == 3
                              ? AppColors.primary
                              : AppColors.brandBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 34,
                        child: Text(
                          label,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            height: 1.14,
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SecureCheckoutNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FDFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFAEE5EC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF9FB),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safe & Secure Checkout',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Secure payment • Start instantly',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: Color(0xFF66768F),
              ),
              const SizedBox(width: 4),
              Text(
                'SSL Encrypted',
                textAlign: TextAlign.right,
                style: GoogleFonts.manrope(
                  fontSize: 10.8,
                  color: const Color(0xFF66768F),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrialPlanDetailsSheet extends StatelessWidget {
  const _TrialPlanDetailsSheet({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    final plan = controller.selectedPlan;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9E4EE),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              plan.name,
              style: GoogleFonts.manrope(
                fontSize: 22,
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              plan.description,
              style: GoogleFonts.manrope(
                fontSize: 14.5,
                color: AppColors.mutedText,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            for (final feature in plan.features.take(6)) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: AppColors.text,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentContent extends StatefulWidget {
  const _PaymentContent({required this.controller});

  final PaymentController controller;

  @override
  State<_PaymentContent> createState() => _PaymentContentState();
}

class _PaymentContentState extends State<_PaymentContent> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _billingHistoryKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final liveProfile = widget.controller.remoteProfile.value;
      if (widget.controller.isLoading.value && liveProfile == null) {
        return const _LoadingState();
      }

      if (liveProfile == null) {
        return _ErrorState(
          message:
              widget.controller.errorMessage.value ??
              'Unable to load billing details right now.',
          onRetry: widget.controller.refreshData,
        );
      }

      final maxWidth = MediaQuery.sizeOf(context).width >= 820 ? 720.0 : 560.0;

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: widget.controller.refreshData,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SubscriptionTopBar(
                      onBack: _handleBack,
                      onBillingHistoryTap: _scrollToBillingHistory,
                    ),
                    const SizedBox(height: 12),
                    if (widget.controller.errorMessage.value != null) ...[
                      _FeedbackBanner(
                        message: widget.controller.errorMessage.value!,
                        isError: true,
                        onDismiss: widget.controller.clearError,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (widget.controller.infoMessage.value != null) ...[
                      _FeedbackBanner(
                        message: widget.controller.infoMessage.value!,
                        onDismiss: widget.controller.clearInfo,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (widget.controller.billingWarnings.isNotEmpty) ...[
                      _BillingWarningsCard(controller: widget.controller),
                      const SizedBox(height: 12),
                    ],
                    _IntroAccessBanner(controller: widget.controller),
                    const SizedBox(height: 12),
                    _ActiveSubscriptionCard(controller: widget.controller),
                    const SizedBox(height: 12),
                    _UpgradePlansCard(controller: widget.controller),
                    const SizedBox(height: 12),
                    _SecurePaymentCard(controller: widget.controller),
                    const SizedBox(height: 12),
                    Container(
                      key: _billingHistoryKey,
                      child: _PaymentHistoryCard(controller: widget.controller),
                    ),
                    const SizedBox(height: 12),
                    _AutoRenewCard(controller: widget.controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _handleBack() {
    if (Get.previousRoute.isNotEmpty) {
      Get.back();
      return;
    }
    Get.offNamed(AppRoutes.account);
  }

  Future<void> _scrollToBillingHistory() async {
    final context = _billingHistoryKey.currentContext;
    if (context == null) {
      return;
    }
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFDCE5EE)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12003F70),
              blurRadius: 20,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.3,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading subscription...',
              style: AppTypography.button(
                fontSize: 14,
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFFFD2D2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12003F70),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEFF1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.credit_card_off_rounded,
                  color: Color(0xFFE24B4B),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Billing details unavailable',
                textAlign: TextAlign.center,
                style: AppTypography.card(
                  fontSize: 22,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body(
                  fontSize: 14,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => onRetry(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionTopBar extends StatelessWidget {
  const _SubscriptionTopBar({
    required this.onBack,
    required this.onBillingHistoryTap,
  });

  final VoidCallback onBack;
  final Future<void> Function() onBillingHistoryTap;

  @override
  Widget build(BuildContext context) {
    final backButton = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onBack,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12003F70),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.brandBlue,
            size: 18,
          ),
        ),
      ),
    );

    final historyButton = TextButton(
      onPressed: () => onBillingHistoryTap(),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Billing History',
        style: AppTypography.label(
          fontSize: 12.6,
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 380) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    backButton,
                    Expanded(
                      child: Text(
                        'Payments & Billing',
                        textAlign: TextAlign.center,
                        style: AppTypography.button(
                          fontSize: 20,
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 6),
                Align(alignment: Alignment.centerRight, child: historyButton),
              ],
            );
          }

          return Row(
            children: [
              backButton,
              Expanded(
                child: Text(
                  'Payments & Billing',
                  textAlign: TextAlign.center,
                  style: AppTypography.button(
                    fontSize: 20,
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              historyButton,
            ],
          );
        },
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.message,
    required this.onDismiss,
    this.isError = false,
  });

  final String message;
  final VoidCallback onDismiss;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final background = isError
        ? const Color(0xFFFFF1F1)
        : const Color(0xFFEFFAF6);
    final border = isError ? const Color(0xFFFFD0D0) : const Color(0xFFBDE8D2);
    final iconColor = isError
        ? const Color(0xFFE34B4B)
        : const Color(0xFF11885D);
    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(
                fontSize: 13.2,
                color: isError
                    ? const Color(0xFF913838)
                    : const Color(0xFF0B6D48),
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            splashRadius: 18,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.mutedText,
          ),
        ],
      ),
    );
  }
}

class _IntroAccessBanner extends StatelessWidget {
  const _IntroAccessBanner({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.hasActiveSubscription) {
      return const SizedBox.shrink();
    }

    final isRenewal = controller.requiresRenewalPayment;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2B5B), Color(0xFF42C7D5)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16003F70),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRenewal
                      ? 'Continue your visibility engine'
                      : 'Activate your first 7 days for Rs 99',
                  style: AppTypography.card(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isRenewal
                      ? 'This business is locked until billing is restored. Pick a monthly or yearly plan to continue where you left off.'
                      : 'Every business must complete payment before dashboard access. After 7 days, choose a plan to continue.',
                  style: AppTypography.body(
                    fontSize: 13.2,
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveSubscriptionCard extends StatelessWidget {
  const _ActiveSubscriptionCard({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    final amount = controller.activePlanMonthlyDisplayInr;
    final title = _planDisplayTitle(controller.activePlan);
    final renewText = controller.compactRenewalLabel;
    final statusColor = controller.hasActiveSubscription
        ? const Color(0xFF34C47C)
        : const Color(0xFFF5A623);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: _cardDecoration(
        border: Border.all(color: const Color(0xFFDCE5EE)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 390;

          Widget statusPill() {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    controller.hasActiveSubscription ? 'Active' : 'Pending',
                    style: AppTypography.label(
                      fontSize: 11.2,
                      color: statusColor == const Color(0xFFF5A623)
                          ? const Color(0xFF9A6711)
                          : const Color(0xFF2F6E58),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }

          Widget summaryText() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                statusPill(),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: AppTypography.card(
                    fontSize: 18.8,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
          }

          Widget amountBlock({bool alignEnd = true}) {
            return Column(
              crossAxisAlignment: alignEnd
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppTypography.card(
                      fontSize: 14,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      TextSpan(
                        text: _formatInr(amount),
                        style: AppTypography.card(
                          fontSize: 19,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: '/mo',
                        style: AppTypography.body(
                          fontSize: 12.5,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: alignEnd ? 120 : constraints.maxWidth,
                  ),
                  child: Text(
                    renewText == 'Not scheduled'
                        ? renewText
                        : 'Renews $renewText',
                    textAlign: alignEnd ? TextAlign.right : TextAlign.left,
                    style: AppTypography.body(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 2,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              if (compact) ...[
                summaryText(),
                const SizedBox(height: 12),
                amountBlock(alignEnd: false),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: summaryText()),
                    const SizedBox(width: 12),
                    amountBlock(),
                  ],
                ),
              const SizedBox(height: 14),
              if (compact) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${controller.daysRemaining} days remaining',
                      style: AppTypography.button(
                        fontSize: 12.8,
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(controller.renewalProgress * 100).round()}%',
                      style: AppTypography.label(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _cycleLabel(controller.activeBillingCycle),
                  style: AppTypography.label(
                    fontSize: 11.8,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${controller.daysRemaining} days remaining',
                            style: AppTypography.button(
                              fontSize: 12.8,
                              color: AppColors.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${(controller.renewalProgress * 100).round()}%',
                            style: AppTypography.label(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _cycleLabel(controller.activeBillingCycle),
                      style: AppTypography.label(
                        fontSize: 11.8,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: controller.renewalProgress,
                  minHeight: 4.5,
                  backgroundColor: const Color(0xFFE7EEF4),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.brandBlue,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFE8EEF4)),
              const SizedBox(height: 12),
              for (final feature in controller.activePlan.features.take(5)) ...[
                _FeatureBullet(label: feature),
                const SizedBox(height: 9),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _UpgradePlansCard extends StatefulWidget {
  const _UpgradePlansCard({required this.controller});

  final PaymentController controller;

  @override
  State<_UpgradePlansCard> createState() => _UpgradePlansCardState();
}

class _UpgradePlansCardState extends State<_UpgradePlansCard> {
  final Set<String> _expandedPlanCodes = <String>{};

  @override
  void initState() {
    super.initState();
    _expandedPlanCodes.add(widget.controller.selectedPlan.code);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.controller.hasActiveSubscription
                ? 'Change Your Plan'
                : 'Activate Your Plan',
            style: AppTypography.card(
              fontSize: 18,
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Review all three plans, expand the full feature list, and complete payment securely with Razorpay.',
            style: AppTypography.body(
              fontSize: 12.8,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 14),
          _BillingCycleToggle(controller: widget.controller),
          const SizedBox(height: 14),
          Column(
            children: [
              for (int index = 0; index < widget.controller.plans.length; index++) ...[
                _PlanOfferCard(
                  controller: widget.controller,
                  plan: widget.controller.plans[index],
                  expanded: _expandedPlanCodes.contains(
                    widget.controller.plans[index].code,
                  ),
                  onToggleExpanded: () {
                    final code = widget.controller.plans[index].code;
                    setState(() {
                      if (_expandedPlanCodes.contains(code)) {
                        _expandedPlanCodes.remove(code);
                      } else {
                        _expandedPlanCodes.add(code);
                      }
                    });
                  },
                ),
                if (index != widget.controller.plans.length - 1)
                  const SizedBox(height: 12),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BillingCycleToggle extends StatelessWidget {
  const _BillingCycleToggle({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE6EF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CycleOption(
              title: 'Monthly',
              selected: controller.selectedBillingCycle.value == 'monthly',
              onTap: () => controller.setBillingCycle('monthly'),
            ),
          ),
          Expanded(
            child: _CycleOption(
              title: 'Yearly',
              selected: controller.selectedBillingCycle.value == 'yearly',
              badge: 'Save 20%',
              onTap: () => controller.setBillingCycle('yearly'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleOption extends StatelessWidget {
  const _CycleOption({
    required this.title,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE2F4FA) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.button(
                    fontSize: 13.2,
                    color: selected ? AppColors.brandBlue : AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8FFF2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: AppTypography.label(
                        fontSize: 9.5,
                        color: const Color(0xFF1E8D58),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanOfferCard extends StatelessWidget {
  const _PlanOfferCard({
    required this.controller,
    required this.plan,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final PaymentController controller;
  final BillingPlanDefinition plan;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final isSelected = controller.selectedPlan.code == plan.code;
    final isActive = controller.activePlan.code == plan.code;
    final tag = switch (plan.code) {
      'SINGLE' => 'TRENDING',
      'PRO' => 'POPULAR',
      'PREMIUM' => 'BEST VALUE',
      _ => 'PLAN',
    };
    final accentColor = _planAccentColor(plan.code);
    final isYearly = controller.selectedBillingCycle.value == 'yearly';
    final price = plan.priceFor(controller.selectedBillingCycle.value);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected ? accentColor : const Color(0xFFDDE6EF),
          width: isSelected ? 1.7 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? accentColor.withValues(alpha: 0.18)
                : const Color(0x0C003F70),
            blurRadius: isSelected ? 22 : 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: Color.lerp(accentColor, Colors.white, 0.84),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(21),
              ),
            ),
            child: Text(
              isActive ? 'CURRENT' : tag,
              textAlign: TextAlign.center,
              style: AppTypography.label(
                fontSize: 10.2,
                color: accentColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 380;
                    final detailsAction = TextButton.icon(
                      onPressed: onToggleExpanded,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.brandBlue,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                      ),
                      label: Text(expanded ? 'Hide details' : 'Show details'),
                    );

                    final header = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _shortPlanTitle(plan),
                          style: AppTypography.card(
                            fontSize: 22,
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.description.replaceFirst('Best For: ', ''),
                          style: AppTypography.body(
                            fontSize: 13,
                            color: AppColors.mutedText,
                            height: 1.35,
                          ),
                        ),
                      ],
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          header,
                          const SizedBox(height: 10),
                          detailsAction,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: header),
                        const SizedBox(width: 12),
                        detailsAction,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: AppTypography.card(
                          fontSize: 16,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w700,
                        ),
                        children: [
                          TextSpan(
                            text: _formatInr(price),
                            style: AppTypography.card(
                              fontSize: 24,
                              color: AppColors.brandBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: '/mo',
                            style: AppTypography.body(
                              fontSize: 13,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isYearly)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAFBF2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Save ${_formatInr(plan.annualSavingsInr())} yearly',
                          style: AppTypography.label(
                            fontSize: 10.8,
                            color: const Color(0xFF168554),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isYearly
                      ? '${_formatInr(plan.yearlyTotalInr ?? price * 12)} billed yearly'
                      : _cycleLabel(controller.selectedBillingCycle.value),
                  style: AppTypography.body(
                    fontSize: 12.4,
                    color: isYearly
                        ? const Color(0xFF168554)
                        : AppColors.mutedText,
                    fontWeight: isYearly ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PlanInfoChip(
                      label: plan.capacityLabel,
                      background: const Color(0xFFF1F8FF),
                      foreground: AppColors.brandBlue,
                    ),
                    _PlanInfoChip(
                      label: plan.eyebrow,
                      background: Color.lerp(accentColor, Colors.white, 0.86)!,
                      foreground: accentColor,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                for (final feature in expanded ? plan.features : plan.features.take(4)) ...[
                  _FeatureBullet(label: feature),
                  const SizedBox(height: 9),
                ],
                if (!expanded && plan.features.length > 4)
                  Text(
                    '+${plan.features.length - 4} more features',
                    style: AppTypography.label(
                      fontSize: 11.5,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => controller.selectPlan(plan.code),
                    style: FilledButton.styleFrom(
                      backgroundColor: isActive
                          ? Colors.white
                          : (isSelected ? AppColors.brandBlue : accentColor),
                      foregroundColor: isActive
                          ? AppColors.brandBlue
                          : Colors.white,
                      side: isActive
                          ? const BorderSide(color: Color(0xFFD7E2EC))
                          : BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isActive ? 'Current Plan' : 'Select Plan',
                      style: AppTypography.button(
                        fontSize: 13.4,
                        color: isActive ? AppColors.brandBlue : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanInfoChip extends StatelessWidget {
  const _PlanInfoChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.label(
          fontSize: 11.1,
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SecurePaymentCard extends StatelessWidget {
  const _SecurePaymentCard({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    final selectedMethod = controller.selectedPaymentMethodId;
    final couponResult = controller.couponResult.value;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: _cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Color(0xFF1C8B57),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure payment',
                          style: AppTypography.button(
                            fontSize: 15.2,
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Choose manual checkout or AutoPay, then complete billing with Razorpay.',
                          style: AppTypography.body(
                            fontSize: 12.4,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PaymentMethodChip(
                    label: 'Manual pay',
                    selected: controller.selectedBillingMode.value == 'MANUAL',
                    onTap: controller.supportsManualCheckout
                        ? () => controller.setBillingMode('MANUAL')
                        : null,
                  ),
                  _PaymentMethodChip(
                    label: 'AutoPay',
                    selected: controller.selectedBillingMode.value == 'AUTOPAY',
                    onTap: controller.supportsAutopayCheckout
                        ? () => controller.setBillingMode('AUTOPAY')
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCE6F1)),
                ),
                child: Text(
                  controller.selectedBillingMode.value == 'AUTOPAY'
                      ? controller.canResumeAutopay
                            ? 'Resume recurring billing for this business. Razorpay will ask for a fresh mandate authorization.'
                            : 'Set up a recurring Razorpay mandate so renewals happen automatically until the owner cancels it.'
                      : 'Use a one-time Razorpay checkout for this billing cycle. This is best when the owner does not want recurring deductions yet.',
                  style: AppTypography.body(
                    fontSize: 12.6,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (controller.selectedBillingMode.value == 'MANUAL') ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final method in _paymentMethods)
                      _PaymentMethodChip(
                        label: method.label,
                        selected: selectedMethod == method.id,
                        onTap: () =>
                            controller.updatePreferredPaymentMethod(method.id),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (couponResult == null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBFCFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE1E9F2)),
                  ),
                  child: compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: controller.couponCodeController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: _couponInputDecoration(),
                            ),
                            const SizedBox(height: 10),
                            FilledButton(
                              onPressed:
                                  controller.isApplyingCoupon.value ||
                                      controller.couponCode.value.trim().isEmpty
                                  ? null
                                  : controller.applyCoupon,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.brandBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: controller.isApplyingCoupon.value
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.1,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Apply'),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller.couponCodeController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: _couponInputDecoration(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              onPressed:
                                  controller.isApplyingCoupon.value ||
                                      controller.couponCode.value.trim().isEmpty
                                  ? null
                                  : controller.applyCoupon,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.brandBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: controller.isApplyingCoupon.value
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.1,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Apply'),
                            ),
                          ],
                        ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FBF6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFC4EAD4)),
                  ),
                  child: compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_offer_rounded,
                                  color: Color(0xFF1D8F58),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    couponResult.skipPayment
                                        ? '${couponResult.coupon?.code ?? controller.couponCode.value} makes this checkout free.'
                                        : '${couponResult.coupon?.code ?? controller.couponCode.value} applied to the server order.',
                                    style: AppTypography.body(
                                      fontSize: 12.6,
                                      color: const Color(0xFF126B42),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: controller.removeCoupon,
                                child: const Text('Remove'),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const Icon(
                              Icons.local_offer_rounded,
                              color: Color(0xFF1D8F58),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                couponResult.skipPayment
                                    ? '${couponResult.coupon?.code ?? controller.couponCode.value} makes this checkout free.'
                                    : '${couponResult.coupon?.code ?? controller.couponCode.value} applied to the server order.',
                                style: AppTypography.body(
                                  fontSize: 12.6,
                                  color: const Color(0xFF126B42),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: controller.removeCoupon,
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                ),
              const SizedBox(height: 14),
              Text(
                controller.couponResult.value?.skipPayment == true
                    ? 'This action will activate the selected plan immediately using the validated coupon.'
                    : controller.selectedBillingMode.value == 'AUTOPAY'
                    ? 'AutoPay is only a mandate setup here. The backend still controls renewal status, warnings, and cancellation rules per activated business.'
                    : 'Razorpay checkout stays real. The charged amount comes from the backend order created at tap time.',
                style: AppTypography.body(
                  fontSize: 12.2,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: controller.isSelectedPlanBusy
                      ? null
                      : controller.checkoutSelectedPlan,
                  icon: controller.isSelectedPlanBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.1,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          controller.couponResult.value?.skipPayment == true
                              ? Icons.auto_awesome_rounded
                              : Icons.lock_rounded,
                          size: 18,
                        ),
                  label: Text(controller.checkoutButtonLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  const _PaymentHistoryCard({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final records = controller.paymentHistory;
      final canDownloadAll = controller.hasDownloadableInvoices;

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: _cardDecoration(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            final downloadAllLabel = controller.isDownloadingAllInvoices.value
                ? 'Saving...'
                : 'Download all';

            Widget headerAction() {
              if (!canDownloadAll) {
                return const SizedBox.shrink();
              }
              return GestureDetector(
                onTap: controller.isDownloadingAllInvoices.value
                    ? null
                    : controller.downloadAllInvoices,
                child: Text(
                  downloadAllLabel,
                  style: AppTypography.label(
                    fontSize: 12,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (compact)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment History',
                        style: AppTypography.card(
                          fontSize: 17,
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (canDownloadAll) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: headerAction(),
                        ),
                      ],
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Payment History',
                          style: AppTypography.card(
                            fontSize: 17,
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      headerAction(),
                    ],
                  ),
                const SizedBox(height: 10),
                if (records.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'No billing records yet. Your successful Razorpay payments and invoices will appear here.',
                      style: AppTypography.body(
                        fontSize: 13.2,
                        color: AppColors.mutedText,
                      ),
                    ),
                  )
                else
                  for (int index = 0; index < records.length; index++) ...[
                    _PaymentHistoryRow(
                      controller: controller,
                      record: records[index],
                    ),
                    if (index != records.length - 1)
                      const Divider(height: 20, color: Color(0xFFE8EEF4)),
                  ],
              ],
            );
          },
        ),
      );
    });
  }
}

class _PaymentHistoryRow extends StatelessWidget {
  const _PaymentHistoryRow({required this.controller, required this.record});

  final PaymentController controller;
  final SubscriptionPaymentRecord record;

  @override
  Widget build(BuildContext context) {
    final paidDate = DateTime.tryParse(record.paidOnIso);
    final dateLabel = paidDate == null ? 'Unknown date' : _formatDate(paidDate);
    final invoiceLabel = record.invoiceNumber?.trim() ?? '';
    final businessLabel = record.businessName?.trim() ?? '';
    final locationLabel = record.businessLocation?.trim() ?? '';
    final isDownloading = controller.isInvoiceDownloading(record.invoiceId);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 350;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _historyPlanTitle(record.planId),
                style: AppTypography.button(
                  fontSize: 14,
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (businessLabel.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  businessLabel,
                  style: AppTypography.body(
                    fontSize: 12.4,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                dateLabel,
                style: AppTypography.body(
                  fontSize: 12.2,
                  color: AppColors.mutedText,
                ),
              ),
              if (invoiceLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  invoiceLabel,
                  style: AppTypography.body(
                    fontSize: 11.6,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
              if (locationLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  locationLabel,
                  style: AppTypography.body(
                    fontSize: 11.6,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _formatInr(record.amountInr),
                    style: AppTypography.button(
                      fontSize: 15,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8EF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      record.status,
                      style: AppTypography.label(
                        fontSize: 10.5,
                        color: const Color(0xFF24985D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (record.canDownload &&
                      (record.invoiceId?.trim().isNotEmpty ?? false)) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: isDownloading
                          ? null
                          : () => controller.downloadInvoice(record),
                      child: Text(
                        isDownloading ? 'Saving...' : 'Invoice',
                        style: AppTypography.label(
                          fontSize: 11.5,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _historyPlanTitle(record.planId),
                    style: AppTypography.button(
                      fontSize: 14,
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateLabel,
                    style: AppTypography.body(
                      fontSize: 12.2,
                      color: AppColors.mutedText,
                    ),
                  ),
                  if (invoiceLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      invoiceLabel,
                      style: AppTypography.body(
                        fontSize: 11.6,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                  if (businessLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      businessLabel,
                      style: AppTypography.body(
                        fontSize: 11.8,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (locationLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      locationLabel,
                      style: AppTypography.body(
                        fontSize: 11.6,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatInr(record.amountInr),
                  style: AppTypography.button(
                    fontSize: 15,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8EF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    record.status,
                    style: AppTypography.label(
                      fontSize: 10.5,
                      color: const Color(0xFF24985D),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (record.canDownload &&
                    (record.invoiceId?.trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: isDownloading
                        ? null
                        : () => controller.downloadInvoice(record),
                    child: Text(
                      isDownloading ? 'Saving...' : 'Download invoice',
                      style: AppTypography.label(
                        fontSize: 11.4,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AutoRenewCard extends StatelessWidget {
  const _AutoRenewCard({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: _cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final toggle = Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: controller.autoRenewEnabled
                  ? const Color(0xFFE4FAFC)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Switch.adaptive(
              value: controller.autoRenewEnabled,
              onChanged: controller.updateAutoRenew,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: const Color(0xFFD8E1EA),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-Renewal',
                  style: AppTypography.card(
                    fontSize: 17,
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.compactRenewalLabel == 'Not scheduled'
                      ? 'Renewal date not available yet.'
                      : 'Renews automatically on ${controller.compactRenewalLabel}, 2026'
                            .replaceFirst(
                              ', 2026',
                              controller.renewalDate == null
                                  ? ''
                                  : ', ${controller.renewalDate!.year}',
                            ),
                  style: AppTypography.body(
                    fontSize: 12.6,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: toggle),
                if (controller.canResumeAutopay ||
                    controller.canCancelAutopay) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (controller.canResumeAutopay)
                        OutlinedButton.icon(
                          onPressed: controller.resumeAutopay,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Resume AutoPay'),
                        ),
                      if (controller.canCancelAutopay)
                        TextButton.icon(
                          onPressed: controller.cancelAutopay,
                          icon: const Icon(
                            Icons.pause_circle_outline,
                            size: 16,
                          ),
                          label: const Text('Stop at period end'),
                        ),
                    ],
                  ),
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Renewal',
                      style: AppTypography.card(
                        fontSize: 17,
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.compactRenewalLabel == 'Not scheduled'
                          ? 'Renewal date not available yet.'
                          : 'Renews automatically on ${controller.compactRenewalLabel}, 2026'
                                .replaceFirst(
                                  ', 2026',
                                  controller.renewalDate == null
                                      ? ''
                                      : ', ${controller.renewalDate!.year}',
                                ),
                      style: AppTypography.body(
                        fontSize: 12.6,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  toggle,
                  if (controller.canResumeAutopay ||
                      controller.canCancelAutopay) ...[
                    const SizedBox(height: 10),
                    if (controller.canResumeAutopay)
                      OutlinedButton(
                        onPressed: controller.resumeAutopay,
                        child: const Text('Resume'),
                      ),
                    if (controller.canCancelAutopay)
                      TextButton(
                        onPressed: controller.cancelAutopay,
                        child: const Text('Stop at period end'),
                      ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BillingWarningsCard extends StatelessWidget {
  const _BillingWarningsCard({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration().copyWith(
        border: Border.all(color: const Color(0xFFE4EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Billing status',
            style: AppTypography.card(
              fontSize: 18,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final warning in controller.billingWarnings) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _warningBackground(warning.severity),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _warningBorder(warning.severity)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warning.title,
                    style: AppTypography.button(
                      fontSize: 13.5,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    warning.message,
                    style: AppTypography.body(
                      fontSize: 12.6,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  const _FeatureBullet({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Icon(Icons.circle, size: 6, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _shortFeature(label),
            style: AppTypography.body(fontSize: 13.1, color: AppColors.text),
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  const _PaymentMethodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE2F6FC)
              : onTap == null
              ? const Color(0xFFF8FAFC)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : onTap == null
                ? const Color(0xFFE2E8F0)
                : const Color(0xFFD6E1EB),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.label(
            fontSize: 11.2,
            color: selected
                ? AppColors.brandBlue
                : onTap == null
                ? AppColors.mutedText
                : AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodItem {
  const _PaymentMethodItem({required this.id, required this.label});

  final String id;
  final String label;
}

const _paymentMethods = <_PaymentMethodItem>[
  _PaymentMethodItem(id: 'visa', label: 'VISA'),
  _PaymentMethodItem(id: 'mc', label: 'MC'),
  _PaymentMethodItem(id: 'amex', label: 'AMEX'),
  _PaymentMethodItem(id: 'apple_pay', label: 'Apple Pay'),
  _PaymentMethodItem(id: 'upi', label: 'UPI'),
];

Color _warningBackground(String severity) {
  switch (severity.toLowerCase()) {
    case 'error':
      return const Color(0xFFFFF1F2);
    case 'info':
      return const Color(0xFFF1FBFF);
    case 'warning':
    default:
      return const Color(0xFFFFF8EB);
  }
}

Color _warningBorder(String severity) {
  switch (severity.toLowerCase()) {
    case 'error':
      return const Color(0xFFFFC9D2);
    case 'info':
      return const Color(0xFFCFEFFC);
    case 'warning':
    default:
      return const Color(0xFFF9D68D);
  }
}

InputDecoration _couponInputDecoration() {
  return InputDecoration(
    hintText: 'Coupon code',
    hintStyle: AppTypography.body(fontSize: 13, color: AppColors.mutedText),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD6E1EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD6E1EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
  );
}

BoxDecoration _cardDecoration({Border? border}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: border ?? Border.all(color: const Color(0xFFDCE5EE)),
    boxShadow: const [
      BoxShadow(
        color: Color(0x10003F70),
        blurRadius: 18,
        offset: Offset(0, 10),
      ),
    ],
  );
}

Color _planAccentColor(String code) {
  switch (code) {
    case 'SINGLE':
      return const Color(0xFF42BFDA);
    case 'PRO':
      return const Color(0xFF1FA5D4);
    case 'PREMIUM':
      return const Color(0xFF322D93);
    default:
      return AppColors.primary;
  }
}

String _planDisplayTitle(BillingPlanDefinition plan) {
  if (plan.code == 'PREMIUM') {
    return 'Business Pro';
  }
  return plan.name.replaceAll(' Package', ' Plan');
}

String _shortPlanTitle(BillingPlanDefinition plan) {
  switch (plan.code) {
    case 'SINGLE':
      return 'Starter';
    case 'PRO':
      return 'Growth';
    case 'PREMIUM':
      return 'Business Pro';
    default:
      return plan.name;
  }
}

String _renewalPlanTitle(BillingPlanDefinition plan) {
  final name = plan.name.trim();
  if (name.isEmpty) {
    return _shortPlanTitle(plan);
  }
  return name.replaceAll(' Package', '').replaceAll(' Plan', '');
}

String _renewalPlanSubtitle(BillingPlanDefinition plan) {
  switch (plan.code) {
    case 'SINGLE':
      return 'Small businesses starting online';
    case 'PRO':
      return 'For continuous inquiries and branding';
    case 'PREMIUM':
      return 'Maximum AI automation • Up to 5 business locations';
    default:
      return plan.suitableFor;
  }
}

String _historyPlanTitle(String planId) {
  switch (planId.trim().toLowerCase()) {
    case 'starter':
      return 'Starter Plan';
    case 'premium':
      return 'Business Pro Plan';
    case 'enterprise':
      return 'Business Pro Plan';
    case 'growth':
    default:
      return 'Growth Plan';
  }
}

String _cycleLabel(String billingCycle) {
  return billingCycle == 'yearly' ? 'Annual plan' : 'Monthly plan';
}

String _shortFeature(String value) {
  return value
      .replaceAll(' or ', ' / ')
      .replaceAll('support', 'Support')
      .replaceAll('automation', 'Automation');
}

String _formatInr(int amount) {
  final digits = amount.toString();
  if (digits.length <= 3) {
    return '₹$digits';
  }

  final lastThree = digits.substring(digits.length - 3);
  final prefix = digits.substring(0, digits.length - 3);
  final parts = <String>[];
  for (int index = prefix.length; index > 0; index -= 2) {
    final start = (index - 2).clamp(0, prefix.length);
    parts.insert(0, prefix.substring(start, index));
  }

  return '₹${parts.join(',')},$lastThree';
}

String _formatDate(DateTime value) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}

String _expiredAgoLabel(DateTime? expiredAt) {
  if (expiredAt == null) {
    return 'Plan expired';
  }

  final diff = DateTime.now().difference(expiredAt);
  if (diff.inMinutes < 1) {
    return 'Expired just now';
  }
  if (diff.inHours < 1) {
    return 'Expired ${diff.inMinutes}m ago';
  }
  if (diff.inDays < 1) {
    return 'Expired ${diff.inHours}h ago';
  }
  if (diff.inDays < 30) {
    return 'Expired ${diff.inDays}d ago';
  }
  final months = (diff.inDays / 30).floor();
  if (months < 12) {
    return 'Expired ${months}mo ago';
  }
  final years = (diff.inDays / 365).floor();
  return 'Expired ${years}y ago';
}
