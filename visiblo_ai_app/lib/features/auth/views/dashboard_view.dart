import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/services/local_auth_service.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/widgets/app_logo.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/gbp_post.dart';
import '../models/test_account.dart';
import '../widgets/auth_calendar_sheet.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_navigation_shell.dart';
import 'gbp_post_create_flow_view.dart';
import 'gbp_post_editor_view.dart';
import 'gbp_post_preview_view.dart';
import '../../../app/routes/app_routes.dart';

class DashboardView extends GetView<OnboardingController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthNavigationShell(
      currentTab: AuthTab.home,
      backgroundColor: _DashboardPalette.canvas,
      child: Obx(() {
        final user = controller.currentUser.value;
        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return _DashboardContent(user: user, onLogout: controller.logout);
      }),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent({required this.user, required this.onLogout});

  final TestAccount user;
  final Future<void> Function() onLogout;

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  final OnboardingController controller = Get.find<OnboardingController>();

  List<GbpPost> get _posts {
    if (controller.liveGbpPosts.isNotEmpty) {
      return controller.liveGbpPosts;
    }
    if (widget.user.backendAuthenticated ||
        widget.user.googleBusinessProfileConnected) {
      return const <GbpPost>[];
    }
    return _buildPosts(widget.user);
  }

  _PostFilter _selectedFilter = _PostFilter.all;
  int _currentPage = 1;

  List<GbpPost> get _visiblePosts {
    switch (_selectedFilter) {
      case _PostFilter.all:
        return _posts;
      case _PostFilter.drafts:
        return _posts
            .where(
              (post) =>
                  post.status == GbpPostStatus.draft ||
                  post.status == GbpPostStatus.failed,
            )
            .toList();
      case _PostFilter.scheduled:
        return _posts
            .where((post) => post.status == GbpPostStatus.scheduled)
            .toList();
      case _PostFilter.live:
        return _posts
            .where((post) => post.status == GbpPostStatus.live)
            .toList();
    }
  }

  List<GbpPost> get _schedulablePosts => _posts
      .where(
        (post) =>
            post.status == GbpPostStatus.draft ||
            post.status == GbpPostStatus.failed ||
            post.status == GbpPostStatus.scheduled,
      )
      .toList();

  int _countFor(_PostFilter filter) {
    switch (filter) {
      case _PostFilter.all:
        return _posts.length;
      case _PostFilter.drafts:
        return _posts
            .where(
              (post) =>
                  post.status == GbpPostStatus.draft ||
                  post.status == GbpPostStatus.failed,
            )
            .length;
      case _PostFilter.scheduled:
        return _posts
            .where((post) => post.status == GbpPostStatus.scheduled)
            .length;
      case _PostFilter.live:
        return _posts.where((post) => post.status == GbpPostStatus.live).length;
    }
  }

  List<_MetricData> get _metricCards => [
    _MetricData(
      value: '${_posts.length}',
      label: 'Total Post',
      icon: Icons.note_alt_outlined,
      iconColor: AppColors.brandBlue,
      iconBackground: const Color(0xFFEAF2FF),
      cardBackground: const Color(0xFFF9FBFF),
      borderColor: const Color(0xFFD8E7FF),
    ),
    _MetricData(
      value: '${_countFor(_PostFilter.live)}',
      label: 'Published',
      icon: Icons.check_circle_outline_rounded,
      iconColor: _DashboardPalette.liveGreen,
      iconBackground: const Color(0xFFE6FAEC),
      cardBackground: const Color(0xFFF7FFF9),
      borderColor: const Color(0xFFCBF1D8),
    ),
    _MetricData(
      value: '${_countFor(_PostFilter.scheduled)}',
      label: 'Scheduled',
      icon: Icons.access_time_rounded,
      iconColor: _DashboardPalette.warning,
      iconBackground: const Color(0xFFFFF2CF),
      cardBackground: const Color(0xFFFFFCF4),
      borderColor: const Color(0xFFFFE7BB),
    ),
    _MetricData(
      value: '${_countFor(_PostFilter.drafts)}',
      label: 'Drafts',
      icon: Icons.edit_outlined,
      iconColor: const Color(0xFF7C63F1),
      iconBackground: const Color(0xFFF0E9FF),
      cardBackground: const Color(0xFFFCFAFF),
      borderColor: const Color(0xFFE2D7FF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return RefreshIndicator(
        onRefresh: _doRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AuthViewSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AuthShellBackButton(),
                  const SizedBox(width: 10),
                  const Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: AppLogo(iconSize: 28, fontSize: 19),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.brandBlue,
                    ),
                    onPressed: _doRefresh,
                    tooltip: 'Refresh GBP Posts',
                  ),
                ],
              ),
              const SizedBox(height: AuthViewSpacing.cardGap),
              Obx(() {
                final livePhoto =
                    controller.liveGbpLocation.value?.photoUrl.trim() ?? '';
                return _ProfileCard(
                  user: widget.user,
                  profileImagePath: livePhoto.isNotEmpty
                      ? livePhoto
                      : widget.user.businessPhotoPath,
                  onLogout: widget.onLogout,
                  onUpdateLogo: _handleUpdateLogo,
                );
              }),
              const SizedBox(height: AuthViewSpacing.sectionGap),
              _GeneratorCard(
                businessName: _businessName(widget.user),
                onGenerate: _handleGeneratePost,
                onSchedule: _handleSchedulePost,
              ),
              const SizedBox(height: 14),
              _FilterBar(
                selectedFilter: _selectedFilter,
                draftCount: _countFor(_PostFilter.drafts),
                scheduledCount: _countFor(_PostFilter.scheduled),
                liveCount: _countFor(_PostFilter.live),
                onChanged: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                    _currentPage = 1;
                  });
                },
              ),
              const SizedBox(height: 8),
              if (_visiblePosts.isEmpty)
                const _EmptyPostsCard()
              else ...[
                ..._visiblePosts
                    .skip((_currentPage - 1) * 7)
                    .take(7)
                    .map(
                      (post) => _PostCard(
                        post: post,
                        onView: () => _handleViewPost(post),
                        onEdit: () => _handleEditPost(post),
                        onDelete: () => _handleDeletePost(post),
                        onPublish:
                            (post.status == GbpPostStatus.draft ||
                                post.status == GbpPostStatus.failed)
                            ? () => _handlePublishPost(post)
                            : null,
                        onSchedule:
                            (post.status == GbpPostStatus.draft ||
                                post.status == GbpPostStatus.failed)
                            ? () => _handleScheduleDraftPost(post)
                            : null,
                      ),
                    ),
                if (_visiblePosts.length > 7)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: _PaginationBar(
                      currentPage: _currentPage,
                      totalPages: (_visiblePosts.length / 7).ceil(),
                      onPageChanged: (page) {
                        setState(() => _currentPage = page);
                      },
                    ),
                  ),
              ],
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final sectionMaxWidth = constraints.maxWidth >= 520
                      ? 430.0
                      : constraints.maxWidth;
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: sectionMaxWidth),
                      child: Column(
                        children: [
                          Row(
                            children: _metricCards
                                .map(
                                  (metric) => Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: metric == _metricCards.last
                                            ? 0
                                            : 10,
                                      ),
                                      child: _MetricCard(metric: metric),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 14),
                          const _WeekStrip(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _doRefresh() async {
    // Reset filter to All so posts that moved (e.g. Scheduled → Live) are visible
    setState(() {
      _selectedFilter = _PostFilter.all;
      _currentPage = 1;
    });
    await Get.find<OnboardingController>().fetchDashboardLiveStream();
  }

  Future<void> _handleUpdateLogo() async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final updatedUser = widget.user.copyWith(businessPhotoPath: image.path);
        controller.currentUser.value = updatedUser;
        await Get.find<LocalAuthService>().updateCurrentUser(updatedUser);
        Get.snackbar(
          'Logo Updated',
          'Your business logo has been updated successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF22AF69),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not update logo.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFF6B73),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleGeneratePost() async {
    final created = await Get.to<GbpPost>(
      () => GbpPostCreateMethodView(
        templatePost: _buildGeneratedPost(
          user: widget.user,
          status: GbpPostStatus.draft,
        ),
        businessName: _businessName(widget.user),
      ),
    );

    if (created == null) {
      return;
    }

    if (created.status == GbpPostStatus.live) {
      final draftPost = created.copyWith(status: GbpPostStatus.draft);
      _addCreatedPost(draftPost);
      await _handlePublishPost(draftPost);
    } else if (created.status == GbpPostStatus.scheduled &&
        created.scheduledFor != null) {
      _addCreatedPost(created);
      try {
        await controller.scheduleAiPost(created.id, created.scheduledFor!);
      } catch (e) {
        if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
        Get.snackbar(
          'Schedule failed',
          e.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFF6B73),
          colorText: const Color(0xFFFFFFFF),
        );
      }
    } else {
      _addCreatedPost(created);
    }
  }

  Future<void> _handleSchedulePost() async {
    final posts = _schedulablePosts;
    if (posts.isEmpty) {
      Get.snackbar(
        'Generate a draft first',
        'Create an AI post, then schedule the exact publishing time.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF163C63),
        colorText: Colors.white,
      );
      return;
    }

    final selectedPost = await showModalBottomSheet<GbpPost>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SchedulePostPickerSheet(posts: posts),
    );

    if (selectedPost == null) return;
    await _handleScheduleDraftPost(selectedPost);
  }

  void _addCreatedPost(GbpPost created) {
    setState(() {
      controller.liveGbpPosts.insert(0, created);
      _selectedFilter = switch (created.status) {
        GbpPostStatus.draft => _PostFilter.drafts,
        GbpPostStatus.failed => _PostFilter.drafts,
        GbpPostStatus.scheduled => _PostFilter.scheduled,
        GbpPostStatus.live => _PostFilter.live,
      };
    });
  }

  Future<void> _handleViewPost(GbpPost post) async {
    await Get.to<void>(
      () => GbpPostPreviewView(
        post: post,
        businessName: _businessName(widget.user),
      ),
    );
  }

  Future<void> _handleEditPost(GbpPost post) async {
    final updated = await Get.to<GbpPost>(
      () => GbpPostEditorView(
        initialPost: post,
        businessName: _businessName(widget.user),
      ),
    );

    if (updated == null) {
      return;
    }

    setState(() {
      final index = _posts.indexWhere((item) => item.id == updated.id);
      if (index != -1) {
        _posts[index] = updated;
      }
    });
  }

  Future<void> _handleDeletePost(GbpPost post) async {
    final isLive =
        post.status == GbpPostStatus.live ||
        post.status == GbpPostStatus.scheduled ||
        post.status == GbpPostStatus.failed;
    final String? action = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete post?',
            style: TextStyle(
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            isLive
                ? 'This post is currently live or scheduled on your Google Business Profile. What would you like to do?'
                : 'This will permanently delete "${post.title}".',
            style: const TextStyle(color: AppColors.text, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (isLive)
              Tooltip(
                message: post.id.contains('/')
                    ? 'Posts created directly on Google cannot be reverted to draft in VisibloAI'
                    : '',
                child: TextButton(
                  onPressed: post.id.contains('/')
                      ? null
                      : () => Navigator.of(context).pop('revert'),
                  style: TextButton.styleFrom(
                    backgroundColor: post.id.contains('/')
                        ? Colors.grey.shade200
                        : const Color(0xFFF0E9FF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Revert to Draft',
                    style: TextStyle(
                      color: post.id.contains('/')
                          ? Colors.grey.shade600
                          : const Color(0xFF7C63F1),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('delete'),
              child: const Text(
                'Delete Permanently',
                style: TextStyle(
                  color: _DashboardPalette.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (action == null || action == 'cancel') {
      return;
    }

    try {
      final revertToDraft = action == 'revert';

      if (post.id.contains('/')) {
        // GBP-only post
        await controller.deleteGbpPost(post.id);
      } else {
        // AI Post
        await controller.deleteAiPost(post.id, revertToDraft: revertToDraft);
      }

      if (revertToDraft) {
        // Move the post to DRAFT in the local observable list
        final liveList = controller.liveGbpPosts;
        final index = liveList.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          liveList[index] = post.copyWith(status: GbpPostStatus.draft);
        }
        setState(() {
          _selectedFilter = _PostFilter.drafts;
        });
        Get.snackbar(
          'Reverted to Draft',
          'Post removed from Google and saved as draft.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF7C63F1),
          colorText: const Color(0xFFFFFFFF),
        );
      } else {
        // Remove from local list entirely
        controller.liveGbpPosts.removeWhere((item) => item.id == post.id);
        Get.snackbar(
          'Post deleted',
          'The post has been permanently deleted.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFF6B73),
        colorText: const Color(0xFFFFFFFF),
      );
    }
  }

  Future<void> _handlePublishPost(GbpPost post) async {
    // Show a loading snackbar
    Get.snackbar(
      'Publishing...',
      'Sending your post to Google Business Profile.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 60),
      showProgressIndicator: true,
    );

    try {
      final publishedPost = await controller.publishAiPost(post.id);

      final liveList = controller.liveGbpPosts;
      final index = liveList.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        liveList[index] = publishedPost;
      }
      setState(() {
        _selectedFilter = _PostFilter.live;
      });

      if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
      Get.snackbar(
        'Published! 🎉',
        'Your post is now live on Google Business Profile.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF22AF69),
        colorText: const Color(0xFFFFFFFF),
      );

      // Re-fetch from server so this device AND the web dashboard both
      // reflect the true server state (LIVE or FAILED).
      await controller.fetchDashboardLiveStream();
    } catch (e) {
      if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
      Get.snackbar(
        'Publish failed',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFF6B73),
        colorText: const Color(0xFFFFFFFF),
      );
      // Still re-fetch so we show accurate status
      await controller.fetchDashboardLiveStream();
    }
  }

  Future<void> _handleScheduleDraftPost(GbpPost post) async {
    final now = DateTime.now();
    final initialSchedule =
        post.scheduledFor != null && post.scheduledFor!.isAfter(now)
        ? post.scheduledFor!
        : now.add(const Duration(days: 1));
    final pickedDate = await showAuthCalendarSheet(
      context: context,
      initialDate: initialSchedule,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      title: post.status == GbpPostStatus.scheduled
          ? 'Change Schedule'
          : 'Schedule Post',
    );

    if (pickedDate == null) return;
    if (!mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialSchedule),
    );

    if (selectedTime == null) return;

    final scheduledDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // Optimistically update local state so the UI feels instant
    final scheduledPost = post.copyWith(
      status: GbpPostStatus.scheduled,
      scheduledFor: scheduledDateTime,
    );
    final index = controller.liveGbpPosts.indexWhere((p) => p.id == post.id);
    if (index != -1) {
      controller.liveGbpPosts[index] = scheduledPost;
    }
    setState(() {
      _selectedFilter = _PostFilter.scheduled;
      _currentPage = 1;
    });

    // ── CRITICAL: persist the schedule to the backend ──────────────────────
    try {
      await controller.scheduleAiPost(post.id, scheduledDateTime);
      if (!mounted) return;
      Get.snackbar(
        'Post Scheduled 📅',
        'Your post is scheduled for ${_formatDateTime(scheduledDateTime)}.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF2C90FC),
        colorText: Colors.white,
      );
    } catch (e) {
      // Roll back the optimistic update if the API call fails
      if (index != -1) {
        controller.liveGbpPosts[index] = post;
      }
      if (mounted) {
        setState(() {
          _selectedFilter = _PostFilter.drafts;
          _currentPage = 1;
        });
        Get.snackbar(
          'Schedule Failed',
          e.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFF6B73),
          colorText: Colors.white,
        );
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    return '${dt.day}/${dt.month}/${dt.year} at $hour:${dt.minute.toString().padLeft(2, '0')} $period';
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.profileImagePath,
    required this.onLogout,
    required this.onUpdateLogo,
  });

  final TestAccount user;
  final String profileImagePath;
  final Future<void> Function() onLogout;
  final VoidCallback onUpdateLogo;

  String _formatPlanName(String planId) {
    switch (planId.trim().toLowerCase()) {
      case 'single':
      case 'starter':
        return 'Starter Plan';
      case 'pro':
      case 'growth':
        return 'Growth Plan';
      case 'premium':
      case 'enterprise':
        return 'Business Pro';
      default:
        return 'Plan';
    }
  }

  String get _profileStatusLabel {
    final business = _activeBusiness;
    final locked =
        _readBool(business?['locked']) || _readBool(business?['isPaused']);
    if (locked) return 'Locked';
    if (!user.googleBusinessProfileConnected) return 'Not connected';
    return 'Profile Active';
  }

  Color get _profileStatusColor {
    if (_profileStatusLabel == 'Locked') return _DashboardPalette.danger;
    if (_profileStatusLabel == 'Not connected') {
      return _DashboardPalette.warning;
    }
    return _DashboardPalette.liveGreen;
  }

  Color get _profileStatusBackground {
    if (_profileStatusLabel == 'Locked') return _DashboardPalette.dangerSoft;
    if (_profileStatusLabel == 'Not connected') {
      return _DashboardPalette.warningSoft;
    }
    return _DashboardPalette.liveSoft;
  }

  Map<String, dynamic>? get _activeBusiness {
    for (final business in user.backendAvailableBusinesses) {
      if ((business['id'] ?? '').toString().trim() ==
          user.backendBusinessId.trim()) {
        return business;
      }
    }
    return user.backendAvailableBusinesses.isNotEmpty
        ? user.backendAvailableBusinesses.first
        : null;
  }

  bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  ImageProvider? _profileImageProvider() {
    final value = profileImagePath.trim();
    if (value.isEmpty) {
      return null;
    }
    final lower = value.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return NetworkImage(value);
    }
    final file = File(value);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _profileImageProvider();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6F0F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F2746),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onUpdateLogo,
            child: Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8FC),
                    shape: BoxShape.circle,
                    image: imageProvider != null
                        ? DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A39B4BD),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: imageProvider == null
                      ? const Icon(
                          Icons.storefront_rounded,
                          color: AppColors.brandBlue,
                          size: 24,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.2),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_businessName(user)}, ${_locationLabel(user)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.15,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      _BadgePill(
                        label: _profileStatusLabel,
                        foreground: _profileStatusColor,
                        background: _profileStatusBackground,
                        icon: Icons.circle,
                      ),
                      const SizedBox(width: 8),
                      _BadgePill(
                        label: _formatPlanName(user.subscriptionPlanId),
                        foreground: _DashboardPalette.warning,
                        background: _DashboardPalette.warningSoft,
                        icon: Icons.star_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await onLogout();
              }
            },
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: _DashboardPalette.danger,
                    ),
                    SizedBox(width: 8),
                    Text('Log out'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 28,
                color: AppColors.text.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratorCard extends StatelessWidget {
  const _GeneratorCard({
    required this.businessName,
    required this.onGenerate,
    required this.onSchedule,
  });

  final String businessName;
  final VoidCallback onGenerate;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _GooglePostHeader(),
        const SizedBox(height: 18),
        Text(
          'Create, manage, and publish high-converting GBP posts powered by AI',
          style: TextStyle(
            fontSize: 14.5,
            height: 1.5,
            color: AppColors.text,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _DashboardPalette.generatorBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0E16335B),
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI-Powered Content',
                style: TextStyle(
                  fontSize: 16.5,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(
                    child: _FeatureText(label: 'AI-optimized posting times'),
                  ),
                  SizedBox(width: 18),
                  Expanded(child: _FeatureText(label: 'Smart GBP post timing')),
                ],
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Expanded(
                    child: _FeatureText(label: 'AI content visibility boost'),
                  ),
                  SizedBox(width: 18),
                  Expanded(
                    child: _FeatureText(label: 'Visibility-optimized posts'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _GradientActionButton(
                      label: 'Generate',
                      icon: Icons.auto_awesome_rounded,
                      onTap: onGenerate,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _OutlineActionButton(
                      label: 'Schedule',
                      icon: Icons.schedule_rounded,
                      onTap: onSchedule,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight = constraints.maxWidth < 78;
        final iconBoxSize = isTight ? 26.0 : 30.0;
        final valueFontSize = isTight ? 16.0 : 18.0;
        final labelFontSize = isTight ? 9.0 : 10.3;

        return SizedBox(
          height: 112,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              isTight ? 9 : 10,
              10,
              isTight ? 7 : 8,
              10,
            ),
            decoration: BoxDecoration(
              color: metric.cardBackground,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: metric.borderColor),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0E16335B),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: metric.iconBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    metric.icon,
                    size: isTight ? 15 : 17,
                    color: metric.iconColor,
                  ),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    metric.value,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      height: 1,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  metric.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    height: 1.15,
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
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

class _WeekStrip extends StatefulWidget {
  const _WeekStrip();

  @override
  State<_WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<_WeekStrip> {
  DateTime _selectedDate = DateTime.now();

  List<DateTime> get _weekDates {
    final start = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    return List<DateTime>.generate(
      7,
      (index) => DateTime(start.year, start.month, start.day + index),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showAuthCalendarSheet(
      context: context,
      title: 'Publishing Calendar',
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2032),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Color? _markerFor(DateTime date) {
    if (_isSameDay(date, _selectedDate)) {
      return null;
    }

    switch (date.weekday) {
      case DateTime.tuesday:
        return AppColors.brandBlue;
      case DateTime.friday:
        return _DashboardPalette.warning;
      case DateTime.sunday:
        return AppColors.primary;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7F4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1016335B),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.stop_rounded,
                  size: 10,
                  color: AppColors.brandBlue,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'This week',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _pickDate(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'View calendar',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.brandBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _weekDates
                .map(
                  (date) => Expanded(
                    child: _CalendarBubble(
                      day: _weekdayLabel(date.weekday),
                      date: '${date.day}',
                      selected: _isSameDay(date, _selectedDate),
                      markerColor: _markerFor(date),
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selectedFilter,
    required this.draftCount,
    required this.scheduledCount,
    required this.liveCount,
    required this.onChanged,
  });

  final _PostFilter selectedFilter;
  final int draftCount;
  final int scheduledCount;
  final int liveCount;
  final ValueChanged<_PostFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All Posts',
            selected: selectedFilter == _PostFilter.all,
            onTap: () => onChanged(_PostFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Drafts',
            count: draftCount,
            selected: selectedFilter == _PostFilter.drafts,
            onTap: () => onChanged(_PostFilter.drafts),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Scheduled',
            count: scheduledCount,
            selected: selectedFilter == _PostFilter.scheduled,
            onTap: () => onChanged(_PostFilter.scheduled),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Live',
            count: liveCount,
            selected: selectedFilter == _PostFilter.live,
            onTap: () => onChanged(_PostFilter.live),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    this.onPublish,
    this.onSchedule,
  });

  final GbpPost post;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onPublish;
  final VoidCallback? onSchedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AuthViewSpacing.cardGap),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _DashboardPalette.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2746),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: post.assetPath.isEmpty
                    ? Container(
                        width: double.infinity,
                        height: 214,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF2FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.image_outlined,
                          color: Color(0xFF90AFCC),
                          size: 48,
                        ),
                      )
                    : post.isBase64Asset
                    ? Image.memory(
                        base64Decode(
                          post.assetPath.substring(
                            post.assetPath.indexOf(',') + 1,
                          ),
                        ),
                        width: double.infinity,
                        height: 214,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: 214,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : post.isNetworkAsset
                    ? Image.network(
                        post.assetPath,
                        width: double.infinity,
                        height: 214,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: 214,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : post.isFileAsset
                    ? Image.file(
                        File(post.assetPath),
                        width: double.infinity,
                        height: 214,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: 214,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Image.asset(
                        post.assetPath,
                        width: double.infinity,
                        height: 214,
                        fit: BoxFit.cover,
                      ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: _BadgePill(
                  label: post.badgeLabel,
                  foreground: _badgeForeground(post.status),
                  background: _badgeBackground(post.status),
                  icon: Icons.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 15,
              height: 1.3,
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          _ExpandableText(text: post.subtitle),
          const SizedBox(height: 7),
          Text(
            post.meta,
            style: const TextStyle(
              fontSize: 11,
              height: 1.45,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            post.scheduledLabel ?? post.createdLabel,
            style: TextStyle(
              fontSize: 10.5,
              color: post.scheduledLabel == null
                  ? AppColors.mutedText
                  : const Color(0xFF9A691B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          // Row 1: View | Edit | Delete
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'View',
                  icon: Icons.remove_red_eye_outlined,
                  foreground: AppColors.brandBlue,
                  background: AppColors.softBlue,
                  borderColor: const Color(0xFFD4E8FF),
                  onPressed: onView,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  foreground: const Color(0xFF7C63F1),
                  background: const Color(0xFFF3EEFF),
                  borderColor: const Color(0xFFE0D8FF),
                  onPressed: onEdit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  foreground: _DashboardPalette.danger,
                  background: const Color(0xFFFFF0F0),
                  borderColor: const Color(0xFFFFD5D8),
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
          // Row 2: Publish Now (only for drafts)
          if (post.status == GbpPostStatus.failed &&
              post.errorMessage == 'Auth Required') ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.googleOAuth),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFFFFF),
                  backgroundColor: const Color(0xFFE53935),
                  side: const BorderSide(color: Color(0xFFD32F2F)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                icon: const Icon(
                  Icons.link_off_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  'Reconnect Account',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ] else if (onPublish != null || onSchedule != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (onSchedule != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSchedule,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColors.brandBlue,
                        side: const BorderSide(color: AppColors.brandBlue),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Schedule',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (onSchedule != null && onPublish != null)
                  const SizedBox(width: 8),
                if (onPublish != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onPublish,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFFFFFF),
                        backgroundColor: _DashboardPalette.liveGreen,
                        side: const BorderSide(color: Color(0xFF1A9A58)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      icon: const Icon(
                        Icons.send_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Publish',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SchedulePostPickerSheet extends StatelessWidget {
  const _SchedulePostPickerSheet({required this.posts});

  final List<GbpPost> posts;

  @override
  Widget build(BuildContext context) {
    final draftCount = posts
        .where(
          (post) =>
              post.status == GbpPostStatus.draft ||
              post.status == GbpPostStatus.failed,
        )
        .length;
    final scheduledCount = posts
        .where((post) => post.status == GbpPostStatus.scheduled)
        .length;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6DEE8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 12, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule a Google post',
                            style: TextStyle(
                              fontSize: 17,
                              color: AppColors.brandBlue,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Choose a draft or update an existing schedule.',
                            style: TextStyle(
                              fontSize: 12.2,
                              height: 1.35,
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFFE45A62),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    _ScheduleSummaryPill(
                      label: '$draftCount drafts',
                      color: const Color(0xFF7C63F1),
                      background: const Color(0xFFF3EEFF),
                    ),
                    const SizedBox(width: 8),
                    _ScheduleSummaryPill(
                      label: '$scheduledCount scheduled',
                      color: const Color(0xFFDB8A00),
                      background: const Color(0xFFFFF3D9),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFE8EDF3)),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                  itemCount: posts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _SchedulePostPickerTile(
                      post: post,
                      onTap: () => Navigator.of(context).pop(post),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SchedulePostPickerTile extends StatelessWidget {
  const _SchedulePostPickerTile({required this.post, required this.onTap});

  final GbpPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isScheduled = post.status == GbpPostStatus.scheduled;
    final statusColor = isScheduled
        ? const Color(0xFFDB8A00)
        : const Color(0xFF7C63F1);
    final statusBackground = isScheduled
        ? const Color(0xFFFFF3D9)
        : const Color(0xFFF3EEFF);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _DashboardPalette.cardBorder),
        ),
        child: Row(
          children: [
            _SchedulePostThumb(post: post),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.4,
                      height: 1.25,
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isScheduled
                        ? post.scheduledLabel ?? 'Scheduled'
                        : 'Draft ready to schedule',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.2,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBackground,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isScheduled ? 'Scheduled' : 'Draft',
                          style: TextStyle(
                            fontSize: 10.4,
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          post.meta.isEmpty
                              ? 'Google Business Profile'
                              : post.meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.8,
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.brandBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isScheduled ? 'Change\ntime' : 'Schedule',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.6,
                  height: 1.1,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchedulePostThumb extends StatelessWidget {
  const _SchedulePostThumb({required this.post});

  final GbpPost post;

  @override
  Widget build(BuildContext context) {
    const size = 58.0;
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(
        Icons.image_outlined,
        size: 24,
        color: Color(0xFF90AFCC),
      ),
    );

    if (post.assetPath.isEmpty) return placeholder;

    Widget image;
    if (post.isBase64Asset) {
      image = Image.memory(
        base64Decode(post.assetPath.substring(post.assetPath.indexOf(',') + 1)),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else if (post.isNetworkAsset) {
      image = Image.network(
        post.assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else if (post.isFileAsset) {
      image = Image.file(
        File(post.assetPath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else {
      image = Image.asset(
        post.assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

    return ClipRRect(borderRadius: BorderRadius.circular(13), child: image);
  }
}

class _ScheduleSummaryPill extends StatelessWidget {
  const _ScheduleSummaryPill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GooglePostHeader extends StatelessWidget {
  const _GooglePostHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        _GoogleWordmark(),
        SizedBox(width: 10),
        _PostStoreGlyph(),
        SizedBox(width: 10),
        Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text(
            'POST',
            style: TextStyle(
              fontSize: 16,
              letterSpacing: 1.2,
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleWordmark extends StatelessWidget {
  const _GoogleWordmark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'G',
              style: TextStyle(
                fontSize: 24,
                height: 1,
                color: Color(0xFF4285F4),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'o',
              style: TextStyle(
                fontSize: 24,
                height: 1,
                color: Color(0xFFEA4335),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'o',
              style: TextStyle(
                fontSize: 24,
                height: 1,
                color: Color(0xFFFBBC05),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'g',
              style: TextStyle(
                fontSize: 24,
                height: 1,
                color: Color(0xFF4285F4),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'l',
              style: TextStyle(
                fontSize: 24,
                height: 1,
                color: Color(0xFF34A853),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'e',
              style: TextStyle(
                fontSize: 24,
                height: 1,
                color: Color(0xFFEA4335),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Text(
            'My Business',
            style: TextStyle(
              fontSize: 9.5,
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PostStoreGlyph extends StatelessWidget {
  const _PostStoreGlyph();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 26,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF5B97D3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Positioned(
            top: 2,
            child: Row(
              children: List.generate(
                4,
                (index) => Container(
                  width: 5.5,
                  height: 7,
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? const Color(0xFF4E7FBE)
                        : const Color(0xFF7CB4EA),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 3,
            right: 4,
            child: Text(
              'G',
              style: TextStyle(
                fontSize: 8,
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureText extends StatelessWidget {
  const _FeatureText({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11.5,
        height: 1.4,
        color: AppColors.brandBlue,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB827FC),
            Color(0xFF2C90FC),
            Color(0xFFB8FD33),
            Color(0xFFFEC837),
            Color(0xFFFD1892),
          ],
          stops: [0.0, 0.25, 0.50, 0.75, 1.0],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Material(
          color: const Color(0xFFFEFFFF),
          borderRadius: BorderRadius.circular(999),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15.2,
                      color: Color(0xFF33B4C4),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 20, color: const Color(0xFF33B4C4)),
                ],
              ),
            ),
          ),
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.brandBlue,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.brandBlue, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 21, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({
    required this.label,
    required this.foreground,
    required this.background,
    required this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: icon == Icons.circle ? 8 : 12, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarBubble extends StatelessWidget {
  const _CalendarBubble({
    required this.day,
    required this.date,
    required this.selected,
    required this.onTap,
    this.markerColor,
  });

  final String day;
  final String date;
  final bool selected;
  final VoidCallback onTap;
  final Color? markerColor;

  @override
  Widget build(BuildContext context) {
    final background = selected ? AppColors.brandBlue : AppColors.white;
    final foreground = selected ? AppColors.white : AppColors.brandBlue;
    final border = selected ? AppColors.brandBlue : const Color(0xFFCCD3E0);
    final dayColor = selected ? AppColors.brandBlue : const Color(0xFF666C78);

    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = constraints.maxWidth.clamp(34.0, 44.0);
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              children: [
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 10.8,
                    color: dayColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: diameter,
                  height: diameter,
                  decoration: BoxDecoration(
                    color: background,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: border,
                      width: selected ? 0 : 1.25,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: diameter < 40 ? 16.2 : 17.4,
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!selected && markerColor != null)
                        Positioned(
                          bottom: diameter < 40 ? 4 : 5,
                          child: Container(
                            width: diameter < 40 ? 5.5 : 6.5,
                            height: diameter < 40 ? 5.5 : 6.5,
                            decoration: BoxDecoration(
                              color: markerColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onTap,
    this.count,
    this.selected = false,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.primary
        : _DashboardPalette.unselectedPillBorder;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: selected ? AppColors.primary : AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 11.5,
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.78)
                      : AppColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.borderColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: background,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyPostsCard extends StatelessWidget {
  const _EmptyPostsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _DashboardPalette.cardBorder),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy_outlined, size: 28, color: AppColors.mutedText),
          SizedBox(height: 10),
          Text(
            'No posts in this section yet',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Try a different filter or generate a new GBP post.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

String _businessName(TestAccount user) {
  if (user.businessName.trim().isNotEmpty) {
    return user.businessName.trim();
  }
  if (user.fullName.trim().isNotEmpty) {
    return user.fullName.trim();
  }
  return 'VisibloAI Business';
}

String _locationLabel(TestAccount user) {
  if (user.city.trim().isNotEmpty) {
    return user.city.trim();
  }
  if (user.country.trim().isNotEmpty) {
    return user.country.trim();
  }
  return 'Profile';
}

String _weekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Mo';
    case DateTime.tuesday:
      return 'Tu';
    case DateTime.wednesday:
      return 'We';
    case DateTime.thursday:
      return 'Th';
    case DateTime.friday:
      return 'Fr';
    case DateTime.saturday:
      return 'Sa';
    case DateTime.sunday:
      return 'Su';
    default:
      return '';
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _postAssetForUser(TestAccount user) {
  final category =
      '${user.industry} ${user.categoryTitle} ${user.categorySubtitle}'
          .toLowerCase();

  if (category.contains('clinic') ||
      category.contains('dental') ||
      category.contains('skin') ||
      category.contains('health')) {
    return 'assets/images/doctor.png';
  }
  if (category.contains('salon') ||
      category.contains('spa') ||
      category.contains('makeup')) {
    return 'assets/images/parlour.png';
  }
  if (category.contains('cafe') ||
      category.contains('bakery') ||
      category.contains('coffee')) {
    return 'assets/images/bakery.png';
  }
  if (category.contains('fashion') || category.contains('boutique')) {
    return 'assets/images/mall.png';
  }
  if (category.contains('gym') || category.contains('fitness')) {
    return 'assets/images/fitness.png';
  }
  return 'assets/images/office.png';
}

GbpPost _buildGeneratedPost({
  required TestAccount user,
  required GbpPostStatus status,
}) {
  final businessName = _businessName(user);
  final businessTag = businessName.replaceAll(RegExp(r'\s+'), '');
  return GbpPost(
    id: 'post-${DateTime.now().microsecondsSinceEpoch}',
    status: status,
    assetPath: _postAssetForUser(user),
    title: 'Why locals are noticing $businessName this week',
    subtitle:
        'Highlight your standout offer, share a clear next step, and turn nearby searches into direct leads.',
    meta:
        '#$businessTag #GoogleBusinessProfile #LocalSEO #VisibloAI #SmartPosting',
    createdAt: DateTime.now(),
    scheduledFor: status == GbpPostStatus.scheduled
        ? DateTime.now().add(const Duration(days: 2))
        : null,
  );
}

Color _badgeForeground(GbpPostStatus status) {
  switch (status) {
    case GbpPostStatus.live:
      return AppColors.white;
    case GbpPostStatus.draft:
    case GbpPostStatus.failed:
      return const Color(0xFF7C63F1);
    case GbpPostStatus.scheduled:
      return _DashboardPalette.warning;
  }
}

Color _badgeBackground(GbpPostStatus status) {
  switch (status) {
    case GbpPostStatus.live:
      return const Color(0xFF52C271);
    case GbpPostStatus.draft:
    case GbpPostStatus.failed:
      return const Color(0xFFF3EEFF);
    case GbpPostStatus.scheduled:
      return _DashboardPalette.warningSoft;
  }
}

List<GbpPost> _buildPosts(TestAccount user) {
  return [
    GbpPost(
      id: 'post-live-1',
      status: GbpPostStatus.live,
      assetPath: 'assets/images/office.png',
      title:
          'Looking for a ready office space in Goregaon East for your growing team?',
      subtitle:
          'Discover premium office space in Lotus Corporate Park with flexible floor plans.',
      meta:
          '#LotusCorporatePark #OfficeSpaceGoregaon #OfficeForRentMumbai #GoregaonOffice #CommercialOfficeMumbai',
      createdAt: DateTime(2026, 10, 31),
    ),
    GbpPost(
      id: 'post-draft-1',
      status: GbpPostStatus.draft,
      assetPath: _postAssetForUser(user),
      title: 'Fresh local content idea for ${_businessName(user)}',
      subtitle:
          'Draft a polished local update, add your offer, and publish when ready.',
      meta: '#DraftPost #LocalSEO #VisibloAI #ContentPlanning #SmartPosting',
      createdAt: DateTime(2026, 10, 30),
    ),
  ];
}

class _MetricData {
  const _MetricData({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.cardBackground,
    required this.borderColor,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color cardBackground;
  final Color borderColor;
}

enum _PostFilter { all, drafts, scheduled, live }

abstract final class _DashboardPalette {
  static const canvas = AppColors.white;
  static const generatorBorder = Color(0xFFD6EDF7);
  static const cardBorder = Color(0xFFE4EBF5);
  static const unselectedPillBorder = Color(0xFFCFCFD7);
  static const liveGreen = Color(0xFF22AF69);
  static const liveSoft = Color(0xFFE8F9EF);
  static const warning = Color(0xFFF3A53B);
  static const warningSoft = Color(0xFFFEF7E9);
  static const danger = Color(0xFFFF4954);
  static const dangerSoft = Color(0xFFFFF0F1);
}

class _ExpandableText extends StatefulWidget {
  final String text;

  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.text.trim();
    if (text.isEmpty) return const SizedBox.shrink();

    // Split by double newline or single newline to find paragraphs
    final parts = text.split(RegExp(r'\n\s*\n|\n'));
    String firstPara = parts.first;

    // If there are no newlines but the text is very long, truncate it
    bool hasMore = text.length > firstPara.length;
    if (!hasMore && text.length > 150) {
      firstPara = '${text.substring(0, 150)}...';
      hasMore = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _expanded ? text : firstPara,
          style: TextStyle(
            fontSize: 13.5, // Increased from 12
            height: 1.5,
            color: AppColors.text.withValues(alpha: 0.75),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (hasMore) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'See less' : 'See more',
              style: const TextStyle(
                fontSize: 13.5, // Increased from 12
                fontWeight: FontWeight.w700,
                color: AppColors.brandBlue,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final page = index + 1;
        final isSelected = page == currentPage;
        return GestureDetector(
          onTap: () => onPageChanged(page),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 36, // Increased from 28
            height: 36, // Increased from 28
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.brandBlue : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? AppColors.brandBlue
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              '$page',
              style: TextStyle(
                fontSize: 15, // Increased from 13
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.text,
              ),
            ),
          ),
        );
      }),
    );
  }
}
