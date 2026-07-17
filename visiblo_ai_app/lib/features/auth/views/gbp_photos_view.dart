import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/gbp_media.dart';
import '../models/test_account.dart';
import '../widgets/auth_navigation_shell.dart';
import '../widgets/visiblo_brand_wordmark.dart';

enum _PhotosFilter { published, scheduled }

class GbpPhotosView extends StatelessWidget {
  const GbpPhotosView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthNavigationShell(
      currentTab: AuthTab.home,
      backgroundColor: const Color(0xFFF5F7FB),
      child: _GbpPhotosContent(controller: Get.find<OnboardingController>()),
    );
  }
}

class _GbpPhotosContent extends StatefulWidget {
  const _GbpPhotosContent({required this.controller});

  final OnboardingController controller;

  @override
  State<_GbpPhotosContent> createState() => _GbpPhotosContentState();
}

class _GbpPhotosContentState extends State<_GbpPhotosContent> {
  _PhotosFilter _selectedFilter = _PhotosFilter.published;
  bool _isUploadingPhotos = false;
  String? _busyPhotoPath;
  int _visiblePhotoLimit = 20;

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Get.back();
      return;
    }
    Get.offNamed(AppRoutes.dashboard);
  }

  Future<void> _uploadPhotos() async {
    if (_isUploadingPhotos) {
      return;
    }

    setState(() => _isUploadingPhotos = true);
    try {
      final addedCount = await widget.controller
          .pickAndAddBusinessGalleryPhotos();
      if (!mounted) {
        return;
      }
      if (addedCount > 0) {
        Get.snackbar(
          'Photos uploaded',
          addedCount == 1
              ? '1 photo was added to your published gallery.'
              : '$addedCount photos were added to your published gallery.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhotos = false);
      }
    }
  }

  Future<void> _setPrimaryPhoto(String photoPath) async {
    if (_busyPhotoPath != null) {
      return;
    }

    setState(() => _busyPhotoPath = photoPath);
    try {
      final updated = await widget.controller.setPrimaryBusinessPhoto(
        photoPath,
      );
      if (!mounted || updated) {
        return;
      }
      Get.snackbar(
        'Unable to update',
        'This photo could not be marked as the primary profile image.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _busyPhotoPath = null);
      }
    }
  }

  Future<void> _deletePhoto(String photoPath) async {
    if (_busyPhotoPath != null) {
      return;
    }

    setState(() => _busyPhotoPath = photoPath);
    try {
      final deleted = _selectedFilter == _PhotosFilter.scheduled
          ? await widget.controller.deleteDraftGalleryPhoto(photoPath)
          : await widget.controller.deleteBusinessGalleryPhoto(photoPath);
      if (!mounted || deleted) {
        return;
      }
      Get.snackbar(
        'Unable to remove',
        'This photo could not be deleted right now.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _busyPhotoPath = null);
      }
    }
  }

  Future<void> _promptPublishDraft(String photoPath) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish AI Photo?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(photoPath),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: const Color(0xFFF4F7FB),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 28,
                      color: AppColors.mutedText,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Do you want to publish this AI generated photo to your live Google Business Profile gallery?',
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop('delete'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFD32F2F)),
                  child: const Text('Delete'),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop('cancel'),
                      child: const Text('Schedule for later'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop('publish'),
                      child: const Text('Publish Now'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (action == 'delete') {
      _deletePhoto(photoPath);
      return;
    }

    if (action != 'publish') return;

    if (_isUploadingPhotos) return;
    setState(() {
      _busyPhotoPath = photoPath;
      _isUploadingPhotos = true;
    });
    
    try {
      final success = await widget.controller.publishDraftPhoto(photoPath);
      if (success && mounted) {
        Get.snackbar(
          'Photo Published',
          'AI generated photo is now published.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busyPhotoPath = null;
          _isUploadingPhotos = false;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = widget.controller.currentUser.value;
      if (user == null) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      final uploadedPhotos = widget.controller.businessPhotoGalleryFor(user);
      final liveMedia = widget.controller.liveGbpMedia;
      final activePhotoPath = _resolveActivePhotoPath(user, uploadedPhotos);
      final publishedItems = _buildPublishedGalleryItems(
        user: user,
        uploadedPhotos: uploadedPhotos,
        liveMedia: liveMedia,
        activePhotoPath: activePhotoPath,
      );
      final draftPhotos = widget.controller.draftBusinessPhotoGalleryFor(user);
      final draftItems = _buildDraftGalleryItems(
        user: user,
        draftPhotos: draftPhotos,
      );

      final allItems = _selectedFilter == _PhotosFilter.published
          ? publishedItems
          : draftItems;

      final totalCount = allItems.length;
      final visibleItems = allItems.take(_visiblePhotoLimit).toList();
      final loadedCount = visibleItems.length;
      final hasMorePhotos = loadedCount < totalCount;

      final showDemoHint = _selectedFilter == _PhotosFilter.published && publishedItems.isEmpty;

      return Stack(
        children: [
          Column(
            children: [
              _PhotosTopBar(onBack: _handleBack),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 96),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 540),
                              child: Column(
                                children: const [
                                  Text(
                                    'Manage your published business visuals and profile-ready gallery assets.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13.6,
                                      height: 1.46,
                                      color: Color(0xFF61708A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      Text(
                                        'Powered by',
                                        style: TextStyle(
                                          fontSize: 12.8,
                                          color: Color(0xFF7F8BA0),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      VisibloBrandWordmark(
                                        iconSize: 22,
                                        fontSize: 16.5,
                                        showIcon: false,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _PhotosToolbarCard(
                            selectedFilter: _selectedFilter,
                            photoCount: totalCount,
                            loadedCount: loadedCount,
                            onFilterChanged: (filter) {
                              setState(() {
                                _selectedFilter = filter;
                                _visiblePhotoLimit = 20;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          if (showDemoHint)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                14,
                                12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFFAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFBFE8EC),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Preview cards below use bundled demo images until you upload your own photo gallery.',
                                      style: AppTypography.body(
                                        fontSize: 12.4,
                                        height: 1.4,
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (showDemoHint) const SizedBox(height: 14),
                          Text(
                            _selectedFilter == _PhotosFilter.published
                                ? 'Your published images'
                                : 'Scheduled image drops',
                            style: AppTypography.card(
                              fontSize: 18,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (visibleItems.isEmpty &&
                              _selectedFilter == _PhotosFilter.scheduled)
                            const _ScheduledPhotosEmptyState()
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final crossAxisCount = _photoGridColumnCount(
                                  constraints.maxWidth,
                                );
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: visibleItems.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 14,
                                        childAspectRatio: crossAxisCount >= 4
                                            ? 0.88
                                            : 0.84,
                                      ),
                                  itemBuilder: (context, index) {
                                    final item = visibleItems[index];
                                    final isBusy =
                                        item.isLocal &&
                                        _busyPhotoPath == item.imagePath;
                                    return _PhotoCard(
                                      item: item,
                                      isBusy: isBusy,
                                      onTap: () {
                                        if (item.isAsset || item.isNetwork) return;
                                        
                                        if (_selectedFilter == _PhotosFilter.scheduled) {
                                          _promptPublishDraft(item.imagePath);
                                        } else {
                                          if (item.isPrimary) return;
                                          _setPrimaryPhoto(item.imagePath);
                                        }
                                      },
                                      onDelete: item.isAsset || item.isNetwork
                                          ? null
                                          : () => _deletePhoto(item.imagePath),
                                    );
                                  },
                                );
                              },
                            ),
                          if (totalCount > 0) ...[
                            const SizedBox(height: 20),
                            Center(
                              child: Text(
                                '$loadedCount of $totalCount photos loaded',
                                style: AppTypography.body(
                                  fontSize: 12.5,
                                  color: AppColors.mutedText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (hasMorePhotos) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _visiblePhotoLimit += 20;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  side: const BorderSide(color: AppColors.primary),
                                  foregroundColor: AppColors.primary,
                                ),
                                icon: const Icon(Icons.expand_more_rounded, size: 18),
                                label: Text('Load ${(totalCount - loadedCount).clamp(0, 20)} More'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Row(
              children: [
                Expanded(
                  child: _GradientActionButton(
                    label: 'Generate AI Photo',
                    icon: Icons.auto_fix_high_rounded,
                    onTap: _isUploadingPhotos ? null : _promptAiPhoto,
                    isLoading: _isUploadingPhotos,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GradientActionButton(
                    label: 'Upload',
                    icon: Icons.file_upload_outlined,
                    onTap: _isUploadingPhotos ? null : _uploadPhotos,
                    isLoading: _isUploadingPhotos,
                    secondary: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Future<void> _promptAiPhoto() async {
    final promptController = TextEditingController();
    
    final prompt = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate AI Photo'),
        content: TextField(
          controller: promptController,
          decoration: const InputDecoration(
            hintText: 'E.g. A modern clinic reception area',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(promptController.text),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (prompt != null && prompt.trim().isNotEmpty) {
      if (_isUploadingPhotos) return;
      setState(() => _isUploadingPhotos = true);
      
      try {
        final success = await widget.controller.generateAndSaveAiPhoto(prompt.trim());
        if (success && mounted) {
          Get.snackbar(
            'Photo Generated',
            'AI generated photo was added to your gallery.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } finally {
        if (mounted) setState(() => _isUploadingPhotos = false);
      }
    }
  }
}

class _PhotosTopBar extends StatelessWidget {
  const _PhotosTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDCE3EE))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: SizedBox(
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _HeaderBackButton(onTap: onBack),
              ),
              Text(
                'GBP Photos',
                style: AppTypography.card(
                  fontSize: 18,
                  color: AppColors.primaryDark,
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

class _PhotosToolbarCard extends StatelessWidget {
  const _PhotosToolbarCard({
    required this.selectedFilter,
    required this.photoCount,
    required this.loadedCount,
    required this.onFilterChanged,
  });

  final _PhotosFilter selectedFilter;
  final int photoCount;
  final int loadedCount;
  final ValueChanged<_PhotosFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _GalleryFilterChip(
                label: 'Published',
                selected: selectedFilter == _PhotosFilter.published,
                onTap: () => onFilterChanged(_PhotosFilter.published),
              ),
              _GalleryFilterChip(
                label: 'Scheduled',
                selected: selectedFilter == _PhotosFilter.scheduled,
                onTap: () => onFilterChanged(_PhotosFilter.scheduled),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 2),
                child: Text(
                  '$loadedCount of $photoCount photos loaded',
                  style: AppTypography.label(
                    fontSize: 11.9,
                    color: const Color(0xFF8692A6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FB),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE1E7F0)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}

class _GalleryFilterChip extends StatelessWidget {
  const _GalleryFilterChip({
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
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                  )
                : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.transparent : const Color(0xFFDDE5EF),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.label(
              fontSize: 12.5,
              color: selected ? AppColors.white : AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduledPhotosEmptyState extends StatelessWidget {
  const _ScheduledPhotosEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F1)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF5FB),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.schedule_send_outlined,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No scheduled photo drops yet',
            style: AppTypography.card(
              fontSize: 19,
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This tab is ready for timed publishing when your photo scheduling flow is connected next.',
            textAlign: TextAlign.center,
            style: AppTypography.body(
              fontSize: 13,
              color: AppColors.mutedText,
              height: 1.48,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.item,
    required this.isBusy,
    required this.onTap,
    required this.onDelete,
  });

  final _PhotoGalleryItem item;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppColors.white,
            border: Border.all(
              color: item.isPrimary
                  ? AppColors.primary
                  : const Color(0xFFE1E8F2),
              width: item.isPrimary ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F2746),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(item.isPrimary ? 6 : 7),
            child: Stack(
              fit: StackFit.expand,
              children: [
                item.isNetwork
                    ? Image.network(
                        item.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF4F7FB),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              size: 28,
                              color: AppColors.mutedText,
                            ),
                          );
                        },
                      )
                    : item.isAsset
                        ? Image.asset(item.imagePath, fit: BoxFit.cover)
                        : Image.file(
                            File(item.imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFFF4F7FB),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  size: 28,
                                  color: AppColors.mutedText,
                                ),
                              );
                            },
                          ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.badge,
                      style: AppTypography.label(
                        fontSize: 10.5,
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (onDelete != null)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isBusy ? null : onDelete,
                        borderRadius: BorderRadius.circular(999),
                        child: Ink(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.62),
                        ],
                        stops: const [0.48, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label(
                                fontSize: 13.2,
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label(
                                fontSize: 11.1,
                                color: AppColors.white.withValues(alpha: 0.88),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryDark, AppColors.primary],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x2239B4BD),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          item.isPrimary
                              ? Icons.check_rounded
                              : Icons.visibility_outlined,
                          size: 18,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.isPrimary)
                  Positioned(
                    left: 12,
                    bottom: 62,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Primary photo',
                        style: AppTypography.label(
                          fontSize: 10.6,
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (isBusy)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.32),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.white,
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

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isLoading,
    this.secondary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            gradient: secondary
                ? null
                : const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
            color: secondary ? AppColors.white : null,
            borderRadius: BorderRadius.circular(12),
            border: secondary
                ? Border.all(color: AppColors.primary, width: 1.6)
                : null,
            boxShadow: const [
              BoxShadow(
                color: Color(0x2239B4BD),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: secondary ? AppColors.primaryDark : AppColors.white,
                  ),
                )
              else
                Icon(
                  icon,
                  size: 18,
                  color: secondary ? AppColors.primaryDark : AppColors.white,
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label(
                    fontSize: 14.5,
                    color: secondary ? AppColors.primaryDark : AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoGalleryItem {
  const _PhotoGalleryItem({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.isAsset,
    required this.isLocal,
    required this.isNetwork,
    required this.isPrimary,
  });

  final String imagePath;
  final String title;
  final String subtitle;
  final String badge;
  final bool isAsset;
  final bool isLocal;
  final bool isNetwork;
  final bool isPrimary;
}

class _FallbackPhotoSeed {
  const _FallbackPhotoSeed({
    required this.assetPath,
    required this.title,
    required this.badge,
  });

  final String assetPath;
  final String title;
  final String badge;
}

String _resolveActivePhotoPath(TestAccount user, List<String> uploadedPhotos) {
  final currentPhotoPath = user.businessPhotoPath.trim();
  if (currentPhotoPath.isNotEmpty &&
      uploadedPhotos.contains(currentPhotoPath)) {
    return currentPhotoPath;
  }
  return uploadedPhotos.isNotEmpty ? uploadedPhotos.first : '';
}

List<_PhotoGalleryItem> _buildPublishedGalleryItems({
  required TestAccount user,
  required List<String> uploadedPhotos,
  required List<GbpMedia> liveMedia,
  required String activePhotoPath,
}) {
  final items = <_PhotoGalleryItem>[];
  final resolvedBusinessName = user.businessName.trim().isNotEmpty
      ? user.businessName.trim()
      : 'Your Business';
  
  for (final media in liveMedia) {
    items.add(_PhotoGalleryItem(
      imagePath: media.googleUrl.isNotEmpty ? media.googleUrl : media.thumbnailUrl,
      title: media.name.split('/').last,
      subtitle: media.createTime.isNotEmpty ? media.createTime.split('T').first : 'Live Photo',
      badge: media.category.isNotEmpty ? media.category : 'GALLERY',
      isAsset: false,
      isLocal: false,
      isNetwork: true,
      isPrimary: false,
    ));
  }

  for (var index = 0; index < uploadedPhotos.length; index++) {
    items.add(_PhotoGalleryItem(
      imagePath: uploadedPhotos[index],
      title: index == 0
          ? resolvedBusinessName
          : '$resolvedBusinessName gallery',
      subtitle: uploadedPhotos[index] == activePhotoPath
          ? 'Current profile photo'
          : 'Tap to make this the primary photo',
      badge: uploadedPhotos[index] == activePhotoPath ? 'PROFILE' : 'ADDITIONAL',
      isAsset: false,
      isLocal: true,
      isNetwork: false,
      isPrimary: uploadedPhotos[index] == activePhotoPath,
    ));
  }

  final shouldUseSampleFallback =
      !(user.backendAuthenticated || user.googleBusinessProfileConnected);
  final sampleCount = shouldUseSampleFallback
      ? math.max(0, 9 - items.length)
      : 0;
  for (final seed in _kFallbackPhotoSeeds.take(sampleCount)) {
    items.add(
      _PhotoGalleryItem(
        imagePath: seed.assetPath,
        title: seed.title,
        subtitle: 'Bundled demo preview card',
        badge: seed.badge,
        isAsset: true,
        isLocal: false,
        isNetwork: false,
        isPrimary: false,
      ),
    );
  }
  return items;
}

List<_PhotoGalleryItem> _buildDraftGalleryItems({
  required TestAccount user,
  required List<String> draftPhotos,
}) {
  final items = <_PhotoGalleryItem>[];
  for (var index = 0; index < draftPhotos.length; index++) {
    items.add(_PhotoGalleryItem(
      imagePath: draftPhotos[index],
      title: 'AI Generated Draft',
      subtitle: 'Tap to publish',
      badge: 'DRAFT',
      isAsset: false,
      isLocal: true,
      isNetwork: false,
      isPrimary: false,
    ));
  }
  return items;
}

int _photoGridColumnCount(double width) {
  if (width >= 980) {
    return 5;
  }
  if (width >= 760) {
    return 4;
  }
  if (width >= 520) {
    return 3;
  }
  return 2;
}

const List<_FallbackPhotoSeed> _kFallbackPhotoSeeds = [
  _FallbackPhotoSeed(
    assetPath: 'assets/images/office.png',
    title: 'Office space',
    badge: 'ADDITIONAL',
  ),
  _FallbackPhotoSeed(
    assetPath: 'assets/images/mall.png',
    title: 'Property feature',
    badge: 'COVER',
  ),
  _FallbackPhotoSeed(
    assetPath: 'assets/images/site.png',
    title: 'Site update',
    badge: 'ADDITIONAL',
  ),
  _FallbackPhotoSeed(
    assetPath: 'assets/images/doctor.png',
    title: 'Team moment',
    badge: 'PROFILE',
  ),
  _FallbackPhotoSeed(
    assetPath: 'assets/images/flowers.png',
    title: 'Brand detail',
    badge: 'ADDITIONAL',
  ),
  _FallbackPhotoSeed(
    assetPath: 'assets/images/bakery.png',
    title: 'Customer-ready shot',
    badge: 'FEATURED',
  ),
  _FallbackPhotoSeed(
    assetPath: 'assets/images/coffee.png',
    title: 'Lifestyle post',
    badge: 'ADDITIONAL',
  ),
  _FallbackPhotoSeed(
    assetPath: 'assets/images/fitness.png',
    title: 'Action visual',
    badge: 'COVER',
  ),
  _FallbackPhotoSeed(
    assetPath: 'assets/images/makeup.png',
    title: 'Offer creative',
    badge: 'ADDITIONAL',
  ),
];
