import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/widgets/app_logo.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/report_models.dart';
import '../models/test_account.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_navigation_shell.dart';
import '../widgets/auth_sidebar.dart';
import '../widgets/trend_chart.dart';

class HomeOverviewView extends GetView<OnboardingController> {
  const HomeOverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthNavigationShell(
      currentTab: AuthTab.home,
      backgroundColor: _OverviewPalette.canvas,
      floatingActionButton: _AddPostFab(),
      child: _HomeOverviewContent(),
    );
  }
}

class _HomeOverviewContent extends StatefulWidget {
  const _HomeOverviewContent();

  @override
  State<_HomeOverviewContent> createState() => _HomeOverviewContentState();
}

class _HomeOverviewContentState extends State<_HomeOverviewContent> {
  final OnboardingController controller = Get.find<OnboardingController>();
  final GlobalKey _healthSectionKey = GlobalKey();
  final GlobalKey _growthTrendSectionKey = GlobalKey();
  final GlobalKey _aiGallerySectionKey = GlobalKey();
  int _healthAnimationCycle = 1;
  int _growthTrendAnimationCycle = 1;
  bool _wasHealthVisible = false;
  bool _wasGrowthTrendVisible = false;
  ScrollDirection _lastScrollDirection = ScrollDirection.idle;
  bool _isSidebarOpen = false;
  bool _isAiGalleryDialogOpen = false;
  TrendWindow _trendWindow = TrendWindow.month;
  TrendVisualMode _trendVisualMode = TrendVisualMode.bar;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchDashboardLiveStream();
      _fetchDashboardTrends();
    });
  }

  void _fetchDashboardTrends() {
    final now = DateTime.now();
    DateTime startDate;
    switch (_trendWindow) {
      case TrendWindow.month:
        startDate = now.subtract(const Duration(days: 30));
        break;
      case TrendWindow.quarter:
        startDate = now.subtract(const Duration(days: 90));
        break;
      case TrendWindow.halfYear:
        startDate = now.subtract(const Duration(days: 180));
        break;
      case TrendWindow.year:
        startDate = now.subtract(const Duration(days: 365));
        break;
    }
    final range = DateTimeRange(start: startDate, end: now);
    controller.fetchReportsData(range);
  }

  Future<void> _scrollToAiGallery() async {
    final sectionContext = _aiGallerySectionKey.currentContext;
    if (sectionContext == null) {
      return;
    }
    await Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.1,
    );
  }

  Future<void> _openAiGalleryDialog() async {
    if (_isAiGalleryDialogOpen) {
      return;
    }

    final user = controller.currentUser.value;
    if (user == null) {
      return;
    }

    setState(() {
      _isAiGalleryDialogOpen = true;
    });

    try {
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.32),
        builder: (dialogContext) {
          return _AiLiveGalleryDialog(
            controller: controller,
            businessName: _businessName(user),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAiGalleryDialogOpen = false;
        });
      }
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    final healthVisible = _isSectionVisible(_healthSectionKey);
    final growthTrendVisible = _isSectionVisible(_growthTrendSectionKey);

    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle) {
        _lastScrollDirection = ScrollDirection.idle;
        _wasHealthVisible = healthVisible;
        _wasGrowthTrendVisible = growthTrendVisible;
        return false;
      }

      final directionChanged = notification.direction != _lastScrollDirection;
      final healthEnteredVisibleArea = healthVisible && !_wasHealthVisible;
      final growthEnteredVisibleArea =
          growthTrendVisible && !_wasGrowthTrendVisible;
      if (healthVisible && (directionChanged || healthEnteredVisibleArea) ||
          growthTrendVisible &&
              (directionChanged || growthEnteredVisibleArea)) {
        setState(() {
          if (healthVisible && (directionChanged || healthEnteredVisibleArea)) {
            _healthAnimationCycle++;
          }
          if (growthTrendVisible &&
              (directionChanged || growthEnteredVisibleArea)) {
            _growthTrendAnimationCycle++;
          }
        });
      }
      _lastScrollDirection = notification.direction;
      _wasHealthVisible = healthVisible;
      _wasGrowthTrendVisible = growthTrendVisible;
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final healthEnteredVisibleArea = healthVisible && !_wasHealthVisible;
      final growthEnteredVisibleArea =
          growthTrendVisible && !_wasGrowthTrendVisible;
      if (healthEnteredVisibleArea || growthEnteredVisibleArea) {
        setState(() {
          if (healthEnteredVisibleArea) {
            _healthAnimationCycle++;
          }
          if (growthEnteredVisibleArea) {
            _growthTrendAnimationCycle++;
          }
        });
      }
      _wasHealthVisible = healthVisible;
      _wasGrowthTrendVisible = growthTrendVisible;
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

  Future<void> _openSidebar(TestAccount user) async {
    if (_isSidebarOpen) {
      return;
    }
    setState(() => _isSidebarOpen = true);
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierLabel: 'Sidebar',
        barrierDismissible: true,
        barrierColor: const Color(0x800F2746),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          final currentRoute = Get.currentRoute;
          var isSeoToolsExpanded =
              currentRoute == AppRoutes.keywordRanking ||
              currentRoute == AppRoutes.seoCompetitors ||
              currentRoute == AppRoutes.seoHeatmap;
          var isReviewsExpanded =
              currentRoute == AppRoutes.clientReviews ||
              currentRoute == AppRoutes.reviewPoster;
          var isContentExpanded =
              currentRoute == AppRoutes.gbpPosts ||
              currentRoute == AppRoutes.gbpOffers ||
              currentRoute == AppRoutes.gbpPhotos ||
              currentRoute == AppRoutes.gbpEvents;
          var isAuditExpanded = currentRoute == AppRoutes.audit;

          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final screenWidth = MediaQuery.sizeOf(dialogContext).width;
              final sidebarWidth = math
                  .min(screenWidth - 20, math.max(screenWidth * 0.58, 232.0))
                  .toDouble();
              final safeTop = MediaQuery.paddingOf(dialogContext).top;
              final safeBottom = MediaQuery.paddingOf(dialogContext).bottom;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(dialogContext).pop(),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {},
                        child: TweenAnimationBuilder<Offset>(
                          tween: Tween(
                            begin: const Offset(-1.02, 0),
                            end: Offset.zero,
                          ),
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          builder: (context, offset, child) {
                            return FractionalTranslation(
                              translation: offset,
                              child: child,
                            );
                          },
                          child: SizedBox(
                            width: sidebarWidth,
                            height: double.infinity,
                            child: AuthSidebarPanel(
                              user: user,
                              safeTopInset: safeTop,
                              safeBottomInset: safeBottom,
                              onDashboardTap: () =>
                                  Navigator.of(dialogContext).pop(),
                              onGbpManagerTap: () {
                                Navigator.of(dialogContext).pop();
                                _navigateSidebar(AppRoutes.gbpManager);
                              },
                              onContentSectionTap: () {
                                setDialogState(() {
                                  isContentExpanded = !isContentExpanded;
                                });
                              },
                              isContentExpanded: isContentExpanded,
                              onContentPostsTap: () {
                                Navigator.of(dialogContext).pop();
                                _navigateSidebar(AppRoutes.gbpPosts);
                              },
                              onContentOffersTap: () {
                                Navigator.of(dialogContext).pop();
                                _navigateSidebar(AppRoutes.gbpOffers);
                              },
                              onContentPhotosTap: () {
                                Navigator.of(dialogContext).pop();
                                _navigateSidebar(AppRoutes.gbpPhotos);
                              },
                              onContentEventsTap: () {
                                Navigator.of(dialogContext).pop();
                                _navigateSidebar(AppRoutes.gbpEvents);
                              },
                              onReviewsTap: () {
                                setDialogState(() {
                                  isReviewsExpanded = !isReviewsExpanded;
                                });
                              },
                              isReviewsExpanded: isReviewsExpanded,
                              onReviewResponseTap: () {
                                Navigator.of(dialogContext).pop();
                                _navigateSidebar(AppRoutes.clientReviews);
                              },
                              onReviewPosterTap: () {
                                Navigator.of(dialogContext).pop();
                                _navigateSidebar(AppRoutes.reviewPoster);
                              },
                              onSeoToolsTap: () {
                                setDialogState(() {
                                  isSeoToolsExpanded = !isSeoToolsExpanded;
                                });
                              },
                              isSeoToolsExpanded: isSeoToolsExpanded,
                              onKeywordRankingTap: () {
                                Navigator.of(dialogContext).pop();
                                _navigateSidebar(AppRoutes.keywordRanking);
                              },
                              onCompetitorAnalysisTap: () {
                                Navigator.of(dialogContext).pop();
                                _navigateSidebar(AppRoutes.seoCompetitors);
                              },
                              onHeatmapTap: () {
                                Navigator.of(dialogContext).pop();
                                _navigateSidebar(AppRoutes.seoHeatmap);
                              },
                              onCitationsTap: () {
                                Navigator.of(dialogContext).pop();
                                _navigateSidebar(
                                  AppRoutes.citations,
                                  replaceCurrent: true,
                                );
                              },
                              onWebsiteBuilderTap: () {
                                Navigator.of(dialogContext).pop();
                                _navigateSidebar(AppRoutes.websiteManager);
                              },
                              onReportsTap: () {
                                Navigator.of(dialogContext).pop();
                                _navigateSidebar(
                                  AppRoutes.reports,
                                  replaceCurrent: true,
                                );
                              },
                              onAuditTap: () {
                                setDialogState(() {
                                  isAuditExpanded = !isAuditExpanded;
                                });
                              },
                              isAuditExpanded: isAuditExpanded,
                              onAuditScoreTap: () {
                                Navigator.of(dialogContext).pop();
                                _navigateSidebar(
                                  AppRoutes.audit,
                                  replaceCurrent: true,
                                  arguments: {'tab': 'health'},
                                );
                              },
                              onAuditProfileTap: () {
                                Navigator.of(dialogContext).pop();
                                _navigateSidebar(
                                  AppRoutes.audit,
                                  replaceCurrent: true,
                                  arguments: {'tab': 'profile'},
                                );
                              },
                              onAlertsTap: () {
                                Navigator.of(dialogContext).pop();
                                _navigateSidebar(AppRoutes.alerts);
                              },
                              onSettingsTap: () {
                                Navigator.of(dialogContext).pop();
                                _navigateSidebar(
                                  AppRoutes.account,
                                  replaceCurrent: true,
                                );
                              },
                              onSupportTap: () async {
                                Navigator.of(dialogContext).pop();
                                _navigateSidebar(AppRoutes.support);
                              },
                              onCollapseTap: () =>
                                  Navigator.of(dialogContext).pop(),
                              onLogoutTap: () {
                                Navigator.of(dialogContext).pop();
                                controller.logout();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSidebarOpen = false);
      }
    }
  }

  void _navigateSidebar(
    String route, {
    bool replaceCurrent = false,
    dynamic arguments,
  }) {
    if (Get.currentRoute == route) {
      // If we are already on the route but passing new arguments, we may want to handle it
      // but usually the bottom bar or GetX will handle it. We can re-route if needed.
    }
    if (replaceCurrent) {
      Get.offNamed(route, arguments: arguments);
      return;
    }
    Get.toNamed(route, arguments: arguments);
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
      final connectedProfile =
          user.backendAuthenticated || user.googleBusinessProfileConnected;
      final liveReviews = controller.liveGbpReviews;
      final reviewCount = connectedProfile
          ? liveReviews.length
          : controller.businessReviewsFor(user).length;
      final pendingReviewCount = controller.pendingBusinessReviewCount(
        user: user,
      );

      return LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 300;
          final pairSpacing = 6.0;
          final topCardGap = 8.0;
          final topSectionGap = 8.0;

          final liveLoc = controller.liveGbpLocation.value;
          int gbpHealth = 0;
          if (liveLoc != null) {
            if (liveLoc.name.isNotEmpty) gbpHealth += 20;
            if (liveLoc.formattedAddress.isNotEmpty) gbpHealth += 20;
            if (liveLoc.primaryPhone.isNotEmpty) gbpHealth += 20;
            if (liveLoc.websiteUrl.isNotEmpty) gbpHealth += 20;
            if (liveLoc.primaryCategory.isNotEmpty) gbpHealth += 20;
          } else {
            gbpHealth = 40; // Default for unverified
          }

          int totalReviews = reviewCount;
          double totalStars = connectedProfile
              ? liveReviews.fold(0.0, (sum, r) => sum + r.starRating)
              : controller
                  .businessReviewsFor(user)
                  .fold(0.0, (sum, r) => sum + r.rating);
          double avgRating = totalReviews > 0 ? totalStars / totalReviews : 0;
          int reviewScore = totalReviews > 0
              ? ((avgRating / 5) * 100).round()
              : 0;

          int citations = 0;
          int seoScore =
              ((gbpHealth * 0.4) + (reviewScore * 0.3) + (citations * 0.3))
                  .round();
          int listings = 0;

          return NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: SingleChildScrollView(
              physics: _adaptiveHomeScrollPhysics(context),
              padding: const EdgeInsets.fromLTRB(
                AuthViewSpacing.pageHorizontal,
                AuthViewSpacing.pageTop,
                AuthViewSpacing.pageHorizontal,
                AuthViewSpacing.pageBottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  _HomeOverviewHeader(onMenuTap: () => _openSidebar(user)),
                  SizedBox(height: topCardGap),
                  _BusinessSummaryCard(
                    user: user,
                    reviewCountLabel: '$reviewCount',
                    onBusinessPhotoTap: _scrollToAiGallery,
                  ),
                  const SizedBox(height: AuthViewSpacing.cardGap),
                  _BusinessQuickActionsCard(user: user),
                  SizedBox(height: topSectionGap),
                  _HealthOverviewSection(
                    key: _healthSectionKey,
                    animationCycle: _healthAnimationCycle,
                    seoScore: seoScore,
                    gbpHealth: gbpHealth,
                    citations: citations,
                    listings: listings,
                  ),
                  SizedBox(height: 6),
                  _OverviewMetricsSection(
                    isCompact: isCompact,
                    spacing: pairSpacing,
                    reviewCount: reviewCount,
                    insights: controller.liveInsights.value,
                  ),
                  const SizedBox(height: AuthViewSpacing.cardGap),
                  _ActivityTrendsCard(
                    key: _growthTrendSectionKey,
                    animationCycle: _growthTrendAnimationCycle,
                    insights: controller.liveInsights.value,
                    trendWindow: _trendWindow,
                    visualMode: _trendVisualMode,
                    onWindowSelected: (window) {
                      setState(() {
                        _trendWindow = window;
                      });
                      _fetchDashboardTrends();
                    },
                    onVisualModeChanged: (mode) {
                      setState(() {
                        _trendVisualMode = mode;
                        _growthTrendAnimationCycle++;
                      });
                    },
                  ),
                  const SizedBox(height: AuthViewSpacing.cardGap),
                  _SectionHeader(
                    title: 'AI Recommendations',
                    actionLabel: 'View all',
                    onActionTap: _openAiGalleryDialog,
                  ),
                  const SizedBox(height: AuthViewSpacing.cardGap),
                  _AiRecommendationsScroller(
                    gallerySectionKey: _aiGallerySectionKey,
                    user: user,
                    onOpenGalleryTap: _openAiGalleryDialog,
                  ),
                  const SizedBox(height: AuthViewSpacing.cardGap),
                  const _SectionHeader(title: 'Pending Actions'),
                  const SizedBox(height: AuthViewSpacing.cardGap),
                  _PendingActionsCard(
                    pendingReviewCount: pendingReviewCount,
                    onPhotoTap: _openAiGalleryDialog,
                  ),
                  const SizedBox(height: AuthViewSpacing.cardGap),
                  const _SectionHeader(
                    title: 'May 2025 Growth Summary',
                    actionLabel: 'View Report',
                    actionColor: AppColors.primary,
                  ),
                  const SizedBox(height: AuthViewSpacing.cardGap),
                  const _GrowthSummaryCard(),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

class _HomeOverviewHeader extends StatelessWidget {
  const _HomeOverviewHeader({required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return _GoogleBusinessHeroCard(onMenuTap: onMenuTap);
  }
}

class _AddPostFab extends StatelessWidget {
  const _AddPostFab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed(AppRoutes.gbpPosts),
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2239B4BD),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 34,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleBusinessHeroCard extends StatelessWidget {
  const _GoogleBusinessHeroCard({required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final isTightWidth = MediaQuery.sizeOf(context).width < 390;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(isTightWidth ? 8 : 10, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_homeCardRadius(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2746),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SidebarMenuTriggerButton(onTap: onMenuTap, isEmbedded: true),
          SizedBox(width: isTightWidth ? 8 : 10),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: _GoogleBusinessLogo(
                alignLeft: true,
                showTagline: true,
                useBrandBadgeColors: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleBusinessLogo extends StatelessWidget {
  const _GoogleBusinessLogo({
    this.alignLeft = false,
    this.showTagline = false,
    this.useBrandBadgeColors = false,
  });

  final bool alignLeft;
  final bool showTagline;
  final bool useBrandBadgeColors;

  @override
  Widget build(BuildContext context) {
    final isCompactHero = MediaQuery.sizeOf(context).width < 390;
    final googleFontSize = isCompactHero ? 24.0 : 31.0;
    final googleSubLabelSize = isCompactHero ? 11.8 : 15.5;
    final storeBadgeSize = isCompactHero ? 42.0 : 52.0;
    final brandMarkSize = isCompactHero ? 31.0 : 37.0;
    final taglineFontSize = isCompactHero ? 14.0 : 18.0;
    const taglineText = 'AI-powered visibility\nfor your GBP';

    final logoRow = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: googleFontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
                children: const [
                  TextSpan(
                    text: 'G',
                    style: TextStyle(color: Color(0xFF4285F4)),
                  ),
                  TextSpan(
                    text: 'o',
                    style: TextStyle(color: Color(0xFFEA4335)),
                  ),
                  TextSpan(
                    text: 'o',
                    style: TextStyle(color: Color(0xFFFBBC05)),
                  ),
                  TextSpan(
                    text: 'g',
                    style: TextStyle(color: Color(0xFF4285F4)),
                  ),
                  TextSpan(
                    text: 'l',
                    style: TextStyle(color: Color(0xFF34A853)),
                  ),
                  TextSpan(
                    text: 'e',
                    style: TextStyle(color: Color(0xFFEA4335)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                'My Business',
                style: TextStyle(
                  fontSize: googleSubLabelSize,
                  color: useBrandBadgeColors
                      ? const Color(0xFF1E8E99)
                      : const Color(0xFF5F6368),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 6),
        _GoogleStoreBadge(size: storeBadgeSize),
      ],
    );

    if (!showTagline) {
      return Align(
        alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
        child: logoRow,
      );
    }

    final visibloColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppLogo(iconSize: brandMarkSize),
        const SizedBox(height: 6),
        Text(
          taglineText,
          style: TextStyle(
            fontSize: taglineFontSize,
            height: 1.08,
            color: AppColors.brandBlue.withValues(alpha: 0.94),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    final brandRow = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoRow,
        SizedBox(width: isCompactHero ? 14 : 18),
        visibloColumn,
      ],
    );

    return Align(
      alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
        child: brandRow,
      ),
    );
  }
}

class _GoogleStoreBadge extends StatelessWidget {
  const _GoogleStoreBadge({this.size = 54});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.2;
    final awningHeight = size * 0.28;
    final shadowColor = const Color(0x220F2746);

    return SizedBox(
      width: size * 0.86,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF5388EE), Color(0xFF477EE7)],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: size * 0.46,
                height: size * 0.46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0x00000000), Color(0x330F2746)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: size * 0.48,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF72A2EE), Color(0xFF6B97DC)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: awningHeight,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Expanded(child: _AwningStripe(color: Color(0xFF79A5E9))),
                    Expanded(child: _AwningStripe(color: Color(0xFF4855B0))),
                    Expanded(child: _AwningStripe(color: Color(0xFF79A5E9))),
                    Expanded(child: _AwningStripe(color: Color(0xFF4855B0))),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: awningHeight,
              child: Container(
                height: size * 0.03,
                color: const Color(0x40FFFFFF),
              ),
            ),
            Positioned(
              right: size * 0.08,
              bottom: size * 0.03,
              child: Text(
                'G',
                style: TextStyle(
                  fontSize: size * 0.5,
                  height: 1,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AwningStripe extends StatelessWidget {
  const _AwningStripe({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
      ),
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({
    required this.isCompact,
    required this.first,
    required this.second,
    this.spacing = 10,
  });

  final bool isCompact;
  final Widget first;
  final Widget second;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Column(
        children: [
          first,
          SizedBox(height: spacing),
          second,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: first),
        SizedBox(width: spacing),
        Expanded(child: second),
      ],
    );
  }
}

class _OverviewMetricsSection extends StatelessWidget {
  const _OverviewMetricsSection({
    required this.isCompact,
    required this.spacing,
    required this.reviewCount,
    this.insights,
  });

  final bool isCompact;
  final double spacing;
  final int reviewCount;
  final LocationInsightsResponse? insights;

  @override
  Widget build(BuildContext context) {
    final views =
        (insights?.totals.searchImpressions ?? 0) +
        (insights?.totals.mapsImpressions ?? 0);
    final calls = insights?.totals.callClicks ?? 0;
    final websiteVisits = insights?.totals.websiteClicks ?? 0;

    String formatNum(int number) {
      return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }

    return Column(
      children: [
        _ResponsivePair(
          isCompact: isCompact,
          spacing: spacing,
          first: _MiniMetricCard(
            title: 'Google Views',
            value: formatNum(views),
            delta: '+0%', // Dynamic delta calculation can be added later
            leading: _MetricIconBubble(
              background: const Color(0xFFF6F8FE),
              child: SvgPicture.asset(
                'assets/icons/google_logo.svg',
                width: 26,
                height: 26,
              ),
            ),
          ),
          second: _MiniMetricCard(
            title: 'Calls',
            value: formatNum(calls),
            delta: '+0%',
            leading: const _MetricIconBubble(
              background: Color(0xFFEFFAF4),
              child: Icon(
                Icons.call_rounded,
                size: 24,
                color: Color(0xFF32B76B),
              ),
            ),
          ),
        ),
        SizedBox(height: spacing),
        _ResponsivePair(
          isCompact: isCompact,
          spacing: spacing,
          first: _MiniMetricCard(
            title: 'Website Visits',
            value: formatNum(websiteVisits),
            delta: '+0%',
            leading: const _MetricIconBubble(
              background: Color(0xFFF2F6FD),
              child: Icon(
                Icons.public_rounded,
                size: 20,
                color: AppColors.brandBlue,
              ),
            ),
          ),
          second: _MiniMetricCard(
            title: 'Total Reviews',
            value: formatNum(reviewCount),
            delta: '+0%',
            leading: const _MetricIconBubble(
              background: Color(0xFFFFF8DF),
              child: Icon(
                Icons.star_rounded,
                size: 24,
                color: Color(0xFFF2B211),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BusinessSummaryCard extends StatefulWidget {
  const _BusinessSummaryCard({
    required this.user,
    required this.reviewCountLabel,
    required this.onBusinessPhotoTap,
  });

  final TestAccount user;
  final String reviewCountLabel;
  final VoidCallback onBusinessPhotoTap;

  @override
  State<_BusinessSummaryCard> createState() => _BusinessSummaryCardState();
}

class _BusinessSummaryCardState extends State<_BusinessSummaryCard> {
  bool _isDetailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final reviewCountLabel = widget.reviewCountLabel;
    final mediaRadius = Radius.circular(_homeCardRadius(30));

    return Container(
      width: double.infinity,
      decoration: _sectionCardDecoration(30),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child: _BusinessPhotoTile(
                    user: user,
                    borderRadius: BorderRadius.only(topLeft: mediaRadius),
                    onTap: widget.onBusinessPhotoTap,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 1,
                  child: _BusinessMapPreviewTile(
                    user: user,
                    borderRadius: BorderRadius.only(topRight: mediaRadius),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: _businessName(user)),
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: EdgeInsetsDirectional.only(
                                  start: 8,
                                  bottom: 2,
                                ),
                                child: _BusinessVerifiedBadge(),
                              ),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: 18.8,
                          height: 1.1,
                          color: Color(0xFF08183F),
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => Get.toNamed(AppRoutes.gbpManager),
                      borderRadius: BorderRadius.circular(999),
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(4, 3, 2, 3),
                        child: Icon(
                          Icons.more_vert_rounded,
                          size: 24,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isDetailsExpanded = !_isDetailsExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(2, 3, 4, 3),
                        child: AnimatedRotation(
                          turns: _isDetailsExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: const Icon(
                            Icons.expand_more_rounded,
                            size: 29,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${_clientCategory(user)}  •  ${_clientLocationSummary(user)}',
                  style: const TextStyle(
                    fontSize: 14.4,
                    height: 1.25,
                    color: Color(0xFF5F6368),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      '4.7',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3C4043),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const _BusinessRatingStars(),
                    Text(
                      '$reviewCountLabel Google reviews',
                      style: const TextStyle(
                        fontSize: 14.2,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                _InlineBusinessDetailsSection(
                  user: user,
                  isExpanded: _isDetailsExpanded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessPhotoTile extends StatelessWidget {
  const _BusinessPhotoTile({
    required this.user,
    required this.borderRadius,
    required this.onTap,
  });

  final TestAccount user;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final customPhotoPath = user.businessPhotoPath.trim();
    final fallbackAssetPath = _businessPhotoAsset(user);
    final customPhotoFile = _safeLocalImageFile(customPhotoPath);

    final controller = Get.find<OnboardingController>();
    final livePhotos = controller.liveGbpMedia;
    final String? liveImageUrl = livePhotos.isNotEmpty
        ? livePhotos.first.googleUrl
        : null;

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (customPhotoFile != null)
                  Image.file(
                    customPhotoFile,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Image.asset(fallbackAssetPath, fit: BoxFit.cover),
                  )
                else
                  Image.asset(fallbackAssetPath, fit: BoxFit.cover),
                if (liveImageUrl != null && liveImageUrl.isNotEmpty)
                  Image.network(
                    liveImageUrl,
                    fit: BoxFit.cover,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded) return child;
                          return AnimatedOpacity(
                            opacity: frame == null ? 0 : 1,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            child: child,
                          );
                        },
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.brandBlue.withValues(alpha: 0.04),
                        Colors.black.withValues(alpha: 0.26),
                      ],
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

class _BusinessMapPreviewTile extends StatefulWidget {
  const _BusinessMapPreviewTile({
    required this.user,
    required this.borderRadius,
  });

  final TestAccount user;
  final BorderRadius borderRadius;

  @override
  State<_BusinessMapPreviewTile> createState() =>
      _BusinessMapPreviewTileState();
}

class _BusinessMapPreviewTileState extends State<_BusinessMapPreviewTile> {
  String? _staticMapUrl;

  @override
  void initState() {
    super.initState();
    _fetchMapUrl();
  }

  Future<void> _fetchMapUrl() async {
    try {
      final address = _clientLocationSummary(widget.user);
      if (address.isEmpty) return;

      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {'q': address, 'format': 'json', 'limit': 1},
        options: Options(headers: {'User-Agent': 'VisibloAI'}),
      );

      if (response.data != null &&
          response.data is List &&
          response.data.isNotEmpty) {
        final result = response.data[0];
        final lat = result['lat'];
        final lon = result['lon'];
        if (lat != null && lon != null && mounted) {
          setState(() {
            _staticMapUrl =
                'https://static-maps.yandex.ru/1.x/?l=map&pt=$lon,$lat,pm2rdm&z=13&size=450,450&lang=en_US';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching map coords: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openClientMap(widget.user),
        borderRadius: widget.borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SvgPicture.asset(
                  'assets/images/location_map_preview.svg',
                  fit: BoxFit.cover,
                ),
                if (_staticMapUrl != null)
                  Image.network(
                    _staticMapUrl!,
                    fit: BoxFit.cover,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded) return child;
                          return AnimatedOpacity(
                            opacity: frame == null ? 0 : 1,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            child: child,
                          );
                        },
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                Container(color: AppColors.primary.withValues(alpha: 0.04)),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _MapActionButton(
                    icon: Icons.directions_rounded,
                    onTap: () => _openClientMap(widget.user),
                  ),
                ),
                if (_staticMapUrl == null)
                  Positioned(
                    left: 20,
                    top: 50,
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.route_rounded,
                          size: 16,
                          color: AppColors.brandBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _clientLocationSummary(widget.user),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.2,
                              color: AppColors.brandBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.96),
            ),
          ),
          child: Icon(icon, size: 18, color: AppColors.white),
        ),
      ),
    );
  }
}

class _BusinessRatingStars extends StatelessWidget {
  const _BusinessRatingStars();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.star_rounded, size: 15, color: Color(0xFFF4B400)),
        Icon(Icons.star_rounded, size: 15, color: Color(0xFFF4B400)),
        Icon(Icons.star_rounded, size: 15, color: Color(0xFFF4B400)),
        Icon(Icons.star_rounded, size: 15, color: Color(0xFFF4B400)),
        Icon(Icons.star_half_rounded, size: 15, color: Color(0xFFF4B400)),
      ],
    );
  }
}

class _BusinessQuickActions extends StatelessWidget {
  const _BusinessQuickActions({required this.user});

  final TestAccount user;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _BusinessQuickActionChip(
              icon: Icons.grid_view_rounded,
              label: 'Overview',
              onTap: _openBusinessOverview,
            ),
            const SizedBox(width: 8),
            _BusinessQuickActionChip(
              icon: Icons.bar_chart_rounded,
              label: 'Performance',
              onTap: _openBusinessPerformance,
            ),
            const SizedBox(width: 8),
            _BusinessQuickActionChip(
              icon: Icons.star_outline_rounded,
              label: 'Reviews',
              onTap: _openClientReviews,
            ),
            const SizedBox(width: 8),
            _BusinessQuickActionChip(
              icon: Icons.share_outlined,
              label: 'Share',
              onTap: () => _shareBusinessProfile(user),
            ),
            const SizedBox(width: 8),
            _BusinessQuickActionChip(
              icon: Icons.call_outlined,
              label: 'Call',
              onTap: () => _callBusiness(user),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessQuickActionsCard extends StatelessWidget {
  const _BusinessQuickActionsCard({required this.user});

  final TestAccount user;

  @override
  Widget build(BuildContext context) {
    return _BusinessQuickActions(user: user);
  }
}

class _BusinessQuickActionChip extends StatelessWidget {
  const _BusinessQuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFEFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFD7DEE8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14.4,
                  color: Color(0xFF475467),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessVerifiedBadge extends StatelessWidget {
  const _BusinessVerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4BD7C1), Color(0xFF20B7A8)],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x6620B7A8), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2239B4BD),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.verified_rounded,
        size: 17,
        color: AppColors.white,
      ),
    );
  }
}

class _InlineBusinessDetailsSection extends StatelessWidget {
  const _InlineBusinessDetailsSection({
    required this.user,
    required this.isExpanded,
  });

  final TestAccount user;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      child: isExpanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _BusinessDetailItem(
                  label: 'Address',
                  value: _clientStreetAddress(user),
                  valueColor: AppColors.brandBlue,
                  onTap: () => _openClientMap(user),
                ),
                const SizedBox(height: 14),
                _BusinessDetailItem(
                  label: 'Phone',
                  value: _clientPhoneDisplay(user),
                  valueColor: AppColors.primaryDark,
                  onTap: () => _callBusiness(user),
                ),
                const SizedBox(height: 14),
                _BusinessHoursItem(status: _businessHoursStatus(user)),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

class _BusinessDetailItem extends StatelessWidget {
  const _BusinessDetailItem({
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF202124),
    this.onTap,
  });

  final String label;
  final String value;
  final Color valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      value,
      style: TextStyle(
        fontSize: 15,
        height: 1.45,
        color: valueColor,
        fontWeight: FontWeight.w500,
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14.5,
              color: Color(0xFF202124),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: onTap == null
              ? text
              : InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: text,
                  ),
                ),
        ),
      ],
    );
  }
}

class _BusinessHoursItem extends StatelessWidget {
  const _BusinessHoursItem({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 78,
          child: Text(
            'Hours:',
            style: TextStyle(
              fontSize: 14.5,
              color: Color(0xFF202124),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                color: Color(0xFF3C4043),
              ),
              children: [
                TextSpan(
                  text: status,
                  style: const TextStyle(
                    color: Color(0xFF188038),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: '  ·  Closes 8:30 pm'),
                const TextSpan(
                  text: '  ·  More hours',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({
    required this.title,
    required this.value,
    required this.delta,
    required this.leading,
  });

  final String title;
  final String value;
  final String delta;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight = constraints.maxWidth < 170;
        final cardHeight = isTight ? 70.0 : 74.0;
        final titleStyle = TextStyle(
          fontSize: isTight ? 11.0 : 12.0,
          height: 1.0,
          color: AppColors.text.withValues(alpha: 0.78),
          fontWeight: FontWeight.w600,
        );
        final decoration = BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(_homeCardRadius(22)),
          border: Border.all(color: const Color(0xFFF1F4F8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F2746),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        );
        final radius = BorderRadius.circular(_homeCardRadius(22));
        final content = ClipRRect(
          borderRadius: radius,
          child: Column(
            children: [
              Container(height: 3, color: AppColors.primary),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTight ? 10 : 12,
                    vertical: isTight ? 8 : 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: isTight ? 32 : 34,
                        height: isTight ? 32 : 34,
                        child: FittedBox(fit: BoxFit.contain, child: leading),
                      ),
                      SizedBox(width: isTight ? 8 : 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle,
                            ),
                            SizedBox(height: isTight ? 3 : 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 600),
                                    transitionBuilder:
                                        (
                                          Widget child,
                                          Animation<double> animation,
                                        ) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        },
                                    child: Text(
                                      value,
                                      key: ValueKey(value),
                                      style: TextStyle(
                                        fontSize: isTight ? 17.4 : 18.6,
                                        height: 1,
                                        color: AppColors.brandBlue,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: isTight ? 4 : 5),
                                  _MetricDelta(value: delta, compact: true),
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
        );

        return SizedBox(
          height: cardHeight,
          child: Container(decoration: decoration, child: content),
        );
      },
    );
  }
}

class _MetricIconBubble extends StatelessWidget {
  const _MetricIconBubble({required this.background, required this.child});

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _MetricDelta extends StatelessWidget {
  const _MetricDelta({required this.value, this.compact = false});

  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.north_east_rounded,
          size: compact ? 11 : 12,
          color: Color(0xFF23BF73),
        ),
        SizedBox(width: compact ? 0.25 : 0.75),
        Text(
          value.startsWith('+') ? value.substring(1) : value,
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            color: Color(0xFF23BF73),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActivityTrendsCard extends StatelessWidget {
  const _ActivityTrendsCard({
    super.key,
    required this.animationCycle,
    required this.insights,
    required this.trendWindow,
    required this.visualMode,
    required this.onWindowSelected,
    required this.onVisualModeChanged,
  });

  final int animationCycle;
  final LocationInsightsResponse? insights;
  final TrendWindow trendWindow;
  final TrendVisualMode visualMode;
  final ValueChanged<TrendWindow> onWindowSelected;
  final ValueChanged<TrendVisualMode> onVisualModeChanged;

  Future<void> _pickTrendWindow(BuildContext context) async {
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
                    final isSelected = window == trendWindow;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(window),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEFF3FF)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.16)
                                  : const Color(0xFFE8EDF4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : const Color(0xFFC4D0DF),
                                    width: isSelected ? 6.5 : 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  config.buttonLabel,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isSelected
                                        ? AppColors.brandBlue
                                        : const Color(0xFF4A5568),
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
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

    if (selectedWindow != null && selectedWindow != trendWindow) {
      onWindowSelected(selectedWindow);
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use a mock fallback if insights are not yet loaded or missing
    final fallback = trendWindow.config;

    final trendConfig = TrendConfigFactory.fromInsights(
      insights,
      fallback,
      trendWindow,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: _sectionCardDecoration(26),
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
                      'Activity Trends',
                      style: const TextStyle(
                        fontSize: 17,
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      trendConfig.subtitle,
                      style: const TextStyle(
                        fontSize: 12.8,
                        color: Color(0xFF7E8798),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _pickTrendWindow(context),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        trendConfig.buttonLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.brandBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedTrendChart(
            config: trendConfig,
            cycle: animationCycle,
            visualMode: visualMode,
            onVisualModeChanged: onVisualModeChanged,
          ),
        ],
      ),
    );
  }
}

class _HealthOverviewSection extends StatelessWidget {
  const _HealthOverviewSection({
    super.key,
    required this.animationCycle,
    required this.seoScore,
    required this.gbpHealth,
    required this.citations,
    required this.listings,
  });

  final int animationCycle;
  final int seoScore;
  final int gbpHealth;
  final int citations;
  final int listings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health Overview',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _HealthOverviewCard(
          animationCycle: animationCycle,
          seoScore: seoScore,
          gbpHealth: gbpHealth,
          citations: citations,
          listings: listings,
        ),
      ],
    );
  }
}

class _HealthOverviewCard extends StatelessWidget {
  const _HealthOverviewCard({
    required this.animationCycle,
    required this.seoScore,
    required this.gbpHealth,
    required this.citations,
    required this.listings,
  });

  final int animationCycle;
  final int seoScore;
  final int gbpHealth;
  final int citations;
  final int listings;

  static const _seoScoreColor = Color(0xFFCC4568);
  static const _gbpHealthColor = Color(0xFF5DC344);
  static const _citationsColor = Color(0xFFF58AD4);
  static const _listingsColor = Color(0xFF6673E0);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: _sectionCardDecoration(26),
      child: Row(
        children: [
          Expanded(
            child: _HealthCircle(
              score: '$seoScore',
              label: 'SEO Score',
              progress: seoScore / 100.0,
              color: _seoScoreColor,
              animationCycle: animationCycle,
              index: 0,
            ),
          ),
          Expanded(
            child: _HealthCircle(
              score: '$gbpHealth',
              label: 'GBP Health',
              progress: gbpHealth / 100.0,
              color: _gbpHealthColor,
              animationCycle: animationCycle,
              index: 1,
            ),
          ),
          Expanded(
            child: _HealthCircle(
              score: '$citations',
              label: 'Citations',
              progress: citations == 0 ? 0 : citations / 100.0,
              color: _citationsColor,
              animationCycle: animationCycle,
              index: 2,
            ),
          ),
          Expanded(
            child: _HealthCircle(
              score: '$listings',
              label: 'Listings',
              progress: listings == 0 ? 0 : listings / 100.0,
              color: _listingsColor,
              animationCycle: animationCycle,
              index: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.actionColor = AppColors.brandBlue,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final Color actionColor;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    fontSize: 12.2,
                    color: actionColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AiRecommendationsScroller extends StatelessWidget {
  const _AiRecommendationsScroller({
    required this.user,
    required this.onOpenGalleryTap,
    this.gallerySectionKey,
  });

  final TestAccount user;
  final Key? gallerySectionKey;
  final VoidCallback onOpenGalleryTap;

  @override
  Widget build(BuildContext context) {
    return _AiGalleryRecommendationCard(
      key: gallerySectionKey,
      user: user,
      controller: Get.find<OnboardingController>(),
      onOpenGalleryTap: onOpenGalleryTap,
    );
  }
}

class _AiGalleryRecommendationCard extends StatelessWidget {
  const _AiGalleryRecommendationCard({
    super.key,
    required this.user,
    required this.controller,
    required this.onOpenGalleryTap,
  });

  final TestAccount user;
  final OnboardingController controller;
  final VoidCallback onOpenGalleryTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final galleryItems = _buildAiGalleryItems(
        user: user,
        controller: controller,
        minimumCount: 9,
      );
      final previewItems = galleryItems.take(9).toList(growable: false);
      final livePhotoCount = galleryItems
          .where((item) => item.isNetwork || item.isLocal)
          .length;
      final hasOverflowTile = galleryItems.length > 9;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: _sectionCardDecoration(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF4FF),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.photo_library_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Gallery',
                        style: TextStyle(
                          fontSize: 15.2,
                          color: AppColors.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your latest business photos stay visible here. Open View all to upload, add, and manage the complete gallery.',
                        style: TextStyle(
                          fontSize: 12.1,
                          height: 1.4,
                          color: AppColors.mutedText.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$livePhotoCount live',
                    style: const TextStyle(
                      fontSize: 11.4,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hasOverflowTile ? 9 : previewItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                if (hasOverflowTile && index == 8) {
                  return _AiGalleryMoreTile(
                    extraCount: galleryItems.length - 8,
                    onTap: onOpenGalleryTap,
                  );
                }

                return _AiGalleryPreviewTile(
                  item: previewItems[index],
                  onTap: onOpenGalleryTap,
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Tap any image or View all to open the full live gallery.',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: AppColors.mutedText.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _AiLiveGalleryDialog extends StatefulWidget {
  const _AiLiveGalleryDialog({
    required this.controller,
    required this.businessName,
  });

  final OnboardingController controller;
  final String businessName;

  @override
  State<_AiLiveGalleryDialog> createState() => _AiLiveGalleryDialogState();
}

class _AiLiveGalleryDialogState extends State<_AiLiveGalleryDialog> {
  bool _isUploadingPhotos = false;
  String? _busyPhotoPath;
  String? _busyAssetPath;

  bool get _isWorking =>
      _isUploadingPhotos || _busyPhotoPath != null || _busyAssetPath != null;

  Future<void> _uploadPhotos() async {
    if (_isWorking) {
      return;
    }

    setState(() {
      _isUploadingPhotos = true;
    });

    try {
      final addedCount = await widget.controller
          .pickAndAddBusinessGalleryPhotos();
      if (!mounted || addedCount == 0) {
        return;
      }

      final message = addedCount == 1
          ? '1 gallery photo was added and is ready to use.'
          : '$addedCount gallery photos were added and are ready to use.';
      _showHomeSnack(
        title: 'Photos added',
        message: message,
        icon: Icons.photo_library_outlined,
        accent: AppColors.brandBlue,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showHomeSnack(
        title: 'Upload failed',
        message: 'The selected gallery photos could not be added right now.',
        icon: Icons.error_outline_rounded,
        accent: const Color(0xFFD95C5C),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhotos = false;
        });
      }
    }
  }

  Future<void> _setPrimaryPhoto(String photoPath) async {
    final currentUser = widget.controller.currentUser.value;
    if (_isWorking ||
        currentUser == null ||
        currentUser.businessPhotoPath.trim() == photoPath) {
      return;
    }

    setState(() {
      _busyPhotoPath = photoPath;
    });

    try {
      final wasUpdated = await widget.controller.setPrimaryBusinessPhoto(
        photoPath,
      );
      if (!mounted || !wasUpdated) {
        return;
      }

      _showHomeSnack(
        title: 'Photo updated',
        message:
            'The business profile photo for ${widget.businessName} was updated successfully.',
        icon: Icons.photo_camera_back_outlined,
        accent: AppColors.primary,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showHomeSnack(
        title: 'Update failed',
        message: 'The selected gallery photo could not be used right now.',
        icon: Icons.error_outline_rounded,
        accent: const Color(0xFFD95C5C),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyPhotoPath = null;
        });
      }
    }
  }

  Future<void> _useSamplePhoto(String assetPath) async {
    if (_isWorking) {
      return;
    }

    setState(() {
      _busyAssetPath = assetPath;
    });

    try {
      final wasSaved = await widget.controller.saveBusinessPhotoFromAsset(
        assetPath,
      );
      if (!mounted || !wasSaved) {
        return;
      }

      _showHomeSnack(
        title: 'Photo added',
        message:
            'A sample photo was added for ${widget.businessName} and set as the current profile image.',
        icon: Icons.photo_library_outlined,
        accent: AppColors.primary,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showHomeSnack(
        title: 'Add failed',
        message: 'The sample photo could not be added right now.',
        icon: Icons.error_outline_rounded,
        accent: const Color(0xFFD95C5C),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyAssetPath = null;
        });
      }
    }
  }

  Future<void> _deletePhoto(String photoPath) async {
    final currentUser = widget.controller.currentUser.value;
    if (_isWorking || currentUser == null) {
      return;
    }

    final wasCurrentPhoto = currentUser.businessPhotoPath.trim() == photoPath;
    setState(() {
      _busyPhotoPath = photoPath;
    });

    try {
      final wasDeleted = await widget.controller.deleteBusinessGalleryPhoto(
        photoPath,
      );
      if (!mounted || !wasDeleted) {
        return;
      }

      _showHomeSnack(
        title: 'Photo removed',
        message: wasCurrentPhoto
            ? 'The current business photo was removed. Another uploaded photo will be used next.'
            : 'The uploaded photo was removed from your list.',
        icon: Icons.delete_outline_rounded,
        accent: const Color(0xFFD95C5C),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showHomeSnack(
        title: 'Delete failed',
        message: 'This photo could not be removed right now.',
        icon: Icons.error_outline_rounded,
        accent: const Color(0xFFD95C5C),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyPhotoPath = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentUser = widget.controller.currentUser.value;
      final galleryItems = currentUser == null
          ? const <_AiGalleryItem>[]
          : _buildAiGalleryItems(
              user: currentUser,
              controller: widget.controller,
              minimumCount: 9,
            );
      final livePhotoCount = galleryItems
          .where((item) => item.isNetwork || item.isLocal)
          .length;

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.of(context).size.height * 0.84,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.all(Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF4FF),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.photo_library_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Live Gallery',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Upload photos, add sample visuals, or tap any live image to make it the current business photo.',
                              style: TextStyle(
                                fontSize: 12.2,
                                height: 1.4,
                                color: AppColors.mutedText.withValues(
                                  alpha: 0.92,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$livePhotoCount live photos',
                          style: const TextStyle(
                            fontSize: 11.8,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'Centered gallery manager',
                        style: TextStyle(
                          fontSize: 11.8,
                          color: AppColors.mutedText.withValues(alpha: 0.84),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    physics: _adaptiveHomeScrollPhysics(context),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: galleryItems.length + 1,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.92,
                          ),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _AiAddPhotoThumb(
                            onTap: _isWorking ? null : _uploadPhotos,
                            isLoading: _isUploadingPhotos,
                          );
                        }

                        final item = galleryItems[index - 1];
                        final isBusy = item.isAsset
                            ? _busyAssetPath == item.imagePath
                            : _busyPhotoPath == item.imagePath;
                        return _AiGalleryModalPhotoTile(
                          item: item,
                          isBusy: isBusy,
                          onTap: item.isAsset
                              ? () => _useSamplePhoto(item.imagePath)
                              : () => _setPrimaryPhoto(item.imagePath),
                          onDelete: item.isLocal
                              ? () => _deletePhoto(item.imagePath)
                              : null,
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: _AiGalleryDialogActionButton(
                          label: 'Close',
                          icon: Icons.close_rounded,
                          onTap: () => Navigator.of(context).pop(),
                          isPrimary: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AiGalleryDialogActionButton(
                          label: 'Upload Photo',
                          icon: Icons.file_upload_outlined,
                          onTap: _isWorking ? null : _uploadPhotos,
                          isPrimary: true,
                          isLoading: _isUploadingPhotos,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _AiAddPhotoThumb extends StatelessWidget {
  const _AiAddPhotoThumb({required this.onTap, required this.isLoading});

  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCE6F2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 24,
                      color: AppColors.primary,
                    ),
              const SizedBox(height: 8),
              Text(
                'Add photo',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.mutedText.withValues(alpha: 0.92),
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

class _AiGalleryPreviewTile extends StatelessWidget {
  const _AiGalleryPreviewTile({required this.item, required this.onTap});

  final _AiGalleryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.isPrimary
                  ? AppColors.primary
                  : const Color(0xFFDCE6F2),
              width: item.isPrimary ? 1.8 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(item.isPrimary ? 16 : 17),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _AiGalleryImage(item: item),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.02),
                          Colors.black.withValues(alpha: 0.26),
                        ],
                      ),
                    ),
                  ),
                ),
                if (item.isPrimary)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.48),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.badge,
                      style: const TextStyle(
                        fontSize: 9.6,
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
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

class _AiGalleryMoreTile extends StatelessWidget {
  const _AiGalleryMoreTile({required this.extraCount, required this.onTap});

  final int extraCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFFF2F6FC),
            border: Border.all(color: const Color(0xFFDCE6F2)),
          ),
          child: Center(
            child: Text(
              '+$extraCount',
              style: const TextStyle(
                fontSize: 24,
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AiGalleryModalPhotoTile extends StatelessWidget {
  const _AiGalleryModalPhotoTile({
    required this.item,
    required this.isBusy,
    required this.onTap,
    required this.onDelete,
  });

  final _AiGalleryItem item;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isBusy ? null : onTap,
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: item.isPrimary
                        ? AppColors.primary
                        : const Color(0xFFDCE6F2),
                    width: item.isPrimary ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(item.isPrimary ? 16 : 17),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _AiGalleryImage(item: item),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.55),
                            ],
                            stops: const [0.5, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.badge,
                            style: const TextStyle(
                              fontSize: 9.6,
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.2,
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.isAsset
                                  ? 'Tap to add this sample to your live gallery'
                                  : (item.isPrimary
                                        ? 'Current profile photo'
                                        : 'Tap to make this your main photo'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.6,
                                height: 1.28,
                                color: AppColors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.isPrimary)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      if (isBusy)
                        Container(
                          color: Colors.black.withValues(alpha: 0.3),
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (onDelete != null)
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isBusy ? null : onDelete,
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.54),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AiGalleryImage extends StatelessWidget {
  const _AiGalleryImage({required this.item});

  final _AiGalleryItem item;

  @override
  Widget build(BuildContext context) {
    if (item.isNetwork) {
      return Image.network(
        item.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFFF8FBFF),
            alignment: Alignment.center,
            child: const Icon(
              Icons.broken_image_outlined,
              size: 24,
              color: AppColors.mutedText,
            ),
          );
        },
      );
    }

    if (item.isAsset) {
      return Image.asset(item.imagePath, fit: BoxFit.cover);
    }

    final localFile = _safeLocalImageFile(item.imagePath);
    if (localFile == null) {
      return Container(
        color: const Color(0xFFF8FBFF),
        alignment: Alignment.center,
        child: const Icon(
          Icons.broken_image_outlined,
          size: 24,
          color: AppColors.mutedText,
        ),
      );
    }

    return Image.file(
      localFile,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFFF8FBFF),
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            size: 24,
            color: AppColors.mutedText,
          ),
        );
      },
    );
  }
}

class _AiGalleryDialogActionButton extends StatelessWidget {
  const _AiGalleryDialogActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isPrimary,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      gradient: isPrimary
          ? const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
            )
          : null,
      color: isPrimary ? null : const Color(0xFFF5F8FD),
      borderRadius: BorderRadius.circular(16),
      border: isPrimary ? null : Border.all(color: const Color(0xFFD5E1EF)),
      boxShadow: isPrimary
          ? const [
              BoxShadow(
                color: Color(0x2239B4BD),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ]
          : null,
    );

    final foregroundColor = isPrimary ? AppColors.white : AppColors.text;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 52,
          decoration: decoration,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.white,
                  ),
                )
              else
                Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.2,
                  color: foregroundColor,
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

class _AiGalleryItem {
  const _AiGalleryItem({
    required this.imagePath,
    required this.title,
    required this.badge,
    required this.isAsset,
    this.isNetwork = false,
    required this.isPrimary,
  });

  final String imagePath;
  final String title;
  final String badge;
  final bool isAsset;
  final bool isNetwork;
  final bool isPrimary;

  bool get isLocal => !isAsset && !isNetwork;
}

class _AiGalleryFallbackSeed {
  const _AiGalleryFallbackSeed({
    required this.assetPath,
    required this.title,
    required this.badge,
  });

  final String assetPath;
  final String title;
  final String badge;
}

String _resolveAiGalleryActivePhotoPath(
  TestAccount user,
  List<String> uploadedPhotos,
) {
  final currentPhotoPath = user.businessPhotoPath.trim();
  if (currentPhotoPath.isNotEmpty &&
      uploadedPhotos.contains(currentPhotoPath)) {
    return currentPhotoPath;
  }
  return uploadedPhotos.isNotEmpty ? uploadedPhotos.first : '';
}

List<_AiGalleryItem> _buildAiGalleryItems({
  required TestAccount user,
  required OnboardingController controller,
  int minimumCount = 0,
}) {
  final uploadedPhotos = controller.businessPhotoGalleryFor(user);
  final activePhotoPath = _resolveAiGalleryActivePhotoPath(
    user,
    uploadedPhotos,
  );
  final resolvedBusinessName = _businessName(user);
  final items = <_AiGalleryItem>[];

  for (final media in controller.liveGbpMedia) {
    items.add(
      _AiGalleryItem(
        imagePath: media.googleUrl.isNotEmpty
            ? media.googleUrl
            : media.thumbnailUrl,
        title: media.name.split('/').last,
        badge: 'LIVE',
        isAsset: false,
        isNetwork: true,
        isPrimary: false,
      ),
    );
  }

  for (var index = 0; index < uploadedPhotos.length; index++) {
    items.add(
      _AiGalleryItem(
        imagePath: uploadedPhotos[index],
        title: index == 0
            ? resolvedBusinessName
            : '$resolvedBusinessName gallery',
        badge: uploadedPhotos[index] == activePhotoPath ? 'LIVE' : 'PHOTO',
        isAsset: false,
        isPrimary: uploadedPhotos[index] == activePhotoPath,
      ),
    );
  }

  final shouldUseSampleFallback =
      !(user.backendAuthenticated || user.googleBusinessProfileConnected);
  final sampleCount = shouldUseSampleFallback
      ? math.max(0, minimumCount - items.length)
      : 0;
  for (final seed in _kAiGalleryFallbackSeeds.take(sampleCount)) {
    items.add(
      _AiGalleryItem(
        imagePath: seed.assetPath,
        title: seed.title,
        badge: seed.badge,
        isAsset: true,
        isPrimary: false,
      ),
    );
  }
  return items;
}

const List<_AiGalleryFallbackSeed> _kAiGalleryFallbackSeeds = [
  _AiGalleryFallbackSeed(
    assetPath: 'assets/images/office.png',
    title: 'Office space',
    badge: 'SAMPLE',
  ),
  _AiGalleryFallbackSeed(
    assetPath: 'assets/images/mall.png',
    title: 'Property feature',
    badge: 'SAMPLE',
  ),
  _AiGalleryFallbackSeed(
    assetPath: 'assets/images/site.png',
    title: 'Site update',
    badge: 'SAMPLE',
  ),
  _AiGalleryFallbackSeed(
    assetPath: 'assets/images/doctor.png',
    title: 'Team moment',
    badge: 'SAMPLE',
  ),
  _AiGalleryFallbackSeed(
    assetPath: 'assets/images/flowers.png',
    title: 'Brand detail',
    badge: 'SAMPLE',
  ),
  _AiGalleryFallbackSeed(
    assetPath: 'assets/images/bakery.png',
    title: 'Customer-ready shot',
    badge: 'SAMPLE',
  ),
  _AiGalleryFallbackSeed(
    assetPath: 'assets/images/coffee.png',
    title: 'Lifestyle post',
    badge: 'SAMPLE',
  ),
  _AiGalleryFallbackSeed(
    assetPath: 'assets/images/fitness.png',
    title: 'Action visual',
    badge: 'SAMPLE',
  ),
  _AiGalleryFallbackSeed(
    assetPath: 'assets/images/makeup.png',
    title: 'Offer creative',
    badge: 'SAMPLE',
  ),
];

class _PendingActionsCard extends StatelessWidget {
  const _PendingActionsCard({
    required this.pendingReviewCount,
    required this.onPhotoTap,
  });

  final int pendingReviewCount;
  final VoidCallback onPhotoTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PendingActionRow(
          iconColor: const Color(0xFF1FAF5B),
          customIcon: SvgPicture.asset(
            'assets/icons/whatsapp_mark.svg',
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              Color(0xFF1FAF5B),
              BlendMode.srcIn,
            ),
          ),
          title: 'Respond to WhatsApp',
          subtitle: '5 new messages',
        ),
        const SizedBox(height: 12),
        _PendingActionRow(
          icon: Icons.star_rounded,
          iconColor: Color(0xFFF2A114),
          title: pendingReviewCount > 0
              ? '$pendingReviewCount reviews need reply'
              : 'Reviews are fully replied',
          subtitle: pendingReviewCount > 0
              ? 'High priority'
              : 'No pending action',
          onTap: () => _openClientReviews(
            initialFilter: pendingReviewCount > 0 ? 'needsReply' : 'all',
          ),
        ),
        const SizedBox(height: 12),
        _PendingActionRow(
          icon: Icons.image_rounded,
          iconColor: AppColors.primary,
          title: 'Add new photos',
          subtitle: 'Take or upload photos for your business profile',
          onTap: onPhotoTap,
        ),
      ],
    );
  }
}

class _GrowthSummaryCard extends StatelessWidget {
  const _GrowthSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
      decoration: _sectionCardDecoration(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 320) {
            return Wrap(
              runSpacing: 12,
              children: const [
                SizedBox(
                  width: 140,
                  child: _SummaryMetric(
                    icon: Icons.visibility_rounded,
                    iconColor: AppColors.brandBlue,
                    label: 'Visibility',
                    value: '18.5K',
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: _SummaryMetric(
                    icon: Icons.call_rounded,
                    iconColor: AppColors.primary,
                    label: 'Enquiries',
                    value: '214',
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: _SummaryMetric(
                    icon: Icons.star_rounded,
                    iconColor: Color(0xFFF2A114),
                    label: 'Reviews',
                    value: '+18',
                    valueColor: Color(0xFF2DBA77),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: _SummaryMetric(
                    icon: Icons.edit_rounded,
                    iconColor: Color(0xFF9A55F5),
                    label: 'Content',
                    value: '12',
                  ),
                ),
              ],
            );
          }

          return const Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.visibility_rounded,
                  iconColor: AppColors.brandBlue,
                  label: 'Visibility',
                  value: '18.5K',
                ),
              ),
              _SummaryDivider(),
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.call_rounded,
                  iconColor: AppColors.primary,
                  label: 'Enquiries',
                  value: '214',
                ),
              ),
              _SummaryDivider(),
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.star_rounded,
                  iconColor: Color(0xFFF2A114),
                  label: 'Reviews',
                  value: '+18',
                  valueColor: Color(0xFF2DBA77),
                ),
              ),
              _SummaryDivider(),
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.edit_rounded,
                  iconColor: Color(0xFF9A55F5),
                  label: 'Content',
                  value: '12',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HealthCircle extends StatelessWidget {
  const _HealthCircle({
    required this.score,
    required this.label,
    required this.progress,
    required this.color,
    required this.animationCycle,
    required this.index,
  });

  final String score;
  final String label;
  final double progress;
  final Color color;
  final int animationCycle;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ring = SizedBox(
      width: 60,
      height: 60,
      child: CircularProgressIndicator(
        value: progress,
        strokeWidth: 6,
        backgroundColor: const Color(0xFFEAEFF4),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );

    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                key: ValueKey('$label-$animationCycle'),
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 1200 + (index * 240)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: value * math.pi * 2,
                    child: child,
                  );
                },
                child: ring,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      score,
                      key: ValueKey(score),
                      style: TextStyle(
                        fontSize: 16,
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '/100',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.text.withValues(alpha: 0.42),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11.2,
            height: 1.35,
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

ScrollPhysics _adaptiveHomeScrollPhysics(BuildContext context) {
  final platform = Theme.of(context).platform;
  return switch (platform) {
    TargetPlatform.iOS ||
    TargetPlatform.macOS => const _GentleBouncingScrollPhysics(),
    TargetPlatform.android ||
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.windows => const ClampingScrollPhysics(),
  };
}

class _GentleBouncingScrollPhysics extends BouncingScrollPhysics {
  const _GentleBouncingScrollPhysics({super.parent})
    : super(decelerationRate: ScrollDecelerationRate.fast);

  @override
  _GentleBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _GentleBouncingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double frictionFactor(double overscrollFraction) {
    return super.frictionFactor(overscrollFraction) * 0.5;
  }

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 0.85, stiffness: 230, damping: 26);
}

BoxDecoration _sectionCardDecoration(double radius) {
  return BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(_homeCardRadius(radius)),
    boxShadow: const [
      BoxShadow(color: Color(0x120F2746), blurRadius: 22, offset: Offset(0, 8)),
    ],
  );
}

class _PendingActionRow extends StatelessWidget {
  const _PendingActionRow({
    this.icon,
    this.customIcon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  }) : assert(icon != null || customIcon != null);

  final IconData? icon;
  final Widget? customIcon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_homeCardRadius(22)),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: _sectionCardDecoration(22),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: customIcon ?? Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.2,
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.2,
                        color: iconColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFAAB3C1),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double _homeCardRadius(double radius) => radius <= 6 ? radius : 8;

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor = AppColors.text,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.2,
            color: AppColors.text.withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.8,
            color: valueColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 60, color: const Color(0xFFE8EDF4));
  }
}

Future<void> _openClientMap(TestAccount user) async {
  final query = Uri.encodeComponent(_clientMapQuery(user));
  final url = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$query',
  );
  try {
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (launched) {
      return;
    }
  } catch (_) {
    // Fall through to the shared error state below.
  }

  _showHomeSnack(
    title: 'Navigation unavailable',
    message: 'Google Maps could not be opened on this device.',
    icon: Icons.navigation_rounded,
    accent: AppColors.brandBlue,
  );
}

void _openBusinessOverview() {
  Get.toNamed(AppRoutes.gbpManager);
}

void _openBusinessPerformance() {
  Get.toNamed(AppRoutes.reports);
}

void _openClientReviews({String initialFilter = 'all'}) {
  Get.toNamed(AppRoutes.clientReviews, arguments: initialFilter);
}

Future<void> _callBusiness(TestAccount user) async {
  final phoneDigits = _clientPhoneDigits(user);
  if (phoneDigits.isEmpty) {
    _showHomeSnack(
      title: 'Calling unavailable',
      message: 'No business phone number is available for this workspace yet.',
      icon: Icons.call_outlined,
      accent: AppColors.primary,
    );
    return;
  }

  final url = Uri.parse('tel:$phoneDigits');
  try {
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (launched) {
      return;
    }
  } catch (_) {
    // Fall through to the shared error state below.
  }

  _showHomeSnack(
    title: 'Calling unavailable',
    message: 'Phone calling could not be opened on this device.',
    icon: Icons.call_outlined,
    accent: AppColors.primary,
  );
}

Future<void> _shareBusinessProfile(TestAccount user) async {
  final shareText = [
    _businessName(user),
    _clientStreetAddress(user),
    _clientPhoneDisplay(user),
  ].join('\n');

  await Clipboard.setData(ClipboardData(text: shareText));
  _showHomeSnack(
    title: 'Details copied',
    message: 'Business details were copied so you can paste and share them.',
    icon: Icons.share_outlined,
    accent: AppColors.brandBlue,
  );
}

void _showHomeSnack({
  required String title,
  required String message,
  required IconData icon,
  required Color accent,
}) {
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: AppColors.white,
    colorText: AppColors.text,
    borderRadius: 12,
    margin: const EdgeInsets.all(12),
    borderWidth: 1,
    borderColor: accent.withValues(alpha: 0.2),
    icon: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 17, color: accent),
    ),
    duration: const Duration(seconds: 2),
  );
}

String _businessName(TestAccount user) {
  final liveLoc = Get.find<OnboardingController>().liveGbpLocation.value;
  if (liveLoc != null && liveLoc.title.isNotEmpty) {
    return liveLoc.title;
  }
  if (user.businessName.trim().isNotEmpty) {
    return user.businessName.trim();
  }
  if (user.fullName.trim().isNotEmpty) {
    return user.fullName.trim();
  }
  return 'Your Business';
}

String _businessPhotoAsset(TestAccount user) {
  final category = user.categoryTitle.trim().toLowerCase();
  final industry = user.industry.trim().toLowerCase();
  final combined = '$category $industry';

  if (combined.contains('clinic') ||
      combined.contains('dentist') ||
      combined.contains('doctor') ||
      combined.contains('medical')) {
    return 'assets/images/doctor.png';
  }
  if (combined.contains('salon') ||
      combined.contains('beauty') ||
      combined.contains('parlour') ||
      combined.contains('spa')) {
    return 'assets/images/parlour.png';
  }
  if (combined.contains('bakery') || combined.contains('cake')) {
    return 'assets/images/bakery.png';
  }
  if (combined.contains('coffee') ||
      combined.contains('cafe') ||
      combined.contains('restaurant')) {
    return 'assets/images/coffee.png';
  }
  if (combined.contains('fitness') || combined.contains('gym')) {
    return 'assets/images/fitness.png';
  }
  if (combined.contains('flower')) {
    return 'assets/images/flowers.png';
  }

  return 'assets/images/office.png';
}

File? _safeLocalImageFile(String path) {
  final trimmedPath = path.trim();
  if (trimmedPath.isEmpty) {
    return null;
  }

  final file = File(trimmedPath);
  try {
    return file.existsSync() ? file : null;
  } catch (_) {
    return null;
  }
}

String _clientCategory(TestAccount user) {
  if (user.categoryTitle.trim().isNotEmpty) {
    return user.categoryTitle.trim();
  }
  if (user.industry.trim().isNotEmpty) {
    return '${user.industry.trim()} business';
  }
  return 'Software company';
}

String _clientAddress(TestAccount user) {
  if (user.streetAddress.trim().isNotEmpty) {
    return user.streetAddress.trim();
  }

  final city = user.city.trim();
  final country = user.country.trim();
  final enrichedIndianAddress = switch (city.toLowerCase()) {
    'mumbai' => 'Andheri East, Mumbai, Maharashtra, India',
    'delhi' => 'Connaught Place, New Delhi, Delhi, India',
    'bengaluru' => 'Indiranagar, Bengaluru, Karnataka, India',
    'pune' => 'Koregaon Park, Pune, Maharashtra, India',
    'hyderabad' => 'Banjara Hills, Hyderabad, Telangana, India',
    'ahmedabad' => 'Navrangpura, Ahmedabad, Gujarat, India',
    _ => null,
  };

  if (country.toLowerCase() == 'india' && enrichedIndianAddress != null) {
    return enrichedIndianAddress;
  }

  if (city.isNotEmpty && country.isNotEmpty) {
    return '$city, $country';
  }
  if (city.isNotEmpty) {
    return city;
  }
  if (country.isNotEmpty) {
    return country;
  }
  return 'Andheri East, Mumbai, India';
}

String _clientLocationSummary(TestAccount user) {
  final city = user.city.trim();
  return switch (city.toLowerCase()) {
    'mumbai' => 'Mumbai, Maharashtra',
    'delhi' => 'New Delhi, Delhi',
    'bengaluru' => 'Bengaluru, Karnataka',
    'pune' => 'Pune, Maharashtra',
    'hyderabad' => 'Hyderabad, Telangana',
    'ahmedabad' => 'Ahmedabad, Gujarat',
    _ when city.isNotEmpty => city,
    _ => 'Mumbai, Maharashtra',
  };
}

String _clientStreetAddress(TestAccount user) {
  final liveLoc = Get.find<OnboardingController>().liveGbpLocation.value;
  if (liveLoc != null && liveLoc.formattedAddress.isNotEmpty) {
    return liveLoc.formattedAddress;
  }
  if (user.streetAddress.trim().isNotEmpty) {
    return user.streetAddress.trim();
  }

  final city = user.city.trim().toLowerCase();
  return switch (city) {
    'mumbai' =>
      'Office no. 4018, 4th Floor, 1 Aerocity NIBR Corporate Park, Saki Naka, Andheri East, Mumbai, Maharashtra 400072',
    'delhi' =>
      '3rd Floor, Statesman House, Barakhamba Road, Connaught Place, New Delhi, Delhi 110001',
    'bengaluru' =>
      '211, 12th Main Road, HAL 2nd Stage, Indiranagar, Bengaluru, Karnataka 560038',
    'pune' =>
      '8th Floor, Nyati Unitree, Nagar Road, Yerawada, Pune, Maharashtra 411006',
    'hyderabad' =>
      'Level 6, NSL Centrum, Road No. 1, Banjara Hills, Hyderabad, Telangana 500034',
    'ahmedabad' =>
      '4th Floor, Mondeal Heights, SG Highway, Navrangpura, Ahmedabad, Gujarat 380009',
    _ => _clientAddress(user),
  };
}

String _clientPhoneDisplay(TestAccount user) {
  final liveLoc = Get.find<OnboardingController>().liveGbpLocation.value;
  if (liveLoc != null && liveLoc.primaryPhone.isNotEmpty) {
    return liveLoc.primaryPhone;
  }
  if (user.phoneNumber.trim().isNotEmpty) {
    return user.phoneNumber.trim();
  }

  final city = user.city.trim().toLowerCase();
  return switch (city) {
    'mumbai' => '098207 90117',
    'delhi' => '098100 44221',
    'bengaluru' => '098450 33412',
    'pune' => '097640 55123',
    'hyderabad' => '099125 66781',
    'ahmedabad' => '098240 22319',
    _ => '098207 90117',
  };
}

String _clientPhoneDigits(TestAccount user) {
  return _clientPhoneDisplay(user).replaceAll(RegExp(r'[^0-9+]'), '');
}

String _businessHoursStatus(TestAccount user) {
  final liveLoc = Get.find<OnboardingController>().liveGbpLocation.value;
  if (liveLoc != null && liveLoc.openHours.isNotEmpty) {
    return 'Open (Live)';
  }
  final timeZone = user.timeZone.trim().toLowerCase();
  if (timeZone.contains('pst') || timeZone.contains('est')) {
    return 'Open';
  }
  return 'Open';
}

String _clientMapQuery(TestAccount user) {
  return '${_businessName(user)}, ${_clientStreetAddress(user)}';
}

abstract final class _OverviewPalette {
  static const canvas = Color(0xFFF5F8FE);
}
