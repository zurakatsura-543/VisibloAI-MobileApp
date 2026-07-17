import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api_client.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/gbp_post.dart';
import 'gbp_post_editor_view.dart';
import '../widgets/auth_calendar_sheet.dart';

class GbpPostCreateMethodView extends StatelessWidget {
  const GbpPostCreateMethodView({
    super.key,
    required this.templatePost,
    required this.businessName,
    this.postType = 'standard',
  });

  final GbpPost templatePost;
  final String businessName;
  final String postType;

  @override
  Widget build(BuildContext context) {
    return _CreatePostShell(
      title: 'Create Post',
      showBack: false,
      subtitle: 'Select your preferred creation method',
      child: Column(
        children: [
          _CreationMethodCard(
            icon: Icons.auto_fix_high_rounded,
            iconColor: const Color(0xFF6B7CF3),
            iconBackground: const Color(0xFFF5F4FF),
            iconBorder: const Color(0xFF99A7FB),
            title: 'VisibloAI Generation',
            description:
                'Instantly generate high-converting GBP posts fully optimized for your audience. Saves hours of writing and brainstorming.',
            onTap: () => _openAiGeneration(context),
          ),
          const SizedBox(height: 18),
          _CreationMethodCard(
            icon: Icons.edit_outlined,
            iconColor: const Color(0xFF35C87D),
            iconBackground: const Color(0xFFF1FFF7),
            iconBorder: const Color(0xFF59D88D),
            title: 'Create Manually',
            description:
                'Write your own content completely from scratch and choose your exact media and publish times.',
            onTap: () => _openManualCreation(context),
          ),
        ],
      ),
    );
  }

  Future<void> _openAiGeneration(BuildContext context) async {
    final created = await Get.to<GbpPost>(
      () => GbpPostAiComposerView(
        templatePost: templatePost,
        businessName: businessName,
        postType: postType,
      ),
    );

    if (created != null && context.mounted) {
      Get.back(result: created);
    }
  }

  Future<void> _openManualCreation(BuildContext context) async {
    final created = await Get.to<GbpPost>(
      () => GbpPostManualComposerView(
        templatePost: templatePost,
        businessName: businessName,
      ),
    );

    if (created != null && context.mounted) {
      Get.back(result: created);
    }
  }
}

class GbpPostAiComposerView extends StatefulWidget {
  const GbpPostAiComposerView({
    super.key,
    required this.templatePost,
    required this.businessName,
    this.postType = 'standard',
  });

  final GbpPost templatePost;
  final String businessName;
  final String postType;

  @override
  State<GbpPostAiComposerView> createState() => _GbpPostAiComposerViewState();
}

