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
import '../models/ai_manager_action.dart';
import '../models/gbp_post.dart';
import '../models/gbp_review.dart';
import '../models/report_models.dart';
import '../models/test_account.dart';
import '../services/auth_api_service.dart';

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
  late final AuthApiService _authApiService = Get.find<AuthApiService>();
  LocationInsightsResponse? _previousInsights;
  List<AiManagerAction> _aiActions = const <AiManagerAction>[];
  bool _isLoadingAiActions = false;
  bool _aiActionsPreviewMode = false;
  String _activeAiActionId = '';
  Map<String, dynamic>? _businessHealthReport;
  bool _isLoadingBusinessHealth = false;
  Map<String, dynamic>? _aiWorkReport;
  bool _isLoadingAiWorkReport = false;

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
    final previousRange = DateTimeRange(
      start: now.subtract(const Duration(days: 59)),
      end: now.subtract(const Duration(days: 30)),
    );
    await _controller.fetchDashboardLiveStream();
    final results = await Future.wait<Object?>([
      _controller.fetchReportsData(insightsRange),
      _controller.loadInsightsForRange(previousRange),
      _socialAccountsController.loadAccounts(),
      _socialPostsController.loadPosts(),
    ]);
    await _loadAiActions(generateNow: true);
    await _loadBusinessHealthReport(refresh: true);
    await _loadAiWorkReport();
    if (mounted) {
      setState(() {
        _previousInsights = results[1] as LocationInsightsResponse?;
      });
    }
    _socialAnalyticsController.loadIfBusinessOrRangeChanged('Last 28 days');
  }

  Future<void> _showRecentActivity(
    BuildContext context,
    List<_ActivityItem> items,
  ) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (pageContext) => _ActivityNotificationsPage(
          items: items,
          onViewAllTap: () {
            Navigator.of(pageContext).pop();
            _productModeController.selectMode(ProductMode.googleBusiness);
            Get.toNamed(AppRoutes.reports);
          },
        ),
      ),
    );
  }

  Future<void> _loadAiActions({bool generateNow = false}) async {
    final businessId =
        _controller.currentUser.value?.backendBusinessId.trim() ?? '';
    if (businessId.isEmpty) return;

    if (mounted) {
      setState(() => _isLoadingAiActions = true);
    }

    try {
      if (generateNow) {
        await _authApiService.generateAiManagerActionsNow(
          businessId: businessId,
        );
      }
      final actions = await _authApiService.listAiManagerActions(
        businessId: businessId,
      );
      if (mounted) {
        setState(() {
          _aiActions = actions.isEmpty
              ? _previewAiActions(businessId)
              : actions;
          _aiActionsPreviewMode = actions.isEmpty;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _aiActions = _previewAiActions(businessId);
          _aiActionsPreviewMode = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAiActions = false);
      }
    }
  }

  Future<void> _loadBusinessHealthReport({bool refresh = false}) async {
    final businessId =
        _controller.currentUser.value?.backendBusinessId.trim() ?? '';
    if (businessId.isEmpty) return;

    if (mounted) {
      setState(() => _isLoadingBusinessHealth = true);
    }

    try {
      final report = await _authApiService.fetchAiBusinessHealthReport(
        businessId: businessId,
        refresh: refresh,
      );
      if (mounted) {
        setState(() => _businessHealthReport = report);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _businessHealthReport = null);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingBusinessHealth = false);
      }
    }
  }

  Future<void> _loadAiWorkReport({String range = 'week'}) async {
    final businessId =
        _controller.currentUser.value?.backendBusinessId.trim() ?? '';
    if (businessId.isEmpty) return;

    if (mounted) {
      setState(() => _isLoadingAiWorkReport = true);
    }

    try {
      final report = await _authApiService.fetchAiWorkReport(
        businessId: businessId,
        range: range,
      );
      if (mounted) {
        setState(() => _aiWorkReport = report);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _aiWorkReport = _buildLocalAiWorkReport(businessId));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAiWorkReport = false);
      }
    }
  }

  Map<String, dynamic> _buildLocalAiWorkReport(String businessId) {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final googlePosts = _controller.liveGbpPosts;
    final completedActions = _aiActions
        .where((action) => action.isCompleted)
        .toList(growable: false);
    final activeActions = _aiActions
        .where(
          (action) =>
              action.isPending ||
              action.isApproved ||
              action.isRunning ||
              action.status == 'PREVIEW',
        )
        .toList(growable: false);
    final publishedPosts = googlePosts.where((post) {
      if (!_isPublishedGbpPost(post)) return false;
      final date = post.createdAt;
      return date.isAfter(weekStart) || _isSameDay(date, weekStart);
    }).length;
    final scheduledPosts = googlePosts
        .where((post) => post.publishStatus.toUpperCase() == 'SCHEDULED')
        .length;
    final reviewReplies = completedActions
        .where((action) => action.type == 'REVIEW_REPLY')
        .length;
    final keywordsAdded = completedActions
        .where((action) => action.type == 'SEO_KEYWORD')
        .length;
    final gapsFound = (_healthFindings(_businessHealthReport).isNotEmpty)
        ? _healthFindings(_businessHealthReport).length
        : activeActions.length;

    return <String, dynamic>{
      'ok': true,
      'fallback': true,
      'range': 'week',
      'businessId': businessId,
      'summary':
          'VisibloAI is tracking weekly work from your dashboard while the live report service connects.',
      'metrics': <String, dynamic>{
        'postsPublished': publishedPosts,
        'postsScheduled': scheduledPosts,
        'reviewRepliesPosted': reviewReplies,
        'keywordsAdded': keywordsAdded,
        'completedActions': completedActions.length,
        'activeActions': activeActions.length,
        'gapsFound': gapsFound,
      },
      'workItems': <Map<String, dynamic>>[
        <String, dynamic>{
          'code': 'POSTS_PUBLISHED',
          'label': 'Google posts',
          'value': publishedPosts,
        },
        <String, dynamic>{
          'code': 'REVIEWS_REPLIED',
          'label': 'Review replies',
          'value': reviewReplies,
        },
        <String, dynamic>{
          'code': 'KEYWORDS_ADDED',
          'label': 'SEO keywords',
          'value': keywordsAdded,
        },
        <String, dynamic>{
          'code': 'GAPS_FOUND',
          'label': 'Gaps found',
          'value': gapsFound,
        },
      ],
      'nextActions': activeActions
          .take(2)
          .map(
            (action) => <String, dynamic>{
              'id': action.id,
              'type': action.type,
              'status': action.status,
              'title': action.title,
              'reason': action.reason,
            },
          )
          .toList(growable: false),
      'generatedAt': now.toUtc().toIso8601String(),
    };
  }

  Future<void> _handleAiAction(
    AiManagerAction action,
    Future<AiManagerAction> Function(String businessId) command,
  ) async {
    final businessId =
        _controller.currentUser.value?.backendBusinessId.trim() ?? '';
    if (businessId.isEmpty) return;

    setState(() => _activeAiActionId = action.id);
    try {
      final updatedAction = await command(businessId);
      await _loadAiActions();
      if (action.type == 'GBP_CONTENT_CALENDAR' && updatedAction.isCompleted) {
        _productModeController.selectMode(ProductMode.googleBusiness);
        Get.snackbar(
          'Calendar ready',
          updatedAction.result['message']?.toString() ??
              'VisibloAI created your 30-day content calendar.',
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.toNamed(AppRoutes.aiContentCalendar);
      } else if (action.type == 'GBP_POST' &&
          updatedAction.isCompleted &&
          (updatedAction.result['postId']?.toString().trim().isNotEmpty ??
              false)) {
        _productModeController.selectMode(ProductMode.googleBusiness);
        Get.snackbar(
          'Post draft ready',
          'VisibloAI created a Google post draft for review.',
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.toNamed(AppRoutes.gbpPosts);
      } else if (action.type == 'REVIEW_REPLY' && updatedAction.isCompleted) {
        _productModeController.selectMode(ProductMode.googleBusiness);
        Get.snackbar(
          'Review replies posted',
          updatedAction.result['message']?.toString() ??
              'VisibloAI posted the approved review replies.',
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.toNamed(AppRoutes.clientReviews);
      }
    } catch (error) {
      Get.snackbar(
        'AI action',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _activeAiActionId = '');
      }
    }
  }

  Future<void> _approveCalendarAndOpen(AiManagerAction action) async {
    final businessId =
        _controller.currentUser.value?.backendBusinessId.trim() ?? '';
    if (businessId.isEmpty) return;

    setState(() => _activeAiActionId = action.id);
    try {
      final approved = await _authApiService.approveAiManagerAction(
        actionId: action.id,
        businessId: businessId,
      );
      final completed = await _authApiService.runAiManagerAction(
        actionId: approved.id,
        businessId: businessId,
      );
      await _loadAiActions();
      _productModeController.selectMode(ProductMode.googleBusiness);
      Get.snackbar(
        'Calendar ready',
        completed.result['message']?.toString() ??
            'VisibloAI created your Google Business Profile content calendar.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.toNamed(AppRoutes.aiContentCalendar);
    } catch (error) {
      Get.snackbar(
        'Calendar action',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _activeAiActionId = '');
      }
    }
  }

  void _showReviewReplyPreview(AiManagerAction action) {
    final replies = _reviewReplySuggestions(action);
    if (replies.isEmpty) {
      Get.snackbar(
        'Review reply',
        'No AI reply draft is available for this action yet.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.bottomSheet<void>(
      _ReviewReplyPreviewSheet(
        action: action,
        replies: replies,
        onApprove: () {
          Get.back<void>();
          _handleAiAction(
            action,
            (businessId) => _authApiService.approveAiManagerAction(
              actionId: action.id,
              businessId: businessId,
            ),
          );
        },
        onRegenerate: (reply) {
          Get.back<void>();
          _regenerateReviewReply(action, reply);
        },
        onEdit: (reply) {
          Get.back<void>();
          _editReviewReply(action, reply);
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _viewAiAction(AiManagerAction action) {
    if (action.type == 'GBP_CONTENT_CALENDAR') {
      _productModeController.selectMode(ProductMode.googleBusiness);
      Get.toNamed(AppRoutes.aiContentCalendar);
      return;
    }
    if (action.type == 'REVIEW_REPLY') {
      _showReviewReplyPreview(action);
    }
  }

  Future<void> _regenerateReviewReply(
    AiManagerAction action,
    _ReviewReplySuggestion reply,
  ) async {
    final businessId =
        _controller.currentUser.value?.backendBusinessId.trim() ?? '';
    if (businessId.isEmpty || reply.reviewId.isEmpty) return;

    setState(() => _activeAiActionId = action.id);
    try {
      await _authApiService.regenerateAiManagerReviewReply(
        actionId: action.id,
        reviewId: reply.reviewId,
        businessId: businessId,
      );
      await _loadAiActions();
      Get.snackbar(
        'Reply regenerated',
        'Open View again to review the updated AI reply.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Regenerate reply',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _activeAiActionId = '');
      }
    }
  }

  void _editReviewReply(AiManagerAction action, _ReviewReplySuggestion reply) {
    final textController = TextEditingController(text: reply.replyText);
    Get.dialog<void>(
      AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        title: const Text(
          'Edit AI reply',
          style: TextStyle(
            fontSize: 18,
            height: 1.15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF061A35),
          ),
        ),
        content: TextField(
          controller: textController,
          minLines: 4,
          maxLines: 7,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.28,
            fontWeight: FontWeight.w600,
            color: Color(0xFF061A35),
          ),
          decoration: const InputDecoration(
            hintText: 'Write the reply to post on Google',
            hintStyle: TextStyle(fontSize: 13),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          FilledButton(
            onPressed: () async {
              final editedText = textController.text.trim();
              if (editedText.length < 10) {
                Get.snackbar(
                  'Edit reply',
                  'Please write a little more before saving.',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              Get.back<void>();
              await _saveEditedReviewReply(action, reply.reviewId, editedText);
            },
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEditedReviewReply(
    AiManagerAction action,
    String reviewId,
    String replyText,
  ) async {
    final businessId =
        _controller.currentUser.value?.backendBusinessId.trim() ?? '';
    if (businessId.isEmpty || reviewId.isEmpty) return;

    setState(() => _activeAiActionId = action.id);
    try {
      await _authApiService.updateAiManagerReviewReply(
        actionId: action.id,
        reviewId: reviewId,
        replyText: replyText,
        businessId: businessId,
      );
      await _loadAiActions();
      Get.snackbar(
        'Reply saved',
        'The edited reply will be used when this action runs.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Edit reply',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _activeAiActionId = '');
      }
    }
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
          final previousReach = _googleViews(_previousInsights);
          final unrepliedReviews = liveReviews
              .where((review) => !review.hasOwnerReply)
              .length;
          final unrepliedReviewItems = liveReviews
              .where((review) => !review.hasOwnerReply)
              .toList(growable: false);
          final todayGooglePosts = _todayGooglePostHighlights(googlePosts);
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
                    onNotificationTap: () =>
                        _showRecentActivity(context, activityItems),
                  ),
                  const SizedBox(height: 14),
                  _AiActionsCard(
                    actions: _aiActions,
                    isLoading: _isLoadingAiActions,
                    isPreviewMode: _aiActionsPreviewMode,
                    activeActionId: _activeAiActionId,
                    onRefresh: () => _loadAiActions(generateNow: true),
                    onApprove: (action) {
                      if (action.type == 'GBP_CONTENT_CALENDAR') {
                        _approveCalendarAndOpen(action);
                        return;
                      }
                      _handleAiAction(
                        action,
                        (businessId) => _authApiService.approveAiManagerAction(
                          actionId: action.id,
                          businessId: businessId,
                        ),
                      );
                    },
                    onReject: (action) => _handleAiAction(
                      action,
                      (businessId) => _authApiService.rejectAiManagerAction(
                        actionId: action.id,
                        businessId: businessId,
                        reason: 'Rejected from dashboard',
                      ),
                    ),
                    onRun: (action) => _handleAiAction(
                      action,
                      (businessId) => _authApiService.runAiManagerAction(
                        actionId: action.id,
                        businessId: businessId,
                      ),
                    ),
                    onView: _viewAiAction,
                  ),
                  if (_isLoadingBusinessHealth ||
                      _businessHealthReport != null) ...[
                    const SizedBox(height: 14),
                    _BusinessHealthReportCard(
                      report: _businessHealthReport,
                      isLoading: _isLoadingBusinessHealth,
                      onActionPlanTap: () {
                        _productModeController.selectMode(
                          ProductMode.googleBusiness,
                        );
                        Get.toNamed(AppRoutes.audit);
                      },
                      onRefreshTap: () =>
                          _loadBusinessHealthReport(refresh: true),
                    ),
                  ],
                  if (_isLoadingAiWorkReport || _aiWorkReport != null) ...[
                    const SizedBox(height: 14),
                    _AiWorkReportCard(
                      report: _aiWorkReport,
                      isLoading: _isLoadingAiWorkReport,
                      onReportTap: () {
                        _productModeController.selectMode(
                          ProductMode.googleBusiness,
                        );
                        Get.toNamed(AppRoutes.reports);
                      },
                      onRefreshTap: () => _loadAiWorkReport(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _TodayGooglePostCard(
                    posts: todayGooglePosts,
                    onTap: () {
                      _productModeController.selectMode(
                        ProductMode.googleBusiness,
                      );
                      Get.toNamed(AppRoutes.aiContentCalendar);
                    },
                  ),
                  const SizedBox(height: 12),
                  _ReviewQueueCard(
                    reviews: unrepliedReviewItems,
                    onViewAllTap: () => Get.toNamed(AppRoutes.clientReviews),
                  ),
                  const SizedBox(height: 12),
                  _BackgroundWorkGrid(
                    onWebsiteTap: () => Get.toNamed(AppRoutes.websiteManager),
                    onKeywordTap: () => Get.toNamed(AppRoutes.keywordRanking),
                    onAuditTap: () => Get.toNamed(AppRoutes.audit),
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
                                ? '${_formatReachDeltaText(reach, previousReach)} vs previous 30 days'
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
                  _ReachChartCard(
                    reach: reach,
                    insights: insights,
                    previousInsights: _previousInsights,
                  ),
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

  List<AiManagerAction> _previewAiActions(String businessId) {
    return [
      AiManagerAction(
        id: 'preview-calendar',
        businessId: businessId,
        type: 'GBP_CONTENT_CALENDAR',
        status: 'PREVIEW',
        title: 'Prepare a 30-day Google post calendar',
        description:
            'Educational posts, service highlights, FAQs and trust posts.',
        reason:
            'Keeps your Google profile active without writing from scratch.',
        priority: 95,
        progress: 0,
      ),
      AiManagerAction(
        id: 'preview-review-replies',
        businessId: businessId,
        type: 'REVIEW_REPLY',
        status: 'PREVIEW',
        title: 'Draft replies for new customer reviews',
        description:
            'Positive, negative and no-comment reviews get safe reply drafts.',
        reason: 'Faster replies improve trust and customer confidence.',
        priority: 90,
        progress: 0,
      ),
      AiManagerAction(
        id: 'preview-weekly-post',
        businessId: businessId,
        type: 'GBP_POST',
        status: 'PREVIEW',
        title: 'Create Google Business post drafts',
        description: 'AI suggests topics, copy, CTA and branded visuals.',
        reason: 'Fresh posts show customers the business is active.',
        priority: 86,
        progress: 0,
      ),
      AiManagerAction(
        id: 'preview-seo-keywords',
        businessId: businessId,
        type: 'SEO_KEYWORD',
        status: 'PREVIEW',
        title: 'Find local SEO keyword opportunities',
        description: 'Service, city and near-me keywords for rank tracking.',
        reason:
            'Visibility can only improve when the right keywords are tracked.',
        priority: 82,
        progress: 0,
        payload: const {
          'suggestions': [
            'main service near me',
            'best local business in your city',
            'trusted service provider nearby',
          ],
        },
      ),
      AiManagerAction(
        id: 'preview-profile-fix',
        businessId: businessId,
        type: 'PROFILE_FIX',
        status: 'PREVIEW',
        title: 'Detect missing profile information',
        description: 'Website, phone, category, services and location fields.',
        reason:
            'Complete profiles convert more visitors into calls and visits.',
        priority: 78,
        progress: 0,
      ),
      AiManagerAction(
        id: 'preview-weekly-report',
        businessId: businessId,
        type: 'WEEKLY_REPORT',
        status: 'PREVIEW',
        title: 'Send weekly growth summary',
        description:
            'Visibility movement, reviews, posts, actions and next fixes.',
        reason:
            'The owner should see business growth without opening every tool.',
        priority: 72,
        progress: 0,
      ),
    ];
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

class _AiActionsCard extends StatelessWidget {
  const _AiActionsCard({
    required this.actions,
    required this.isLoading,
    required this.isPreviewMode,
    required this.activeActionId,
    required this.onRefresh,
    required this.onApprove,
    required this.onReject,
    required this.onRun,
    required this.onView,
  });

  final List<AiManagerAction> actions;
  final bool isLoading;
  final bool isPreviewMode;
  final String activeActionId;
  final VoidCallback onRefresh;
  final ValueChanged<AiManagerAction> onApprove;
  final ValueChanged<AiManagerAction> onReject;
  final ValueChanged<AiManagerAction> onRun;
  final ValueChanged<AiManagerAction> onView;

  @override
  Widget build(BuildContext context) {
    final visibleActions = actions
        .where((action) => !action.isRejected)
        .take(4)
        .toList(growable: false);
    final completedCount = actions.where((action) => action.isCompleted).length;
    final pendingCount = actions
        .where((action) => action.isPending || action.status == 'PREVIEW')
        .length;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDE6F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2746),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF106CFF), Color(0xFF29C2D6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset('assets/images/ai.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VisibloAI is working',
                      style: TextStyle(
                        fontSize: 16.5,
                        color: Color(0xFF061A35),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      isPreviewMode
                          ? 'Automation preview while setup is being connected'
                          : 'Today’s AI actions for your business',
                      style: TextStyle(
                        fontSize: 12.4,
                        color: Color(0xFF65748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh AI actions',
                onPressed: isLoading ? null : onRefresh,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        color: AppColors.brandBlue,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _AiActionStat(label: 'Pending', value: '$pendingCount'),
              const SizedBox(width: 8),
              _AiActionStat(label: 'Done', value: '$completedCount'),
              const SizedBox(width: 8),
              _AiActionStat(label: 'Total', value: '${actions.length}'),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading && visibleActions.isEmpty)
            const _AiActionsLoadingState()
          else if (visibleActions.isEmpty)
            const _AiActionsEmptyState()
          else
            ...visibleActions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _AiActionTile(
                  action: action,
                  isBusy: activeActionId == action.id,
                  isPreview: action.status == 'PREVIEW',
                  onApprove: () => onApprove(action),
                  onReject: () => onReject(action),
                  onRun: () => onRun(action),
                  onView: () => onView(action),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AiActionStat extends StatelessWidget {
  const _AiActionStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6FAFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3ECF8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF061A35),
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.2,
                color: Color(0xFF65748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiActionTile extends StatelessWidget {
  const _AiActionTile({
    required this.action,
    required this.isBusy,
    required this.isPreview,
    required this.onApprove,
    required this.onReject,
    required this.onRun,
    required this.onView,
  });

  final AiManagerAction action;
  final bool isBusy;
  final bool isPreview;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRun;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(action.status);
    final keywordSuggestions = _keywordSuggestions(action);
    final calendarHighlights = _calendarActionHighlights(action);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE3ECF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _typeColor(action.type).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _typeIcon(action.type),
                  color: _typeColor(action.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.6,
                        height: 1.18,
                        color: Color(0xFF061A35),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if ((action.reason ?? action.description ?? '')
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        action.reason ?? action.description ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.4,
                          height: 1.25,
                          color: Color(0xFF65748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (keywordSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: keywordSuggestions
                            .take(4)
                            .map((keyword) => _KeywordSuggestionChip(keyword))
                            .toList(growable: false),
                      ),
                    ],
                    if (calendarHighlights.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: calendarHighlights
                            .take(4)
                            .map((label) => _AiActionInfoChip(label))
                            .toList(growable: false),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(action.status),
                  style: TextStyle(
                    fontSize: 10.6,
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (isBusy)
            const LinearProgressIndicator(minHeight: 3)
          else if (isPreview)
            const Text(
              'This will become live after backend deployment and database migration.',
              style: TextStyle(
                fontSize: 11.2,
                height: 1.25,
                color: Color(0xFF65748B),
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Row(
              children: [
                if ((action.type == 'GBP_CONTENT_CALENDAR') ||
                    (action.type == 'REVIEW_REPLY' &&
                        _reviewReplySuggestions(action).isNotEmpty)) ...[
                  _MiniActionButton(
                    label: 'View',
                    icon: action.type == 'GBP_CONTENT_CALENDAR'
                        ? Icons.calendar_month_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF106CFF),
                    onTap: onView,
                  ),
                  const SizedBox(width: 8),
                ],
                if (action.canApprove) ...[
                  _MiniActionButton(
                    label: 'Approve',
                    icon: Icons.check_rounded,
                    color: const Color(0xFF18A85E),
                    onTap: onApprove,
                  ),
                  const SizedBox(width: 8),
                ],
                if (action.canRun) ...[
                  _MiniActionButton(
                    label: action.type == 'GBP_CONTENT_CALENDAR'
                        ? 'Build'
                        : action.isRunning
                        ? 'Finish'
                        : 'Run',
                    icon: Icons.play_arrow_rounded,
                    color: const Color(0xFF106CFF),
                    onTap: onRun,
                  ),
                  const SizedBox(width: 8),
                ],
                if (!action.isCompleted)
                  _MiniActionButton(
                    label: 'Skip',
                    icon: Icons.remove_rounded,
                    color: const Color(0xFF7D8798),
                    onTap: onReject,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.4,
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeywordSuggestionChip extends StatelessWidget {
  const _KeywordSuggestionChip(this.keyword);

  final String keyword;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFCFEFDC)),
      ),
      child: Text(
        keyword,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10.6,
          color: Color(0xFF16864F),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AiActionInfoChip extends StatelessWidget {
  const _AiActionInfoChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFBFA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFCFEFEC)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10.6,
          color: Color(0xFF0E7C70),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReviewReplyPreviewSheet extends StatelessWidget {
  const _ReviewReplyPreviewSheet({
    required this.action,
    required this.replies,
    required this.onApprove,
    required this.onRegenerate,
    required this.onEdit,
  });

  final AiManagerAction action;
  final List<_ReviewReplySuggestion> replies;
  final VoidCallback onApprove;
  final ValueChanged<_ReviewReplySuggestion> onRegenerate;
  final ValueChanged<_ReviewReplySuggestion> onEdit;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6DEEA),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.forum_outlined,
                        color: Color(0xFF2F80ED),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI review reply draft',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF061A35),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Review what VisibloAI will post before approving.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF65748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  itemCount: replies.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final reply = replies[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFCFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE3ECF8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  reply.reviewerName.isEmpty
                                      ? 'Customer review'
                                      : reply.reviewerName,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF061A35),
                                  ),
                                ),
                              ),
                              Text(
                                '${reply.starRating}/5',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFFFA000),
                                ),
                              ),
                            ],
                          ),
                          if (reply.commentText.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              reply.commentText,
                              style: const TextStyle(
                                fontSize: 12.2,
                                height: 1.35,
                                color: Color(0xFF65748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFFAF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFCFEFDC),
                              ),
                            ),
                            child: Text(
                              reply.replyText,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.38,
                                color: Color(0xFF0E5F38),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _ReplySheetActionButton(
                                  label: 'Regenerate',
                                  icon: Icons.refresh_rounded,
                                  color: const Color(0xFF106CFF),
                                  onPressed: () => onRegenerate(reply),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ReplySheetActionButton(
                                  label: 'Edit',
                                  icon: Icons.edit_outlined,
                                  color: const Color(0xFF7C3AED),
                                  onPressed: () => onEdit(reply),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ReplySheetActionButton(
                                  label: 'Approve',
                                  icon: Icons.check_rounded,
                                  color: const Color(0xFF18A85E),
                                  filled: true,
                                  onPressed: action.canApprove
                                      ? onApprove
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }
}

class _ReplySheetActionButton extends StatelessWidget {
  const _ReplySheetActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = filled ? Colors.white : color;
    return Material(
      color: filled
          ? (enabled ? color : const Color(0xFFD6DEEA))
          : color.withValues(alpha: enabled ? 0.08 : 0.04),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: filled
                ? null
                : Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 4),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: label.length > 8 ? 11.2 : 12.2,
                    color: foreground,
                    fontWeight: FontWeight.w900,
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

class _AiActionsLoadingState extends StatelessWidget {
  const _AiActionsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
    );
  }
}

class _AiActionsEmptyState extends StatelessWidget {
  const _AiActionsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3ECF8)),
      ),
      child: const Text(
        'No urgent actions right now. VisibloAI will keep checking reviews, posts, keywords and profile health.',
        style: TextStyle(
          fontSize: 12.4,
          height: 1.35,
          color: Color(0xFF65748B),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TodayGooglePostCard extends StatelessWidget {
  const _TodayGooglePostCard({required this.posts, required this.onTap});

  final List<GbpPost> posts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nextPost = posts.isEmpty ? null : posts.first;
    final isPublished = nextPost == null
        ? false
        : _isPublishedGbpPost(nextPost);
    final isFailed = nextPost == null ? false : _isFailedGbpPost(nextPost);
    final isPublishing = nextPost == null ? false : _isPublishingGbpPost(nextPost);

    return _OperatorCard(
      title: posts.isEmpty
          ? 'Today’s Google post check'
          : isFailed
          ? 'Google post needs review'
          : isPublishing
          ? 'VisibloAI is publishing'
          : isPublished
          ? 'VisibloAI published your post'
          : 'VisibloAI will post today',
      actionLabel: posts.isEmpty
          ? 'Open calendar'
          : isFailed
          ? 'Fix post'
          : isPublishing
          ? 'Check status'
          : isPublished
          ? 'View post'
          : 'View schedule',
      onActionTap: onTap,
      child: nextPost == null
          ? const _OperatorEmptyMessage(
              icon: Icons.event_available_rounded,
              color: Color(0xFF0E9F8B),
              text:
                  'No Google Business post is scheduled for today. VisibloAI will keep the next planned post ready.',
            )
          : Material(
              color: const Color(0xFFF8FAFE),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: Row(
                    children: [
                      _TodayPostMedia(post: nextPost),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextPost.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.15,
                                color: Color(0xFF061A35),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isFailed
                                  ? 'Google could not publish it. Review needed.'
                                  : isPublishing
                                  ? 'Submitting to Google Business Profile now'
                                  : isPublished
                                  ? 'Published successfully on Google Business Profile'
                                  : 'Google Business Profile • ${_formatTimeOnly(nextPost.scheduledFor ?? DateTime.now())}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF65748B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 5,
                              children: [
                                _AiActionInfoChip(
                                  isFailed
                                      ? 'Needs review'
                                      : isPublishing
                                      ? 'Publishing'
                                      : isPublished
                                      ? 'Live now'
                                      : 'Auto publish',
                                ),
                                if (posts.length > 1)
                                  _AiActionInfoChip(
                                    '+${posts.length - 1} more',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isPublished
                              ? const Color(0xFFEAFBF1)
                              : isPublishing
                              ? const Color(0xFFEAF3FF)
                              : isFailed
                              ? const Color(0xFFFFF0F3)
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isPublished
                                ? const Color(0xFFC9F1D8)
                                : isPublishing
                                ? const Color(0xFFCFE0FF)
                                : isFailed
                                ? const Color(0xFFFFCFD9)
                                : const Color(0xFFE5ECF6),
                          ),
                        ),
                        child: Icon(
                          isPublished
                              ? Icons.open_in_new_rounded
                              : isPublishing
                              ? Icons.sync_rounded
                              : isFailed
                              ? Icons.report_gmailerrorred_rounded
                              : Icons.chevron_right_rounded,
                          color: isPublished
                              ? const Color(0xFF1FA463)
                              : isPublishing
                              ? const Color(0xFF1267F1)
                              : isFailed
                              ? const Color(0xFFE94363)
                              : const Color(0xFF8A97AB),
                          size: 19,
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

class _TodayPostMedia extends StatelessWidget {
  const _TodayPostMedia({required this.post});

  final GbpPost post;

  @override
  Widget build(BuildContext context) {
    final asset = post.assetPath.trim();
    Widget child;
    if (asset.isEmpty) {
      child = const Icon(
        Icons.auto_awesome_rounded,
        color: Color(0xFF0E9F8B),
        size: 24,
      );
    } else if (post.isNetworkAsset) {
      child = Image.network(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(
          Icons.auto_awesome_rounded,
          color: Color(0xFF0E9F8B),
          size: 24,
        ),
      );
    } else if (asset.startsWith('assets/')) {
      child = Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(
          Icons.auto_awesome_rounded,
          color: Color(0xFF0E9F8B),
          size: 24,
        ),
      );
    } else {
      child = const Icon(
        Icons.auto_awesome_rounded,
        color: Color(0xFF0E9F8B),
        size: 24,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 58,
        height: 58,
        color: const Color(0xFFEFFBFA),
        child: child,
      ),
    );
  }
}

class _BusinessHealthReportCard extends StatelessWidget {
  const _BusinessHealthReportCard({
    required this.report,
    required this.isLoading,
    required this.onActionPlanTap,
    required this.onRefreshTap,
  });

  final Map<String, dynamic>? report;
  final bool isLoading;
  final VoidCallback onActionPlanTap;
  final VoidCallback onRefreshTap;

  @override
  Widget build(BuildContext context) {
    final findings = _healthFindings(report).take(3).toList(growable: false);
    final score = _healthScore(report);
    final grade = (report?['grade'] ?? 'Checking').toString();
    final summary =
        (report?['summary'] ??
                'VisibloAI is checking reviews, posts, keywords and profile gaps.')
            .toString();

    return _OperatorCard(
      title: findings.isEmpty && report != null
          ? 'Business health looks steady'
          : 'VisibloAI found ${findings.length} growth gap${findings.length == 1 ? '' : 's'}',
      actionLabel: isLoading ? 'Checking' : 'Action plan',
      onActionTap: isLoading ? () {} : onActionPlanTap,
      child: isLoading && report == null
          ? const _BusinessHealthLoading()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FBFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2ECF8)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _healthScoreColor(score).withValues(
                            alpha: 0.12,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$score',
                            style: TextStyle(
                              fontSize: 20,
                              color: _healthScoreColor(score),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Profile strength: $grade',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.2,
                                      color: Color(0xFF061A35),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                if (isLoading) ...[
                                  const SizedBox(width: 8),
                                  const SizedBox(
                                    width: 13,
                                    height: 13,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.8,
                                height: 1.3,
                                color: Color(0xFF65748B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh report',
                        onPressed: isLoading ? null : onRefreshTap,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.brandBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (findings.isEmpty)
                  const _OperatorEmptyMessage(
                    icon: Icons.verified_rounded,
                    color: Color(0xFF18A85E),
                    text:
                        'No urgent growth gaps found today. VisibloAI will keep monitoring and create actions when something needs attention.',
                  )
                else
                  ...findings.map(
                    (finding) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _BusinessHealthFindingTile(finding: finding),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _BusinessHealthLoading extends StatelessWidget {
  const _BusinessHealthLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2ECF8)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'VisibloAI is checking your profile, reviews, posts and keywords.',
              style: TextStyle(
                fontSize: 12.2,
                color: Color(0xFF65748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessHealthFindingTile extends StatelessWidget {
  const _BusinessHealthFindingTile({required this.finding});

  final Map<String, dynamic> finding;

  @override
  Widget build(BuildContext context) {
    final severity = (finding['severity'] ?? 'LOW').toString();
    final color = _healthSeverityColor(severity);
    final actionType = (finding['actionType'] ?? '').toString();
    final metricLabel = (finding['metricLabel'] ?? '').toString();
    final metricValue = (finding['metricValue'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(_healthFindingIcon(actionType), color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (finding['title'] ?? 'Growth gap found').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.8,
                          color: Color(0xFF061A35),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (metricLabel.isNotEmpty)
                      _HealthMetricPill(
                        label: metricLabel,
                        value: metricValue,
                        color: color,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  (finding['fix'] ??
                          'VisibloAI will prepare the next fix for approval.')
                      .toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.28,
                    color: Color(0xFF65748B),
                    fontWeight: FontWeight.w700,
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

class _HealthMetricPill extends StatelessWidget {
  const _HealthMetricPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$value $label',
        style: TextStyle(
          fontSize: 10.5,
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AiWorkReportCard extends StatelessWidget {
  const _AiWorkReportCard({
    required this.report,
    required this.isLoading,
    required this.onReportTap,
    required this.onRefreshTap,
  });

  final Map<String, dynamic>? report;
  final bool isLoading;
  final VoidCallback onReportTap;
  final VoidCallback onRefreshTap;

  @override
  Widget build(BuildContext context) {
    final workItems = _workReportItems(report).take(4).toList(growable: false);
    final nextActions = _workReportNextActions(report).take(2).toList(
      growable: false,
    );
    final summary =
        (report?['summary'] ??
                'VisibloAI is preparing your weekly business work report.')
            .toString();

    return _OperatorCard(
      title: 'This week VisibloAI worked on',
      actionLabel: isLoading ? 'Updating' : 'View report',
      onActionTap: isLoading ? () {} : onReportTap,
      child: isLoading && report == null
          ? const _AiWorkReportLoading()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.1,
                    height: 1.35,
                    color: Color(0xFF65748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 11),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: workItems.isEmpty ? 4 : workItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.45,
                    crossAxisSpacing: 9,
                    mainAxisSpacing: 9,
                  ),
                  itemBuilder: (context, index) {
                    final item = workItems.isEmpty
                        ? _emptyWorkReportItem(index)
                        : workItems[index];
                    return _AiWorkMetricTile(item: item);
                  },
                ),
                const SizedBox(height: 11),
                if (nextActions.isEmpty)
                  const _OperatorEmptyMessage(
                    icon: Icons.auto_awesome_rounded,
                    color: Color(0xFF0E9F8B),
                    text:
                        'No urgent next action is waiting. VisibloAI will continue checking posts, reviews, keywords and profile health.',
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFE),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFE8EEF7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.next_plan_rounded,
                              color: AppColors.brandBlue,
                              size: 17,
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Next work queued',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF061A35),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Refresh work report',
                              visualDensity: VisualDensity.compact,
                              onPressed: isLoading ? null : onRefreshTap,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: AppColors.brandBlue,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ...nextActions.map(
                          (action) => Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              (action['title'] ?? 'AI action').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.7,
                                color: Color(0xFF65748B),
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

class _AiWorkReportLoading extends StatelessWidget {
  const _AiWorkReportLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
    );
  }
}

class _AiWorkMetricTile extends StatelessWidget {
  const _AiWorkMetricTile({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final code = (item['code'] ?? '').toString();
    final color = _workReportColor(code);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_workReportIcon(code), color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (item['value'] ?? 0).toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF061A35),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  (item['label'] ?? 'Work item').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.4,
                    color: Color(0xFF65748B),
                    fontWeight: FontWeight.w700,
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

class _ReviewQueueCard extends StatelessWidget {
  const _ReviewQueueCard({required this.reviews, required this.onViewAllTap});

  final List<GbpReview> reviews;
  final VoidCallback onViewAllTap;

  @override
  Widget build(BuildContext context) {
    final visibleReviews = reviews.take(2).toList(growable: false);
    final extraCount = reviews.length - visibleReviews.length;

    return _OperatorCard(
      title: reviews.isEmpty
          ? 'Review replies are under control'
          : 'AI review replies waiting',
      actionLabel: reviews.length > 2 ? 'Show more' : 'Open reviews',
      onActionTap: onViewAllTap,
      child: reviews.isEmpty
          ? const _OperatorEmptyMessage(
              icon: Icons.forum_outlined,
              color: Color(0xFF2F80ED),
              text:
                  'No unreplied reviews right now. VisibloAI will draft replies when new reviews arrive.',
            )
          : Column(
              children: [
                ...visibleReviews.map(
                  (review) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ReviewQueueTile(review: review),
                  ),
                ),
                if (extraCount > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onViewAllTap,
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: Text(
                        'Show $extraCount more review${extraCount == 1 ? '' : 's'}',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ReviewQueueTile extends StatelessWidget {
  const _ReviewQueueTile({required this.review});

  final GbpReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(
                review.reviewerInitial,
                style: const TextStyle(
                  color: Color(0xFF2F80ED),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.reviewerName.isEmpty
                            ? 'Customer review'
                            : review.reviewerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.8,
                          color: Color(0xFF061A35),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${review.starRating}/5',
                      style: const TextStyle(
                        fontSize: 11.2,
                        color: Color(0xFFFFA000),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  review.comment,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF65748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'VisibloAI has a reply draft ready',
                  style: TextStyle(
                    fontSize: 11.2,
                    color: Color(0xFF18A85E),
                    fontWeight: FontWeight.w800,
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

class _BackgroundWorkGrid extends StatelessWidget {
  const _BackgroundWorkGrid({
    required this.onWebsiteTap,
    required this.onKeywordTap,
    required this.onAuditTap,
  });

  final VoidCallback onWebsiteTap;
  final VoidCallback onKeywordTap;
  final VoidCallback onAuditTap;

  @override
  Widget build(BuildContext context) {
    return _OperatorCard(
      title: 'More ways VisibloAI is strengthening your profile',
      actionLabel: 'View audit',
      onActionTap: onAuditTap,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _BackgroundWorkTile(
                  icon: Icons.language_rounded,
                  color: const Color(0xFF106CFF),
                  title: 'SEO website',
                  subtitle: 'One-click SEO-ready site for local enquiries.',
                  onTap: onWebsiteTap,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _BackgroundWorkTile(
                  icon: Icons.travel_explore_rounded,
                  color: const Color(0xFF18A85E),
                  title: 'AI keywords',
                  subtitle: 'Service + city keywords suggested for tracking.',
                  onTap: onKeywordTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _BackgroundWorkTile(
            icon: Icons.health_and_safety_outlined,
            color: const Color(0xFFFF8A00),
            title: 'Profile health',
            subtitle:
                'VisibloAI checks missing services, weak content and listing issues.',
            onTap: onAuditTap,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _BackgroundWorkTile extends StatelessWidget {
  const _BackgroundWorkTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.fullWidth = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFE),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EEF7)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.7,
                        color: Color(0xFF061A35),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: fullWidth ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.8,
                        height: 1.22,
                        color: Color(0xFF65748B),
                        fontWeight: FontWeight.w600,
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
  }
}

class _OperatorCard extends StatelessWidget {
  const _OperatorCard({
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
    required this.child,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
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
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.3,
                    color: Color(0xFF061A35),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: onActionTap,
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 11.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _OperatorEmptyMessage extends StatelessWidget {
  const _OperatorEmptyMessage({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11.8,
                height: 1.3,
                color: Color(0xFF65748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
  const _ReachChartCard({
    required this.reach,
    required this.insights,
    required this.previousInsights,
  });

  final int reach;
  final LocationInsightsResponse? insights;
  final LocationInsightsResponse? previousInsights;

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
            'Reach Overview (Last 30 Days)',
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
                        _ReachDeltaText(
                          current: reach,
                          previous: _googleViews(previousInsights),
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

class _ReachDeltaText extends StatelessWidget {
  const _ReachDeltaText({required this.current, required this.previous});

  final int current;
  final int previous;

  @override
  Widget build(BuildContext context) {
    final delta = _formatReachDeltaText(current, previous);
    final isNegative = delta.startsWith('-');
    final isZero = delta == '0%' || delta == '+0%';
    final icon = isZero
        ? Icons.remove_rounded
        : isNegative
        ? Icons.south_east_rounded
        : Icons.north_east_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Colors.white),
        const SizedBox(width: 2),
        Text(
          delta.startsWith('+') ? delta.substring(1) : delta,
          style: const TextStyle(
            fontSize: 11.2,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
            ...items.map((item) => _ActivityTile(item: item)),
        ],
      ),
    );
  }
}

class _ActivityNotificationsPage extends StatelessWidget {
  const _ActivityNotificationsPage({
    required this.items,
    required this.onViewAllTap,
  });

  final List<_ActivityItem> items;
  final VoidCallback onViewAllTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.brandBlue,
          ),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF061A35),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: items.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 54,
                    color: Color(0xFF9AA8BA),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: Color(0xFF162845),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Your recent business activity will appear here.',
                    style: TextStyle(
                      color: Color(0xFF6B7890),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(2, 0, 2, 10),
                  child: Text(
                    'Recent Activity',
                    style: TextStyle(
                      color: Color(0xFF65748B),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ...items.map((item) => _ActivityTile(item: item)),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onViewAllTap,
                  child: const Text(
                    'See All Activity',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final _ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
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
            Icon(item.trailingIcon, color: const Color(0xFF7D8AA0), size: 18),
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

List<GbpPost> _todayGooglePostHighlights(List<GbpPost> posts) {
  final now = DateTime.now();
  final todayPosts = posts
      .where((post) {
        final visibleDate = post.scheduledFor ?? post.createdAt;
        if (!_isSameDay(visibleDate, now)) return false;
        return true;
      })
      .toList(growable: false);

  todayPosts.sort((a, b) {
    final aFailed = _isFailedGbpPost(a);
    final bFailed = _isFailedGbpPost(b);
    if (aFailed != bFailed) {
      return aFailed ? -1 : 1;
    }
    final aPublishing = _isPublishingGbpPost(a);
    final bPublishing = _isPublishingGbpPost(b);
    if (aPublishing != bPublishing) {
      return aPublishing ? -1 : 1;
    }
    final aLive = _isPublishedGbpPost(a);
    final bLive = _isPublishedGbpPost(b);
    if (aLive != bLive) {
      return aLive ? -1 : 1;
    }
    final first = a.scheduledFor ?? a.createdAt;
    final second = b.scheduledFor ?? b.createdAt;
    return first.compareTo(second);
  });
  return todayPosts;
}

bool _isFailedGbpPost(GbpPost post) {
  final status = post.publishStatus.toUpperCase();
  return status == 'FAILED' ||
      status == 'REJECTED' ||
      post.status == GbpPostStatus.failed;
}

bool _isPublishedGbpPost(GbpPost post) {
  final status = post.publishStatus.toUpperCase();
  return status == 'LIVE' ||
      status == 'PUBLISHED' ||
      post.status == GbpPostStatus.live;
}

bool _isPublishingGbpPost(GbpPost post) {
  return post.publishStatus.toUpperCase() == 'PUBLISHING';
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
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

  final values = _bucketReachDailyValues(daily);
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

  final labelSource = _bucketReachDailyLabels(daily);
  return labelSource
      .map((item) {
        final date = DateTime.tryParse(item.date);
        if (date == null) {
          return item.date;
        }
        return '${_monthShort(date.month)} ${date.day}';
      })
      .toList(growable: false);
}

List<int> _bucketReachDailyValues(List<DailyInsight> daily) {
  if (daily.length <= 7) {
    return daily
        .map((item) => item.searchImpressions + item.mapsImpressions)
        .toList(growable: false);
  }

  final values = <int>[];
  for (var bucketIndex = 0; bucketIndex < 7; bucketIndex++) {
    final start = (bucketIndex * daily.length / 7).floor();
    final end = ((bucketIndex + 1) * daily.length / 7).floor();
    final slice = daily.sublist(start, end <= start ? start + 1 : end);
    values.add(
      slice.fold<int>(
        0,
        (sum, item) => sum + item.searchImpressions + item.mapsImpressions,
      ),
    );
  }
  return values;
}

List<DailyInsight> _bucketReachDailyLabels(List<DailyInsight> daily) {
  if (daily.length <= 7) {
    return daily;
  }

  return List<DailyInsight>.generate(7, (bucketIndex) {
    final end = (((bucketIndex + 1) * daily.length / 7).floor() - 1).clamp(
      0,
      daily.length - 1,
    );
    return daily[end];
  }, growable: false);
}

String _formatReachDeltaText(int current, int previous) {
  if (previous <= 0) {
    return current <= 0 ? '0%' : '+100%';
  }
  final rounded = (((current - previous) / previous) * 100).round();
  return rounded > 0 ? '+$rounded%' : '$rounded%';
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

IconData _typeIcon(String type) {
  switch (type) {
    case 'REVIEW_REPLY':
      return Icons.forum_outlined;
    case 'SEO_KEYWORD':
      return Icons.travel_explore_rounded;
    case 'PROFILE_FIX':
      return Icons.tune_rounded;
    case 'GBP_CONTENT_CALENDAR':
      return Icons.calendar_month_outlined;
    case 'GBP_POST':
      return Icons.post_add_rounded;
    case 'CREATIVE':
    case 'CREATIVE_GENERATION':
      return Icons.image_outlined;
    case 'WEEKLY_REPORT':
      return Icons.analytics_outlined;
    default:
      return Icons.auto_awesome_rounded;
  }
}

Color _typeColor(String type) {
  switch (type) {
    case 'REVIEW_REPLY':
      return const Color(0xFF2F80ED);
    case 'SEO_KEYWORD':
      return const Color(0xFF18A85E);
    case 'PROFILE_FIX':
      return const Color(0xFFFF8A00);
    case 'GBP_CONTENT_CALENDAR':
      return const Color(0xFF0E9F8B);
    case 'GBP_POST':
      return const Color(0xFF7C3AED);
    case 'CREATIVE':
    case 'CREATIVE_GENERATION':
      return const Color(0xFFEC4899);
    case 'WEEKLY_REPORT':
      return const Color(0xFF0891B2);
    default:
      return const Color(0xFF106CFF);
  }
}

List<String> _keywordSuggestions(AiManagerAction action) {
  if (action.type != 'SEO_KEYWORD') return const <String>[];
  final raw = action.payload['suggestions'];
  if (raw is! List) return const <String>[];
  return raw
      .map((value) => value.toString().trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

List<String> _calendarActionHighlights(AiManagerAction action) {
  if (action.type != 'GBP_CONTENT_CALENDAR') return const <String>[];
  final labels = <String>[];
  final plannedCount = _intFromAny(action.payload['plannedPostCount']);
  if (plannedCount > 0) {
    labels.add('$plannedCount posts');
  }
  final rawFestivals = action.payload['festivals'];
  if (rawFestivals is List) {
    for (final rawFestival in rawFestivals) {
      final festival = _mapFromAny(rawFestival);
      final name = _stringFromAny(festival['name']);
      if (name.isNotEmpty) {
        labels.add(name);
      }
    }
  }
  return labels;
}

List<_ReviewReplySuggestion> _reviewReplySuggestions(AiManagerAction action) {
  if (action.type != 'REVIEW_REPLY') return const <_ReviewReplySuggestion>[];
  final rawReplies = action.payload['suggestedReplies'];
  if (rawReplies is! List) return const <_ReviewReplySuggestion>[];

  final reviewsById = <String, Map<String, dynamic>>{};
  final rawReviews = action.payload['reviews'];
  if (rawReviews is List) {
    for (final rawReview in rawReviews) {
      final review = _mapFromAny(rawReview);
      final id = _stringFromAny(review['id']);
      if (id.isNotEmpty) {
        reviewsById[id] = review;
      }
    }
  }

  return rawReplies
      .map((rawReply) {
        final reply = _mapFromAny(rawReply);
        final reviewId = _stringFromAny(reply['reviewId']);
        final review = reviewsById[reviewId] ?? const <String, dynamic>{};
        return _ReviewReplySuggestion(
          reviewId: reviewId,
          reviewerName: _stringFromAny(review['reviewerName']),
          starRating: _intFromAny(review['starRating']),
          commentText: _stringFromAny(review['commentText']),
          replyText: _stringFromAny(reply['replyText']),
        );
      })
      .where((reply) => reply.replyText.isNotEmpty)
      .toList(growable: false);
}

class _ReviewReplySuggestion {
  const _ReviewReplySuggestion({
    required this.reviewId,
    required this.reviewerName,
    required this.starRating,
    required this.commentText,
    required this.replyText,
  });

  final String reviewId;
  final String reviewerName;
  final int starRating;
  final String commentText;
  final String replyText;
}

Map<String, dynamic> _mapFromAny(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, dynamic>{};
}

String _stringFromAny(Object? value) {
  return value?.toString().trim() ?? '';
}

int _intFromAny(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

Color _statusColor(String status) {
  switch (status) {
    case 'COMPLETED':
      return const Color(0xFF18A85E);
    case 'APPROVED':
      return const Color(0xFF106CFF);
    case 'RUNNING':
      return const Color(0xFFFF8A00);
    case 'FAILED':
      return const Color(0xFFE54B5B);
    case 'PREVIEW':
      return const Color(0xFF0E9F8B);
    default:
      return const Color(0xFF7C3AED);
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'PENDING_APPROVAL':
      return 'Review';
    case 'APPROVED':
      return 'Approved';
    case 'RUNNING':
      return 'Running';
    case 'COMPLETED':
      return 'Done';
    case 'FAILED':
      return 'Failed';
    case 'PREVIEW':
      return 'Planned';
    default:
      return status.replaceAll('_', ' ').toLowerCase();
  }
}

List<Map<String, dynamic>> _healthFindings(Map<String, dynamic>? report) {
  final raw = report?['findings'];
  if (raw is! List) return const <Map<String, dynamic>>[];
  return raw
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
      .toList(growable: false);
}

int _healthScore(Map<String, dynamic>? report) {
  final value = report?['score'];
  if (value is int) return value.clamp(0, 100);
  if (value is num) return value.round().clamp(0, 100);
  return 0;
}

Color _healthScoreColor(int score) {
  if (score >= 85) return const Color(0xFF18A85E);
  if (score >= 70) return const Color(0xFF0E9F8B);
  if (score >= 55) return const Color(0xFFFF8A00);
  return const Color(0xFFE94363);
}

Color _healthSeverityColor(String severity) {
  switch (severity.toUpperCase()) {
    case 'HIGH':
      return const Color(0xFFE94363);
    case 'MEDIUM':
      return const Color(0xFFFF8A00);
    default:
      return const Color(0xFF0E9F8B);
  }
}

IconData _healthFindingIcon(String actionType) {
  switch (actionType) {
    case 'REVIEW_REPLY':
    case 'REVIEW_GROWTH':
      return Icons.forum_outlined;
    case 'GBP_CONTENT_CALENDAR':
    case 'GBP_POST_RECOVERY':
      return Icons.event_available_rounded;
    case 'SEO_KEYWORD':
    case 'VISIBILITY_GROWTH':
      return Icons.travel_explore_rounded;
    case 'PROFILE_FIX':
      return Icons.storefront_rounded;
    default:
      return Icons.auto_awesome_rounded;
  }
}

List<Map<String, dynamic>> _workReportItems(Map<String, dynamic>? report) {
  final raw = report?['workItems'];
  if (raw is! List) return const <Map<String, dynamic>>[];
  return raw
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
      .toList(growable: false);
}

List<Map<String, dynamic>> _workReportNextActions(
  Map<String, dynamic>? report,
) {
  final raw = report?['nextActions'];
  if (raw is! List) return const <Map<String, dynamic>>[];
  return raw
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
      .toList(growable: false);
}

Map<String, dynamic> _emptyWorkReportItem(int index) {
  const items = [
    {
      'code': 'POSTS_PUBLISHED',
      'label': 'Google posts',
      'value': 0,
    },
    {
      'code': 'REVIEWS_REPLIED',
      'label': 'Review replies',
      'value': 0,
    },
    {
      'code': 'KEYWORDS_ADDED',
      'label': 'SEO keywords',
      'value': 0,
    },
    {
      'code': 'GAPS_FOUND',
      'label': 'Gaps found',
      'value': 0,
    },
  ];
  return items[index.clamp(0, items.length - 1)];
}

Color _workReportColor(String code) {
  switch (code) {
    case 'POSTS_PUBLISHED':
      return const Color(0xFF106CFF);
    case 'REVIEWS_REPLIED':
      return const Color(0xFF7C3AED);
    case 'KEYWORDS_ADDED':
      return const Color(0xFF18A85E);
    case 'GAPS_FOUND':
      return const Color(0xFFFF8A00);
    default:
      return const Color(0xFF0E9F8B);
  }
}

IconData _workReportIcon(String code) {
  switch (code) {
    case 'POSTS_PUBLISHED':
      return Icons.campaign_rounded;
    case 'REVIEWS_REPLIED':
      return Icons.forum_outlined;
    case 'KEYWORDS_ADDED':
      return Icons.travel_explore_rounded;
    case 'GAPS_FOUND':
      return Icons.health_and_safety_outlined;
    default:
      return Icons.auto_awesome_rounded;
  }
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
