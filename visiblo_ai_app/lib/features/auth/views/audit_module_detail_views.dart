import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../services/auth_api_service.dart';
import '../models/audit_models.dart';
import '../models/business_review.dart';
import '../models/citation_manager_models.dart';
import '../models/test_account.dart';
import '../widgets/auth_navigation_shell.dart';

class AuditCategoryModuleView extends GetView<OnboardingController> {
  const AuditCategoryModuleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.currentUser.value;
      if (user == null) {
        return const AuthNavigationShell(
          currentTab: AuthTab.audit,
          backgroundColor: _AuditModulePalette.canvas,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      final section = controller.liveAudit.value?.sections
          .firstWhereOrNull((s) => s.key == 'category');

      return _AuditModuleScaffold(
        title: 'Optimization Modules',
        trailing: _TopBarIconButton(
          icon: Icons.more_vert_rounded,
          onTap: () => _showModuleSnack(
            'More actions',
            'More category actions can be attached here next.',
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AuditCategoryModuleContent(
                section: section,
                user: user,
                onManageTap: () => _showModuleSnack(
                  'Manage categories',
                  'Category sync to Google Business Profile can be connected here next.',
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class AuditHoursModuleView extends GetView<OnboardingController> {
  const AuditHoursModuleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.currentUser.value;
      if (user == null) {
        return const AuthNavigationShell(
          currentTab: AuthTab.audit,
          backgroundColor: _AuditModulePalette.canvas,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      final section = controller.liveAudit.value?.sections
          .firstWhereOrNull((s) => s.key == 'hours');

      return _AuditModuleScaffold(
        title: 'Business Hours',
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AuditHoursModuleContent(
                user: user,
                section: section,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class AuditReviewModuleView extends GetView<OnboardingController> {
  const AuditReviewModuleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.currentUser.value;
      if (user == null) {
        return const AuthNavigationShell(
          currentTab: AuthTab.audit,
          backgroundColor: _AuditModulePalette.canvas,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      final reviews = controller.businessReviewsFor(user);
      final averageRating = controller.averageBusinessReviewScore(user: user);

      return _AuditModuleScaffold(
        title: 'Review Response Health',
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AuditReviewModuleContent(
                section: controller.liveAudit.value?.sections
                    .firstWhereOrNull((s) => s.key == 'reviews'),
                reviews: reviews,
                averageRating: averageRating,
                onViewAllTap: () => Get.toNamed(AppRoutes.clientReviews),
                onCreatePosterTap: () => Get.toNamed(AppRoutes.reviewPoster),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class AuditCategoryModuleContent extends StatelessWidget {
  const AuditCategoryModuleContent({
    super.key,
    required this.section,
    required this.user,
    required this.onManageTap,
  });

  final AuditSection? section;
  final TestAccount user;
  final VoidCallback onManageTap;

  @override
  Widget build(BuildContext context) {
    final primaryCategory = section?.currentValue?.isNotEmpty == true ? section!.currentValue! : _businessCategory(user);
    final suggestions = section?.suggestions?.isNotEmpty == true ? section!.suggestions! : _categorySuggestionLabels(user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'CATEGORY COVERAGE',
                      style: AppTypography.label(
                        fontSize: 11.4,
                        color: const Color(0xFF596372),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.55,
                      ),
                    ),
                  ),
                  _ScoreBadge(
                    label: '${section?.score ?? 75}/100',
                    background: const Color(0xFFF4EAFF),
                    color: const Color(0xFF9A5CE4),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF6EBFF),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.layers_rounded,
                      size: 18,
                      color: Color(0xFF9A5CE4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Business Category map',
                      style: AppTypography.card(
                        fontSize: 16.4,
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Categories tell Google what searches your profile should appear for. Keep the primary category precise and add only relevant secondary categories.',
                style: AppTypography.body(
                  fontSize: 13.3,
                  height: 1.45,
                  color: const Color(0xFF596372),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel(label: 'PRIMARY CATEGORY'),
              const SizedBox(height: 10),
              Text(
                primaryCategory,
                style: AppTypography.card(
                  fontSize: 18,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This is the strongest category signal for local ranking.',
                style: AppTypography.body(
                  fontSize: 13.3,
                  height: 1.45,
                  color: const Color(0xFF596372),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel(label: 'AUDIT CHECKS'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFEFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8EDF4)),
                ),
                child: Column(
                  children: [
                    ...(section?.findings ?? []).map((f) => _CategoryAuditCheckRow(
                      icon: f.status == 'pass' ? Icons.check_rounded : (f.status == 'fail' ? Icons.cancel_outlined : Icons.warning_amber_rounded),
                      iconBackground: f.status == 'pass' ? const Color(0xFFE9FBF6) : (f.status == 'fail' ? const Color(0xFFFFEAEA) : const Color(0xFFFFF4E8)),
                      iconColor: f.status == 'pass' ? const Color(0xFF1FBF8F) : (f.status == 'fail' ? const Color(0xFFFF5D5D) : const Color(0xFFFF9800)),
                      title: f.label,
                      subtitle: f.detail,
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel(label: 'SUGGESTED ADDITIONS'),
              const SizedBox(height: 8),
              Text(
                'Add these only if they accurately match what the business offers.',
                style: AppTypography.body(
                  fontSize: 13.3,
                  height: 1.45,
                  color: const Color(0xFF596372),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestions.asMap().entries.map((entry) {
                  return _SuggestionPill(
                    label: entry.value,
                    isSelected: entry.key == 0,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _OutlinedAuditButton(
          label: 'Manage on Google Business Profile',
          icon: Icons.open_in_new_rounded,
          onTap: onManageTap,
        ),
      ],
    );
  }
}

class AuditHoursModuleContent extends StatefulWidget {
  const AuditHoursModuleContent({
    super.key,
    required this.user,
    required this.section,
  });

  final TestAccount user;
  final AuditSection? section;

  @override
  State<AuditHoursModuleContent> createState() => _AuditHoursModuleContentState();
}

class _AuditHoursModuleContentState extends State<AuditHoursModuleContent> {
  final OnboardingController _onboardingController = Get.find<OnboardingController>();
  final AuthApiService _authApiService = Get.find<AuthApiService>();
  late List<_BusinessHoursEntry> _entries;
  CitationNapInfo? _napInfo;
  bool _isLoadingNap = true;
  bool _isSavingHours = false;

  @override
  void initState() {
    super.initState();
    _entries = _entriesFromRegularHours(null);
    _loadNapInfo();
  }

  Future<void> _loadNapInfo() async {
    try {
      final locationId = await _resolveLocationId();
      if (locationId.isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() => _isLoadingNap = false);
        return;
      }

      final napInfo = await _authApiService.fetchLocationNap(locationId);
      if (!mounted) {
        return;
      }

      setState(() {
        _napInfo = napInfo;
        _entries = _entriesFromRegularHours(napInfo?.regularHours);
        _isLoadingNap = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingNap = false);
    }
  }

  Future<String> _resolveLocationId() async {
    try {
      final me = await _authApiService.fetchMyData();
      if (me.locationId.trim().isNotEmpty) {
        return me.locationId.trim();
      }
    } catch (_) {}

    if (widget.user.backendAvailableBusinesses.isNotEmpty) {
      return widget.user.backendAvailableBusinesses.first['locationId']
              ?.toString() ??
          '';
    }
    return '';
  }

  Future<void> _syncHoursToGoogle() async {
    if (_isSavingHours) {
      return;
    }

    final locationId = await _resolveLocationId();
    if (locationId.isEmpty) {
      _showModuleSnack(
        'Location unavailable',
        'Select a valid business location before syncing hours.',
      );
      return;
    }

    setState(() => _isSavingHours = true);
    try {
      final updatedNap = await _authApiService.updateCitationNap(
        locationId,
        businessName: _effectiveBusinessName(widget.user, _napInfo),
        completeAddress: _effectiveAddress(widget.user, _napInfo),
        phone: _effectivePhone(widget.user, _napInfo),
        website: _effectiveWebsite(widget.user, _napInfo),
        regularHours: _buildAuditRegularHoursPayload(_entries),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _napInfo = updatedNap;
        _entries = _entriesFromRegularHours(updatedNap.regularHours);
      });

      await _onboardingController.fetchDashboardLiveStream();

      final needsManualConfirmation =
          updatedNap.gmbSyncFields?.any(
            (field) =>
                field.status == CitationGmbSyncStatus.manualConfirmation ||
                field.status == CitationGmbSyncStatus.failed,
          ) ??
          false;

      _showModuleSnack(
        'Hours updated',
        needsManualConfirmation
            ? 'Hours were saved in VisibloAI. Some Google Business Profile fields need manual confirmation.'
            : updatedNap.gmbLinked
            ? 'Hours were saved and synced to Google Business Profile.'
            : 'Hours were saved for this business workspace.',
      );
    } catch (error) {
      _showModuleSnack(
        'Sync failed',
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingHours = false);
      }
    }
  }

  Future<void> _pickTime(int index, {required bool isOpenTime}) async {
    final currentEntry = _entries[index];
    final initialTime = _parseTimeOfDay24(
      isOpenTime ? currentEntry.opensAt : currentEntry.closesAt,
    );

    final pickedTime = await showDialog<TimeOfDay>(
      context: context,
      barrierColor: const Color(0xB3000000),
      builder: (dialogContext) {
        return _AuditHoursTimePickerDialog(
          initialTime: initialTime,
          title: isOpenTime ? 'Select Opening Time' : 'Select Closing Time',
          subtitle: isOpenTime
              ? 'Choose when this business day starts.'
              : 'Choose when this business day ends.',
          accent: AppColors.primaryDark,
          leadingIcon: isOpenTime
              ? Icons.wb_sunny_outlined
              : Icons.nights_stay_outlined,
        );
      },
    );

    if (pickedTime == null || !mounted) {
      return;
    }

    final formattedTime = _formatTimeOfDay24(pickedTime);
    setState(() {
      _entries[index] = currentEntry.copyWith(
        opensAt: isOpenTime ? formattedTime : currentEntry.opensAt,
        closesAt: isOpenTime ? currentEntry.closesAt : formattedTime,
      );
    });
  }

  void _toggleOpen(int index, bool isOpen) {
    setState(() {
      _entries[index] = _entries[index].copyWith(isClosed: !isOpen);
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysOpen = _entries.where((entry) => !entry.isClosed).length;
    final areHoursConsistent = _entries
        .where((entry) => !entry.isClosed)
        .map((entry) => '${entry.opensAt}-${entry.closesAt}')
        .toSet()
        .length <= 1;
    final syncLabel = _napInfo == null
        ? 'Draft'
        : _napInfo!.gmbLinked
        ? 'Synced'
        : 'Saved';
    final syncSubLabel = _napInfo == null
        ? 'local state'
        : _napInfo!.gmbLinked
        ? 'Google ready'
        : 'awaiting sync';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: _SectionLabel(label: 'AVAILABILITY')),
                  _ScoreBadge(
                    label: '${widget.section?.score ?? 100}/100',
                    background: const Color(0xFFEAFBFF),
                    color: AppColors.primaryDark,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Business hours\ncontrol',
                style: AppTypography.card(
                  fontSize: 18.8,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Accurate opening hours reduce bad customer experiences and help Google trust that the profile is maintained.',
                style: AppTypography.body(
                  fontSize: 13.2,
                  color: const Color(0xFF596372),
                  height: 1.42,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              const _SectionLabel(label: 'AUDIT CHECKS'),
              const SizedBox(height: 10),
              Column(
                children: [
                  _InlineCheckItem(
                    label: 'Coverage',
                    text: daysOpen == 7
                        ? 'All 7 days have hours set'
                        : '$daysOpen of 7 days are marked open',
                  ),
                  const SizedBox(height: 8),
                  _InlineCheckItem(
                    label: 'Days active',
                    text: '$daysOpen of 7 days configured',
                  ),
                  const SizedBox(height: 8),
                  _InlineCheckItem(
                    label: 'Consistent',
                    text: areHoursConsistent
                        ? 'Open days use a consistent schedule'
                        : 'Opening times vary across the week',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel(label: 'AUDIT CHECKS'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8EDF4)),
                ),
                child: Column(
                  children: [
                    ...(widget.section?.findings ?? []).map((f) => _HoursAuditLine(
                      title: f.label,
                      subtitle: f.detail,
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _SectionLabel(label: 'HOURS HEALTH'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _HoursMetricCard(
                value: '$daysOpen/7',
                label: 'days open',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HoursMetricCard(
                icon: Icons.cloud_done_rounded,
                iconColor: const Color(0xFFE05AC8),
                value: syncLabel,
                label: syncSubLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _SectionLabel(label: 'WEEKLY SCHEDULE'),
        const SizedBox(height: 2),
        Text(
          _isLoadingNap
              ? 'Loading current hours from your business workspace.'
              : 'Review each day before syncing to Google.',
          style: AppTypography.body(
            fontSize: 12.4,
            color: const Color(0xFF596372),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        if (_isLoadingNap)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else
          _BusinessWeekSchedule(
            entries: _entries,
            onOpenChanged: _toggleOpen,
            onEditOpenTime: (index) => _pickTime(index, isOpenTime: true),
            onEditCloseTime: (index) => _pickTime(index, isOpenTime: false),
          ),
        const SizedBox(height: 14),
        _FilledAuditButton(
          label: _isSavingHours ? 'Syncing hours...' : 'Sync Hours to Google',
          icon: Icons.cloud_upload_outlined,
          onTap: _syncHoursToGoogle,
        ),
      ],
    );
  }
}

class AuditReviewModuleContent extends StatelessWidget {
  const AuditReviewModuleContent({
    super.key,
    required this.section,
    required this.reviews,
    required this.averageRating,
    required this.onViewAllTap,
    required this.onCreatePosterTap,
  });

  final AuditSection? section;

  final List<BusinessReview> reviews;
  final double averageRating;
  final VoidCallback onViewAllTap;
  final VoidCallback onCreatePosterTap;

  @override
  Widget build(BuildContext context) {
    final totalReviews = section?.meta?['totalCount'] ?? reviews.length;
    final respondedCount = reviews
        .where((review) => review.hasOwnerReply)
        .length;
    final responseRate = section?.meta?['responseRate'] ?? (totalReviews == 0 ? 0 : ((respondedCount / totalReviews) * 100).round());
    final needReply = section?.meta?['unrepliedCount'] ?? (totalReviews - respondedCount);
    final recentReviews = reviews
        .where((review) => review.hasOwnerReply)
        .take(2)
        .toList();
    final visibleReviews = recentReviews.isEmpty
        ? reviews.take(2).toList()
        : recentReviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: const [
                        Icon(
                          Icons.star_border_rounded,
                          size: 16,
                          color: Color(0xFFFFA31A),
                        ),
                        SizedBox(width: 6),
                        _SectionLabel(label: 'REVIEW TRUST'),
                      ],
                    ),
                  ),
                  _ScoreBadge(
                    label: '${section?.score ?? 65}/100',
                    background: const Color(0xFFFFF1DA),
                    color: const Color(0xFFFFA31A),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Review response health',
                style: AppTypography.card(
                  fontSize: 18.6,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track rating strength, response coverage, and missed replies that can quietly reduce customer trust.',
                style: AppTypography.body(
                  fontSize: 13.2,
                  color: const Color(0xFF596372),
                  height: 1.42,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: [
            _ReviewMetricCard(value: '$totalReviews', label: 'TOTAL REVIEWS'),
            _ReviewMetricCard(
              value: (section?.meta?['averageRating'] ?? averageRating).toStringAsFixed((section?.meta?['averageRating'] ?? averageRating).truncateToDouble() == (section?.meta?['averageRating'] ?? averageRating) ? 0 : 1),
              label: 'AVG RATING',
              trailingIcon: Icons.star_rounded,
              trailingColor: const Color(0xFFFFB21E),
            ),
            _ReviewGaugeCard(value: responseRate),
            _ReviewMetricCard(
              value: '$needReply',
              label: 'NEED REPLY',
              valueColor: const Color(0xFFFF5D5D),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel(label: 'AUDIT CHECKS'),
              const SizedBox(height: 12),
              if (section != null && section!.findings.isNotEmpty)
                ...section!.findings.map((f) {
                  final isPass = f.status == 'pass';
                  final isFail = f.status == 'fail';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReviewAuditRow(
                      icon: isPass ? Icons.check_circle_outline_rounded : (isFail ? Icons.cancel_outlined : Icons.warning_amber_rounded),
                      color: isPass ? const Color(0xFF22B273) : (isFail ? const Color(0xFFFF5D5D) : const Color(0xFFFFA31A)),
                      title: f.label,
                      subtitle: f.detail,
                    ),
                  );
                })
              else ...[
                _ReviewAuditRow(
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFFFA31A),
                  title: 'Building up — $totalReviews reviews',
                  subtitle: 'Aim for 50+ for strong local ranking',
                ),
                const SizedBox(height: 12),
                _ReviewAuditRow(
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF22B273),
                  title:
                      'Rating — ${averageRating.toStringAsFixed(1)} star average',
                  subtitle: 'Excellent',
                ),
                const SizedBox(height: 12),
                _ReviewAuditRow(
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFFFA31A),
                  title: 'Response rate — $responseRate% replied',
                  subtitle: 'Try to respond to all reviews',
                ),
                const SizedBox(height: 12),
                const _ReviewAuditRow(
                  icon: Icons.warning_amber_rounded,
                  color: Color(0xFFFFA31A),
                  title: 'Review freshness',
                  subtitle: 'No new review found in the last 90 days.',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(child: _SectionLabel(label: 'RECENT REVIEWS')),
            TextButton(
              onPressed: onViewAllTap,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandBlue,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View all',
                style: AppTypography.label(
                  fontSize: 12.2,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Use live API recentReviews when available
        if (section?.meta?['recentReviews'] != null &&
            (section!.meta!['recentReviews'] as List).isNotEmpty)
          ...(section!.meta!['recentReviews'] as List)
              .take(2)
              .toList()
              .asMap()
              .entries
              .map((entry) {
            final r = entry.value as Map<String, dynamic>;
            final name = r['name']?.toString() ?? 'Customer';
            final rating = (r['rating'] is int) ? r['rating'] as int : int.tryParse(r['rating']?.toString() ?? '5') ?? 5;
            final comment = r['comment']?.toString() ?? '';
            final reply = r['reply']?.toString() ?? '';
            final createTime = r['createTime']?.toString() ?? '';
            final hasReply = reply.isNotEmpty;
            final accent = entry.key.isEven
                ? const Color(0xFFFF4B98)
                : const Color(0xFF7A63FF);

            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == 1 || entry.key == (section!.meta!['recentReviews'] as List).take(2).length - 1 ? 0 : 12,
              ),
              child: _ModuleSurfaceCard(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AppTypography.card(
                              fontSize: 16.2,
                              color: AppColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (hasReply)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF9F0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.reply_rounded, size: 12, color: Color(0xFF3AAE67)),
                                const SizedBox(width: 4),
                                Text('Replied', style: AppTypography.label(fontSize: 11, color: const Color(0xFF3AAE67), fontWeight: FontWeight.w700)),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4E8),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('Needs reply', style: AppTypography.label(fontSize: 11, color: const Color(0xFFE5890A), fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '★' * rating,
                          style: AppTypography.body(fontSize: 14, color: const Color(0xFFFFB21E), fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _timeAgoFromIso(createTime),
                          style: AppTypography.label(fontSize: 11.4, color: const Color(0xFF7A8698), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    if (comment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '"${comment.length > 150 ? '${comment.substring(0, 150)}…' : comment}"',
                        style: AppTypography.body(fontSize: 13, color: AppColors.text, height: 1.42, fontWeight: FontWeight.w500),
                      ),
                    ],
                    if (hasReply) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FBFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border(left: BorderSide(color: accent, width: 2.5)),
                        ),
                        child: Text(
                          'Your reply: ${reply.length > 120 ? '${reply.substring(0, 120)}…' : reply}',
                          style: AppTypography.body(fontSize: 12.3, color: const Color(0xFF596372), height: 1.38, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          })
        else
          ...visibleReviews.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == visibleReviews.length - 1 ? 0 : 12,
              ),
              child: _RecentReviewCard(
                review: entry.value,
                accent: entry.key.isEven
                    ? const Color(0xFFFF4B98)
                    : const Color(0xFF7A63FF),
              ),
            );
          }),
        const SizedBox(height: 14),
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            children: [
              const Icon(
                Icons.star_border_rounded,
                size: 26,
                color: AppColors.primaryDark,
              ),
              const SizedBox(height: 8),
              Text(
                'Get more Google reviews',
                textAlign: TextAlign.center,
                style: AppTypography.card(
                  fontSize: 16.4,
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Share a QR code...',
                style: AppTypography.body(
                  fontSize: 13,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _FilledAuditButton(
                  label: 'Create Review Poster',
                  onTap: onCreatePosterTap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AuditPhotosModuleContent extends StatelessWidget {
  const AuditPhotosModuleContent({
    super.key,
    required this.section,
    required this.uploadedPhotos,
    required this.activePhotoPath,
    required this.onManageTap,
  });

  final AuditSection? section;
  final List<String> uploadedPhotos;
  final String activePhotoPath;
  final VoidCallback onManageTap;

  @override
  Widget build(BuildContext context) {
    final totalAssets = section?.meta?['totalCount'] ?? (uploadedPhotos.length >= 9 ? uploadedPhotos.length : 9);
    final previewItems = _buildAuditPhotoPreviewItems(
      uploadedPhotos: uploadedPhotos,
      activePhotoPath: activePhotoPath,
    ).take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
                      color: const Color(0xFFE8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 20,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VISUAL PROOF',
                          style: AppTypography.label(
                            fontSize: 11.2,
                            color: const Color(0xFF6A7587),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.55,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Business image\ncoverage',
                          style: AppTypography.card(
                            fontSize: 18.8,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ScoreBadge(
                    label: '${section?.score ?? 55}/100',
                    background: const Color(0xFFE5FBFF),
                    color: AppColors.primaryDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$totalAssets image assets found. Fresh photos help customers trust the business before they call or visit.',
                style: AppTypography.body(
                  fontSize: 13.2,
                  height: 1.42,
                  color: const Color(0xFF596372),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel(label: 'AUDIT CHECKS'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8EDF4)),
                ),
                child: Column(
                  children: section != null && section!.findings.isNotEmpty
                      ? section!.findings.asMap().entries.map((entry) {
                          final f = entry.value;
                          final isPass = f.status == 'pass';
                          final isFail = f.status == 'fail';
                          final isLast = entry.key == section!.findings.length - 1;
                          return Column(
                            children: [
                              _CategoryAuditCheckRow(
                                icon: isPass ? Icons.check_rounded : (isFail ? Icons.cancel_outlined : Icons.warning_amber_rounded),
                                iconBackground: isPass ? const Color(0xFFE9FBF6) : (isFail ? const Color(0xFFFFEAEA) : const Color(0xFFFFF4E8)),
                                iconColor: isPass ? const Color(0xFF1FBF8F) : (isFail ? const Color(0xFFFF5D5D) : const Color(0xFFFF9800)),
                                title: f.label,
                                subtitle: f.detail,
                              ),
                              if (!isLast)
                                const Divider(height: 1, color: Color(0xFFEFF3F8)),
                            ],
                          );
                        }).toList()
                      : const [
                          _CategoryAuditCheckRow(
                            icon: Icons.check_rounded,
                            iconBackground: Color(0xFFE9FBF6),
                            iconColor: Color(0xFF1FBF8F),
                            title: 'Image Quality',
                            subtitle: 'High resolution assets detected',
                          ),
                          Divider(height: 1, color: Color(0xFFEFF3F8)),
                          _CategoryAuditCheckRow(
                            icon: Icons.warning_amber_rounded,
                            iconBackground: Color(0xFFFFF4E8),
                            iconColor: Color(0xFFFF9800),
                            title: 'Category Diversity',
                            subtitle: 'Needs more interior shots',
                          ),
                        ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel(label: 'PHOTO INVENTORY'),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '$totalAssets',
                  style: AppTypography.card(
                    fontSize: 34,
                    color: const Color(0xFF3FA50B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Center(
                child: Text(
                  'total profile photos and media assets',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    fontSize: 13,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel(label: 'RECENT PHOTOS'),
              const SizedBox(height: 12),
              if (section?.meta?['photos'] != null &&
                  (section!.meta!['photos'] as List).isNotEmpty)
                Row(
                  children: (section!.meta!['photos'] as List)
                      .take(3)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                    final photo = entry.value as Map<String, dynamic>;
                    final url = photo['url']?.toString() ?? '';
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: entry.key == 2 || entry.key == (section!.meta!['photos'] as List).take(3).length - 1 ? 0 : 8,
                        ),
                        child: AspectRatio(
                          aspectRatio: 1.1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: url.isNotEmpty
                                ? Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Color(0xFFE8F8FB), Color(0xFFDCEAF7)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.image_outlined, color: AppColors.primaryDark),
                                      );
                                    },
                                  )
                                : Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFFE8F8FB), Color(0xFFDCEAF7)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.image_outlined, color: AppColors.primaryDark),
                                  ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )
              else
                Row(
                  children: previewItems.asMap().entries.map((entry) {
                    final item = entry.value;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: entry.key == previewItems.length - 1 ? 0 : 8,
                        ),
                        child: _AuditPhotoPreviewTile(item: item),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD7EEF2)),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.storefront_outlined,
                      size: 20,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Showcase your business\nbrand',
                          style: AppTypography.card(
                            fontSize: 16.2,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Business listings with high-quality, recent photos receive stronger engagement and more direction requests on Google Maps.',
                          style: AppTypography.body(
                            fontSize: 13,
                            color: const Color(0xFF596372),
                            height: 1.42,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _FilledAuditButton(
                label: 'Post New Photos',
                icon: Icons.file_upload_outlined,
                onTap: onManageTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AuditPostModuleContent extends StatelessWidget {
  const AuditPostModuleContent({
    super.key,
    required this.section,
    required this.user,
    required this.onOpenPostsTap,
  });

  final AuditSection? section;
  final TestAccount user;
  final VoidCallback onOpenPostsTap;

  @override
  Widget build(BuildContext context) {
    final meta = section?.meta ?? {};
    final recentPost = meta['recentPost'] as Map<String, dynamic>?;
    final totalPostCount = meta['totalCount'] ?? 0;
    final postsLast30Days = meta['recentPostsCount'] ?? 0;
    final daysSinceLastPost = meta['lastPostDaysAgo'] ?? 0;
    final postSummary = recentPost?['summary']?.toString() ?? '';
    final postMediaUrl = recentPost?['mediaUrl']?.toString() ?? '';
    final postCreateTime = recentPost?['createTime']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Google post\nmomentum',
                      style: AppTypography.card(
                        fontSize: 18.8,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w800,
                        height: 1.16,
                      ),
                    ),
                  ),
                  _ScoreBadge(
                    label: '${section?.score ?? 30}/100',
                    background: const Color(0xFFFFE8E8),
                    color: const Color(0xFFE85656),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$totalPostCount verified post records. Consistent updates show Google and customers that the business is active.',
                style: AppTypography.body(
                  fontSize: 13.2,
                  color: const Color(0xFF596372),
                  height: 1.42,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFE9EDF3), height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AuditStatColumn(
                      label: 'POSTS LAST 30D',
                      value: '$postsLast30Days',
                    ),
                  ),
                  Expanded(
                    child: _AuditStatColumn(
                      label: 'SINCE LAST POST',
                      value: '${daysSinceLastPost}d',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity Analysis',
                style: AppTypography.card(
                  fontSize: 16.2,
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFE9EDF3), height: 1),
              const SizedBox(height: 12),
              if (section != null && section!.findings.isNotEmpty)
                ...section!.findings.map((f) {
                  final isPass = f.status == 'pass';
                  final isFail = f.status == 'fail';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReviewAuditRow(
                      icon: isPass ? Icons.check_circle_outline_rounded : (isFail ? Icons.error_outline_rounded : Icons.warning_amber_rounded),
                      color: isPass ? AppColors.primaryDark : const Color(0xFFE85656),
                      title: f.label,
                      subtitle: f.detail,
                    ),
                  );
                })
              else ...[
                _ReviewAuditRow(
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.primaryDark,
                  title: 'Active',
                  subtitle: '$totalPostCount posts recorded historically.',
                ),
                const SizedBox(height: 12),
                _ReviewAuditRow(
                  icon: Icons.error_outline_rounded,
                  color: const Color(0xFFE85656),
                  title: 'Inactive',
                  subtitle: 'Last post was $daysSinceLastPost days ago.',
                ),
                const SizedBox(height: 12),
                _ReviewAuditRow(
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFE85656),
                  title: 'Low Frequency',
                  subtitle: '$postsLast30Days posts in the last 30 days.',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stay active on Google Search',
                style: AppTypography.card(
                  fontSize: 16.2,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Publishing regular updates improves local search visibility and customer engagement metrics.',
                style: AppTypography.body(
                  fontSize: 13,
                  color: const Color(0xFF596372),
                  height: 1.42,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              _FilledAuditButton(
                label: 'Create Brand Update',
                icon: Icons.edit_square,
                onTap: onOpenPostsTap,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // LATEST PROFILE UPDATE — live data from API
        if (recentPost != null)
          _ModuleSurfaceCard(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: _SectionLabel(label: 'LATEST PROFILE UPDATE'),
                      ),
                      Text(
                        _timeAgoFromIso(postCreateTime).isNotEmpty ? 'Posted ${_timeAgoFromIso(postCreateTime)}' : '',
                        style: AppTypography.label(
                          fontSize: 10.8,
                          color: const Color(0xFFE68AC3),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (postMediaUrl.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 1.55,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(0),
                      child: Image.network(
                        postMediaUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF4F7FB),
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined, color: AppColors.mutedText, size: 32),
                          );
                        },
                      ),
                    ),
                  ),
                if (postSummary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: Text(
                      postSummary,
                      style: AppTypography.body(
                        fontSize: 13.2,
                        color: AppColors.text,
                        height: 1.42,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _OutlinedAuditButton(
                    label: 'Open GBP Posts',
                    onTap: onOpenPostsTap,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
                      color: const Color(0xFFF3EEFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: Color(0xFF7C63F1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stay active on Google Search',
                          style: AppTypography.card(
                            fontSize: 16,
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Regular updates signal to Google that your business is reliable and active. Businesses that post weekly see stronger search visibility.',
                          style: AppTypography.body(
                            fontSize: 13,
                            color: const Color(0xFF596372),
                            height: 1.42,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _OutlinedAuditButton(
                label: 'Create Brand Update',
                icon: Icons.edit_square,
                onTap: onOpenPostsTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AuditProfileReadinessModuleContent extends StatelessWidget {
  const AuditProfileReadinessModuleContent({
    super.key,
    required this.section,
    required this.user,
    required this.onOpenManagerTap,
  });

  final AuditSection? section;
  final TestAccount user;
  final VoidCallback onOpenManagerTap;

  @override
  Widget build(BuildContext context) {
    final phoneNumber = user.phoneNumber.trim().isEmpty
        ? '099304 21939'
        : user.phoneNumber.trim();
    final address = _businessAddress(user);
    final websiteUrl = _businessWebsiteUrl(user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4EEFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.verified_user_outlined,
                      size: 22,
                      color: Color(0xFF7C63F1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AUDIT MODULE',
                          style: AppTypography.label(
                            fontSize: 11.2,
                            color: const Color(0xFF6A7587),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.55,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Profile Readiness',
                          style: AppTypography.card(
                            fontSize: 18.6,
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phone connected · Website connected',
                          style: AppTypography.body(
                            fontSize: 13,
                            color: const Color(0xFF596372),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _ScoreBadge(
                        label: '${section?.score ?? 80}/100',
                        background: const Color(0xFFF6EAFE),
                        color: const Color(0xFF8A57E2),
                      ),
                      const SizedBox(height: 10),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: Color(0xFF4A5567),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFE9EDF3), height: 1),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: _SectionLabel(label: 'AUDIT CHECKS'),
              ),
              const SizedBox(height: 14),
              _ProfileAuditItem(
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF2CB46A),
                title:
                    'Phone number — Customers can call directly from Google Search and Maps.',
                value: phoneNumber,
              ),
              const SizedBox(height: 16),
              _ProfileAuditItem(
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF2CB46A),
                title:
                    'Address — Address is available for local discovery and directions.',
                value: address,
              ),
              const SizedBox(height: 16),
              _ProfileAuditItem(
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF2CB46A),
                title:
                    'Website — Website link is connected for deeper conversion.',
                value: websiteUrl,
              ),
              const SizedBox(height: 16),
              const _ProfileAuditWarning(
                title:
                    'Place ID not saved — The dashboard can still audit, but precise review/ranking matching becomes weaker.',
                note:
                    'Next action: Sync the profile once from GBP Manager so VisibloAI can save the Google Place ID.',
              ),
              const SizedBox(height: 16),
              const _ProfileAuditWarning(
                title:
                    'Coordinates missing — Heatmap precision may be limited without location coordinates.',
                note:
                    'Next action: Sync the location or update address details so heatmap tracking can use accurate coordinates.',
              ),
              const SizedBox(height: 16),
              _OutlinedAuditButton(
                label: 'Open GBP Manager',
                icon: Icons.open_in_new_rounded,
                onTap: onOpenManagerTap,
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }
}

class AuditVisibilityActionsModuleContent extends StatelessWidget {
  const AuditVisibilityActionsModuleContent({
    super.key,
    required this.section,
    required this.onOpenReportsTap,
  });

  final AuditSection? section;
  final VoidCallback onOpenReportsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompactHeader = constraints.maxWidth < 320;
                  final titleBlock = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AUDIT MODULE',
                        style: AppTypography.label(
                          fontSize: 11.2,
                          color: const Color(0xFF6A7587),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.55,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Visibility &\nCustomer Actions',
                        style: AppTypography.card(
                          fontSize: 18.8,
                          color: AppColors.text,
                          fontWeight: FontWeight.w800,
                          height: 1.16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No insight history',
                        style: AppTypography.body(
                          fontSize: 13.8,
                          color: const Color(0xFF627086),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );

                  final scoreBlock = Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ScoreBadge(
                        label: '${section?.score ?? 68}/100',
                        background: const Color(0xFFFAF1EB),
                        color: const Color(0xFF8E6247),
                      ),
                      const SizedBox(height: 10),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: Color(0xFF5A6575),
                      ),
                    ],
                  );

                  if (isCompactHeader) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF2ED),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.north_east_rounded,
                                size: 22,
                                color: Color(0xFF8E6247),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: titleBlock),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: scoreBlock,
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF2ED),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.north_east_rounded,
                          size: 22,
                          color: Color(0xFF8E6247),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: titleBlock),
                      const SizedBox(width: 12),
                      scoreBlock,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDCE6F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(label: 'AUDIT CHECKS'),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 22,
                          color: Color(0xFFFF6A21),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Insights syncing — GBP insight history is not available yet, so this audit is holding performance as pending instead of treating it as a real failure.',
                            style: AppTypography.body(
                              fontSize: 13.8,
                              color: const Color(0xFF425063),
                              height: 1.42,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _NextActionCard(
                      text:
                          'Next action: Sync Google Business Profile insights, then refresh the audit to calculate real views, calls, directions, and website clicks.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _OutlinedAuditButton(
                label: 'Open Reports',
                icon: Icons.bar_chart_rounded,
                onTap: onOpenReportsTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AuditLocalRankingModuleContent extends StatelessWidget {
  const AuditLocalRankingModuleContent({
    super.key,
    required this.section,
    required this.onOpenRankingTap,
  });

  final AuditSection? section;
  final VoidCallback onOpenRankingTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModuleSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
                      color: const Color(0xFFE9F9EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.track_changes_rounded,
                      size: 22,
                      color: Color(0xFF1FAE63),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AUDIT MODULE',
                          style: AppTypography.label(
                            fontSize: 11.2,
                            color: const Color(0xFF6A7587),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.55,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Local Ranking\nCoverage',
                          style: AppTypography.card(
                            fontSize: 18.8,
                            color: AppColors.text,
                            fontWeight: FontWeight.w800,
                            height: 1.16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No keywords tracked',
                          style: AppTypography.body(
                            fontSize: 13.8,
                            color: const Color(0xFF627086),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _ScoreBadge(
                        label: '${section?.score ?? 30}/100',
                        background: const Color(0xFFFFECEC),
                        color: const Color(0xFFFF5D5D),
                      ),
                      const SizedBox(height: 10),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: Color(0xFF5A6575),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDCE6F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(label: 'AUDIT CHECKS'),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.cancel_outlined,
                          size: 22,
                          color: Color(0xFFFF5D5D),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No keywords tracked — No active local keywords are being tracked for this location.',
                            style: AppTypography.body(
                              fontSize: 13.8,
                              color: const Color(0xFF183C73),
                              height: 1.42,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _NextActionCard(
                      text:
                          'Next action: Add 5-10 buying-intent keywords like "category near me" and "category in city".',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _OutlinedAuditButton(
                label: 'Open Keyword Ranking',
                icon: Icons.track_changes_rounded,
                onTap: onOpenRankingTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuditModuleScaffold extends StatelessWidget {
  const _AuditModuleScaffold({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AuthNavigationShell(
      currentTab: AuthTab.audit,
      backgroundColor: _AuditModulePalette.canvas,
      child: Column(
        children: [
          _ModuleTopBar(title: title, trailing: trailing),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ModuleTopBar extends StatelessWidget {
  const _ModuleTopBar({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: _TopBarBackButton(),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.card(
                  fontSize: 17.5,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: trailing ?? const SizedBox(width: 40, height: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBarBackButton extends StatelessWidget {
  const _TopBarBackButton();

  @override
  Widget build(BuildContext context) {
    return _TopBarIconButton(
      icon: Icons.arrow_back_ios_new_rounded,
      onTap: Get.back,
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: AppColors.primaryDark),
        ),
      ),
    );
  }
}

class _ModuleSurfaceCard extends StatelessWidget {
  const _ModuleSurfaceCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060A2740),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.label(
        fontSize: 11.2,
        color: const Color(0xFF707B8D),
        fontWeight: FontWeight.w800,
        letterSpacing: 0.55,
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({
    required this.label,
    required this.background,
    required this.color,
  });

  final String label;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.label(
          fontSize: 11.6,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CategoryAuditCheckRow extends StatelessWidget {
  const _CategoryAuditCheckRow({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body(
                    fontSize: 13.2,
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTypography.body(
                    fontSize: 11.7,
                    color: const Color(0xFF596372),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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

class _SuggestionPill extends StatelessWidget {
  const _SuggestionPill({required this.label, this.isSelected = false});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF2F8FF) : AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isSelected ? AppColors.brandBlue : const Color(0xFFD9E1EC),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.label(
          fontSize: 12,
          color: isSelected ? AppColors.brandBlue : const Color(0xFF555F70),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _OutlinedAuditButton extends StatelessWidget {
  const _OutlinedAuditButton({
    required this.label,
    this.icon,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary),
            color: AppColors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypography.button(
                    fontSize: 14.2,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 17, color: AppColors.primaryDark),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilledAuditButton extends StatelessWidget {
  const _FilledAuditButton({
    required this.label,
    this.icon,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2239B4BD),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.white),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTypography.button(
                  fontSize: 14.2,
                  color: AppColors.white,
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

class _InlineCheckItem extends StatelessWidget {
  const _InlineCheckItem({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Color(0xFFE5FAFA),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.check_rounded,
            size: 12,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label — ',
                  style: AppTypography.body(
                    fontSize: 12.6,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: text,
                  style: AppTypography.body(
                    fontSize: 12.6,
                    color: AppColors.text,
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

class _HoursAuditLine extends StatelessWidget {
  const _HoursAuditLine({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Color(0xFFEAFBF2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_rounded,
              size: 12,
              color: Color(0xFF42BD76),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body(
                    fontSize: 12.8,
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.body(
                    fontSize: 11.4,
                    color: const Color(0xFF596372),
                    fontWeight: FontWeight.w500,
                    height: 1.32,
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

class _HoursMetricCard extends StatelessWidget {
  const _HoursMetricCard({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return _ModuleSurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: iconColor ?? AppColors.primaryDark),
            const SizedBox(height: 6),
          ],
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTypography.card(
              fontSize: 16.8,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.label(
              fontSize: 11.1,
              color: const Color(0xFF707B8D),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessWeekSchedule extends StatelessWidget {
  const _BusinessWeekSchedule({
    required this.entries,
    required this.onOpenChanged,
    required this.onEditOpenTime,
    required this.onEditCloseTime,
  });

  final List<_BusinessHoursEntry> entries;
  final void Function(int index, bool isOpen) onOpenChanged;
  final ValueChanged<int> onEditOpenTime;
  final ValueChanged<int> onEditCloseTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == entries.length - 1 ? 0 : 10,
          ),
          child: _BusinessDayHoursCard(
            entry: item,
            onOpenChanged: (value) => onOpenChanged(index, value),
            onEditOpenTime: () => onEditOpenTime(index),
            onEditCloseTime: () => onEditCloseTime(index),
          ),
        );
      }).toList(),
    );
  }
}

class _BusinessDayHoursCard extends StatelessWidget {
  const _BusinessDayHoursCard({
    required this.entry,
    required this.onOpenChanged,
    required this.onEditOpenTime,
    required this.onEditCloseTime,
  });

  final _BusinessHoursEntry entry;
  final ValueChanged<bool> onOpenChanged;
  final VoidCallback onEditOpenTime;
  final VoidCallback onEditCloseTime;

  @override
  Widget build(BuildContext context) {
    return _ModuleSurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.day,
                  style: AppTypography.card(
                    fontSize: 15,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                entry.isClosed ? 'Closed' : 'Open',
                style: AppTypography.label(
                  fontSize: 11.2,
                  color: entry.isClosed
                      ? const Color(0xFF596372)
                      : AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Switch.adaptive(
                value: !entry.isClosed,
                activeThumbColor: AppColors.white,
                activeTrackColor: AppColors.primaryDark,
                inactiveThumbColor: AppColors.white,
                inactiveTrackColor: const Color(0xFFDCE4EE),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: onOpenChanged,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HoursValueField(
                  label: 'OPENS',
                  value: _displayAuditHour(entry.opensAt),
                  enabled: !entry.isClosed,
                  onTap: onEditOpenTime,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HoursValueField(
                  label: 'CLOSES',
                  value: _displayAuditHour(entry.closesAt),
                  enabled: !entry.isClosed,
                  onTap: onEditCloseTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HoursValueField extends StatelessWidget {
  const _HoursValueField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label(
            fontSize: 10.6,
            color: const Color(0xFF8A95A7),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: enabled ? onTap : null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.fromLTRB(10, 11, 10, 11),
            backgroundColor: enabled
                ? const Color(0xFFF8FBFF)
                : const Color(0xFFF2F5F8),
            side: BorderSide(
              color: enabled
                  ? const Color(0xFFE1E7F0)
                  : const Color(0xFFE6EBF2),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: Icon(
            Icons.schedule_rounded,
            size: 14,
            color: enabled ? const Color(0xFF9AA5B6) : const Color(0xFFBBC4D1),
          ),
          label: Text(
            value,
            style: AppTypography.body(
              fontSize: 12.8,
              color: enabled ? AppColors.brandBlue : const Color(0xFF96A0AE),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuditHoursTimePickerDialog extends StatefulWidget {
  const _AuditHoursTimePickerDialog({
    required this.initialTime,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.leadingIcon,
  });

  final TimeOfDay initialTime;
  final String title;
  final String subtitle;
  final Color accent;
  final IconData leadingIcon;

  @override
  State<_AuditHoursTimePickerDialog> createState() =>
      _AuditHoursTimePickerDialogState();
}

class _AuditHoursTimePickerDialogState
    extends State<_AuditHoursTimePickerDialog> {
  late int _selectedHour;
  late int _selectedMinute;
  late bool _isAm;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    final hour24 = widget.initialTime.hour;
    _isAm = hour24 < 12;
    _selectedHour = hour24 % 12 == 0 ? 12 : hour24 % 12;
    _selectedMinute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(
      initialItem: _selectedHour - 1,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  TimeOfDay _buildResult() {
    var hour = _selectedHour % 12;
    if (!_isAm) {
      hour += 12;
    }
    return TimeOfDay(hour: hour, minute: _selectedMinute);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.transparent,
      child: _AuditTimeModalCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuditTimeModalHeader(
              title: 'Select Time',
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 12),
            Text(
              widget.subtitle,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF556987),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 78,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE7EDF6)),
                    ),
                    child: Row(
                      children: [
                        Icon(widget.leadingIcon, color: widget.accent, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Text(
                                  '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF08112F),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isAm ? 'AM' : 'PM',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: widget.accent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
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
                const SizedBox(width: 10),
                Container(
                  width: 102,
                  height: 52,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDE6F1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isAm = true),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isAm ? widget.accent : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'AM',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: _isAm
                                    ? Colors.white
                                    : const Color(0xFF556987),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isAm = false),
                          child: Container(
                            decoration: BoxDecoration(
                              color: !_isAm ? widget.accent : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'PM',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: !_isAm
                                    ? Colors.white
                                    : const Color(0xFF556987),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _AuditTimeWheelField(
                    title: 'HOUR',
                    controller: _hourController,
                    values: List<String>.generate(
                      12,
                      (index) => (index + 1).toString().padLeft(2, '0'),
                    ),
                    onSelected: (index) {
                      setState(() => _selectedHour = index + 1);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 78, 10, 0),
                  child: Text(
                    ':',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF08112F),
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: _AuditTimeWheelField(
                    title: 'MINUTE',
                    controller: _minuteController,
                    values: List<String>.generate(
                      60,
                      (index) => index.toString().padLeft(2, '0'),
                    ),
                    onSelected: (index) {
                      setState(() => _selectedMinute = index);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFDDE6F1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF08112F),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_buildResult()),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: widget.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

class _AuditTimeModalCard extends StatelessWidget {
  const _AuditTimeModalCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x240A1A36),
            blurRadius: 32,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AuditTimeModalHeader extends StatelessWidget {
  const _AuditTimeModalHeader({
    required this.title,
    required this.onClose,
  });

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFE4E8EF),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const SizedBox(width: 52),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF08112F),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            GestureDetector(
              onTap: onClose,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE7EDF6)),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF08112F),
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AuditTimeWheelField extends StatelessWidget {
  const _AuditTimeWheelField({
    required this.title,
    required this.controller,
    required this.values,
    required this.onSelected,
  });

  final String title;
  final FixedExtentScrollController controller;
  final List<String> values;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF556987),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 214,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFDDE6F1)),
          ),
          child: CupertinoPicker(
            scrollController: controller,
            itemExtent: 40,
            squeeze: 1.1,
            selectionOverlay: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0x664F79C8),
                border: Border.all(color: const Color(0xFFBFD0EA)),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onSelectedItemChanged: onSelected,
            children: values
                .map(
                  (value) => Center(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF08112F),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _ReviewMetricCard extends StatelessWidget {
  const _ReviewMetricCard({
    required this.value,
    required this.label,
    this.valueColor = AppColors.brandBlue,
    this.trailingIcon,
    this.trailingColor,
  });

  final String value;
  final String label;
  final Color valueColor;
  final IconData? trailingIcon;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    return _ModuleSurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTypography.card(
                  fontSize: 18.5,
                  color: valueColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 2),
                Icon(
                  trailingIcon,
                  size: 18,
                  color: trailingColor ?? valueColor,
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.label(
              fontSize: 11.1,
              color: const Color(0xFF707B8D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewGaugeCard extends StatelessWidget {
  const _ReviewGaugeCard({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return _ModuleSurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: value / 100,
                  strokeWidth: 5,
                  backgroundColor: const Color(0xFFE7EEF7),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryDark,
                  ),
                ),
                Text(
                  '$value%',
                  style: AppTypography.label(
                    fontSize: 12,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'RESPONDED',
            textAlign: TextAlign.center,
            style: AppTypography.label(
              fontSize: 11.1,
              color: const Color(0xFF707B8D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewAuditRow extends StatelessWidget {
  const _ReviewAuditRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body(
                  fontSize: 13.2,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.body(
                  fontSize: 12,
                  color: const Color(0xFF596372),
                  height: 1.34,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentReviewCard extends StatelessWidget {
  const _RecentReviewCard({required this.review, required this.accent});

  final BusinessReview review;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final replyText = review.hasOwnerReply
        ? review.ownerReply
        : review.suggestedReply;

    return _ModuleSurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: AppTypography.card(
                    fontSize: 16.2,
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF9F0),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.reply_rounded,
                      size: 12,
                      color: Color(0xFF3AAE67),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Replied',
                      style: AppTypography.label(
                        fontSize: 11,
                        color: const Color(0xFF3AAE67),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '★★★★★'.substring(0, review.rating),
                style: AppTypography.body(
                  fontSize: 14,
                  color: const Color(0xFFFFB21E),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _reviewAgeLabel(review.reviewDateLabel),
                style: AppTypography.label(
                  fontSize: 11.4,
                  color: const Color(0xFF7A8698),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '"${review.comment}"',
            style: AppTypography.body(
              fontSize: 13,
              color: AppColors.text,
              height: 1.42,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFF),
              borderRadius: BorderRadius.circular(10),
              border: Border(left: BorderSide(color: accent, width: 2.5)),
            ),
            child: Text(
              'Your reply: $replyText',
              style: AppTypography.body(
                fontSize: 12.3,
                color: const Color(0xFF596372),
                height: 1.38,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditPhotoPreviewTile extends StatelessWidget {
  const _AuditPhotoPreviewTile({required this.item});

  final _AuditPhotoPreview item;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: item.isLocal
            ? Image.file(
                File(item.path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _photoFallbackTile();
                },
              )
            : Image.asset(
                item.path,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _photoFallbackTile();
                },
              ),
      ),
    );
  }

  Widget _photoFallbackTile() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F8FB), Color(0xFFDCEAF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: AppColors.primaryDark),
    );
  }
}

class _AuditStatColumn extends StatelessWidget {
  const _AuditStatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: AppTypography.label(
              fontSize: 10.5,
              color: const Color(0xFF8C97A8),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppTypography.card(
              fontSize: 20,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileAuditItem extends StatelessWidget {
  const _ProfileAuditItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body(
                  fontSize: 13.6,
                  color: const Color(0xFF404856),
                  height: 1.42,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF7DACE6)),
                ),
                child: Text(
                  value,
                  style: AppTypography.body(
                    fontSize: 13.2,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileAuditWarning extends StatelessWidget {
  const _ProfileAuditWarning({required this.title, required this.note});

  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          size: 22,
          color: Color(0xFFF3A011),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body(
                  fontSize: 13.6,
                  color: const Color(0xFF404856),
                  height: 1.42,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5FF),
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(
                    left: BorderSide(color: Color(0xFF8A57E2), width: 3),
                  ),
                ),
                child: Text(
                  note,
                  style: AppTypography.body(
                    fontSize: 13,
                    color: const Color(0xFF7B58D1),
                    height: 1.38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NextActionCard extends StatelessWidget {
  const _NextActionCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F0FF),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFF8A57E2), width: 3),
        ),
      ),
      child: Text(
        text,
        style: AppTypography.body(
          fontSize: 13.2,
          color: const Color(0xFF6D53A8),
          height: 1.38,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AuditPhotoPreview {
  const _AuditPhotoPreview({required this.path, required this.isLocal});

  final String path;
  final bool isLocal;
}

class _BusinessHoursEntry {
  const _BusinessHoursEntry({
    required this.day,
    required this.opensAt,
    required this.closesAt,
    this.isClosed = false,
  });

  final String day;
  final String opensAt;
  final String closesAt;
  final bool isClosed;

  _BusinessHoursEntry copyWith({
    String? day,
    String? opensAt,
    String? closesAt,
    bool? isClosed,
  }) {
    return _BusinessHoursEntry(
      day: day ?? this.day,
      opensAt: opensAt ?? this.opensAt,
      closesAt: closesAt ?? this.closesAt,
      isClosed: isClosed ?? this.isClosed,
    );
  }
}

const List<String> _auditHoursDayOrder = <String>[
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY',
];

const Map<String, String> _auditHoursDayLabels = <String, String>{
  'MONDAY': 'Monday',
  'TUESDAY': 'Tuesday',
  'WEDNESDAY': 'Wednesday',
  'THURSDAY': 'Thursday',
  'FRIDAY': 'Friday',
  'SATURDAY': 'Saturday',
  'SUNDAY': 'Sunday',
};

List<_BusinessHoursEntry> _entriesFromRegularHours(CitationRegularHours? hours) {
  final schedule = <String, ({bool closed, String open, String close})>{
    for (final day in _auditHoursDayOrder)
      day: (closed: true, open: '09:00', close: '18:00'),
  };

  for (final period in hours?.periods ?? const <CitationRegularHourPeriod>[]) {
    final day = period.openDay.trim().toUpperCase();
    if (!schedule.containsKey(day)) {
      continue;
    }
    schedule[day] = (
      closed: false,
      open: _formatHourTime24(period.openTime?.hours, period.openTime?.minutes),
      close: _formatHourTime24(
        period.closeTime?.hours,
        period.closeTime?.minutes,
      ),
    );
  }

  return _auditHoursDayOrder
      .map(
        (day) => _BusinessHoursEntry(
          day: _auditHoursDayLabels[day] ?? day,
          opensAt: schedule[day]!.open,
          closesAt: schedule[day]!.close,
          isClosed: schedule[day]!.closed,
        ),
      )
      .toList(growable: false);
}

Map<String, dynamic> _buildAuditRegularHoursPayload(
  List<_BusinessHoursEntry> entries,
) {
  return <String, dynamic>{
    'periods': entries
        .where((entry) => !entry.isClosed)
        .map((entry) {
          final dayKey = _dayKeyForLabel(entry.day);
          final open = entry.opensAt.split(':').map(int.parse).toList();
          final close = entry.closesAt.split(':').map(int.parse).toList();
          return <String, dynamic>{
            'openDay': dayKey,
            'openTime': <String, dynamic>{
              'hours': open[0],
              'minutes': open[1],
            },
            'closeDay': dayKey,
            'closeTime': <String, dynamic>{
              'hours': close[0],
              'minutes': close[1],
            },
          };
        })
        .toList(growable: false),
  };
}

String _dayKeyForLabel(String label) {
  return _auditHoursDayLabels.entries
      .firstWhere(
        (entry) => entry.value.toLowerCase() == label.toLowerCase(),
        orElse: () => const MapEntry('MONDAY', 'Monday'),
      )
      .key;
}

String _formatHourTime24(int? hours, int? minutes) {
  final h = (hours ?? 0).toString().padLeft(2, '0');
  final m = (minutes ?? 0).toString().padLeft(2, '0');
  return '$h:$m';
}

String _displayAuditHour(String value) {
  final parts = value.split(':');
  if (parts.length != 2) {
    return value;
  }
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  final period = hour >= 12 ? 'PM' : 'AM';
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
}

TimeOfDay _parseTimeOfDay24(String value) {
  final parts = value.split(':');
  if (parts.length != 2) {
    return const TimeOfDay(hour: 10, minute: 30);
  }
  return TimeOfDay(
    hour: int.tryParse(parts[0]) ?? 10,
    minute: int.tryParse(parts[1]) ?? 30,
  );
}

String _formatTimeOfDay24(TimeOfDay value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _effectiveBusinessName(TestAccount user, CitationNapInfo? napInfo) {
  final candidate = napInfo?.businessName.trim() ?? '';
  return candidate.isNotEmpty ? candidate : _businessName(user);
}

String _effectiveAddress(TestAccount user, CitationNapInfo? napInfo) {
  final candidate = napInfo?.address.trim() ?? '';
  return candidate.isNotEmpty ? candidate : _businessAddress(user);
}

String _effectivePhone(TestAccount user, CitationNapInfo? napInfo) {
  final candidate = napInfo?.phone.trim() ?? '';
  if (candidate.isNotEmpty) {
    return candidate;
  }
  final fallback = user.phoneNumber.trim();
  return fallback.isNotEmpty ? fallback : '+91 98765 43210';
}

String _effectiveWebsite(TestAccount user, CitationNapInfo? napInfo) {
  final candidate = napInfo?.website.trim() ?? '';
  return candidate.isNotEmpty ? candidate : _businessWebsiteUrl(user);
}

List<_AuditPhotoPreview> _buildAuditPhotoPreviewItems({
  required List<String> uploadedPhotos,
  required String activePhotoPath,
}) {
  final items = <_AuditPhotoPreview>[
    for (final path in uploadedPhotos)
      _AuditPhotoPreview(path: path, isLocal: true),
  ];

  final fallbackAssets = [
    if (activePhotoPath.isEmpty) 'assets/images/office.png',
    'assets/images/site.png',
    'assets/images/mall.png',
    'assets/images/coffee.png',
  ];

  for (final path in fallbackAssets) {
    if (items.length >= 3) {
      break;
    }
    items.add(_AuditPhotoPreview(path: path, isLocal: false));
  }
  return items;
}


String _businessAddress(TestAccount user) {
  if (user.streetAddress.trim().isNotEmpty) {
    return user.streetAddress.trim();
  }
  final parts = <String>[
    if (user.city.trim().isNotEmpty) user.city.trim(),
    if (user.country.trim().isNotEmpty) user.country.trim(),
  ];
  if (parts.isEmpty) {
    return 'Andheri-Kurla Road, Mumbai, Maharashtra, 400072';
  }
  return parts.join(', ');
}

String _businessWebsiteUrl(TestAccount user) {
  final raw = _businessName(
    user,
  ).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  final slug = raw.isEmpty ? 'visibloai' : raw;
  return 'https://www.$slug.com/';
}

String _businessName(TestAccount user) {
  final businessName = user.businessName.trim();
  if (businessName.isNotEmpty) {
    return businessName;
  }
  final fullName = user.fullName.trim();
  if (fullName.isNotEmpty) {
    return fullName;
  }
  return 'Your Business';
}



List<String> _categorySuggestionLabels(TestAccount user) {
  final category = _businessCategory(user).toLowerCase();
  if (category.contains('estate') || category.contains('property')) {
    return const [
      'Estate agent',
      'Real estate agency',
      'Property management',
      'Property services',
      'Real estate services',
      'Real estate agent',
      'Residential property management',
      'Commercial property management',
      'Property consultants',
      'Real estate consultants',
    ];
  }

  final businessCategory = _businessCategory(user);
  return [
    businessCategory,
    '$businessCategory services',
    '$businessCategory consultant',
    '${user.city.trim().isEmpty ? 'Local' : user.city.trim()} $businessCategory',
    'Professional $businessCategory',
    '$businessCategory specialists',
  ];
}

String _businessCategory(TestAccount user) {
  final category = user.categoryTitle.trim();
  if (category.isNotEmpty) {
    return category;
  }
  final industry = user.industry.trim();
  if (industry.isNotEmpty) {
    return industry;
  }
  return 'Business Category';
}

String _reviewAgeLabel(String reviewDateLabel) {
  final parts = reviewDateLabel.split('/');
  if (parts.length != 3) {
    return reviewDateLabel;
  }

  final month = int.tryParse(parts[0]);
  final day = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (month == null || day == null || year == null) {
    return reviewDateLabel;
  }

  final reviewDate = DateTime(year, month, day);
  final now = DateTime.now();
  final totalMonths =
      (now.year - reviewDate.year) * 12 + now.month - reviewDate.month;
  if (totalMonths > 0) {
    return '$totalMonths mo ago';
  }

  final totalDays = now.difference(reviewDate).inDays;
  if (totalDays >= 7) {
    return '${totalDays ~/ 7} wk ago';
  }
  if (totalDays > 0) {
    return '$totalDays d ago';
  }
  return 'Today';
}

void _showModuleSnack(String title, String message) {
  Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
}

abstract final class _AuditModulePalette {
  static const Color canvas = Color(0xFFF5F7FB);
}

String _timeAgoFromIso(String isoString) {
  if (isoString.isEmpty) return '';
  try {
    final date = DateTime.parse(isoString);
    final diff = DateTime.now().difference(date);
    final days = diff.inDays;
    
    if (days >= 365) return '${days ~/ 365}y ago';
    if (days >= 30) return '${days ~/ 30}mo ago';
    if (days >= 7) return '${days ~/ 7}wk ago';
    if (days > 0) return '${days}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  } catch (_) {
    return '';
  }
}
