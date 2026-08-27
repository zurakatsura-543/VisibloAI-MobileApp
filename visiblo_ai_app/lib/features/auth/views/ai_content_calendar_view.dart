import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/widgets/app_logo.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/ai_manager_action.dart';
import '../models/gbp_post.dart';
import '../services/auth_api_service.dart';

typedef _PostPreviewAction = Future<GbpPost?> Function(GbpPost post);
typedef _PostRefreshAction = Future<GbpPost?> Function(String postId);
typedef _PlatformChipTap =
    void Function(GbpPost post, _PlatformChipData chip);

class _PlatformChipData {
  const _PlatformChipData({
    required this.id,
    required this.platform,
    required this.status,
    this.title,
    this.caption,
    this.mediaUrls = const <String>[],
    this.scheduledAt,
    this.socialPostId,
  });

  final String id;
  final String platform;
  final String status;
  final String? title;
  final String? caption;
  final List<String> mediaUrls;
  final DateTime? scheduledAt;
  final String? socialPostId;

  _PlatformChipData copyWith({
    String? title,
    String? caption,
    List<String>? mediaUrls,
    DateTime? scheduledAt,
  }) {
    return _PlatformChipData(
      id: id,
      platform: platform,
      status: status,
      title: title ?? this.title,
      caption: caption ?? this.caption,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      socialPostId: socialPostId,
    );
  }
}

class AiContentCalendarView extends StatefulWidget {
  const AiContentCalendarView({super.key});

  @override
  State<AiContentCalendarView> createState() => _AiContentCalendarViewState();
}

