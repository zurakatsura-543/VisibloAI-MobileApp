import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../controllers/review_poster_controller.dart';
import '../models/review_poster_models.dart';
import '../models/website_manager_models.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_navigation_shell.dart';

class ReviewPosterView extends GetView<ReviewPosterController> {
  const ReviewPosterView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthNavigationShell(
      currentTab: AuthTab.home,
      backgroundColor: const Color(0xFFF4F7FB),
      child: Obx(() {
        if (controller.isLoading.value && controller.locations.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final selectedLocation = controller.selectedLocation;
        final dropdownValue =
            controller.locations.any(
              (location) => location.id == controller.selectedLocationId.value,
            )
            ? controller.selectedLocationId.value
            : null;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.refreshData,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideLayout = constraints.maxWidth >= 980;
              final leftColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderCard(
                    onRefresh: controller.refreshData,
                    isRefreshing:
                        controller.isLoading.value ||
                        controller.isResolvingReviewUrl.value,
                  ),
                  const SizedBox(height: 12),
                  if (controller.errorMessage.value != null) ...[
                    _FeedbackBanner(
                      message: controller.errorMessage.value!,
                      isError: true,
                      onDismiss: controller.clearError,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (controller.infoMessage.value != null) ...[
                    _FeedbackBanner(
                      message: controller.infoMessage.value!,
                      onDismiss: controller.clearInfo,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _DesignCard(controller: controller),
                  const SizedBox(height: 12),
                  _PosterContentCard(
                    controller: controller,
                    onCopy: _copyReviewLink,
                    onShareWhatsApp: _shareReviewLinkOnWhatsApp,
                  ),
                ],
              );

              final previewColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PreviewPanel(
                    controller: controller,
                    onOpenReview: _openReviewPage,
                  ),
                  const SizedBox(height: 12),
                  _ExportCard(onOpenPosterPdf: _openPosterPdf),
                  const SizedBox(height: 12),
                  _LocationCard(
                    locations: controller.locations,
                    selectedLocation: selectedLocation,
                    dropdownValue: dropdownValue,
                    isResolvingReviewUrl: controller.isResolvingReviewUrl.value,
                    hasDirectReviewUrl: controller.hasDirectReviewUrl,
                    reviewUrl: controller.reviewUrl,
                    onLocationChanged: controller.selectLocation,
                  ),
                ],
              );

              final content = isWideLayout
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: leftColumn),
                        const SizedBox(width: 18),
                        Expanded(flex: 7, child: previewColumn),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        leftColumn,
                        const SizedBox(height: 14),
                        previewColumn,
                      ],
                    );

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AuthViewSpacing.pageHorizontal,
                  12,
                  AuthViewSpacing.pageHorizontal,
                  24,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1360),
                      child: content,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }),
    );
  }

  Future<void> _copyReviewLink() async {
    final reviewUrl = controller.reviewUrl.trim();
    if (reviewUrl.isEmpty) {
      _showFailure('Copy failed', 'There is no review link to copy yet.');
      return;
    }

    await Clipboard.setData(ClipboardData(text: reviewUrl));
    Get.snackbar(
      'Link copied',
      'The live review link is ready to share.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: AppColors.text,
      margin: const EdgeInsets.all(12),
    );
  }

  Future<void> _openReviewPage() async {
    final reviewUrl = controller.reviewUrl.trim();
    if (reviewUrl.isEmpty) {
      _showFailure('Open failed', 'There is no review link to open yet.');
      return;
    }

    final uri = _normalizeUri(reviewUrl);
    if (uri == null) {
      _showFailure('Open failed', 'The review link could not be opened.');
      return;
    }

    final launched = await _launchWithFallbacks(uri);
    if (!launched) {
      _showFailure(
        'Open failed',
        'The Google review page could not be opened on this device.',
      );
    }
  }

  Future<void> _shareReviewLinkOnWhatsApp() async {
    final reviewUrl = controller.reviewUrl.trim();
    if (reviewUrl.isEmpty) {
      _showFailure('Share failed', 'There is no review link to share yet.');
      return;
    }

    final shareMessage = controller.whatsAppShareMessage;
    final appShareUri = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(shareMessage)}',
    );
    final shareUri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '/',
      queryParameters: <String, String>{'text': shareMessage},
    );

    if (await _launchWithFallbacks(appShareUri)) {
      return;
    }

    if (await _launchWithFallbacks(shareUri)) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: shareMessage));
    Get.snackbar(
      'Share text copied',
      'WhatsApp could not be opened, so the message was copied instead.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: AppColors.text,
      margin: const EdgeInsets.all(12),
    );
  }

  Future<void> _openPosterPdf() async {
    try {
      final pdfFile = await _createReviewPosterPdf(
        authorName: controller.currentUser?.fullName.trim().isNotEmpty == true
            ? controller.currentUser!.fullName.trim()
            : controller.businessName,
        businessName: controller.businessName,
        title: controller.titleValue,
        description: controller.descriptionValue,
        reviewUrl: controller.reviewUrl,
        shortDisplayUrl: controller.shortDisplayUrl,
        brandColor: controller.brandColor,
        paperSize: controller.selectedPaperSize.value,
        template: controller.selectedTemplate.value,
        showFooter: controller.showFooter.value,
      );

      final openResult = await OpenFilex.open(
        pdfFile.path,
        type: 'application/pdf',
      );

      if (openResult.type == ResultType.done) {
        return;
      }

      final opened = await _launchWithFallbacks(
        Uri.file(pdfFile.path),
        modes: const <LaunchMode>[
          LaunchMode.platformDefault,
          LaunchMode.externalApplication,
        ],
      );
      if (!opened) {
        final resultMessage = openResult.message.trim();
        _showFailure(
          'Open failed',
          resultMessage.isNotEmpty
              ? 'The poster PDF was created, but it could not be opened: $resultMessage'
              : 'The poster PDF was created, but no app was available to open it.',
        );
      }
    } catch (_) {
      _showFailure(
        'PDF failed',
        'The review poster PDF could not be created right now.',
      );
    }
  }

  Future<bool> _launchWithFallbacks(
    Uri uri, {
    List<LaunchMode> modes = const <LaunchMode>[
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
    ],
  }) async {
    for (final mode in modes) {
      try {
        if (await launchUrl(uri, mode: mode)) {
          return true;
        }
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  void _showFailure(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: AppColors.text,
      margin: const EdgeInsets.all(12),
    );
  }

  Uri? _normalizeUri(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = Uri.tryParse(trimmed);
    if (parsed == null) {
      return null;
    }
    if (parsed.hasScheme) {
      return parsed;
    }
    return Uri.tryParse('https://$trimmed');
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.onRefresh, required this.isRefreshing});

  final Future<void> Function() onRefresh;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AuthShellBackButton(size: 40, iconSize: 18),
            Expanded(
              child: Text(
                'Review Poster',
                textAlign: TextAlign.center,
                style: AppTypography.button(
                  fontSize: 18,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 40, height: 40),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Review Poster',
          style: AppTypography.section(
            fontSize: 30,
            color: AppColors.brandBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: AppTypography.body(
              fontSize: 12.8,
              color: AppColors.mutedText,
              height: 1.55,
            ),
            children: [
              const TextSpan(
                text:
                    'Generate a customized poster to encourage customers to leave reviews powered by ',
              ),
              TextSpan(
                text: 'VisibloAI',
                style: AppTypography.body(
                  fontSize: 12.8,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (isRefreshing) ...[
          const SizedBox(height: 10),
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionCardHeader extends StatelessWidget {
  const _SectionCardHeader({
    required this.icon,
    required this.title,
    required this.accentColor,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Color accentColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accentColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: AppTypography.card(
              fontSize: 16.2,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.locations,
    required this.selectedLocation,
    required this.dropdownValue,
    required this.isResolvingReviewUrl,
    required this.hasDirectReviewUrl,
    required this.reviewUrl,
    required this.onLocationChanged,
  });

  final List<BusinessLocationSummary> locations;
  final BusinessLocationSummary? selectedLocation;
  final String? dropdownValue;
  final bool isResolvingReviewUrl;
  final bool hasDirectReviewUrl;
  final String reviewUrl;
  final Future<void> Function(String? value) onLocationChanged;

  @override
  Widget build(BuildContext context) {
    return _PosterShellCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCardHeader(
            icon: Icons.store_mall_directory_outlined,
            title: 'Business Location',
            accentColor: const Color(0xFF47C0D6),
            trailing: isResolvingReviewUrl
                ? Text(
                    'Resolving...',
                    style: AppTypography.label(
                      fontSize: 11.2,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            'Choose the live business location that should drive the Google review QR and poster branding.',
            style: AppTypography.body(
              fontSize: 12.5,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 12),
          if (locations.isEmpty)
            const _EmptyLocationState()
          else ...[
            DropdownButtonFormField<String>(
              key: ValueKey(dropdownValue ?? 'review-poster-location'),
              initialValue: dropdownValue,
              isExpanded: true,
              decoration: _inputDecoration(hintText: 'Select a location'),
              items: locations
                  .map(
                    (location) => DropdownMenuItem<String>(
                      value: location.id,
                      child: Text(
                        location.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          fontSize: 13,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: onLocationChanged,
            ),
            if (selectedLocation != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoPill(
                    icon: Icons.storefront_outlined,
                    label: selectedLocation!.primaryCategory.isEmpty
                        ? 'Google Business location'
                        : selectedLocation!.primaryCategory,
                  ),
                  if (selectedLocation!.displayAddress.isNotEmpty)
                    _InfoPill(
                      icon: Icons.location_on_outlined,
                      label: selectedLocation!.displayAddress,
                    ),
                  if (selectedLocation!.phone.isNotEmpty)
                    _InfoPill(
                      icon: Icons.phone_outlined,
                      label: selectedLocation!.phone,
                    ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 12),
          _ReviewLinkStatusCard(
            reviewUrl: reviewUrl,
            hasDirectReviewUrl: hasDirectReviewUrl,
          ),
        ],
      ),
    );
  }
}

class _DesignCard extends StatelessWidget {
  const _DesignCard({required this.controller});

  final ReviewPosterController controller;

  @override
  Widget build(BuildContext context) {
    return _PosterShellCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCardHeader(
            icon: Icons.design_services_outlined,
            title: 'Design & Format',
            accentColor: const Color(0xFF6EC6F5),
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Paper Size'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReviewPosterPaperSize.values
                .map(
                  (paperSize) => _ChoiceChipButton(
                    label: paperSize.label,
                    selected: controller.selectedPaperSize.value == paperSize,
                    onTap: () => controller.setPaperSize(paperSize),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Brand Color'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ReviewPosterController.brandColors
                .map(
                  (color) => _BrandSwatch(
                    color: color,
                    isSelected:
                        controller.brandColor.toARGB32() == color.toARGB32(),
                    onTap: () => controller.setBrandColor(color),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Display "Powered by VisibloAI" footer',
                  style: AppTypography.body(
                    fontSize: 13.5,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch.adaptive(
                value: controller.showFooter.value,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: const Color(0xFFDDE4EC),
                onChanged: controller.setShowFooter,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PosterContentCard extends StatelessWidget {
  const _PosterContentCard({
    required this.controller,
    required this.onCopy,
    required this.onShareWhatsApp,
  });

  final ReviewPosterController controller;
  final Future<void> Function() onCopy;
  final Future<void> Function() onShareWhatsApp;

  @override
  Widget build(BuildContext context) {
    final actionButtons = <Widget>[
      _SquareActionButton(
        icon: Icons.content_copy_outlined,
        tooltip: 'Copy review link',
        onTap: onCopy,
      ),
      _SquareActionButton(
        onTap: onShareWhatsApp,
        tooltip: 'Share on WhatsApp',
        child: SvgPicture.asset(
          'assets/icons/whatsapp_mark.svg',
          width: 19,
          height: 19,
          colorFilter: const ColorFilter.mode(
            Color(0xFF35B44B),
            BlendMode.srcIn,
          ),
        ),
      ),
    ];

    return _PosterShellCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCardHeader(
            icon: Icons.article_outlined,
            title: 'Poster Content',
            accentColor: const Color(0xFF7FD7E6),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 360) {
                return const _FieldLabel('Share Link');
              }

              return Row(
                children: [
                  const Expanded(child: _FieldLabel('Share Link')),
                  Text(
                    'copy',
                    style: AppTypography.label(
                      fontSize: 10.4,
                      color: const Color(0xFF9AA8BA),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 26),
                  Text(
                    'share',
                    style: AppTypography.label(
                      fontSize: 10.4,
                      color: const Color(0xFF9AA8BA),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 560;
              final inputField = TextField(
                controller: controller.reviewUrlController,
                keyboardType: TextInputType.url,
                decoration: _inputDecoration(
                  hintText: 'Paste your Google review link here...',
                ),
                style: AppTypography.body(
                  fontSize: 13,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w600,
                ),
              );
              final actionRow = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actionButtons,
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    inputField,
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerRight, child: actionRow),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: inputField),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: actionRow,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Poster Title'),
          const SizedBox(height: 8),
          TextField(
            controller: controller.titleController,
            decoration: _inputDecoration(
              hintText: ReviewPosterController.defaultTitle,
            ),
            style: AppTypography.body(
              fontSize: 13,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Description'),
          const SizedBox(height: 8),
          TextField(
            controller: controller.descriptionController,
            maxLines: 3,
            decoration: _inputDecoration(
              hintText: ReviewPosterController.defaultDescription,
            ),
            style: AppTypography.body(
              fontSize: 13,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({required this.onOpenPosterPdf});

  final Future<void> Function() onOpenPosterPdf;

  @override
  Widget build(BuildContext context) {
    return _PosterShellCard(
      backgroundColor: const Color(0xFFFBFEFF),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final content = <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.picture_as_pdf_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to Print?',
                    style: AppTypography.card(
                      fontSize: 16.5,
                      color: AppColors.brandBlue,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Download or print your customized review poster now.',
                    style: AppTypography.body(
                      fontSize: 12.4,
                      color: AppColors.mutedText,
                      height: 1.42,
                    ),
                  ),
                ],
              ),
            ),
          ];

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: content),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onOpenPosterPdf,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(
                      'Open PDF',
                      style: AppTypography.button(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ...content,
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onOpenPosterPdf,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(
                  'Open PDF',
                  style: AppTypography.button(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.controller, required this.onOpenReview});

  final ReviewPosterController controller;
  final Future<void> Function() onOpenReview;

  @override
  Widget build(BuildContext context) {
    final paperSize = controller.selectedPaperSize.value;

    return _PosterShellCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Poster Preview',
            style: AppTypography.card(fontSize: 17, color: AppColors.brandBlue),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final previewWidth = math.min(constraints.maxWidth, 620.0);
              final previewHeight = previewWidth / paperSize.aspectRatio;

              return Center(
                child: GestureDetector(
                  onTap: onOpenReview,
                  child: RepaintBoundary(
                    child: Container(
                      width: previewWidth,
                      height: previewHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5C8FF)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x120A3E6E),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          child: _PosterTemplatePreview(
                            key: ValueKey(
                              '${controller.selectedTemplate.value.name}-${controller.brandColor.toARGB32()}-${controller.showFooter.value}-${controller.titleValue}-${controller.descriptionValue}-${controller.shortDisplayUrl}',
                            ),
                            template: controller.selectedTemplate.value,
                            title: controller.titleValue,
                            description: controller.descriptionValue,
                            businessName: controller.businessName,
                            brandColor: controller.brandColor,
                            shortDisplayUrl: controller.shortDisplayUrl,
                            reviewUrl: controller.reviewUrl,
                            showFooter: controller.showFooter.value,
                            onOpenReview: onOpenReview,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PosterTemplatePreview extends StatelessWidget {
  const _PosterTemplatePreview({
    super.key,
    required this.template,
    required this.title,
    required this.description,
    required this.businessName,
    required this.brandColor,
    required this.shortDisplayUrl,
    required this.reviewUrl,
    required this.showFooter,
    required this.onOpenReview,
  });

  final ReviewPosterTemplate template;
  final String title;
  final String description;
  final String businessName;
  final Color brandColor;
  final String shortDisplayUrl;
  final String reviewUrl;
  final bool showFooter;
  final Future<void> Function() onOpenReview;

  @override
  Widget build(BuildContext context) {
    switch (template) {
      case ReviewPosterTemplate.classic:
        return _ClassicPosterTemplate(
          title: title,
          description: description,
          businessName: businessName,
          brandColor: brandColor,
          shortDisplayUrl: shortDisplayUrl,
          reviewUrl: reviewUrl,
          showFooter: showFooter,
          onOpenReview: onOpenReview,
        );
      case ReviewPosterTemplate.minimal:
        return _MinimalPosterTemplate(
          title: title,
          description: description,
          businessName: businessName,
          brandColor: brandColor,
          shortDisplayUrl: shortDisplayUrl,
          reviewUrl: reviewUrl,
          showFooter: showFooter,
          onOpenReview: onOpenReview,
        );
      case ReviewPosterTemplate.split:
        return _SplitPosterTemplate(
          title: title,
          description: description,
          businessName: businessName,
          brandColor: brandColor,
          shortDisplayUrl: shortDisplayUrl,
          reviewUrl: reviewUrl,
          showFooter: showFooter,
          onOpenReview: onOpenReview,
        );
    }
  }
}

class _SplitPosterTemplate extends StatelessWidget {
  const _SplitPosterTemplate({
    required this.title,
    required this.description,
    required this.businessName,
    required this.brandColor,
    required this.shortDisplayUrl,
    required this.reviewUrl,
    required this.showFooter,
    required this.onOpenReview,
  });

  final String title;
  final String description;
  final String businessName;
  final Color brandColor;
  final String shortDisplayUrl;
  final String reviewUrl;
  final bool showFooter;
  final Future<void> Function() onOpenReview;

  @override
  Widget build(BuildContext context) {
    final softTop = _blendWithWhite(brandColor, 0.82);
    final softBottom = _blendWithWhite(brandColor, 0.96);
    final deepAccent = _blendWithBlack(brandColor, 0.2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxHeight < 760 ||
            constraints.maxWidth < 330 ||
            businessName.length > 28 ||
            shortDisplayUrl.length > 34;
        final ultraCompact =
            constraints.maxHeight < 600 || constraints.maxWidth < 300;
        final horizontalPadding = isCompact ? 18.0 : 24.0;
        final topPadding = ultraCompact
            ? 14.0
            : isCompact
            ? 18.0
            : 24.0;
        final bottomPadding = ultraCompact
            ? 10.0
            : isCompact
            ? 12.0
            : 16.0;
        final qrCardWidth = ultraCompact
            ? 166.0
            : isCompact
            ? 188.0
            : 204.0;
        final qrPadding = ultraCompact
            ? 10.0
            : isCompact
            ? 12.0
            : 16.0;
        final qrHeight = ultraCompact
            ? 128.0
            : isCompact
            ? 146.0
            : 162.0;
        final titleSize = ultraCompact
            ? 17.8
            : isCompact
            ? 19.8
            : 22.4;
        final descriptionSize = ultraCompact
            ? 10.0
            : isCompact
            ? 10.8
            : 11.6;
        final starSize = ultraCompact
            ? 16.2
            : isCompact
            ? 17.6
            : 19.4;
        final businessNameSize = ultraCompact
            ? 11.8
            : isCompact
            ? 12.8
            : 13.6;
        final urlSize = ultraCompact
            ? 9.8
            : isCompact
            ? 10.4
            : 11.2;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [softTop, softBottom, Colors.white, Colors.white],
              stops: const [0, 0.56, 0.56, 1],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              bottomPadding,
            ),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.section(
                    fontSize: titleSize,
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w800,
                    height: 1.16,
                  ),
                ),
                SizedBox(height: isCompact ? 4 : 6),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    fontSize: descriptionSize,
                    color: const Color(0xFF5C6A7D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  height: ultraCompact
                      ? 8
                      : isCompact
                      ? 10
                      : 14,
                ),
                _PosterStepLine(number: '1', label: 'Open your camera app'),
                SizedBox(
                  height: ultraCompact
                      ? 6
                      : isCompact
                      ? 8
                      : 10,
                ),
                _PosterStepLine(number: '2', label: 'Scan the QR code'),
                SizedBox(
                  height: ultraCompact
                      ? 6
                      : isCompact
                      ? 8
                      : 10,
                ),
                _PosterStepLine(number: '3', label: 'Share your thoughts'),
                SizedBox(
                  height: ultraCompact
                      ? 10
                      : isCompact
                      ? 14
                      : 16,
                ),
                Text(
                  'You can also rate us by visiting this link:',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    fontSize: ultraCompact
                        ? 9.8
                        : isCompact
                        ? 10.6
                        : 11.2,
                    color: const Color(0xFF5C6A7D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  height: ultraCompact
                      ? 4
                      : isCompact
                      ? 5
                      : 6,
                ),
                Text(
                  shortDisplayUrl,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label(
                    fontSize: urlSize,
                    color: const Color(0xFF314B66),
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  width: qrCardWidth,
                  padding: EdgeInsets.all(qrPadding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x170A233F),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: qrHeight,
                        child: _PosterQrPreview(reviewUrl: reviewUrl),
                      ),
                      SizedBox(height: isCompact ? 8 : 10),
                      Text(
                        'SCAN CODE',
                        style: AppTypography.label(
                          fontSize: 10.6,
                          color: const Color(0xFF5D6D83),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: ultraCompact
                      ? 10
                      : isCompact
                      ? 14
                      : 16,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(
                    5,
                    (_) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        Icons.star_rounded,
                        size: starSize,
                        color: const Color(0xFFF9C620),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: ultraCompact
                      ? 8
                      : isCompact
                      ? 12
                      : 14,
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ultraCompact ? 10 : 14,
                    vertical: ultraCompact ? 8 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE3EAF3)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D0F2746),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/google_logo.svg',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          businessName,
                          textAlign: TextAlign.center,
                          maxLines: ultraCompact ? 1 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.label(
                            fontSize: businessNameSize,
                            color: deepAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (showFooter && !ultraCompact)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'We partner with VisibloAI for review generation',
                          style: AppTypography.label(
                            fontSize: isCompact ? 9.2 : 9.8,
                            color: const Color(0xFF7E8A9A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        'VisibloAI',
                        style: AppTypography.label(
                          fontSize: isCompact ? 9.6 : 10.2,
                          color: const Color(0xFF58667B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                else if (showFooter)
                  Text(
                    'VisibloAI',
                    style: AppTypography.label(
                      fontSize: 8.8,
                      color: const Color(0xFF58667B),
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

class _ClassicPosterTemplate extends StatelessWidget {
  const _ClassicPosterTemplate({
    required this.title,
    required this.description,
    required this.businessName,
    required this.brandColor,
    required this.shortDisplayUrl,
    required this.reviewUrl,
    required this.showFooter,
    required this.onOpenReview,
  });

  final String title;
  final String description;
  final String businessName;
  final Color brandColor;
  final String shortDisplayUrl;
  final String reviewUrl;
  final bool showFooter;
  final Future<void> Function() onOpenReview;

  @override
  Widget build(BuildContext context) {
    final mutedText = const Color(0xFF1E293B).withValues(alpha: 0.82);
    final softTone = _blendWithWhite(brandColor, 0.84);

    return ColoredBox(
      color: softTone,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.section(
                fontSize: 24,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 12.4,
                color: mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _TemplateStepCard(
                          number: '1',
                          label: 'Open your camera app',
                        ),
                        SizedBox(height: 10),
                        _TemplateStepCard(
                          number: '2',
                          label: 'Scan the QR code',
                        ),
                        SizedBox(height: 10),
                        _TemplateStepCard(
                          number: '3',
                          label: 'Share your thoughts',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x170A233F),
                                blurRadius: 18,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 136,
                                child: _PosterQrPreview(reviewUrl: reviewUrl),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'SCAN CODE',
                                style: AppTypography.label(
                                  fontSize: 10.5,
                                  color: const Color(0xFF475569),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List<Widget>.generate(
                            5,
                            (_) => const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 1.5),
                              child: Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: Color(0xFFFACC15),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    businessName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.card(
                      fontSize: 15,
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    shortDisplayUrl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(
                      fontSize: 11.2,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (showFooter) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'We partner with VisibloAI for review generation',
                      style: AppTypography.label(
                        fontSize: 9.8,
                        color: const Color(0xFF1E293B).withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    'VisibloAI',
                    style: AppTypography.label(
                      fontSize: 10.8,
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MinimalPosterTemplate extends StatelessWidget {
  const _MinimalPosterTemplate({
    required this.title,
    required this.description,
    required this.businessName,
    required this.brandColor,
    required this.shortDisplayUrl,
    required this.reviewUrl,
    required this.showFooter,
    required this.onOpenReview,
  });

  final String title;
  final String description;
  final String businessName;
  final Color brandColor;
  final String shortDisplayUrl;
  final String reviewUrl;
  final bool showFooter;
  final Future<void> Function() onOpenReview;

  @override
  Widget build(BuildContext context) {
    final softTone = _blendWithWhite(brandColor, 0.9);

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 26, 26, 18),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.section(
                fontSize: 24,
                color: brandColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 12.2,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: softTone,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: SizedBox(
                  width: 168,
                  height: 168,
                  child: _PosterQrPreview(reviewUrl: reviewUrl),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Expanded(
                  child: _MinimalStepBubble(number: '1', label: 'Scan'),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _MinimalStepBubble(number: '2', label: 'Rate'),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _MinimalStepBubble(number: '3', label: 'Share'),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Text(
                    businessName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.card(
                      fontSize: 14,
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shortDisplayUrl,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(
                      fontSize: 11.2,
                      color: brandColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (showFooter) ...[
              const SizedBox(height: 14),
              Text(
                'Powered by VisibloAI',
                style: AppTypography.label(
                  fontSize: 10.5,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PosterStepLine extends StatelessWidget {
  const _PosterStepLine({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Color(0xFFE9F1F8),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: AppTypography.label(
              fontSize: 10.2,
              color: Color(0xFF375067),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppTypography.body(
              fontSize: 11.6,
              color: const Color(0xFF2D4057),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _TemplateStepCard extends StatelessWidget {
  const _TemplateStepCard({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: AppTypography.label(
              fontSize: 11.8,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.body(
              fontSize: 11.8,
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MinimalStepBubble extends StatelessWidget {
  const _MinimalStepBubble({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 1.8),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: AppTypography.label(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.label(
            fontSize: 11,
            color: const Color(0xFF475569),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ReviewLinkStatusCard extends StatelessWidget {
  const _ReviewLinkStatusCard({
    required this.reviewUrl,
    required this.hasDirectReviewUrl,
  });

  final String reviewUrl;
  final bool hasDirectReviewUrl;

  @override
  Widget build(BuildContext context) {
    final isDirect = hasDirectReviewUrl;
    final headingColor = isDirect
        ? const Color(0xFF196F43)
        : const Color(0xFF8A5B12);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDirect ? const Color(0xFFF0FCF7) : const Color(0xFFFFFAEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDirect ? const Color(0xFFCFEEDB) : const Color(0xFFF4DDA2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isDirect
                    ? Icons.check_circle_outline
                    : Icons.info_outline_rounded,
                color: isDirect
                    ? const Color(0xFF1B9E5A)
                    : const Color(0xFFB7791F),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isDirect
                      ? 'Direct "Write a Review" link ready'
                      : 'Fallback Google Maps search link',
                  softWrap: true,
                  style: AppTypography.button(
                    fontSize: 12.2,
                    color: headingColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isDirect
                ? 'The QR opens the Google review form directly for this business.'
                : 'No direct review URL was found yet, so the QR opens a Google Maps search fallback. Sync or paste a direct review link if you have one.',
            style: AppTypography.body(
              fontSize: 12.2,
              color: headingColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            reviewUrl,
            minLines: 1,
            maxLines: 3,
            enableInteractiveSelection: true,
            style: AppTypography.label(
              fontSize: 11,
              color: headingColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterQrPreview extends StatelessWidget {
  const _PosterQrPreview({required this.reviewUrl});

  final String reviewUrl;

  @override
  Widget build(BuildContext context) {
    final qrUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=320x320&margin=0&data=${Uri.encodeComponent(reviewUrl)}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final dimension = math.min(constraints.maxWidth, constraints.maxHeight);

        return Center(
          child: SizedBox.square(
            dimension: dimension,
            child: Image.network(
              qrUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }
                return const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return CustomPaint(
                  painter: _FallbackQrPainter(reviewUrl),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _FallbackQrPainter extends CustomPainter {
  const _FallbackQrPainter(this.data);

  final String data;

  @override
  void paint(Canvas canvas, Size size) {
    const modules = 29;
    final cellSize = size.shortestSide / modules;
    final darkPaint = Paint()..color = const Color(0xFF14181F);
    final lightPaint = Paint()..color = Colors.white;

    canvas.drawRect(Offset.zero & size, lightPaint);

    bool isInFinder(int x, int y, int startX, int startY) {
      return x >= startX && x < startX + 7 && y >= startY && y < startY + 7;
    }

    void drawModule(int x, int y) {
      canvas.drawRect(
        Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
        darkPaint,
      );
    }

    void drawFinder(int startX, int startY) {
      for (var y = 0; y < 7; y++) {
        for (var x = 0; x < 7; x++) {
          final isBorder = x == 0 || x == 6 || y == 0 || y == 6;
          final isCenter = x >= 2 && x <= 4 && y >= 2 && y <= 4;
          if (isBorder || isCenter) {
            drawModule(startX + x, startY + y);
          }
        }
      }
    }

    drawFinder(0, 0);
    drawFinder(modules - 7, 0);
    drawFinder(0, modules - 7);

    for (var index = 8; index < modules - 8; index++) {
      if (index.isEven) {
        drawModule(6, index);
        drawModule(index, 6);
      }
    }

    final seed = data.codeUnits.fold<int>(
      0x2A2F3A,
      (value, element) => ((value * 33) ^ element) & 0x7fffffff,
    );

    for (var y = 0; y < modules; y++) {
      for (var x = 0; x < modules; x++) {
        final reserved =
            isInFinder(x, y, 0, 0) ||
            isInFinder(x, y, modules - 7, 0) ||
            isInFinder(x, y, 0, modules - 7) ||
            x == 6 ||
            y == 6;
        if (reserved) {
          continue;
        }

        final bit = ((seed + (x * 97) + (y * 57) + (x * y * 13)) >> 2) & 1;
        final altBit = ((seed ^ (x * 911) ^ (y * 353) ^ (x + y)) >> 4) & 1;
        if (bit == 1 || (x + y).isEven && altBit == 1) {
          drawModule(x, y);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FallbackQrPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _PosterShellCard extends StatelessWidget {
  const _PosterShellCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = Colors.white,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7EEF6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F2746),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.message,
    required this.onDismiss,
    this.isError = false,
  });

  final String message;
  final VoidCallback onDismiss;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final foreground = isError
        ? const Color(0xFF9F2F2F)
        : const Color(0xFF196F43);
    final background = isError
        ? const Color(0xFFFFF2F2)
        : const Color(0xFFEFFBF4);
    final border = isError ? const Color(0xFFFFD6D6) : const Color(0xFFCFEEDB);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            color: foreground,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(
                fontSize: 12.6,
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded, color: foreground, size: 18),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.label(
        fontSize: 10.8,
        color: const Color(0xFF7E8BA0),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ChoiceChipButton extends StatelessWidget {
  const _ChoiceChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAFBFA) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFD7DEE7),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.label(
              fontSize: 12.4,
              color: selected ? AppColors.primaryDark : const Color(0xFF6F7C90),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandSwatch extends StatelessWidget {
  const _BrandSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? const Color(0xFFDBF4F2) : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: isSelected
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

class _SquareActionButton extends StatelessWidget {
  const _SquareActionButton({
    required this.onTap,
    this.icon,
    this.child,
    this.tooltip,
  }) : assert(icon != null || child != null);

  final Future<void> Function() onTap;
  final IconData? icon;
  final Widget? child;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD6E7ED)),
          ),
          child: Center(
            child:
                child ?? Icon(icon, size: 19, color: const Color(0xFF47C0D6)),
          ),
        ),
      ),
    );

    if ((tooltip ?? '').trim().isEmpty) {
      return button;
    }

    return Tooltip(message: tooltip!, child: button);
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4EDF6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: AppTypography.label(
                fontSize: 11.2,
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLocationState extends StatelessWidget {
  const _EmptyLocationState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAF2FA)),
      ),
      child: Text(
        'No business locations were returned yet. The poster will fall back to a search-based review URL until a location is connected.',
        style: AppTypography.body(
          fontSize: 12.4,
          color: AppColors.mutedText,
          height: 1.42,
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTypography.body(
      fontSize: 12.8,
      color: const Color(0xFF90A0B2),
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: const Color(0xFFFCFDFF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD8E4EE)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD8E4EE)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
    ),
  );
}

Color _blendWithWhite(Color color, double amount) {
  return Color.lerp(color, Colors.white, amount) ?? color;
}

Color _blendWithBlack(Color color, double amount) {
  return Color.lerp(color, const Color(0xFF0F172A), amount) ?? color;
}

Future<File> _createReviewPosterPdf({
  required String authorName,
  required String businessName,
  required String title,
  required String description,
  required String reviewUrl,
  required String shortDisplayUrl,
  required Color brandColor,
  required ReviewPosterPaperSize paperSize,
  required ReviewPosterTemplate template,
  required bool showFooter,
}) async {
  final directory = await getTemporaryDirectory();
  final safeBusinessName = businessName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final fileName = safeBusinessName.isEmpty
      ? 'review-poster.pdf'
      : '$safeBusinessName-review-poster.pdf';
  final file = File('${directory.path}/$fileName');

  final bytes = _PosterPdfBuilder.build(
    authorName: authorName,
    businessName: businessName,
    title: title,
    description: description,
    reviewUrl: reviewUrl,
    shortDisplayUrl: shortDisplayUrl,
    brandColor: brandColor,
    paperSize: paperSize,
    template: template,
    showFooter: showFooter,
  );
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

class _PosterPdfBuilder {
  static List<int> build({
    required String authorName,
    required String businessName,
    required String title,
    required String description,
    required String reviewUrl,
    required String shortDisplayUrl,
    required Color brandColor,
    required ReviewPosterPaperSize paperSize,
    required ReviewPosterTemplate template,
    required bool showFooter,
  }) {
    final pageSize = paperSize.pageSize;
    final content = StringBuffer();
    final width = pageSize.width;
    final height = pageSize.height;
    final outerPadding = math.min(40.0, width * 0.07);
    final posterX = outerPadding;
    final posterY = outerPadding;
    final posterWidth = width - (outerPadding * 2);
    final posterHeight = height - (outerPadding * 2);
    final posterTop = posterY + posterHeight;
    final brand = _PdfColor.fromColor(brandColor);

    _fillRect(content, 0, 0, width, height, const _PdfColor(1, 1, 1));

    switch (template) {
      case ReviewPosterTemplate.split:
        _drawSplitTemplate(
          content,
          posterX: posterX,
          posterY: posterY,
          posterWidth: posterWidth,
          posterHeight: posterHeight,
          posterTop: posterTop,
          title: title,
          description: description,
          businessName: businessName,
          shortDisplayUrl: shortDisplayUrl,
          reviewUrl: reviewUrl,
          brand: brand,
          showFooter: showFooter,
        );
      case ReviewPosterTemplate.classic:
        _drawClassicTemplate(
          content,
          posterX: posterX,
          posterY: posterY,
          posterWidth: posterWidth,
          posterHeight: posterHeight,
          posterTop: posterTop,
          title: title,
          description: description,
          businessName: businessName,
          shortDisplayUrl: shortDisplayUrl,
          reviewUrl: reviewUrl,
          brand: brand,
          showFooter: showFooter,
        );
      case ReviewPosterTemplate.minimal:
        _drawMinimalTemplate(
          content,
          posterX: posterX,
          posterY: posterY,
          posterWidth: posterWidth,
          posterHeight: posterHeight,
          posterTop: posterTop,
          title: title,
          description: description,
          businessName: businessName,
          shortDisplayUrl: shortDisplayUrl,
          reviewUrl: reviewUrl,
          brand: brand,
          showFooter: showFooter,
        );
    }

    final pdf = _SimplePdfDocument(
      width: width,
      height: height,
      content: content.toString(),
      linkUrl: reviewUrl,
      linkRect: Rect.fromLTWH(
        posterX + 20,
        posterY + 20,
        posterWidth - 40,
        posterHeight - 40,
      ),
      title: '$businessName review poster',
      author: authorName,
    );
    return pdf.build();
  }

  static void _drawSplitTemplate(
    StringBuffer content, {
    required double posterX,
    required double posterY,
    required double posterWidth,
    required double posterHeight,
    required double posterTop,
    required String title,
    required String description,
    required String businessName,
    required String shortDisplayUrl,
    required String reviewUrl,
    required _PdfColor brand,
    required bool showFooter,
  }) {
    _fillRect(
      content,
      posterX,
      posterY,
      posterWidth,
      posterHeight,
      const _PdfColor(1, 1, 1),
    );
    _fillRect(
      content,
      posterX,
      posterY + (posterHeight * 0.55),
      posterWidth,
      posterHeight * 0.45,
      brand,
    );

    final wrappedTitle = _wrapText(
      title,
      fontSize: math.min(26.0, posterWidth * 0.07),
      maxWidth: posterWidth - 60,
      charWidthFactor: 0.56,
    );
    final wrappedDescription = _wrapText(
      description,
      fontSize: math.min(13.0, posterWidth * 0.033),
      maxWidth: posterWidth - 80,
      charWidthFactor: 0.5,
    );

    _drawCenteredLines(
      content,
      lines: wrappedTitle,
      centerX: posterX + (posterWidth / 2),
      topY: posterTop - 40,
      fontSize: math.min(26.0, posterWidth * 0.07),
      color: const _PdfColor(0.07, 0.15, 0.25),
      fontName: 'F2',
      leading: 29,
    );
    _drawCenteredLines(
      content,
      lines: wrappedDescription,
      centerX: posterX + (posterWidth / 2),
      topY: posterTop - 100,
      fontSize: math.min(13.0, posterWidth * 0.033),
      color: const _PdfColor(0.18, 0.23, 0.32),
      fontName: 'F1',
      leading: 16,
    );

    final qrBoxWidth = math.min(230.0, posterWidth * 0.5);
    final qrBoxHeight = qrBoxWidth + 40;
    final qrBoxX = posterX + (posterWidth - qrBoxWidth) / 2;
    final qrBoxY = posterY + (posterHeight * 0.3);
    _fillRect(
      content,
      qrBoxX,
      qrBoxY,
      qrBoxWidth,
      qrBoxHeight,
      const _PdfColor(1, 1, 1),
    );
    _drawPseudoQr(
      content,
      data: reviewUrl,
      x: qrBoxX + 18,
      y: qrBoxY + 28,
      size: qrBoxWidth - 36,
      color: const _PdfColor(0.09, 0.1, 0.12),
    );
    _drawCenteredText(
      content,
      text: 'SCAN ME',
      centerX: qrBoxX + (qrBoxWidth / 2),
      baselineY: qrBoxY + 12,
      fontSize: 10.5,
      color: const _PdfColor(0.35, 0.42, 0.51),
      fontName: 'F2',
    );

    final businessY = posterY + 82;
    _drawCenteredText(
      content,
      text: businessName,
      centerX: posterX + (posterWidth / 2),
      baselineY: businessY,
      fontSize: 15,
      color: const _PdfColor(0.06, 0.1, 0.18),
      fontName: 'F2',
    );
    _drawCenteredText(
      content,
      text: shortDisplayUrl,
      centerX: posterX + (posterWidth / 2),
      baselineY: businessY - 18,
      fontSize: 10.6,
      color: const _PdfColor(0.39, 0.45, 0.54),
      fontName: 'F2',
    );

    _drawStars(
      content,
      centerX: posterX + (posterWidth / 2),
      baselineY: posterY + 118,
      spacing: 22,
      size: 18,
    );

    if (showFooter) {
      _drawCenteredText(
        content,
        text: 'Created with VisibloAI',
        centerX: posterX + (posterWidth / 2),
        baselineY: posterY + 18,
        fontSize: 9.6,
        color: const _PdfColor(0.58, 0.64, 0.72),
        fontName: 'F2',
      );
    }
  }

  static void _drawClassicTemplate(
    StringBuffer content, {
    required double posterX,
    required double posterY,
    required double posterWidth,
    required double posterHeight,
    required double posterTop,
    required String title,
    required String description,
    required String businessName,
    required String shortDisplayUrl,
    required String reviewUrl,
    required _PdfColor brand,
    required bool showFooter,
  }) {
    _fillRect(content, posterX, posterY, posterWidth, posterHeight, brand);

    final titleSize = math.min(24.0, posterWidth * 0.065);
    final wrappedTitle = _wrapText(
      title,
      fontSize: titleSize,
      maxWidth: posterWidth - 56,
      charWidthFactor: 0.56,
    );
    final wrappedDescription = _wrapText(
      description,
      fontSize: 12.4,
      maxWidth: posterWidth - 70,
      charWidthFactor: 0.5,
    );

    _drawCenteredLines(
      content,
      lines: wrappedTitle,
      centerX: posterX + (posterWidth / 2),
      topY: posterTop - 42,
      fontSize: titleSize,
      color: const _PdfColor(0.06, 0.1, 0.18),
      fontName: 'F2',
      leading: titleSize * 1.15,
    );
    _drawCenteredLines(
      content,
      lines: wrappedDescription,
      centerX: posterX + (posterWidth / 2),
      topY: posterTop - 94,
      fontSize: 12.4,
      color: const _PdfColor(0.13, 0.18, 0.26),
      fontName: 'F1',
      leading: 15.2,
    );

    final qrBoxWidth = math.min(210.0, posterWidth * 0.42);
    final qrBoxHeight = qrBoxWidth + 34;
    final qrBoxX = posterX + posterWidth - qrBoxWidth - 24;
    final qrBoxY = posterY + posterHeight * 0.34;
    _fillRect(
      content,
      qrBoxX,
      qrBoxY,
      qrBoxWidth,
      qrBoxHeight,
      const _PdfColor(1, 1, 1),
    );
    _drawPseudoQr(
      content,
      data: reviewUrl,
      x: qrBoxX + 16,
      y: qrBoxY + 24,
      size: qrBoxWidth - 32,
      color: const _PdfColor(0.09, 0.1, 0.12),
    );
    _drawCenteredText(
      content,
      text: 'SCAN CODE',
      centerX: qrBoxX + (qrBoxWidth / 2),
      baselineY: qrBoxY + 10,
      fontSize: 9.8,
      color: const _PdfColor(0.29, 0.34, 0.4),
      fontName: 'F2',
    );

    final steps = <String>[
      'Open your camera app',
      'Scan the QR code',
      'Share your thoughts',
    ];
    final leftX = posterX + 28;
    final stepTop = qrBoxY + qrBoxHeight - 10;
    for (var index = 0; index < steps.length; index++) {
      final topY = stepTop - (index * 34);
      _fillRect(content, leftX, topY, 18, 18, const _PdfColor(0.06, 0.1, 0.18));
      _drawCenteredText(
        content,
        text: '${index + 1}',
        centerX: leftX + 9,
        baselineY: topY + 4.2,
        fontSize: 8.4,
        color: const _PdfColor(1, 1, 1),
        fontName: 'F2',
      );
      _drawText(
        content,
        text: steps[index],
        x: leftX + 28,
        baselineY: topY + 3.8,
        fontSize: 11.2,
        color: const _PdfColor(0.06, 0.1, 0.18),
        fontName: 'F2',
      );
    }

    _drawStars(
      content,
      centerX: qrBoxX + (qrBoxWidth / 2),
      baselineY: qrBoxY - 24,
      spacing: 18,
      size: 15,
    );

    final cardX = posterX + 24;
    final cardY = posterY + 30;
    final cardWidth = posterWidth - 48;
    _fillRect(content, cardX, cardY, cardWidth, 52, const _PdfColor(1, 1, 1));
    _drawText(
      content,
      text: businessName,
      x: cardX + 18,
      baselineY: cardY + 29,
      fontSize: 13.8,
      color: const _PdfColor(0.06, 0.1, 0.18),
      fontName: 'F2',
    );
    _drawText(
      content,
      text: shortDisplayUrl,
      x: cardX + 18,
      baselineY: cardY + 14,
      fontSize: 10.2,
      color: const _PdfColor(0.39, 0.45, 0.54),
      fontName: 'F2',
    );

    if (showFooter) {
      _drawText(
        content,
        text: 'We partner with VisibloAI for review generation',
        x: posterX + 12,
        baselineY: posterY + 14,
        fontSize: 8.4,
        color: const _PdfColor(0.13, 0.18, 0.26),
        fontName: 'F1',
      );
      _drawText(
        content,
        text: 'VisibloAI',
        x: posterX + posterWidth - 50,
        baselineY: posterY + 14,
        fontSize: 8.8,
        color: const _PdfColor(0.06, 0.1, 0.18),
        fontName: 'F2',
      );
    }
  }

  static void _drawMinimalTemplate(
    StringBuffer content, {
    required double posterX,
    required double posterY,
    required double posterWidth,
    required double posterHeight,
    required double posterTop,
    required String title,
    required String description,
    required String businessName,
    required String shortDisplayUrl,
    required String reviewUrl,
    required _PdfColor brand,
    required bool showFooter,
  }) {
    _fillRect(
      content,
      posterX,
      posterY,
      posterWidth,
      posterHeight,
      const _PdfColor(1, 1, 1),
    );
    final titleSize = math.min(24.0, posterWidth * 0.065);
    final wrappedTitle = _wrapText(
      title,
      fontSize: titleSize,
      maxWidth: posterWidth - 56,
      charWidthFactor: 0.56,
    );
    final wrappedDescription = _wrapText(
      description,
      fontSize: 12.2,
      maxWidth: posterWidth - 72,
      charWidthFactor: 0.5,
    );

    _drawCenteredLines(
      content,
      lines: wrappedTitle,
      centerX: posterX + (posterWidth / 2),
      topY: posterTop - 44,
      fontSize: titleSize,
      color: brand,
      fontName: 'F2',
      leading: titleSize * 1.14,
    );
    _drawCenteredLines(
      content,
      lines: wrappedDescription,
      centerX: posterX + (posterWidth / 2),
      topY: posterTop - 92,
      fontSize: 12.2,
      color: const _PdfColor(0.39, 0.45, 0.54),
      fontName: 'F1',
      leading: 15,
    );

    final qrFrameSize = math.min(260.0, posterWidth * 0.5);
    final qrFrameX = posterX + (posterWidth - qrFrameSize) / 2;
    final qrFrameY = posterY + posterHeight * 0.46;
    _fillRect(content, qrFrameX, qrFrameY, qrFrameSize, qrFrameSize, brand);
    _fillRect(
      content,
      qrFrameX + 18,
      qrFrameY + 18,
      qrFrameSize - 36,
      qrFrameSize - 36,
      const _PdfColor(1, 1, 1),
    );
    _drawPseudoQr(
      content,
      data: reviewUrl,
      x: qrFrameX + 32,
      y: qrFrameY + 34,
      size: qrFrameSize - 64,
      color: brand,
    );

    final stepLabels = <String>['Scan', 'Rate', 'Share'];
    final stepY = qrFrameY - 78;
    final stepWidth = (posterWidth - 72) / 3;
    for (var index = 0; index < stepLabels.length; index++) {
      final stepX = posterX + 20 + (index * (stepWidth + 16));
      _drawCircle(
        content,
        centerX: stepX + (stepWidth / 2),
        centerY: stepY + 16,
        radius: 13,
        strokeColor: brand,
        strokeWidth: 1.4,
      );
      _drawCenteredText(
        content,
        text: '${index + 1}',
        centerX: stepX + (stepWidth / 2),
        baselineY: stepY + 11,
        fontSize: 9.6,
        color: brand,
        fontName: 'F2',
      );
      _drawCenteredText(
        content,
        text: stepLabels[index],
        centerX: stepX + (stepWidth / 2),
        baselineY: stepY - 10,
        fontSize: 10.2,
        color: const _PdfColor(0.29, 0.34, 0.4),
        fontName: 'F2',
      );
    }

    final badgeWidth = math.min(260.0, posterWidth - 80);
    final badgeX = posterX + (posterWidth - badgeWidth) / 2;
    final badgeY = posterY + 34;
    _fillRect(
      content,
      badgeX,
      badgeY,
      badgeWidth,
      42,
      const _PdfColor(0.97, 0.98, 0.99),
    );
    _drawCenteredText(
      content,
      text: businessName,
      centerX: badgeX + (badgeWidth / 2),
      baselineY: badgeY + 24,
      fontSize: 13.2,
      color: const _PdfColor(0.06, 0.1, 0.18),
      fontName: 'F2',
    );
    _drawCenteredText(
      content,
      text: shortDisplayUrl,
      centerX: badgeX + (badgeWidth / 2),
      baselineY: badgeY + 10,
      fontSize: 10,
      color: brand,
      fontName: 'F2',
    );

    if (showFooter) {
      _drawCenteredText(
        content,
        text: 'Powered by VisibloAI',
        centerX: posterX + (posterWidth / 2),
        baselineY: posterY + 14,
        fontSize: 9.4,
        color: const _PdfColor(0.58, 0.64, 0.72),
        fontName: 'F2',
      );
    }
  }

  static void _fillRect(
    StringBuffer content,
    double x,
    double y,
    double width,
    double height,
    _PdfColor color,
  ) {
    content
      ..writeln('${color.fill} rg')
      ..writeln(
        '${_pdfNum(x)} ${_pdfNum(y)} ${_pdfNum(width)} ${_pdfNum(height)} re f',
      );
  }

  static void _drawCircle(
    StringBuffer content, {
    required double centerX,
    required double centerY,
    required double radius,
    required _PdfColor strokeColor,
    required double strokeWidth,
  }) {
    final control = radius * 0.5522847498;
    content
      ..writeln('${strokeColor.fill} RG')
      ..writeln('${_pdfNum(strokeWidth)} w')
      ..writeln(
        '${_pdfNum(centerX)} ${_pdfNum(centerY + radius)} m '
        '${_pdfNum(centerX + control)} ${_pdfNum(centerY + radius)} ${_pdfNum(centerX + radius)} ${_pdfNum(centerY + control)} ${_pdfNum(centerX + radius)} ${_pdfNum(centerY)} c '
        '${_pdfNum(centerX + radius)} ${_pdfNum(centerY - control)} ${_pdfNum(centerX + control)} ${_pdfNum(centerY - radius)} ${_pdfNum(centerX)} ${_pdfNum(centerY - radius)} c '
        '${_pdfNum(centerX - control)} ${_pdfNum(centerY - radius)} ${_pdfNum(centerX - radius)} ${_pdfNum(centerY - control)} ${_pdfNum(centerX - radius)} ${_pdfNum(centerY)} c '
        '${_pdfNum(centerX - radius)} ${_pdfNum(centerY + control)} ${_pdfNum(centerX - control)} ${_pdfNum(centerY + radius)} ${_pdfNum(centerX)} ${_pdfNum(centerY + radius)} c S',
      );
  }

  static void _drawText(
    StringBuffer content, {
    required String text,
    required double x,
    required double baselineY,
    required double fontSize,
    required _PdfColor color,
    required String fontName,
  }) {
    final safeText = _pdfText(text);
    if (safeText.isEmpty) {
      return;
    }
    content
      ..writeln('BT')
      ..writeln('/$fontName ${_pdfNum(fontSize)} Tf')
      ..writeln('${color.fill} rg')
      ..writeln('1 0 0 1 ${_pdfNum(x)} ${_pdfNum(baselineY)} Tm ($safeText) Tj')
      ..writeln('ET');
  }

  static void _drawCenteredText(
    StringBuffer content, {
    required String text,
    required double centerX,
    required double baselineY,
    required double fontSize,
    required _PdfColor color,
    required String fontName,
  }) {
    final safeText = _pdfText(text);
    if (safeText.isEmpty) {
      return;
    }
    final estimatedWidth = safeText.length * fontSize * 0.52;
    _drawText(
      content,
      text: safeText,
      x: centerX - (estimatedWidth / 2),
      baselineY: baselineY,
      fontSize: fontSize,
      color: color,
      fontName: fontName,
    );
  }

  static double _drawCenteredLines(
    StringBuffer content, {
    required List<String> lines,
    required double centerX,
    required double topY,
    required double fontSize,
    required _PdfColor color,
    required String fontName,
    required double leading,
  }) {
    for (var index = 0; index < lines.length; index++) {
      _drawCenteredText(
        content,
        text: lines[index],
        centerX: centerX,
        baselineY: topY - (index * leading) - fontSize,
        fontSize: fontSize,
        color: color,
        fontName: fontName,
      );
    }
    return topY - (lines.length * leading);
  }

  static void _drawStars(
    StringBuffer content, {
    required double centerX,
    required double baselineY,
    required double spacing,
    required double size,
  }) {
    final startX = centerX - ((spacing * 2));
    for (var index = 0; index < 5; index++) {
      _drawText(
        content,
        text: '*',
        x: startX + (index * spacing),
        baselineY: baselineY,
        fontSize: size,
        color: const _PdfColor(1, 0.83, 0.19),
        fontName: 'F2',
      );
    }
  }

  static void _drawPseudoQr(
    StringBuffer content, {
    required String data,
    required double x,
    required double y,
    required double size,
    required _PdfColor color,
  }) {
    const modules = 29;
    final cellSize = size / modules;

    bool isInFinder(int cellX, int cellY, int startX, int startY) {
      return cellX >= startX &&
          cellX < startX + 7 &&
          cellY >= startY &&
          cellY < startY + 7;
    }

    void drawModule(int cellX, int cellY) {
      final moduleX = x + (cellX * cellSize);
      final moduleY = y + ((modules - cellY - 1) * cellSize);
      _fillRect(content, moduleX, moduleY, cellSize, cellSize, color);
    }

    void drawFinder(int startX, int startY) {
      for (var cellY = 0; cellY < 7; cellY++) {
        for (var cellX = 0; cellX < 7; cellX++) {
          final isBorder = cellX == 0 || cellX == 6 || cellY == 0 || cellY == 6;
          final isCenter = cellX >= 2 && cellX <= 4 && cellY >= 2 && cellY <= 4;
          if (isBorder || isCenter) {
            drawModule(startX + cellX, startY + cellY);
          }
        }
      }
    }

    drawFinder(0, 0);
    drawFinder(modules - 7, 0);
    drawFinder(0, modules - 7);

    for (var index = 8; index < modules - 8; index++) {
      if (index.isEven) {
        drawModule(6, index);
        drawModule(index, 6);
      }
    }

    final seed = data.codeUnits.fold<int>(
      0x2A2F3A,
      (value, element) => ((value * 33) ^ element) & 0x7fffffff,
    );

    for (var cellY = 0; cellY < modules; cellY++) {
      for (var cellX = 0; cellX < modules; cellX++) {
        final reserved =
            isInFinder(cellX, cellY, 0, 0) ||
            isInFinder(cellX, cellY, modules - 7, 0) ||
            isInFinder(cellX, cellY, 0, modules - 7) ||
            cellX == 6 ||
            cellY == 6;
        if (reserved) {
          continue;
        }

        final bit =
            ((seed + (cellX * 97) + (cellY * 57) + (cellX * cellY * 13)) >> 2) &
            1;
        final altBit =
            ((seed ^ (cellX * 911) ^ (cellY * 353) ^ (cellX + cellY)) >> 4) & 1;
        if (bit == 1 || (cellX + cellY).isEven && altBit == 1) {
          drawModule(cellX, cellY);
        }
      }
    }
  }

  static List<String> _wrapText(
    String text, {
    required double fontSize,
    required double maxWidth,
    double charWidthFactor = 0.52,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const [''];
    }

    final words = trimmed.split(RegExp(r'\s+'));
    final lines = <String>[];
    final buffer = StringBuffer();

    for (final word in words) {
      final candidate = buffer.isEmpty ? word : '${buffer.toString()} $word';
      final candidateWidth = candidate.length * fontSize * charWidthFactor;
      if (candidateWidth <= maxWidth || buffer.isEmpty) {
        buffer
          ..clear()
          ..write(candidate);
      } else {
        lines.add(buffer.toString());
        buffer
          ..clear()
          ..write(word);
      }
    }

    if (buffer.isNotEmpty) {
      lines.add(buffer.toString());
    }
    return lines;
  }

  static String _pdfNum(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  static String _pdfText(String input) {
    final safeAscii = input.runes
        .map(
          (rune) => rune >= 32 && rune <= 126 ? String.fromCharCode(rune) : '?',
        )
        .join();
    return safeAscii
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
  }
}

class _SimplePdfDocument {
  const _SimplePdfDocument({
    required this.width,
    required this.height,
    required this.content,
    required this.linkUrl,
    required this.linkRect,
    required this.title,
    required this.author,
  });

  final double width;
  final double height;
  final String content;
  final String linkUrl;
  final Rect linkRect;
  final String title;
  final String author;

  List<int> build() {
    final objects = <String>[
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
      '''
<< /Type /Page /Parent 2 0 R
/MediaBox [0 0 ${_PosterPdfBuilder._pdfNum(width)} ${_PosterPdfBuilder._pdfNum(height)}]
/Resources << /Font << /F1 4 0 R /F2 5 0 R >> >>
/Contents 6 0 R
/Annots [7 0 R]
>>''',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>',
      '<< /Length ${content.length} >>\nstream\n$content\nendstream',
      '''
<< /Type /Annot
/Subtype /Link
/Rect [${_PosterPdfBuilder._pdfNum(linkRect.left)} ${_PosterPdfBuilder._pdfNum(linkRect.top)} ${_PosterPdfBuilder._pdfNum(linkRect.right)} ${_PosterPdfBuilder._pdfNum(linkRect.bottom)}]
/Border [0 0 0]
/A << /S /URI /URI (${_PosterPdfBuilder._pdfText(linkUrl)}) >>
>>''',
      '''
<< /Title (${_PosterPdfBuilder._pdfText(title)})
/Author (${_PosterPdfBuilder._pdfText(author)})
/Producer (VisibloAI)
>>''',
    ];

    final buffer = StringBuffer('%PDF-1.4\n');
    final offsets = <int>[0];

    for (var index = 0; index < objects.length; index++) {
      offsets.add(buffer.length);
      buffer.write('${index + 1} 0 obj\n${objects[index]}\nendobj\n');
    }

    final xrefOffset = buffer.length;
    buffer.write('xref\n0 ${objects.length + 1}\n');
    buffer.write('0000000000 65535 f \n');
    for (var index = 1; index < offsets.length; index++) {
      buffer.write('${offsets[index].toString().padLeft(10, '0')} 00000 n \n');
    }
    buffer.write(
      'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R /Info 8 0 R >>\n',
    );
    buffer.write('startxref\n$xrefOffset\n%%EOF');

    return buffer.toString().codeUnits;
  }
}

class _PdfColor {
  const _PdfColor(this.red, this.green, this.blue);

  factory _PdfColor.fromColor(Color color) {
    return _PdfColor(color.r, color.g, color.b);
  }

  final double red;
  final double green;
  final double blue;

  String get fill =>
      '${_PosterPdfBuilder._pdfNum(red)} ${_PosterPdfBuilder._pdfNum(green)} ${_PosterPdfBuilder._pdfNum(blue)}';
}
