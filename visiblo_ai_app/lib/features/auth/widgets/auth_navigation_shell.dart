import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

enum AuthTab { home, audit, reports, payment, account }

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
    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: AuthBottomNavigationBar(currentTab: currentTab),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(child: child),
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
    final items = [
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
        label: 'Payment',
        icon: Icons.account_balance_wallet_outlined,
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
    };

    if (Get.currentRoute != route) {
      Get.offNamed(route);
    }
  }
}
