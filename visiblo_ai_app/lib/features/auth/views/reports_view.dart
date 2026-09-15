import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_responsive.dart';
import '../../../app/theme/app_typography.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/report_models.dart';
import '../widgets/auth_navigation_shell.dart';
import '../widgets/trend_chart.dart' hide AnimatedTrendChart;

class ReportsView extends GetView<OnboardingController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthNavigationShell(
      currentTab: AuthTab.reports,
      backgroundColor: Color(0xFFF4F7FC),
      child: _ReportsContent(),
    );
  }
}

class _ReportsContent extends StatefulWidget {
  const _ReportsContent();

  @override
  State<_ReportsContent> createState() => _ReportsContentState();
}

class _ReportsContentState extends State<_ReportsContent> {
  final OnboardingController controller = Get.find<OnboardingController>();
  final GlobalKey _discoverySectionKey = GlobalKey();
  final GlobalKey _trendsSectionKey = GlobalKey();

  late DateTimeRange _selectedRange;
  LocationInsightsResponse? _reportInsights;
  LocationInsightsResponse? _previousInsights;
  List<SearchKeyword> _reportKeywords = const <SearchKeyword>[];
  bool _isLoadingSnapshot = false;
  int _reportsRequestToken = 0;
  TrendWindow _trendWindow = TrendWindow.month;
  bool _showAllTopQueries = false;
  int _discoveryAnimationCycle = 1;
  int _trendAnimationCycle = 1;
  bool _wasDiscoveryVisible = false;
  bool _wasTrendsVisible = false;
  ScrollDirection _lastScrollDirection = ScrollDirection.idle;

