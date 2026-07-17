import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../controllers/website_manager_controller.dart';
import '../models/website_manager_models.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_navigation_shell.dart';

class WebsiteManagerView extends GetView<WebsiteManagerController> {
  const WebsiteManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthNavigationShell(
      currentTab: AuthTab.home,
      backgroundColor: _WebsitePalette.canvas,
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.08)),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const _LoadingState();
          }

          final selectedLocation = controller.selectedLocation;
          final activeWebsite = controller.activeWebsite;
          final selectedLocationHistory = controller.selectedLocationHistory;
          final activeLiveUrl = controller.absolutePreviewUrlFor(activeWebsite);
          final activePreviewUrl = controller.activePreviewUrl;
          final screenWidth = MediaQuery.sizeOf(context).width;
          final isWideLayout = screenWidth >= 980;
          final previewHeight = isWideLayout ? 700.0 : 500.0;
          final dropdownValue =
              controller.locations.any(
                (location) =>
                    location.id == controller.selectedLocationId.value,
              )
              ? controller.selectedLocationId.value
              : null;

          final leftColumn = Column(
            children: [
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF5FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.language_rounded,
                            color: AppColors.brandBlue,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Live Website',
                                style: AppTypography.section(
                                  fontSize: 22,
                                  color: AppColors.brandBlue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Connect this screen to your cloud-hosted website instances and manage the live version per location.',
                                style: AppTypography.body(
                                  fontSize: 13.2,
                                  color: AppColors.mutedText,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (activeWebsite != null)
                          const _StatusBadge(
                            label: 'Live',
                            foreground: Color(0xFF1B9E5A),
                            background: Color(0xFFE9F8EF),
                            icon: Icons.check_circle_rounded,
                          ),
                        _StatusBadge(
                          label: controller.generationJob.value == null
                              ? 'Cloud Ready'
                              : controller.generationJob.value!.status.label,
                          foreground:
                              controller.generationJob.value != null &&
                                  controller.generationJob.value!.status ==
                                      WebsiteGenerationStatus.failed
                              ? const Color(0xFFD64545)
                              : const Color(0xFF2368D8),
                          background:
                              controller.generationJob.value != null &&
                                  controller.generationJob.value!.status ==
                                      WebsiteGenerationStatus.failed
                              ? const Color(0xFFFFECEC)
                              : const Color(0xFFEAF2FF),
                          icon:
                              controller.generationJob.value != null &&
                                  controller.generationJob.value!.status ==
                                      WebsiteGenerationStatus.failed
                              ? Icons.error_rounded
                              : Icons.cloud_done_rounded,
                        ),
                        if (selectedLocationHistory.isNotEmpty)
                          _StatusBadge(
                            label:
                                '${selectedLocationHistory.length} version${selectedLocationHistory.length == 1 ? '' : 's'}',
                            foreground: AppColors.primary,
                            background: const Color(0xFFEAF9FB),
                            icon: Icons.history_rounded,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Business Location',
                      style: AppTypography.label(
                        fontSize: 12.2,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey(dropdownValue ?? 'no-location'),
                      initialValue: dropdownValue,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.mutedText,
                      ),
                      decoration: _inputDecoration(),
                      style: AppTypography.body(
                        fontSize: 13,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w700,
                      ),
                      items: controller.locations
                          .map(
                            (location) => DropdownMenuItem<String>(
                              value: location.id,
                              child: Text(
                                location.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: controller.locations.isEmpty
                          ? null
                          : controller.selectLocation,
                    ),
                    if (selectedLocation != null) ...[
                      const SizedBox(height: 14),
                      _LocationSummaryBlock(location: selectedLocation),
                    ],
                    if (activeWebsite != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Live Link',
                        style: AppTypography.label(
                          fontSize: 12.2,
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _LinkActionRow(
                        link: activeLiveUrl,
                        onCopy: () => _copyLink(activeLiveUrl),
                        onOpen: () => _openExternal(activeLiveUrl),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            controller.isGenerating.value ||
                                controller.selectedLocationId.value.isEmpty
                            ? null
                            : controller.generateForSelectedLocation,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.brandBlue,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: controller.isGenerating.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                controller.hasWebsiteForSelectedLocation
                                    ? Icons.refresh_rounded
                                    : Icons.auto_fix_high_rounded,
                                size: 18,
                              ),
                        label: Text(
                          controller.isGenerating.value
                              ? 'Generating...'
                              : controller.hasWebsiteForSelectedLocation
                              ? 'Regenerate Website'
                              : 'Make This Website Live',
                          style: AppTypography.button(
                            fontSize: 13.4,
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final rightColumn = Column(
            children: [
              _SectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompactHeader = constraints.maxWidth < 560;

                          final details = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Website Preview',
                                style: AppTypography.section(
                                  fontSize: 22,
                                  color: AppColors.brandBlue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activeWebsite == null
                                    ? 'Select a location and generate its website to load the live cloud preview here.'
                                    : 'This preview is loaded from the live generated website instance stored in the cloud.',
                                style: AppTypography.body(
                                  fontSize: 13,
                                  color: AppColors.mutedText,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          );

                          final action = activeWebsite == null
                              ? null
                              : _PreviewActionButton(
                                  onTap: () => _openExternal(activeLiveUrl),
                                );

                          if (isCompactHeader) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                details,
                                if (action != null) ...[
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: action,
                                  ),
                                ],
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: details),
                              if (action != null) ...[
                                const SizedBox(width: 14),
                                action,
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Container(
                        height: previewHeight,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FBFE),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE1E9F2)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A0F2746),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: activeWebsite == null
                            ? const _PreviewPlaceholder()
                            : _LiveWebsitePreview(previewUrl: activePreviewUrl),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Generation History',
                            style: AppTypography.section(
                              fontSize: 22,
                              color: AppColors.brandBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _CountPill(
                          label:
                              '${selectedLocationHistory.length} version${selectedLocationHistory.length == 1 ? '' : 's'}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedLocation?.name ??
                          activeWebsite?.locationName ??
                          'Generated websites',
                      style: AppTypography.body(
                        fontSize: 12.8,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (selectedLocationHistory.isEmpty)
                      const _EmptySectionCopy(
                        title: 'No generated versions for this location',
                        subtitle:
                            'The first live instance will appear here after you run website generation.',
                      )
                    else
                      Column(
                        children: selectedLocationHistory
                            .map(
                              (website) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _HistoryTile(
                                  website: website,
                                  isActive:
                                      website.siteKey == activeWebsite?.siteKey,
                                  liveUrl: controller.absolutePreviewUrlFor(
                                    website,
                                  ),
                                  onSelect: () =>
                                      controller.selectWebsite(website.siteKey),
                                  onOpen: () => _openExternal(
                                    controller.absolutePreviewUrlFor(website),
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                  ],
                ),
              ),
            ],
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AuthViewSpacing.pageHorizontal,
              8,
              AuthViewSpacing.pageHorizontal,
              AuthViewSpacing.pageBottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderBar(
                  isRefreshing: controller.isRefreshing.value,
                  onBack: _handleBackTap,
                  onRefresh: controller.refreshData,
                ),
                const SizedBox(height: 12),
                Text(
                  'Website Manager',
                  style: AppTypography.section(
                    fontSize: 30,
                    height: 1.08,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            'Manage your AI-generated websites, cloud-hosted live links, and preview experience powered by ',
                        style: AppTypography.body(
                          fontSize: 13.4,
                          color: AppColors.mutedText,
                          height: 1.45,
                        ),
                      ),
                      TextSpan(
                        text: 'VisibloAI',
                        style: AppTypography.body(
                          fontSize: 13.4,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (controller.errorMessage.value != null) ...[
                  _InlineBanner(
                    title: 'Something needs attention',
                    message: controller.errorMessage.value!,
                    accent: const Color(0xFFD64545),
                    background: const Color(0xFFFFF1F1),
                    icon: Icons.error_outline_rounded,
                    onDismiss: controller.clearError,
                  ),
                  const SizedBox(height: 12),
                ],
                if (controller.infoMessage.value != null) ...[
                  _InlineBanner(
                    title: 'Website Manager',
                    message: controller.infoMessage.value!,
                    accent: const Color(0xFF188B63),
                    background: const Color(0xFFEFFBF5),
                    icon: Icons.info_outline_rounded,
                    onDismiss: controller.clearInfoMessage,
                  ),
                  const SizedBox(height: 12),
                ],
                if (controller.generationJob.value != null &&
                    !controller.generationJob.value!.status.isTerminal) ...[
                  _JobStatusCard(job: controller.generationJob.value!),
                  const SizedBox(height: 12),
                ],
                if (isWideLayout)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: leftColumn),
                      const SizedBox(width: 16),
                      Expanded(flex: 7, child: rightColumn),
                    ],
                  )
                else
                  Column(
                    children: [
                      leftColumn,
                      const SizedBox(height: 16),
                      rightColumn,
                    ],
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _handleBackTap() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
      return;
    }
    Get.offNamed(AppRoutes.dashboard);
  }

  Future<void> _copyLink(String link) async {
    if (link.trim().isEmpty) {
      _showSnack(
        title: 'No live link yet',
        message: 'Generate a website first so there is a cloud link to copy.',
        accent: const Color(0xFFD64545),
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: link));
    _showSnack(
      title: 'Link copied',
      message: 'The live website link is ready to share.',
      accent: AppColors.primary,
      icon: Icons.copy_rounded,
    );
  }

  Future<void> _openExternal(String link) async {
    final uri = Uri.tryParse(link.trim());
    if (uri == null) {
      _showSnack(
        title: 'Invalid link',
        message: 'This website URL could not be opened.',
        accent: const Color(0xFFD64545),
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      _showSnack(
        title: 'Could not open website',
        message: 'The external browser could not open this link right now.',
        accent: const Color(0xFFD64545),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  void _showSnack({
    required String title,
    required String message,
    required Color accent,
    required IconData icon,
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
      borderColor: accent.withValues(alpha: 0.18),
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
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.isRefreshing,
    required this.onBack,
    required this.onRefresh,
  });

  final bool isRefreshing;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onBack,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _WebsitePalette.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0E0F2746),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: AppColors.brandBlue,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'Website Builder',
            textAlign: TextAlign.center,
            style: AppTypography.label(
              fontSize: 15,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isRefreshing ? null : onRefresh,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _WebsitePalette.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0E0F2746),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.brandBlue,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: AppColors.brandBlue,
                  ),
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Loading your live website manager...',
              textAlign: TextAlign.center,
              style: AppTypography.button(
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fetching business locations, generated websites, and cloud preview details.',
              textAlign: TextAlign.center,
              style: AppTypography.body(
                color: AppColors.mutedText,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _WebsitePalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F2746),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.label(
              fontSize: 11.2,
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.label(
          fontSize: 10.8,
          color: AppColors.brandBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LocationSummaryBlock extends StatelessWidget {
  const _LocationSummaryBlock({required this.location});

  final BusinessLocationSummary location;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EBF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            location.name,
            style: AppTypography.button(
              fontSize: 15.5,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (location.primaryCategory.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              location.primaryCategory,
              style: AppTypography.body(
                fontSize: 12.1,
                color: AppColors.mutedText,
              ),
            ),
          ],
          if (location.displayAddress.isNotEmpty) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.place_outlined,
              value: location.displayAddress,
            ),
          ],
          if (location.phone.isNotEmpty) ...[
            const SizedBox(height: 6),
            _DetailRow(icon: Icons.call_outlined, value: location.phone),
          ],
          if (location.websiteUrl.isNotEmpty) ...[
            const SizedBox(height: 6),
            _DetailRow(icon: Icons.link_rounded, value: location.websiteUrl),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.mutedText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTypography.body(
              fontSize: 12.1,
              color: AppColors.mutedText,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _LinkActionRow extends StatelessWidget {
  const _LinkActionRow({
    required this.link,
    required this.onCopy,
    required this.onOpen,
  });

  final String link;
  final VoidCallback onCopy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E8F1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              link,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(
                fontSize: 12.1,
                color: AppColors.mutedText,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _MiniActionButton(
            icon: Icons.copy_rounded,
            background: AppColors.primary,
            foreground: AppColors.white,
            onTap: onCopy,
          ),
          const SizedBox(width: 6),
          _MiniActionButton(
            icon: Icons.open_in_new_rounded,
            background: const Color(0xFFEAF2FF),
            foreground: AppColors.brandBlue,
            onTap: onOpen,
          ),
        ],
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: foreground),
      ),
    );
  }
}

class _PreviewActionButton extends StatelessWidget {
  const _PreviewActionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.open_in_new_rounded, size: 17),
      label: Text(
        'Open Full Page',
        style: AppTypography.button(
          fontSize: 13,
          color: AppColors.brandBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brandBlue,
        backgroundColor: AppColors.white,
        side: const BorderSide(color: Color(0xFFD6E4F4)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({
    required this.title,
    required this.message,
    required this.accent,
    required this.background,
    required this.icon,
    required this.onDismiss,
  });

  final String title;
  final String message;
  final Color accent;
  final Color background;
  final IconData icon;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.button(
                    fontSize: 13.5,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTypography.body(
                    fontSize: 12.4,
                    color: AppColors.mutedText,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobStatusCard extends StatelessWidget {
  const _JobStatusCard({required this.job});

  final WebsiteGenerationJob job;

  @override
  Widget build(BuildContext context) {
    final queueText = job.queuePosition == null
        ? 'The backend is preparing this website now.'
        : 'Queue position ${job.queuePosition}. The backend is building this website now.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E8FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Building your live website...',
                  style: AppTypography.button(
                    fontSize: 13.8,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  queueText,
                  style: AppTypography.body(
                    fontSize: 12.4,
                    color: AppColors.mutedText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFDCE8F6)),
                  ),
                  child: Text(
                    'Job ${job.id}',
                    style: AppTypography.label(
                      fontSize: 11,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w700,
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

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7FAFD),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5FF),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.language_rounded,
              size: 34,
              color: AppColors.brandBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No website generated yet',
            textAlign: TextAlign.center,
            style: AppTypography.section(
              fontSize: 18,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a business location and make its website live to load the real cloud preview here.',
            textAlign: TextAlign.center,
            style: AppTypography.body(
              fontSize: 13,
              color: AppColors.mutedText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveWebsitePreview extends StatefulWidget {
  const _LiveWebsitePreview({required this.previewUrl});

  final String previewUrl;

  @override
  State<_LiveWebsitePreview> createState() => _LiveWebsitePreviewState();
}

class _LiveWebsitePreviewState extends State<_LiveWebsitePreview> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  int _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _error = null;
              _progress = 0;
            });
          },
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              _progress = progress;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _progress = 100;
            });
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _error = error.description.isEmpty
                  ? 'The preview could not be loaded right now.'
                  : error.description;
            });
          },
        ),
      );
    _loadPreview();
  }

  @override
  void didUpdateWidget(covariant _LiveWebsitePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewUrl != widget.previewUrl) {
      _loadPreview();
    }
  }

  Future<void> _loadPreview() async {
    final uri = Uri.tryParse(widget.previewUrl);
    if (uri == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'The preview URL is invalid.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _progress = 0;
    });

    await _webViewController.loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: WebViewWidget(controller: _webViewController)),
        if (_isLoading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _progress == 0 || _progress >= 100
                  ? null
                  : _progress / 100,
              color: AppColors.primary,
              backgroundColor: const Color(0xFFDCE8F6),
            ),
          ),
        if (_error != null)
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF7FAFD),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.public_off_rounded,
                    size: 36,
                    color: AppColors.mutedText,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Preview unavailable',
                    style: AppTypography.section(
                      fontSize: 17,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppTypography.body(
                      fontSize: 12.6,
                      color: AppColors.mutedText,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _loadPreview,
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: const Text('Reload Preview'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandBlue,
                      side: const BorderSide(color: Color(0xFFD7E8FF)),
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.website,
    required this.isActive,
    required this.liveUrl,
    required this.onSelect,
    required this.onOpen,
  });

  final GeneratedWebsite website;
  final bool isActive;
  final String liveUrl;
  final VoidCallback onSelect;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onSelect,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF1F8FF) : const Color(0xFFF9FBFD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? const Color(0xFF8FC3FF) : const Color(0xFFE7EDF4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    website.locationName.isEmpty
                        ? 'Generated website'
                        : website.locationName,
                    style: AppTypography.button(
                      fontSize: 13.5,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isActive)
                  const _StatusBadge(
                    label: 'Active',
                    foreground: AppColors.primary,
                    background: Color(0xFFEAF9FB),
                    icon: Icons.visibility_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatTimestamp(website.generatedAt),
              style: AppTypography.body(
                fontSize: 12.4,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HistoryMetaPill(label: _formatTemplateId(website.templateId)),
                _HistoryMetaPill(
                  label:
                      '${website.pages.length} page${website.pages.length == 1 ? '' : 's'}',
                ),
                _HistoryMetaPill(label: _formatSource(website.source)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    liveUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      fontSize: 11.6,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onOpen,
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: AppColors.brandBlue,
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

class _HistoryMetaPill extends StatelessWidget {
  const _HistoryMetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDE8F4)),
      ),
      child: Text(
        label,
        style: AppTypography.label(
          fontSize: 10.8,
          color: AppColors.brandBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptySectionCopy extends StatelessWidget {
  const _EmptySectionCopy({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EDF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.button(
              fontSize: 13,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.body(
              fontSize: 12.2,
              color: AppColors.mutedText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration() {
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: const Color(0xFFF9FBFD),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE0E8F1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE0E8F1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
  );
}

String _formatTemplateId(String? templateId) {
  final normalized = (templateId ?? '').trim();
  if (normalized.isEmpty) {
    return 'Auto';
  }

  return normalized
      .split(RegExp(r'[-_]+'))
      .where((part) => part.trim().isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String _formatSource(String? source) {
  final normalized = (source ?? '').trim().toLowerCase();
  switch (normalized) {
    case 'place_id':
      return 'GBP Sync';
    case 'lead_fallback':
      return 'Lead Fallback';
    case '':
      return 'Waiting';
    default:
      return normalized
          .split('_')
          .where((part) => part.isNotEmpty)
          .map(
            (part) =>
                '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
          )
          .join(' ');
  }
}

String _formatTimestamp(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) {
    return value.trim().isEmpty ? 'Unknown date' : value;
  }

  final local = date.toLocal();
  const months = <String>[
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
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  final minute = local.minute.toString().padLeft(2, '0');
  return '${months[local.month - 1]} ${local.day}, ${local.year} • $hour:$minute $suffix';
}

abstract final class _WebsitePalette {
  static const canvas = Color(0xFFF3F7FB);
  static const border = Color(0xFFE3EAF2);
}
