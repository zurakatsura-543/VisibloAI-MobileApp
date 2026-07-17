import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../controllers/payment_controller.dart';
import '../controllers/seo_tools_controller.dart';
import '../models/payment_models.dart';
import '../models/seo_tools_models.dart';
import '../models/website_manager_models.dart';
import '../widgets/auth_navigation_shell.dart';
import '../widgets/billing_access_banner.dart';

class KeywordRankingView extends StatefulWidget {
  const KeywordRankingView({
    super.key,
    this.initialTab = SeoMobileTab.keywords,
  });

  final SeoMobileTab initialTab;

  @override
  State<KeywordRankingView> createState() => _KeywordRankingViewState();
}

class _KeywordRankingViewState extends State<KeywordRankingView> {
  late final SeoToolsController _controller;
  late final PaymentController _paymentController;
  final GlobalKey _keywordSnapshotKey = GlobalKey();
  final GlobalKey _commandCenterKey = GlobalKey();
  final GlobalKey _keywordCommandCenterKey = GlobalKey();
  final GlobalKey _aiSuggestionsKey = GlobalKey();
  final GlobalKey _keywordRankingKey = GlobalKey();
  final GlobalKey _proofSummaryKey = GlobalKey();
  final GlobalKey _rankingGraphKey = GlobalKey();
  final GlobalKey _recommendationsKey = GlobalKey();
  final GlobalKey _trackedKeywordsKey = GlobalKey();
  final GlobalKey _heatmapCommandKey = GlobalKey();
  final GlobalKey _heatmapGridKey = GlobalKey();
  final GlobalKey _heatmapInsightsKey = GlobalKey();
  int _visibleSuggestedCount = 5;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<SeoToolsController>()) {
      _controller = Get.find<SeoToolsController>();
    } else {
      _controller = Get.put(SeoToolsController());
    }
    if (Get.isRegistered<PaymentController>()) {
      _paymentController = Get.find<PaymentController>();
    } else {
      _paymentController = Get.put(PaymentController());
    }
    _controller.changeTab(widget.initialTab);
  }

  @override
  Widget build(BuildContext context) {
    return AuthNavigationShell(
      currentTab: AuthTab.home,
      backgroundColor: const Color(0xFFF7FAFC),
      child: Obx(() {
        final selectedKeyword = _controller.selectedKeyword;
        final selectedLocation = _controller.selectedLocation;
        final billingBanner = _buildBillingBanner(_controller.activeTab.value);

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _controller.loadInitialData(
            manualRefresh: true,
            initialTab: _controller.activeTab.value,
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SeoPageHeader(
                      title: _titleFor(_controller.activeTab.value),
                      onBackTap: _handleBackTap,
                    ),
                    const SizedBox(height: 12),
                    if (_controller.errorMessage.value != null)
                      _MessageBanner(
                        message: _controller.errorMessage.value!,
                        tone: _BannerTone.error,
                      ),
                    if (_controller.infoMessage.value != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _MessageBanner(
                          message: _controller.infoMessage.value!,
                          tone: _BannerTone.info,
                        ),
                      ),
                    if (billingBanner != null) ...[
                      const SizedBox(height: 10),
                      billingBanner,
                    ],
                    const SizedBox(height: 12),
                    _OverviewHero(
                      overview: _controller.overview.value,
                      location: selectedLocation,
                    ),
                    const SizedBox(height: 12),
                    _LocationSelectorCard(
                      locations: _controller.locations,
                      selectedLocationId: _controller.selectedLocationId.value,
                      onChanged: _controller.selectLocation,
                    ),
                    const SizedBox(height: 12),
                    _SeoSectionSwitcher(
                      activeTab: _controller.activeTab.value,
                      onChanged: _handleTabChange,
                    ),
                    const SizedBox(height: 12),
                    _QuickSectionNav(
                      activeTab: _controller.activeTab.value,
                      onAddKeywordTap: _showAddKeywordSheet,
                      onRunCompetitorTap: _handleCompetitorDiscovery,
                      onGenerateHeatmapTap: _handleHeatmapGeneration,
                    ),
                    const SizedBox(height: 12),
                    if (_controller.isLoading.value &&
                        _controller.keywords.isEmpty &&
                        _controller.competitors.isEmpty)
                      const _LoadingCard()
                    else
                      switch (_controller.activeTab.value) {
                        SeoMobileTab.keywords => _KeywordsTab(
                          controller: _controller,
                          selectedKeyword: selectedKeyword,
                          onAddKeywordTap: _showAddKeywordSheet,
                          onAddSuggestedKeyword: _handleSuggestedKeywordAdd,
                          onScanKeyword: _handleScanKeyword,
                          visibleSuggestedCount: _visibleSuggestedCount,
                          onToggleSuggested: () {
                            setState(() {
                              final total =
                                  _controller.availableSuggestions.length;
                              if (_visibleSuggestedCount >= total) {
                                _visibleSuggestedCount = 5;
                              } else {
                                _visibleSuggestedCount = math.min(
                                  _visibleSuggestedCount + 5,
                                  total,
                                );
                              }
                            });
                          },
                          commandCenterKey: _commandCenterKey,
                          keywordCommandCenterKey: _keywordCommandCenterKey,
                          aiSuggestionsKey: _aiSuggestionsKey,
                          keywordRankingKey: _keywordRankingKey,
                          proofSummaryKey: _proofSummaryKey,
                          rankingGraphKey: _rankingGraphKey,
                          recommendationsKey: _recommendationsKey,
                          trackedKeywordsKey: _trackedKeywordsKey,
                          onJumpToSection: _jumpToSection,
                          keywordSnapshotKey: _keywordSnapshotKey,
                        ),
                        SeoMobileTab.competitors => _CompetitorsTab(
                          controller: _controller,
                          selectedKeyword: selectedKeyword,
                          onDiscoverTap: _handleCompetitorDiscovery,
                        ),
                        SeoMobileTab.heatmap => _HeatmapTab(
                          controller: _controller,
                          selectedKeyword: selectedKeyword,
                          onGenerateTap: _handleHeatmapGeneration,
                          heatmapCommandKey: _heatmapCommandKey,
                          heatmapGridKey: _heatmapGridKey,
                          heatmapInsightsKey: _heatmapInsightsKey,
                          onJumpToSection: _jumpToSection,
                        ),
                      },
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  String _titleFor(SeoMobileTab tab) {
    switch (tab) {
      case SeoMobileTab.keywords:
        return 'Keyword Ranking';
      case SeoMobileTab.competitors:
        return 'Competitor Analysis';
      case SeoMobileTab.heatmap:
        return 'Heatmap';
    }
  }

  String _routeForTab(SeoMobileTab tab) {
    switch (tab) {
      case SeoMobileTab.keywords:
        return AppRoutes.keywordRanking;
      case SeoMobileTab.competitors:
        return AppRoutes.seoCompetitors;
      case SeoMobileTab.heatmap:
        return AppRoutes.seoHeatmap;
    }
  }

  Future<void> _handleTabChange(SeoMobileTab tab) async {
    await _controller.changeTab(tab);
    final route = _routeForTab(tab);
    if (Get.currentRoute != route) {
      Get.offNamed(route);
    }
  }

  Future<void> _handleSuggestedKeywordAdd(String keyword) async {
    if (!await _guardKeywordCreation()) {
      return;
    }
    await _controller.addKeyword(keyword);
    if (!mounted) return;
    setState(() {
      _visibleSuggestedCount = 5;
    });
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final sectionContext = _keywordSnapshotKey.currentContext;
    if (sectionContext != null && sectionContext.mounted) {
      await Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    }
  }

  Future<void> _jumpToSection(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null || !context.mounted) {
      return;
    }
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.06,
    );
  }

  Future<void> _handleScanKeyword(String keywordId, {int? radiusKm}) async {
    if (!await _guardKeywordScan()) {
      return;
    }
    await _controller.scanKeywordNow(keywordId, radiusKm: radiusKm);
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final sectionContext = _keywordSnapshotKey.currentContext;
    if (sectionContext != null && sectionContext.mounted) {
      await Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    }
  }

  void _handleBackTap() {
    if (Navigator.of(context).canPop()) {
      Get.back();
      return;
    }
    Get.offNamed(AppRoutes.dashboard);
  }

  Future<void> _showAddKeywordSheet() async {
    if (!await _guardKeywordCreation()) {
      return;
    }
    if (!mounted) {
      return;
    }
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final suggestions = _controller.availableSuggestions;
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              22,
              20,
              22 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add a new keyword',
                  style: AppTypography.card(
                    fontSize: 20,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track money keywords, service + city terms, and nearby intent terms first.',
                  style: AppTypography.body(
                    fontSize: 13.5,
                    color: const Color(0xFF65758B),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'e.g. kurti manufacturers in mumbai',
                    filled: true,
                    fillColor: const Color(0xFFF8FBFD),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFD9E5EF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFD9E5EF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFF2DB6C4)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final keyword = controller.text.trim();
                      if (keyword.isEmpty) return;
                      Navigator.of(context).pop();
                      await _handleSuggestedKeywordAdd(keyword);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Add keyword'),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Suggested keywords from GBP demand',
                  style: AppTypography.label(
                    fontSize: 12.8,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                if (suggestions.isEmpty)
                  Text(
                    'No fresh unused suggestions are available right now. You can still add a keyword manually.',
                    style: AppTypography.body(
                      fontSize: 12.6,
                      color: const Color(0xFF7A879A),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: suggestions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = suggestions[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FBFD),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFDDE8F0)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.keyword,
                                      style: AppTypography.label(
                                        fontSize: 13.2,
                                        color: AppColors.brandBlue,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.reason ??
                                          'Relevant local demand idea',
                                      style: AppTypography.body(
                                        fontSize: 11.8,
                                        color: const Color(0xFF6C7A90),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              _InlineButton(
                                label: 'Add',
                                icon: Icons.add_rounded,
                                filled: true,
                                onTap: () async {
                                  Navigator.of(context).pop();
                                  await _handleSuggestedKeywordAdd(
                                    item.keyword,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  BillingUsageInfo? get _billingUsage => _paymentController.billingUsage.value;

  BillingFeatureEntitlement? _featureEntitlement(String key) {
    return _billingUsage?.featureEntitlements[key];
  }

  Future<void> _openPaymentPlans() async {
    await Get.toNamed(AppRoutes.payment);
  }

  Future<void> _showBillingBlocker({
    required String title,
    required String message,
    String? badge,
  }) {
    return showBillingAccessSheet(
      context: context,
      title: title,
      message: message,
      badge: badge,
      primaryLabel: 'Open plans',
      onPrimaryTap: _openPaymentPlans,
      secondaryLabel: 'Maybe later',
      onSecondaryTap: () {},
    );
  }

  Future<bool> _guardLockedWorkspace() async {
    final usage = _billingUsage;
    if (usage == null || !usage.locked) {
      return true;
    }
    await _showBillingBlocker(
      title: 'Activate this workspace first',
      message:
          'Your current business is still outside the active billing access state. Activate or upgrade this workspace before using SEO scans and growth tools.',
      badge: usage.planDisplayName,
    );
    return false;
  }

  Future<bool> _guardKeywordCreation() async {
    if (!await _guardLockedWorkspace()) {
      return false;
    }
    final feature = _billingUsage?.keywords;
    if (feature != null && !feature.canUse) {
      await _showBillingBlocker(
        title: 'Keyword limit reached',
        message:
            'You have used all ${feature.limit} keyword slots in your current plan. Upgrade to keep tracking more high-intent keywords for this location.',
        badge: '${feature.used}/${feature.limit} used',
      );
      return false;
    }
    return true;
  }

  Future<bool> _guardKeywordScan() async {
    if (!await _guardLockedWorkspace()) {
      return false;
    }
    final feature = _billingUsage?.keywordChecks;
    if (feature != null && !feature.canUse) {
      await _showBillingBlocker(
        title: 'Monthly scan budget used',
        message:
            'Your plan has used its monthly keyword scan budget. Upgrade to refresh ranking proof more often across more keywords.',
        badge: '${feature.used}/${feature.limit} scans',
      );
      return false;
    }
    return true;
  }

  Future<void> _handleCompetitorDiscovery() async {
    if (!await _guardLockedWorkspace()) {
      return;
    }
    final entitlement = _featureEntitlement('COMPETITOR_ANALYSIS');
    if (entitlement != null && !entitlement.included) {
      await _showBillingBlocker(
        title: 'Competitor Analysis is locked',
        message: entitlement.upgradeMessage,
        badge: _billingUsage?.planDisplayName,
      );
      return;
    }
    await _controller.discoverCompetitors();
  }

  Future<void> _handleHeatmapGeneration() async {
    if (!await _guardLockedWorkspace()) {
      return;
    }
    final entitlement = _featureEntitlement('HEATMAP');
    if (entitlement != null && !entitlement.included) {
      await _showBillingBlocker(
        title: 'Heatmap is locked',
        message: entitlement.upgradeMessage,
        badge: _billingUsage?.planDisplayName,
      );
      return;
    }
    final feature = _billingUsage?.heatmapScans;
    if (feature != null && !feature.canUse) {
      await _showBillingBlocker(
        title: 'Monthly heatmap budget used',
        message:
            'Your current plan has used all available heatmap scans for this billing cycle. Upgrade to keep generating fresh local visibility maps.',
        badge: '${feature.used}/${feature.limit} scans',
      );
      return;
    }
    await _controller.loadHeatmapData(generate: true);
  }

  Widget? _buildBillingBanner(SeoMobileTab tab) {
    final usage = _billingUsage;
    if (usage == null) {
      return null;
    }
    if (usage.locked) {
      return BillingAccessBanner(
        eyebrow: 'workspace billing',
        title: 'This business is waiting for activation.',
        message:
            'You can browse the SEO workspace, but scans and growth actions stay protected until this location is covered by an active plan.',
        badge: usage.planDisplayName,
        primaryLabel: 'Activate or upgrade',
        onPrimaryTap: _openPaymentPlans,
      );
    }

    switch (tab) {
      case SeoMobileTab.keywords:
        final keywordSlots = usage.keywords;
        if (!keywordSlots.canUse) {
          return BillingAccessBanner(
            eyebrow: 'keyword quota',
            title: 'All tracked keyword slots are full.',
            message:
                'You have already filled ${keywordSlots.limit} tracked keywords in this plan. Upgrade before adding the next money keyword.',
            badge: '${keywordSlots.used}/${keywordSlots.limit} used',
            primaryLabel: 'Upgrade plan',
            onPrimaryTap: _openPaymentPlans,
          );
        }
        if (keywordSlots.remaining <= 3) {
          return BillingAccessBanner(
            eyebrow: 'keyword quota',
            title: 'Only ${keywordSlots.remaining} keyword slots left.',
            message:
                'Keep this in mind before adding more terms. If you want broader coverage across nearby intent keywords, upgrade before you run out.',
            badge: '${keywordSlots.used}/${keywordSlots.limit} used',
            primaryLabel: 'View plans',
            onPrimaryTap: _openPaymentPlans,
            secondaryLabel: 'Use remaining wisely',
            onSecondaryTap: () {},
          );
        }
        break;
      case SeoMobileTab.competitors:
        final entitlement = _featureEntitlement('COMPETITOR_ANALYSIS');
        if (entitlement != null && !entitlement.included) {
          return BillingAccessBanner(
            eyebrow: 'feature lock',
            title: 'Competitor Analysis needs a higher plan.',
            message: entitlement.upgradeMessage,
            badge: usage.planDisplayName,
            primaryLabel: 'Unlock this feature',
            onPrimaryTap: _openPaymentPlans,
          );
        }
        break;
      case SeoMobileTab.heatmap:
        final heatmapScans = usage.heatmapScans;
        if (!heatmapScans.canUse) {
          return BillingAccessBanner(
            eyebrow: 'scan budget',
            title: 'Your monthly heatmap scans are used up.',
            message:
                'Fresh local visibility maps are locked until the next billing reset or an upgrade increases your scan capacity.',
            badge: '${heatmapScans.used}/${heatmapScans.limit} scans',
            primaryLabel: 'Upgrade for more scans',
            onPrimaryTap: _openPaymentPlans,
          );
        }
        if (heatmapScans.remaining <= 3) {
          return BillingAccessBanner(
            eyebrow: 'scan budget',
            title: 'Only ${heatmapScans.remaining} heatmap scans remain.',
            message:
                'Use the remaining scans on your highest-intent keywords first, or upgrade if you want to test more local areas this month.',
            badge: '${heatmapScans.used}/${heatmapScans.limit} scans',
            primaryLabel: 'See upgrade options',
            onPrimaryTap: _openPaymentPlans,
            secondaryLabel: 'Continue carefully',
            onSecondaryTap: () {},
          );
        }
        break;
    }
    return null;
  }
}

class _KeywordsTab extends StatelessWidget {
  const _KeywordsTab({
    required this.controller,
    required this.selectedKeyword,
    required this.onAddKeywordTap,
    required this.onAddSuggestedKeyword,
    required this.onScanKeyword,
    required this.visibleSuggestedCount,
    required this.onToggleSuggested,
    required this.commandCenterKey,
    required this.keywordCommandCenterKey,
    required this.aiSuggestionsKey,
    required this.keywordRankingKey,
    required this.proofSummaryKey,
    required this.rankingGraphKey,
    required this.recommendationsKey,
    required this.trackedKeywordsKey,
    required this.onJumpToSection,
    required this.keywordSnapshotKey,
  });

  final SeoToolsController controller;
  final TrackedKeyword? selectedKeyword;
  final VoidCallback onAddKeywordTap;
  final ValueChanged<String> onAddSuggestedKeyword;
  final Future<void> Function(String keywordId, {int? radiusKm}) onScanKeyword;
  final int visibleSuggestedCount;
  final VoidCallback onToggleSuggested;
  final GlobalKey commandCenterKey;
  final GlobalKey keywordCommandCenterKey;
  final GlobalKey aiSuggestionsKey;
  final GlobalKey keywordRankingKey;
  final GlobalKey proofSummaryKey;
  final GlobalKey rankingGraphKey;
  final GlobalKey recommendationsKey;
  final GlobalKey trackedKeywordsKey;
  final Future<void> Function(GlobalKey key) onJumpToSection;
  final GlobalKey keywordSnapshotKey;

  @override
  Widget build(BuildContext context) {
    final sections = controller.keywordSections.value;
    final overview = controller.overview.value;
    final recommendations = controller.recommendations.value;
    final suggestedKeywords = controller.availableSuggestions;
    final visibleSuggestions = suggestedKeywords
        .take(math.min(visibleSuggestedCount, suggestedKeywords.length))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          key: keywordSnapshotKey,
          title: 'Jump to any part of the keyword page.',
          eyebrow: 'page navigation',
          child: _PageNavigationCard(
            items: [
              _PageJumpItem(
                label: 'Local SEO Command Center',
                icon: Icons.adjust_rounded,
                onTap: () => onJumpToSection(commandCenterKey),
              ),
              _PageJumpItem(
                label: 'Keyword Command Center',
                icon: Icons.filter_center_focus_rounded,
                onTap: () => onJumpToSection(keywordCommandCenterKey),
              ),
              _PageJumpItem(
                label: 'AI Suggested next keywords',
                icon: Icons.auto_awesome_rounded,
                onTap: () => onJumpToSection(aiSuggestionsKey),
              ),
              _PageJumpItem(
                label: 'What VisibloAI thinks you should do next',
                icon: Icons.verified_user_outlined,
                onTap: () => onJumpToSection(recommendationsKey),
              ),
              _PageJumpItem(
                label: 'Keyword Ranking',
                icon: Icons.show_chart_rounded,
                onTap: () => onJumpToSection(keywordRankingKey),
              ),
              _PageJumpItem(
                label: 'Proof summary',
                icon: Icons.pin_drop_outlined,
                onTap: () => onJumpToSection(proofSummaryKey),
              ),
              _PageJumpItem(
                label: 'Tracked Keywords',
                icon: Icons.search_rounded,
                onTap: () => onJumpToSection(trackedKeywordsKey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          key: commandCenterKey,
          title: 'Local SEO Command Center',
          eyebrow: 'owner overview',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Visibility',
                      value: '${overview?.localVisibilityScore ?? 0}',
                      tone: const Color(0xFFEAF8F8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Verified avg',
                      value: overview?.verifiedAverageRank != null
                          ? '#${overview!.verifiedAverageRank!.toStringAsFixed(1)}'
                          : 'Build proof',
                      tone: const Color(0xFFEAF2FF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Top 3',
                      value: '${overview?.top3CoveragePercent ?? 0}%',
                      tone: const Color(0xFFEAF9F1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Top 10',
                      value: '${overview?.top10CoveragePercent ?? 0}%',
                      tone: const Color(0xFFFFF6E8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          key: keywordCommandCenterKey,
          title: 'Keyword Command Center',
          eyebrow: 'grouped action lanes',
          trailing: _SoftActionButton(
            label: 'Add keyword',
            icon: Icons.add_rounded,
            onTap: onAddKeywordTap,
          ),
          child: Column(
            children: [
              _KeywordLane(
                title: 'Quick wins',
                subtitle: 'Closest keywords to visible movement.',
                tone: const Color(0xFFEAF9F1),
                items: sections?.quickWins ?? const <TrackedKeyword>[],
                selectedId: controller.selectedKeywordId.value,
                onTap: controller.selectKeyword,
              ),
              const SizedBox(height: 10),
              _KeywordLane(
                title: 'Needs attention',
                subtitle: 'Weak coverage that needs stronger proof.',
                tone: const Color(0xFFFFF0F3),
                items: sections?.needsAttention ?? const <TrackedKeyword>[],
                selectedId: controller.selectedKeywordId.value,
                onTap: controller.selectKeyword,
              ),
              const SizedBox(height: 10),
              _KeywordLane(
                title: 'Defend winners',
                subtitle: 'Already strong keywords to protect.',
                tone: const Color(0xFFEAF5FF),
                items: sections?.defend ?? const <TrackedKeyword>[],
                selectedId: controller.selectedKeywordId.value,
                onTap: controller.selectKeyword,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          key: aiSuggestionsKey,
          title: 'AI Suggested next keywords 🪄',
          eyebrow: 'smart expansion ideas',
          child: suggestedKeywords.isEmpty
              ? const _EmptyStateCard(
                  title: 'No suggestions yet',
                  copy:
                      'Add 2-3 core service keywords first so VisibloAI can suggest fresh unused next ideas.',
                )
              : Column(
                  children: [
                    ...visibleSuggestions.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FBFD),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFDDE8F0)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.keyword,
                                      style: AppTypography.label(
                                        fontSize: 13.2,
                                        color: AppColors.brandBlue,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.reason ?? 'Relevant local idea',
                                      style: AppTypography.body(
                                        fontSize: 11.8,
                                        color: const Color(0xFF6C7A90),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              _InlineButton(
                                label: 'Add keyword',
                                icon: Icons.add_rounded,
                                filled: true,
                                onTap: () =>
                                    onAddSuggestedKeyword(item.keyword),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (suggestedKeywords.length > 5)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _SoftActionButton(
                          label:
                              visibleSuggestedCount >= suggestedKeywords.length
                              ? 'See less'
                              : 'See 5 more',
                          icon:
                              visibleSuggestedCount >= suggestedKeywords.length
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          onTap: onToggleSuggested,
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        if (selectedKeyword != null) ...[
          _SectionCard(
            key: keywordRankingKey,
            title: 'Keyword Ranking',
            eyebrow: 'track movement from 50+ to the map pack',
            trailing: _RadiusSelector(
              value: controller.selectedRadiusKm.value,
              onChanged: (value) => controller.setRadiusKm(value),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedKeyword!.keyword,
                  style: AppTypography.card(
                    fontSize: 18.2,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Switch the scan radius, refresh proof, and watch this keyword move from discoverable to visible to map-pack strength.',
                  style: AppTypography.body(
                    fontSize: 12.8,
                    color: const Color(0xFF68778F),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InlineButton(
                        label:
                            controller.checkingKeywordId.value ==
                                selectedKeyword!.id
                            ? 'Scanning...'
                            : 'Scan now',
                        icon:
                            controller.checkingKeywordId.value ==
                                selectedKeyword!.id
                            ? Icons.hourglass_top_rounded
                            : Icons.sync_rounded,
                        filled: true,
                        onTap:
                            controller.checkingKeywordId.value ==
                                selectedKeyword!.id
                            ? null
                            : () => onScanKeyword(selectedKeyword!.id),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniMetricCard(
                        label: 'Current proof',
                        value: _rankLabel(selectedKeyword!),
                        tone: _qualitySurface(selectedKeyword!.rankingQuality),
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            key: proofSummaryKey,
            title: 'Proof summary',
            eyebrow: 'verified proof vs estimates',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KeywordProofStrip(keyword: selectedKeyword!),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MiniMetricCard(
                        label: 'Maps rank',
                        value: selectedKeyword!.latestMapsRank == null
                            ? '20+'
                            : 'Avg #${selectedKeyword!.latestMapsRank}',
                        tone: const Color(0xFFEAF2FF),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniMetricCard(
                        label: 'Coverage',
                        value: '${selectedKeyword!.geoGridCoveragePercent}%',
                        tone: const Color(0xFFEAF8F8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MiniMetricCard(
                        label: 'Strength',
                        value: '${selectedKeyword!.mapsStrength}%',
                        tone: const Color(0xFFFFF6E8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniMetricCard(
                        label: 'Priority',
                        value: '${selectedKeyword!.priorityScore}',
                        tone: const Color(0xFFEAF2FF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            key: rankingGraphKey,
            title: 'Ranking growth graph',
            eyebrow: 'lower is better',
            child: _HistoryStrip(
              history: controller.rankingHistory,
              days: controller.rankHistoryDays.value,
              onDaysChanged: controller.setRankHistoryDays,
              keyword: selectedKeyword!,
              radiusKm: controller.selectedRadiusKm.value,
              keywords: controller.keywords,
              onKeywordChanged: controller.selectKeyword,
              onRadiusChanged: controller.setRadiusKm,
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            key: recommendationsKey,
            title: 'What VisibloAI thinks you should do next',
            eyebrow: 'recommended actions',
            child: _RecommendationList(
              title: selectedKeyword!.keyword,
              items:
                  recommendations?.items
                      .map((item) => item.reason)
                      .take(3)
                      .toList() ??
                  selectedKeyword!.recommendations.take(3).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _SectionCard(
          key: trackedKeywordsKey,
          title: 'Tracked Keywords',
          eyebrow: 'live tracked list',
          child: controller.keywords.isEmpty
              ? const _EmptyStateCard(
                  title: 'No keywords tracked yet',
                  copy:
                      'Add your first money keyword, service + city keyword, and nearby intent keyword to begin.',
                )
              : Column(
                  children: [
                    _TrackedKeywordToolbar(controller: controller),
                    const SizedBox(height: 12),
                    if (controller.filteredTrackedKeywords.isEmpty)
                      const _EmptyStateCard(
                        title: 'No tracked keywords match these filters',
                        copy:
                            'Try a broader trust filter, clear the search, or sort differently to find the keyword you want.',
                      )
                    else
                      ...controller.filteredTrackedKeywords.map((keyword) {
                        final isSelected =
                            controller.selectedKeywordId.value == keyword.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _KeywordTrackedCard(
                            keyword: keyword,
                            selected: isSelected,
                            checking:
                                controller.checkingKeywordId.value ==
                                keyword.id,
                            deleting:
                                controller.removingKeywordId.value ==
                                keyword.id,
                            selectedRadiusKm: controller.selectedRadiusKm.value,
                            onTap: () => controller.selectKeyword(keyword.id),
                            onScan: ({radiusKm}) =>
                                onScanKeyword(keyword.id, radiusKm: radiusKm),
                            onDelete: () =>
                                controller.removeKeyword(keyword.id),
                          ),
                        );
                      }),
                  ],
                ),
        ),
      ],
    );
  }
}

class _CompetitorsTab extends StatelessWidget {
  const _CompetitorsTab({
    required this.controller,
    required this.selectedKeyword,
    required this.onDiscoverTap,
  });

  final SeoToolsController controller;
  final TrackedKeyword? selectedKeyword;
  final VoidCallback onDiscoverTap;

  @override
  Widget build(BuildContext context) {
    final insights = controller.competitorInsights.value;
    final spotlightCompetitors = controller.filteredCompetitors
        .where((competitor) => !competitor.isOwnBusiness)
        .take(3)
        .toList(growable: false);
    final competitorRows = controller.filteredCompetitors;
    final trustQuality = competitorRows.isNotEmpty
        ? competitorRows.first.rankingQuality
        : insights?.summary.quality ?? SeoRankingQuality.needsScan;
    final trustConfidence = competitorRows.isNotEmpty
        ? competitorRows.first.rankingConfidence
        : insights?.summary.confidence ?? 0;
    final trustWarning = competitorRows.isNotEmpty
        ? competitorRows.first.rankingWarning
        : insights?.summary.warning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'Competitor leaderboard',
          eyebrow: 'local threat map',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _TrustBadge(
                      quality: trustQuality,
                      confidence: trustConfidence,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 126,
                    child: _InlineButton(
                      label: controller.isLoadingCompetitors.value
                          ? 'Loading...'
                          : 'Discover',
                      icon: controller.isLoadingCompetitors.value
                          ? Icons.hourglass_top_rounded
                          : Icons.radar_rounded,
                      filled: true,
                      onTap: controller.isLoadingCompetitors.value
                          ? null
                          : onDiscoverTap,
                    ),
                  ),
                ],
              ),
              if ((trustWarning ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6E8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF8D38A)),
                  ),
                  child: Text(
                    trustWarning!,
                    style: AppTypography.body(
                      fontSize: 12.3,
                      color: const Color(0xFF9A6700),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Keyword',
                      value: selectedKeyword?.keyword ?? 'Choose one',
                      tone: const Color(0xFFEAF2FF),
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Radius',
                      value: '${controller.selectedRadiusKm.value}km',
                      tone: const Color(0xFFEAF8F8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _GraphDropdown<String>(
                      label: 'Keyword',
                      value:
                          selectedKeyword?.id ??
                          (controller.keywords.isNotEmpty
                              ? controller.keywords.first.id
                              : ''),
                      items: controller.keywords
                          .map(
                            (keyword) => DropdownMenuItem<String>(
                              value: keyword.id,
                              child: Text(
                                keyword.keyword,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          controller.selectKeyword(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 116,
                    child: _GraphDropdown<int>(
                      label: 'Radius',
                      value: controller.selectedRadiusKm.value,
                      items: const [1, 3, 5, 10]
                          .map(
                            (radius) => DropdownMenuItem<int>(
                              value: radius,
                              child: Text('${radius}km'),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          controller.setRadiusKm(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Threats',
                      value: '${insights?.summary.strongestThreatCount ?? 0}',
                      tone: const Color(0xFFFFF0F3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Outranking',
                      value: '${insights?.summary.outrankingCount ?? 0}',
                      tone: const Color(0xFFFFF6E8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Coverage leaders',
                      value: '${insights?.summary.coverageLeaders ?? 0}',
                      tone: const Color(0xFFEAF8F8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Avg coverage',
                      value: '${insights?.summary.averageCoverage ?? 0}%',
                      tone: const Color(0xFFEAF9F1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (spotlightCompetitors.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...spotlightCompetitors.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CompetitorSpotlightCard(
                competitor: entry.value,
                threatIndex: entry.key + 1,
              ),
            );
          }),
        ],
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Top competitor stories',
          eyebrow: 'who to watch',
          child: Column(
            children: [
              _InsightGroupCard(
                title: 'Strongest threats',
                color: const Color(0xFFFFF0F3),
                items:
                    insights?.strongestThreats ?? const <CompetitorInsight>[],
              ),
              const SizedBox(height: 10),
              _InsightGroupCard(
                title: 'Closest rivals',
                color: const Color(0xFFFFF6E8),
                items: insights?.closestRivals ?? const <CompetitorInsight>[],
              ),
              const SizedBox(height: 10),
              _InsightGroupCard(
                title: 'Easiest to beat',
                color: const Color(0xFFEAF8F8),
                items: insights?.easiestToBeat ?? const <CompetitorInsight>[],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Tracked competitors',
          eyebrow: 'search and manage',
          child: Column(
            children: [
              _CompetitorToolbar(controller: controller),
              const SizedBox(height: 12),
              if (controller.isLoadingCompetitors.value)
                const _LoadingInline()
              else if (controller.filteredCompetitors.isEmpty)
                const _EmptyStateCard(
                  title: 'No competitor data yet',
                  copy:
                      'Run discovery for this keyword and radius to surface the nearby businesses actually competing with you.',
                )
              else
                Column(
                  children: controller.filteredCompetitors.map((competitor) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CompetitorCard(
                        competitor: competitor,
                        pinning:
                            controller.pinningCompetitorId.value ==
                            competitor.id,
                        deleting:
                            controller.deletingCompetitorId.value ==
                            competitor.id,
                        onPin: () =>
                            controller.toggleCompetitorPin(competitor.id),
                        onDelete: () =>
                            controller.deleteCompetitor(competitor.id),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeatmapTab extends StatelessWidget {
  const _HeatmapTab({
    required this.controller,
    required this.selectedKeyword,
    required this.onGenerateTap,
    required this.heatmapCommandKey,
    required this.heatmapGridKey,
    required this.heatmapInsightsKey,
    required this.onJumpToSection,
  });

  final SeoToolsController controller;
  final TrackedKeyword? selectedKeyword;
  final VoidCallback onGenerateTap;
  final GlobalKey heatmapCommandKey;
  final GlobalKey heatmapGridKey;
  final GlobalKey heatmapInsightsKey;
  final Future<void> Function(GlobalKey key) onJumpToSection;

  @override
  Widget build(BuildContext context) {
    final summary = controller.heatmapSummary.value;
    final heatmap = controller.heatmap.value;
    final points = heatmap?.grid ?? const <HeatmapPoint>[];
    final heatmapQuality =
        summary?.quality ?? heatmap?.quality ?? SeoRankingQuality.needsScan;
    final heatmapConfidence = summary?.confidence ?? heatmap?.confidence ?? 0;
    final heatmapWarning = summary?.warning ?? heatmap?.warning;
    final heatmapActionItems = _buildHeatmapActionItems(summary);
    final hasScannedPoints = points.isNotEmpty;
    final hasAnyRankedPoint = points.any((point) => (point.rank ?? 0) > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'Jump to the key parts of the heatmap page.',
          eyebrow: 'page navigation',
          child: _PageNavigationCard(
            items: [
              _PageJumpItem(
                label: 'Local SEO Command Center',
                icon: Icons.adjust_rounded,
                onTap: () => onJumpToSection(heatmapCommandKey),
              ),
              _PageJumpItem(
                label: 'Heatmap grid',
                icon: Icons.grid_view_rounded,
                onTap: () => onJumpToSection(heatmapGridKey),
              ),
              _PageJumpItem(
                label: 'What the map is saying',
                icon: Icons.route_rounded,
                onTap: () => onJumpToSection(heatmapInsightsKey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          key: heatmapCommandKey,
          title: 'Local ranking heatmap',
          eyebrow: 'live local proof',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _TrustBadge(
                      quality: heatmapQuality,
                      confidence: heatmapConfidence,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 128,
                    child: _InlineButton(
                      label: controller.isLoadingHeatmap.value
                          ? 'Scanning...'
                          : 'Generate',
                      icon: controller.isLoadingHeatmap.value
                          ? Icons.hourglass_top_rounded
                          : Icons.grid_on_rounded,
                      filled: true,
                      onTap: controller.isLoadingHeatmap.value
                          ? null
                          : onGenerateTap,
                    ),
                  ),
                ],
              ),
              if ((heatmapWarning ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6E8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF8D38A)),
                  ),
                  child: Text(
                    heatmapWarning!,
                    style: AppTypography.body(
                      fontSize: 12.3,
                      color: const Color(0xFF9A6700),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _GraphDropdown<String>(
                      label: 'Keyword',
                      value:
                          selectedKeyword?.id ??
                          (controller.keywords.isNotEmpty
                              ? controller.keywords.first.id
                              : ''),
                      items: controller.keywords
                          .map(
                            (keyword) => DropdownMenuItem<String>(
                              value: keyword.id,
                              child: Text(
                                keyword.keyword,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          controller.selectKeyword(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 116,
                    child: _GraphDropdown<int>(
                      label: 'Radius',
                      value: controller.selectedRadiusKm.value,
                      items: const [1, 3, 5, 10]
                          .map(
                            (radius) => DropdownMenuItem<int>(
                              value: radius,
                              child: Text('${radius}km'),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          controller.setRadiusKm(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Keyword',
                      value: selectedKeyword?.keyword ?? 'Choose one',
                      tone: const Color(0xFFEAF2FF),
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Visibility',
                      value: '${summary?.visibilityScore ?? 0}',
                      tone: const Color(0xFFEAF8F8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Top 3 share',
                      value: '${summary?.summary.top3Share ?? 0}%',
                      tone: const Color(0xFFEAF9F1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Not ranked',
                      value: '${summary?.summary.notRankedShare ?? 0}%',
                      tone: const Color(0xFFFFF0F3),
                    ),
                  ),
                ],
              ),
              if (summary != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MiniMetricCard(
                        label: 'Weakest zone',
                        value: summary.summary.weakestZone.label,
                        tone: const Color(0xFFFFF6E8),
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniMetricCard(
                        label: 'Ranked points',
                        value: '${summary.summary.rankedCount}',
                        tone: const Color(0xFFEAF2FF),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          key: heatmapGridKey,
          title: 'Heatmap grid',
          eyebrow: 'easy local position view',
          child: controller.isLoadingHeatmap.value
              ? const _LoadingInline()
              : points.isEmpty
              ? const _EmptyStateCard(
                  title: 'No heatmap generated yet',
                  copy:
                      'Generate the heatmap for the selected keyword to see where you are strong, weak, or invisible nearby.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasScannedPoints && !hasAnyRankedPoint)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF6E8),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFF8D38A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scan completed, but this keyword is not visible nearby yet.',
                              style: AppTypography.label(
                                fontSize: 12.6,
                                color: const Color(0xFF9A6700),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'The heatmap is generated. The issue is ranking absence, not a broken scanner. Try a tighter radius or a stronger keyword next.',
                              style: AppTypography.body(
                                fontSize: 12.3,
                                color: const Color(0xFF9A6700),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    _HeatmapFieldMap(
                      points: points,
                      radiusKm: controller.selectedRadiusKm.value,
                      isEstimated: heatmapQuality != SeoRankingQuality.verified,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const _LegendChip(
                          label: 'Top 3',
                          color: Color(0xFFDDF8E8),
                        ),
                        const _LegendChip(
                          label: '4-10',
                          color: Color(0xFFDDF6FB),
                        ),
                        const _LegendChip(
                          label: '11-20',
                          color: Color(0xFFFFF0DA),
                        ),
                        _LegendChip(
                          label: heatmapQuality == SeoRankingQuality.verified
                              ? 'Not ranked'
                              : 'Estimate only',
                          color: Color(0xFFFFE9EE),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          key: heatmapInsightsKey,
          title: 'What the map is saying',
          eyebrow: 'location insights',
          child: summary == null
              ? const _EmptyStateCard(
                  title: 'No summary available yet',
                  copy:
                      'Generate or refresh the heatmap so VisibloAI can summarize your strongest and weakest nearby areas.',
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MiniMetricCard(
                            label: 'Strongest area',
                            value: summary.summary.strongestZone.label,
                            tone: const Color(0xFFEAF9F1),
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniMetricCard(
                            label: 'Weakest area',
                            value: summary.summary.weakestZone.label,
                            tone: const Color(0xFFFFF0F3),
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniMetricCard(
                            label: 'Top 10 reach',
                            value: '${summary.summary.top10Share}%',
                            tone: const Color(0xFFEAF2FF),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniMetricCard(
                            label: 'Top 3 share',
                            value: '${summary.summary.top3Share}%',
                            tone: const Color(0xFFEAF9F1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...heatmapActionItems.asMap().entries.map((entry) {
                      final item = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: entry.key == heatmapActionItems.length - 1
                              ? 0
                              : 10,
                        ),
                        child: _HeatmapActionCard(
                          index: entry.key + 1,
                          title: item.title,
                          copy: item.copy,
                          tone: item.tone,
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ],
    );
  }
}

class _SeoPageHeader extends StatelessWidget {
  const _SeoPageHeader({required this.title, required this.onBackTap});

  final String title;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: onBackTap,
              borderRadius: BorderRadius.circular(999),
              child: const SizedBox(
                width: 34,
                height: 34,
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 24,
                  color: AppColors.brandBlue,
                ),
              ),
            ),
          ),
          Text(
            title,
            style: AppTypography.card(
              fontSize: 23,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewHero extends StatelessWidget {
  const _OverviewHero({required this.overview, required this.location});

  final SeoOverviewResponse? overview;
  final BusinessLocationSummary? location;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFDDE8F1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0B325A),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEO Tools',
            style: AppTypography.label(
              fontSize: 11.5,
              color: const Color(0xFF22A8B5),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track rankings, pressure competitors, and improve nearby visibility from one mobile command center.',
            style: AppTypography.card(
              fontSize: 19.2,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            location == null
                ? 'Select a business location to begin.'
                : '${location!.name} • ${location!.city.isEmpty ? location!.primaryCategory : location!.city}',
            style: AppTypography.body(
              fontSize: 13.4,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Visibility',
                  value: '${overview?.localVisibilityScore ?? 0}',
                  color: const Color(0xFFEAF8F8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  label: 'Keywords',
                  value: '${overview?.keywordCount ?? 0}',
                  color: const Color(0xFFEAF2FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  label: 'Heatmap',
                  value: '${overview?.heatmapReachScore ?? 0}%',
                  color: const Color(0xFFFFF6E8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationSelectorCard extends StatelessWidget {
  const _LocationSelectorCard({
    required this.locations,
    required this.selectedLocationId,
    required this.onChanged,
  });

  final List<BusinessLocationSummary> locations;
  final String selectedLocationId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    String locationLabel(BusinessLocationSummary location) {
      final suffix = location.city.isEmpty
          ? location.primaryCategory
          : location.city;
      return '${location.name} • $suffix';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE8F1)),
      ),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: selectedLocationId.isEmpty ? null : selectedLocationId,
        decoration: InputDecoration(
          labelText: 'Business location',
          labelStyle: AppTypography.body(
            fontSize: 12.8,
            color: const Color(0xFF64748B),
          ),
          filled: true,
          fillColor: const Color(0xFFF8FBFD),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD9E5EF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD9E5EF)),
          ),
        ),
        selectedItemBuilder: (context) {
          return locations.map((location) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                locationLabel(location),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandBlue,
                ),
              ),
            );
          }).toList();
        },
        items: locations.map((location) {
          return DropdownMenuItem<String>(
            value: location.id,
            child: Text(
              locationLabel(location),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

class _SeoSectionSwitcher extends StatelessWidget {
  const _SeoSectionSwitcher({required this.activeTab, required this.onChanged});

  final SeoMobileTab activeTab;
  final ValueChanged<SeoMobileTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDE8F1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x090F2746),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEO sections',
            style: AppTypography.card(
              fontSize: 16.4,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SeoMobileTab.values.map((tab) {
                final selected = activeTab == tab;
                final title = switch (tab) {
                  SeoMobileTab.keywords => 'Keyword Ranking',
                  SeoMobileTab.competitors => 'Competitor Analysis',
                  SeoMobileTab.heatmap => 'Heatmap',
                };
                final icon = switch (tab) {
                  SeoMobileTab.keywords => Icons.query_stats_rounded,
                  SeoMobileTab.competitors => Icons.groups_2_rounded,
                  SeoMobileTab.heatmap => Icons.grid_view_rounded,
                };
                final accent = switch (tab) {
                  SeoMobileTab.keywords => const Color(0xFFEAF2FF),
                  SeoMobileTab.competitors => const Color(0xFFFFF6E8),
                  SeoMobileTab.heatmap => const Color(0xFFEAF8F8),
                };

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () => onChanged(tab),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? accent : const Color(0xFFF8FBFD),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF2DB6C4)
                              : const Color(0xFFDDE8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFBFEDEF)
                                    : const Color(0xFFDDE8F0),
                              ),
                            ),
                            child: Icon(
                              icon,
                              size: 18,
                              color: AppColors.brandBlue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTypography.label(
                                  fontSize: 12.8,
                                  color: AppColors.brandBlue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selected ? 'Open now' : 'Switch',
                                style: AppTypography.body(
                                  fontSize: 11.4,
                                  color: const Color(0xFF6B7A90),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickSectionNav extends StatelessWidget {
  const _QuickSectionNav({
    required this.activeTab,
    required this.onAddKeywordTap,
    required this.onRunCompetitorTap,
    required this.onGenerateHeatmapTap,
  });

  final SeoMobileTab activeTab;
  final VoidCallback onAddKeywordTap;
  final VoidCallback onRunCompetitorTap;
  final VoidCallback onGenerateHeatmapTap;

  @override
  Widget build(BuildContext context) {
    final actions = switch (activeTab) {
      SeoMobileTab.keywords => [
        ('Add keyword', Icons.add_chart_rounded, onAddKeywordTap),
        ('Track proof', Icons.insights_rounded, onAddKeywordTap),
        ('Plan next move', Icons.auto_awesome_rounded, onAddKeywordTap),
      ],
      SeoMobileTab.competitors => [
        ('Choose keyword', Icons.search_rounded, onRunCompetitorTap),
        ('Discover', Icons.radar_rounded, onRunCompetitorTap),
        ('Review threats', Icons.flag_outlined, onRunCompetitorTap),
      ],
      SeoMobileTab.heatmap => [
        ('Choose keyword', Icons.place_outlined, onGenerateHeatmapTap),
        ('Generate map', Icons.grid_on_rounded, onGenerateHeatmapTap),
        ('Read zones', Icons.route_rounded, onGenerateHeatmapTap),
      ],
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE8F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What to do here',
            style: AppTypography.card(
              fontSize: 18,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A simple 3-step flow so owners always know what to do next.',
            style: AppTypography.body(
              fontSize: 13.2,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          Column(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                _StepCard(
                  index: i + 1,
                  title: actions[i].$1,
                  icon: actions[i].$2,
                  onTap: actions[i].$3,
                ),
                if (i != actions.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      size: 18,
                      color: Color(0xFF94A3B8),
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

class _PageJumpItem {
  const _PageJumpItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _PageNavigationCard extends StatelessWidget {
  const _PageNavigationCard({required this.items});

  final List<_PageJumpItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This gives owners a clear map of what exists on this page so it does not feel stacked or endless.',
          style: AppTypography.body(
            fontSize: 12.8,
            color: const Color(0xFF68778F),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) {
            return InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                constraints: const BoxConstraints(minWidth: 156),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFD),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDDE8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 16, color: AppColors.brandBlue),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        item.label,
                        style: AppTypography.label(
                          fontSize: 12.2,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TrackedKeywordToolbar extends StatelessWidget {
  const _TrackedKeywordToolbar({required this.controller});

  final SeoToolsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: controller.updateTrackedKeywordSearch,
          decoration: InputDecoration(
            hintText: 'Search tracked keywords or intent',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: const Color(0xFFF8FBFD),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFD9E5EF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFD9E5EF)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GraphDropdown<SeoTrackedKeywordTrustFilter>(
                label: '',
                value: controller.trackedKeywordTrustFilter.value,
                items: SeoTrackedKeywordTrustFilter.values
                    .map(
                      (value) => DropdownMenuItem<SeoTrackedKeywordTrustFilter>(
                        value: value,
                        child: Text(_trustFilterLabel(value)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    controller.setTrackedKeywordTrustFilter(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GraphDropdown<SeoTrackedKeywordSort>(
                label: '',
                value: controller.trackedKeywordSort.value,
                items: SeoTrackedKeywordSort.values
                    .map(
                      (value) => DropdownMenuItem<SeoTrackedKeywordSort>(
                        value: value,
                        child: Text(_sortLabel(value)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    controller.setTrackedKeywordSort(value);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}    

class _CompetitorToolbar extends StatelessWidget {
  const _CompetitorToolbar({required this.controller});

  final SeoToolsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: controller.updateCompetitorSearch,
          decoration: InputDecoration(
            hintText: 'Search competitors by name or address',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: const Color(0xFFF8FBFD),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFD9E5EF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFD9E5EF)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SeoCompetitorFilter.values
              .map((filter) {
                final selected = controller.competitorFilter.value == filter;
                return InkWell(
                  onTap: () => controller.setCompetitorFilter(filter),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFEAF8F8) : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF1BA6B3)
                            : const Color(0xFFD9E5EF),
                      ),
                    ),
                    child: Text(
                      _competitorFilterLabel(filter),
                      style: AppTypography.label(
                        fontSize: 11.8,
                        color: selected
                            ? const Color(0xFF0F93A1)
                            : AppColors.brandBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.quality, required this.confidence});

  final SeoRankingQuality quality;
  final int confidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _qualitySurface(quality),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E5EF)),
      ),
      child: Row(
        children: [
          Icon(
            quality == SeoRankingQuality.verified
                ? Icons.verified_user_outlined
                : quality == SeoRankingQuality.estimated
                ? Icons.auto_graph_rounded
                : Icons.warning_amber_rounded,
            size: 16,
            color: AppColors.brandBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_qualityLabel(quality)}  $confidence%',
              style: AppTypography.label(
                fontSize: 12.2,
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.title,
    required this.eyebrow,
    required this.child,
    this.trailing,
  });

  final String title;
  final String eyebrow;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE8F1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x090F2746),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: AppTypography.label(
                        fontSize: 11.2,
                        color: const Color(0xFF22A8B5),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: AppTypography.card(
                        fontSize: 19,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _RadiusSelector extends StatelessWidget {
  const _RadiusSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const radii = <int>[1, 3, 5, 10];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE8F1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: radii.map((radius) {
          final selected = radius == value;
          return GestureDetector(
            onTap: () => onChanged(radius),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.brandBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${radius}km',
                style: AppTypography.label(
                  fontSize: 11.8,
                  color: selected ? Colors.white : AppColors.brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KeywordLane extends StatelessWidget {
  const _KeywordLane({
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.items,
    required this.selectedId,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color tone;
  final List<TrackedKeyword> items;
  final String? selectedId;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.card(
              fontSize: 16.2,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.body(
              fontSize: 12.6,
              color: const Color(0xFF68778F),
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text(
              'Nothing in this lane yet.',
              style: TextStyle(
                fontSize: 12.4,
                color: Color(0xFF748298),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...items.take(3).map((keyword) {
              final isSelected = selectedId == keyword.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onTap(keyword.id),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2DB6C4)
                            : const Color(0xFFDDE8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          keyword.keyword,
                          style: AppTypography.label(
                            fontSize: 13.4,
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _Chip(
                              label: _rankLabel(keyword),
                              color: _qualitySurface(keyword.rankingQuality),
                            ),
                            _Chip(
                              label:
                                  'Coverage ${keyword.geoGridCoveragePercent}%',
                              color: const Color(0xFFEAF8F8),
                            ),
                            _Chip(
                              label: keyword.intentType.label,
                              color: const Color(0xFFEAF2FF),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _KeywordProofStrip extends StatelessWidget {
  const _KeywordProofStrip({required this.keyword});

  final TrackedKeyword keyword;

  @override
  Widget build(BuildContext context) {
    final rank = keyword.latestMapsRank;
    final coverage = keyword.geoGridCoveragePercent;
    final markerAlign = rank == null
        ? 0.98
        : ((rank.clamp(1, 50) - 1) / 49).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proof summary',
            style: AppTypography.card(
              fontSize: 16,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'See where this keyword sits now, how much nearby map coverage you own, and whether the proof is verified or still estimated.',
            style: AppTypography.body(
              fontSize: 12.8,
              color: const Color(0xFF68778F),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDDE8F0)),
            ),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final markerLeft =
                        (constraints.maxWidth - 54) * markerAlign;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF53D18B),
                                Color(0xFF63D6E7),
                                Color(0xFFF7D053),
                                Color(0xFFF6C38F),
                                Color(0xFFF28FA9),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: markerLeft,
                          top: -10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFDDE8F0),
                              ),
                            ),
                            child: Text(
                              rank == null ? '50+' : '#$rank',
                              style: AppTypography.label(
                                fontSize: 11.4,
                                color: AppColors.brandBlue,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: const [
                    Expanded(
                      child: _ProofBand(
                        label: '1-3',
                        caption: 'map pack',
                        color: Color(0xFFDDF8E8),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _ProofBand(
                        label: '4-10',
                        caption: 'visible',
                        color: Color(0xFFDDF6FB),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _ProofBand(
                        label: '11-20',
                        caption: 'weak',
                        color: Color(0xFFFFF0DA),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _ProofBand(
                        label: '21-50',
                        caption: 'discoverable',
                        color: Color(0xFFF9E9D8),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _ProofBand(
                        label: '50+',
                        caption: 'not found',
                        color: Color(0xFFFFE9EE),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(
                      label: 'Coverage $coverage%',
                      color: const Color(0xFFEAF8F8),
                    ),
                    _Chip(
                      label:
                          keyword.rankingQuality == SeoRankingQuality.verified
                          ? 'Verified proof'
                          : 'Estimate only',
                      color: _qualitySurface(keyword.rankingQuality),
                    ),
                    _Chip(
                      label: keyword.top3CoveragePercent > 0
                          ? 'Top 3 ${keyword.top3CoveragePercent}%'
                          : 'Build top-3 proof',
                      color: const Color(0xFFEAF9F1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryStrip extends StatelessWidget {
  const _HistoryStrip({
    required this.history,
    required this.days,
    required this.onDaysChanged,
    required this.keyword,
    required this.radiusKm,
    required this.keywords,
    required this.onKeywordChanged,
    required this.onRadiusChanged,
  });

  final List<KeywordRankingPoint> history;
  final int days;
  final ValueChanged<int> onDaysChanged;
  final TrackedKeyword keyword;
  final int radiusKm;
  final List<TrackedKeyword> keywords;
  final ValueChanged<String> onKeywordChanged;
  final ValueChanged<int> onRadiusChanged;

  @override
  Widget build(BuildContext context) {
    final visibleHistory = history
        .take(8)
        .toList()
        .reversed
        .toList(growable: false);
    final latestRank = keyword.latestMapsRank;
    final bestRank = history
        .map((point) => point.mapsRank)
        .whereType<int>()
        .fold<int?>(
          null,
          (best, rank) => best == null ? rank : math.min(best, rank),
        );
    final trendLabel = (keyword.mapsTrend).isEmpty
        ? 'Stable'
        : '${keyword.mapsTrend[0].toUpperCase()}${keyword.mapsTrend.substring(1)}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Track movement from 50+ to the map pack.',
                  style: AppTypography.card(
                    fontSize: 15.6,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Wrap(
                spacing: 6,
                children: [7, 30, 90].map((value) {
                  final active = value == days;
                  return GestureDetector(
                    onTap: () => onDaysChanged(value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: active ? AppColors.brandBlue : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active
                              ? AppColors.brandBlue
                              : const Color(0xFFDDE8F0),
                        ),
                      ),
                      child: Text(
                        '${value}D',
                        style: AppTypography.label(
                          fontSize: 11.8,
                          color: active ? Colors.white : AppColors.brandBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Lower is better. Every scan becomes one checkpoint so owners can see rank 45 moving to 22, then top 10, then top 3.',
            style: AppTypography.body(
              fontSize: 12.6,
              color: const Color(0xFF68778F),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: _GraphDropdown<String>(
                  label: 'Keyword',
                  value: keyword.id,
                  items: keywords
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(
                            item.keyword,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      onKeywordChanged(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: _GraphDropdown<int>(
                  label: 'Radius',
                  value: radiusKm,
                  items: const [1, 3, 5, 10]
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text('${value}km'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      onRadiusChanged(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: _GraphDropdown<int>(
                  label: 'Interval',
                  value: days,
                  items: const [7, 30, 90]
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text(_intervalLabel(value)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      onDaysChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                label: latestRank == null ? 'Now 50+' : 'Now #$latestRank',
                color: const Color(0xFFEAF2FF),
              ),
              _Chip(
                label: bestRank == null ? 'Best --' : 'Best #$bestRank',
                color: const Color(0xFFEAF9F1),
              ),
              _Chip(label: trendLabel, color: const Color(0xFFF1F5F9)),
            ],
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            const Text(
              'Run a scan to start building proof history.',
              style: TextStyle(
                fontSize: 12.8,
                color: Color(0xFF748298),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 220,
                  child: _RankingLineChart(history: visibleHistory),
                ),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    Expanded(
                      child: _LegendChip(
                        label: '1-3 map pack',
                        color: Color(0xFFDDF8E8),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _LegendChip(
                        label: '4-10 visible',
                        color: Color(0xFFDDF6FB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Expanded(
                      child: _LegendChip(
                        label: '11-20 weak',
                        color: Color(0xFFFFF0DA),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _LegendChip(
                        label: '50+ not found',
                        color: Color(0xFFFFE9EE),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RecommendationList extends StatelessWidget {
  const _RecommendationList({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFBFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD7F0F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.card(
              fontSize: 16,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...items.take(3).toList().asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        fontSize: 11.8,
                        color: Color(0xFF1AA3AF),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: AppTypography.body(
                        fontSize: 13.4,
                        color: const Color(0xFF375172),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _KeywordTrackedCard extends StatelessWidget {
  const _KeywordTrackedCard({
    required this.keyword,
    required this.selected,
    required this.checking,
    required this.deleting,
    required this.selectedRadiusKm,
    required this.onTap,
    required this.onScan,
    required this.onDelete,
  });

  final TrackedKeyword keyword;
  final bool selected;
  final bool checking;
  final bool deleting;
  final int selectedRadiusKm;
  final VoidCallback onTap;
  final Future<void> Function({int? radiusKm}) onScan;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0FBFC) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? const Color(0xFF2DB6C4) : const Color(0xFFDDE8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    keyword.keyword,
                    style: AppTypography.card(
                      fontSize: 15.2,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: keyword.actionBucket.label,
                  color: _bucketSurface(keyword.actionBucket),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(
                  label: keyword.rankingQuality == SeoRankingQuality.verified
                      ? 'Verified ${keyword.rankingConfidence}%'
                      : _rankLabel(keyword),
                  color: _qualitySurface(keyword.rankingQuality),
                ),
                _Chip(
                  label: keyword.actionBucket.label,
                  color: _bucketSurface(keyword.actionBucket),
                ),
                _Chip(
                  label: keyword.intentType.label,
                  color: const Color(0xFFF2EAFF),
                ),
                _Chip(
                  label: 'Priority ${keyword.priorityScore}',
                  color: const Color(0xFFFFF6E8),
                ),
                _Chip(
                  label: 'Visibility ${keyword.visibilityScore}',
                  color: const Color(0xFFEAF8F8),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFD),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDDE8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan actions',
                          style: AppTypography.label(
                            fontSize: 11.2,
                            color: const Color(0xFF7A869A),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [1, 3, 5, 10]
                              .map((radius) {
                                final selectedRadius =
                                    radius == selectedRadiusKm;
                                return InkWell(
                                  onTap: checking
                                      ? null
                                      : () => onScan(radiusKm: radius),
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selectedRadius
                                          ? const Color(0xFF21A7B5)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selectedRadius
                                            ? const Color(0xFF21A7B5)
                                            : const Color(0xFFD9E5EF),
                                      ),
                                    ),
                                    child: Text(
                                      '${radius}km',
                                      style: AppTypography.label(
                                        fontSize: 11.8,
                                        color: selectedRadius
                                            ? Colors.white
                                            : AppColors.brandBlue,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                );
                              })
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 130,
                    child: _InlineButton(
                      label: checking ? 'Scanning...' : 'Scan now',
                      icon: checking
                          ? Icons.hourglass_top_rounded
                          : Icons.sync_rounded,
                      filled: true,
                      onTap: checking
                          ? null
                          : () => onScan(radiusKm: selectedRadiusKm),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Maps rank',
                    value: keyword.latestMapsRank == null
                        ? 'Avg #20+'
                        : 'Avg #${keyword.latestMapsRank}',
                    hint:
                        '${keyword.geoGridPointsFound}/${keyword.geoGridPointsChecked} pts',
                    tone: const Color(0xFFEAF2FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Coverage',
                    value: '${keyword.geoGridCoveragePercent}%',
                    hint: 'Top 3 ${keyword.top3CoveragePercent}%',
                    tone: const Color(0xFFFFF6E8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Rank change',
                    value: keyword.mapsRankChange == null
                        ? '0'
                        : '${keyword.mapsRankChange! >= 0 ? '+' : ''}${keyword.mapsRankChange}',
                    hint: keyword.lastChecked == null
                        ? 'No proof yet'
                        : 'Checked ${_timeAgo(keyword.lastChecked!)}',
                    tone: const Color(0xFFF2EAFF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Strength',
                    value: '${keyword.mapsStrength}%',
                    hint: keyword.geoGridBestRank == null
                        ? 'Build proof'
                        : 'Best #${keyword.geoGridBestRank}',
                    tone: const Color(0xFFEAF5FF),
                  ),
                ),
              ],
            ),
            if (keyword.recommendations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3FCFD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFEDEF)),
                ),
                child: Text(
                  keyword.recommendations.first,
                  style: AppTypography.body(
                    fontSize: 12.8,
                    color: const Color(0xFF66758A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InlineButton(
                    label: deleting ? 'Removing...' : 'Remove',
                    icon: Icons.delete_outline_rounded,
                    danger: true,
                    onTap: deleting ? null : onDelete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompetitorCard extends StatelessWidget {
  const _CompetitorCard({
    required this.competitor,
    required this.pinning,
    required this.deleting,
    required this.onPin,
    required this.onDelete,
  });

  final Competitor competitor;
  final bool pinning;
  final bool deleting;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDE8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CompetitorAvatar(
                name: competitor.name,
                photoUrl: competitor.photoUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      competitor.name,
                      style: AppTypography.card(
                        fontSize: 15.2,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if ((competitor.address ?? '').trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          competitor.address!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            fontSize: 12.4,
                            color: const Color(0xFF6B778C),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniMetricCard(
                  label: 'Avg rank',
                  value: competitor.averageRank == null
                      ? '20+'
                      : '#${competitor.averageRank!.toStringAsFixed(1)}',
                  tone: const Color(0xFFEAF2FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetricCard(
                  label: 'Coverage',
                  value: '${competitor.coveragePercent}%',
                  tone: const Color(0xFFFFF6E8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InlineButton(
                  label: pinning
                      ? 'Saving...'
                      : competitor.isPinned
                      ? 'Pinned'
                      : 'Pin',
                  icon: Icons.push_pin_outlined,
                  onTap: pinning ? null : onPin,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InlineButton(
                  label: deleting ? 'Removing...' : 'Remove',
                  icon: Icons.delete_outline_rounded,
                  danger: true,
                  onTap: deleting ? null : onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompetitorSpotlightCard extends StatelessWidget {
  const _CompetitorSpotlightCard({
    required this.competitor,
    required this.threatIndex,
  });

  final Competitor competitor;
  final int threatIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE8F0)),
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF8F8), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _CompetitorAvatar(
                name: competitor.name,
                photoUrl: competitor.photoUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            competitor.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.card(
                              fontSize: 16,
                              color: AppColors.brandBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          label: '#$threatIndex threat',
                          color: const Color(0xFFFFF6E8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      competitor.address ?? 'Address unavailable',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        fontSize: 12.3,
                        color: const Color(0xFF66758A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Avg rank',
                  value: competitor.averageRank == null
                      ? '—'
                      : '#${competitor.averageRank!.toStringAsFixed(1)}',
                  hint: competitor.rankingQuality == SeoRankingQuality.verified
                      ? 'local leaderboard'
                      : 'estimate only',
                  tone: const Color(0xFFEAF2FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Coverage',
                  value: '${competitor.coveragePercent}%',
                  hint:
                      '${competitor.pointsFound}/${competitor.pointsChecked} points',
                  tone: const Color(0xFFFFF6E8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightGroupCard extends StatelessWidget {
  const _InsightGroupCard({
    required this.title,
    required this.color,
    required this.items,
  });

  final String title;
  final Color color;
  final List<CompetitorInsight> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.card(
              fontSize: 15.8,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text(
              'Nothing surfaced yet for this group.',
              style: TextStyle(
                fontSize: 12.6,
                color: Color(0xFF728198),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...items.take(3).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDDE8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTypography.label(
                          fontSize: 13.6,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Chip(
                            label: 'Strength ${item.strengthScore}',
                            color: const Color(0xFFFFF6E8),
                          ),
                          _Chip(
                            label: 'Outranking ${item.outrankingShare}%',
                            color: const Color(0xFFEAF2FF),
                          ),
                          _Chip(
                            label: 'Visibility ${item.visibilityShare}%',
                            color: const Color(0xFFEAF8F8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.whyItMatters,
                        style: AppTypography.body(
                          fontSize: 12.6,
                          color: const Color(0xFF66758A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _HeatmapFieldMap extends StatelessWidget {
  const _HeatmapFieldMap({
    required this.points,
    required this.radiusKm,
    required this.isEstimated,
  });

  final List<HeatmapPoint> points;
  final int radiusKm;
  final bool isEstimated;

  @override
  Widget build(BuildContext context) {
    final maxGrid = points.fold<int>(
      3,
      (max, point) => math.max(max, math.max(point.gridX + 1, point.gridY + 1)),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFCFEFF2)),
        gradient: const LinearGradient(
          colors: [Color(0xFFF4FCFD), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.maxWidth;
            return Stack(
              children: [
                for (final percent in [0.26, 0.46, 0.66, 0.84])
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: size * percent,
                      height: size * percent,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFDDF1F4)),
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: size * 0.78,
                    height: 1,
                    color: const Color(0xFFDDF1F4),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 1,
                    height: size * 0.78,
                    color: const Color(0xFFDDF1F4),
                  ),
                ),
                const Positioned(
                  top: 4,
                  left: 0,
                  right: 0,
                  child: Center(child: _DirectionLabel('North')),
                ),
                const Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Center(child: _DirectionLabel('South')),
                ),
                const Positioned(
                  left: 4,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: _DirectionLabel('West'),
                    ),
                  ),
                ),
                const Positioned(
                  right: 4,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: _DirectionLabel('East'),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF179CA3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33179CA3),
                          blurRadius: 14,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                for (final point in points)
                  Positioned(
                    left: _heatmapPointOffset(point.gridX, maxGrid, size),
                    top: _heatmapPointOffset(point.gridY, maxGrid, size),
                    child: Transform.translate(
                      offset: const Offset(-18, -18),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _heatmapRankColor(point.rank, isEstimated),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A0F2746),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          point.rank == null
                              ? '—'
                              : isEstimated
                              ? 'Est'
                              : '#${point.rank}',
                          style: AppTypography.label(
                            fontSize: point.rank == null || !isEstimated
                                ? 10.4
                                : 9.2,
                            color: point.rank == null
                                ? const Color(0xFF7A869A)
                                : isEstimated
                                ? const Color(0xFF9A6700)
                                : Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFDDE8F0)),
                    ),
                    child: Text(
                      '$radiusKm km live scan',
                      style: AppTypography.label(
                        fontSize: 10.8,
                        color: const Color(0xFF0F93A1),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeatmapActionCard extends StatelessWidget {
  const _HeatmapActionCard({
    required this.index,
    required this.title,
    required this.copy,
    required this.tone,
  });

  final int index;
  final String title;
  final String copy;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 11.6,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1599A7),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.label(
                    fontSize: 13,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  copy,
                  style: AppTypography.body(
                    fontSize: 12.4,
                    color: const Color(0xFF66758A),
                    fontWeight: FontWeight.w600,
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.label(
          fontSize: 11.6,
          color: AppColors.brandBlue,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.label(
          fontSize: 11.6,
          color: AppColors.brandBlue,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProofBand extends StatelessWidget {
  const _ProofBand({
    required this.label,
    required this.caption,
    required this.color,
  });

  final String label;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.card(
              fontSize: 13.4,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTypography.label(
              fontSize: 9.6,
              color: const Color(0xFF7A869A),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingLineChart extends StatelessWidget {
  const _RankingLineChart({required this.history});

  final List<KeywordRankingPoint> history;

  @override
  Widget build(BuildContext context) {
    final ranks = history
        .map((point) => (point.mapsRank ?? 50).clamp(1, 50))
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 16, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDE8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _AxisLabel('#1'),
              _AxisLabel('#10'),
              _AxisLabel('#25'),
              _AxisLabel('#50'),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: _RankingLineChartPainter(ranks: ranks),
                    child: Container(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: history.map((point) {
                    return Expanded(
                      child: Text(
                        _compactDate(point.searchedAt),
                        textAlign: TextAlign.center,
                        style: AppTypography.label(
                          fontSize: 10.6,
                          color: const Color(0xFF7A869A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingLineChartPainter extends CustomPainter {
  _RankingLineChartPainter({required this.ranks});

  final List<int> ranks;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFDDE8F0)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = const Color(0xFF1D9EAD)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = const Color(0xFF1D9EAD)
      ..style = PaintingStyle.fill;

    const yMarks = <double>[1, 10, 25, 50];
    for (final mark in yMarks) {
      final dy = _rankToY(mark.toInt(), size.height);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    if (ranks.isEmpty) {
      return;
    }

    final path = Path();
    for (var i = 0; i < ranks.length; i++) {
      final x = ranks.length == 1
          ? size.width / 2
          : (size.width * i) / (ranks.length - 1);
      final y = _rankToY(ranks[i], size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    for (var i = 0; i < ranks.length; i++) {
      final x = ranks.length == 1
          ? size.width / 2
          : (size.width * i) / (ranks.length - 1);
      final y = _rankToY(ranks[i], size.height);
      canvas.drawCircle(Offset(x, y), 5.5, fillPaint..color = Colors.white);
      canvas.drawCircle(
        Offset(x, y),
        5.5,
        Paint()
          ..color = const Color(0xFF1D9EAD)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  double _rankToY(int rank, double height) {
    final clamped = rank.clamp(1, 50);
    return ((clamped - 1) / 49) * height;
  }

  @override
  bool shouldRepaint(covariant _RankingLineChartPainter oldDelegate) {
    return oldDelegate.ranks != ranks;
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.label(
        fontSize: 10.8,
        color: const Color(0xFF7A869A),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _DirectionLabel extends StatelessWidget {
  const _DirectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.label(
        fontSize: 10.5,
        color: const Color(0xFF7A869A),
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({
    required this.label,
    required this.value,
    required this.tone,
    this.compact = false,
  });

  final String label;
  final String value;
  final Color tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.label(
              fontSize: 10.8,
              color: const Color(0xFF748199),
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.card(
              fontSize: compact ? 14.2 : 18,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.hint,
    required this.tone,
  });

  final String label;
  final String value;
  final String hint;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.label(
              fontSize: 10.4,
              color: const Color(0xFF7A869A),
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.card(
              fontSize: 17,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            style: AppTypography.body(
              fontSize: 12,
              color: const Color(0xFF6B778C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GraphDropdown<T> extends StatelessWidget {
  const _GraphDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label.toUpperCase(),
            style: AppTypography.label(
              fontSize: 10.5,
              color: const Color(0xFF7A869A),
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD9E5EF)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              borderRadius: BorderRadius.circular(16),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.brandBlue,
              ),
              style: AppTypography.label(
                fontSize: 12.8,
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w800,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.label(
              fontSize: 11.2,
              color: const Color(0xFF6E7C92),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.card(
              fontSize: 18,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final int index;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDDE8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF6E8),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFCC8A0A),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDE8F0)),
              ),
              child: Icon(icon, size: 18, color: AppColors.brandBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTypography.label(
                  fontSize: 13.1,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF8FA1B9),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftActionButton extends StatelessWidget {
  const _SoftActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF8F8),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1599A7)),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.label(
                fontSize: 12.2,
                color: const Color(0xFF1599A7),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineButton extends StatelessWidget {
  const _InlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: filled
              ? AppColors.brandBlue
              : danger
              ? const Color(0xFFFFF0F3)
              : const Color(0xFFF8FBFD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: filled
                ? AppColors.brandBlue
                : danger
                ? const Color(0xFFFFCBD7)
                : const Color(0xFFDDE8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: filled
                  ? Colors.white
                  : danger
                  ? const Color(0xFFD24F6A)
                  : AppColors.brandBlue,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label(
                fontSize: 12.4,
                color: filled
                    ? Colors.white
                    : danger
                    ? const Color(0xFFD24F6A)
                    : AppColors.brandBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompetitorAvatar extends StatelessWidget {
  const _CompetitorAvatar({required this.name, required this.photoUrl});

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part.trim()[0].toUpperCase())
        .join();

    if ((photoUrl ?? '').trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          photoUrl!,
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stackTrace) =>
              _AvatarFallback(initials: initials),
        ),
      );
    }
    return _AvatarFallback(initials: initials);
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        initials.isEmpty ? 'B' : initials,
        style: AppTypography.label(
          fontSize: 16,
          color: AppColors.brandBlue,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message, required this.tone});

  final String message;
  final _BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final surface = tone == _BannerTone.error
        ? const Color(0xFFFFF0F3)
        : const Color(0xFFEFFBFB);
    final border = tone == _BannerTone.error
        ? const Color(0xFFFFCCD7)
        : const Color(0xFFD6F1F3);
    final icon = tone == _BannerTone.error
        ? Icons.error_outline_rounded
        : Icons.info_outline_rounded;
    final foreground = tone == _BannerTone.error
        ? const Color(0xFFD24F6A)
        : const Color(0xFF1297A4);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(
                fontSize: 13.2,
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.copy});

  final String title;
  final String copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.card(
              fontSize: 15.2,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            copy,
            style: AppTypography.body(
              fontSize: 12.8,
              color: const Color(0xFF68778F),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE8F1)),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 14),
          Text(
            'Loading real SEO data...',
            style: TextStyle(
              fontSize: 13.6,
              color: Color(0xFF6B778C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingInline extends StatelessWidget {
  const _LoadingInline();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.1,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Loading...',
            style: TextStyle(
              fontSize: 13.2,
              color: Color(0xFF6B778C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

enum _BannerTone { error, info }

String _rankLabel(TrackedKeyword keyword) {
  final rank = keyword.latestMapsRank;
  switch (keyword.rankingQuality) {
    case SeoRankingQuality.verified:
      return rank == null ? 'Verified' : 'Verified #$rank';
    case SeoRankingQuality.estimated:
      return 'Estimate only';
    case SeoRankingQuality.notFound:
      return 'Outside top 20';
    case SeoRankingQuality.unverified:
      return 'Needs proof';
    case SeoRankingQuality.needsScan:
      return 'Needs scan';
  }
}

Color _qualitySurface(SeoRankingQuality quality) {
  switch (quality) {
    case SeoRankingQuality.verified:
      return const Color(0xFFEAF9F1);
    case SeoRankingQuality.estimated:
      return const Color(0xFFFFF6E8);
    case SeoRankingQuality.notFound:
      return const Color(0xFFFFE9EE);
    case SeoRankingQuality.unverified:
      return const Color(0xFFFFF0F3);
    case SeoRankingQuality.needsScan:
      return const Color(0xFFEAF2FF);
  }
}

Color _bucketSurface(SeoActionBucket bucket) {
  switch (bucket) {
    case SeoActionBucket.quickWin:
      return const Color(0xFFEAF8F8);
    case SeoActionBucket.defend:
      return const Color(0xFFEAF2FF);
    case SeoActionBucket.needsAttention:
      return const Color(0xFFFFF0F3);
    case SeoActionBucket.buildFoundation:
      return const Color(0xFFFFF6E8);
    case SeoActionBucket.tracked:
      return const Color(0xFFF2F5F9);
  }
}

String _compactDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
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
  return '${months[parsed.month - 1]} ${parsed.day}';
}

String _trustFilterLabel(SeoTrackedKeywordTrustFilter filter) {
  switch (filter) {
    case SeoTrackedKeywordTrustFilter.all:
      return 'All trust levels';
    case SeoTrackedKeywordTrustFilter.verified:
      return 'Verified only';
    case SeoTrackedKeywordTrustFilter.estimated:
      return 'Estimated only';
    case SeoTrackedKeywordTrustFilter.needsProof:
      return 'Needs proof';
  }
}

String _competitorFilterLabel(SeoCompetitorFilter filter) {
  switch (filter) {
    case SeoCompetitorFilter.all:
      return 'All';
    case SeoCompetitorFilter.pinned:
      return 'Pinned';
    case SeoCompetitorFilter.top10:
      return 'Top 10';
    case SeoCompetitorFilter.highCoverage:
      return 'High coverage';
  }
}

String _sortLabel(SeoTrackedKeywordSort sort) {
  switch (sort) {
    case SeoTrackedKeywordSort.priority:
      return 'Sort by priority';
    case SeoTrackedKeywordSort.rank:
      return 'Sort by rank';
    case SeoTrackedKeywordSort.coverage:
      return 'Sort by coverage';
    case SeoTrackedKeywordSort.updated:
      return 'Sort by recent update';
    case SeoTrackedKeywordSort.alphabetical:
      return 'Sort A-Z';
  }
}

String _qualityLabel(SeoRankingQuality quality) {
  switch (quality) {
    case SeoRankingQuality.verified:
      return 'Verified';
    case SeoRankingQuality.estimated:
      return 'Estimated';
    case SeoRankingQuality.notFound:
      return 'Not found';
    case SeoRankingQuality.unverified:
      return 'Needs proof';
    case SeoRankingQuality.needsScan:
      return 'Needs scan';
  }
}

String _intervalLabel(int days) {
  switch (days) {
    case 7:
      return 'Last 7 Days';
    case 30:
      return 'Last 30 Days';
    case 90:
      return 'Last 90 Days';
    default:
      return 'Last $days Days';
  }
}

String _timeAgo(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  final now = DateTime.now();
  final difference = now.difference(parsed);
  if (difference.inDays >= 1) {
    return '${difference.inDays}d ago';
  }
  if (difference.inHours >= 1) {
    return '${difference.inHours}h ago';
  }
  if (difference.inMinutes >= 1) {
    return '${difference.inMinutes}m ago';
  }
  return 'just now';
}

double _heatmapPointOffset(int coordinate, int gridSize, double size) {
  if (gridSize <= 1) {
    return size / 2;
  }
  final fraction = coordinate / math.max(1, gridSize - 1);
  return size * (0.16 + (fraction * 0.68));
}

Color _heatmapRankColor(int? rank, bool isEstimated) {
  if (rank == null) {
    return const Color(0xFFF1F5F9);
  }
  if (isEstimated) {
    return const Color(0xFFFFF1D6);
  }
  if (rank <= 3) {
    return const Color(0xFF34C97B);
  }
  if (rank <= 10) {
    return const Color(0xFF57CDE2);
  }
  if (rank <= 20) {
    return const Color(0xFFF7C65A);
  }
  return const Color(0xFFF28FA9);
}

class _HeatmapActionItem {
  const _HeatmapActionItem({
    required this.title,
    required this.copy,
    required this.tone,
  });

  final String title;
  final String copy;
  final Color tone;
}

List<_HeatmapActionItem> _buildHeatmapActionItems(
  HeatmapSummaryResponse? summary,
) {
  if (summary == null) {
    return const [
      _HeatmapActionItem(
        title: 'Generate the first field scan',
        copy:
            'Run the heatmap for this keyword to understand real local reach around your business location.',
        tone: Color(0xFFEAF8F8),
      ),
    ];
  }

  final items = <_HeatmapActionItem>[];
  if (summary.summary.notRankedShare >= 70) {
    items.add(
      _HeatmapActionItem(
        title: 'Tighten the radius or improve keyword relevance',
        copy:
            '${summary.summary.notRankedShare}% of points are still not ranking. Try a smaller radius first, then strengthen GBP categories, website keyword alignment, and citations.',
        tone: const Color(0xFFFFF0F3),
      ),
    );
  }
  if (summary.summary.top3Share < 20) {
    items.add(
      _HeatmapActionItem(
        title: 'Build proof in the weaker zones',
        copy:
            'Top 3 share is only ${summary.summary.top3Share}%. Focus content, backlinks, and local landing page mentions around ${summary.summary.weakestZone.label}.',
        tone: const Color(0xFFFFF6E8),
      ),
    );
  }
  if (summary.summary.strongestZone.averageRank != null) {
    items.add(
      _HeatmapActionItem(
        title: 'Double down on ${summary.summary.strongestZone.label}',
        copy:
            'This is currently your best performing direction. Use it as proof that the keyword can rank and replicate those signals elsewhere.',
        tone: const Color(0xFFEAF8F8),
      ),
    );
  }
  return items.take(3).toList(growable: false);
}