class _GbpPostAiComposerViewState extends State<GbpPostAiComposerView> {
  late final TextEditingController _topicController;
  late final ImagePicker _imagePicker;
  _AIPostTone _selectedTone = _AIPostTone.professional;
  _AIPostLanguage _selectedLanguage = _AIPostLanguage.english;
  bool _generateImage = true;
  bool _isGenerateAiExpanded = true;
  bool _isUploadExpanded = false;
  bool _isGenerating = false;
  bool _isPublishing = false;
  List<String> _uploadedImagePaths = <String>[];
  GbpPost? _generatedPost;

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController();
    _imagePicker = ImagePicker();
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CreatePostShell(
      title: 'Create Post With AI',
      showBack: true,
      subtitle: 'Craft and fine-tune your perfect post',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AiComposerModeCard(
            title: 'Generate with AI',
            description: 'Generate both post content and image with AI.',
            icon: Icons.auto_awesome_rounded,
            iconColor: const Color(0xFFB75CFF),
            iconBackground: const Color(0xFFF9EEFF),
            borderColor: const Color(0xFFEBCBFF),
            isExpanded: _isGenerateAiExpanded,
            onToggle: () {
              setState(() {
                _isGenerateAiExpanded = !_isGenerateAiExpanded;
                if (_isGenerateAiExpanded) {
                  _isUploadExpanded = false;
                }
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CreateFieldLabel('Topic / Keywords'),
                const SizedBox(height: 10),
                _CreateTextField(
                  controller: _topicController,
                  hintText: 'e.g., Summer collection launch...',
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _CreateDropdownField<_AIPostTone>(
                        label: 'Tone',
                        value: _selectedTone,
                        items: _AIPostTone.values,
                        itemLabel: (item) => item.label,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedTone = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _CreateDropdownField<_AIPostLanguage>(
                        label: 'Language',
                        value: _selectedLanguage,
                        items: _AIPostLanguage.values,
                        itemLabel: (item) => item.label,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedLanguage = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _AiComposerHintCard(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Generate image with AI',
                  description:
                      'AI will create the image and content to match your post.',
                  trailing: Switch.adaptive(
                    value: _generateImage,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: const Color(0xFFDDE4EC),
                    onChanged: (value) {
                      setState(() => _generateImage = value);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _FilledCreateActionButton(
                    label: _isGenerating ? 'Generating...' : 'Generate AI Post',
                    icon: _isGenerating
                        ? Icons.hourglass_top_rounded
                        : Icons.auto_awesome_rounded,
                    onTap: _isGenerating
                        ? () {}
                        : () => _generatePost(useUploadedImage: false),
                    borderColor: const Color(0xFFEBCBFF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _AiComposerModeCard(
            title: 'Use My Image',
            description:
                'Upload your own image and let AI generate the post content.',
            icon: Icons.image_outlined,
            iconColor: const Color(0xFF4D7CFF),
            iconBackground: const Color(0xFFEEF3FF),
            borderColor: const Color(0xFFD8E3FF),
            isExpanded: _isUploadExpanded,
            onToggle: () {
              setState(() {
                _isUploadExpanded = !_isUploadExpanded;
                if (_isUploadExpanded) {
                  _isGenerateAiExpanded = false;
                }
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AiComposerHintCard(
                  icon: Icons.text_snippet_outlined,
                  title: 'AI will generate caption / post content',
                  description:
                      'Your uploaded image will be used as the post media while the same AI backend generates the text.',
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const _UploadInfoChip(
                      icon: Icons.photo_library_outlined,
                      label: 'Maximum 4 images',
                    ),
                    const Spacer(),
                    Text(
                      '${_uploadedImagePaths.length}/4 uploaded',
                      style: AppTypography.button(
                        fontSize: 12.5,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _AiImageUploadCard(onTap: _pickUploadedImages),
                if (_uploadedImagePaths.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'UPLOADED IMAGES (${_uploadedImagePaths.length}/4)',
                    style: AppTypography.label(
                      fontSize: 11.5,
                      color: const Color(0xFF5B6778),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _uploadedImagePaths
                        .map(
                          (path) => _AiSelectedImageTile(
                            path: path,
                            onRemove: () => _removeUploadedImage(path),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _FilledCreateActionButton(
                    label: _isGenerating ? 'Generating...' : 'Generate AI Post',
                    icon: _isGenerating
                        ? Icons.hourglass_top_rounded
                        : Icons.auto_awesome_rounded,
                    onTap: _isGenerating
                        ? () {}
                        : () => _generatePost(useUploadedImage: true),
                    borderColor: const Color(0xFFD8E3FF),
                  ),
                ),
              ],
            ),
          ),
          if (_generatedPost != null) ...[
            const SizedBox(height: 18),
            const _AiSuccessBanner(),
            const SizedBox(height: 16),
            _GeneratedAiPreviewCard(
              post: _generatedPost!,
              businessName: widget.businessName,
              toneLabel: _selectedTone.label,
              languageLabel: _selectedLanguage.label,
              onPreview: _openPreviewModal,
            ),
            const SizedBox(height: 14),
            _GeneratedAiContentCard(
              post: _generatedPost!,
              topic: _topicController.text.trim(),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: _OutlinedCreateActionButton(
                label: 'View Generated Post',
                icon: Icons.preview_outlined,
                onTap: _openPreviewModal,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _OutlinedCreateActionButton(
                    label: 'Schedule',
                    icon: Icons.calendar_today_outlined,
                    onTap: () async {
                      final updated = await Get.to<GbpPost>(
                        () => GbpPostEditorView(
                          initialPost: _generatedPost!.copyWith(status: GbpPostStatus.scheduled),
                          businessName: widget.businessName,
                          isCreating: true,
                        ),
                      );
                      if (updated != null && mounted) {
                        Get.back(result: updated);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FilledCreateActionButton(
                    label: _isPublishing ? 'Publishing...' : 'Publish Now',
                    icon: _isPublishing ? Icons.hourglass_top_rounded : Icons.send_outlined,
                    onTap: (_isPublishing || _isGenerating) ? () {} : _publishNow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: _isGenerating
                    ? null
                    : () => _generatePost(
                        useUploadedImage: _uploadedImagePaths.isNotEmpty,
                      ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Regenerate AI Post'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF545C69),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickUploadedImages() async {
    final remainingSlots = 4 - _uploadedImagePaths.length;
    if (remainingSlots <= 0) {
      Get.snackbar(
        'Upload limit reached',
        'You can upload up to 4 images for this post.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final pickedImages = await _imagePicker.pickMultiImage(
        maxWidth: 1800,
        imageQuality: 90,
      );
      if (pickedImages.isEmpty || !mounted) {
        return;
      }

      final nextPaths = [
        ..._uploadedImagePaths,
        ...pickedImages.map((image) => image.path),
      ].take(4).toList(growable: false);

      setState(() {
        _uploadedImagePaths = nextPaths;
        _isUploadExpanded = true;
        _isGenerateAiExpanded = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      Get.snackbar(
        'Upload failed',
        'The image could not be selected right now.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _removeUploadedImage(String path) {
    setState(() {
      _uploadedImagePaths = _uploadedImagePaths
          .where((item) => item != path)
          .toList(growable: false);
    });
  }

  Future<void> _publishNow() async {
    final post = _generatedPost;
    if (post == null) return;

    setState(() => _isPublishing = true);

    Get.snackbar(
      'Publishing…',
      'Sending your post to Google Business Profile.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 60),
      showProgressIndicator: true,
    );

    try {
      final controller = Get.find<OnboardingController>();
      await controller.publishAiPost(post.id);

      if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

      if (!mounted) return;
      Get.snackbar(
        'Published! 🎉',
        'Your post is now live on Google Business Profile.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF22AF69),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 3),
      );

      // Re-fetch dashboard data so the post shows as LIVE
      await controller.fetchDashboardLiveStream();

      // Pop back with the live post so the dashboard list updates
      if (mounted) {
        Get.back(result: post.copyWith(status: GbpPostStatus.live));
      }
    } catch (e) {
      if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
      if (mounted) {
        Get.snackbar(
          'Publish Failed',
          e.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFF6B73),
          colorText: const Color(0xFFFFFFFF),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  Future<void> _generatePost({required bool useUploadedImage}) async {
    final typedTopic = _topicController.text.trim();
    final topic = typedTopic.isNotEmpty
        ? typedTopic
        : '${widget.businessName} local business update';

    if (!useUploadedImage && typedTopic.isEmpty) {
      Get.snackbar(
        'Topic required',
        'Add a topic or keyword before generating the post.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (useUploadedImage && _uploadedImagePaths.isEmpty) {
      Get.snackbar(
        'Upload an image',
        'Add at least one image before generating this post.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final controller = Get.find<OnboardingController>();
      final result = await controller.generateAiPost(
        topic: topic,
        tone: _selectedTone.label,
        language: _selectedLanguage.label,
        skipImage: !_generateImage,
        type: widget.postType,
      );

      debugPrint('=== AI POST RESULT ===');
      debugPrint('id: ${result['id']}');
      debugPrint('title: ${result['title']}');
      debugPrint('image: ${result['image']}');
      debugPrint('status: ${result['status']}');
      debugPrint('======================');

      // Backend mapPost returns the image URL under 'image' (not 'imageUrl')
      var imageUrl = result['image']?.toString() ?? '';

      // Resolve relative /uploads/ paths to full server URLs
      if (imageUrl.startsWith('/uploads/')) {
        // baseUrl is https://app.visibloai.com/api — strip /api for public root
        final apiBase = ApiClient().baseUrl;
        final publicBase = apiBase.replaceAll(RegExp(r'/api/?$'), '');
        imageUrl = '$publicBase$imageUrl';
      }

      final previewAssetPath =
          useUploadedImage && _uploadedImagePaths.isNotEmpty
          ? _uploadedImagePaths.first
          : imageUrl.isNotEmpty
          ? imageUrl
          : widget.templatePost.assetPath;

      final created = widget.templatePost.copyWith(
        id:
            result['id']?.toString() ??
            'post-${DateTime.now().microsecondsSinceEpoch}',
        status: GbpPostStatus.draft,
        title: result['title']?.toString() ?? 'Generated Post',
        subtitle: result['content']?.toString() ?? '',
        assetPath: previewAssetPath,
        meta: _buildAiHashtags(businessName: widget.businessName, topic: topic),
        createdAt: DateTime.now(),
        scheduledFor: null,
      );

      if (mounted) {
        setState(() => _generatedPost = created);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Generation Failed',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _openPreviewModal() async {
    final generatedPost = _generatedPost;
    if (generatedPost == null) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: _GeneratedAiPreviewModal(
            post: generatedPost,
            businessName: widget.businessName,
            toneLabel: _selectedTone.label,
            languageLabel: _selectedLanguage.label,
          ),
        );
      },
    );
  }
}

class _AiComposerModeCard extends StatelessWidget {
  const _AiComposerModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.borderColor,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color borderColor;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded ? borderColor : const Color(0xFFE7EDF4),
          width: isExpanded ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded
                ? borderColor.withValues(alpha: 0.18)
                : const Color(0x0F0F2746),
            blurRadius: isExpanded ? 20 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onToggle,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.card(
                            fontSize: 15,
                            color: const Color(0xFF463E91),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: AppTypography.body(
                            fontSize: 13,
                            color: const Color(0xFF708096),
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? iconBackground
                          : const Color(0xFFF4F6FA),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 18),
                child: child,
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiComposerHintCard extends StatelessWidget {
  const _AiComposerHintCard({
    required this.icon,
    required this.title,
    required this.description,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EDF5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.button(
                    fontSize: 14.4,
                    color: const Color(0xFF36475B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: AppTypography.body(
                    fontSize: 13,
                    color: const Color(0xFF718096),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class _UploadInfoChip extends StatelessWidget {
  const _UploadInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD8E5F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.brandBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.button(
              fontSize: 12,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiImageUploadCard extends StatelessWidget {
  const _AiImageUploadCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedRRectBorderPainter(
          color: const Color(0xFF55D5E8),
          radius: 14,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FCFE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.file_upload_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Image',
                      style: AppTypography.button(
                        fontSize: 15,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Recommended: 1260 x 570 px, 16:9',
                      style: AppTypography.body(
                        fontSize: 12.4,
                        color: const Color(0xFF707A89),
                        fontWeight: FontWeight.w500,
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

class _AiSelectedImageTile extends StatelessWidget {
  const _AiSelectedImageTile({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(path),
            width: 74,
            height: 74,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 74,
              height: 74,
              color: const Color(0xFFF2F5F9),
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                color: Color(0xFF9AA6B6),
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.close_rounded,
                size: 13,
                color: Color(0xFFE45A64),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AiSuccessBanner extends StatelessWidget {
  const _AiSuccessBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FFFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFF1E5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI post generated successfully',
                  style: AppTypography.card(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Review your content below before publishing.',
                  style: AppTypography.body(
                    fontSize: 13.1,
                    color: const Color(0xFF617283),
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

class _GeneratedAiPreviewCard extends StatelessWidget {
  const _GeneratedAiPreviewCard({
    required this.post,
    required this.businessName,
    required this.toneLabel,
    required this.languageLabel,
    this.onPreview,
  });

  final GbpPost post;
  final String businessName;
  final String toneLabel;
  final String languageLabel;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F2746),
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
              const Icon(
                Icons.visibility_outlined,
                size: 20,
                color: AppColors.brandBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Post Preview',
                  style: AppTypography.card(
                    fontSize: 17,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onPreview != null)
                TextButton.icon(
                  onPressed: onPreview,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  icon: const Icon(Icons.open_in_full_rounded, size: 16),
                  label: Text(
                    'Preview',
                    style: AppTypography.button(
                      fontSize: 12.8,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _AiPostHeroMedia(post: post, businessName: businessName),
          const SizedBox(height: 14),
          Text(
            post.subtitle,
            style: AppTypography.body(
              fontSize: 14.2,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _PreviewMetaPill(
                icon: Icons.auto_awesome_rounded,
                label: toneLabel,
                color: const Color(0xFFF49822),
              ),
              _PreviewMetaPill(
                icon: Icons.language_rounded,
                label: languageLabel,
                color: const Color(0xFFB238D4),
              ),
              const _PreviewMetaPill(
                icon: Icons.psychology_alt_outlined,
                label: 'AI Generated',
                color: Color(0xFF3468E8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GeneratedAiContentCard extends StatelessWidget {
  const _GeneratedAiContentCard({required this.post, required this.topic});

  final GbpPost post;
  final String topic;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F2746),
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
              const Icon(
                Icons.description_outlined,
                size: 20,
                color: AppColors.brandBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Post Content',
                style: AppTypography.card(
                  fontSize: 17,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EEF5)),
            ),
            child: Text(
              post.subtitle,
              style: AppTypography.body(
                fontSize: 14.2,
                color: const Color(0xFF556274),
                fontWeight: FontWeight.w500,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (topic.isNotEmpty)
                _TinyLabelChip(
                  label: 'Topic: $topic',
                  foreground: AppColors.primary,
                  background: const Color(0xFFEAFBFD),
                ),
              if (post.meta.trim().isNotEmpty)
                _TinyLabelChip(
                  label: 'Hashtags ready',
                  foreground: AppColors.brandBlue,
                  background: const Color(0xFFF2F6FB),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GeneratedAiPreviewModal extends StatelessWidget {
  const _GeneratedAiPreviewModal({
    required this.post,
    required this.businessName,
    required this.toneLabel,
    required this.languageLabel,
  });

  final GbpPost post;
  final String businessName;
  final String toneLabel;
  final String languageLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F9FC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Post Preview',
                      style: AppTypography.section(
                        fontSize: 19,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF7F8A9A),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE4EAF1)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GeneratedAiPreviewCard(
                      post: post,
                      businessName: businessName,
                      toneLabel: toneLabel,
                      languageLabel: languageLabel,
                    ),
                    const SizedBox(height: 14),
                    _GeneratedAiContentCard(post: post, topic: ''),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiPostHeroMedia extends StatelessWidget {
  const _AiPostHeroMedia({required this.post, required this.businessName});

  final GbpPost post;
  final String businessName;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          _PostMedia(assetPath: post.assetPath, height: 210),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.58),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.section(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.18,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  const Icon(Icons.home_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.button(
                        fontSize: 13.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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

class _PreviewMetaPill extends StatelessWidget {
  const _PreviewMetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTypography.label(
            fontSize: 12.3,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TinyLabelChip extends StatelessWidget {
  const _TinyLabelChip({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
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
        style: AppTypography.label(
          fontSize: 11.5,
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PostMedia extends StatelessWidget {
  const _PostMedia({required this.assetPath, required this.height});

  final String assetPath;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (assetPath.trim().isEmpty) {
      return Container(
        width: double.infinity,
        height: height,
        color: const Color(0xFFEAF2FF),
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_outlined,
          color: Color(0xFF90AFCC),
          size: 48,
        ),
      );
    }

    if (assetPath.startsWith('data:image/')) {
      try {
        final base64Str = assetPath.substring(assetPath.indexOf(',') + 1);
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: double.infinity,
            height: height,
            color: const Color(0xFFF0F4F9),
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_not_supported_rounded,
              color: Color(0xFF9AA6B6),
              size: 42,
            ),
          ),
        );
      } catch (_) {
        // Fallthrough if parsing fails
      }
    }

    if (assetPath.startsWith('http')) {
      return Image.network(
        assetPath,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: double.infinity,
          height: height,
          color: const Color(0xFFF0F4F9),
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_rounded,
            color: Color(0xFF9AA6B6),
            size: 42,
          ),
        ),
      );
    }

    if (assetPath.startsWith('/')) {
      return Image.file(
        File(assetPath),
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: double.infinity,
          height: height,
          color: const Color(0xFFF0F4F9),
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_rounded,
            color: Color(0xFF9AA6B6),
            size: 42,
          ),
        ),
      );
    }

    return Image.asset(
      assetPath,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
    );
  }
}

class GbpPostManualComposerView extends StatefulWidget {
  const GbpPostManualComposerView({
    super.key,
    required this.templatePost,
    required this.businessName,
  });

  final GbpPost templatePost;
  final String businessName;

  @override
  State<GbpPostManualComposerView> createState() =>
      _GbpPostManualComposerViewState();
}

class _GbpPostManualComposerViewState extends State<GbpPostManualComposerView> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  _ManualCallToAction _selectedCallToAction = _ManualCallToAction.none;
  DateTime? _scheduledFor;
  late String _selectedAssetPath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _selectedAssetPath = widget.templatePost.assetPath;
    _contentController.addListener(_refresh);
  }

  @override
  void dispose() {
    _contentController.removeListener(_refresh);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentLength = _contentController.text.length;

    return _CreatePostShell(
      title: 'Create Post Manually',
      showBack: true,
      subtitle: 'Craft and fine-tune your perfect post',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CreateFieldLabel('Title'),
          const SizedBox(height: 10),
          _CreateTextField(
            controller: _titleController,
            hintText: 'Post title',
          ),
          const SizedBox(height: 18),
          const _CreateFieldLabel('Content'),
          const SizedBox(height: 10),
          _CreateTextField(
            controller: _contentController,
            hintText: 'Write your beautiful post content...',
            maxLines: 6,
            inputFormatters: [LengthLimitingTextInputFormatter(1500)],
          ),
          const SizedBox(height: 6),
          Text(
            '$contentLength/1500 characters',
            style: AppTypography.label(
              fontSize: 11.5,
              color: const Color(0xFF545C69),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          const _CreateFieldLabel('Add Media'),
          const SizedBox(height: 6),
          Text(
            'Posts with images generate significantly more engagement',
            style: AppTypography.body(
              fontSize: 13.3,
              color: const Color(0xFF646C79),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          _MediaUploadCard(
            assetPath: _selectedAssetPath,
            onTap: _pickMediaAsset,
          ),
          const SizedBox(height: 18),
          _CreateDropdownField<_ManualCallToAction>(
            label: 'Call to Action',
            value: _selectedCallToAction,
            items: _ManualCallToAction.values,
            itemLabel: (item) => item.label,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCallToAction = value);
              }
            },
          ),
          const SizedBox(height: 18),
          const _CreateFieldLabel('Publish/Schedule Timing'),
          const SizedBox(height: 10),
          _ScheduleDateField(
            value: _scheduledFor,
            onTap: _pickScheduleDateTime,
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: _OutlinedCreateActionButton(
                  label: 'Schedule',
                  icon: Icons.calendar_today_outlined,
                  onTap: _schedulePost,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FilledCreateActionButton(
                  label: 'Publish Now',
                  icon: Icons.send_outlined,
                  onTap: _publishPost,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () => Get.back<void>(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2F3745),
                textStyle: AppTypography.body(
                  fontSize: 14.2,
                  color: const Color(0xFF2F3745),
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Change Mode'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickScheduleDateTime() async {
    final initialDate =
        _scheduledFor ?? DateTime.now().add(const Duration(days: 1));
    final pickedDate = await showAuthCalendarSheet(
      context: context,
      title: 'Schedule Publish Date',
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2032),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _scheduledFor ?? DateTime.now().add(const Duration(hours: 2)),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) {
      return;
    }

    setState(() {
      _scheduledFor = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _pickMediaAsset() async {
    final selectedAssetPath = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9E2EC),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose post media',
                  style: AppTypography.button(
                    fontSize: 16,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  itemCount: _manualMediaChoices.length,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 110,
                  ),
                  itemBuilder: (context, index) {
                    final item = _manualMediaChoices[index];
                    final isSelected = item.assetPath == _selectedAssetPath;

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () =>
                          Navigator.of(sheetContext).pop(item.assetPath),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FBFE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFFDCE4ED),
                            width: isSelected ? 1.6 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(15),
                                ),
                                child: Image.asset(
                                  item.assetPath,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                item.label,
                                style: AppTypography.label(
                                  fontSize: 11.5,
                                  color: AppColors.brandBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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
      },
    );

    if (selectedAssetPath != null && mounted) {
      setState(() => _selectedAssetPath = selectedAssetPath);
    }
  }

  void _schedulePost() {
    _submitPost(preferredStatus: GbpPostStatus.scheduled);
  }

  void _publishPost() {
    _submitPost(preferredStatus: GbpPostStatus.live);
  }

  void _submitPost({required GbpPostStatus preferredStatus}) {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      Get.snackbar(
        'Complete the post',
        'Please add both a title and content before continuing.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (preferredStatus == GbpPostStatus.scheduled && _scheduledFor == null) {
      Get.snackbar(
        'Schedule required',
        'Select a publish date and time before scheduling this post.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final created = widget.templatePost.copyWith(
      id: 'post-${DateTime.now().microsecondsSinceEpoch}',
      status: preferredStatus,
      assetPath: _selectedAssetPath,
      title: title,
      subtitle: content,
      meta: _manualMetaFromCallToAction(
        businessName: widget.businessName,
        callToAction: _selectedCallToAction,
      ),
      createdAt: DateTime.now(),
      scheduledFor: preferredStatus == GbpPostStatus.scheduled
          ? _scheduledFor
          : null,
    );

    Get.back(result: created);
  }
}

class _CreatePostShell extends StatelessWidget {
  const _CreatePostShell({
    required this.title,
    required this.showBack,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final bool showBack;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CreatePostPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
              child: Row(
                children: [
                  if (showBack)
                    _HeaderIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Get.back<void>(),
                    )
                  else
                    const SizedBox(width: 34),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.section(
                        fontSize: 17.8,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _HeaderIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Get.back<void>(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  subtitle,
                  style: AppTypography.body(
                    fontSize: 14.1,
                    color: const Color(0xFF687283),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Container(height: 1, color: const Color(0xFFE4EAF1)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, color: const Color(0xFF97A2B3)),
      ),
    );
  }
}

class _CreationMethodCard extends StatelessWidget {
  const _CreationMethodCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.iconBorder,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color iconBorder;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE9EEF4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x100F2746),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: iconBorder),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.card(
                      fontSize: 15,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _RecommendedPill(),
                  const SizedBox(height: 14),
                  Text(
                    description,
                    style: AppTypography.body(
                      fontSize: 13.2,
                      color: const Color(0xFF5A6270),
                      fontWeight: FontWeight.w500,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 54),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedPill extends StatelessWidget {
  const _RecommendedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEAFBFB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFB7ECEB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 12,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'RECOMMENDED',
            style: AppTypography.label(
              fontSize: 10.2,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateFieldLabel extends StatelessWidget {
  const _CreateFieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.button(
        fontSize: 14.6,
        color: AppColors.brandBlue,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _CreateTextField extends StatelessWidget {
  const _CreateTextField({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      style: AppTypography.body(
        fontSize: 15,
        color: const Color(0xFF323B48),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.body(
          fontSize: 15,
          color: const Color(0xFF98A2B2),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: maxLines > 1 ? 14 : 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _CreatePostPalette.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
        ),
      ),
    );
  }
}

class _CreateDropdownField<T> extends StatelessWidget {
  const _CreateDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CreateFieldLabel(label),
        const SizedBox(height: 10),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: _CreatePostPalette.fieldBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.3,
              ),
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF7A8799),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    style: AppTypography.body(
                      fontSize: 14.5,
                      color: const Color(0xFF323B48),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _FilledCreateActionButton extends StatelessWidget {
  const _FilledCreateActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.borderColor = Colors.transparent,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: borderColor, width: 2),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: AppTypography.button(
          fontSize: 15.5,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OutlinedCreateActionButton extends StatelessWidget {
  const _OutlinedCreateActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: AppTypography.button(
          fontSize: 15,
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MediaUploadCard extends StatelessWidget {
  const _MediaUploadCard({required this.assetPath, required this.onTap});

  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final cardHeight = isCompact ? 140.0 : 132.0;
        final previewWidth = isCompact ? 84.0 : 92.0;
        final uploadLabelSize = isCompact ? 14.2 : 15.0;
        final noteSize = isCompact ? 11.3 : 12.1;

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: CustomPaint(
            painter: _DashedRRectBorderPainter(
              color: const Color(0xFF55D5E8),
              radius: 14,
            ),
            child: Container(
              width: double.infinity,
              height: cardHeight,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FCFE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      assetPath,
                      width: previewWidth,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.file_upload_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload Image',
                          style: AppTypography.button(
                            fontSize: uploadLabelSize,
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Recommended: 1260 * 570 px,\n16:9',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTypography.body(
                            fontSize: noteSize,
                            color: const Color(0xFF707A89),
                            fontWeight: FontWeight.w500,
                            height: 1.35,
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
      },
    );
  }
}

class _ScheduleDateField extends StatelessWidget {
  const _ScheduleDateField({required this.value, required this.onTap});

  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _CreatePostPalette.fieldBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null
                    ? 'dd-mm-yyyy -:-'
                    : _formatScheduleDateTime(value!),
                style: AppTypography.body(
                  fontSize: 14.6,
                  color: value == null
                      ? const Color(0xFF98A2B2)
                      : const Color(0xFF323B48),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Color(0xFF687283),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRRectBorderPainter extends CustomPainter {
  const _DashedRRectBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    const dash = 6.0;
    const gap = 5.0;
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

enum _AIPostTone { professional, friendly, promotional, informative }

extension on _AIPostTone {
  String get label {
    return switch (this) {
      _AIPostTone.professional => 'Professional',
      _AIPostTone.friendly => 'Friendly',
      _AIPostTone.promotional => 'Promotional',
      _AIPostTone.informative => 'Informative',
    };
  }
}

enum _AIPostLanguage { english, hindi, hinglish }

extension on _AIPostLanguage {
  String get label {
    return switch (this) {
      _AIPostLanguage.english => 'English',
      _AIPostLanguage.hindi => 'Hindi',
      _AIPostLanguage.hinglish => 'Hinglish',
    };
  }
}

enum _ManualCallToAction { none, callNow, learnMore, visitWebsite, bookNow }

extension on _ManualCallToAction {
  String get label {
    return switch (this) {
      _ManualCallToAction.none => 'None',
      _ManualCallToAction.callNow => 'Call Now',
      _ManualCallToAction.learnMore => 'Learn More',
      _ManualCallToAction.visitWebsite => 'Visit Website',
      _ManualCallToAction.bookNow => 'Book Now',
    };
  }
}

class _ManualMediaChoice {
  const _ManualMediaChoice({required this.label, required this.assetPath});

  final String label;
  final String assetPath;
}

const List<_ManualMediaChoice> _manualMediaChoices = <_ManualMediaChoice>[
  _ManualMediaChoice(label: 'Office', assetPath: 'assets/images/office.png'),
  _ManualMediaChoice(label: 'Doctor', assetPath: 'assets/images/doctor.png'),
  _ManualMediaChoice(label: 'Bakery', assetPath: 'assets/images/bakery.png'),
  _ManualMediaChoice(label: 'Salon', assetPath: 'assets/images/parlour.png'),
  _ManualMediaChoice(label: 'Fitness', assetPath: 'assets/images/fitness.png'),
  _ManualMediaChoice(label: 'Mall', assetPath: 'assets/images/mall.png'),
];

abstract final class _CreatePostPalette {
  static const background = Color(0xFFF7FAFD);
  static const fieldBorder = Color(0xFFC9D2DE);
}

String _buildAiHashtags({required String businessName, required String topic}) {
  final businessTag = businessName.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  final topicWords = topic
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(3)
      .map((word) => word.replaceAll(RegExp(r'[^A-Za-z0-9]'), ''))
      .where((word) => word.isNotEmpty)
      .map((word) => '#$word')
      .join(' ');

  return '#$businessTag #GoogleBusinessProfile #VisibloAI $topicWords'.trim();
}

String _manualMetaFromCallToAction({
  required String businessName,
  required _ManualCallToAction callToAction,
}) {
  final businessTag = businessName.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  final ctaTag = callToAction == _ManualCallToAction.none
      ? '#BrandUpdate'
      : '#${callToAction.label.replaceAll(' ', '')}';
  return '#$businessTag #GooglePost $ctaTag #LocalBusiness';
}

String _formatScheduleDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day-$month-$year $hour:$minute';
}
