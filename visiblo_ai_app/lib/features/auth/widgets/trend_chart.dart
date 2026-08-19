import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../models/report_models.dart';

// ─── Data models ────────────────────────────────────────────

enum TrendWindow {
  month,
  year,
  quarter,
  halfYear;

  TrendConfig get config {
    switch (this) {
      case TrendWindow.month:
        return const TrendConfig(
          buttonLabel: 'Month',
          subtitle: 'Visibility and actions - Last 30 Days',
          periodUnitLabel: 'week',
          chartCaption: 'Each bar shows the total Google Views for one week.',
          xLabels: ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5'],
          yLabels: [700, 525, 350, 175, 0],
          series: [
            TrendSeries(
              label: 'Google Views',
              color: AppColors.brandBlue,
              points: [420, 510, 470, 620, 540],
            ),
            TrendSeries(
              label: 'Website Visits',
              color: AppColors.primary,
              points: [24, 31, 27, 36, 33],
            ),
            TrendSeries(
              label: 'Calls',
              color: Color(0xFF00C853), // Vibrant Green
              points: [8, 10, 9, 13, 11],
            ),
            TrendSeries(
              label: 'Directions',
              color: Color(0xFFFF6D00), // Vibrant Orange
              points: [54, 66, 61, 74, 69],
            ),
          ],
        );
      case TrendWindow.year:
        return const TrendConfig(
          buttonLabel: 'Year',
          subtitle: 'Visibility and actions - Last 12 Months',
          periodUnitLabel: 'quarter',
          chartCaption:
              'Each bar shows the total Google Views for one quarter.',
          xLabels: ['Jun-Aug', 'Sep-Nov', 'Dec-Feb', 'Mar-Jun'],
          yLabels: [900, 675, 450, 225, 0],
          series: [
            TrendSeries(
              label: 'Google Views',
              color: AppColors.brandBlue,
              points: [490, 470, 680, 910],
            ),
            TrendSeries(
              label: 'Website Visits',
              color: AppColors.primary,
              points: [31, 38, 54, 76],
            ),
            TrendSeries(
              label: 'Calls',
              color: Color(0xFF00C853),
              points: [12, 16, 14, 19],
            ),
            TrendSeries(
              label: 'Directions',
              color: Color(0xFFFF6D00),
              points: [88, 104, 151, 208],
            ),
          ],
        );
      case TrendWindow.quarter:
        return const TrendConfig(
          buttonLabel: 'Quarter',
          subtitle: 'Visibility and actions - Last 90 Days',
          periodUnitLabel: 'month',
          chartCaption: 'Each bar shows the total Google Views for one month.',
          xLabels: ['Mar', 'Apr', 'May', 'Jun'],
          yLabels: [800, 600, 400, 200, 0],
          series: [
            TrendSeries(
              label: 'Google Views',
              color: AppColors.brandBlue,
              points: [430, 470, 540, 610],
            ),
            TrendSeries(
              label: 'Website Visits',
              color: AppColors.primary,
              points: [26, 30, 37, 43],
            ),
            TrendSeries(
              label: 'Calls',
              color: Color(0xFF00C853),
              points: [9, 11, 14, 17],
            ),
            TrendSeries(
              label: 'Directions',
              color: Color(0xFFFF6D00),
              points: [63, 70, 78, 95],
            ),
          ],
        );
      case TrendWindow.halfYear:
        return const TrendConfig(
          buttonLabel: '6 Months',
          subtitle: 'Visibility and actions - Last 180 Days',
          periodUnitLabel: 'month',
          chartCaption: 'Each bar shows the total Google Views for one month.',
          xLabels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
          yLabels: [900, 675, 450, 225, 0],
          series: [
            TrendSeries(
              label: 'Google Views',
              color: AppColors.brandBlue,
              points: [360, 410, 470, 540, 620, 700],
            ),
            TrendSeries(
              label: 'Website Visits',
              color: AppColors.primary,
              points: [18, 22, 27, 31, 38, 44],
            ),
            TrendSeries(
              label: 'Calls',
              color: Color(0xFF00C853),
              points: [6, 8, 10, 11, 13, 15],
            ),
            TrendSeries(
              label: 'Directions',
              color: Color(0xFFFF6D00),
              points: [42, 52, 61, 69, 77, 88],
            ),
          ],
        );
    }
  }
}

