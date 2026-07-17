import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_logo.dart';
import '../models/test_account.dart';

class SidebarMenuTriggerButton extends StatelessWidget {
  const SidebarMenuTriggerButton({
    super.key,
    required this.onTap,
    this.isEmbedded = false,
  });

  final VoidCallback onTap;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: isEmbedded ? const Color(0xFFF3F7FD) : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E9F2)),
            boxShadow: isEmbedded
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x140F2746),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
          ),
          child: const Icon(
            Icons.menu_rounded,
            size: 28,
            color: AppColors.brandBlue,
          ),
        ),
      ),
    );
  }
}

class AuthSidebarPanel extends StatelessWidget {
  const AuthSidebarPanel({
    super.key,
    required this.user,
    required this.safeTopInset,
    required this.safeBottomInset,
    required this.onDashboardTap,
    required this.onGbpManagerTap,
    required this.onContentSectionTap,
    required this.isContentExpanded,
    required this.onContentPostsTap,
    required this.onContentOffersTap,
    required this.onContentPhotosTap,
    required this.onContentEventsTap,
    required this.onReviewsTap,
    required this.isReviewsExpanded,
    required this.onReviewResponseTap,
    required this.onReviewPosterTap,
    required this.onSeoToolsTap,
    required this.isSeoToolsExpanded,
    required this.onKeywordRankingTap,
    required this.onCompetitorAnalysisTap,
    required this.onHeatmapTap,
    required this.onCitationsTap,
    required this.onWebsiteBuilderTap,
    required this.onReportsTap,
    required this.onAuditTap,
    required this.isAuditExpanded,
    required this.onAuditScoreTap,
    required this.onAuditProfileTap,
    required this.onAlertsTap,
    required this.onSettingsTap,
    required this.onSupportTap,
    required this.onCollapseTap,
    required this.onLogoutTap,
  });

  final TestAccount user;
  final double safeTopInset;
  final double safeBottomInset;
  final VoidCallback onDashboardTap;
  final VoidCallback onGbpManagerTap;
  final VoidCallback onContentSectionTap;
  final bool isContentExpanded;
  final VoidCallback onContentPostsTap;
  final VoidCallback onContentOffersTap;
  final VoidCallback onContentPhotosTap;
  final VoidCallback onContentEventsTap;
  final VoidCallback onReviewsTap;
  final bool isReviewsExpanded;
  final VoidCallback onReviewResponseTap;
  final VoidCallback onReviewPosterTap;
  final VoidCallback onSeoToolsTap;
  final bool isSeoToolsExpanded;
  final VoidCallback onKeywordRankingTap;
  final VoidCallback onCompetitorAnalysisTap;
  final VoidCallback onHeatmapTap;
  final VoidCallback onCitationsTap;
  final VoidCallback onWebsiteBuilderTap;
  final VoidCallback onReportsTap;
  final VoidCallback onAuditTap;
  final bool isAuditExpanded;
  final VoidCallback onAuditScoreTap;
  final VoidCallback onAuditProfileTap;
  final VoidCallback onAlertsTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onSupportTap;
  final VoidCallback onCollapseTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    final currentRoute = Get.currentRoute;
    final isDashboardSelected = currentRoute == AppRoutes.dashboard;
    final isGbpManagerSelected = currentRoute == AppRoutes.gbpManager;
    final isPostsSelected = currentRoute == AppRoutes.gbpPosts;
    final isOffersSelected = currentRoute == AppRoutes.gbpOffers;
    final isPhotosSelected = currentRoute == AppRoutes.gbpPhotos;
    final isEventsSelected = currentRoute == AppRoutes.gbpEvents;
    final isContentSectionSelected =
        isPostsSelected ||
        isOffersSelected ||
        isPhotosSelected ||
        isEventsSelected;
    final isReviewResponseSelected = currentRoute == AppRoutes.clientReviews;
    final isReviewPosterSelected = currentRoute == AppRoutes.reviewPoster;
    final isReviewSectionSelected =
        isReviewResponseSelected || isReviewPosterSelected;
    final isWebsiteBuilderSelected = currentRoute == AppRoutes.websiteManager;
    final isReportsSelected = currentRoute == AppRoutes.reports;
    final isAuditSelected = currentRoute == AppRoutes.audit;
    final isAlertsSelected = currentRoute == AppRoutes.alerts;
    final isSettingsSelected = currentRoute == AppRoutes.account;
    final isSupportSelected = currentRoute == AppRoutes.support;
    final isKeywordRankingSelected = currentRoute == AppRoutes.keywordRanking;
    final isCompetitorAnalysisSelected =
        currentRoute == AppRoutes.seoCompetitors;
    final isHeatmapSelected = currentRoute == AppRoutes.seoHeatmap;
    final isSeoToolsSectionSelected =
        isKeywordRankingSelected ||
        isCompetitorAnalysisSelected ||
        isHeatmapSelected;
    final isCitationsSelected = currentRoute == AppRoutes.citations;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 240;

