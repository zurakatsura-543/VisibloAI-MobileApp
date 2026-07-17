import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../widgets/auth_navigation_shell.dart';
import '../widgets/visiblo_brand_wordmark.dart';
import '../models/gbp_post.dart';
import 'gbp_post_create_flow_view.dart';

enum _EventFilter { all, scheduled, live }

class GbpEventsView extends StatelessWidget {
  const GbpEventsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthNavigationShell(
      currentTab: AuthTab.home,
      backgroundColor: const Color(0xFFF6F8FC),
      child: _GbpEventsContent(controller: Get.find<OnboardingController>()),
    );
  }
}

class _GbpEventsContent extends StatefulWidget {
  const _GbpEventsContent({required this.controller});

  final OnboardingController controller;

  @override
  State<_GbpEventsContent> createState() => _GbpEventsContentState();
}

class _GbpEventsContentState extends State<_GbpEventsContent> {
  _EventFilter _selectedFilter = _EventFilter.all;

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Get.back();
      return;
    }
    Get.offNamed(AppRoutes.dashboard);
  }

  void _showEventsSnack(String title, String message) {
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = widget.controller.currentUser.value;
      if (user == null) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      final events = widget.controller.liveGbpPosts
          .where((p) => p.meta == 'EVENT')
          .toList();
      final liveCount = events.where((p) => p.status == GbpPostStatus.live).length;
      final scheduledCount = events.where((p) => p.status == GbpPostStatus.scheduled).length;
      final totalCount = events.length;

      return Stack(
        children: [
          Column(
            children: [
              _EventsTopBar(
                onBack: _handleBack,
                onNotificationsTap: () {
                  _showEventsSnack(
                    'Notifications',
                    'Event reminders and campaign alerts can appear here.',
                  );
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 150),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: Column(
                                children: const [
                                  Text(
                                    'Manage your promotional events and local offers for your business.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13.6,
                                      height: 1.46,
                                      color: Color(0xFF61708A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      Text(
                                        'Powered by',
                                        style: TextStyle(
                                          fontSize: 12.8,
                                          color: Color(0xFF7F8BA0),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      VisibloBrandWordmark(
                                        iconSize: 22,
                                        fontSize: 16.5,
                                        showIcon: false,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _EventsToolbarCard(
                            selectedFilter: _selectedFilter,
                            onFilterChanged: (filter) {
                              setState(() => _selectedFilter = filter);
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 104,
                                  child: _EventsMetricCard(
                                    title: 'LIVE EVENTS',
                                    value: '$liveCount',
                                    icon: Icons.check_circle_outline_rounded,
                                    iconColor: AppColors.primary,
                                    iconBackground: Color(0xFFE8FBFB),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 104,
                                  child: _EventsMetricCard(
                                    title: 'SCHEDULED',
                                    value: '$scheduledCount',
                                    icon: Icons.schedule_rounded,
                                    iconColor: AppColors.primaryDark,
                                    iconBackground: Color(0xFFEAF4FF),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 104,
                                  child: _EventsMetricCard(
                                    title: 'TOTAL CREATED',
                                    value: '$totalCount',
                                    icon: Icons.calendar_today_outlined,
                                    iconColor: AppColors.primary,
                                    iconBackground: Color(0xFFE8FBFB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _EventsEmptyState(
                            filter: _selectedFilter,
                            onPrimaryTap: () async {
                              final template = GbpPost.createEmpty();
                              final businessName = widget.controller.currentUser.value?.businessName ?? 'Business';
                              
                              await Get.to<GbpPost>(
                                () => GbpPostCreateMethodView(
                                  templatePost: template,
                                  businessName: businessName,
                                  postType: 'event',
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: Center(
              child: _EventsPrimaryButton(
                label: 'Create New Event',
                icon: Icons.add_rounded,
                secondary: true,
                onTap: () async {
                  final template = GbpPost.createEmpty();
                  final businessName = widget.controller.currentUser.value?.businessName ?? 'Business';
                  
                  await Get.to<GbpPost>(
                    () => GbpPostCreateMethodView(
                      templatePost: template,
                      businessName: businessName,
                      postType: 'event',
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _EventsTopBar extends StatelessWidget {
  const _EventsTopBar({required this.onBack, required this.onNotificationsTap});

  final VoidCallback onBack;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDCE3EE))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: SizedBox(
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _HeaderBackButton(onTap: onBack),
              ),
              Text(
                'GBP Events',
                style: AppTypography.card(
                  fontSize: 18,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: _BellIconButton(onTap: onNotificationsTap),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventsToolbarCard extends StatelessWidget {
  const _EventsToolbarCard({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final _EventFilter selectedFilter;
  final ValueChanged<_EventFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _EventsFilterChip(
            label: 'All Events',
            selected: selectedFilter == _EventFilter.all,
            onTap: () => onFilterChanged(_EventFilter.all),
          ),
          _EventsFilterChip(
            label: 'Scheduled',
            selected: selectedFilter == _EventFilter.scheduled,
            onTap: () => onFilterChanged(_EventFilter.scheduled),
          ),
          _EventsFilterChip(
            label: 'LIVE',
            selected: selectedFilter == _EventFilter.live,
            onTap: () => onFilterChanged(_EventFilter.live),
          ),
        ],
      ),
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FB),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE1E7F0)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}

class _BellIconButton extends StatelessWidget {
  const _BellIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE1E7F0)),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 17,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _EventsFilterChip extends StatelessWidget {
  const _EventsFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                  )
                : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.transparent : const Color(0xFFDDE5EF),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.label(
              fontSize: 12.5,
              color: selected ? AppColors.white : AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _EventsMetricCard extends StatelessWidget {
  const _EventsMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A102F5A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(9, 10, 9, 10),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 16, color: iconColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          style: AppTypography.label(
                            fontSize: 9.6,
                            height: 1.15,
                            color: const Color(0xFF93A0B3),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: AppTypography.card(
                            fontSize: 22,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventsEmptyState extends StatelessWidget {
  const _EventsEmptyState({required this.filter, required this.onPrimaryTap});

  final _EventFilter filter;
  final VoidCallback onPrimaryTap;

  @override
  Widget build(BuildContext context) {
    final title = switch (filter) {
      _EventFilter.all => 'No events created yet',
      _EventFilter.scheduled => 'No scheduled events yet',
      _EventFilter.live => 'No live events right now',
    };

    final description = switch (filter) {
      _EventFilter.all =>
        'Start creating promotional events to boost your local visibility and engage with customers directly.',
      _EventFilter.scheduled =>
        'Create an event and choose a future launch time to keep your business updates planned ahead.',
      _EventFilter.live =>
        'When an event is live, it will appear here so you can track and manage it quickly.',
    };

    return CustomPaint(
      painter: const _DashedRoundedBorderPainter(
        color: Color(0xFFDCE5F0),
        radius: 26,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 42),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F7FC),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.calendar_month_outlined,
                    size: 34,
                    color: AppColors.primary,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.add_circle,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.card(
                fontSize: 24,
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: AppTypography.body(
                  fontSize: 13.3,
                  color: AppColors.mutedText,
                  height: 1.48,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 22),
            _EventsPrimaryButton(
              label: filter == _EventFilter.all
                  ? 'Launch Your First Event'
                  : 'Create New Event',
              icon: Icons.auto_awesome_outlined,
              secondary: true,
              onTap: onPrimaryTap,
              compact: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _EventsPrimaryButton extends StatelessWidget {
  const _EventsPrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.compact = true,
    this.secondary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 30 : 20,
            vertical: compact ? 17 : 14,
          ),
          decoration: BoxDecoration(
            gradient: secondary
                ? null
                : const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
            color: secondary ? AppColors.white : null,
            borderRadius: BorderRadius.circular(18),
            border: secondary
                ? Border.all(color: AppColors.primary, width: 1.6)
                : null,
            boxShadow: const [
              BoxShadow(
                color: Color(0x2239B4BD),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: compact ? 18 : 18,
                color: secondary ? AppColors.primaryDark : AppColors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.label(
                  fontSize: compact ? 15.5 : 13.4,
                  color: secondary ? AppColors.primaryDark : AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dashWidth = 7.0;
      const dashSpace = 6.0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        dashedPath.addPath(
          metric.extractPath(distance, nextDistance.clamp(0, metric.length)),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
