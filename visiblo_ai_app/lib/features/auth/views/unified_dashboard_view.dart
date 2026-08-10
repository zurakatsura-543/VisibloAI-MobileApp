import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/widgets/app_logo.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../../social/controllers/social_accounts_controller.dart';
import '../../social/controllers/social_analytics_controller.dart';
import '../../social/controllers/social_posts_controller.dart';
import '../controllers/product_mode_controller.dart';
import '../models/gbp_post.dart';
import '../models/gbp_review.dart';
import '../models/report_models.dart';
import '../models/test_account.dart';

class UnifiedDashboardView extends StatefulWidget {
  const UnifiedDashboardView({super.key});

  @override
  State<UnifiedDashboardView> createState() => _UnifiedDashboardViewState();
}

class _UnifiedDashboardViewState extends State<UnifiedDashboardView> {
  late final OnboardingController _controller =
      Get.find<OnboardingController>();
  late final ProductModeController _productModeController =
      Get.isRegistered<ProductModeController>()
      ? Get.find<ProductModeController>()
      : Get.put(ProductModeController(), permanent: true);
  late final SocialAccountsController _socialAccountsController =
      Get.isRegistered<SocialAccountsController>()
      ? Get.find<SocialAccountsController>()
      : Get.put(SocialAccountsController());
  late final SocialPostsController _socialPostsController =
      Get.isRegistered<SocialPostsController>()
      ? Get.find<SocialPostsController>()
      : Get.put(SocialPostsController());
  late final SocialAnalyticsController _socialAnalyticsController =
      Get.isRegistered<SocialAnalyticsController>()
      ? Get.find<SocialAnalyticsController>()
      : Get.put(SocialAnalyticsController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshDashboard());
  }

  Future<void> _refreshDashboard() async {
    final now = DateTime.now();
    final insightsRange = DateTimeRange(
      start: now.subtract(const Duration(days: 29)),
      end: now,
    );
    await _controller.fetchDashboardLiveStream();
    await Future.wait([
      _controller.fetchReportsData(insightsRange),
      _socialAccountsController.loadAccounts(),
      _socialPostsController.loadPosts(),
    ]);
    _socialAnalyticsController.loadIfBusinessOrRangeChanged('Last 28 days');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF29C2D6), Color(0xFF1397FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x3322A9E7),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              _productModeController.selectMode(ProductMode.googleBusiness);
              Get.toNamed(AppRoutes.gbpPosts);
            },
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 34),
          ),
        ),
      ),
      bottomNavigationBar: _CommonBottomBar(
        onDashboardTap: () {},
        onPostsTap: () {
          _productModeController.selectMode(ProductMode.googleBusiness);
          Get.toNamed(AppRoutes.gbpPosts);
        },
        onReviewsTap: () => Get.toNamed(AppRoutes.clientReviews),
        onMoreTap: () => Get.toNamed(AppRoutes.account),
      ),
      body: SafeArea(
        child: Obx(() {
          final user = _controller.currentUser.value;
          if (user == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final googlePosts = _controller.liveGbpPosts;
          final liveReviews = _controller.liveGbpReviews;
          final connectedAccounts = _socialAccountsController.accounts;
          final socialPosts = _socialPostsController.posts;
          final insights = _controller.liveInsights.value;
          final reach = _googleViews(insights);
          final unrepliedReviews = liveReviews
              .where((review) => !review.hasOwnerReply)
              .length;
          final nextScheduledSocialPost = _nextScheduledSocialPost(socialPosts);
          final activityItems = _buildActivityItems(
            googlePosts: googlePosts,
            liveReviews: liveReviews,
            socialPosts: socialPosts,
          );

          return RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DashboardHeader(
                    user: user,
                    onNotificationTap: () {
                      Get.snackbar(
                        'Notifications',
                        'New dashboard alerts will appear here.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 124,
                          child: _ModuleSummaryCard(
                            title: 'Google\nBusiness Profile',
                            subtitle: 'View profile insights',
                            statusLabel: user.googleBusinessProfileConnected
                                ? 'Active'
                                : 'Setup',
                            icon: _GoogleBusinessIcon(),
                            onTap: () {
                              _productModeController.selectMode(
                                ProductMode.googleBusiness,
                              );
                              Get.toNamed(AppRoutes.dashboard);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 124,
                          child: _ModuleSummaryCard(
                            title: 'Social\nAuto Post',
                            subtitle: nextScheduledSocialPost == null
                                ? 'Open social workspace'
                                : 'Next post ${_formatTimeOnly(nextScheduledSocialPost)}',
                            statusLabel: connectedAccounts.isNotEmpty
                                ? 'Running'
                                : 'Connect',
                            icon: const _SocialAutoPostIcon(),
                            onTap: () {
                              _productModeController.selectMode(
                                ProductMode.socialMedia,
                              );
                              Get.toNamed(AppRoutes.socialDashboard);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 150,
                          child: _MetricOverviewCard(
                            title: 'Review\nReplies',
                            value: '$unrepliedReviews',
                            subtitle: 'Unreplied reviews',
                            icon: _ReviewRepliesIcon(),
                            trendText: null,
                            onTap: () => Get.toNamed(AppRoutes.clientReviews),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 150,
                          child: _MetricOverviewCard(
                            title: 'Reach Overview',
                            value: _formatCompactNumber(reach),
                            subtitle: 'People reached',
                            icon: const _ReachOverviewIcon(),
                            trendText: reach > 0
                                ? '+ 28%  vs last 7 days'
                                : null,
                            onTap: () {
                              _productModeController.selectMode(
                                ProductMode.socialMedia,
                              );
                              Get.toNamed(AppRoutes.socialAnalytics);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ReachChartCard(reach: reach, insights: insights),
                  const SizedBox(height: 12),
                  _RecentActivityCard(
                    items: activityItems,
                    onViewAllTap: () {
                      _productModeController.selectMode(
                        ProductMode.googleBusiness,
                      );
                      Get.toNamed(AppRoutes.reports);
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.user, required this.onNotificationTap});

  final TestAccount user;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppLogo(iconSize: 42, fontSize: 24),
            const Spacer(),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onNotificationTap,
                borderRadius: BorderRadius.circular(999),
                child: const SizedBox(
                  width: 34,
                  height: 34,
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.brandBlue,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Hello, Business Owner 👋',
          style: const TextStyle(
            fontSize: 17.5,
            color: Color(0xFF061A35),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Here\'s what\'s happening with your business today.',
          style: TextStyle(
            fontSize: 13.0,
            color: Color(0xFF65748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ModuleSummaryCard extends StatelessWidget {
  const _ModuleSummaryCard({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPositive =
        statusLabel.toLowerCase() == 'active' ||
        statusLabel.toLowerCase() == 'running';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDDE6F2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F2746),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      style: const TextStyle(
                        height: 1.04,
                        fontSize: 13.4,
                        color: Color(0xFF061A35),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0xFFE9FAEF)
                      : const Color(0xFFFFF4E3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11.3,
                    color: isPositive
                        ? const Color(0xFF21A564)
                        : const Color(0xFFB37A16),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 11.8,
                        height: 1.12,
                        color: Color(0xFF65748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF8A97AB),
                    size: 18,
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

class _MetricOverviewCard extends StatelessWidget {
  const _MetricOverviewCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.trendText,
    required this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final Widget icon;
  final String? trendText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDDE6F2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F2746),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      style: const TextStyle(
                        height: 1.04,
                        fontSize: 13.1,
                        color: Color(0xFF061A35),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 25,
                  height: 1.0,
                  color: Color(0xFF13243F),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.2,
                  height: 1.0,
                  color: Color(0xFF65748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trendText ?? '',
                      style: TextStyle(
                        fontSize: 11.6,
                        height: 1.0,
                        color: trendText == null
                            ? Colors.transparent
                            : const Color(0xFF1FAE68),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF8A97AB),
                    size: 18,
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

class _ReachChartCard extends StatelessWidget {
  const _ReachChartCard({required this.reach, required this.insights});

  final int reach;
  final LocationInsightsResponse? insights;

  @override
  Widget build(BuildContext context) {
    final points = _buildReachChartPoints(insights);
    final dayLabels = _buildReachChartLabels(insights);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE6F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2746),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reach Overview (Last 7 Days)',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InsightStatPill(
                  icon: Icons.search_rounded,
                  iconColor: Color(0xFF4285F4),
                  label: 'Google Views',
                  value: _formatCompactNumber(_googleViews(insights)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InsightStatPill(
                  icon: Icons.call_rounded,
                  iconColor: Color(0xFF20B486),
                  label: 'Customer Calls',
                  value: _formatCompactNumber(_customerCalls(insights)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InsightStatPill(
                  icon: Icons.near_me_rounded,
                  iconColor: Color(0xFF2155B8),
                  label: 'Direction requests',
                  value: _formatCompactNumber(_directionRequests(insights)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InsightStatPill(
                  icon: Icons.star_rounded,
                  iconColor: Color(0xFFFFC23D),
                  label: 'Website Visits',
                  value: _formatCompactNumber(_websiteVisits(insights)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 150),
                  painter: _LineChartPainter(points: points),
                ),
                Positioned(
                  top: 4,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1AA0FF), Color(0xFF2668FF)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatCompactNumber(reach),
                          style: const TextStyle(
                            fontSize: 12.8,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          '↑ 28%',
                          style: TextStyle(
                            fontSize: 11.2,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dayLabels
                .map(
                  (label) => Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10.6,
                      color: Color(0xFF7B889B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _InsightStatPill extends StatelessWidget {
  const _InsightStatPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 9, 8, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.8,
                    height: 1.0,
                    color: Color(0xFF65748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    height: 1.0,
                    color: Color(0xFF061A35),
                    fontWeight: FontWeight.w900,
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

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.items, required this.onViewAllTap});

  final List<_ActivityItem> items;
  final VoidCallback onViewAllTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE6F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2746),
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
              const Expanded(
                child: Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAllTap,
                child: const Text(
                  'See All',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text(
                'No recent activity yet.',
                style: TextStyle(
                  fontSize: 12.8,
                  color: Color(0xFF6B7890),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ...items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: item.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Icon(item.icon, color: item.accent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 13.1,
                              color: Color(0xFF162845),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              fontSize: 11.9,
                              color: Color(0xFF6B7890),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.trailingAsset != null)
                      Image.asset(
                        item.trailingAsset!,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      )
                    else if (item.trailingIcon != null)
                      Icon(
                        item.trailingIcon,
                        color: const Color(0xFF7D8AA0),
                        size: 18,
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

class _CommonBottomBar extends StatelessWidget {
  const _CommonBottomBar({
    required this.onDashboardTap,
    required this.onPostsTap,
    required this.onReviewsTap,
    required this.onMoreTap,
  });

  final VoidCallback onDashboardTap;
  final VoidCallback onPostsTap;
  final VoidCallback onReviewsTap;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 12,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 70,
        child: Row(
          children: [
            Expanded(
              child: _BottomNavItem(
                icon: Icons.home_outlined,
                label: 'Dashboard',
                active: true,
                onTap: onDashboardTap,
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.description_outlined,
                label: 'Posts',
                onTap: onPostsTap,
              ),
            ),
            const SizedBox(width: 72),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.star_border_rounded,
                label: 'Reviews',
                onTap: onReviewsTap,
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.more_horiz_rounded,
                label: 'More',
                onTap: onMoreTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : const Color(0xFF7B879A);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleBusinessIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/google-my-business-icon.png',
      width: 50,
      height: 50,
      fit: BoxFit.contain,
    );
  }
}

class _SocialAutoPostIcon extends StatelessWidget {
  const _SocialAutoPostIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 42,
      child: Stack(
        children: const [
          Positioned(
            left: 0,
            top: 0,
            child: _CircleAssetIcon(assetPath: 'assets/images/facebook.png'),
          ),
          Positioned(
            left: 31,
            top: 0,
            child: _CircleAssetIcon(assetPath: 'assets/images/instagram.png'),
          ),
        ],
      ),
    );
  }
}

class _CircleAssetIcon extends StatelessWidget {
  const _CircleAssetIcon({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(assetPath, width: 38, height: 38, fit: BoxFit.contain);
  }
}

class _ReviewRepliesIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/star.png',
      width: 48,
      height: 48,
      fit: BoxFit.contain,
    );
  }
}

class _ReachOverviewIcon extends StatelessWidget {
  const _ReachOverviewIcon();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/eye.png',
      width: 48,
      height: 48,
      fit: BoxFit.contain,
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.when,
    this.trailingIcon,
    this.trailingAsset,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final DateTime when;
  final IconData? trailingIcon;
  final String? trailingAsset;
}

List<_ActivityItem> _buildActivityItems({
  required List<GbpPost> googlePosts,
  required List<GbpReview> liveReviews,
  required List<dynamic> socialPosts,
}) {
  final items = <_ActivityItem>[];

  final latestSocial = socialPosts.fold<dynamic>(null, (current, post) {
    final postTime = _socialPostDate(post);
    if (postTime == null) {
      return current;
    }
    if (current == null) {
      return post;
    }
    final currentTime = _socialPostDate(current);
    if (currentTime == null) {
      return post;
    }
    return postTime.isAfter(currentTime) ? post : current;
  });

  if (latestSocial != null) {
    items.add(
      _ActivityItem(
        title: 'Post published to ${_activityPlatform(latestSocial)}',
        subtitle: _formatActivityTime(_socialPostDate(latestSocial)!),
        icon: Icons.check_circle_rounded,
        accent: const Color(0xFF21A564),
        when: _socialPostDate(latestSocial)!,
        trailingAsset: _activityPlatformAsset(latestSocial),
      ),
    );
  }

  if (liveReviews.isNotEmpty) {
    final review = liveReviews.first;
    final reviewDate =
        DateTime.tryParse(review.reviewCreatedAt) ?? DateTime.now();
    items.add(
      _ActivityItem(
        title: 'New review received on Google',
        subtitle: _formatActivityTime(reviewDate),
        icon: Icons.reviews_rounded,
        accent: const Color(0xFF2E6DFF),
        when: reviewDate,
        trailingIcon: Icons.chevron_right_rounded,
      ),
    );
  }

  if (googlePosts.isNotEmpty) {
    final post = googlePosts.first;
    items.add(
      _ActivityItem(
        title: 'GBP post synced successfully',
        subtitle: _formatActivityTime(post.createdAt),
        icon: Icons.storefront_rounded,
        accent: const Color(0xFF19A1C1),
        when: post.createdAt,
        trailingIcon: Icons.chevron_right_rounded,
      ),
    );
  }

  items.sort((a, b) => b.when.compareTo(a.when));
  return items.take(4).toList(growable: false);
}

String _activityPlatform(dynamic post) {
  final platforms = (post.platforms as List<dynamic>? ?? const [])
      .map((item) => item.toString().trim().toLowerCase())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  if (platforms.contains('instagram')) {
    return 'Instagram';
  }
  if (platforms.contains('facebook')) {
    return 'Facebook';
  }
  if (platforms.contains('linkedin')) {
    return 'LinkedIn';
  }
  return 'Social';
}

String? _activityPlatformAsset(dynamic post) {
  final platforms = (post.platforms as List<dynamic>? ?? const [])
      .map((item) => item.toString().trim().toLowerCase())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  if (platforms.contains('instagram')) {
    return 'assets/images/instagram.png';
  }
  if (platforms.contains('facebook')) {
    return 'assets/images/facebook.png';
  }
  if (platforms.contains('linkedin')) {
    return 'assets/images/link.png';
  }
  return null;
}

DateTime? _nextScheduledSocialPost(List<dynamic> posts) {
  DateTime? next;
  for (final post in posts) {
    final status = post.status.toString().trim().toUpperCase();
    final scheduledAt = post.scheduledAt as DateTime?;
    if (status != 'SCHEDULED' || scheduledAt == null) {
      continue;
    }
    if (scheduledAt.isBefore(DateTime.now())) {
      continue;
    }
    if (next == null || scheduledAt.isBefore(next)) {
      next = scheduledAt;
    }
  }
  return next;
}

DateTime? _socialPostDate(dynamic post) {
  return post.publishedAt as DateTime? ??
      post.scheduledAt as DateTime? ??
      post.createdAt as DateTime?;
}

int _googleViews(LocationInsightsResponse? insights) {
  final totals = insights?.totals;
  if (totals == null) {
    return 0;
  }
  return totals.searchImpressions + totals.mapsImpressions;
}

int _customerCalls(LocationInsightsResponse? insights) {
  return insights?.totals.callClicks ?? 0;
}

int _directionRequests(LocationInsightsResponse? insights) {
  return insights?.totals.directionRequests ?? 0;
}

int _websiteVisits(LocationInsightsResponse? insights) {
  return insights?.totals.websiteClicks ?? 0;
}

List<double> _buildReachChartPoints(LocationInsightsResponse? insights) {
  final daily = insights?.daily ?? const <DailyInsight>[];
  if (daily.isEmpty) {
    return const [0.15, 0.24, 0.36, 0.32, 0.46, 0.39, 0.72];
  }

  final recent = daily.length > 7 ? daily.sublist(daily.length - 7) : daily;
  final values = recent
      .map((item) => item.searchImpressions + item.mapsImpressions)
      .toList(growable: false);
  final maxValue = values.fold<int>(
    0,
    (max, value) => value > max ? value : max,
  );
  if (maxValue == 0) {
    return List<double>.filled(values.length, 0.08);
  }
  return values
      .map((value) => (value / maxValue).clamp(0.08, 0.82).toDouble())
      .toList(growable: false);
}

List<String> _buildReachChartLabels(LocationInsightsResponse? insights) {
  final daily = insights?.daily ?? const <DailyInsight>[];
  if (daily.isEmpty) {
    return const [
      'May 7',
      'May 8',
      'May 9',
      'May 10',
      'May 11',
      'May 12',
      'May 13',
    ];
  }

  final recent = daily.length > 7 ? daily.sublist(daily.length - 7) : daily;
  return recent
      .map((item) {
        final date = DateTime.tryParse(item.date);
        if (date == null) {
          return item.date;
        }
        return '${_monthShort(date.month)} ${date.day}';
      })
      .toList(growable: false);
}

String _formatActivityTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '${_monthShort(value.month)} ${value.day}, $hour:$minute $period';
}

String _formatTimeOnly(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return 'at $hour:$minute $period';
}

String _monthShort(int month) {
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
  return months[(month - 1).clamp(0, 11)];
}

String _formatCompactNumber(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
  }
  return '$value';
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({required this.points});

  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE7EEF8)
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = 10 + (i * ((size.height - 28) / 4));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePath = Path();
    final fillPath = Path();
    final usableHeight = size.height - 20;
    final pointCount = points.length;

    for (var i = 0; i < pointCount; i++) {
      final progress = pointCount == 1 ? 1.0 : i / (pointCount - 1);
      final dx = (size.width - 12) * progress;
      final dy = usableHeight - (usableHeight * points[i]);
      if (i == 0) {
        linePath.moveTo(dx, dy);
        fillPath.moveTo(dx, size.height);
        fillPath.lineTo(dx, dy);
      } else {
        linePath.lineTo(dx, dy);
        fillPath.lineTo(dx, dy);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x2E1A85FF), Color(0x031A85FF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF21A7FF), Color(0xFF1E60FF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = const Color(0xFF1E60FF);
    for (var i = 0; i < points.length; i++) {
      final dx = (size.width - 12) * (i / (points.length - 1));
      final dy = usableHeight - (usableHeight * points[i]);
      canvas.drawCircle(Offset(dx, dy), 3.1, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