class _AiContentCalendarViewState extends State<AiContentCalendarView>
    with WidgetsBindingObserver {
  late final AuthApiService _api = Get.find<AuthApiService>();
  late final OnboardingController _controller =
      Get.find<OnboardingController>();
  final ImagePicker _imagePicker = ImagePicker();

  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<GbpPost> _posts = const <GbpPost>[];
  Map<String, List<_PlatformChipData>> _platformChipsByPostId =
      const <String, List<_PlatformChipData>>{};
  Map<String, dynamic>? _automationSettings;
  bool _isLoading = false;
  bool _isBuildingPlan = false;
  bool _isSavingAutomation = false;
  bool _refreshCalendarOnResume = false;
  bool _triedSocialDraftBackfill = false;
  String? _busyPostId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPosts());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_refreshCalendarOnResume) {
      return;
    }
    _refreshCalendarOnResume = false;
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final businessId =
        _controller.currentUser.value?.backendBusinessId.trim() ?? '';
    if (businessId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final locationId = _resolveWorkspaceLocationId();
      final rangeStart = DateTime(_visibleMonth.year, _visibleMonth.month);
      final rangeEnd = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
      final results = await Future.wait<dynamic>([
        _api.fetchAiPostsList(businessId),
        _api
            .fetchAiMasterContentCalendar(
              businessId: businessId,
              from: rangeStart,
              to: rangeEnd,
            )
            .catchError((_) => <String, dynamic>{}),
        _api.fetchGbpAutomationSettings(
          businessId: businessId,
          locationId: locationId.isEmpty ? null : locationId,
        ).catchError((_) => <String, dynamic>{}),
      ]);
      final posts = (results[0] as List<GbpPost>);
      posts.sort((a, b) => _postDate(a).compareTo(_postDate(b)));
      final platformChips = Map<String, List<_PlatformChipData>>.from(
        _readMasterCalendarPlatformChips(
          Map<String, dynamic>.from(results[1] as Map),
        ),
      );
      if (!_triedSocialDraftBackfill &&
          posts.isNotEmpty &&
          !_hasSocialPlatformChips(platformChips)) {
        _triedSocialDraftBackfill = true;
        await _api
            .ensureAiCalendarSocialDrafts(
              businessId: businessId,
              from: rangeStart,
              to: rangeEnd,
            )
            .catchError((_) => <String, dynamic>{});
        final refreshedCalendar = await _api
            .fetchAiMasterContentCalendar(
              businessId: businessId,
              from: rangeStart,
              to: rangeEnd,
            )
            .catchError((_) => <String, dynamic>{});
        platformChips
          ..clear()
          ..addAll(
            _readMasterCalendarPlatformChips(
              Map<String, dynamic>.from(refreshedCalendar as Map),
            ),
          );
      }
      if (mounted) {
        setState(() {
          _posts = posts;
          _platformChipsByPostId = platformChips;
          _automationSettings = Map<String, dynamic>.from(
            results[2] as Map,
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _changeVisibleMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
    });
    _loadPosts();
  }

  Future<void> _openSocialAccountsAndRefresh() async {
    _refreshCalendarOnResume = true;
    await Get.toNamed(AppRoutes.socialAccounts);
    _refreshCalendarOnResume = false;
    if (mounted) {
      await _loadPosts();
    }
  }

  void _openPlatformDraftPreview(GbpPost post, _PlatformChipData chip) {
    if (chip.platform.toUpperCase() == 'GOOGLE_BUSINESS') {
      _openPostPreview(post);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SocialPlatformDraftSheet(
        post: post,
        chip: chip,
        onConnect: _openSocialAccountsAndRefresh,
        onSave: (updated) async {
          final businessId =
              _controller.currentUser.value?.backendBusinessId.trim() ?? '';
          if (businessId.isEmpty || updated.id.isEmpty) return;
          await _api.updateAiPlatformPostDraft(
            platformPostId: updated.id,
            businessId: businessId,
            title: updated.title,
            caption: updated.caption,
            mediaUrls: updated.mediaUrls,
            scheduledAt: updated.scheduledAt,
          );
          await _loadPosts();
        },
      ),
    );
  }

  Future<void> _buildThirtyDayPlan() async {
    final businessId =
        _controller.currentUser.value?.backendBusinessId.trim() ?? '';
    if (businessId.isEmpty) return;

    setState(() => _isBuildingPlan = true);
    try {
      final createdActions = await _api.generateAiManagerActionsNow(
        businessId: businessId,
      );
      final allActions = [
        ...createdActions,
        ...await _api.listAiManagerActions(businessId: businessId),
      ];
      final calendarAction = _findRunnableCalendarAction(allActions);
      if (calendarAction == null) {
        Get.snackbar(
          'AI calendar',
          'No calendar action is available right now. Refresh the dashboard and try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final approvedAction = calendarAction.canApprove
          ? await _api.approveAiManagerAction(
              actionId: calendarAction.id,
              businessId: businessId,
            )
          : calendarAction;

      if (!approvedAction.canRun) {
        Get.snackbar(
          'AI calendar',
          'This calendar action is not ready to build yet.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final completed = await _api.runAiManagerAction(
        actionId: approvedAction.id,
        businessId: businessId,
      );
      await _loadPosts();
      Get.snackbar(
        'Calendar ready',
        completed.result['message']?.toString() ??
            'VisibloAI created your 30-day Google Business Profile drafts.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'AI calendar',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isBuildingPlan = false);
      }
    }
  }

  Future<void> _openPostPreview(GbpPost post) async {
    await Get.to<void>(
      () => _CalendarPostPreviewSheet(
        post: post,
        platformChips: _platformChipsByPostId[post.id] ??
            const <_PlatformChipData>[],
        onEdit: _editCalendarPost,
        onRegenerateText: _regeneratePostText,
        onGenerateImage: _generatePostImage,
        onUploadImage: _uploadPostImage,
        onApproveSchedule: _approvePostSchedule,
        onPauseAutoPost: _pauseAutoPost,
        onPostNow: _postNow,
        onRefreshPost: _refreshPostStatus,
        isBusy: _busyPostId == post.id,
      ),
    );
    await _loadPosts();
  }

  Future<GbpPost?> _editCalendarPost(GbpPost post) async {
    final titleController = TextEditingController(text: post.title);
    final contentController = TextEditingController(text: post.subtitle);
    final saved = await Get.dialog<bool>(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit post draft',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111B3D),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                maxLines: 2,
                style: const TextStyle(fontSize: 14, height: 1.25),
                decoration: const InputDecoration(
                  labelText: 'Headline',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                minLines: 5,
                maxLines: 8,
                style: const TextStyle(fontSize: 14, height: 1.3),
                decoration: const InputDecoration(
                  labelText: 'Post text',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Get.back(result: true),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (saved != true) return null;
    return _runPostTask(
      post.id,
      successTitle: 'Draft updated',
      successMessage: 'Your Google Business Profile draft was saved.',
      task: () async {
        final updated = await _api.updateAiPost(
          post.id,
          title: titleController.text.trim(),
          content: contentController.text.trim(),
        );
        return GbpPost.fromAiApiMap(updated);
      },
    );
  }

  Future<GbpPost?> _regeneratePostText(GbpPost post) async {
    if (_busyPostId != null) return null;
    setState(() => _busyPostId = post.id);
    try {
      final updated = await _api.regenerateAiPostText(post.id);
      await _loadPosts();
      Get.snackbar(
        'Fresh copy ready',
        'VisibloAI regenerated the post text.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return updated;
    } catch (error) {
      final message = error.toString();
      if (!message.contains('Cannot POST') ||
          !message.contains('regenerate-text')) {
        Get.snackbar(
          'Post draft',
          message.replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }

      try {
        final updated = await _fallbackRegeneratePostText(post);
        await _loadPosts();
        Get.snackbar(
          'Fresh copy ready',
          'VisibloAI regenerated the post text.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return updated;
      } catch (fallbackError) {
        Get.snackbar(
          'Post draft',
          fallbackError.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }
    } finally {
      if (mounted) {
        setState(() => _busyPostId = null);
      }
    }
  }

  Future<GbpPost?> _generatePostImage(GbpPost post) async {
    if (_busyPostId != null) return null;
    setState(() => _busyPostId = post.id);
    try {
      final updated = await _api.regenerateAiPostImage(post.id);
      await _loadPosts();
      final hasImage = updated.assetPath.trim().isNotEmpty;
      final imageChanged = updated.assetPath.trim() != post.assetPath.trim();
      if (updated.status == GbpPostStatus.failed || !hasImage) {
        Get.snackbar(
          'Image not generated',
          updated.errorMessage ??
              'VisibloAI could not generate a new creative. The previous image was kept.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return updated;
      }
      Get.snackbar(
        imageChanged ? 'Image ready' : 'Image checked',
        imageChanged
            ? 'VisibloAI generated a new creative for this post.'
            : 'No new image was returned yet. Please try again in a moment.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return updated;
    } catch (error) {
      Get.snackbar(
        'Image not generated',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      if (mounted) {
        setState(() => _busyPostId = null);
      }
    }
  }

  Future<GbpPost?> _uploadPostImage(GbpPost post) async {
    if (_busyPostId != null) return null;
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (picked == null) return null;

    return _runPostTask(
      post.id,
      successTitle: 'Image uploaded',
      successMessage: 'Your image is now attached to this Google post draft.',
      task: () async {
        final updated = await _api.uploadAiPostImage(
          postId: post.id,
          imagePath: picked.path,
        );
        return GbpPost.fromAiApiMap(updated);
      },
    );
  }

  Future<GbpPost> _fallbackRegeneratePostText(GbpPost post) async {
    final businessId =
        _controller.currentUser.value?.backendBusinessId.trim() ?? '';
    final locationId = _resolveLocationId(post);
    final generated = await _api.generateAiPost(
      topic: post.title,
      tone: 'Professional',
      language: 'English',
      skipImage: true,
      businessId: businessId.isEmpty ? null : businessId,
      locationId: locationId.isEmpty ? null : locationId,
      type: post.meta.isEmpty ? 'post' : post.meta.toLowerCase(),
      clientRequestId:
          'calendar-text-fallback:${post.id}:${DateTime.now().microsecondsSinceEpoch}',
    );

    final generatedPostId = generated['id']?.toString() ?? '';
    final updated = await _api.updateAiPost(
      post.id,
      title: generated['title']?.toString() ?? post.title,
      content: generated['content']?.toString() ?? post.subtitle,
    );
    if (generatedPostId.isNotEmpty && generatedPostId != post.id) {
      await _api.deleteAiPost(generatedPostId).catchError((_) {});
    }
    return GbpPost.fromAiApiMap(updated);
  }

  Future<GbpPost?> _approvePostSchedule(GbpPost post) async {
    final businessId =
        _controller.currentUser.value?.backendBusinessId.trim() ?? '';
    final locationId = _resolveLocationId(post);
    final scheduledAt = post.scheduledFor;

    if (businessId.isEmpty || locationId.isEmpty || scheduledAt == null) {
      Get.snackbar(
        'Schedule post',
        'Business, Google location, or schedule time is missing for this draft.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }

    return _runPostTask(
      post.id,
      successTitle: 'Post approved',
      successMessage:
          'This draft is now scheduled for Google Business Profile.',
      task: () async {
        await _api.scheduleAiPost(
          post.id,
          scheduledAt.toUtc().toIso8601String(),
          businessId,
          locationId,
        );
        return post.copyWith(
          status: GbpPostStatus.scheduled,
          publishStatus: 'SCHEDULED',
        );
      },
    );
  }

  Future<GbpPost?> _pauseAutoPost(GbpPost post) {
    return _runPostTask(
      post.id,
      successTitle: 'Auto post paused',
      successMessage:
          'This draft will not auto publish until you schedule it again.',
      task: () async {
        final updated = await _api.updateAiPost(
          post.id,
          publishStatus: 'DRAFT',
        );
        return GbpPost.fromAiApiMap(updated);
      },
    );
  }

  Future<GbpPost?> _postNow(GbpPost post) async {
    final businessId =
        _controller.currentUser.value?.backendBusinessId.trim() ?? '';
    final locationId = _resolveLocationId(post);
    if (businessId.isEmpty || locationId.isEmpty) {
      Get.snackbar(
        'Post now',
        'Business or Google location is missing for this draft.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }

    return _runPostTask(
      post.id,
      successTitle: 'Post published',
      successMessage: 'This post was published to Google Business Profile.',
      task: () => _api.publishAiPost(
        post.id,
        businessId: businessId,
        locationId: locationId,
      ),
    );
  }

  Future<GbpPost?> _refreshPostStatus(String postId) async {
    final updated = await _api.fetchAiPostById(postId);
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index >= 0 && mounted) {
      final nextPosts = List<GbpPost>.from(_posts);
      nextPosts[index] = updated;
      setState(() => _posts = nextPosts);
    }
    return updated;
  }

  Future<GbpPost?> _runPostTask(
    String postId, {
    required String successTitle,
    required String successMessage,
    required Future<GbpPost?> Function() task,
  }) async {
    if (_busyPostId != null) return null;
    setState(() => _busyPostId = postId);
    try {
      final updated = await task();
      await _loadPosts();
      Get.snackbar(
        successTitle,
        successMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
      return updated;
    } catch (error) {
      Get.snackbar(
        'Post draft',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      if (mounted) {
        setState(() => _busyPostId = null);
      }
    }
  }

  String _resolveLocationId(GbpPost post) {
    final fromPost = post.locationId?.trim() ?? '';
    if (fromPost.isNotEmpty) return fromPost;
    return _resolveWorkspaceLocationId();
  }

  String _resolveWorkspaceLocationId() {
    final businesses =
        _controller.currentUser.value?.backendAvailableBusinesses ??
        const <Map<String, dynamic>>[];
    if (businesses.isEmpty) return '';
    final first = businesses.first;
    return (first['gmbLocationId'] ??
            first['locationId'] ??
            first['backendLocationId'] ??
            '')
        .toString()
        .trim();
  }

  Future<void> _updateAutomationSettings({
    bool? autoPostActive,
    String? approvalMode,
    String? postingFrequency,
  }) async {
    final businessId =
        _controller.currentUser.value?.backendBusinessId.trim() ?? '';
    if (businessId.isEmpty || _isSavingAutomation) return;

    setState(() => _isSavingAutomation = true);
    try {
      final settings = await _api.updateGbpAutomationSettings(
        businessId: businessId,
        locationId: _resolveWorkspaceLocationId(),
        autoPostActive: autoPostActive,
        approvalMode: approvalMode,
        postingFrequency: postingFrequency,
      );
      if (mounted) {
        setState(() => _automationSettings = settings);
      }
      Get.snackbar(
        'Auto Post settings',
        'VisibloAI updated how Google posts will be handled.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Auto Post settings',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingAutomation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plannedPosts = _posts
        .where((post) => post.scheduledFor != null)
        .toList(growable: false);
    final monthPosts = plannedPosts
        .where((post) => _isSameMonth(_postDate(post), _visibleMonth))
        .toList();
    final upcomingPosts = monthPosts
        .where((post) => !_postDate(post).isBefore(_startOfDay(DateTime.now())))
        .toList();
    final socialConnectCounts = _socialConnectRequiredCounts(
      _platformChipsByPostId,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPosts,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              _Header(onBack: Get.back, onRefresh: _loadPosts),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  '30-Day AI Content Schedule',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111B3D),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'AI-planned posts for Google Business Profile.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF66728A),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 18),
              const _PlatformNotice(),
              const SizedBox(height: 12),
              _AutomationSettingsCard(
                settings: _automationSettings,
                isSaving: _isSavingAutomation,
                onToggleActive: (value) => _updateAutomationSettings(
                  autoPostActive: value,
                ),
                onApprovalModeChanged: (value) => _updateAutomationSettings(
                  approvalMode: value,
                ),
                onFrequencyChanged: (value) => _updateAutomationSettings(
                  postingFrequency: value,
                ),
              ),
              const SizedBox(height: 12),
              _MonthSwitcher(
                visibleMonth: _visibleMonth,
                onPrevious: () => _changeVisibleMonth(-1),
                onNext: () => _changeVisibleMonth(1),
              ),
              const SizedBox(height: 12),
              _StatusStrip(
                posts: monthPosts,
                settings: _automationSettings,
              ),
              const SizedBox(height: 12),
              _CalendarGrid(
                visibleMonth: _visibleMonth,
                posts: monthPosts,
                platformChipsByPostId: _platformChipsByPostId,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 10),
              const _CalendarLegend(),
              const SizedBox(height: 18),
              if (socialConnectCounts.isNotEmpty) ...[
                _SocialConnectRequiredCard(
                  counts: socialConnectCounts,
                  onTap: _openSocialAccountsAndRefresh,
                ),
                const SizedBox(height: 18),
              ],
              _UpcomingPosts(
                posts: upcomingPosts,
                platformChipsByPostId: _platformChipsByPostId,
                monthPostCount: monthPosts.length,
                onOpenPosts: () => Get.toNamed(AppRoutes.gbpPosts),
                onBuildPlan: _buildThirtyDayPlan,
                onPostTap: _openPostPreview,
                onPlatformTap: _openPlatformDraftPreview,
                isBuildingPlan: _isBuildingPlan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onRefresh});

  final VoidCallback onBack;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const Spacer(),
        const AppLogo(iconSize: 54),
        const Spacer(),
        _IconButton(icon: Icons.refresh_rounded, onTap: () => onRefresh()),
      ],
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.visibleMonth,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime visibleMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          _IconButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),
          Expanded(
            child: Text(
              '${_monthName(visibleMonth.month)} ${visibleMonth.year}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111B3D),
              ),
            ),
          ),
          _IconButton(icon: Icons.chevron_right_rounded, onTap: onNext),
        ],
      ),
    );
  }
}

class _PlatformNotice extends StatelessWidget {
  const _PlatformNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Color(0xFF1267F1),
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Publishing destination',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111B3D),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'One AI calendar will manage Google Business Profile first, then Facebook and Instagram from the same plan.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF66728A),
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

class _AutomationSettingsCard extends StatelessWidget {
  const _AutomationSettingsCard({
    required this.settings,
    required this.isSaving,
    required this.onToggleActive,
    required this.onApprovalModeChanged,
    required this.onFrequencyChanged,
  });

  final Map<String, dynamic>? settings;
  final bool isSaving;
  final ValueChanged<bool> onToggleActive;
  final ValueChanged<String> onApprovalModeChanged;
  final ValueChanged<String> onFrequencyChanged;

  @override
  Widget build(BuildContext context) {
    final autoPostActive = settings?['autoPostActive'] != false;
    final consentAccepted = settings?['consentAccepted'] == true;
    final approvalMode = (settings?['approvalMode'] ?? 'APPROVE_CALENDAR')
        .toString()
        .toUpperCase();
    final frequency = (settings?['postingFrequency'] ?? 'GROWTH')
        .toString()
        .toUpperCase();
    final explanation = _automationModeExplanation(
      approvalMode: approvalMode,
      autoPostActive: autoPostActive,
      consentAccepted: consentAccepted,
    );
    final frequencyLabel = _automationFrequencyExplanation(frequency);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: autoPostActive
                      ? const Color(0xFFE9FBF3)
                      : const Color(0xFFF1F3F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  autoPostActive
                      ? Icons.smart_toy_rounded
                      : Icons.pause_circle_outline_rounded,
                  color: autoPostActive
                      ? const Color(0xFF17A964)
                      : const Color(0xFF66728A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Google Auto Post',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111B3D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      autoPostActive
                          ? 'VisibloAI can publish approved scheduled posts.'
                          : 'Publishing is paused until you turn it back on.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF66728A),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSaving)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              else
                Switch.adaptive(
                  value: autoPostActive,
                  activeThumbColor: const Color(0xFF17A964),
                  onChanged: onToggleActive,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F9FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDCE8FF)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF1267F1),
                  size: 17,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$explanation $frequencyLabel',
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF33415C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!consentAccepted) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD9A6)),
              ),
              child: const Text(
                'Consent will be saved when you update these settings.',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9A5B00),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Approval mode',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111B3D),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AutomationChoiceChip(
                label: 'Review all',
                value: 'REVIEW_ALL',
                selectedValue: approvalMode,
                onSelected: onApprovalModeChanged,
              ),
              _AutomationChoiceChip(
                label: 'Approve calendar',
                value: 'APPROVE_CALENDAR',
                selectedValue: approvalMode,
                onSelected: onApprovalModeChanged,
              ),
              _AutomationChoiceChip(
                label: 'Full auto',
                value: 'FULL_AUTO',
                selectedValue: approvalMode,
                onSelected: onApprovalModeChanged,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Posting frequency',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111B3D),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AutomationChoiceChip(
                label: '3/wk',
                value: 'CONSERVATIVE',
                selectedValue: frequency,
                onSelected: onFrequencyChanged,
              ),
              _AutomationChoiceChip(
                label: '5/wk',
                value: 'GROWTH',
                selectedValue: frequency,
                onSelected: onFrequencyChanged,
              ),
              _AutomationChoiceChip(
                label: 'Daily',
                value: 'DAILY',
                selectedValue: frequency,
                onSelected: onFrequencyChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _automationModeExplanation({
  required String approvalMode,
  required bool autoPostActive,
  required bool consentAccepted,
}) {
  if (!consentAccepted) {
    return 'Auto publishing is locked until Google Auto Post consent is saved.';
  }
  if (!autoPostActive) {
    return 'Auto Post is paused. New calendar posts will stay as drafts until you schedule them.';
  }
  if (approvalMode == 'REVIEW_ALL') {
    return 'Review All mode: every post stays as a draft until you approve it.';
  }
  if (approvalMode == 'FULL_AUTO') {
    return 'Full Auto mode: VisibloAI can schedule validated posts automatically.';
  }
  return 'Approve Calendar mode: once the calendar is approved, posts are scheduled automatically.';
}

String _automationFrequencyExplanation(String frequency) {
  if (frequency == 'DAILY') return 'Daily creates about 30 posts for 30 days.';
  if (frequency == 'CONSERVATIVE') {
    return 'Conservative creates about 12 posts for 30 days.';
  }
  return 'Growth creates about 20 posts for 30 days.';
}

class _AutomationChoiceChip extends StatelessWidget {
  const _AutomationChoiceChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;
    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF3FF) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF1267F1) : const Color(0xFFE2E8F5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            color: selected
                ? const Color(0xFF1267F1)
                : const Color(0xFF66728A),
          ),
        ),
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.posts, required this.settings});

  final List<GbpPost> posts;
  final Map<String, dynamic>? settings;

  @override
  Widget build(BuildContext context) {
    final scheduled = posts
        .where((post) => post.status == GbpPostStatus.scheduled)
        .length;
    final draft = posts
        .where((post) => post.status == GbpPostStatus.draft)
        .length;
    final live = posts
        .where((post) => post.status == GbpPostStatus.live)
        .length;
    final publishing = posts
        .where((post) => post.publishStatus.toUpperCase() == 'PUBLISHING')
        .length;
    final failed = posts
        .where((post) => post.status == GbpPostStatus.failed)
        .length;
    final approvalMode = (settings?['approvalMode'] ?? 'APPROVE_CALENDAR')
        .toString()
        .toUpperCase();
    final autoPostActive = settings?['autoPostActive'] != false;
    final draftLabel = approvalMode == 'REVIEW_ALL' || !autoPostActive
        ? '$draft need review'
        : '$draft draft';

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatusChip(
          label: '$scheduled scheduled',
          color: const Color(0xFF22B66E),
        ),
        _StatusChip(label: draftLabel, color: const Color(0xFFFF8A1F)),
        if (publishing > 0)
          _StatusChip(
            label: '$publishing publishing',
            color: const Color(0xFF1267F1),
          ),
        _StatusChip(label: '$live live', color: const Color(0xFF1267F1)),
        if (failed > 0)
          _StatusChip(label: '$failed failed', color: const Color(0xFFE94363)),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.visibleMonth,
    required this.posts,
    required this.platformChipsByPostId,
    required this.isLoading,
  });

  final DateTime visibleMonth;
  final List<GbpPost> posts;
  final Map<String, List<_PlatformChipData>> platformChipsByPostId;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final days = _calendarDays(visibleMonth);

    return Container(
      decoration: _panelDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF1F5FF),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: const Row(
              children: [
                _WeekdayLabel('Sun'),
                _WeekdayLabel('Mon'),
                _WeekdayLabel('Tue'),
                _WeekdayLabel('Wed'),
                _WeekdayLabel('Thu'),
                _WeekdayLabel('Fri'),
                _WeekdayLabel('Sat'),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              final dayPosts = posts
                  .where((post) => _isSameDay(_postDate(post), day))
                  .toList();
              return _CalendarDayCell(
                day: day,
                visibleMonth: visibleMonth,
                posts: dayPosts,
                platformChipsByPostId: platformChipsByPostId,
              );
            },
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 14),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.visibleMonth,
    required this.posts,
    required this.platformChipsByPostId,
  });

  final DateTime day;
  final DateTime visibleMonth;
  final List<GbpPost> posts;
  final Map<String, List<_PlatformChipData>> platformChipsByPostId;

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth = _isSameMonth(day, visibleMonth);
    final isToday = _isSameDay(day, DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFF0E6BFF) : Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F5), width: 0.7),
      ),
      padding: const EdgeInsets.all(5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isToday
                  ? Colors.white
                  : isCurrentMonth
                  ? const Color(0xFF111B3D)
                  : const Color(0xFFB1BACB),
            ),
          ),
          if (posts.isNotEmpty) ...[
            const SizedBox(height: 5),
            Wrap(
              spacing: 3,
              runSpacing: 3,
              alignment: WrapAlignment.center,
              children: posts
                  .take(3)
                  .map(
                    (post) => Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _calendarStatusColor(post),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 2,
              runSpacing: 2,
              alignment: WrapAlignment.center,
              children: _platformsForPosts(posts, platformChipsByPostId)
                  .take(3)
                  .map((chip) => _MiniPlatformChip(chip: chip))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: const [
        _LegendItem(label: 'Scheduled', color: Color(0xFF22B66E)),
        _LegendItem(label: 'Needs review', color: Color(0xFFFF8A1F)),
        _LegendItem(label: 'Live', color: Color(0xFF1267F1)),
        _LegendItem(label: 'Failed', color: Color(0xFFE94363)),
      ],
    );
  }
}

class _PlatformChipRow extends StatelessWidget {
  const _PlatformChipRow({required this.chips, this.onTap});

  final List<_PlatformChipData> chips;
  final ValueChanged<_PlatformChipData>? onTap;

  @override
  Widget build(BuildContext context) {
    final visibleChips = chips.isEmpty
        ? const <_PlatformChipData>[
            _PlatformChipData(
              id: '',
              platform: 'GOOGLE_BUSINESS',
              status: 'PLANNED',
            ),
          ]
        : chips;
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: visibleChips
          .take(3)
          .map((chip) => _PlatformPill(chip: chip, onTap: onTap))
          .toList(),
    );
  }
}

class _PlatformPill extends StatelessWidget {
  const _PlatformPill({required this.chip, this.onTap});

  final _PlatformChipData chip;
  final ValueChanged<_PlatformChipData>? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _platformChipColor(chip);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(chip),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_platformIcon(chip.platform), size: 11, color: color),
              const SizedBox(width: 4),
              Text(
                '${_platformLabel(chip.platform)} ${_platformStatusLabel(chip)}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPlatformChip extends StatelessWidget {
  const _MiniPlatformChip({required this.chip});

  final _PlatformChipData chip;

  @override
  Widget build(BuildContext context) {
    final color = _platformColor(chip.platform);
    return Container(
      width: 19,
      height: 13,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _platformLabel(chip.platform),
        style: const TextStyle(
          fontSize: 7,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF66728A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _UpcomingPosts extends StatelessWidget {
  const _UpcomingPosts({
    required this.posts,
    required this.platformChipsByPostId,
    required this.monthPostCount,
    required this.onOpenPosts,
    required this.onBuildPlan,
    required this.onPostTap,
    required this.onPlatformTap,
    required this.isBuildingPlan,
  });

  final List<GbpPost> posts;
  final Map<String, List<_PlatformChipData>> platformChipsByPostId;
  final int monthPostCount;
  final VoidCallback onOpenPosts;
  final VoidCallback onBuildPlan;
  final ValueChanged<GbpPost> onPostTap;
  final _PlatformChipTap onPlatformTap;
  final bool isBuildingPlan;

  @override
  Widget build(BuildContext context) {
    final visiblePosts = posts.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Upcoming Posts',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111B3D),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onOpenPosts,
              icon: const Icon(Icons.edit_calendar_outlined, size: 18),
              label: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (visiblePosts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: _panelDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No upcoming Google Business Profile drafts to show here.',
                  style: TextStyle(
                    color: Color(0xFF111B3D),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  monthPostCount > 0
                      ? 'This month has draft posts, but none are scheduled after today. Use Manage to review all drafts.'
                      : 'Go back to dashboard and approve the 30-day calendar action. VisibloAI will then create dated Google Business Profile post drafts.',
                  style: const TextStyle(
                    color: Color(0xFF66728A),
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isBuildingPlan ? null : onBuildPlan,
                    icon: isBuildingPlan
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded),
                    label: Text(
                      isBuildingPlan
                          ? 'Building plan...'
                          : 'Build 30-day Google plan',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF106CFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...visiblePosts.map(
            (post) => _UpcomingPostTile(
              post: post,
              platformChips: platformChipsByPostId[post.id] ??
                  const <_PlatformChipData>[],
              onPlatformTap: (chip) => onPlatformTap(post, chip),
              onTap: () => onPostTap(post),
            ),
          ),
      ],
    );
  }
}

class _SocialConnectRequiredCard extends StatelessWidget {
  const _SocialConnectRequiredCard({
    required this.counts,
    required this.onTap,
  });

  final Map<String, int> counts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labels = counts.entries
        .map((entry) => '${_platformLabel(entry.key)} ${entry.value}')
        .join(' • ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: Color(0xFF9A5B00),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connect social channels',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111B3D),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'VisibloAI prepared these social drafts. Connect accounts to schedule them.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF66728A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F5)),
            ),
            child: Text(
              labels,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF33415C),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.facebook_rounded, size: 18),
              label: const Text('Connect Facebook & Instagram'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF106CFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialPlatformDraftSheet extends StatefulWidget {
  const _SocialPlatformDraftSheet({
    required this.post,
    required this.chip,
    required this.onConnect,
    required this.onSave,
  });

  final GbpPost post;
  final _PlatformChipData chip;
  final VoidCallback onConnect;
  final Future<void> Function(_PlatformChipData updated) onSave;

  @override
  State<_SocialPlatformDraftSheet> createState() =>
      _SocialPlatformDraftSheetState();
}

class _SocialPlatformDraftSheetState extends State<_SocialPlatformDraftSheet> {
  late final TextEditingController _titleController = TextEditingController(
    text: (widget.chip.title?.trim().isNotEmpty ?? false)
        ? widget.chip.title!.trim()
        : widget.post.title,
  );
  late final TextEditingController _captionController = TextEditingController(
    text: (widget.chip.caption?.trim().isNotEmpty ?? false)
        ? widget.chip.caption!.trim()
        : widget.post.subtitle,
  );
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final caption = _captionController.text.trim();
    if (caption.length < 10) {
      Get.snackbar(
        'Social draft',
        'Caption is too short.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        widget.chip.copyWith(
          title: _titleController.text.trim(),
          caption: caption,
        ),
      );
      if (mounted) {
        setState(() => _isEditing = false);
      }
      Get.back<void>();
      Get.snackbar(
        'Social draft saved',
        '${_platformLabel(widget.chip.platform)} draft updated.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Social draft',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chip = widget.chip;
    final platform = _platformLabel(chip.platform);
    final statusLabel = _platformStatusLabel(chip);
    final color = _platformChipColor(chip);
    final imageUrl = chip.mediaUrls.isNotEmpty
        ? chip.mediaUrls.first
        : widget.post.assetPath;
    final scheduledAt = chip.scheduledAt ?? widget.post.scheduledFor;
    final needsConnect = statusLabel == 'connect required';

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9E0EE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_platformIcon(chip.platform), color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$platform draft preview',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111B3D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          needsConnect
                              ? 'Prepared by VisibloAI. Connect account to schedule.'
                              : 'Connected and ready in the social scheduler.',
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF66728A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back<void>(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl.isEmpty
                    ? Container(
                        height: 155,
                        color: const Color(0xFFF1F5FF),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: Color(0xFF66728A),
                            size: 34,
                          ),
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _StatusChip(label: '$platform $statusLabel', color: color),
                  const Spacer(),
                  if (scheduledAt != null)
                    Text(
                      '${_formatPostDate(scheduledAt)} • ${_formatPostTime(scheduledAt)}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF66728A),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (_isEditing) ...[
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _captionController,
                  decoration: const InputDecoration(labelText: 'Caption'),
                  minLines: 5,
                  maxLines: 9,
                ),
              ] else ...[
                Text(
                  _titleController.text,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111B3D),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _captionController.text,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF33415C),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              if (needsConnect)
                FilledButton.icon(
                  onPressed: () {
                    Get.back<void>();
                    widget.onConnect();
                  },
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('Connect Facebook & Instagram'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF106CFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else if (_isEditing)
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_isSaving ? 'Saving...' : 'Save draft'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF17A964),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: const Icon(Icons.edit_rounded, size: 17),
                        label: const Text('Edit draft'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Get.toNamed(AppRoutes.socialScheduler),
                        icon: const Icon(Icons.calendar_month_rounded, size: 17),
                        label: const Text('Scheduler'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _UpcomingPostTile extends StatelessWidget {
  const _UpcomingPostTile({
    required this.post,
    required this.platformChips,
    required this.onPlatformTap,
    required this.onTap,
  });

  final GbpPost post;
  final List<_PlatformChipData> platformChips;
  final ValueChanged<_PlatformChipData> onPlatformTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = _postDate(post);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: _panelDecoration(),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111B3D),
                      ),
                    ),
                    Text(
                      _shortMonth(date.month),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF66728A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _PostMediaThumb(post: post),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111B3D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.status == GbpPostStatus.failed
                          ? _failedPostSummary(post)
                          : post.meta.isEmpty
                          ? 'Google Business Profile'
                          : 'Google Business Profile • ${post.meta}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF66728A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _PlatformChipRow(
                      chips: platformChips,
                      onTap: onPlatformTap,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: _calendarBadgeLabel(post),
                color: _calendarStatusColor(post),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarPostPreviewSheet extends StatefulWidget {
  const _CalendarPostPreviewSheet({
    required this.post,
    required this.platformChips,
    required this.onEdit,
    required this.onRegenerateText,
    required this.onGenerateImage,
    required this.onUploadImage,
    required this.onApproveSchedule,
    required this.onPauseAutoPost,
    required this.onPostNow,
    required this.onRefreshPost,
    required this.isBusy,
  });

  final GbpPost post;
  final List<_PlatformChipData> platformChips;
  final _PostPreviewAction onEdit;
  final _PostPreviewAction onRegenerateText;
  final _PostPreviewAction onGenerateImage;
  final _PostPreviewAction onUploadImage;
  final _PostPreviewAction onApproveSchedule;
  final _PostPreviewAction onPauseAutoPost;
  final _PostPreviewAction onPostNow;
  final _PostRefreshAction onRefreshPost;
  final bool isBusy;

  @override
  State<_CalendarPostPreviewSheet> createState() =>
      _CalendarPostPreviewSheetState();
}

class _CalendarPostPreviewSheetState extends State<_CalendarPostPreviewSheet> {
  late GbpPost _post = widget.post;
  String? _busyLabel;
  Timer? _timer;
  DateTime _now = DateTime.now();
  bool _autoImageRequested = false;
  bool _isRefreshingStatus = false;
  DateTime? _lastStatusRefresh;

  bool get _isBusy => widget.isBusy || _busyLabel != null;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
        _maybeRefreshPublishingStatus();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoGenerateImageIfMissing();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _runSheetAction(
    String busyLabel,
    _PostPreviewAction action,
  ) async {
    if (_isBusy) return;
    setState(() => _busyLabel = busyLabel);
    try {
      final updated = await action(_post);
      if (updated != null && mounted) {
        setState(() => _post = updated);
      }
    } finally {
      if (mounted) {
        setState(() => _busyLabel = null);
      }
    }
  }

  Future<void> _autoGenerateImageIfMissing() async {
    if (_autoImageRequested || _post.assetPath.trim().isNotEmpty || _isBusy) {
      return;
    }
    _autoImageRequested = true;
    await _runSheetAction('Preparing image', widget.onGenerateImage);
  }

  Future<void> _maybeRefreshPublishingStatus() async {
    if (_isRefreshingStatus || _isBusy || _post.id.trim().isEmpty) return;

    final publishStatus = _post.publishStatus.toUpperCase();
    if (publishStatus == 'LIVE' ||
        publishStatus == 'PUBLISHED' ||
        publishStatus == 'FAILED' ||
        publishStatus == 'REJECTED') {
      return;
    }

    final date = _post.scheduledFor;
    final shouldRefresh =
        publishStatus == 'PUBLISHING' ||
        (date != null && !date.isAfter(_now));
    if (!shouldRefresh) return;

    final last = _lastStatusRefresh;
    if (last != null && _now.difference(last).inSeconds < 10) return;

    _lastStatusRefresh = _now;
    setState(() => _isRefreshingStatus = true);
    try {
      final updated = await widget.onRefreshPost(_post.id);
      if (updated != null && mounted) {
        setState(() => _post = updated);
      }
    } catch (_) {
      // Keep the preview open; the next poll or manual refresh can recover.
    } finally {
      if (mounted) {
        setState(() => _isRefreshingStatus = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    final date = post.scheduledFor;
    final publishStatus = post.publishStatus.toUpperCase();
    final isLive = publishStatus == 'LIVE' || publishStatus == 'PUBLISHED';
    final isPublishing = publishStatus == 'PUBLISHING';
    final isDueAndWaiting =
        !isLive &&
        !isPublishing &&
        date != null &&
        !date.isAfter(_now) &&
        publishStatus == 'SCHEDULED';
    final isFailed =
        publishStatus == 'FAILED' ||
        publishStatus == 'REJECTED' ||
        post.status == GbpPostStatus.failed;
    final isAutoPostActive = date != null && publishStatus == 'SCHEDULED';
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      bottomNavigationBar: const _PreviewBottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: _isBusy ? () {} : Get.back,
                    ),
                    const Spacer(),
                    const AppLogo(iconSize: 58),
                    const Spacer(),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _IconButton(
                          icon: Icons.notifications_none_rounded,
                          onTap: () {},
                        ),
                        Positioned(
                          right: -2,
                          top: -3,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF106CFF),
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'AI Post Preview',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF080D42),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    isLive
                        ? 'Great job! Your post was successfully published on Google Business Profile.'
                        : isPublishing || isDueAndWaiting
                        ? 'VisibloAI is checking Google Business Profile publishing status.'
                        : isFailed
                        ? 'Google could not publish this post. Review the reason and approve again.'
                        : isAutoPostActive
                        ? 'AI will publish this post automatically unless you edit or pause it.'
                        : 'Review this Google Business Profile draft before it goes live.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF66728A),
                      fontSize: 12.2,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 14),
                isLive
                    ? _LivePostSuccessPanel(post: post)
                    : isPublishing || isDueAndWaiting
                    ? _PublishingPostPanel(post: post)
                    : isFailed
                    ? _FailedPostRecoveryPanel(post: post)
                    : _CountdownPanel(
                        scheduledAt: date,
                        now: _now,
                        isAutoPostActive: isAutoPostActive,
                      ),
                if (_busyLabel != null || _isRefreshingStatus) ...[
                  const SizedBox(height: 12),
                  _SheetBusyNotice(
                    label: _busyLabel ?? 'Checking Google status',
                  ),
                ],
                const SizedBox(height: 16),
                _PostPreviewCard(
                  post: post,
                  platformChips: widget.platformChips,
                  isPreparingImage:
                      post.assetPath.trim().isEmpty &&
                      _busyLabel == 'Preparing image',
                ),
                const SizedBox(height: 14),
                isFailed
                    ? _RecoveryChecklistPanel(reason: post.errorMessage)
                    : isPublishing || isDueAndWaiting
                    ? const _PublishingChecklistPanel()
                    : const _AiChecksPanel(),
                if (!isLive && !isPublishing && !isDueAndWaiting) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SheetActionButton(
                        icon: Icons.refresh_rounded,
                        label: isFailed
                            ? 'Regenerate safer text'
                            : 'Regenerate text',
                        isLoading: _busyLabel == 'Regenerating text',
                        onPressed: _isBusy
                            ? null
                            : () => _runSheetAction(
                                'Regenerating text',
                                widget.onRegenerateText,
                              ),
                      ),
                      _SheetActionButton(
                        icon: Icons.image_outlined,
                        label: 'Regenerate image',
                        isLoading:
                            _busyLabel == 'Generating image' ||
                            _busyLabel == 'Preparing image',
                        onPressed: _isBusy
                            ? null
                            : () => _runSheetAction(
                                'Generating image',
                                widget.onGenerateImage,
                              ),
                      ),
                      _SheetActionButton(
                        icon: Icons.upload_file_rounded,
                        label: 'Upload image',
                        isLoading: _busyLabel == 'Uploading image',
                        onPressed: _isBusy
                            ? null
                            : () => _runSheetAction(
                                'Uploading image',
                                widget.onUploadImage,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _LargeActionButton(
                          icon: Icons.edit_rounded,
                          label: 'Edit Post',
                          onPressed: _isBusy
                              ? null
                              : () => _runSheetAction(
                                  'Saving edit',
                                  widget.onEdit,
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isFailed)
                        Expanded(
                          child: _LargeActionButton(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Approve Again',
                            onPressed: _isBusy
                                ? null
                                : () => _runSheetAction(
                                    'Scheduling again',
                                    widget.onApproveSchedule,
                                  ),
                          ),
                        )
                      else
                        Expanded(
                          child: _LargeActionButton(
                            icon: Icons.pause_circle_outline_rounded,
                            label: 'Pause Auto Post',
                            onPressed: _isBusy
                                ? null
                                : () => _runSheetAction(
                                    'Pausing auto post',
                                    widget.onPauseAutoPost,
                                  ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isBusy
                          ? null
                          : () => _runSheetAction(
                              'Posting now',
                              widget.onPostNow,
                            ),
                      icon: _busyLabel == 'Posting now'
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: const Text(
                        'Post Now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0057FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _InfoStrip(
                  text: isLive
                      ? 'Published successfully on Google Business Profile. VisibloAI will track this post and keep improving future content.'
                      : isFailed
                      ? 'This post needs review. Regenerate safer text, edit if needed, then approve again or post now.'
                      : isDueAndWaiting
                      ? 'The timer ended. VisibloAI is waiting for the backend publisher and checking Google status.'
                      : isAutoPostActive
                      ? 'You can edit or stop this post anytime before the timer ends.'
                      : 'This post is planned for Google Business Profile. Schedule it or post it now when ready.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FailedPostRecoveryPanel extends StatelessWidget {
  const _FailedPostRecoveryPanel({required this.post});

  final GbpPost post;

  @override
  Widget build(BuildContext context) {
    final reason = _cleanFailureReason(post.errorMessage);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFCFD9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10E94363),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFE94363),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.report_gmailerrorred_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review needed before reposting',
                  style: TextStyle(
                    color: Color(0xFF111B3D),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  reason,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8A1F36),
                    fontSize: 12,
                    height: 1.3,
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

class _LivePostSuccessPanel extends StatelessWidget {
  const _LivePostSuccessPanel({required this.post});

  final GbpPost post;

  @override
  Widget build(BuildContext context) {
    final viewUrl = _googlePostViewUrl(post);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE8F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x101B2B5A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF22B66E).withValues(alpha: 0.10),
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF22B66E).withValues(alpha: 0.16),
                ),
              ),
              Container(
                width: 45,
                height: 45,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF22B66E),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Your Post is Live!',
            style: TextStyle(
              color: Color(0xFF080D42),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Great job! Your post has been successfully published on Google Business Profile.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF66728A),
              fontSize: 11.8,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFE9FAEF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFCFEFDC)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.public_rounded,
                  size: 15,
                  color: Color(0xFF18A85E),
                ),
                const SizedBox(width: 6),
                Text(
                  'Published successfully',
                  style: const TextStyle(
                    color: Color(0xFF16864F),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (viewUrl != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openExternalUrl(viewUrl),
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: const Text('View on Google'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0057FF),
                  side: const BorderSide(color: Color(0xFFBFD4FF)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PublishingPostPanel extends StatelessWidget {
  const _PublishingPostPanel({required this.post});

  final GbpPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE8F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x101B2B5A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF3FF),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(13),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF1267F1),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Publishing to Google',
                  style: TextStyle(
                    color: Color(0xFF080D42),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  post.gmbPostId?.trim().isNotEmpty == true
                      ? 'Google has received the post. VisibloAI is checking when it becomes live.'
                      : 'VisibloAI is submitting this post and will update the status automatically.',
                  style: const TextStyle(
                    color: Color(0xFF66728A),
                    fontSize: 12,
                    height: 1.3,
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

class _CountdownPanel extends StatelessWidget {
  const _CountdownPanel({
    required this.scheduledAt,
    required this.now,
    required this.isAutoPostActive,
  });

  final DateTime? scheduledAt;
  final DateTime now;
  final bool isAutoPostActive;

  @override
  Widget build(BuildContext context) {
    final remaining = scheduledAt == null
        ? Duration.zero
        : scheduledAt!.difference(now);
    final safeRemaining = remaining.isNegative ? Duration.zero : remaining;
    final hours = safeRemaining.inHours.toString().padLeft(2, '0');
    final minutes = (safeRemaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (safeRemaining.inSeconds % 60).toString().padLeft(2, '0');
    final helperText = isAutoPostActive
        ? 'This post will be published automatically when the timer ends.'
        : 'Schedule this post to let VisibloAI publish it automatically.';
    final ringProgress =
        (safeRemaining.inSeconds / const Duration(hours: 24).inSeconds)
            .clamp(0.0, 1.0)
            .toDouble();

    Widget botIcon() {
      return SizedBox(
        width: 58,
        height: 58,
        child: CustomPaint(
          painter: _CountdownRingPainter(progress: ringProgress),
          child: Center(
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEAFBFF),
              ),
              padding: const EdgeInsets.all(2),
              child: Image.asset('assets/images/ai.png', fit: BoxFit.contain),
            ),
          ),
        ),
      );
    }

    Widget timerBlock() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Posting in',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF111B3D),
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$hours : $minutes : $seconds',
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFF080D42),
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const Text(
            'HOURS        MINUTES        SECONDS',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF66728A),
              fontSize: 8.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    Widget statusBlock({required bool compact}) {
      return SizedBox(
        width: compact ? double.infinity : 126,
        child: Column(
          crossAxisAlignment: compact
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            _AutoPostBadge(active: isAutoPostActive),
            const SizedBox(height: 7),
            Text(
              helperText,
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              textAlign: compact ? TextAlign.center : TextAlign.start,
              style: const TextStyle(
                color: Color(0xFF41506A),
                fontSize: 9.25,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 300;

        return Container(
          padding: EdgeInsets.fromLTRB(12, 14, 12, compact ? 14 : 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDDE8F6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x101B2B5A),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: compact
              ? Column(
                  children: [
                    Row(
                      children: [
                        botIcon(),
                        const SizedBox(width: 10),
                        Expanded(child: timerBlock()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    statusBlock(compact: true),
                  ],
                )
              : Row(
                  children: [
                    botIcon(),
                    const SizedBox(width: 10),
                    Expanded(child: timerBlock()),
                    const SizedBox(width: 6),
                    statusBlock(compact: false),
                  ],
                ),
        );
      },
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  const _CountdownRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 5) / 2;
    final basePaint = Paint()
      ..color = const Color(0xFFDDE8F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF21C6BD), Color(0xFF0E6BFF)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(center, radius, basePaint);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _AutoPostBadge extends StatelessWidget {
  const _AutoPostBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF22B66E) : const Color(0xFFFF8A1F);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              active ? 'Auto Post Active' : 'Planned',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9.8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostPreviewCard extends StatelessWidget {
  const _PostPreviewCard({
    required this.post,
    required this.platformChips,
    required this.isPreparingImage,
  });

  final GbpPost post;
  final List<_PlatformChipData> platformChips;
  final bool isPreparingImage;

  @override
  Widget build(BuildContext context) {
    final date = post.scheduledFor;
    return Container(
      decoration: _panelDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: _PlatformTab(
                  icon: Icons.storefront_rounded,
                  label: 'Google Business Profile',
                  active: true,
                ),
              ),
              Expanded(
                child: _SocialPlatformSummaryTab(chips: platformChips),
              ),
            ],
          ),
          Container(height: 1, color: const Color(0xFFE2E8F5)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PreviewMedia(post: post, isPreparingImage: isPreparingImage),
                const SizedBox(height: 14),
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111B3D),
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 9),
                _ExpandablePostText(text: post.subtitle),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Get.snackbar(
                    'Google CTA',
                    '${_ctaLabel(post.callToAction)} will be attached when this post is published.',
                    snackPosition: SnackPosition.BOTTOM,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0057FF),
                    side: const BorderSide(color: Color(0xFF0057FF)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: Text(
                    _ctaLabel(post.callToAction),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (platformChips.isNotEmpty) ...[
                  _PlatformChipRow(chips: platformChips),
                  const SizedBox(height: 14),
                ],
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _PreviewMetaBlock(
                        title: 'Platform',
                        lines: [
                          platformChips.isEmpty
                              ? 'GBP'
                              : platformChips
                                    .map((chip) => _platformLabel(chip.platform))
                                    .join(', '),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 10,
                      child: _PreviewMetaBlock(
                        title: 'Scheduled',
                        lines: [
                          date == null ? 'Not set' : _formatPostDate(date),
                          date == null ? '' : _formatPostTime(date),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF66728A),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
                          _StatusChip(
                            label: _calendarBadgeLabel(post),
                            color: _calendarStatusColor(post),
                          ),
                        ],
                      ),
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

class _ExpandablePostText extends StatefulWidget {
  const _ExpandablePostText({required this.text});

  final String text;

  @override
  State<_ExpandablePostText> createState() => _ExpandablePostTextState();
}

class _ExpandablePostTextState extends State<_ExpandablePostText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.text.trim().isEmpty
        ? 'No post text generated yet.'
        : widget.text.trim();
    final shouldClamp = text.length > 170 || text.split('\n').length > 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          maxLines: _expanded ? null : 5,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.38,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        if (shouldClamp) ...[
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _expanded ? 'Show less' : 'See more',
              style: const TextStyle(
                color: Color(0xFF0057FF),
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PlatformTab extends StatelessWidget {
  const _PlatformTab({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: active ? const Color(0xFF0057FF) : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: active ? const Color(0xFF0057FF) : const Color(0xFF8A94A8),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              active ? label : '$label Soon',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: active
                    ? const Color(0xFF0057FF)
                    : const Color(0xFF8A94A8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialPlatformSummaryTab extends StatelessWidget {
  const _SocialPlatformSummaryTab({required this.chips});

  final List<_PlatformChipData> chips;

  @override
  Widget build(BuildContext context) {
    final socialChips = chips
        .where((chip) {
          final platform = chip.platform.toUpperCase();
          return platform == 'FACEBOOK' || platform == 'INSTAGRAM';
        })
        .toList(growable: false);
    final hasConnected = socialChips.any((chip) => chip.socialPostId != null);
    final label = socialChips.isEmpty
        ? 'Social drafts'
        : hasConnected
        ? 'FB/IG ready'
        : 'Connect social';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasConnected ? Icons.public_rounded : Icons.link_off_rounded,
            size: 16,
            color: hasConnected
                ? const Color(0xFF17A964)
                : const Color(0xFF7A8499),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasConnected
                    ? const Color(0xFF17A964)
                    : const Color(0xFF7A8499),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewMetaBlock extends StatelessWidget {
  const _PreviewMetaBlock({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF66728A),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        ...lines
            .where((line) => line.isNotEmpty)
            .map(
              (line) => Text(
                line,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF111B3D),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
      ],
    );
  }
}

String _ctaLabel(String? value) {
  switch ((value ?? '').toUpperCase()) {
    case 'CALL':
      return 'Call now';
    case 'BOOK':
      return 'Book';
    case 'ORDER':
      return 'Order online';
    case 'SHOP':
    case 'BUY':
      return 'Buy';
    case 'SIGN_UP':
      return 'Sign up';
    case 'NONE':
      return 'No button';
    case 'LEARN_MORE':
    default:
      return 'Learn more';
  }
}

void _showAiChecksDetails() {
  Get.bottomSheet<void>(
    Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Center(child: SizedBox(width: 42, child: Divider(thickness: 4))),
            SizedBox(height: 12),
            Text(
              'AI checks completed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111B3D),
              ),
            ),
            SizedBox(height: 12),
            _AiCheckDetailLine(
              title: 'Policy checked',
              text:
                  'No unsafe promises, spam wording, or unsupported offer claims detected.',
            ),
            _AiCheckDetailLine(
              title: 'Brand tone matched',
              text:
                  'Copy is kept professional, local, and suitable for Google Business Profile.',
            ),
            _AiCheckDetailLine(
              title: 'Best time selected',
              text:
                  'The post is placed in the planned calendar slot for better consistency.',
            ),
            _AiCheckDetailLine(
              title: 'Media ready',
              text:
                  'Image is prepared for preview and can be regenerated or replaced before posting.',
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _AiCheckDetailLine extends StatelessWidget {
  const _AiCheckDetailLine({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF22B66E),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111B3D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF66728A),
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

class _RecoveryChecklistPanel extends StatelessWidget {
  const _RecoveryChecklistPanel({required this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD7DE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1B2B5A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.auto_fix_high_rounded,
                color: Color(0xFFE94363),
                size: 18,
              ),
              SizedBox(width: 7),
              Text(
                'Recovery checks',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111B3D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RecoveryLine(
            title: 'Google response captured',
            text: _cleanFailureReason(reason),
            color: const Color(0xFFE94363),
          ),
          const _RecoveryLine(
            title: 'Safer copy available',
            text:
                'Regenerate text to remove risky wording, unsupported claims, or policy-sensitive phrases.',
            color: Color(0xFF0E6BFF),
          ),
          const _RecoveryLine(
            title: 'Ready to approve again',
            text:
                'After editing or regenerating, approve again to put this post back into the publishing queue.',
            color: Color(0xFF22B66E),
          ),
        ],
      ),
    );
  }
}

class _RecoveryLine extends StatelessWidget {
  const _RecoveryLine({
    required this.title,
    required this.text,
    required this.color,
  });

  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111B3D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF66728A),
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

class _AiChecksPanel extends StatelessWidget {
  const _AiChecksPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'AI Checks Completed',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111B3D),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF0057FF),
                size: 15,
              ),
              const Spacer(),
              TextButton(
                onPressed: _showAiChecksDetails,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF0057FF),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _AiCheckItem(title: 'Policy Checked', subtitle: 'Compliant'),
              _AiCheckItem(
                title: 'Brand Tone Matched',
                subtitle: 'Professional',
              ),
              _AiCheckItem(
                title: 'Best Time Selected',
                subtitle: 'High engagement',
              ),
              _AiCheckItem(title: 'Media Ready', subtitle: 'Optimized'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PublishingChecklistPanel extends StatelessWidget {
  const _PublishingChecklistPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Publishing Progress',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111B3D),
            ),
          ),
          SizedBox(height: 12),
          _RecoveryLine(
            title: 'Submitted to Google',
            text: 'VisibloAI has sent this post through the Google Business Profile publishing API.',
            color: Color(0xFF1267F1),
          ),
          _RecoveryLine(
            title: 'Waiting for final Google state',
            text: 'The scheduler will reconcile this post as Live or Failed automatically.',
            color: Color(0xFF22B66E),
          ),
        ],
      ),
    );
  }
}

class _AiCheckItem extends StatelessWidget {
  const _AiCheckItem({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 142,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF22B66E),
            size: 18,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF111B3D),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF66728A),
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

class _LargeActionButton extends StatelessWidget {
  const _LargeActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0057FF),
        side: const BorderSide(color: Color(0xFF0057FF)),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: Color(0xFF0057FF), size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF0E4AA8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewBottomNav extends StatelessWidget {
  const _PreviewBottomNav();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F5))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _PreviewNavItem(
              icon: Icons.grid_view_rounded,
              label: 'Dashboard',
              active: true,
            ),
            _PreviewNavItem(icon: Icons.article_outlined, label: 'Content'),
            _PreviewNavItem(icon: Icons.bar_chart_rounded, label: 'Analytics'),
            _PreviewNavItem(icon: Icons.settings_outlined, label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

class _PreviewNavItem extends StatelessWidget {
  const _PreviewNavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF0057FF) : const Color(0xFF66728A);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PreviewMedia extends StatelessWidget {
  const _PreviewMedia({required this.post, required this.isPreparingImage});

  final GbpPost post;
  final bool isPreparingImage;

  @override
  Widget build(BuildContext context) {
    final imageUrl = post.assetPath.trim();
    return AspectRatio(
      aspectRatio: 1.9,
      child: Container(
        decoration: BoxDecoration(
          color: _postTypeColor(post.meta).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageUrl.startsWith('http')
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _PreviewMediaFallback(
                  post: post,
                  isPreparingImage: isPreparingImage,
                ),
              )
            : _PreviewMediaFallback(
                post: post,
                isPreparingImage: isPreparingImage,
              ),
      ),
    );
  }
}

class _PreviewMediaFallback extends StatelessWidget {
  const _PreviewMediaFallback({
    required this.post,
    required this.isPreparingImage,
  });

  final GbpPost post;
  final bool isPreparingImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isPreparingImage)
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: _postTypeColor(post.meta),
            ),
          )
        else
          Icon(
            _postTypeIcon(post.meta),
            color: _postTypeColor(post.meta),
            size: 30,
          ),
        const SizedBox(height: 6),
        Text(
          isPreparingImage
              ? 'VisibloAI is creating the image'
              : 'Image will be prepared automatically',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF66728A),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SheetBusyNotice extends StatelessWidget {
  const _SheetBusyNotice({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCFE1FF)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label...',
              style: const TextStyle(
                color: Color(0xFF0E4AA8),
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 17),
      label: Text(
        isLoading ? 'Working' : label,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: Color(0xFFDCE5F4)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _PostMediaThumb extends StatelessWidget {
  const _PostMediaThumb({required this.post});

  final GbpPost post;

  @override
  Widget build(BuildContext context) {
    final imageUrl = post.assetPath.trim();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _postTypeColor(post.meta).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.startsWith('http')
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _PostTypeIcon(post: post),
            )
          : _PostTypeIcon(post: post),
    );
  }
}

class _PostTypeIcon extends StatelessWidget {
  const _PostTypeIcon({required this.post});

  final GbpPost post;

  @override
  Widget build(BuildContext context) {
    return Icon(
      _postTypeIcon(post.meta),
      color: _postTypeColor(post.meta),
      size: 21,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF66728A),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F5)),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF111B3D)),
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE2E8F5)),
    boxShadow: const [
      BoxShadow(color: Color(0x0F1B2B5A), blurRadius: 16, offset: Offset(0, 8)),
    ],
  );
}

Map<String, List<_PlatformChipData>> _readMasterCalendarPlatformChips(
  Map<String, dynamic> response,
) {
  final itemsRaw = response['items'];
  if (itemsRaw is! List) return const <String, List<_PlatformChipData>>{};

  final chipsByPostId = <String, List<_PlatformChipData>>{};
  for (final itemRaw in itemsRaw) {
    if (itemRaw is! Map) continue;
    final item = Map<String, dynamic>.from(itemRaw);
    final chipsRaw = item['platformChips'];
    if (chipsRaw is! List) continue;

    for (final chipRaw in chipsRaw) {
      if (chipRaw is! Map) continue;
      final chip = Map<String, dynamic>.from(chipRaw);
      final aiPostId = (chip['aiPostId'] ?? '').toString().trim();
      final chipId = (chip['id'] ?? '').toString().trim();
      final platform = (chip['platform'] ?? '').toString().trim();
      if (aiPostId.isEmpty || platform.isEmpty) continue;
      final mediaRaw = chip['mediaUrls'];

      final existing = chipsByPostId[aiPostId] ?? <_PlatformChipData>[];
      existing.add(
        _PlatformChipData(
          id: chipId,
          platform: platform,
          status: (chip['status'] ?? '').toString().trim(),
          title: (chip['title'] ?? '').toString().trim().isEmpty
              ? null
              : (chip['title'] ?? '').toString().trim(),
          caption: (chip['caption'] ?? '').toString().trim().isEmpty
              ? null
              : (chip['caption'] ?? '').toString().trim(),
          mediaUrls: mediaRaw is List
              ? mediaRaw
                    .map((url) => url.toString().trim())
                    .where((url) => url.isNotEmpty)
                    .toList(growable: false)
              : const <String>[],
          scheduledAt:
              DateTime.tryParse((chip['scheduledAt'] ?? '').toString())
                  ?.toLocal(),
          socialPostId: (chip['socialPostId'] ?? '').toString().trim().isEmpty
              ? null
              : (chip['socialPostId'] ?? '').toString().trim(),
        ),
      );
      chipsByPostId[aiPostId] = existing;
    }
  }

  return chipsByPostId;
}

List<_PlatformChipData> _platformsForPosts(
  List<GbpPost> posts,
  Map<String, List<_PlatformChipData>> platformChipsByPostId,
) {
  final seen = <String>{};
  final chips = <_PlatformChipData>[];
  for (final post in posts) {
    final postChips = platformChipsByPostId[post.id];
    if (postChips == null || postChips.isEmpty) {
      if (seen.add('GOOGLE_BUSINESS')) {
        chips.add(
          _PlatformChipData(
            id: '',
            platform: 'GOOGLE_BUSINESS',
            status: post.publishStatus,
            socialPostId: null,
          ),
        );
      }
      continue;
    }
    for (final chip in postChips) {
      if (seen.add(chip.platform)) {
        chips.add(chip);
      }
    }
  }
  return chips;
}

Map<String, int> _socialConnectRequiredCounts(
  Map<String, List<_PlatformChipData>> platformChipsByPostId,
) {
  final counts = <String, int>{};
  for (final chips in platformChipsByPostId.values) {
    for (final chip in chips) {
      final platform = chip.platform.toUpperCase();
      if (platform != 'FACEBOOK' && platform != 'INSTAGRAM') continue;
      if (_platformStatusLabel(chip) != 'connect required') continue;
      counts[platform] = (counts[platform] ?? 0) + 1;
    }
  }
  return counts;
}

bool _hasSocialPlatformChips(
  Map<String, List<_PlatformChipData>> platformChipsByPostId,
) {
  for (final chips in platformChipsByPostId.values) {
    for (final chip in chips) {
      final platform = chip.platform.toUpperCase();
      if (platform == 'FACEBOOK' || platform == 'INSTAGRAM') {
        return true;
      }
    }
  }
  return false;
}

String _platformLabel(String platform) {
  final normalized = platform.toUpperCase();
  if (normalized == 'GOOGLE_BUSINESS') return 'GBP';
  if (normalized == 'FACEBOOK') return 'FB';
  if (normalized == 'INSTAGRAM') return 'IG';
  return normalized.length <= 3 ? normalized : normalized.substring(0, 3);
}

IconData _platformIcon(String platform) {
  final normalized = platform.toUpperCase();
  if (normalized == 'GOOGLE_BUSINESS') return Icons.storefront_rounded;
  if (normalized == 'FACEBOOK') return Icons.facebook_rounded;
  if (normalized == 'INSTAGRAM') return Icons.camera_alt_rounded;
  return Icons.public_rounded;
}

Color _platformColor(String platform) {
  final normalized = platform.toUpperCase();
  if (normalized == 'GOOGLE_BUSINESS') return const Color(0xFF1267F1);
  if (normalized == 'FACEBOOK') return const Color(0xFF1877F2);
  if (normalized == 'INSTAGRAM') return const Color(0xFFE94363);
  return const Color(0xFF66728A);
}

Color _platformChipColor(_PlatformChipData chip) {
  final statusLabel = _platformStatusLabel(chip);
  if (statusLabel == 'connect required') return const Color(0xFF9A5B00);
  if (statusLabel == 'live') return const Color(0xFF17A964);
  if (statusLabel == 'failed') return const Color(0xFFE94363);
  return _platformColor(chip.platform);
}

String _platformStatusLabel(_PlatformChipData chip) {
  final platform = chip.platform.toUpperCase();
  final status = chip.status.toUpperCase();
  final isSocial = platform == 'FACEBOOK' || platform == 'INSTAGRAM';

  if (isSocial && chip.socialPostId == null) {
    return 'connect required';
  }
  if (status == 'SCHEDULED') return 'scheduled';
  if (status == 'PUBLISHED' || status == 'LIVE') return 'live';
  if (status == 'PUBLISHING') return 'publishing';
  if (status == 'FAILED') return isSocial ? 'connect required' : 'failed';
  if (status == 'PENDING_APPROVAL') return 'review';
  return 'planned';
}

DateTime _postDate(GbpPost post) {
  return post.scheduledFor ?? post.createdAt;
}

String _calendarBadgeLabel(GbpPost post) {
  final status = post.publishStatus.toUpperCase();
  if (status == 'PUBLISHING') return 'PUBLISHING';
  if (status == 'REJECTED') return 'REVIEW';
  if (status == 'FAILED') return 'FAILED';
  if (post.publishStatus == 'DRAFT' && post.scheduledFor != null) {
    return 'REVIEW';
  }
  if (post.publishStatus == 'SCHEDULED') return 'SCHEDULED';
  return post.badgeLabel;
}

Color _calendarStatusColor(GbpPost post) {
  final status = post.publishStatus.toUpperCase();
  if (status == 'PUBLISHING') return const Color(0xFF1267F1);
  return _statusColor(post.status);
}

String? _googlePostViewUrl(GbpPost post) {
  final postName = post.gmbPostId?.trim() ?? '';
  if (postName.isEmpty && post.title.trim().isEmpty) return null;
  final query = [
    post.title.trim(),
    'Google Business Profile',
  ].where((part) => part.isNotEmpty).join(' ');
  return 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
}

Future<void> _openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

String _failedPostSummary(GbpPost post) {
  final reason = _cleanFailureReason(post.errorMessage);
  return 'Needs review • $reason';
}

String _cleanFailureReason(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) {
    return 'Google could not publish this post. Review the content and try again.';
  }
  if (raw.toLowerCase() == 'auth required') {
    return 'Google connection needs attention before this post can be published.';
  }
  return raw
      .replaceFirst('Exception: ', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _formatPostDate(DateTime value) {
  return '${value.day} ${_shortMonth(value.month)} ${value.year}';
}

String _formatPostTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

IconData _postTypeIcon(String value) {
  final type = value.toUpperCase();
  if (type.contains('EVENT')) return Icons.event_available_outlined;
  if (type.contains('PRODUCT')) return Icons.inventory_2_outlined;
  if (type.contains('OFFER')) return Icons.local_offer_outlined;
  if (type.contains('PHOTO')) return Icons.image_outlined;
  return Icons.article_outlined;
}

Color _postTypeColor(String value) {
  final type = value.toUpperCase();
  if (type.contains('EVENT')) return const Color(0xFF7C3AED);
  if (type.contains('PRODUCT')) return const Color(0xFF0891B2);
  if (type.contains('OFFER')) return const Color(0xFFFF8A1F);
  if (type.contains('PHOTO')) return const Color(0xFFEC4899);
  return const Color(0xFF1267F1);
}

AiManagerAction? _findRunnableCalendarAction(List<AiManagerAction> actions) {
  final calendarActions = actions
      .where((action) => action.type == 'GBP_CONTENT_CALENDAR')
      .toList(growable: false);
  for (final action in calendarActions) {
    if (action.canApprove || action.canRun) {
      return action;
    }
  }
  return null;
}

DateTime _startOfDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _isSameMonth(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month;
}

List<DateTime> _calendarDays(DateTime visibleMonth) {
  final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
  final firstGridDay = firstDay.subtract(Duration(days: firstDay.weekday % 7));
  return List.generate(42, (index) => firstGridDay.add(Duration(days: index)));
}

Color _statusColor(GbpPostStatus status) {
  switch (status) {
    case GbpPostStatus.live:
      return const Color(0xFF1267F1);
    case GbpPostStatus.scheduled:
      return const Color(0xFF22B66E);
    case GbpPostStatus.failed:
      return const Color(0xFFE94363);
    case GbpPostStatus.draft:
      return const Color(0xFFFF8A1F);
  }
}

String _monthName(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return months[month - 1];
}

String _shortMonth(int month) {
  return _monthName(month).substring(0, 3).toUpperCase();
}