enum TrendVisualMode {
  bar,
  trend;

  String get label {
    switch (this) {
      case TrendVisualMode.bar:
        return 'Bar View';
      case TrendVisualMode.trend:
        return 'Trend View';
    }
  }
}

class TrendConfig {
  const TrendConfig({
    required this.buttonLabel,
    required this.subtitle,
    required this.periodUnitLabel,
    required this.chartCaption,
    required this.xLabels,
    required this.yLabels,
    required this.series,
  });

  final String buttonLabel;
  final String subtitle;
  final String periodUnitLabel;
  final String chartCaption;
  final List<String> xLabels;
  final List<int> yLabels;
  final List<TrendSeries> series;
}

class TrendSeries {
  const TrendSeries({
    required this.label,
    required this.color,
    required this.points,
  });

  final String label;
  final Color color;
  final List<double> points;
}

// ─── Factory to build TrendConfig from live insights ────────

class TrendConfigFactory {
  TrendConfigFactory._();

  static TrendConfig emptyStateConfig(TrendConfig baseConfig) {
    return TrendConfig(
      buttonLabel: baseConfig.buttonLabel,
      subtitle: baseConfig.subtitle,
      periodUnitLabel: baseConfig.periodUnitLabel,
      chartCaption: baseConfig.chartCaption,
      xLabels: baseConfig.xLabels,
      yLabels: const [0, 0, 0, 0],
      series: baseConfig.series
          .map(
            (series) => TrendSeries(
              label: series.label,
              color: series.color,
              points: List<double>.filled(baseConfig.xLabels.length, 0),
            ),
          )
          .toList(growable: false),
    );
  }

  static TrendConfig fromInsights(
    LocationInsightsResponse? insights,
    TrendConfig fallbackConfig,
    TrendWindow window,
  ) {
    final daily = insights?.daily ?? [];

    if (daily.isEmpty) {
      return emptyStateConfig(fallbackConfig);
    }

    final datedInsights =
        daily
            .map((item) => (date: DateTime.tryParse(item.date), insight: item))
            .where((entry) => entry.date != null)
            .map((entry) => (date: entry.date!, insight: entry.insight))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    if (datedInsights.isEmpty) {
      return emptyStateConfig(fallbackConfig);
    }

    final bucketCount = _bucketCountForWindow(window, datedInsights.length);
    final buckets = _groupInsightsIntoBuckets(
      datedInsights,
      bucketCount: bucketCount,
      window: window,
    );

    final xLabels = buckets
        .map((bucket) => bucket.shortLabel)
        .toList(growable: false);
    final viewsPoints = buckets
        .map((bucket) => bucket.views)
        .toList(growable: false);
    final clicksPoints = buckets
        .map((bucket) => bucket.websiteVisits)
        .toList(growable: false);
    final callsPoints = buckets
        .map((bucket) => bucket.calls)
        .toList(growable: false);
    final dirPoints = buckets
        .map((bucket) => bucket.directions)
        .toList(growable: false);

    final maxVal = viewsPoints.fold<double>(
      0,
      (maxValue, value) => math.max(maxValue, value),
    );

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
          label: 'Google Views',
          color: AppColors.brandBlue,
          points: viewsPoints,
        ),
        TrendSeries(
          label: 'Website Visits',
          color: AppColors.primary,
          points: clicksPoints,
        ),
        TrendSeries(
          label: 'Calls',
          color: const Color(0xFF00C853),
          points: callsPoints,
        ),
        TrendSeries(
          label: 'Directions',
          color: const Color(0xFFFF6D00),
          points: dirPoints,
        ),
      ],
    );
  }
}