  @override
  void initState() {
    super.initState();
    // Default to last 30 days
    final now = DateTime.now();
    _selectedRange = DateTimeRange(
      start: now.subtract(const Duration(days: 29)),
      end: now,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReportsSnapshot();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.currentUser.value;
      if (user == null) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      if (_isLoadingSnapshot && _reportInsights == null) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      final trendConfig = _buildTrendConfig();
      final activityCards = _buildActivityCards();
      final topQueries = _buildTopQueries();

      return NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            context.responsiveHorizontalPadding,
            10,
            context.responsiveHorizontalPadding,
            18,
          ),
          child: ResponsiveCenter(
            useHorizontalPadding: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  _buildHeader(context),
                  const SizedBox(height: 10),
                  _buildActivitySection(activityCards),
                  const SizedBox(height: 10),
                  _buildTrendsSection(trendConfig),
                  const SizedBox(height: 10),
                  _buildDiscoverySection(),
                  const SizedBox(height: 10),
                  _buildTopQueriesSection(topQueries),
                ],
              ),
            ),
          ),
        );
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    final discoveryVisible = _isSectionVisible(_discoverySectionKey);
    final trendsVisible = _isSectionVisible(_trendsSectionKey);

    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle) {
        _lastScrollDirection = ScrollDirection.idle;
        _wasDiscoveryVisible = discoveryVisible;
        _wasTrendsVisible = trendsVisible;
        return false;
      }

      final directionChanged = notification.direction != _lastScrollDirection;
      final discoveryEnteredVisibleArea =
          discoveryVisible && !_wasDiscoveryVisible;
      final trendsEnteredVisibleArea = trendsVisible && !_wasTrendsVisible;

      if (directionChanged ||
          discoveryEnteredVisibleArea ||
          trendsEnteredVisibleArea) {
        setState(() {
          if (discoveryVisible &&
              (directionChanged || discoveryEnteredVisibleArea)) {
            _discoveryAnimationCycle++;
          }
          if (trendsVisible && (directionChanged || trendsEnteredVisibleArea)) {
            _trendAnimationCycle++;
          }
        });
      }

      _lastScrollDirection = notification.direction;
      _wasDiscoveryVisible = discoveryVisible;
      _wasTrendsVisible = trendsVisible;
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final discoveryEnteredVisibleArea =
          discoveryVisible && !_wasDiscoveryVisible;
      final trendsEnteredVisibleArea = trendsVisible && !_wasTrendsVisible;

      if (discoveryEnteredVisibleArea || trendsEnteredVisibleArea) {
        setState(() {
          if (discoveryEnteredVisibleArea) {
            _discoveryAnimationCycle++;
          }
          if (trendsEnteredVisibleArea) {
            _trendAnimationCycle++;
          }
        });
      }

      _wasDiscoveryVisible = discoveryVisible;
      _wasTrendsVisible = trendsVisible;
    }

    return false;
  }

  bool _isSectionVisible(GlobalKey sectionKey) {
    final sectionContext = sectionKey.currentContext;
    if (sectionContext == null) {
      return false;
    }

    final renderBox = sectionContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return false;
    }

    final top = renderBox.localToGlobal(Offset.zero).dy;
    final bottom = top + renderBox.size.height;
    final screenHeight = MediaQuery.of(context).size.height;
    return top < screenHeight - 60 && bottom > 80;
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _handleBackTap,
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 24,
                  color: AppColors.brandBlue,
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              'Reports',
              style: AppTypography.card(
                fontSize: 20,
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadReportsSnapshot() async {
    final requestToken = ++_reportsRequestToken;
    setState(() => _isLoadingSnapshot = true);

    try {
      final currentRange = _selectedRange;
      final inclusiveDays =
          currentRange.end.difference(currentRange.start).inDays + 1;
      final previousEnd = currentRange.start.subtract(const Duration(days: 1));
      final previousStart = previousEnd.subtract(
        Duration(days: inclusiveDays - 1),
      );
      final previousRange = DateTimeRange(
        start: previousStart,
        end: previousEnd,
      );

      final results = await Future.wait<Object?>([
        controller.loadInsightsForRange(currentRange),
        controller.loadInsightsForRange(previousRange),
        controller.loadReportKeywords(),
      ]);

      if (!mounted || requestToken != _reportsRequestToken) {
        return;
      }

      setState(() {
        _reportInsights = results[0] as LocationInsightsResponse?;
        _previousInsights = results[1] as LocationInsightsResponse?;
        _reportKeywords = (results[2] as List<dynamic>)
            .whereType<SearchKeyword>()
            .toList(growable: false);
      });
    } finally {
      if (mounted && requestToken == _reportsRequestToken) {
        setState(() => _isLoadingSnapshot = false);
      }
    }
  }

  Widget _buildActivitySection(List<_ActivityCardData> activityCards) {
    return _ReportSectionCard(
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
                      'Customer Activity',
                      style: AppTypography.card(fontSize: 18),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Your performance on Google',
                      style: AppTypography.label(
                        color: const Color(0xFF7E8798),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 380;

              return GridView.builder(
                shrinkWrap: true,
                itemCount: activityCards.length,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: isCompact ? 8 : 7,
                  crossAxisSpacing: isCompact ? 8 : 7,
                  mainAxisExtent: isCompact ? 74 : 78,
                ),
                itemBuilder: (context, index) {
                  final card = activityCards[index];
                  return _ActivityMetricTile(card: card);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverySection() {
    final insights = _reportInsights;
    final breakdown = insights?.platformBreakdown;

    final sm = breakdown?.searchMobile ?? 0;
    final sd = breakdown?.searchDesktop ?? 0;
    final mm = breakdown?.mapsMobile ?? 0;
    final md = breakdown?.mapsDesktop ?? 0;
    final total = sm + sd + mm + md;

    final pSm = total > 0 ? (sm / total * 100).round() : 0;
    final pSd = total > 0 ? (sd / total * 100).round() : 0;
    final pMm = total > 0 ? (mm / total * 100).round() : 0;
    final pMd = total > 0 ? (md / total * 100).round() : 0;

    final items = [
      _DiscoveryLegendData(
        value: '$sm ($pSm%)',
        label: 'Google Search (Mobile)',
        color: const Color(0xFF0A0A84),
      ),
      _DiscoveryLegendData(
        value: '$sd ($pSd%)',
        label: 'Google Search (Desktop)',
        color: const Color(0xFF33B9E7),
      ),
      _DiscoveryLegendData(
        value: '$mm ($pMm%)',
        label: 'Google Maps (Mobile)',
        color: const Color(0xFF8CE0F0),
      ),
      _DiscoveryLegendData(
        value: '$md ($pMd%)',
        label: 'Google Maps (Desktop)',
        color: const Color(0xFFD9EDF5),
      ),
    ];

    final segments = <({double value, Color color})>[
      (value: total > 0 ? sm / total : 0, color: const Color(0xFF0A0A84)),
      (value: total > 0 ? sd / total : 0, color: const Color(0xFF33B9E7)),
      (value: total > 0 ? mm / total : 0, color: const Color(0xFF8CE0F0)),
      (value: total > 0 ? md / total : 0, color: const Color(0xFFD9EDF5)),
    ];

    return Container(
      key: _discoverySectionKey,
      child: _ReportSectionCard(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTight = constraints.maxWidth < 345;
            final donutSize = isTight ? 108.0 : 132.0;
            final chartLegendGap = isTight ? 12.0 : 20.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discovery Breakdown',
                  style: AppTypography.card(
                    fontSize: isTight ? 17 : 18,
                    color: const Color(0xFF1E2A3B),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Where customers are finding your business',
                  style: AppTypography.label(
                    fontSize: isTight ? 11.8 : 12.3,
                    color: const Color(0xFF6D7789),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: donutSize + (isTight ? 8 : 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: isTight ? 0 : 2),
                          child: _AnimatedDiscoveryDonutChart(
                            cycle: _discoveryAnimationCycle,
                            segments: segments,
                            size: donutSize,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: chartLegendGap),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: isTight ? 2 : 4,
                            right: isTight ? 4 : 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: items
                                .map(
                                  (item) => _DiscoveryLegendItem(
                                    data: item,
                                    compact: isTight,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTrendsSection(TrendConfig trendConfig) {
    return Container(
      key: _trendsSectionKey,
      child: _ReportSectionCard(
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
                        'Activity Trends',
                        style: AppTypography.card(fontSize: 18),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              trendConfig.subtitle,
                              style: AppTypography.label(
                                color: const Color(0xFF7E8798),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_drop_up_rounded,
                            size: 16,
                            color: Color(0xFF2BA54A),
                          ),
                          const Text(
                            '4',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF2BA54A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 16,
                            color: Color(0xFF2BA54A),
                          ),
                          const Text(
                            '4',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF2BA54A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _ActionPillButton(
                  label: trendConfig.buttonLabel,
                  onTap: _pickTrendWindow,
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedTrendChart(
              config: trendConfig,
              cycle: _trendAnimationCycle,
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < trendConfig.series.length; i++) ...[
                    _TrendLegendChip(series: trendConfig.series[i]),
                    if (i != trendConfig.series.length - 1)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopQueriesSection(List<_TopQueryData> topQueries) {
    const initialVisibleQueryCount = 5;
    final visibleCount = _showAllTopQueries
        ? topQueries.length
        : math.min(initialVisibleQueryCount, topQueries.length);
    final hiddenCount = math.max(0, topQueries.length - visibleCount);
    final visibleQueries = topQueries.take(visibleCount).toList();

    return _ReportSectionCard(
      topAccent: const LinearGradient(
        colors: [Color(0xFF30C2F3), Color(0xFF196AF0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Search Queries', style: AppTypography.card(fontSize: 18)),
          const SizedBox(height: 1),
          Text(
            'Terms people used to find your profile',
            style: AppTypography.label(color: const Color(0xFF7E8798)),
          ),
          const SizedBox(height: 8),
          ...List<Widget>.generate(visibleQueries.length, (index) {
            final item = visibleQueries[index];
            return Column(
              children: [
                _TopQueryTile(
                  rank: index + 1,
                  query: item.query,
                  searches: item.searches,
                  onTap: () => Get.toNamed(AppRoutes.audit),
                ),
                if (index != visibleQueries.length - 1)
                  const Divider(height: 1, color: Color(0xFFF0F3F8)),
              ],
            );
          }),
          if (hiddenCount > 0 || _showAllTopQueries) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showAllTopQueries = !_showAllTopQueries;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  textStyle: AppTypography.label(
                    fontSize: 13,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(
                  _showAllTopQueries
                      ? 'Show less'
                      : 'View more ($hiddenCount more)',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_ActivityCardData> _buildActivityCards() {
    final insights = _reportInsights;
    final previous = _previousInsights;
    final views =
        (insights?.totals.searchImpressions ?? 0) +
        (insights?.totals.mapsImpressions ?? 0);
    final calls = insights?.totals.callClicks ?? 0;
    final directions = insights?.totals.directionRequests ?? 0;
    final websiteVisits = insights?.totals.websiteClicks ?? 0;
    final previousViews =
        (previous?.totals.searchImpressions ?? 0) +
        (previous?.totals.mapsImpressions ?? 0);
    final previousCalls = previous?.totals.callClicks ?? 0;
    final previousDirections = previous?.totals.directionRequests ?? 0;
    final previousWebsiteVisits = previous?.totals.websiteClicks ?? 0;

    return [
      _ActivityCardData(
        title: 'Google Views',
        value: _formatNumber(views),
        delta: _formatDeltaText(views, previousViews),
        deltaColor: _deltaColor(views, previousViews),
        iconBackground: const Color(0xFFFFF3F3),
        icon: SvgPicture.asset(
          'assets/icons/google_logo.svg',
          width: 18,
          height: 18,
        ),
      ),
      _ActivityCardData(
        title: 'Customer Calls',
        value: _formatNumber(calls),
        delta: _formatDeltaText(calls, previousCalls),
        deltaColor: _deltaColor(calls, previousCalls),
        iconBackground: const Color(0xFFF1FBF5),
        icon: const Icon(
          Icons.call_rounded,
          size: 18,
          color: Color(0xFF2FB16F),
        ),
      ),
      _ActivityCardData(
        title: 'Direction requests',
        value: _formatNumber(directions),
        delta: _formatDeltaText(directions, previousDirections),
        deltaColor: _deltaColor(directions, previousDirections),
        iconBackground: const Color(0xFFF1F6FF),
        icon: const Icon(
          Icons.public_rounded,
          size: 18,
          color: AppColors.brandBlue,
        ),
      ),
      _ActivityCardData(
        title: 'Website Visits',
        value: _formatNumber(websiteVisits),
        delta: _formatDeltaText(websiteVisits, previousWebsiteVisits),
        deltaColor: _deltaColor(websiteVisits, previousWebsiteVisits),
        iconBackground: const Color(0xFFFFF8DE),
        icon: const Icon(
          Icons.star_rounded,
          size: 22,
          color: Color(0xFFF3B400),
        ),
      ),
    ];
  }

  TrendConfig _buildTrendConfig() {
    final insights = _reportInsights;
    final daily = insights?.daily ?? [];
    final fallbackConfig = _trendWindow.config;

    if (daily.isEmpty) {
      return TrendConfigFactory.emptyStateConfig(fallbackConfig);
    }

    final xLabels = <String>[];
    final viewsPoints = <double>[];
    final clicksPoints = <double>[];
    final callsPoints = <double>[];
    final dirPoints = <double>[];

    // Downsample for xLabels if there are too many points
    final step = (daily.length / 6).ceil();

    for (var i = 0; i < daily.length; i++) {
      final d = daily[i];
      if (i % step == 0 || i == daily.length - 1) {
        try {
          final dt = DateTime.parse(d.date);
          final monthStr = [
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
          ][dt.month - 1];
          xLabels.add('$monthStr ${dt.day}');
        } catch (_) {
          xLabels.add(d.date.substring(5)); // MM-DD fallback
        }
      }
      viewsPoints.add(d.searchImpressions.toDouble());
      clicksPoints.add(d.websiteClicks.toDouble());
      callsPoints.add(d.callClicks.toDouble());
      dirPoints.add(d.directionRequests.toDouble());
    }

    // Keep max 6 xLabels
    if (xLabels.length > 6) {
      final filtered = <String>[];
      final lblStep = (xLabels.length / 5).ceil();
      for (var i = 0; i < xLabels.length; i += lblStep) {
        filtered.add(xLabels[i]);
      }
      if (!filtered.contains(xLabels.last)) filtered.add(xLabels.last);
      xLabels.clear();
      xLabels.addAll(filtered);
    }

    final maxVal = [
      ...viewsPoints,
      ...clicksPoints,
      ...callsPoints,
      ...dirPoints,
    ].fold(0.0, (m, v) => math.max(m, v));

    final yLabels = <int>[
      maxVal.ceil(),
      (maxVal * 0.66).ceil(),
      (maxVal * 0.33).ceil(),
      0,
    ];

    return TrendConfig(
      buttonLabel: fallbackConfig.buttonLabel,
      subtitle: fallbackConfig.subtitle,
      periodUnitLabel: fallbackConfig.periodUnitLabel,
      chartCaption: fallbackConfig.chartCaption,
      xLabels: xLabels,
      yLabels: yLabels,
      series: [
        TrendSeries(
          label: 'Profile Views',
          color: const Color(0xFF7A4DFF),
          points: viewsPoints,
        ),
        TrendSeries(
          label: 'Website Clicks',
          color: const Color(0xFF2D4DDB),
          points: clicksPoints,
        ),
        TrendSeries(
          label: 'Calls',
          color: const Color(0xFF31B13B),
          points: callsPoints,
        ),
        TrendSeries(
          label: 'Directions',
          color: const Color(0xFFF1BE24),
          points: dirPoints,
        ),
      ],
    );
  }

  List<_TopQueryData> _buildTopQueries() {
    final keywords = _reportKeywords;
    if (keywords.isEmpty) {
      return [];
    }

    return keywords
        .map((k) => _TopQueryData(query: k.term, searches: k.totalImpressions))
        .toList();
  }

  void _handleBackTap() {
    if (Navigator.of(context).canPop()) {
      Get.back();
      return;
    }
    Get.offNamed(AppRoutes.dashboard);
  }

  Future<void> _pickTrendWindow() async {
    final selectedWindow = await showModalBottomSheet<TrendWindow>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7DEEA),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Choose trend range',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...TrendWindow.values.map((window) {
                    final config = window.config;
                    final isSelected = window == _trendWindow;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.of(context).pop(window),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEFF7FF)
                                : const Color(0xFFF8FAFD),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFB5D7FF)
                                  : const Color(0xFFE8EDF4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      config.buttonLabel,
                                      style: TextStyle(
                                        fontSize: 13.2,
                                        color: isSelected
                                            ? AppColors.brandBlue
                                            : AppColors.text,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      config.subtitle,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF7E8798),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                size: 18,
                                color: isSelected
                                    ? AppColors.brandBlue
                                    : const Color(0xFFB8C2D0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selectedWindow == null || !mounted) {
      return;
    }

    setState(() {
      _trendWindow = selectedWindow;
      _trendAnimationCycle++;

      final now = DateTime.now();
      switch (selectedWindow) {
        case TrendWindow.month:
          _selectedRange = DateTimeRange(
            start: now.subtract(const Duration(days: 29)),
            end: now,
          );
          break;
        case TrendWindow.quarter:
          _selectedRange = DateTimeRange(
            start: now.subtract(const Duration(days: 89)),
            end: now,
          );
          break;
        case TrendWindow.halfYear:
          _selectedRange = DateTimeRange(
            start: now.subtract(const Duration(days: 179)),
            end: now,
          );
          break;
        case TrendWindow.year:
          _selectedRange = DateTimeRange(
            start: now.subtract(const Duration(days: 364)),
            end: now,
          );
          break;
      }
    });

    _loadReportsSnapshot();
  }

  String _formatDeltaText(int current, int previous) {
    if (previous <= 0) {
      return current <= 0 ? '0%' : '+100%';
    }
    final diff = ((current - previous) / previous) * 100;
    final rounded = diff.round();
    if (rounded > 0) {
      return '+$rounded%';
    }
    return '$rounded%';
  }

  Color _deltaColor(int current, int previous) {
    if (current < previous) {
      return const Color(0xFFE24B4B);
    }
    return const Color(0xFF2BA54A);
  }
}

class _ReportSectionCard extends StatelessWidget {
  const _ReportSectionCard({required this.child, this.topAccent});

  final Widget child;
  final Gradient? topAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x090F2746),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (topAccent != null)
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: topAccent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              topAccent == null ? 12 : 10,
              12,
              12,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ActionPillButton extends StatelessWidget {
  const _ActionPillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFAAC6F3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.2,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppColors.brandBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityMetricTile extends StatelessWidget {
  const _ActivityMetricTile({required this.card});

  final _ActivityCardData card;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 170;
        final titleStyle = TextStyle(
          fontSize: isCompact ? 11.0 : 12.0,
          height: 1.0,
          color: AppColors.text.withValues(alpha: 0.78),
          fontWeight: FontWeight.w600,
        );

        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: radius,
            border: Border.all(color: const Color(0xFFF1F4F8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F2746),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Column(
              children: [
                Container(height: 3, color: AppColors.primary),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 10 : 12,
                      vertical: isCompact ? 8 : 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: isCompact ? 32 : 34,
                          height: isCompact ? 32 : 34,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: card.iconBackground,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: card.icon,
                            ),
                          ),
                        ),
                        SizedBox(width: isCompact ? 8 : 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: titleStyle,
                              ),
                              SizedBox(height: isCompact ? 3 : 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      card.value,
                                      style: TextStyle(
                                        fontSize: isCompact ? 17.4 : 18.6,
                                        height: 1,
                                        color: AppColors.brandBlue,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(width: isCompact ? 4 : 5),
                                    _ActivityMetricDelta(
                                      value: card.delta,
                                      color: card.deltaColor,
                                      compact: true,
                                    ),
                                  ],
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
          ),
        );
      },
    );
  }
}

class _ActivityMetricDelta extends StatelessWidget {
  const _ActivityMetricDelta({
    required this.value,
    required this.color,
    this.compact = false,
  });

  final String value;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isNegative = value.trim().startsWith('-');
    final isZero = value.trim() == '0%' || value.trim() == '+0%';
    final icon = isZero
        ? Icons.remove_rounded
        : isNegative
        ? Icons.south_east_rounded
        : Icons.north_east_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 11 : 12, color: color),
        SizedBox(width: compact ? 0.25 : 0.75),
        Text(
          value.startsWith('+') ? value.substring(1) : value,
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AnimatedDiscoveryDonutChart extends StatelessWidget {
  const _AnimatedDiscoveryDonutChart({
    required this.cycle,
    required this.segments,
    this.size = 116,
  });

  final int cycle;
  final List<({double value, Color color})> segments;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(cycle),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1600),
      curve: Curves.easeInOutCubic,
      builder: (context, progress, child) {
        final textScale = 0.92 + (progress * 0.08);

        // Find largest segment for center text
        double maxVal = 0;
        for (var s in segments) {
          if (s.value > maxVal) maxVal = s.value;
        }
        final maxPct = maxVal > 0 ? (maxVal * 100).round() : 0;
        final centerText = maxPct > 0 ? '$maxPct%' : '0%';

        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DiscoveryDonutPainter(
              progress: progress,
              segments: segments,
            ),
            child: Center(
              child: Transform.scale(
                scale: textScale,
                child: Opacity(
                  opacity: 0.45 + (progress * 0.55),
                  child: Text(
                    centerText,
                    style: TextStyle(
                      fontSize: size * 0.275,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DiscoveryLegendItem extends StatelessWidget {
  const _DiscoveryLegendItem({required this.data, this.compact = false});

  final _DiscoveryLegendData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 10 : 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 8 : 9,
            height: compact ? 8 : 9,
            margin: EdgeInsets.only(top: compact ? 4 : 5),
            decoration: BoxDecoration(
              color: data.color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: compact ? 8 : 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: TextStyle(
                  fontSize: compact ? 12.4 : 13.4,
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.label,
                style: TextStyle(
                  fontSize: compact ? 11.1 : 11.8,
                  color: const Color(0xFF7E8798),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AnimatedTrendChart extends StatelessWidget {
  const AnimatedTrendChart({
    super.key,
    required this.config,
    required this.cycle,
  });

  final TrendConfig config;
  final int cycle;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(cycle),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1800),
      curve: Curves.easeInOutCubic,
      builder: (context, progress, child) {
        return _TrendChart(config: config, progress: progress);
      },
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.config, this.progress = 1});

  final TrendConfig config;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 212,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 22,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: config.yLabels
                      .map(
                        (label) => Text(
                          '$label',
                          style: const TextStyle(
                            fontSize: 10.8,
                            color: Color(0xFF7E8798),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomPaint(
                  painter: _TrendChartPainter(
                    series: config.series,
                    progress: progress,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 30, right: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: config.xLabels
                .map(
                  (label) => Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10.8,
                      color: Color(0xFF6F7A8B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _TrendLegendChip extends StatelessWidget {
  const _TrendLegendChip({required this.series});

  final TrendSeries series;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: series.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: series.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 10,
            child: CustomPaint(
              painter: _TrendLegendMarkerPainter(series.color),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            series.label,
            style: const TextStyle(
              fontSize: 11.0,
              color: Color(0xFF657388),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendLegendMarkerPainter extends CustomPainter {
  const _TrendLegendMarkerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8;

    final start = Offset(0, size.height / 2);
    final end = Offset(size.width, size.height / 2);
    canvas.drawLine(start, end, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.55, size.height / 2),
      2.3,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendLegendMarkerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _TopQueryTile extends StatelessWidget {
  const _TopQueryTile({
    required this.rank,
    required this.query,
    required this.searches,
    required this.onTap,
  });

  final int rank;
  final String query;
  final int searches;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1EDFF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    fontSize: 9.9,
                    color: Color(0xFF6E6A93),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  query,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.8,
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$searches',
                    style: const TextStyle(
                      fontSize: 14.6,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 1),
                    child: Text(
                      'SEARCHES',
                      style: TextStyle(
                        fontSize: 8.3,
                        color: Color(0xFF8A95A7),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoveryDonutPainter extends CustomPainter {
  const _DiscoveryDonutPainter({
    required this.progress,
    required this.segments,
  });

  final double progress;
  final List<({double value, Color color})> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.14;
    final baseRect = rect.deflate(strokeWidth / 2);
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    basePaint.color = const Color(0xFFEFF4F8);
    canvas.drawArc(baseRect, 0, math.pi * 2, false, basePaint);

    if (segments.isEmpty) return;

    var startAngle = -math.pi * 0.92;
    const gap = 0.085;
    final easedProgress = Curves.easeOutCubic.transform(progress.clamp(0, 1));
    final animatedGap = gap * easedProgress;

    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweepAngle =
          segment.value *
          ((math.pi * 2) - (gap * segments.where((s) => s.value > 0).length)) *
          easedProgress;
      basePaint.color = segment.color;
      canvas.drawArc(baseRect, startAngle, sweepAngle, false, basePaint);
      startAngle += sweepAngle + animatedGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DiscoveryDonutPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.segments != segments;
  }
}

class _TrendChartPainter extends CustomPainter {
  const _TrendChartPainter({required this.series, required this.progress});

  final List<TrendSeries> series;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final allPoints = series.expand((series) => series.points).toList();
    final minValue = allPoints.reduce(math.min) - 0.15;
    final maxValue = allPoints.reduce(math.max) + 0.15;
    final gridPaint = Paint()
      ..color = const Color(0xFFE7ECF3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final visibleWidth = size.width * Curves.easeOutCubic.transform(progress);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, visibleWidth, size.height));

    for (var i = 0; i < 4; i++) {
      final dy = size.height * (i / 3);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    for (final line in series) {
      final points = <Offset>[];
      final stepX = size.width / (line.points.length - 1);

      for (var i = 0; i < line.points.length; i++) {
        final normalized = (line.points[i] - minValue) / (maxValue - minValue);
        final dy = size.height - (normalized * size.height);
        points.add(Offset(stepX * i, dy.clamp(0, size.height)));
      }

      final path = _smoothPath(points);
      final strokePaint = Paint()
        ..color = line.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 2.2;

      canvas.drawPath(path, strokePaint);
    }

    canvas.restore();
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) {
      return path;
    }

    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final midpoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, midpoint.dx, midpoint.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.series != series || oldDelegate.progress != progress;
  }
}

class _ActivityCardData {
  const _ActivityCardData({
    required this.title,
    required this.value,
    required this.delta,
    required this.deltaColor,
    required this.iconBackground,
    required this.icon,
  });

  final String title;
  final String value;
  final String delta;
  final Color deltaColor;
  final Color iconBackground;
  final Widget icon;
}

class _DiscoveryLegendData {
  const _DiscoveryLegendData({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;
}

class _TopQueryData {
  const _TopQueryData({required this.query, required this.searches});

  final String query;
  final int searches;
}

String _formatNumber(int value) {
  final valueString = value.toString();
  return valueString.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
}
