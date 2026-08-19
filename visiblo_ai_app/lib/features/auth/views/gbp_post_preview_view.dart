import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/gbp_post.dart';
import '../widgets/auth_layout.dart';
import 'gbp_post_editor_view.dart';

class GbpPostPreviewView extends StatelessWidget {
  const GbpPostPreviewView({
    super.key,
    required this.post,
    required this.businessName,
  });

  final GbpPost post;
  final String businessName;

  @override
  Widget build(BuildContext context) {
    final badgeColors = _badgeColorsFor(post.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F9FF),
        foregroundColor: AppColors.brandBlue,
        title: const Text(
          'Post Preview',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: AuthViewSpacing.pagePadding,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDDE7F3)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x100F2746),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF8F9),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            businessName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.brandBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            post.createdLabel,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColors.background,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        post.badgeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: badgeColors.foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: post.assetPath.isEmpty
                      ? Container(
                          width: double.infinity,
                          height: 220,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.image_outlined,
                            color: Color(0xFF90AFCC),
                            size: 48,
                          ),
                        )
                      : post.isBase64Asset
                      ? Image.memory(
                          base64Decode(post.assetPath.substring(post.assetPath.indexOf(',') + 1)),
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 220,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported_rounded,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                      : post.isNetworkAsset
                      ? Image.network(
                          post.assetPath,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 220,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported_rounded,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                      : post.isFileAsset
                      ? Image.file(
                          File(post.assetPath),
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 220,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported_rounded,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                      : Image.asset(
                          post.assetPath,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(height: 14),
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.25,
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  post.subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: AppColors.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                if (post.meta.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FBFE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDCE7F3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hashtags',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.meta,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (post.scheduledLabel != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6E8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFE0AF)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: Color(0xFFF3A53B),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          post.scheduledLabel!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF9A691B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Actions row
                if (post.status == GbpPostStatus.draft ||
                    post.status == GbpPostStatus.scheduled)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleDelete(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                          ),
                          label: const Text(
                            'Delete',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleEdit(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.brandBlue,
                            side: const BorderSide(color: Color(0xFFDCE7F3)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text(
                            'Edit',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _handlePublish(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text(
                            'Publish',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePublish(BuildContext context) async {
    try {
      final controller = Get.find<OnboardingController>();
      final publishedPost = await controller.publishAiPost(post.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published successfully!')),
        );
        Navigator.of(context).pop(publishedPost);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleEdit(BuildContext context) async {
    final updatedPost = await Get.to<GbpPost>(
      () => GbpPostEditorView(
        initialPost: post,
        businessName: businessName,
        isCreating: false,
      ),
    );

    if (updatedPost != null && context.mounted) {
      // Return the updated post back so the list can refresh
      Navigator.of(context).pop(updatedPost);
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    try {
      final controller = Get.find<OnboardingController>();
      await controller.deleteAiPost(post.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }
}

({Color foreground, Color background}) _badgeColorsFor(GbpPostStatus status) {
  switch (status) {
    case GbpPostStatus.live:
      return (foreground: AppColors.white, background: const Color(0xFF52C271));
    case GbpPostStatus.draft:
    case GbpPostStatus.failed:
      return (
        foreground: const Color(0xFF7C63F1),
        background: const Color(0xFFF3EEFF),
      );
    case GbpPostStatus.scheduled:
      return (
        foreground: const Color(0xFFF3A53B),
        background: const Color(0xFFFFF2E1),
      );
  }
}
