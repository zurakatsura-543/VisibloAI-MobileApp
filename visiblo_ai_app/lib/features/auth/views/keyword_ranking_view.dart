import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final GlobalKey _keywordRankingKey = GlobalKey();
  final GlobalKey _heatmapCommandKey = GlobalKey();
  final GlobalKey _heatmapGridKey = GlobalKey();
  final GlobalKey _heatmapInsightsKey = GlobalKey();

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
                    if (_controller.activeTab.value != SeoMobileTab.keywords)
                      _OverviewHero(
                        overview: _controller.overview.value,
                        location: selectedLocation,
                      ),
                    if (_controller.activeTab.value != SeoMobileTab.keywords)
                      const SizedBox(height: 12),
                    _LocationSelectorCard(
                      locations: _controller.locations,
                      selectedLocationId: _controller.selectedLocationId.value,
                      onChanged: _controller.selectLocation,
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
                          selectedLocation: selectedLocation,
                          selectedKeyword: selectedKeyword,
                          onAddKeywordTap: _showAddKeywordSheet,
                          onAddSuggestedKeyword: _handleKeywordAdd,
                          onScanKeyword: _handleScanKeyword,
                          onKeywordChanged: _handleKeywordSelection,
                          onRadiusChanged: _controller.setRadiusKm,
                          keywordSnapshotKey: _keywordSnapshotKey,
                          keywordRankingKey: _keywordRankingKey,
                          onChangeKeywordTap: _showKeywordPickerSheet,
                          onOpenMapTap: () =>
                              _openLocationInMaps(selectedLocation),
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

  Future<void> _handleKeywordAdd(String keyword) async {
    final cleaned = keyword.trim();
    if (cleaned.isEmpty) {
      return;
    }
    if (!await _guardKeywordCreation()) {
      return;
    }
    await _controller.addKeyword(cleaned);
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final sectionContext = _keywordRankingKey.currentContext;
    if (sectionContext != null && sectionContext.mounted) {
      await Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    }
  }

  Future<void> _handleKeywordSelection(String keywordId) async {
    await _controller.selectKeyword(keywordId);
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 140));
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
        final sheetHeight = MediaQuery.of(context).size.height * 0.82;
        return SafeArea(
          top: false,
          child: SizedBox(
            height: sheetHeight,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                22,
                20,
                22 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Search Queries',
                    style: AppTypography.card(
                      fontSize: 20,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Terms people used to find your profile',
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
                      hintText: 'Add your own keyword',
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
                        await _handleKeywordAdd(keyword);
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
                  Expanded(
                    child: suggestions.isEmpty
                        ? Text(
                            'No fresh unused suggestions are available right now. You can still add a keyword manually.',
                            style: AppTypography.body(
                              fontSize: 12.6,
                              color: const Color(0xFF7A879A),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: const Color(0xFFDDE8F0)),
                            ),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: suggestions.length,
                              separatorBuilder: (context, index) => const Divider(
                                height: 1,
                                color: Color(0xFFE8EEF4),
                              ),
                              itemBuilder: (context, index) {
                                final item = suggestions[index];
                                return InkWell(
                                  onTap: () async {
                                    Navigator.of(context).pop();
                                    await _handleKeywordAdd(item.keyword);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          child: Text(
                                            '${index + 1}',
                                            style: AppTypography.label(
                                              fontSize: 12,
                                              color: const Color(0xFF8A97AA),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.keyword,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.label(
                                              fontSize: 14,
                                              color: AppColors.brandBlue,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${item.searchVolume}',
                                          style: AppTypography.label(
                                            fontSize: 13,
                                            color: AppColors.brandBlue,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            'SEARCHES',
                                            style: AppTypography.label(
                                              fontSize: 9.8,
                                              color: const Color(0xFF7B8798),
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.4,
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showKeywordPickerSheet() async {
    final items = _controller.keywords;
    if (items.isEmpty) {
      await _showAddKeywordSheet();
      return;
    }
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change keyword',
                  style: AppTypography.card(
                    fontSize: 19,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose one of your tracked keywords to inspect its local rank.',
                  style: AppTypography.body(
                    fontSize: 13,
                    color: const Color(0xFF68778F),
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final keyword = items[index];
                      final selected =
                          _controller.selectedKeywordId.value == keyword.id;
                      return InkWell(
                        onTap: () async {
                          Navigator.of(context).pop();
                          await _handleKeywordSelection(keyword.id);
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFEAF8F8)
                                : const Color(0xFFF8FBFD),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF2DB6C4)
                                  : const Color(0xFFDDE8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
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
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _Chip(
                                          label: _rankLabel(keyword),
                                          color: _qualitySurface(
                                            keyword.rankingQuality,
                                          ),
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
                              const SizedBox(width: 10),
                              Icon(
                                selected
                                    ? Icons.check_circle_rounded
                                    : Icons.chevron_right_rounded,
                                color: selected
                                    ? const Color(0xFF21A7B5)
                                    : const Color(0xFF8FA1B9),
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
      },
    );
  }

  Future<void> _openLocationInMaps(BusinessLocationSummary? location) async {
    if (location == null) {
      return;
    }

    final parts = [
      location.name,
      location.addressLine1,
      location.city,
      location.state,
      location.postalCode,
    ].where((value) => value.trim().isNotEmpty).toList(growable: false);
    if (parts.isEmpty) {
      return;
    }

    final query = Uri.encodeComponent(parts.join(', '));
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
    required this.selectedLocation,
    required this.selectedKeyword,
    required this.onAddKeywordTap,
    required this.onAddSuggestedKeyword,
    required this.onScanKeyword,
    required this.onKeywordChanged,
    required this.onRadiusChanged,
    required this.keywordSnapshotKey,
    required this.keywordRankingKey,
    required this.onChangeKeywordTap,
    required this.onOpenMapTap,
  });

  final SeoToolsController controller;
  final BusinessLocationSummary? selectedLocation;
  final TrackedKeyword? selectedKeyword;
  final VoidCallback onAddKeywordTap;
  final ValueChanged<String> onAddSuggestedKeyword;
  final Future<void> Function(String keywordId, {int? radiusKm}) onScanKeyword;
  final ValueChanged<String> onKeywordChanged;
  final ValueChanged<int> onRadiusChanged;
  final GlobalKey keywordSnapshotKey;
  final GlobalKey keywordRankingKey;
  final Future<void> Function() onChangeKeywordTap;
  final Future<void> Function() onOpenMapTap;

  @override
  Widget build(BuildContext context) {
    final suggestedKeywords = controller.availableSuggestions.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'Keyword Ranking',
          eyebrow: 'selected keyword',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _KeywordSelectionHero(
                selectedKeyword: selectedKeyword,
                selectedLocation: selectedLocation,
                onChangeTap: onChangeKeywordTap,
                onOpenMapTap: onOpenMapTap,
              ),
              if (selectedKeyword != null) ...[
                const SizedBox(height: 14),
                _KeywordRankingSnapshot(
                  key: keywordSnapshotKey,
                  keyword: selectedKeyword!,
                  rankingHistory: controller.rankingHistory,
                  radiusKm: controller.selectedRadiusKm.value,
                  showScanButton: false,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'AI Suggested Keywords',
          eyebrow: 'quick ideas',
          trailing: _OutlineActionButton(
            label: 'Add keyword',
            icon: Icons.add_rounded,
            onTap: () async => onAddKeywordTap(),
          ),
          child: suggestedKeywords.isEmpty
              ? const _EmptyStateCard(
                  title: 'No suggestions yet',
                  copy:
                      'Add a few business keywords first and VisibloAI will suggest more local keyword ideas here.',
                )
              : Column(
                  children: [
                    ...suggestedKeywords.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FBFD),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFDDE8F0)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.keyword,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.label(
                                        fontSize: 13,
                                        color: AppColors.brandBlue,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if ((item.reason ?? '').trim().isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        item.reason!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.body(
                                          fontSize: 11.4,
                                          color: const Color(0xFF7A879A),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              _InlineButton(
                                label: 'Add',
                                icon: Icons.add_rounded,
                                filled: true,
                                onTap: () => onAddSuggestedKeyword(item.keyword),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          key: keywordRankingKey,
          title: 'Scan And Check Ranking',
          eyebrow: 'choose radius and scan',
          child: selectedKeyword == null
              ? const _EmptyStateCard(
                  title: 'Choose a keyword first',
                  copy:
                      'Pick a tracked keyword to see its rank, nearby coverage, and movement across local areas.',
                )
              : _KeywordScanActionCard(
                  keywords: controller.keywords,
                  keyword: selectedKeyword!,
                  radiusKm: controller.selectedRadiusKm.value,
                  isScanning:
                      controller.checkingKeywordId.value == selectedKeyword!.id,
                  onKeywordChanged: onKeywordChanged,
                  onRadiusChanged: onRadiusChanged,
                  onScanTap: () => onScanKeyword(selectedKeyword!.id),
                ),
        ),
      ],
    );
  }
}

class _KeywordSelectionHero extends StatelessWidget {
  const _KeywordSelectionHero({
    required this.selectedKeyword,
    required this.selectedLocation,
    required this.onChangeTap,
    required this.onOpenMapTap,
  });

  final TrackedKeyword? selectedKeyword;
  final BusinessLocationSummary? selectedLocation;
  final Future<void> Function() onChangeTap;
  final Future<void> Function() onOpenMapTap;

  @override
  Widget build(BuildContext context) {
    final locationLine = [
      selectedLocation?.city,
      selectedLocation?.state,
      selectedLocation?.postalCode,
    ].where((value) => (value ?? '').trim().isNotEmpty).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8FB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Color(0xFF21A7B5),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Keyword',
                    style: AppTypography.label(
                      fontSize: 11.6,
                      color: const Color(0xFF6C7A90),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectedKeyword?.keyword ?? 'Choose a keyword to begin',
                    style: AppTypography.card(
                      fontSize: 17.2,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _OutlineActionButton(
              label: 'Change',
              icon: Icons.swap_horiz_rounded,
              onTap: onChangeTap,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFD),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDDE8F0)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF5A6C85),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedLocation?.name ?? 'Business location',
                      style: AppTypography.label(
                        fontSize: 13.6,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (locationLine.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        locationLine,
                        style: AppTypography.body(
                          fontSize: 12.4,
                          color: const Color(0xFF6B778C),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _OutlineActionButton(
                label: 'View on Map',
                icon: Icons.map_outlined,
                onTap: onOpenMapTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeywordRankingSnapshot extends StatelessWidget {
  const _KeywordRankingSnapshot({
    super.key,
    required this.keyword,
    required this.rankingHistory,
    required this.radiusKm,
    this.showScanButton = true,
  });

  final TrackedKeyword keyword;
  final List<KeywordRankingPoint> rankingHistory;
  final int radiusKm;
  final bool showScanButton;

  @override
  Widget build(BuildContext context) {
    final liveRank = _normalizeLiveMapsRank(
      rankingHistory.isEmpty ? null : rankingHistory.first.mapsRank,
    );
    final ranks = _buildRadiusRanks(
      keyword,
      selectedRadiusKm: radiusKm,
      selectedRadiusRank: liveRank,
    );
    final averageRank =
        ranks
            .map((entry) => entry.rank)
            .whereType<int>()
            .fold<double>(0, (sum, rank) => sum + rank) /
        math.max(1, ranks.map((entry) => entry.rank).whereType<int>().length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Average Rank (lower is better)',
          style: AppTypography.label(
            fontSize: 12.2,
            color: const Color(0xFF22A8B5),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        _StaticRankingChart(ranks: ranks),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDE8F0)),
          ),
          child: Text(
            'Showing a launch-safe ranking snapshot for "${keyword.keyword}". '
            '${liveRank == null ? 'Latest ${radiusKm}km scan is not in the top 20 yet.' : 'Latest ${radiusKm}km scan rank is #$liveRank.'} '
            'Average preview rank is ${averageRank.toStringAsFixed(1)}.',
            style: AppTypography.body(
              fontSize: 12.4,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                'Rankings by Radius',
                style: AppTypography.card(
                  fontSize: 18,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              'Static preview',
              style: AppTypography.label(
                fontSize: 11.5,
                color: const Color(0xFF6C7A90),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...ranks.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RadiusRankRow(
              data: entry,
              isSelected: entry.radiusKm == radiusKm,
              showLiveData: entry.radiusKm == radiusKm,
            ),
          ),
        ),
        if (showScanButton) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _InlineButton(
              label: 'Scan now',
              icon: Icons.sync_rounded,
              filled: true,
              onTap: null,
            ),
          ),
        ],
      ],
    );
  }
}

class _KeywordScanActionCard extends StatelessWidget {
  const _KeywordScanActionCard({
    required this.keywords,
    required this.keyword,
    required this.radiusKm,
    required this.isScanning,
    required this.onKeywordChanged,
    required this.onRadiusChanged,
    required this.onScanTap,
  });

  final List<TrackedKeyword> keywords;
  final TrackedKeyword keyword;
  final int radiusKm;
  final bool isScanning;
  final ValueChanged<String> onKeywordChanged;
  final ValueChanged<int> onRadiusChanged;
  final VoidCallback onScanTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
                  'Choose keyword',
                  style: AppTypography.label(
                    fontSize: 11.6,
                    color: const Color(0xFF22A8B5),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (keywords.length > 1)
                Text(
                  '${keywords.length} tracked',
                  style: AppTypography.label(
                    fontSize: 11.2,
                    color: const Color(0xFF8A97AA),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          IgnorePointer(
            ignoring: isScanning,
            child: Opacity(
              opacity: isScanning ? 0.65 : 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDDE8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: keyword.id,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.brandBlue,
                    ),
                    items: keywords
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.id,
                            child: Text(
                              item.keyword,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label(
                                fontSize: 13.6,
                                color: AppColors.brandBlue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null && value != keyword.id) {
                        onKeywordChanged(value);
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a radius above, then run a live scan to check how this keyword ranks in your local area.',
            style: AppTypography.body(
              fontSize: 12.8,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          IgnorePointer(
            ignoring: isScanning,
            child: Opacity(
              opacity: isScanning ? 0.65 : 1,
              child: _RadiusSelector(
                value: radiusKm,
                onChanged: onRadiusChanged,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDE8F0)),
            ),
            child: Text(
              'Current scan radius: ${radiusKm}km. This scan will trigger the live ranking checker for "${keyword.keyword}".',
              style: AppTypography.body(
                fontSize: 12.4,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: _InlineButton(
              label: isScanning ? 'Scanning...' : 'Scan now',
              icon: isScanning
                  ? Icons.hourglass_top_rounded
                  : Icons.sync_rounded,
              filled: true,
              onTap: isScanning ? null : onScanTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticRankingChart extends StatelessWidget {
  const _StaticRankingChart({required this.ranks});

  final List<_RadiusRankData> ranks;

  @override
  Widget build(BuildContext context) {
    final maxRank = ranks.map((entry) => entry.rank).reduce(math.max).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE8F0)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: ranks.map((entry) {
                final heightFactor = 1 - ((entry.rank - 1) / (maxRank <= 1 ? 1 : maxRank));
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: entry.color,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          entry.displayRank,
                          style: AppTypography.label(
                            fontSize: 12.2,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 18,
                        height: 110 * heightFactor.clamp(0.18, 1.0),
                        decoration: BoxDecoration(
                          color: entry.color.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${entry.radiusKm} km',
                        style: AppTypography.label(
                          fontSize: 11.8,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.label,
                        style: AppTypography.body(
                          fontSize: 10.8,
                          color: const Color(0xFF6C7A90),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadiusRankRow extends StatelessWidget {
  const _RadiusRankRow({
    required this.data,
    required this.isSelected,
    required this.showLiveData,
  });

  final _RadiusRankData data;
  final bool isSelected;
  final bool showLiveData;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF1F8FB) : const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? const Color(0xFF2DB6C4) : const Color(0xFFDDE8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.adjust_rounded, color: data.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.radiusKm} km Radius',
                  style: AppTypography.label(
                    fontSize: 13.4,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  showLiveData ? data.label : 'Select this radius to get ranking',
                  style: AppTypography.body(
                    fontSize: 12.1,
                    color: showLiveData
                        ? data.color
                        : const Color(0xFF8A97AA),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                showLiveData ? data.displayRank : '--',
                style: AppTypography.card(
                  fontSize: 22,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                showLiveData ? '/20' : 'select',
                style: AppTypography.body(
                  fontSize: 11.5,
                  color: const Color(0xFF8A97AA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RadiusRankData {
  const _RadiusRankData({
    required this.radiusKm,
    required this.rank,
    required this.displayRank,
    required this.label,
    required this.color,
  });

  final int radiusKm;
  final int rank;
  final String displayRank;
  final String label;
  final Color color;
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDE8F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business location',
            style: AppTypography.label(
              fontSize: 11.2,
              color: const Color(0xFF6C7A90),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            isDense: true,
            initialValue: selectedLocationId.isEmpty ? null : selectedLocationId,
            style: AppTypography.body(
              fontSize: 13.2,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w700,
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.brandBlue,
            ),
            decoration: InputDecoration(
              hintText: 'Choose a business location',
              hintStyle: AppTypography.body(
                fontSize: 12.8,
                color: const Color(0xFF8B97AA),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FBFD),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFD9E5EF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFD9E5EF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2DB6C4)),
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
                      fontSize: 13.2,
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
                  style: AppTypography.body(
                    fontSize: 13,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
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

// ignore: unused_element
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

// ignore: unused_element
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

// ignore: unused_element
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

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2DB6C4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF169DAC)),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.label(
                fontSize: 12.4,
                color: const Color(0xFF169DAC),
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

List<_RadiusRankData> _buildRadiusRanks(
  TrackedKeyword keyword, {
  int? selectedRadiusKm,
  int? selectedRadiusRank,
}) {
  final averageRank =
      keyword.geoGridAverageRank?.round() ??
      keyword.latestMapsRank ??
      (21 - ((keyword.visibilityScore + keyword.mapsStrength) / 12).round())
          .clamp(3, 20);
  final bestRank =
      keyword.geoGridBestRank ??
      keyword.latestMapsRank ??
      (averageRank - ((keyword.top3CoveragePercent / 18).round())).clamp(1, 20);
  final coveragePenalty = ((100 - keyword.geoGridCoveragePercent) / 22).round();
  final strengthPenalty = ((100 - keyword.mapsStrength) / 24).round();
  final radius1 = bestRank.clamp(1, 20);
  final radius3 = averageRank.clamp(1, 20);
  final radius5 = math.max(radius3, averageRank + coveragePenalty).clamp(1, 20);
  final radius10 = math
      .max(radius5, averageRank + coveragePenalty + strengthPenalty + 1)
      .clamp(1, 20);
  final ranks = <int>[radius1, radius3, radius5, radius10];
  const colors = [
    Color(0xFF22B573),
    Color(0xFF2F80ED),
    Color(0xFFF2A100),
    Color(0xFFF04452),
  ];

  return List<_RadiusRankData>.generate(4, (index) {
    const radii = [1, 3, 5, 10];
    final radius = radii[index];
    final isSelectedRadius = selectedRadiusKm == radius;
    final resolvedRank = isSelectedRadius && selectedRadiusRank != null
        ? selectedRadiusRank
        : ranks[index];
    final resolvedLabel = isSelectedRadius && selectedRadiusRank == null
        ? 'Not in top 20'
        : _rankQualityLabel(resolvedRank);
    return _RadiusRankData(
      radiusKm: radius,
      rank: resolvedRank,
      displayRank:
          isSelectedRadius && selectedRadiusRank == null
              ? '20+'
              : '$resolvedRank',
      label: resolvedLabel,
      color: colors[index],
    );
  }, growable: false);
}

int? _normalizeLiveMapsRank(int? rank) {
  if (rank == null || rank < 1 || rank > 20) {
    return null;
  }
  return rank;
}

String _rankQualityLabel(int rank) {
  if (rank <= 3) {
    return 'Very Good';
  }
  if (rank <= 10) {
    return 'Good';
  }
  if (rank <= 15) {
    return 'Average';
  }
  return 'Needs Improvement';
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

// ignore: unused_element
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
