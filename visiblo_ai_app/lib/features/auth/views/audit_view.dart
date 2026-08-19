import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import 'audit_module_detail_views.dart';
import '../models/business_review.dart';
import '../models/test_account.dart';
import '../models/audit_models.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_navigation_shell.dart';

class AuditView extends StatelessWidget {
  const AuditView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthNavigationShell(
      currentTab: AuthTab.audit,
      backgroundColor: _AuditPalette.canvas,
      child: _AuditExperience(),
    );
  }
}

enum _AuditModule {
  name,
  description,
  category,
  hours,
  reviews,
  photos,
  post,
  profileReadiness,
  visibilityActions,
  localRanking,
}

extension _AuditModuleX on _AuditModule {
  String get routeValue {
    return switch (this) {
      _AuditModule.name => 'name',
      _AuditModule.description => 'description',
      _AuditModule.category => 'category',
      _AuditModule.hours => 'hours',
      _AuditModule.reviews => 'reviews',
      _AuditModule.photos => 'photos',
      _AuditModule.post => 'post',
      _AuditModule.profileReadiness => 'profile-readiness',
      _AuditModule.visibilityActions => 'visibility-actions',
      _AuditModule.localRanking => 'local-ranking',
    };
  }

  String get label {
    return switch (this) {
      _AuditModule.name => 'Name',
      _AuditModule.description => 'Description',
      _AuditModule.category => 'Category',
      _AuditModule.hours => 'Hours',
      _AuditModule.reviews => 'Reviews',
      _AuditModule.photos => 'Photos',
      _AuditModule.post => 'POST',
      _AuditModule.profileReadiness => 'Profile readiness',
      _AuditModule.visibilityActions => 'Visibility & Customer Actions',
      _AuditModule.localRanking => 'Local Ranking Coverage',
    };
  }

  IconData get icon {
    return switch (this) {
      _AuditModule.name => Icons.check_circle_outline_rounded,
      _AuditModule.description => Icons.check_circle_outline_rounded,
      _AuditModule.category => Icons.warning_amber_rounded,
      _AuditModule.hours => Icons.check_circle_outline_rounded,
      _AuditModule.reviews => Icons.warning_amber_rounded,
      _AuditModule.photos => Icons.warning_amber_rounded,
      _AuditModule.post => Icons.warning_amber_rounded,
      _AuditModule.profileReadiness => Icons.warning_amber_rounded,
      _AuditModule.visibilityActions => Icons.warning_amber_rounded,
      _AuditModule.localRanking => Icons.cancel_outlined,
    };
  }

  Color get accent {
    return switch (this) {
      _AuditModule.name => AppColors.primaryDark,
      _AuditModule.description => AppColors.primaryDark,
      _AuditModule.category => const Color(0xFFF0B640),
      _AuditModule.hours => AppColors.primaryDark,
      _AuditModule.reviews => const Color(0xFFFF8E4B),
      _AuditModule.photos => const Color(0xFFF0B640),
      _AuditModule.post => const Color(0xFFF0B640),
      _AuditModule.profileReadiness => const Color(0xFFF0B640),
      _AuditModule.visibilityActions => const Color(0xFFB8764F),
      _AuditModule.localRanking => const Color(0xFFFF5D5D),
    };
  }

  Color get softAccent => accent.withValues(alpha: 0.12);

  int get score {
    return switch (this) {
      _AuditModule.name => 87,
      _AuditModule.description => 85,
      _AuditModule.category => 76,
      _AuditModule.hours => 82,
      _AuditModule.reviews => 91,
      _AuditModule.photos => 55,
      _AuditModule.post => 30,
      _AuditModule.profileReadiness => 80,
      _AuditModule.visibilityActions => 68,
      _AuditModule.localRanking => 30,
    };
  }

  String get signalLabel {
    return switch (this) {
      _AuditModule.name => 'NAME SIGNAL',
      _AuditModule.description => 'DESCRIPTION SIGNAL',
      _AuditModule.category => 'CATEGORY SIGNAL',
      _AuditModule.hours => 'HOURS SIGNAL',
      _AuditModule.reviews => 'REVIEW SIGNAL',
      _AuditModule.photos => 'PHOTO SIGNAL',
      _AuditModule.post => 'POST SIGNAL',
      _AuditModule.profileReadiness => 'PROFILE SIGNAL',
      _AuditModule.visibilityActions => 'VISIBILITY SIGNAL',
      _AuditModule.localRanking => 'RANKING SIGNAL',
    };
  }

  String get panelTitle {
    return switch (this) {
      _AuditModule.name => 'Business description engine',
      _AuditModule.description => 'Business description engine',
      _AuditModule.category => 'Category precision engine',
      _AuditModule.hours => 'Business hours engine',
      _AuditModule.reviews => 'Review trust engine',
      _AuditModule.photos => 'Photo coverage engine',
      _AuditModule.post => 'Google post momentum engine',
      _AuditModule.profileReadiness => 'Profile readiness engine',
      _AuditModule.visibilityActions =>
        'Visibility and customer actions engine',
      _AuditModule.localRanking => 'Local ranking coverage engine',
    };
  }

  String get supportingText {
    return switch (this) {
      _AuditModule.name =>
        'Keep the real business name clear, then carefully add only useful local and category terms that help Google understand relevance.',
      _AuditModule.description =>
        'Keep the business description helpful, local, and clear so Google understands what the business does and where it is relevant.',
      _AuditModule.category =>
        'Keep the primary category sharp, align it with buyer intent, and use related service angles only where they strengthen relevance.',
      _AuditModule.hours =>
        'Make opening hours complete and believable so customers know when to call, visit, or ask for directions.',
      _AuditModule.reviews =>
        'Review freshness and replies support trust. Keep the conversation active so the profile looks cared for every week.',
      _AuditModule.photos =>
        'Fresh photos keep the profile active. Rotate real business visuals so the listing feels current and credible.',
      _AuditModule.post =>
        'Post consistency signals business activity. Regular updates help Google and customers trust the profile is current.',
      _AuditModule.profileReadiness =>
        'Connected phone, address, website, and synced GBP data make the profile easier to trust and easier to rank.',
      _AuditModule.visibilityActions =>
        'Insights data helps quantify customer actions like calls, directions, and website clicks. Without sync, performance is still pending.',
      _AuditModule.localRanking =>
        'Keyword tracking reveals whether the profile appears for buying-intent searches in the right places.',
    };
  }

  String get primaryButtonLabel {
    return switch (this) {
      _AuditModule.name => 'Update on Google Maps',
      _AuditModule.description => 'Update on Google Maps',
      _AuditModule.category => 'View Category Details',
      _AuditModule.hours => 'View Hours Details',
      _AuditModule.reviews => 'View Review Health',
      _AuditModule.photos => 'Manage Photos',
      _AuditModule.post => 'Open Posts',
      _AuditModule.profileReadiness => 'Open GBP Manager',
      _AuditModule.visibilityActions => 'Open Reports',
      _AuditModule.localRanking => 'Open Keyword Ranking',
    };
  }

  bool get isHealthy {
    return switch (this) {
      _AuditModule.name => true,
      _AuditModule.description => true,
      _AuditModule.hours => true,
      _AuditModule.category ||
      _AuditModule.reviews ||
      _AuditModule.photos ||
      _AuditModule.post ||
      _AuditModule.profileReadiness ||
      _AuditModule.visibilityActions ||
      _AuditModule.localRanking => false,
    };
  }
}

enum _AuditTab { health, profile }

class _AuditExperience extends StatefulWidget {
  const _AuditExperience();

  @override
  State<_AuditExperience> createState() => _AuditExperienceState();
}

