import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/platform_billing_policy.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_responsive.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_logo.dart';
import '../controllers/product_mode_controller.dart';

enum AuthTab {
  home,
  audit,
  reports,
  payment,
  account,
  socialDashboard,
  socialAccounts,
  socialCreate,
  socialCalendar,
  socialPosts,
  socialAnalytics,
  socialProfile,
}

class AuthNavigationShell extends StatelessWidget {
  const AuthNavigationShell({
    super.key,
    required this.currentTab,
    required this.child,
    this.backgroundColor = Colors.white,
    this.floatingActionButton,
  });

  final AuthTab currentTab;
  final Widget child;
  final Color backgroundColor;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTabletOrLarger;

    if (isTablet) {
      return Scaffold(
        backgroundColor: backgroundColor,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: Row(
          children: [
            _AuthTabletSideNav(currentTab: currentTab),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFE8E8EE),
            ),
            Expanded(child: SafeArea(child: child)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: AuthBottomNavigationBar(currentTab: currentTab),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(child: child),
    );
  }
}

class _AuthTabletSideNav extends StatelessWidget {
  const _AuthTabletSideNav({required this.currentTab});

  final AuthTab currentTab;

  @override
  Widget build(BuildContext context) {
    final productModeController = Get.isRegistered<ProductModeController>()
        ? Get.find<ProductModeController>()
        : Get.put(ProductModeController(), permanent: true);
    final isSocialShell =
        productModeController.isSocialMedia || currentTab._isSocialTab;

    final paymentLabel = PlatformBillingPolicy.usesSupportActivation
        ? 'Plan'
        : 'Payment';
    final items = isSocialShell
        ? [
            (
              tab: AuthTab.socialDashboard,
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
            ),
            (
              tab: AuthTab.socialAccounts,
              label: 'Accounts',
              icon: Icons.groups_outlined,
            ),
            (
              tab: AuthTab.socialPosts,
              label: 'Posts',
              icon: Icons.task_alt_rounded,
            ),
            (
              tab: AuthTab.socialCalendar,
              label: 'Calendar',
              icon: Icons.calendar_month_outlined,
            ),
            (
              tab: AuthTab.socialAnalytics,
              label: 'Analytics',
              icon: Icons.bar_chart_rounded,
            ),
          ]
        : [
            (tab: AuthTab.home, label: 'Home', icon: Icons.home_outlined),
            (
              tab: AuthTab.audit,
              label: 'Audit',
              icon: Icons.insert_chart_outlined_rounded,
            ),
            (
              tab: AuthTab.reports,
              label: 'Reports',
              icon: Icons.pie_chart_outline_rounded,
            ),
            (
              tab: AuthTab.payment,
              label: paymentLabel,
              icon: PlatformBillingPolicy.usesSupportActivation
                  ? Icons.verified_user_outlined
                  : Icons.account_balance_wallet_outlined,
            ),
            (
              tab: AuthTab.account,
              label: 'Account',
              icon: Icons.person_outline_rounded,
            ),
          ];

    return Container(
      width: 230,
      color: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: AppLogo(iconSize: 42, centered: false),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = item.tab == currentTab;
                  return InkWell(
                    onTap: () => _NavItem(
                      tab: item.tab,
                      currentTab: currentTab,
                      label: item.label,
                      icon: item.icon,
                    )._navigate(item.tab),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brandBlue.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 24,
                            color: isSelected
                                ? AppColors.brandBlue
                                : const Color(0xFF5A6473),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              item.label,
                              style: AppTypography.button(
                                fontSize: 15,
                                color: isSelected
                                    ? AppColors.brandBlue
                                    : const Color(0xFF5A6473),
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void handleAuthBack() {
  final navigator = Get.key.currentState;
  if (navigator != null && navigator.canPop()) {
    Get.back<void>();
    return;
  }

  if (Get.currentRoute != AppRoutes.dashboard) {
    Get.offNamed(AppRoutes.dashboard);
  }
}

class AuthShellBackButton extends StatelessWidget {
  const AuthShellBackButton({
    super.key,
    this.onTap,
    this.size = 38,
    this.iconSize = 18,
    this.backgroundColor = const Color(0xFFF2F6FB),
    this.iconColor = AppColors.brandBlue,
  });

  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? handleAuthBack,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE1E7F0)),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

class AuthBottomNavigationBar extends StatelessWidget {
  const AuthBottomNavigationBar({super.key, required this.currentTab});

  final AuthTab currentTab;

  @override
  Widget build(BuildContext context) {
    final productModeController = Get.isRegistered<ProductModeController>()
        ? Get.find<ProductModeController>()
        : Get.put(ProductModeController(), permanent: true);
    final isSocialShell =
        productModeController.isSocialMedia || currentTab._isSocialTab;
    final paymentLabel = PlatformBillingPolicy.usesSupportActivation
        ? 'Plan'
        : 'Payment';
    final items = isSocialShell
        ? [
            (
              tab: AuthTab.socialDashboard,
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
              iconWeight: 350.0,
            ),
            (
              tab: AuthTab.socialAccounts,
              label: 'Accounts',
              icon: Icons.groups_outlined,
              iconWeight: 350.0,
            ),
            (
              tab: AuthTab.socialPosts,
              label: 'Posts',
              icon: Icons.task_alt_rounded,
              iconWeight: 350.0,
            ),
            (
              tab: AuthTab.socialCalendar,
              label: 'Calendar',
              icon: Icons.calendar_month_outlined,
              iconWeight: 350.0,
            ),
            (
              tab: AuthTab.socialAnalytics,
              label: 'Analytics',
              icon: Icons.bar_chart_rounded,
              iconWeight: 350.0,
            ),
          ]
        : [
            (
              tab: AuthTab.home,
              label: 'Home',
              icon: Icons.home_outlined,
              iconWeight: 300.0,
            ),
            (
              tab: AuthTab.audit,
              label: 'Audit',
              icon: Icons.insert_chart_outlined_rounded,
              iconWeight: 400.0,
            ),
            (
              tab: AuthTab.reports,
              label: 'Reports',
              icon: Icons.pie_chart_outline_rounded,
              iconWeight: 300.0,
            ),
            (
              tab: AuthTab.payment,
              label: paymentLabel,
              icon: PlatformBillingPolicy.usesSupportActivation
                  ? Icons.verified_user_outlined
                  : Icons.account_balance_wallet_outlined,
              iconWeight: 300.0,
            ),
            (
              tab: AuthTab.account,
              label: 'Account',
              icon: Icons.person_outline_rounded,
              iconWeight: 300.0,
            ),
          ];

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8E8EE))),
        boxShadow: [
          BoxShadow(
            color: Color(0x080F2746),
            blurRadius: 14,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: items
              .map(
                (item) => Expanded(
                  child: _NavItem(
                    tab: item.tab,
                    currentTab: currentTab,
                    label: item.label,
                    icon: item.icon,
                    iconWeight: item.iconWeight,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.currentTab,
    required this.label,
    required this.icon,
    this.iconWeight = 300,
  });

  final AuthTab tab;
  final AuthTab currentTab;
  final String label;
  final IconData icon;
  final double iconWeight;

  @override
  Widget build(BuildContext context) {
    final isSelected = tab == currentTab;
    final color = isSelected ? AppColors.brandBlue : const Color(0xFF5A6473);
    final labelStyle =
        Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ) ??
        AppTypography.label(
          color: color,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _navigate(tab),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 23, color: color, fill: 0, weight: iconWeight),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: labelStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(AuthTab tab) {
    final route = switch (tab) {
      AuthTab.home => AppRoutes.dashboard,
      AuthTab.audit => AppRoutes.audit,
      AuthTab.reports => AppRoutes.reports,
      AuthTab.payment => AppRoutes.payment,
      AuthTab.account => AppRoutes.account,
      AuthTab.socialDashboard => AppRoutes.socialDashboard,
      AuthTab.socialAccounts => AppRoutes.socialAccounts,
      AuthTab.socialCreate => AppRoutes.socialCreate,
      AuthTab.socialCalendar => AppRoutes.socialCalendar,
      AuthTab.socialPosts => AppRoutes.socialPosts,
      AuthTab.socialAnalytics => AppRoutes.socialAnalytics,
      AuthTab.socialProfile => AppRoutes.socialProfile,
    };

    final productModeController = Get.isRegistered<ProductModeController>()
        ? Get.find<ProductModeController>()
        : Get.put(ProductModeController(), permanent: true);
    productModeController.selectMode(
      tab._isSocialTab ? ProductMode.socialMedia : ProductMode.googleBusiness,
    );

    if (Get.currentRoute != route) {
      Get.offNamed(route);
    }
  }
}

extension on AuthTab {
  bool get _isSocialTab {
    return this == AuthTab.socialDashboard ||
        this == AuthTab.socialAccounts ||
        this == AuthTab.socialCreate ||
        this == AuthTab.socialCalendar ||
        this == AuthTab.socialPosts ||
        this == AuthTab.socialAnalytics ||
        this == AuthTab.socialProfile;
  }
}