        return Material(
          color: AppColors.white,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x260F2746),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 12 : 16,
                      18 + safeTopInset,
                      compact ? 12 : 16,
                      16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppLogo(iconSize: compact ? 40 : 44),
                            const Spacer(),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onCollapseTap,
                                borderRadius: BorderRadius.circular(999),
                                child: Ink(
                                  width: compact ? 34 : 38,
                                  height: compact ? 34 : 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F7FD),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFE2E9F2),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.chevron_left_rounded,
                                    size: compact ? 21 : 24,
                                    color: AppColors.brandBlue,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 14 : 18),
                        _SidebarActionTile(
                          label: 'Dashboard',
                          icon: Icons.dashboard_customize_outlined,
                          isSelected: isDashboardSelected,
                          compact: compact,
                          onTap: onDashboardTap,
                        ),
                        const SizedBox(height: 8),
                        _SidebarActionTile(
                          label: 'GBP Manager',
                          icon: Icons.location_on_outlined,
                          isSelected: isGbpManagerSelected,
                          compact: compact,
                          onTap: onGbpManagerTap,
                        ),
                        const SizedBox(height: 4),
                        _SidebarActionTile(
                          label: 'Content',
                          icon: Icons.auto_awesome_mosaic_outlined,
                          isSelected: isContentSectionSelected,
                          compact: compact,
                          onTap: onContentSectionTap,
                          trailing: Icon(
                            isContentExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: isContentSectionSelected
                                ? AppColors.white.withValues(alpha: 0.9)
                                : const Color(0xFFA7B4C7),
                          ),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: EdgeInsets.fromLTRB(
                              compact ? 10 : 18,
                              6,
                              0,
                              2,
                            ),
                            child: Column(
                              children: [
                                _SidebarSubActionTile(
                                  label: 'Posts',
                                  icon: Icons.description_outlined,
                                  compact: compact,
                                  isSelected: isPostsSelected,
                                  onTap: onContentPostsTap,
                                ),
                                const SizedBox(height: 8),
                                _SidebarSubActionTile(
                                  label: 'Offers',
                                  icon: Icons.local_offer_outlined,
                                  compact: compact,
                                  isSelected: isOffersSelected,
                                  onTap: onContentOffersTap,
                                ),
                                const SizedBox(height: 8),
                                _SidebarSubActionTile(
                                  label: 'Photos',
                                  icon: Icons.photo_library_outlined,
                                  compact: compact,
                                  isSelected: isPhotosSelected,
                                  onTap: onContentPhotosTap,
                                ),
                                const SizedBox(height: 8),
                                _SidebarSubActionTile(
                                  label: 'Events',
                                  icon: Icons.event_outlined,
                                  compact: compact,
                                  isSelected: isEventsSelected,
                                  onTap: onContentEventsTap,
                                ),
                              ],
                            ),
                          ),
                          crossFadeState: isContentExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 180),
                          sizeCurve: Curves.easeOutCubic,
                          firstCurve: Curves.easeOutCubic,
                          secondCurve: Curves.easeOutCubic,
                        ),
                        const SizedBox(height: 4),
                        _SidebarActionTile(
                          label: 'Reviews',
                          icon: Icons.chat_bubble_outline_rounded,
                          isSelected: isReviewSectionSelected,
                          compact: compact,
                          onTap: onReviewsTap,
                          trailing: Icon(
                            isReviewsExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: isReviewSectionSelected
                                ? AppColors.white.withValues(alpha: 0.9)
                                : const Color(0xFFA7B4C7),
                          ),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: EdgeInsets.fromLTRB(
                              compact ? 10 : 18,
                              6,
                              0,
                              2,
                            ),
                            child: Column(
                              children: [
                                _SidebarSubActionTile(
                                  label: 'Review Response',
                                  icon: Icons.mode_comment_outlined,
                                  compact: compact,
                                  isSelected: isReviewResponseSelected,
                                  onTap: onReviewResponseTap,
                                ),
                                const SizedBox(height: 8),
                                _SidebarSubActionTile(
                                  label: 'Review Poster',
                                  icon: Icons.qr_code_2_rounded,
                                  compact: compact,
                                  isSelected: isReviewPosterSelected,
                                  onTap: onReviewPosterTap,
                                ),
                              ],
                            ),
                          ),
                          crossFadeState: isReviewsExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 180),
                          sizeCurve: Curves.easeOutCubic,
                          firstCurve: Curves.easeOutCubic,
                          secondCurve: Curves.easeOutCubic,
                        ),
                        const SizedBox(height: 4),
                        _SidebarActionTile(
                          label: 'SEO Tools',
                          icon: Icons.search_rounded,
                          isSelected: isSeoToolsSectionSelected,
                          compact: compact,
                          onTap: onSeoToolsTap,
                          trailing: Icon(
                            isSeoToolsExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: isSeoToolsSectionSelected
                                ? AppColors.white.withValues(alpha: 0.9)
                                : const Color(0xFFA7B4C7),
                          ),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: EdgeInsets.fromLTRB(
                              compact ? 10 : 18,
                              6,
                              0,
                              2,
                            ),
                            child: Column(
                              children: [
                                _SidebarSubActionTile(
                                  label: 'Keyword Ranking',
                                  icon: Icons.insights_outlined,
                                  isSelected: isKeywordRankingSelected,
                                  compact: compact,
                                  onTap: onKeywordRankingTap,
                                ),
                                const SizedBox(height: 8),
                                _SidebarSubActionTile(
                                  label: 'Competitor Analysis',
                                  icon: Icons.groups_2_outlined,
                                  isSelected: isCompetitorAnalysisSelected,
                                  compact: compact,
                                  onTap: onCompetitorAnalysisTap,
                                ),
                                const SizedBox(height: 8),
                                _SidebarSubActionTile(
                                  label: 'Heatmap',
                                  icon: Icons.grid_view_rounded,
                                  isSelected: isHeatmapSelected,
                                  compact: compact,
                                  onTap: onHeatmapTap,
                                ),
                              ],
                            ),
                          ),
                          crossFadeState: isSeoToolsExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 180),
                          sizeCurve: Curves.easeOutCubic,
                          firstCurve: Curves.easeOutCubic,
                          secondCurve: Curves.easeOutCubic,
                        ),
                        const SizedBox(height: 4),
                        _SidebarActionTile(
                          label: 'Citations',
                          icon: Icons.public_outlined,
                          isSelected: isCitationsSelected,
                          compact: compact,
                          onTap: onCitationsTap,
                        ),
                        const SizedBox(height: 4),
                        _SidebarActionTile(
                          label: 'Website Builder',
                          icon: Icons.language_outlined,
                          isSelected: isWebsiteBuilderSelected,
                          compact: compact,
                          onTap: onWebsiteBuilderTap,
                        ),
                        const SizedBox(height: 4),
                        _SidebarActionTile(
                          label: 'Reports',
                          icon: Icons.description_outlined,
                          isSelected: isReportsSelected,
                          compact: compact,
                          onTap: onReportsTap,
                        ),
                        const SizedBox(height: 4),
                        _SidebarActionTile(
                          label: 'Audit',
                          icon: Icons.task_alt_outlined,
                          isSelected: isAuditSelected,
                          compact: compact,
                          onTap: onAuditTap,
                          trailing: Icon(
                            isAuditExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: isAuditSelected
                                ? AppColors.white.withValues(alpha: 0.9)
                                : const Color(0xFFA7B4C7),
                          ),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: EdgeInsets.fromLTRB(
                              compact ? 10 : 18,
                              6,
                              0,
                              2,
                            ),
                            child: Column(
                              children: [
                                _SidebarSubActionTile(
                                  label: 'Audit score',
                                  icon: Icons.speed_rounded,
                                  compact: compact,
                                  isSelected: isAuditSelected,
                                  onTap: onAuditScoreTap,
                                ),
                                const SizedBox(height: 8),
                                _SidebarSubActionTile(
                                  label: 'Audit profile',
                                  icon: Icons.checklist_rtl_rounded,
                                  compact: compact,
                                  isSelected: isAuditSelected,
                                  onTap: onAuditProfileTap,
                                ),
                              ],
                            ),
                          ),
                          crossFadeState: isAuditExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 180),
                          sizeCurve: Curves.easeOutCubic,
                          firstCurve: Curves.easeOutCubic,
                          secondCurve: Curves.easeOutCubic,
                        ),
                        const SizedBox(height: 4),
                        _SidebarActionTile(
                          label: 'Alerts',
                          icon: Icons.notifications_none_rounded,
                          isSelected: isAlertsSelected,
                          compact: compact,
                          onTap: onAlertsTap,
                          trailing: _SidebarBadge(label: '3', compact: compact),
                        ),
                        const SizedBox(height: 14),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.line,
                        ),
                        const SizedBox(height: 12),
                        _SidebarActionTile(
                          label: 'Settings',
                          icon: Icons.settings_outlined,
                          isSelected: isSettingsSelected,
                          compact: compact,
                          onTap: onSettingsTap,
                        ),
                        const SizedBox(height: 4),
                        _SidebarActionTile(
                          label: 'Support',
                          icon: Icons.help_outline_rounded,
                          isSelected: isSupportSelected,
                          compact: compact,
                          onTap: onSupportTap,
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.line),
                _SidebarUserCard(
                  user: user,
                  compact: compact,
                  onLogoutTap: onLogoutTap,
                ),
                SizedBox(height: safeBottomInset),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SidebarActionTile extends StatelessWidget {
  const _SidebarActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
    this.trailing,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected
        ? AppColors.white
        : const Color(0xFF4C5D7A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 11 : 13,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x2239B4BD),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: compact ? 18 : 19, color: foregroundColor),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.button(
                    fontSize: compact ? 13.8 : 15,
                    color: foregroundColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarBadge extends StatelessWidget {
  const _SidebarBadge({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.label(
          fontSize: compact ? 11.5 : AppTypography.microLabel,
          color: AppColors.brandBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SidebarSubActionTile extends StatelessWidget {
  const _SidebarSubActionTile({
    required this.label,
    required this.onTap,
    this.icon,
    this.isSelected = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? AppColors.primary
        : const Color(0xFFF4FAFB);
    final borderColor = isSelected
        ? AppColors.primary
        : AppColors.primary.withValues(alpha: 0.18);
    final foregroundColor = isSelected ? AppColors.white : AppColors.brandBlue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 9 : 10,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x2239B4BD),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              if (icon == null)
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: foregroundColor,
                    shape: BoxShape.circle,
                  ),
                )
              else
                Icon(icon, size: compact ? 15 : 17, color: foregroundColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label(
                    fontSize: compact ? 13.2 : 14.2,
                    color: foregroundColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isSelected
                    ? AppColors.white.withValues(alpha: 0.95)
                    : const Color(0xFF97A8BD),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarUserCard extends StatelessWidget {
  const _SidebarUserCard({
    required this.user,
    required this.onLogoutTap,
    this.compact = false,
  });

  final TestAccount user;
  final VoidCallback onLogoutTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 14,
        12,
        compact ? 10 : 14,
        14,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 9 : 10,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFEAFBFE),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 30 : 34,
              height: compact ? 30 : 34,
              decoration: const BoxDecoration(
                color: Color(0xFF4A90F3),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _userInitials(user.fullName),
                style: AppTypography.label(
                  fontSize: compact ? 11 : 12,
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(width: compact ? 8 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(
                      fontSize: compact ? 12.6 : 14,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(
                      fontSize: compact ? 10.8 : 12,
                      color: AppColors.mutedText.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onLogoutTap,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.logout_rounded,
                  size: 19,
                  color: Color(0xFFFF5A5A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _userInitials(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();
  if (parts.isEmpty) {
    return 'VA';
  }
  return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
}
