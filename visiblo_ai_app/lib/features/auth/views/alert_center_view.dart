import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../controllers/alert_center_controller.dart';
import '../models/alert_center_models.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_navigation_shell.dart';

class AlertCenterView extends GetView<AlertCenterController> {
  const AlertCenterView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthNavigationShell(
      currentTab: AuthTab.home,
      backgroundColor: const Color(0xFFF7F9FC),
      child: _AlertCenterBody(controller: controller),
    );
  }
}

class _AlertCenterBody extends StatefulWidget {
  const _AlertCenterBody({required this.controller});

  final AlertCenterController controller;

  @override
  State<_AlertCenterBody> createState() => _AlertCenterBodyState();
}

class _AlertCenterBodyState extends State<_AlertCenterBody> {
  final ValueNotifier<double> _scrollSignal = ValueNotifier<double>(0);

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    _scrollSignal.value = notification.metrics.pixels / 20;
    return false;
  }

  @override
  void dispose() {
    _scrollSignal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = widget.controller;

      if (controller.isLoading.value && controller.alerts.isEmpty) {
        return const _LoadingState();
      }

      final topAlert = controller.topAlert;
      final filteredAlerts = controller.filteredAlerts;
      final recentActivity = controller.recentActivity;
      final stats = controller.effectiveStats;
      final statsByType = controller.effectiveStatsByType;

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.refreshData,
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: ListView(
            key: const PageStorageKey<String>('alert-center-scroll'),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              AuthViewSpacing.pageHorizontal,
              12,
              AuthViewSpacing.pageHorizontal,
              28,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderBar(
                        isRefreshing:
                            controller.isRefreshing.value ||
                            controller.isGenerating.value,
                      ),
                      const SizedBox(height: 14),
                      if (controller.errorMessage.value != null) ...[
                        _FeedbackBanner(
                          message: controller.errorMessage.value!,
                          isError: true,
                          onDismiss: controller.clearError,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (controller.infoMessage.value != null) ...[
                        _FeedbackBanner(
                          message: controller.infoMessage.value!,
                          onDismiss: controller.clearInfo,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _StatsGrid(stats: stats),
                      const SizedBox(height: 12),
                      _CommandBriefCard(
                        openAlertCount: controller.openAlerts.length,
                        topAlert: topAlert,
                      ),
                      const SizedBox(height: 12),
                      _MissionCard(
                        topAlert: topAlert,
                        isGenerating: controller.isGenerating.value,
                        onScan: controller.generateAlertScan,
                        onFixTopIssue: topAlert == null
                            ? null
                            : () => controller.openAlertAction(topAlert),
                      ),
                      const SizedBox(height: 14),
                      _FilterTabs(
                        activeFilter: controller.activeFilter.value,
                        countForFilter: controller.countForFilter,
                        onSelected: controller.selectFilter,
                      ),
                      const SizedBox(height: 12),
                      if (filteredAlerts.isEmpty)
                        _EmptyAlertsCard(
                          isScanning: controller.isGenerating.value,
                          activeFilter: controller.activeFilter.value,
                          onScan: controller.generateAlertScan,
                        )
                      else
                        Column(
                          children: filteredAlerts
                              .map(
                                (alert) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _AlertCard(
                                    alert: alert,
                                    isBusy: controller.isBusyForAlert(alert.id),
                                    isResolving:
                                        controller.resolvingAlertId.value ==
                                        alert.id,
                                    isMarkingRead:
                                        controller.markingReadAlertId.value ==
                                        alert.id,
                                    isOpening:
                                        controller.openingAlertId.value ==
                                        alert.id,
                                    onOpen: () =>
                                        controller.openAlertAction(alert),
                                    onRead: () =>
                                        controller.markAlertAsRead(alert.id),
                                    onResolve: () =>
                                        controller.resolveAlert(alert.id),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      const SizedBox(height: 14),
                      _BreakdownCard(
                        activeFilter: controller.activeFilter.value,
                        statsByType: statsByType,
                        scrollSignal: _scrollSignal,
                        onSelect: controller.selectFilter,
                      ),
                      const SizedBox(height: 14),
                      _PriorityPlaybookCard(
                        urgentCount: controller.urgentAlerts.length,
                        openCount: controller.openAlerts.length,
                      ),
                      const SizedBox(height: 14),
                      _RecentActivityCard(
                        alerts: recentActivity,
                        onSelect: controller.openAlertAction,
                        onSeeAll: () =>
                            controller.selectFilter(AlertSignalFilter.all),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12003F70),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.3,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading alert intelligence...',
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

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({required this.isRefreshing});

  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: AuthShellBackButton(size: 36, iconSize: 16),
          ),
          Text(
            'Alert Center',
            style: AppTypography.section(
              fontSize: 18,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 36,
              height: 36,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isRefreshing
                    ? const Padding(
                        key: ValueKey('refreshing'),
                        padding: EdgeInsets.all(9),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.primary,
                        ),
                      )
                    : const SizedBox(key: ValueKey('idle')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final AlertStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;
        final mobileAspectRatio = constraints.maxWidth < 380 ? 1.1 : 1.18;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: isWide ? 1.55 : mobileAspectRatio,
          children: [
            _StatCard(
              title: 'Urgent',
              value: '${stats.highPriority}',
              helper: stats.highPriority == 0 ? 'Stable' : 'Needs action',
              icon: Icons.notifications_active_outlined,
              accentColor: const Color(0xFFEF5350),
              softColor: const Color(0xFFFFF0EF),
            ),
            _StatCard(
              title: 'Fixed today',
              value: '${stats.resolvedToday}',
              helper: stats.resolvedToday == 0 ? 'No fixes yet' : 'Resolved',
              icon: Icons.check_circle_outline_rounded,
              accentColor: const Color(0xFF43C3C9),
              softColor: const Color(0xFFEAFBFD),
            ),
            _StatCard(
              title: 'Newest issue',
              value: stats.avgResponseStr,
              helper: 'Latest signal',
              icon: Icons.access_time_rounded,
              accentColor: const Color(0xFF6CCB79),
              softColor: const Color(0xFFEEFCEF),
            ),
            _StatCard(
              title: 'Unread',
              value: '${stats.unread}',
              helper: stats.unread == 0 ? 'Caught up' : 'Needs review',
              icon: Icons.mail_outline_rounded,
              accentColor: const Color(0xFFF5B443),
              softColor: const Color(0xFFFFF7E9),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.helper,
    required this.icon,
    required this.accentColor,
    required this.softColor,
  });

  final String title;
  final String value;
  final String helper;
  final IconData icon;
  final Color accentColor;
  final Color softColor;

  @override
  Widget build(BuildContext context) {
    final compactValue = value.trim();
    final isLongValue = compactValue.length >= 7;
    final fontSize = isLongValue ? 16.0 : 28.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EBF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A003F70),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: softColor, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(height: 12),
          Text(
            title.toUpperCase(),
            style: AppTypography.label(
              fontSize: 10.3,
              color: AppColors.mutedText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  compactValue.isEmpty ? '0' : compactValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.section(
                    fontSize: fontSize,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label(
              fontSize: 10.8,
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandBriefCard extends StatelessWidget {
  const _CommandBriefCard({
    required this.openAlertCount,
    required this.topAlert,
  });

  final int openAlertCount;
  final BusinessAlert? topAlert;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF3FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA7D8F4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT COMMAND BRIEF',
                  style: AppTypography.label(
                    fontSize: 10.8,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  openAlertCount == 0
                      ? 'All clear'
                      : '$openAlertCount open action${openAlertCount == 1 ? '' : 's'}',
                  style: AppTypography.section(
                    fontSize: 18,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  topAlert == null
                      ? 'No urgent business issues are open right now.'
                      : 'Start with: ${topAlert!.title}.',
                  style: AppTypography.body(
                    fontSize: 13.4,
                    color: AppColors.text.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.monitor_heart_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.topAlert,
    required this.isGenerating,
    required this.onScan,
    required this.onFixTopIssue,
  });

  final BusinessAlert? topAlert;
  final bool isGenerating;
  final Future<void> Function() onScan;
  final Future<void> Function()? onFixTopIssue;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6657F6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE BUSINESS WATCHTOWER',
                  style: AppTypography.label(
                    fontSize: 10.3,
                    color: const Color(0xFF5345DF),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Fix the issues that are quietly leaking local growth.',
            style: AppTypography.section(
              fontSize: 22,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Alerts now scan your real profile health, reviews, posts, insights, keywords, and citations. Each alert tells you what happened, why it matters, and where to fix it.',
            style: AppTypography.body(
              fontSize: 13.6,
              color: AppColors.text.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: isGenerating ? null : onScan,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.radar_rounded, size: 18),
                label: Text(
                  isGenerating ? 'Running scan...' : 'Run alert scan',
                  style: AppTypography.button(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
              if (topAlert != null)
                OutlinedButton.icon(
                  onPressed: onFixTopIssue,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandBlue,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF38BFC9)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    'Fix top issue',
                    style: AppTypography.button(
                      fontSize: 13,
                      color: AppColors.brandBlue,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.activeFilter,
    required this.countForFilter,
    required this.onSelected,
  });

  final AlertSignalFilter activeFilter;
  final int Function(AlertSignalFilter filter) countForFilter;
  final void Function(AlertSignalFilter filter) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: AlertSignalFilter.values
            .map(
              (filter) => Padding(
                padding: EdgeInsets.only(
                  right: filter == AlertSignalFilter.values.last ? 0 : 8,
                ),
                child: _FilterChipButton(
                  label: filter == AlertSignalFilter.all
                      ? 'All Alerts'
                      : filter.label,
                  count: countForFilter(filter),
                  selected: activeFilter == filter,
                  onTap: () => onSelected(filter),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : const Color(0xFFF9FBFD),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.brandBlue : const Color(0xFFD9E3EE),
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x14003F70),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.button(
                  fontSize: 12.2,
                  color: selected ? AppColors.brandBlue : AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFEAF5FF)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: AppTypography.label(
                    fontSize: 10.5,
                    color: selected ? AppColors.brandBlue : AppColors.mutedText,
                    fontWeight: FontWeight.w800,
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

class _EmptyAlertsCard extends StatelessWidget {
  const _EmptyAlertsCard({
    required this.isScanning,
    required this.activeFilter,
    required this.onScan,
  });

  final bool isScanning;
  final AlertSignalFilter activeFilter;
  final Future<void> Function() onScan;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEAFBFD),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            activeFilter == AlertSignalFilter.all
                ? 'No active alerts right now'
                : 'No ${activeFilter.label.toLowerCase()} alerts right now',
            textAlign: TextAlign.center,
            style: AppTypography.section(
              fontSize: 20,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Run a fresh scan to check profile data, reviews, posts, insights, keywords, and citations.',
            textAlign: TextAlign.center,
            style: AppTypography.body(
              fontSize: 13.2,
              color: AppColors.mutedText,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: isScanning ? null : onScan,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: isScanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.radar_rounded, size: 18),
            label: Text(
              isScanning ? 'Scanning business signals...' : 'Run alert scan',
              style: AppTypography.button(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AlertMenuAction { markRead, resolve }

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.isBusy,
    required this.isResolving,
    required this.isMarkingRead,
    required this.isOpening,
    required this.onOpen,
    required this.onRead,
    required this.onResolve,
  });

  final BusinessAlert alert;
  final bool isBusy;
  final bool isResolving;
  final bool isMarkingRead;
  final bool isOpening;
  final Future<void> Function() onOpen;
  final Future<void> Function() onRead;
  final Future<void> Function() onResolve;

  @override
  Widget build(BuildContext context) {
    final typePalette = _typePaletteFor(alert.type);
    final severityPalette = _severityPaletteFor(alert.severity);
    final canOpenMenu = !alert.read || !alert.resolved;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: severityPalette.borderColor),
        boxShadow: [
          BoxShadow(
            color: severityPalette.shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _BadgePill(
                        label: severityPalette.label.toUpperCase(),
                        foreground: severityPalette.foregroundColor,
                        background: severityPalette.backgroundColor,
                        borderColor: Colors.transparent,
                      ),
                      _BadgePill(
                        label: alert.effectiveImpactLabel,
                        foreground: typePalette.darkAccentColor,
                        background: typePalette.softBackground,
                        borderColor: Colors.transparent,
                        showDot: true,
                      ),
                      if (alert.resolved)
                        const _BadgePill(
                          label: 'Resolved',
                          foreground: Color(0xFF1F8E63),
                          background: Color(0xFFEFFBF4),
                          borderColor: Colors.transparent,
                        ),
                    ],
                  ),
                ),
                if (canOpenMenu)
                  PopupMenuButton<_AlertMenuAction>(
                    enabled: !isBusy,
                    padding: EdgeInsets.zero,
                    color: Colors.white,
                    elevation: 8,
                    position: PopupMenuPosition.under,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: isBusy
                          ? AppColors.mutedText.withValues(alpha: 0.4)
                          : AppColors.mutedText,
                    ),
                    onSelected: (action) {
                      if (action == _AlertMenuAction.markRead) {
                        onRead();
                        return;
                      }
                      onResolve();
                    },
                    itemBuilder: (context) => [
                      if (!alert.read)
                        PopupMenuItem<_AlertMenuAction>(
                          value: _AlertMenuAction.markRead,
                          child: Row(
                            children: [
                              if (isMarkingRead)
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: typePalette.accentColor,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.mark_email_read_outlined,
                                  size: 18,
                                  color: typePalette.accentColor,
                                ),
                              const SizedBox(width: 10),
                              Text(
                                'Mark as read',
                                style: AppTypography.button(
                                  fontSize: 13,
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!alert.resolved)
                        PopupMenuItem<_AlertMenuAction>(
                          value: _AlertMenuAction.resolve,
                          child: Row(
                            children: [
                              if (isResolving)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF1B8A57),
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 18,
                                  color: Color(0xFF1B8A57),
                                ),
                              const SizedBox(width: 10),
                              Text(
                                'Resolve alert',
                                style: AppTypography.button(
                                  fontSize: 13,
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  )
                else
                  const SizedBox(width: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert.title,
              style: AppTypography.card(
                fontSize: 17,
                color: AppColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              alert.description,
              style: AppTypography.body(
                fontSize: 13.2,
                color: AppColors.text.withValues(alpha: 0.68),
                fontWeight: FontWeight.w500,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _InlineMeta(
                  icon: Icons.schedule_rounded,
                  label: alert.timeLabel.isEmpty ? 'Unknown' : alert.timeLabel,
                ),
                _InlineMeta(
                  icon: Icons.flag_outlined,
                  label: 'Priority ${alert.effectivePriorityScore}',
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: alert.resolved || isBusy ? null : onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                iconAlignment: IconAlignment.end,
                icon: isOpening
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  alert.effectiveActionLabel,
                  style: AppTypography.button(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.activeFilter,
    required this.statsByType,
    required this.scrollSignal,
    required this.onSelect,
  });

  final AlertSignalFilter activeFilter;
  final AlertStatsByType statsByType;
  final ValueListenable<double> scrollSignal;
  final void Function(AlertSignalFilter filter) onSelect;

  @override
  Widget build(BuildContext context) {
    final total = statsByType.all <= 0 ? 1 : statsByType.all;

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ALERT HEALTH',
                      style: AppTypography.label(
                        fontSize: 11,
                        color: const Color(0xFF23B36B),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Breakdown by signal',
                      style: AppTypography.section(
                        fontSize: 18,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF22BA72),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: AlertSignalType.values
                .asMap()
                .entries
                .map((entry) {
                  final index = entry.key;
                  final type = entry.value;
                  final palette = _typePaletteFor(type);
                  final count = statsByType.countFor(type);
                  final progress = count <= 0 ? 0.0 : count / total;
                  final filter = _filterForType(type);

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: type == AlertSignalType.values.last ? 0 : 12,
                    ),
                    child: _HealthBreakdownTile(
                      label: type.label,
                      count: count,
                      icon: palette.icon,
                      iconColor: palette.accentColor,
                      gradientColors: palette.accentGradient,
                      progress: progress.clamp(0, 1),
                      isSelected: activeFilter == filter,
                      scrollSignal: scrollSignal,
                      phase: index * 0.72,
                      onTap: () => onSelect(filter),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _HealthBreakdownTile extends StatelessWidget {
  const _HealthBreakdownTile({
    required this.label,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.gradientColors,
    required this.progress,
    required this.isSelected,
    required this.scrollSignal,
    required this.phase,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color iconColor;
  final List<Color> gradientColors;
  final double progress;
  final bool isSelected;
  final ValueListenable<double> scrollSignal;
  final double phase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFAED8F0)
                  : const Color(0xFFE2EAF3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: iconColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.button(
                        fontSize: 13,
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '$count',
                    style: AppTypography.button(
                      fontSize: 13,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<double>(
                valueListenable: scrollSignal,
                builder: (context, signal, _) {
                  return _AnimatedHealthTrack(
                    progress: progress,
                    gradientColors: gradientColors,
                    signal: signal,
                    phase: phase,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedHealthTrack extends StatelessWidget {
  const _AnimatedHealthTrack({
    required this.progress,
    required this.gradientColors,
    required this.signal,
    required this.phase,
  });

  final double progress;
  final List<Color> gradientColors;
  final double signal;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final safeProgress = progress.clamp(0.0, 1.0);
        final trackWidth = constraints.maxWidth;
        final fillWidth = trackWidth * safeProgress;
        final highlightWidth = math.min(42.0, fillWidth);
        final highlightTravel = math.max(fillWidth - highlightWidth, 0);
        final highlightFactor = (math.sin((signal * 1.25) + phase) + 1) / 2;
        final highlightLeft = highlightTravel * highlightFactor;

        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 7,
            child: Stack(
              children: [
                Container(color: const Color(0xFFEAF0F7)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  width: fillWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                if (fillWidth > 0.5)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    left: highlightLeft,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: highlightWidth,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: 0.58),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PriorityPlaybookCard extends StatelessWidget {
  const _PriorityPlaybookCard({
    required this.urgentCount,
    required this.openCount,
  });

  final int urgentCount;
  final int openCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2C8B8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flash_on_rounded,
                size: 18,
                color: Color(0xFFE44C1B),
              ),
              const SizedBox(width: 8),
              Text(
                'FIX ORDER',
                style: AppTypography.label(
                  fontSize: 11,
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'What to handle first',
            style: AppTypography.section(
              fontSize: 18,
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            urgentCount == 0
                ? 'No urgent alert is active right now. Keep the scan cadence steady so sudden drops do not sit unseen.'
                : 'Start with $urgentCount urgent alert${urgentCount == 1 ? '' : 's'} that can hurt trust or conversion.',
            style: AppTypography.body(
              fontSize: 13.4,
              color: AppColors.text.withValues(alpha: 0.84),
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            openCount == 0
                ? 'Everything is clear in this view.'
                : 'Then fix freshness, keyword tracking, and citation consistency so rankings have stronger signals.',
            style: AppTypography.body(
              fontSize: 13.4,
              color: AppColors.text.withValues(alpha: 0.84),
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    required this.alerts,
    required this.onSelect,
    required this.onSeeAll,
  });

  final List<BusinessAlert> alerts;
  final Future<void> Function(BusinessAlert alert) onSelect;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Activity',
                    style: AppTypography.card(
                      fontSize: 18,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF3468E8),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text(
                    'See all',
                    style: AppTypography.button(
                      fontSize: 12.6,
                      color: const Color(0xFF3468E8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE7EDF4)),
          if (alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
              child: Text(
                'No alert activity yet.',
                style: AppTypography.body(
                  fontSize: 13.2,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Column(
              children: alerts
                  .map(
                    (alert) => _RecentAlertTile(
                      alert: alert,
                      onTap: () => onSelect(alert),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _RecentAlertTile extends StatelessWidget {
  const _RecentAlertTile({required this.alert, required this.onTap});

  final BusinessAlert alert;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _typePaletteFor(alert.type);
    final showDot = !alert.read || !alert.resolved;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.softBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(palette.icon, size: 20, color: palette.accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: AppTypography.card(
                        fontSize: 16,
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.timeLabel.isEmpty ? 'Unknown' : alert.timeLabel,
                      style: AppTypography.body(
                        fontSize: 12.6,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (showDot)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 7),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A86FF),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
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
    final accentColor = isError
        ? const Color(0xFFCE4D67)
        : const Color(0xFF1B986E);
    final backgroundColor = isError
        ? const Color(0xFFFFF2F5)
        : const Color(0xFFEFFBF4);
    final borderColor = isError
        ? const Color(0xFFF1CDD7)
        : const Color(0xFFCFEEDB);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            color: accentColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(
                fontSize: 12.6,
                color: accentColor,
                fontWeight: FontWeight.w600,
                height: 1.42,
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 18, color: accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({
    required this.label,
    required this.foreground,
    required this.background,
    required this.borderColor,
    this.showDot = false,
  });

  final String label;
  final Color foreground;
  final Color background;
  final Color borderColor;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTypography.label(
              fontSize: 10.4,
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.mutedText),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.label(
            fontSize: 11.2,
            color: AppColors.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E8F1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A003F70),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

AlertSignalFilter _filterForType(AlertSignalType type) {
  switch (type) {
    case AlertSignalType.seo:
      return AlertSignalFilter.seo;
    case AlertSignalType.review:
      return AlertSignalFilter.review;
    case AlertSignalType.post:
      return AlertSignalFilter.post;
    case AlertSignalType.competitor:
      return AlertSignalFilter.competitor;
    case AlertSignalType.compliance:
      return AlertSignalFilter.compliance;
  }
}

_AlertTypePalette _typePaletteFor(AlertSignalType type) {
  switch (type) {
    case AlertSignalType.seo:
      return const _AlertTypePalette(
        icon: Icons.trending_down_rounded,
        accentColor: Color(0xFF37B4C8),
        darkAccentColor: Color(0xFF1F84A5),
        softBackground: Color(0xFFEAFBFD),
        accentGradient: [Color(0xFF2DB4C7), Color(0xFF58C9D3)],
      );
    case AlertSignalType.review:
      return const _AlertTypePalette(
        icon: Icons.star_outline_rounded,
        accentColor: Color(0xFFF4A42F),
        darkAccentColor: Color(0xFFBE7D16),
        softBackground: Color(0xFFFFF7E8),
        accentGradient: [Color(0xFFF2A32A), Color(0xFFF7C059)],
      );
    case AlertSignalType.post:
      return const _AlertTypePalette(
        icon: Icons.receipt_long_outlined,
        accentColor: Color(0xFFF24848),
        darkAccentColor: Color(0xFFD73E3E),
        softBackground: Color(0xFFFFF1F1),
        accentGradient: [Color(0xFFF24848), Color(0xFFF56D6D)],
      );
    case AlertSignalType.competitor:
      return const _AlertTypePalette(
        icon: Icons.groups_2_outlined,
        accentColor: Color(0xFF4777FF),
        darkAccentColor: Color(0xFF345FDA),
        softBackground: Color(0xFFF0F4FF),
        accentGradient: [Color(0xFF4777FF), Color(0xFF6B96FF)],
      );
    case AlertSignalType.compliance:
      return const _AlertTypePalette(
        icon: Icons.shield_outlined,
        accentColor: Color(0xFF6257E8),
        darkAccentColor: Color(0xFF5348D6),
        softBackground: Color(0xFFF1EEFF),
        accentGradient: [Color(0xFF6257E8), Color(0xFF857DF3)],
      );
  }
}

_AlertSeverityPalette _severityPaletteFor(AlertSeverity severity) {
  switch (severity) {
    case AlertSeverity.high:
      return const _AlertSeverityPalette(
        label: 'Urgent',
        foregroundColor: Color(0xFFEC4F4F),
        backgroundColor: Color(0xFFFFF2F2),
        borderColor: Color(0xFFF7C9C9),
        shadowColor: Color(0x10EF6464),
      );
    case AlertSeverity.medium:
      return const _AlertSeverityPalette(
        label: 'Important',
        foregroundColor: Color(0xFFF0A128),
        backgroundColor: Color(0xFFFFF7E8),
        borderColor: Color(0xFFF2D5A3),
        shadowColor: Color(0x10F0C264),
      );
    case AlertSeverity.low:
      return const _AlertSeverityPalette(
        label: 'Watch',
        foregroundColor: Color(0xFF23B36B),
        backgroundColor: Color(0xFFEFFBF4),
        borderColor: Color(0xFFCBECD9),
        shadowColor: Color(0x1029B883),
      );
  }
}

class _AlertTypePalette {
  const _AlertTypePalette({
    required this.icon,
    required this.accentColor,
    required this.darkAccentColor,
    required this.softBackground,
    required this.accentGradient,
  });

  final IconData icon;
  final Color accentColor;
  final Color darkAccentColor;
  final Color softBackground;
  final List<Color> accentGradient;
}

class _AlertSeverityPalette {
  const _AlertSeverityPalette({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.shadowColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
}