// ─── Animated chart widget ──────────────────────────────────

class AnimatedTrendChart extends StatelessWidget {
  const AnimatedTrendChart({
    super.key,
    required this.config,
    required this.cycle,
    required this.visualMode,
    required this.onVisualModeChanged,
  });

  final TrendConfig config;
  final int cycle;
  final TrendVisualMode visualMode;
  final ValueChanged<TrendVisualMode> onVisualModeChanged;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(cycle),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1800),
      curve: Curves.easeInOutCubic,
      builder: (context, progress, child) {
        return _TrendChart(
          config: config,
          progress: progress,
          visualMode: visualMode,
          onVisualModeChanged: onVisualModeChanged,
        );
      },
    );
  }
}

// ─── Chart layout ───────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.config,
    required this.visualMode,
    required this.onVisualModeChanged,
    this.progress = 1,
  });

  final TrendConfig config;
  final double progress;
  final TrendVisualMode visualMode;
  final ValueChanged<TrendVisualMode> onVisualModeChanged;

  @override
  Widget build(BuildContext context) {
    if (config.series.isEmpty) {
      return const SizedBox.shrink();
    }

    final primarySeries = config.series.first;
    final secondarySeries = config.series.skip(1).toList(growable: false);
    final actionTotal = secondarySeries.fold<double>(
      0,
      (sum, series) => sum + _seriesTotal(series),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PrimaryTrendPanel(
          config: config,
          series: primarySeries,
          progress: progress,
          visualMode: visualMode,
          onVisualModeChanged: onVisualModeChanged,
        ),
        if (secondarySeries.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: const Color(0xFFE2EAF3)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D123A61),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Action Breakdown',
                        style: TextStyle(
                          fontSize: 14.4,
                          color: AppColors.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${_formatWholeNumber(actionTotal)} total actions',
                      style: const TextStyle(
                        fontSize: 11.4,
                        color: Color(0xFF6D7A8E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Lower-volume actions are separated here so they stay easy to read.',
                  style: TextStyle(
                    fontSize: 11.2,
                    color: Color(0xFF7C889A),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < secondarySeries.length; i++)
                  _ActionMetricRow(
                    series: secondarySeries[i],
                    progress: progress,
                    totalActionCount: actionTotal,
                    periodUnitLabel: config.periodUnitLabel,
                    periodLabels: config.xLabels,
                    showDivider: i != secondarySeries.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PrimaryTrendPanel extends StatelessWidget {
  const _PrimaryTrendPanel({
    required this.config,
    required this.series,
    required this.progress,
    required this.visualMode,
    required this.onVisualModeChanged,
  });

  final TrendConfig config;
  final TrendSeries series;
  final double progress;
  final TrendVisualMode visualMode;
  final ValueChanged<TrendVisualMode> onVisualModeChanged;

  @override
  Widget build(BuildContext context) {
    final total = _seriesTotal(series);
    final average = _seriesAverage(series);
    final peak = _seriesPeak(series);
    final chartValues = series.points;
    final chartLabels = config.xLabels;
    final yLabels = _buildScaleLabels(_maxPointValue(chartValues));
    final peakIndex = _seriesPeakIndex(series);
    final bestPeriodLabel = chartLabels.isEmpty
        ? 'Selected range'
        : chartLabels[peakIndex.clamp(0, chartLabels.length - 1)];
    final chartCaption = visualMode == TrendVisualMode.bar
        ? config.chartCaption
        : 'Each point shows the total Google Views for one ${config.periodUnitLabel}.';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.zero,
        gradient: const LinearGradient(
          colors: [Color(0xFFFDFEFF), Color(0xFFF3F8FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFDCE6F1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2746),
            blurRadius: 22,
            offset: Offset(0, 10),
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      series.color.withValues(alpha: 0.18),
                      series.color.withValues(alpha: 0.08),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _iconForSeries(series.label),
                  color: series.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.label,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatWholeNumber(total)} total views in the selected range',
                      style: const TextStyle(
                        fontSize: 11.8,
                        color: Color(0xFF6D7A8E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => onVisualModeChanged(
                  visualMode == TrendVisualMode.bar
                      ? TrendVisualMode.trend
                      : TrendVisualMode.bar,
                ),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: series.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        visualMode == TrendVisualMode.bar
                            ? Icons.bar_chart_rounded
                            : Icons.show_chart_rounded,
                        size: 13,
                        color: series.color,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        visualMode.label,
                        style: TextStyle(
                          fontSize: 10.6,
                          color: series.color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TrendSummaryCard(
                  title: 'Total views',
                  value: _formatWholeNumber(total),
                  subtitle: 'Selected range',
                  accent: series.color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TrendSummaryCard(
                  title: 'Avg / ${config.periodUnitLabel}',
                  value: _formatWholeNumber(average.round()),
                  subtitle: 'Per ${config.periodUnitLabel}',
                  accent: const Color(0xFF2C8F97),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TrendSummaryCard(
                  title: 'Best ${config.periodUnitLabel}',
                  value: _formatWholeNumber(peak.round()),
                  subtitle: bestPeriodLabel,
                  accent: const Color(0xFFF2B211),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Y-axis: Total views',
                style: TextStyle(
                  fontSize: 10.8,
                  color: Color(0xFF77859A),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  chartCaption,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 10.4,
                    color: Color(0xFF8A97A8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 236,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: yLabels
                          .map(
                            (label) => Text(
                              _formatAxisValue(label),
                              style: const TextStyle(
                                fontSize: 10.8,
                                color: Color(0xFF7E8798),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(4, 12, 10, 10),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: const Color(0xFFD9E5F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: CustomPaint(
                        painter: visualMode == TrendVisualMode.bar
                            ? _PrimaryTrendPainter(
                                values: chartValues,
                                progress: progress,
                                color: series.color,
                                maxValue: _maxPointValue(chartValues),
                                gridLineCount: yLabels.length,
                              )
                            : _TrendLinePainter(
                                values: chartValues,
                                progress: progress,
                                color: series.color,
                                maxValue: _maxPointValue(chartValues),
                                gridLineCount: yLabels.length,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.only(left: 50),
            child: Text(
              'Time period',
              style: TextStyle(
                fontSize: 10.4,
                color: Color(0xFF8A97A8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 50, right: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < chartLabels.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: i == 0 ? 0 : 3,
                        right: i == chartLabels.length - 1 ? 0 : 3,
                      ),
                      child: Text(
                        chartLabels[i],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.2,
                          height: 1.2,
                          color: Color(0xFF627085),
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

class _ActionMetricRow extends StatelessWidget {
  const _ActionMetricRow({
    required this.series,
    required this.progress,
    required this.totalActionCount,
    required this.periodUnitLabel,
    required this.periodLabels,
    required this.showDivider,
  });

  final TrendSeries series;
  final double progress;
  final double totalActionCount;
  final String periodUnitLabel;
  final List<String> periodLabels;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final total = _seriesTotal(series);
    final average = _seriesAverage(series);
    final peak = _seriesPeak(series);
    final peakIndex = _seriesPeakIndex(series);
    final bestPeriodLabel = periodLabels.isEmpty
        ? 'Selected range'
        : periodLabels[peakIndex.clamp(0, periodLabels.length - 1)];
    final share = totalActionCount <= 0 ? 0.0 : (total / totalActionCount);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: series.color.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _iconForSeries(series.label),
                      color: series.color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      series.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.2,
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatWholeNumber(total),
                    style: const TextStyle(
                      fontSize: 22,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TrendSummaryCard(
                      title: 'Share',
                      value: '${(share * 100).round()}%',
                      subtitle: 'of actions',
                      accent: series.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TrendSummaryCard(
                      title: 'Avg / $periodUnitLabel',
                      value: _formatWholeNumber(average.round()),
                      subtitle: 'Per $periodUnitLabel',
                      accent: const Color(0xFF2C8F97),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TrendSummaryCard(
                      title: 'Best $periodUnitLabel',
                      value: _formatWholeNumber(peak.round()),
                      subtitle: bestPeriodLabel,
                      accent: const Color(0xFFF2B211),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ActionShareBar(
                value: share,
                progress: progress,
                color: series.color,
                label: 'Share of total actions',
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: Color(0xFFE9EEF5)),
      ],
    );
  }
}

class _ActionShareBar extends StatelessWidget {
  const _ActionShareBar({
    required this.value,
    required this.progress,
    required this.color,
    required this.label,
  });

  final double value;
  final double progress;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);
    final animatedValue =
        clampedValue * Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.8,
                color: Color(0xFF7A8799),
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${(clampedValue * 100).round()}%',
              style: const TextStyle(
                fontSize: 10.8,
                color: Color(0xFF6A768A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.zero,
          child: Container(
            height: 10,
            color: const Color(0xFFF0F4F8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: animatedValue,
                child: Container(
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendSummaryCard extends StatelessWidget {
  const _TrendSummaryCard({
    required this.title,
    required this.value,
    required this.accent,
    this.subtitle,
  });

  final String title;
  final String value;
  final Color accent;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.0,
              color: Color(0xFF6A768A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15.2,
              color: AppColors.text,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.7,
                color: Color(0xFF7E8798),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryTrendPainter extends CustomPainter {
  const _PrimaryTrendPainter({
    required this.values,
    required this.progress,
    required this.gridLineCount,
    required this.color,
    required this.maxValue,
  });

  final List<double> values;
  final double progress;
  final int gridLineCount;
  final Color color;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final safeMaxValue = math.max(maxValue, 1);
    final gridPaint = Paint()
      ..color = const Color(0xFFE6ECF4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final totalGridLines = math.max(gridLineCount, 4);
    for (var i = 0; i < totalGridLines; i++) {
      final y = totalGridLines == 1
          ? size.height
          : size.height * (i / (totalGridLines - 1));
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final topPadding = 18.0;
    final chartHeight = math.max(1.0, size.height - topPadding);
    final gap = values.length >= 6 ? 8.0 : 10.0;
    final barWidth = values.length == 1
        ? size.width
        : (size.width - ((values.length - 1) * gap)) / values.length;
    final basePaint = Paint()
      ..color = const Color(0xFFF4F7FB)
      ..style = PaintingStyle.fill;
    final labelStyle = const TextStyle(
      fontSize: 9.8,
      color: Color(0xFF6D7A8E),
      fontWeight: FontWeight.w800,
    );

    for (var i = 0; i < values.length; i++) {
      final left = i * (barWidth + gap);
      final normalized = (values[i] / safeMaxValue).clamp(0.0, 1.0);
      final startDelay = values.length == 1 ? 0.0 : (i / values.length) * 0.22;
      final localProgress = ((progress - startDelay) / (1 - startDelay)).clamp(
        0.0,
        1.0,
      );
      final easedProgress = Curves.easeOutCubic.transform(localProgress);
      final animatedHeight = normalized * easedProgress;
      final rawBarHeight = animatedHeight * (chartHeight - 8);
      final barHeight = rawBarHeight <= 0 ? 0.0 : math.max(8.0, rawBarHeight);
      final top = size.height - barHeight;
      final barRect = Rect.fromLTWH(left, top, barWidth, barHeight);
      final baseRect = Rect.fromLTWH(left, topPadding, barWidth, chartHeight);

      canvas.drawRect(baseRect, basePaint);

      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      if (barHeight > 0) {
        canvas.drawRect(barRect, fillPaint);
      }

      if (localProgress > 0.15) {
        final valuePainter = TextPainter(
          text: TextSpan(text: _formatAxisValue(values[i]), style: labelStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: math.max(barWidth + 12, 26));
        final labelOffset = Offset(
          left + ((barWidth - valuePainter.width) / 2),
          math.max(0, top - valuePainter.height - 4),
        );
        valuePainter.paint(canvas, labelOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PrimaryTrendPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.progress != progress ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.gridLineCount != gridLineCount ||
        oldDelegate.color != color;
  }
}

class _TrendLinePainter extends CustomPainter {
  const _TrendLinePainter({
    required this.values,
    required this.progress,
    required this.color,
    required this.maxValue,
    required this.gridLineCount,
  });

  final List<double> values;
  final double progress;
  final Color color;
  final double maxValue;
  final int gridLineCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final safeMaxValue = math.max(maxValue, 1.0);
    final visibleWidth =
        size.width * Curves.easeOutCubic.transform(progress.clamp(0, 1));
    final gridPaint = Paint()
      ..color = const Color(0xFFE6ECF4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final totalGridLines = math.max(gridLineCount, 4);
    for (var i = 0; i < totalGridLines; i++) {
      final y = totalGridLines == 1
          ? size.height
          : size.height * (i / (totalGridLines - 1));
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final offsets = _buildOffsets(
      values,
      width: size.width,
      height: size.height,
      maxValue: safeMaxValue,
    );
    final linePath = _buildSmoothPath(offsets);
    final fillPath = Path.from(linePath)
      ..lineTo(offsets.last.dx, size.height)
      ..lineTo(offsets.first.dx, size.height)
      ..close();

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, visibleWidth, size.height));

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.04)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, glowPaint);
    canvas.drawPath(linePath, linePaint);

    final visibleOffsets = offsets
        .where((offset) => offset.dx <= visibleWidth)
        .toList();
    if (visibleOffsets.isNotEmpty) {
      final focusPoint = visibleOffsets.last;
      final haloPaint = Paint()
        ..color = color.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill;
      final pointPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final innerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(focusPoint, 10, haloPaint);
      canvas.drawCircle(focusPoint, 5.5, pointPaint);
      canvas.drawCircle(focusPoint, 2.4, innerPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.gridLineCount != gridLineCount;
  }
}

void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
  const dashWidth = 6.0;
  const dashSpace = 4.0;
  var startX = p1.dx;

  while (startX < p2.dx) {
    canvas.drawLine(
      Offset(startX, p1.dy),
      Offset(math.min(startX + dashWidth, p2.dx), p1.dy),
      paint,
    );
    startX += dashWidth + dashSpace;
  }
}

class _TrendBucket {
  const _TrendBucket({
    required this.shortLabel,
    required this.views,
    required this.websiteVisits,
    required this.calls,
    required this.directions,
  });

  final String shortLabel;
  final double views;
  final double websiteVisits;
  final double calls;
  final double directions;
}

int _bucketCountForWindow(TrendWindow window, int pointCount) {
  final targetCount = switch (window) {
    TrendWindow.month => 5,
    TrendWindow.quarter => 4,
    TrendWindow.halfYear => 6,
    TrendWindow.year => 4,
  };

  return math.max(1, math.min(targetCount, pointCount));
}

List<_TrendBucket> _groupInsightsIntoBuckets(
  List<({DateTime date, DailyInsight insight})> insights, {
  required int bucketCount,
  required TrendWindow window,
}) {
  if (insights.isEmpty) {
    return const <_TrendBucket>[];
  }

  final buckets = <_TrendBucket>[];
  var startIndex = 0;

  for (var i = 0; i < bucketCount; i++) {
    final endIndex = i == bucketCount - 1
        ? insights.length
        : ((i + 1) * insights.length / bucketCount).round();

    if (endIndex <= startIndex) {
      continue;
    }

    final slice = insights.sublist(startIndex, endIndex);
    final first = slice.first;
    final last = slice.last;

    buckets.add(
      _TrendBucket(
        shortLabel: _formatBucketLabel(first.date, last.date, window: window),
        views: slice.fold<double>(
          0,
          (sum, entry) =>
              sum +
              entry.insight.searchImpressions +
              entry.insight.mapsImpressions,
        ),
        websiteVisits: slice.fold<double>(
          0,
          (sum, entry) => sum + entry.insight.websiteClicks,
        ),
        calls: slice.fold<double>(
          0,
          (sum, entry) => sum + entry.insight.callClicks,
        ),
        directions: slice.fold<double>(
          0,
          (sum, entry) => sum + entry.insight.directionRequests,
        ),
      ),
    );

    startIndex = endIndex;
  }

  return buckets;
}

String _formatBucketLabel(
  DateTime start,
  DateTime end, {
  required TrendWindow window,
}) {
  const months = [
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

  final startMonth = months[start.month - 1];
  final endMonth = months[end.month - 1];

  switch (window) {
    case TrendWindow.month:
      if (start.month == end.month) {
        return '${start.day}-${end.day} $startMonth';
      }
      return '${start.day} $startMonth-${end.day} $endMonth';
    case TrendWindow.quarter:
    case TrendWindow.halfYear:
    case TrendWindow.year:
      if (start.month == end.month) {
        return startMonth;
      }
      return '$startMonth-$endMonth';
  }
}

List<Offset> _buildOffsets(
  List<double> points, {
  required double width,
  required double height,
  required double maxValue,
}) {
  if (points.isEmpty) {
    return const <Offset>[];
  }

  final stepX = points.length == 1 ? width : width / (points.length - 1);
  final offsets = <Offset>[];

  for (var i = 0; i < points.length; i++) {
    final normalized = (points[i] / maxValue).clamp(0.0, 1.0);
    final y = height - (normalized * height);
    offsets.add(Offset(i * stepX, y.clamp(0.0, height)));
  }

  return offsets;
}

Path _buildSmoothPath(List<Offset> points) {
  final path = Path();
  if (points.isEmpty) {
    return path;
  }

  path.moveTo(points.first.dx, points.first.dy);
  if (points.length == 1) {
    return path;
  }

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

List<double> _buildScaleLabels(double maxValue) {
  final safeMax = math.max(maxValue, 1.0);
  return [safeMax, safeMax * 0.66, safeMax * 0.33, 0.0];
}

double _seriesTotal(TrendSeries series) {
  return series.points.fold<double>(0, (sum, point) => sum + point);
}

double _seriesAverage(TrendSeries series) {
  if (series.points.isEmpty) {
    return 0;
  }
  return _seriesTotal(series) / series.points.length;
}

double _seriesPeak(TrendSeries series) {
  return _maxPointValue(series.points);
}

int _seriesPeakIndex(TrendSeries series) {
  if (series.points.isEmpty) {
    return 0;
  }

  var peakIndex = 0;
  var peakValue = series.points.first;

  for (var i = 1; i < series.points.length; i++) {
    if (series.points[i] > peakValue) {
      peakValue = series.points[i];
      peakIndex = i;
    }
  }

  return peakIndex;
}

double _maxPointValue(List<double> points) {
  return points.isEmpty
      ? 1.0
      : points.fold<double>(0, (maxValue, point) => math.max(maxValue, point));
}

String _formatWholeNumber(num value) {
  final number = value.round();
  return number.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

String _formatAxisValue(double value) {
  if (value >= 1000) {
    final scaled = value / 1000;
    final text = scaled >= 10 || scaled == scaled.roundToDouble()
        ? scaled.toStringAsFixed(0)
        : scaled.toStringAsFixed(1);
    return '${text}k';
  }
  return value.round().toString();
}

IconData _iconForSeries(String label) {
  switch (label) {
    case 'Google Views':
      return Icons.visibility_rounded;
    case 'Website Visits':
      return Icons.language_rounded;
    case 'Calls':
      return Icons.call_rounded;
    case 'Directions':
      return Icons.route_rounded;
    default:
      return Icons.auto_graph_rounded;
  }
}