class _AuditExperienceState extends State<_AuditExperience> {
  final OnboardingController controller = Get.find<OnboardingController>();
  late _AuditModule _selectedModule;
  late _AuditTab _currentTab;
  String? _generatedDescription;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _selectedModule = _moduleFromRouteValue(args['module']);
      if (args['tab'] == 'profile') {
        _currentTab = _AuditTab.profile;
      } else {
        _currentTab = _AuditTab.health;
      }
    } else {
      _selectedModule = _moduleFromRouteValue(args);
      _currentTab = _AuditTab.health;
    }
  }

  void _selectModule(_AuditModule module) {
    if (_selectedModule == module) {
      return;
    }
    setState(() => _selectedModule = module);
  }

  void _handlePrimaryAction() {
    switch (_selectedModule) {
      case _AuditModule.category:
        Get.toNamed(AppRoutes.auditCategory);
        return;
      case _AuditModule.hours:
        Get.toNamed(AppRoutes.auditHours);
        return;
      case _AuditModule.reviews:
        Get.toNamed(AppRoutes.auditReviews);
        return;
      case _AuditModule.photos:
        Get.toNamed(AppRoutes.gbpPhotos);
        return;
      case _AuditModule.post:
        Get.toNamed(AppRoutes.gbpPosts);
        return;
      case _AuditModule.profileReadiness:
        Get.toNamed(AppRoutes.gbpManager);
        return;
      case _AuditModule.visibilityActions:
        Get.toNamed(AppRoutes.reports);
        return;
      case _AuditModule.localRanking:
        Get.toNamed(AppRoutes.keywordRanking);
        return;
      default:
        Get.snackbar(
          _selectedModule.primaryButtonLabel,
          'This audit module is ready for the next sync step.',
          snackPosition: SnackPosition.BOTTOM,
        );
    }
  }

  void _handleGenerateDescription(TestAccount user, AuditResult audit) {
    final generated = _buildAuditAiDescription(
      user: user,
      audit: audit,
      keywords: _keywordChipsFor(_AuditModule.description, user),
    );

    setState(() {
      _generatedDescription = generated;
      _selectedModule = _AuditModule.description;
      _currentTab = _AuditTab.profile;
    });

    Get.snackbar(
      'Description updated',
      'A fresh business description was generated from your audit signals.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _openFullAuditReport(AuditResult audit) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AuditFullReportSheet(audit: audit),
    );
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

      final uploadedPhotos = controller.businessPhotoGalleryFor(user);
      final businessReviews = controller.businessReviewsFor(user);
      final currentPhotoPath = user.businessPhotoPath.trim();
      final activePhotoPath =
          currentPhotoPath.isNotEmpty &&
              uploadedPhotos.contains(currentPhotoPath)
          ? currentPhotoPath
          : (uploadedPhotos.isNotEmpty ? uploadedPhotos.first : '');

      final audit = controller.liveAudit.value;
      if (controller.isLoadingAudit.value || audit == null) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: AuthViewSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AuthShellBackButton(),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F6FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _currentTab = _AuditTab.health),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _currentTab == _AuditTab.health ? AppColors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _currentTab == _AuditTab.health ? const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ] : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Audit Health',
                                style: AppTypography.label(
                                  fontSize: 13,
                                  fontWeight: _currentTab == _AuditTab.health ? FontWeight.w800 : FontWeight.w600,
                                  color: _currentTab == _AuditTab.health ? AppColors.brandBlue : const Color(0xFF7A8492),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _currentTab = _AuditTab.profile),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _currentTab == _AuditTab.profile ? AppColors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _currentTab == _AuditTab.profile ? const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ] : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Audit Profile',
                                style: AppTypography.label(
                                  fontSize: 13,
                                  fontWeight: _currentTab == _AuditTab.profile ? FontWeight.w800 : FontWeight.w600,
                                  color: _currentTab == _AuditTab.profile ? AppColors.brandBlue : const Color(0xFF7A8492),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_currentTab == _AuditTab.health) ...[
              _AuditHeroCard(
                audit: audit,
                onViewFullReport: () => _openFullAuditReport(audit),
              ),
              const SizedBox(height: AuthViewSpacing.cardGap),
              _AuditMetricsGrid(audit: audit),
              const SizedBox(height: AuthViewSpacing.cardGap),
              _AuditVerdictPlanCard(audit: audit),
            ] else if (_currentTab == _AuditTab.profile) ...[
              _AuditWorkbenchCard(
                user: user,
                audit: audit,
                selectedModule: _selectedModule,
                uploadedPhotos: uploadedPhotos,
                businessReviews: businessReviews,
                activePhotoPath: activePhotoPath,
                onModuleSelected: _selectModule,
                onPrimaryAction: _handlePrimaryAction,
                generatedDescription: _generatedDescription,
                onGenerateDescription: () =>
                    _handleGenerateDescription(user, audit),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _AuditHeroCard extends StatelessWidget {
  const _AuditHeroCard({
    required this.audit,
    required this.onViewFullReport,
  });

  final AuditResult audit;
  final VoidCallback onViewFullReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EDF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0711324D),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 300;

              final textBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: AppTypography.card(
                        fontSize: 24,
                        color: const Color(0xFF0D253F),
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                      children: const [
                        TextSpan(text: 'Local visibility\n'),
                        TextSpan(
                          text: 'command center',
                          style: TextStyle(color: Color(0xFF2EADC0)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Track, monitor, and improve your local AI visibility.',
                    style: AppTypography.body(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: 138,
                    height: 1.2,
                    color: const Color(0xFFE6ECF3),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'AI Visibility Score',
                    style: AppTypography.label(
                      fontSize: 15.6,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFF19B26B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          style: AppTypography.label(
                            fontSize: 13.2,
                            color: AppColors.mutedText,
                            fontWeight: FontWeight.w700,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Good',
                              style: TextStyle(
                                color: AppColors.brandBlue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(text: ' · Improving'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );

              final scoreBlock = Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _ScoreRing(score: audit.overallScore),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stacked) ...[
                    textBlock,
                    const SizedBox(height: 16),
                    Center(child: scoreBlock),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: textBlock),
                        const SizedBox(width: 16),
                        scoreBlock,
                      ],
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 220,
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: onViewFullReport,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0A3F85),
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(
                        Icons.bar_chart_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        'View full report',
                        style: AppTypography.button(
                          fontSize: 14.2,
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 36),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: score / 100),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          return SizedBox(
            width: 118,
            height: 118,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 118,
                  height: 118,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: const Color(0xFFE9EDF3),
                    color: const Color(0xFF1EA362),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: GoogleFonts.manrope(
                        fontSize: 37,
                        color: const Color(0xFF0D253F),
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    Text(
                      '/100',
                      style: AppTypography.label(
                        fontSize: 12.2,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AuditMetricsGrid extends StatelessWidget {
  const _AuditMetricsGrid({required this.audit});

  final AuditResult audit;

  @override
  Widget build(BuildContext context) {
    final metricsData = audit.summary?.metrics;
    
    final metrics = [
      (
        background: AppColors.white,
        borderColor: const Color(0xFFAED5FF),
        label: 'Pages Optimized',
        value: '4', // In a full implementation, you might map this from another field
        change: '+2 since last 7 days',
        valueColor: const Color(0xFF3F84DA),
        changeColor: const Color(0xFF24B35A),
        accent: const Color(0xFF3F84DA),
        iconBackground: const Color(0xFFEFF6FF),
        icon: Icons.insert_drive_file_outlined,
      ),
      (
        background: AppColors.white,
        borderColor: const Color(0xFFE4C1F4),
        label: 'Mentions Found',
        value: '${metricsData?.activeCitations ?? 0}',
        change: 'Directory trust',
        valueColor: const Color(0xFFAA57CC),
        changeColor: const Color(0xFF718099),
        accent: const Color(0xFFC056D9),
        iconBackground: const Color(0xFFFFF0FF),
        icon: Icons.bubble_chart_outlined,
      ),
      (
        background: AppColors.white,
        borderColor: const Color(0xFFFFBBB4),
        label: 'Issues Found',
        value: '${audit.sections.where((s) => s.status == 'fail').length}',
        change: 'Needs attention',
        valueColor: const Color(0xFFFF6B1A),
        changeColor: const Color(0xFF718099),
        accent: const Color(0xFFFF5A5A),
        iconBackground: const Color(0xFFFFF2F1),
        icon: Icons.shield_outlined,
      ),
      (
        background: AppColors.white,
        borderColor: const Color(0xFFF5D2D7),
        label: 'Competitors Tracked',
        value: '3',
        change: 'Active tracking',
        valueColor: const Color(0xFF19A9C8),
        changeColor: const Color(0xFF718099),
        accent: const Color(0xFFD35987),
        iconBackground: const Color(0xFFFFF2F5),
        icon: Icons.groups_2_outlined,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 16,
        mainAxisExtent: 148,
      ),
      itemBuilder: (context, index) {
        return _MetricCard(data: metrics[index]);
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final ({
    Color accent,
    Color background,
    Color borderColor,
    String change,
    Color changeColor,
    IconData icon,
    Color iconBackground,
    String label,
    String value,
    Color valueColor,
  })
  data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: data.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: data.borderColor.withValues(alpha: 0.42)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x070F2746),
            blurRadius: 12,
            offset: Offset(0, 4),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: data.iconBackground,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(data.icon, size: 18, color: data.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.label,
                  style: AppTypography.body(
                    fontSize: 15,
                    color: const Color(0xFF203250),
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            data.value,
            style: GoogleFonts.manrope(
              fontSize: 38,
              color: data.valueColor,
              fontWeight: FontWeight.w700,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.change,
            style: AppTypography.body(
              fontSize: 12.6,
              color: data.changeColor,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditVerdictPlanCard extends StatelessWidget {
  const _AuditVerdictPlanCard({required this.audit});

  final AuditResult audit;

  @override
  Widget build(BuildContext context) {
    final summary = audit.summary;
    final metrics = summary?.metrics;
    
    final snapshots = [
      ('${metrics?.profileViews30d ?? 0}', 'PROFILE VIEWS', 'last 30 days', '1'),
      ('${metrics?.customerActions30d ?? 0}', 'CUSTOMER ACTIONS', 'calls, directions, website', '2'),
      ('${metrics?.actionRate?.toStringAsFixed(0) ?? 0}%', 'ACTION RATE', 'views to action', '3'),
      ('${metrics?.averageRating?.toStringAsFixed(1) ?? '5.0'}/5', 'REVIEW TRUST', '${metrics?.reviewCount ?? 0} reviews', '4'),
      ('${metrics?.top3Keywords ?? 0}', 'TOP-3 KEYWORDS', 'Maps pack wins', '5'),
      ('${metrics?.activeCitations ?? 0}', 'ACTIVE CITATIONS', 'directory trust', '6'),
    ];
    
    final steps = summary?.nextBestActions ?? [
      '18 reviews aim for 50+ for strong local ranking',
      'Sync Google Business Profile insights, then refresh the audit to calculate real views, calls, directions, and website clicks.',
      'Add 5-10 buying-intent keywords like "category near me" and "category in city".',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EDF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0711324D),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 5),
                Text(
                  'AUDIT VERDICT',
                  style: AppTypography.label(
                    fontSize: 11.4,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            summary?.verdict ?? 'Good foundation, but growth is leaking in a few areas',
            style: AppTypography.card(
              fontSize: 29,
              color: AppColors.text,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Built from connected GBP signals, reviews, posts, rankings and citation data where available.',
            style: AppTypography.body(
              fontSize: 13.2,
              color: AppColors.mutedText,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _VerdictInfoChip(
                  label: 'CONFIDENCE',
                  value: summary?.confidence ?? 'Medium',
                  background: const Color(0xFFF4F8FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _VerdictInfoChip(
                  label: 'AUDIT MODULES',
                  value: '${audit.sections.length}',
                  background: const Color(0xFFF4EFFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InsightStrip(
            accent: const Color(0xFFE9447A),
            label: 'STRONGEST SIGNAL',
            value: summary?.strongestSignal ?? 'Description: 100/100',
          ),
          const SizedBox(height: 8),
          _InsightStrip(
            accent: const Color(0xFFFF7A26),
            label: 'BIGGEST GROWTH LEAK',
            value: summary?.biggestLeak ?? 'Citation Trust: 25/100',
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshots.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 14,
              mainAxisExtent: 168,
            ),
            itemBuilder: (context, index) {
              final item = snapshots[index];
              return _SnapshotCard(
                value: item.$1,
                label: item.$2,
                subtitle: item.$3,
                badge: item.$4,
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                size: 15,
                color: AppColors.mutedText,
              ),
              const SizedBox(width: 6),
              Text(
                'PRIORITY ACTION PLAN',
                style: AppTypography.label(
                  fontSize: 11.8,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Next 7 days',
                  style: AppTypography.label(
                    fontSize: 10.8,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(steps.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == steps.length - 1 ? 0 : 8,
              ),
              child: _PriorityStepCard(index: index + 1, text: steps[index]),
            );
          }),
        ],
      ),
    );
  }
}

class _VerdictInfoChip extends StatelessWidget {
  const _VerdictInfoChip({
    required this.label,
    required this.value,
    required this.background,
  });

  final String label;
  final String value;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1E9F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.label(
              fontSize: 11,
              color: AppColors.mutedText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.card(
              fontSize: 17,
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightStrip extends StatelessWidget {
  const _InsightStrip({
    required this.accent,
    required this.label,
    required this.value,
  });

  final Color accent;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EDF3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.label(
                    fontSize: 11,
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: AppTypography.body(
                    fontSize: 14.4,
                    color: AppColors.brandBlue,
                    height: 1.32,
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

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.badge,
  });

  final String value;
  final String label;
  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9EDF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0511324D),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF3F84DA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 16, 16),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: AppTypography.card(
                          fontSize: 30,
                          color: const Color(0xFF424347),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label(
                                fontSize: 11.8,
                                color: const Color(0xFF4E4F53),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.32,
                                height: 1.12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body(
                                fontSize: 12.2,
                                color: const Color(0xFF76777A),
                                height: 1.26,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F7FF),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badge,
                        style: AppTypography.label(
                          fontSize: 10.2,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
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

class _PriorityStepCard extends StatelessWidget {
  const _PriorityStepCard({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EDF3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1E8),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: AppTypography.label(
                fontSize: 10.2,
                color: const Color(0xFFFF7A26),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body(
                fontSize: 13.2,
                color: AppColors.text,
                height: 1.42,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditWorkbenchCard extends StatelessWidget {
  const _AuditWorkbenchCard({
    required this.user,
    required this.audit,
    required this.selectedModule,
    required this.uploadedPhotos,
    required this.businessReviews,
    required this.activePhotoPath,
    required this.onModuleSelected,
    required this.onPrimaryAction,
    required this.generatedDescription,
    required this.onGenerateDescription,
  });

  final TestAccount user;
  final AuditResult audit;
  final _AuditModule selectedModule;
  final List<String> uploadedPhotos;
  final List<BusinessReview> businessReviews;
  final String activePhotoPath;
  final ValueChanged<_AuditModule> onModuleSelected;
  final VoidCallback onPrimaryAction;
  final String? generatedDescription;
  final VoidCallback onGenerateDescription;

  @override
  Widget build(BuildContext context) {
    const moduleChipGap = 8.0;
    final selectedSection = _getSectionForModule(audit, selectedModule);
    
    final moduleChecks = selectedSection != null && selectedSection.findings.isNotEmpty
        ? selectedSection.findings.map((f) {
            final isPass = f.status == 'pass';
            final isFail = f.status == 'fail';
            return _AuditCheckItem(
              icon: isPass ? Icons.check_circle_outline_rounded : (isFail ? Icons.cancel_outlined : Icons.warning_amber_rounded),
              text: f.detail.isNotEmpty ? f.detail : f.label,
              color: isPass ? const Color(0xFF80B63B) : (isFail ? const Color(0xFFFF5D5D) : const Color(0xFFF0B640)),
            );
          }).toList()
        : _buildChecks(
            selectedModule,
            user,
            uploadedPhotos.length,
            activePhotoPath,
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EDF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0711324D),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OPTIMIZATION MODULES',
            style: AppTypography.label(
              fontSize: 11.4,
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fix the profile step by step',
            style: AppTypography.card(
              fontSize: 27,
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Each audit module is shown one by one so a business owner can review, understand, and act without getting lost.',
            style: AppTypography.body(
              fontSize: 13.2,
              color: AppColors.mutedText,
              height: 1.42,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${_businessName(user)} agents in ${_businessLocation(user)}',
              style: AppTypography.label(
                fontSize: 11.3,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _AuditModule.values.length,
              separatorBuilder: (_, index) =>
                  const SizedBox(width: moduleChipGap),
              itemBuilder: (context, index) {
                final module = _AuditModule.values[index];
                final section = _getSectionForModule(audit, module);
                return _ModuleChip(
                  module: module,
                  section: section,
                  isSelected: module == selectedModule,
                  onTap: () => onModuleSelected(module),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _ModulePanel(
            module: selectedModule,
            section: selectedSection,
            user: user,
            uploadedPhotos: uploadedPhotos,
            businessReviews: businessReviews,
            activePhotoPath: activePhotoPath,
            moduleChecks: moduleChecks,
            onPrimaryAction: onPrimaryAction,
            generatedDescription: generatedDescription,
            onGenerateDescription: onGenerateDescription,
          ),
        ],
      ),
    );
  }
}

class _ModuleChip extends StatelessWidget {
  const _ModuleChip({
    required this.module,
    required this.section,
    required this.isSelected,
    required this.onTap,
  });

  final _AuditModule module;
  final AuditSection? section;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.primary
        : const Color(0xFFD3DAE3);
    final textColor = isSelected
        ? AppColors.primaryDark
        : const Color(0xFF4C5459);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.6 : 1.1,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x1239B4BD),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                (section?.status == 'pass' || module.isHealthy) 
                    ? Icons.check_circle_outline_rounded 
                    : ((section?.status == 'fail' || !module.isHealthy) ? Icons.warning_amber_rounded : module.icon),
                size: 15,
                color: (section?.status == 'pass' || module.isHealthy) ? AppColors.primaryDark : module.accent,
              ),
              const SizedBox(width: 7),
              Text(
                module.label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: AppTypography.label(
                  fontSize: 12.2,
                  height: 1,
                  color: textColor,
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

class _ModulePanel extends StatelessWidget {
  const _ModulePanel({
    required this.module,
    required this.section,
    required this.user,
    required this.uploadedPhotos,
    required this.businessReviews,
    required this.activePhotoPath,
    required this.moduleChecks,
    required this.onPrimaryAction,
    required this.generatedDescription,
    required this.onGenerateDescription,
  });

  final _AuditModule module;
  final AuditSection? section;
  final TestAccount user;
  final List<String> uploadedPhotos;
  final List<BusinessReview> businessReviews;
  final String activePhotoPath;
  final List<_AuditCheckItem> moduleChecks;
  final VoidCallback onPrimaryAction;
  final String? generatedDescription;
  final VoidCallback onGenerateDescription;

  @override
  Widget build(BuildContext context) {
    if (module == _AuditModule.category) {
      return AuditCategoryModuleContent(
        section: section,
        user: user,
        onManageTap: () => Get.toNamed(AppRoutes.auditCategory),
      );
    }

    if (module == _AuditModule.hours) {
      return AuditHoursModuleContent(
        user: user,
        section: section,
      );
    }

    if (module == _AuditModule.reviews) {
      return AuditReviewModuleContent(
        section: section,
        reviews: businessReviews,
        averageRating: Get.find<OnboardingController>()
            .averageBusinessReviewScore(user: user),
        onViewAllTap: () => Get.toNamed(AppRoutes.clientReviews),
        onCreatePosterTap: () => Get.toNamed(AppRoutes.reviewPoster),
      );
    }

    if (module == _AuditModule.photos) {
      return AuditPhotosModuleContent(
        section: section,
        uploadedPhotos: uploadedPhotos,
        activePhotoPath: activePhotoPath,
        onManageTap: () => Get.toNamed(AppRoutes.gbpPhotos),
      );
    }

    if (module == _AuditModule.post) {
      return AuditPostModuleContent(
        section: section,
        user: user,
        onOpenPostsTap: () => Get.toNamed(AppRoutes.gbpPosts),
      );
    }

    if (module == _AuditModule.profileReadiness) {
      return AuditProfileReadinessModuleContent(
        section: section,
        user: user,
        onOpenManagerTap: () => Get.toNamed(AppRoutes.gbpManager),
      );
    }

    if (module == _AuditModule.visibilityActions) {
      return AuditVisibilityActionsModuleContent(
        section: section,
        onOpenReportsTap: () => Get.toNamed(AppRoutes.reports),
      );
    }

    if (module == _AuditModule.localRanking) {
      return AuditLocalRankingModuleContent(
        section: section,
        onOpenRankingTap: () => Get.toNamed(AppRoutes.keywordRanking),
      );
    }

    final previewChips = _keywordChipsFor(module, user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: module.softAccent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: module.accent.withValues(alpha: 0.5)),
              ),
              alignment: Alignment.center,
              child: Text(
                module.label.characters.first,
                style: AppTypography.label(
                  fontSize: 15,
                  color: module.accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: module.accent.withValues(alpha: 0.6)),
              ),
              child: Text(
                '${section?.score ?? module.score}/100',
                style: AppTypography.label(
                  fontSize: 12.4,
                  color: module.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          module.signalLabel,
          style: AppTypography.label(
            fontSize: 11.4,
            color: AppColors.mutedText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          section?.title ?? module.panelTitle,
          style: AppTypography.card(
            fontSize: 21,
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          module.supportingText,
          style: AppTypography.body(
            fontSize: 13.2,
            color: AppColors.mutedText,
            height: 1.44,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        const Divider(color: Color(0xFFE9EDF3), height: 1),
        const SizedBox(height: 14),
        Text(
          'AUDIT CHECKS',
          style: AppTypography.label(
            fontSize: 11.4,
            color: AppColors.mutedText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...moduleChecks.asMap().entries.map((entry) {
          return Column(
            children: [
              _AuditCheckRow(check: entry.value),
              if (entry.key != moduleChecks.length - 1) ...[
                const SizedBox(height: 10),
                const Divider(color: Color(0xFFE9EDF3), height: 1),
                const SizedBox(height: 10),
              ],
            ],
          );
        }),
        const SizedBox(height: 14),
        ..._buildModuleBody(context, previewChips),
      ],
    );
  }

  List<Widget> _buildModuleBody(
    BuildContext context,
    List<_KeywordChipData> previewChips,
  ) {
    if (module == _AuditModule.description) {
      return [
        _SectionHeading(title: _chipsLabelFor(module)),
        const SizedBox(height: 6),
        Text(
          'Use these naturally inside the content. Avoid dumping keywords without context.',
          style: AppTypography.body(
            fontSize: 13.2,
            color: AppColors.mutedText,
            height: 1.42,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: previewChips
              .map((chip) => _SuggestionChip(chip: chip, module: module))
              .toList(),
        ),
        const SizedBox(height: 16),
        const _SectionHeading(title: 'GOOGLE PROFILE CONTENT'),
        const SizedBox(height: 6),
        Text(
          'Edit the business description customers see on Google.',
          style: AppTypography.body(
            fontSize: 13.2,
            color: AppColors.mutedText,
            height: 1.42,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        _ModulePreviewCard(
          module: module,
          user: user,
          uploadedPhotos: uploadedPhotos,
          businessReviews: businessReviews,
          activePhotoPath: activePhotoPath,
          section: section,
          generatedDescription: generatedDescription,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: onGenerateDescription,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.auto_awesome_outlined, size: 18),
            label: Text(
              'Generate with AI',
              style: AppTypography.button(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _PrimaryAuditButton(module: module, onPressed: onPrimaryAction),
      ];
    }

    return [
      _SectionHeading(title: _previewLabelFor(module)),
      const SizedBox(height: 6),
      Text(
        _previewHelperTextFor(module),
        style: AppTypography.body(
          fontSize: 13.2,
          color: AppColors.mutedText,
          height: 1.42,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 10),
      _ModulePreviewCard(
        module: module,
        user: user,
        uploadedPhotos: uploadedPhotos,
        businessReviews: businessReviews,
        activePhotoPath: activePhotoPath,
        section: section,
      ),
      if (previewChips.isNotEmpty) ...[
        const SizedBox(height: 14),
        _SectionHeading(title: _chipsLabelFor(module)),
        const SizedBox(height: 6),
        Text(
          _chipsHelperTextFor(module),
          style: AppTypography.body(
            fontSize: 13.2,
            color: AppColors.mutedText,
            height: 1.42,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: previewChips
              .map((chip) => _SuggestionChip(chip: chip, module: module))
              .toList(),
        ),
      ],
      const SizedBox(height: 16),
      _PrimaryAuditButton(module: module, onPressed: onPrimaryAction),
    ];
  }
}

class _ModulePreviewCard extends StatelessWidget {
  const _ModulePreviewCard({
    required this.module,
    required this.user,
    required this.uploadedPhotos,
    required this.businessReviews,
    required this.activePhotoPath,
    this.section,
    this.generatedDescription,
  });

  final _AuditModule module;
  final TestAccount user;
  final List<String> uploadedPhotos;
  final List<BusinessReview> businessReviews;
  final String activePhotoPath;
  final AuditSection? section;
  final String? generatedDescription;

  @override
  Widget build(BuildContext context) {
    switch (module) {
      case _AuditModule.name:
        final preview = section?.currentValue?.isNotEmpty == true ? section!.currentValue! : _recommendedName(user);
        return _TextPreviewCard(
          title: preview,
          subtitle:
              '${preview.split(RegExp(r'\s+')).length} words, ${preview.characters.length}/120 characters',
        );
      case _AuditModule.description:
        final preview =
            generatedDescription?.trim().isNotEmpty == true
            ? generatedDescription!.trim()
            : section?.currentValue?.isNotEmpty == true
            ? section!.currentValue!
            : _recommendedDescription(user);
        return _TextPreviewCard(
          title: preview,
          subtitle:
              '${preview.split(RegExp(r'\s+')).length} words, ${preview.characters.length}/750 characters',
        );
      case _AuditModule.category:
        return _CategoryPreviewCard(
          primaryCategory: section?.currentValue?.isNotEmpty == true ? section!.currentValue! : _businessCategory(user),
          secondaryCategories: section?.suggestions?.isNotEmpty == true ? section!.suggestions!.take(3).toList() : _categorySuggestions(
            user,
          ).take(3).map((chip) => chip.label).toList(),
        );
      case _AuditModule.hours:
        return const _HoursPreviewCard();
      case _AuditModule.reviews:
        return _ReviewsPreviewCard(reviewCount: section?.meta?['totalCount'] ?? businessReviews.length);
      case _AuditModule.photos:
        return _PhotosPreviewCard(
          uploadedPhotos: uploadedPhotos,
          activePhotoPath: activePhotoPath,
          totalCount: section?.meta?['totalCount'],
        );
      case _AuditModule.post:
        return const _TextPreviewCard(
          title:
              'Recent posting consistency is low and needs a fresh brand update.',
          subtitle: 'Post activity health snapshot',
        );
      case _AuditModule.profileReadiness:
        return const _TextPreviewCard(
          title:
              'Phone, address, and website should stay synced so the listing remains trusted.',
          subtitle: 'Connection health snapshot',
        );
      case _AuditModule.visibilityActions:
        return const _TextPreviewCard(
          title:
              'Insights syncing is still pending, so calls, directions, and website clicks cannot be scored yet.',
          subtitle: 'Visibility signal snapshot',
        );
      case _AuditModule.localRanking:
        return const _TextPreviewCard(
          title:
              'No active keyword groups are being tracked for this business location yet.',
          subtitle: 'Ranking coverage snapshot',
        );
    }
  }
}

class _TextPreviewCard extends StatelessWidget {
  const _TextPreviewCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body(
              fontSize: 14.6,
              color: AppColors.brandBlue,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              subtitle,
              style: AppTypography.label(
                fontSize: 11.6,
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPreviewCard extends StatelessWidget {
  const _CategoryPreviewCard({
    required this.primaryCategory,
    required this.secondaryCategories,
  });

  final String primaryCategory;
  final List<String> secondaryCategories;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CategoryRow(label: 'Primary category', value: primaryCategory),
          const SizedBox(height: 10),
          _CategoryRow(
            label: 'Support categories',
            value: secondaryCategories.join(', '),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label(
            fontSize: 11.4,
            color: AppColors.mutedText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.body(
            fontSize: 14.2,
            color: AppColors.text,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HoursPreviewCard extends StatelessWidget {
  const _HoursPreviewCard();

  @override
  Widget build(BuildContext context) {
    const hours = [
      ('Mon - Fri', '9:00 AM - 7:00 PM'),
      ('Saturday', '10:00 AM - 4:00 PM'),
      ('Sunday', 'Closed'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Column(
        children: hours.map((item) {
          return Padding(
            padding: EdgeInsets.only(bottom: item == hours.last ? 0 : 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.$1,
                    style: AppTypography.body(
                      fontSize: 13.8,
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  item.$2,
                  style: AppTypography.label(
                    fontSize: 12.2,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReviewsPreviewCard extends StatelessWidget {
  const _ReviewsPreviewCard({required this.reviewCount});

  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ReviewMetric(
              label: 'Reviews',
              value: '$reviewCount',
              accent: const Color(0xFFFF9C4A),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: _ReviewMetric(
              label: 'Reply rate',
              value: '100%',
              accent: Color(0xFF2DBA77),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewMetric extends StatelessWidget {
  const _ReviewMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.card(
              fontSize: 24,
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.label(
              fontSize: 11.4,
              color: AppColors.mutedText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotosPreviewCard extends StatelessWidget {
  const _PhotosPreviewCard({
    required this.uploadedPhotos,
    required this.activePhotoPath,
    this.totalCount,
  });

  final List<String> uploadedPhotos;
  final String activePhotoPath;
  final int? totalCount;

  @override
  Widget build(BuildContext context) {
    if (uploadedPhotos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDCE6F2)),
        ),
        child: Text(
          'No gallery photos are uploaded yet. Use the home recommendation card to take a photo or build a reusable upload list.',
          style: AppTypography.body(
            fontSize: 12.4,
            color: AppColors.mutedText,
            height: 1.4,
          ),
        ),
      );
    }

    final previewPhotos = uploadedPhotos.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: previewPhotos.map((photoPath) {
            final isSelected = photoPath == activePhotoPath;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: photoPath == previewPhotos.last ? 0 : 8,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFFDCE6F2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isSelected ? 14 : 15),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(photoPath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFFF4F7FB),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.mutedText,
                                ),
                              );
                            },
                          ),
                          if (isSelected)
                            Container(
                              color: Colors.black.withValues(alpha: 0.24),
                              alignment: Alignment.bottomCenter,
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Cover',
                                style: AppTypography.label(
                                  fontSize: 10.8,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          '${totalCount ?? uploadedPhotos.length} uploaded photos are available in your gallery list.',
          style: AppTypography.body(
            fontSize: 11.8,
            color: AppColors.mutedText,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.chip, required this.module});

  final _KeywordChipData chip;
  final _AuditModule module;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: chip.isSelected ? const Color(0xFFF4F8FF) : AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: chip.isSelected
              ? const Color(0xFF4D7DDB)
              : const Color(0xFFDCE5F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chip.isSelected) ...[
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 14,
              color: Color(0xFF4D7DDB),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            chip.label,
            style: AppTypography.label(
              fontSize: 12,
              color: chip.isSelected
                  ? const Color(0xFF275DBF)
                  : AppColors.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.label(
        fontSize: 11.4,
        color: AppColors.mutedText,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PrimaryAuditButton extends StatelessWidget {
  const _PrimaryAuditButton({required this.module, required this.onPressed});

  final _AuditModule module;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(_actionIconFor(module), size: 18, color: AppColors.white),
        label: Text(
          module.primaryButtonLabel,
          style: AppTypography.button(
            fontSize: 14.2,
            color: AppColors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AuditCheckRow extends StatelessWidget {
  const _AuditCheckRow({required this.check});

  final _AuditCheckItem check;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(check.icon, size: 18, color: check.color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            check.text,
            style: AppTypography.body(
              fontSize: 13.4,
              color: AppColors.text,
              height: 1.38,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuditCheckItem {
  const _AuditCheckItem({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;
}

class _KeywordChipData {
  const _KeywordChipData({required this.label, this.isSelected = false});

  final String label;
  final bool isSelected;
}

_AuditModule _moduleFromRouteValue(Object? rawValue) {
  final value = rawValue?.toString().trim().toLowerCase();
  return _AuditModule.values.firstWhere(
    (module) => module.routeValue == value,
    orElse: () => _AuditModule.description,
  );
}

List<_AuditCheckItem> _buildChecks(
  _AuditModule module,
  TestAccount user,
  int photoCount,
  String activePhotoPath,
) {
  final city = _businessLocation(user);
  final category = _businessCategory(user);
  return switch (module) {
    _AuditModule.name => [
      const _AuditCheckItem(
        icon: Icons.check_circle_outline_rounded,
        text: 'Length – 6 words, 40 characters – good',
        color: Color(0xFF80B63B),
      ),
      _AuditCheckItem(
        icon: Icons.warning_amber_rounded,
        text:
            'Category keyword – Consider including your primary category keyword',
        color: Color(0xFFF0B640),
      ),
      _AuditCheckItem(
        icon: Icons.warning_amber_rounded,
        text: 'Location – Consider adding "$city" for local SEO',
        color: Color(0xFFF0B640),
      ),
    ],
    _AuditModule.description => [
      const _AuditCheckItem(
        icon: Icons.check_circle_outline_rounded,
        text: 'Length – 747/750 characters – optimal range',
        color: Color(0xFF80B63B),
      ),
      const _AuditCheckItem(
        icon: Icons.check_circle_outline_rounded,
        text: 'Word count – 104 words',
        color: Color(0xFF2CAAB9),
      ),
      const _AuditCheckItem(
        icon: Icons.check_circle_outline_rounded,
        text: 'Keywords – Contains category terms: estate, agent',
        color: Color(0xFF2CAAB9),
      ),
    ],
    _AuditModule.category => [
      _AuditCheckItem(
        icon: Icons.check_circle_outline_rounded,
        text: 'Primary category - "$category" is aligned to the business.',
        color: const Color(0xFF80B63B),
      ),
      const _AuditCheckItem(
        icon: Icons.warning_amber_rounded,
        text:
            'Secondary support - add service-led variations to widen search intent.',
        color: Color(0xFFF0B640),
      ),
      _AuditCheckItem(
        icon: Icons.info_outline_rounded,
        text: 'Local relevance - connect the category language to "$city".',
        color: AppColors.primary,
      ),
    ],
    _AuditModule.hours => [
      const _AuditCheckItem(
        icon: Icons.check_circle_outline_rounded,
        text: 'Weekday hours are filled and easy to trust.',
        color: Color(0xFF80B63B),
      ),
      const _AuditCheckItem(
        icon: Icons.warning_amber_rounded,
        text: 'Special holiday hours are not published yet.',
        color: Color(0xFFF0B640),
      ),
      const _AuditCheckItem(
        icon: Icons.info_outline_rounded,
        text: 'Weekend hours can be clearer to reduce missed calls.',
        color: AppColors.primary,
      ),
    ],
    _AuditModule.reviews => [
      const _AuditCheckItem(
        icon: Icons.check_circle_outline_rounded,
        text: 'Owner replies are active and support trust.',
        color: Color(0xFF80B63B),
      ),
      const _AuditCheckItem(
        icon: Icons.warning_amber_rounded,
        text: 'Fresh reviews are needed to keep weekly momentum.',
        color: Color(0xFFF0B640),
      ),
      const _AuditCheckItem(
        icon: Icons.info_outline_rounded,
        text: 'Reply templates can be localized for more keyword coverage.',
        color: AppColors.primary,
      ),
    ],
    _AuditModule.photos => [
      _AuditCheckItem(
        icon: photoCount > 0
            ? Icons.check_circle_outline_rounded
            : Icons.warning_amber_rounded,
        text: photoCount > 0
            ? '$photoCount uploaded photos are available for the profile.'
            : 'No uploaded profile photos are available yet.',
        color: photoCount > 0
            ? const Color(0xFF80B63B)
            : const Color(0xFFF0B640),
      ),
      _AuditCheckItem(
        icon: activePhotoPath.isNotEmpty
            ? Icons.check_circle_outline_rounded
            : Icons.warning_amber_rounded,
        text: activePhotoPath.isNotEmpty
            ? 'A cover photo is selected and ready to show publicly.'
            : 'A cover photo still needs to be chosen from the upload list.',
        color: activePhotoPath.isNotEmpty
            ? const Color(0xFF80B63B)
            : const Color(0xFFF0B640),
      ),
      const _AuditCheckItem(
        icon: Icons.info_outline_rounded,
        text: 'Rotate real business photos weekly to keep the gallery fresh.',
        color: AppColors.primary,
      ),
    ],
    _AuditModule.post => [
      const _AuditCheckItem(
        icon: Icons.warning_amber_rounded,
        text: 'Posting cadence is below the weekly visibility target.',
        color: Color(0xFFF0B640),
      ),
      const _AuditCheckItem(
        icon: Icons.info_outline_rounded,
        text:
            'Publishing fresh updates helps Google trust the business is active.',
        color: AppColors.primary,
      ),
      const _AuditCheckItem(
        icon: Icons.info_outline_rounded,
        text:
            'Use offer-led or location-led post copy for stronger engagement.',
        color: AppColors.primary,
      ),
    ],
    _AuditModule.profileReadiness => [
      const _AuditCheckItem(
        icon: Icons.check_circle_outline_rounded,
        text: 'Phone and address details are available for discovery.',
        color: Color(0xFF80B63B),
      ),
      const _AuditCheckItem(
        icon: Icons.warning_amber_rounded,
        text:
            'Place ID and coordinates should be synced for deeper audit matching.',
        color: Color(0xFFF0B640),
      ),
      const _AuditCheckItem(
        icon: Icons.info_outline_rounded,
        text: 'GBP Manager sync can improve profile completeness signals.',
        color: AppColors.primary,
      ),
    ],
    _AuditModule.visibilityActions => [
      const _AuditCheckItem(
        icon: Icons.warning_amber_rounded,
        text: 'Insights syncing is pending before performance can be scored.',
        color: Color(0xFFF0B640),
      ),
      const _AuditCheckItem(
        icon: Icons.info_outline_rounded,
        text:
            'Reports will unlock real calls, directions, and website clicks once synced.',
        color: AppColors.primary,
      ),
      const _AuditCheckItem(
        icon: Icons.info_outline_rounded,
        text:
            'Use GBP insight sync to replace placeholders with real action data.',
        color: AppColors.primary,
      ),
    ],
    _AuditModule.localRanking => [
      const _AuditCheckItem(
        icon: Icons.cancel_outlined,
        text:
            'No buying-intent keywords are currently tracked for this location.',
        color: Color(0xFFFF5D5D),
      ),
      const _AuditCheckItem(
        icon: Icons.info_outline_rounded,
        text:
            'Add core service plus city keywords to understand local map visibility.',
        color: AppColors.primary,
      ),
      const _AuditCheckItem(
        icon: Icons.info_outline_rounded,
        text:
            'Keyword Ranking can show movement once the first terms are active.',
        color: AppColors.primary,
      ),
    ],
  };
}

String _previewLabelFor(_AuditModule module) {
  return switch (module) {
    _AuditModule.name => 'LIVE NAME EDITOR',
    _AuditModule.description => 'GOOGLE PROFILE CONTENT',
    _AuditModule.category => 'LIVE CATEGORY EDITOR',
    _AuditModule.hours => 'LIVE HOURS PREVIEW',
    _AuditModule.reviews => 'REVIEW RESPONSE SNAPSHOT',
    _AuditModule.photos => 'PHOTO GALLERY SNAPSHOT',
    _AuditModule.post => 'POST MOMENTUM SNAPSHOT',
    _AuditModule.profileReadiness => 'PROFILE READINESS SNAPSHOT',
    _AuditModule.visibilityActions => 'VISIBILITY ACTION SNAPSHOT',
    _AuditModule.localRanking => 'LOCAL RANKING SNAPSHOT',
  };
}

String _chipsLabelFor(_AuditModule module) {
  return switch (module) {
    _AuditModule.name => 'KEYWORD OPPORTUNITIES',
    _AuditModule.description => 'KEYWORDS TO WEAVE IN',
    _AuditModule.category => 'CATEGORY OPPORTUNITIES',
    _AuditModule.hours => 'HOURS REMINDERS',
    _AuditModule.reviews => 'REPLY FOCUS',
    _AuditModule.photos => 'PHOTO TASKS',
    _AuditModule.post => 'POST TASKS',
    _AuditModule.profileReadiness => 'PROFILE TASKS',
    _AuditModule.visibilityActions => 'INSIGHT TASKS',
    _AuditModule.localRanking => 'RANKING TASKS',
  };
}

String _previewHelperTextFor(_AuditModule module) {
  return switch (module) {
    _AuditModule.name => 'Preview before publishing to Google Maps.',
    _AuditModule.description =>
      'Edit the business description customers see on Google.',
    _AuditModule.category =>
      'Review the primary and support category direction.',
    _AuditModule.hours => 'Check how business hours will appear publicly.',
    _AuditModule.reviews => 'Preview how trust signals are landing right now.',
    _AuditModule.photos => 'Preview the active photo coverage for the listing.',
    _AuditModule.post => 'Check how posting momentum is tracking this month.',
    _AuditModule.profileReadiness =>
      'Review the live profile connection health and missing sync signals.',
    _AuditModule.visibilityActions =>
      'Check whether calls, directions, and website action data is ready.',
    _AuditModule.localRanking =>
      'Check whether buying-intent local keywords are being monitored yet.',
  };
}

String _chipsHelperTextFor(_AuditModule module) {
  return switch (module) {
    _AuditModule.name =>
      'Green terms are already present. Tap a grey term to add it.',
    _AuditModule.description =>
      'Use these naturally inside the content. Avoid dumping keywords without context.',
    _AuditModule.category =>
      'Use nearby category themes only when they fit the business.',
    _AuditModule.hours =>
      'Small hour fixes reduce confusion and missed visits.',
    _AuditModule.reviews =>
      'Use reply language that improves trust and local relevance.',
    _AuditModule.photos =>
      'Refresh these image types to keep the profile active.',
    _AuditModule.post =>
      'Small, regular posting beats long periods of silence.',
    _AuditModule.profileReadiness =>
      'Connected data improves audit depth and local trust signals.',
    _AuditModule.visibilityActions =>
      'Insight sync replaces placeholders with real customer action history.',
    _AuditModule.localRanking =>
      'Tracked keywords make local ranking work measurable.',
  };
}

IconData _actionIconFor(_AuditModule module) {
  return switch (module) {
    _AuditModule.name => Icons.publish_outlined,
    _AuditModule.description => Icons.publish_outlined,
    _AuditModule.category => Icons.cloud_upload_outlined,
    _AuditModule.hours => Icons.schedule_send_outlined,
    _AuditModule.reviews => Icons.reply_all_rounded,
    _AuditModule.photos => Icons.photo_camera_back_outlined,
    _AuditModule.post => Icons.edit_square,
    _AuditModule.profileReadiness => Icons.verified_user_outlined,
    _AuditModule.visibilityActions => Icons.open_in_new_rounded,
    _AuditModule.localRanking => Icons.track_changes_rounded,
  };
}

List<_KeywordChipData> _keywordChipsFor(_AuditModule module, TestAccount user) {
  final city = _businessLocation(user);
  final businessWord = _businessName(user).split(RegExp(r'\s+')).first;
  final category = _businessCategory(user);
  final categoryWord = category.split(RegExp(r'\s+')).first;
  final industryWord = user.industry.trim().isEmpty
      ? categoryWord
      : user.industry.trim().split(RegExp(r'\s+')).first;

  return switch (module) {
    _AuditModule.name => [
      _KeywordChipData(label: city, isSelected: true),
      const _KeywordChipData(label: 'Mumbai'),
      _KeywordChipData(label: industryWord, isSelected: true),
      _KeywordChipData(label: categoryWord, isSelected: true),
      _KeywordChipData(label: 'Local $categoryWord'),
      _KeywordChipData(label: businessWord, isSelected: true),
      _KeywordChipData(label: '$categoryWord near me'),
      _KeywordChipData(label: category),
    ],
    _AuditModule.description => [
      _KeywordChipData(label: category, isSelected: true),
      _KeywordChipData(label: '$category in $city'),
      _KeywordChipData(label: '$industryWord services', isSelected: true),
      const _KeywordChipData(label: 'local market expertise'),
      const _KeywordChipData(label: 'client-focused approach', isSelected: true),
      _KeywordChipData(label: '$category specialists', isSelected: true),
      _KeywordChipData(label: '$industryWord business'),
    ],
    _AuditModule.category => _categorySuggestions(user),
    _AuditModule.hours => [
      const _KeywordChipData(label: 'Weekend hours', isSelected: true),
      const _KeywordChipData(label: 'Holiday hours'),
      const _KeywordChipData(label: 'Call window'),
    ],
    _AuditModule.reviews => [
      const _KeywordChipData(label: 'Reply faster', isSelected: true),
      _KeywordChipData(label: 'Mention $city'),
      const _KeywordChipData(label: 'Ask for photos'),
    ],
    _AuditModule.photos => [
      const _KeywordChipData(label: 'Cover refresh', isSelected: true),
      const _KeywordChipData(label: 'Team photo'),
      const _KeywordChipData(label: 'Storefront'),
      const _KeywordChipData(label: 'Products', isSelected: true),
    ],
    _AuditModule.post => [
      const _KeywordChipData(label: 'Weekly update', isSelected: true),
      const _KeywordChipData(label: 'Offer spotlight'),
      _KeywordChipData(label: '$city event'),
      const _KeywordChipData(label: 'Customer win'),
    ],
    _AuditModule.profileReadiness => [
      const _KeywordChipData(label: 'Phone connected', isSelected: true),
      const _KeywordChipData(label: 'Address synced', isSelected: true),
      const _KeywordChipData(label: 'Place ID'),
      const _KeywordChipData(label: 'Coordinates'),
    ],
    _AuditModule.visibilityActions => [
      const _KeywordChipData(label: 'Insights sync', isSelected: true),
      const _KeywordChipData(label: 'Calls'),
      const _KeywordChipData(label: 'Directions'),
      const _KeywordChipData(label: 'Website clicks'),
    ],
    _AuditModule.localRanking => [
      const _KeywordChipData(label: 'Category near me', isSelected: true),
      _KeywordChipData(label: '${_businessCategory(user)} in $city'),
      const _KeywordChipData(label: 'Buying intent'),
      const _KeywordChipData(label: 'Local pack'),
    ],
  };
}

List<_KeywordChipData> _categorySuggestions(TestAccount user) {
  final baseCategory = _businessCategory(user);
  final city = _businessLocation(user);
  return [
    _KeywordChipData(label: baseCategory, isSelected: true),
    _KeywordChipData(label: '$baseCategory in $city'),
    _KeywordChipData(label: 'Local $baseCategory'),
    _KeywordChipData(
      label:
          '${user.industry.trim().isEmpty ? 'Service' : user.industry.trim()} experts',
    ),
  ];
}

String _recommendedName(TestAccount user) {
  final businessName = _businessName(user);
  final categoryWord = _businessCategory(user);
  final city = _businessLocation(user);
  return '$businessName $categoryWord in $city';
}

String _recommendedDescription(TestAccount user) {
  final businessName = _businessName(user);
  final category = _businessCategory(user);
  final city = _businessLocation(user);
  return '$businessName is a trusted $category business serving $city. Highlight the services customers search for most, keep the profile details accurate, and publish fresh proof so Google can better understand your local relevance.';
}

String _buildAuditAiDescription({
  required TestAccount user,
  required AuditResult audit,
  required List<_KeywordChipData> keywords,
}) {
  final businessName = _businessName(user);
  final category = _businessCategory(user);
  final city = _businessLocation(user);
  final pickedKeywords = keywords
      .map((chip) => chip.label.trim())
      .where((value) => value.isNotEmpty)
      .take(3)
      .toList(growable: false);
  final strongestSignal =
      audit.summary?.strongestSignal.trim().isNotEmpty == true
      ? audit.summary!.strongestSignal.trim()
      : 'trusted service quality';
  final keywordText = pickedKeywords.isEmpty
      ? '$category in $city'
      : pickedKeywords.join(', ');

  return '$businessName is a $category business serving $city with a focus on $keywordText. '
      'Customers choose the business for ${strongestSignal.toLowerCase()}. '
      'Use this profile to explore services, review local expertise, and connect with a team that stays active, responsive, and committed to stronger visibility on Google.';
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

String _businessLocation(TestAccount user) {
  final city = user.city.trim();
  if (city.isNotEmpty) {
    return city;
  }
  final country = user.country.trim();
  if (country.isNotEmpty) {
    return country;
  }
  return 'Your City';
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

abstract final class _AuditPalette {
  static const Color canvas = Color(0xFFF5F7FB);
}

AuditSection? _getSectionForModule(AuditResult audit, _AuditModule module) {
  String key;
  switch (module) {
    case _AuditModule.photos:
      key = 'images';
      break;
    case _AuditModule.post:
      key = 'posts';
      break;
    default:
      key = module.name;
  }
  return audit.sections.firstWhereOrNull((s) => s.key == key);
}

class _AuditFullReportSheet extends StatelessWidget {
  const _AuditFullReportSheet({required this.audit});

  final AuditResult audit;

  @override
  Widget build(BuildContext context) {
    final summary = audit.summary;
    final findings = audit.sections
        .expand((section) => section.findings.map((finding) => (section, finding)))
        .toList(growable: false);

    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD4DDE8),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Full Audit Report',
                          style: AppTypography.card(
                            fontSize: 22,
                            color: AppColors.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          audit.businessName.isNotEmpty
                              ? audit.businessName
                              : 'Active business audit',
                          style: AppTypography.body(
                            fontSize: 13.2,
                            color: AppColors.mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8F7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${audit.overallScore}/100',
                      style: AppTypography.label(
                        fontSize: 12.8,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                children: [
                  if (summary != null) ...[
                    _AuditSheetSummaryCard(summary: summary),
                    const SizedBox(height: 14),
                  ],
                  ...audit.sections.map(
                    (section) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AuditReportSectionCard(section: section),
                    ),
                  ),
                  if (findings.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Key Findings',
                      style: AppTypography.card(
                        fontSize: 18,
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...findings.take(10).map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AuditFindingTile(
                          sectionTitle: entry.$1.title,
                          finding: entry.$2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditSheetSummaryCard extends StatelessWidget {
  const _AuditSheetSummaryCard({required this.summary});

  final AuditSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4ECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.verdict,
            style: AppTypography.card(
              fontSize: 18,
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _VerdictInfoChip(
                  label: 'CONFIDENCE',
                  value: summary.confidence,
                  background: const Color(0xFFF4F8FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _VerdictInfoChip(
                  label: 'DATA SOURCES',
                  value: '${summary.dataSources.length}',
                  background: const Color(0xFFF5F0FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InsightStrip(
            accent: const Color(0xFFE9447A),
            label: 'STRONGEST SIGNAL',
            value: summary.strongestSignal,
          ),
          const SizedBox(height: 8),
          _InsightStrip(
            accent: const Color(0xFFFF7A26),
            label: 'BIGGEST GROWTH LEAK',
            value: summary.biggestLeak,
          ),
        ],
      ),
    );
  }
}

class _AuditReportSectionCard extends StatelessWidget {
  const _AuditReportSectionCard({required this.section});

  final AuditSection section;

  @override
  Widget build(BuildContext context) {
    final accent = switch (section.status) {
      'pass' => const Color(0xFF19B26B),
      'fail' => const Color(0xFFFF5D5D),
      _ => const Color(0xFFF0B640),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EDF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  section.title,
                  style: AppTypography.card(
                    fontSize: 16,
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${section.score}/100',
                  style: AppTypography.label(
                    fontSize: 12,
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (section.currentValue?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              section.currentValue!.trim(),
              style: AppTypography.body(
                fontSize: 13.2,
                color: AppColors.brandBlue,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (section.findings.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...section.findings.take(3).map(
              (finding) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AuditFindingTile(
                  sectionTitle: section.title,
                  finding: finding,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AuditFindingTile extends StatelessWidget {
  const _AuditFindingTile({
    required this.sectionTitle,
    required this.finding,
  });

  final String sectionTitle;
  final AuditFinding finding;

  @override
  Widget build(BuildContext context) {
    final accent = switch (finding.status) {
      'pass' => const Color(0xFF19B26B),
      'fail' => const Color(0xFFFF5D5D),
      _ => const Color(0xFFF0B640),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sectionTitle,
            style: AppTypography.label(
              fontSize: 10.8,
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            finding.label,
            style: AppTypography.body(
              fontSize: 13.6,
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            finding.detail,
            style: AppTypography.body(
              fontSize: 12.6,
              color: AppColors.mutedText,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
