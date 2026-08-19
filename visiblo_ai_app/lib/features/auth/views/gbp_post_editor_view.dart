import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/gbp_post.dart';
import '../widgets/auth_calendar_sheet.dart';
import '../widgets/auth_layout.dart';

class GbpPostEditorView extends StatefulWidget {
  const GbpPostEditorView({
    super.key,
    required this.initialPost,
    required this.businessName,
    this.isCreating = false,
  });

  final GbpPost initialPost;
  final String businessName;
  final bool isCreating;

  @override
  State<GbpPostEditorView> createState() => _GbpPostEditorViewState();
}

class _GbpPostEditorViewState extends State<GbpPostEditorView> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _metaController;
  late GbpPostStatus _status;
  DateTime? _scheduledFor;

  @override
  void initState() {
    super.initState();
    final post = widget.initialPost;
    _titleController = TextEditingController(text: post.title);
    _subtitleController = TextEditingController(text: post.subtitle);
    _metaController = TextEditingController(text: post.meta);
    _status = post.status;
    _scheduledFor = post.scheduledFor;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _metaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isScheduled = _status == GbpPostStatus.scheduled;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F9FF),
        foregroundColor: AppColors.brandBlue,
        title: Text(
          widget.isCreating ? 'Create Post' : 'Edit Post',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: AuthViewSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EditorCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: widget.initialPost.isBase64Asset
                          ? Image.memory(
                              base64Decode(widget.initialPost.assetPath.substring(widget.initialPost.assetPath.indexOf(',') + 1)),
                              width: double.infinity,
                              height: 190,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 190,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.image_not_supported_rounded,
                                      color: Colors.grey,
                                    ),
                                  ),
                            )
                          : widget.initialPost.isNetworkAsset
                          ? Image.network(
                              widget.initialPost.assetPath,
                              width: double.infinity,
                              height: 190,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 190,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.image_not_supported_rounded,
                                      color: Colors.grey,
                                    ),
                                  ),
                            )
                          : widget.initialPost.isFileAsset
                          ? Image.file(
                              File(widget.initialPost.assetPath),
                              width: double.infinity,
                              height: 190,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 190,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.image_not_supported_rounded,
                                      color: Colors.grey,
                                    ),
                                  ),
                            )
                          : Image.asset(
                              widget.initialPost.assetPath,
                              width: double.infinity,
                              height: 190,
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.businessName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isCreating
                          ? 'Tune the content before publishing or scheduling it.'
                          : 'Update the post details and save the latest version.',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AuthViewSpacing.cardGap),
              _EditorCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Post Status'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: GbpPostStatus.values.map((status) {
                        return _StatusChip(
                          label: _statusLabel(status),
                          selected: _status == status,
                          onTap: () {
                            setState(() {
                              _status = status;
                              if (_status != GbpPostStatus.scheduled) {
                                _scheduledFor = null;
                              } else {
                                _scheduledFor ??= DateTime.now().add(
                                  const Duration(days: 2),
                                );
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (isScheduled) ...[
                      const SizedBox(height: 18),
                      const _SectionTitle('Schedule Date'),
                      const SizedBox(height: 10),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _pickScheduleDate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FBFE),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFD9E5F2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: AppColors.brandBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _scheduledFor == null
                                    ? 'Pick a publish date'
                                    : _formatLongDate(_scheduledFor!),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _scheduledFor == null
                                      ? AppColors.mutedText
                                      : AppColors.text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.mutedText,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AuthViewSpacing.cardGap),
              _EditorCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Post Content'),
                    const SizedBox(height: 12),
                    _EditorField(
                      controller: _titleController,
                      label: 'Headline',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    _EditorField(
                      controller: _subtitleController,
                      label: 'Description',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    _EditorField(
                      controller: _metaController,
                      label: 'Hashtags',
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AuthViewSpacing.sectionGap),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePost,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.6,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          widget.isCreating ? 'Create Post' : 'Save Changes',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickScheduleDate() async {
    final initial =
        _scheduledFor ?? DateTime.now().add(const Duration(days: 2));
    final picked = await showAuthCalendarSheet(
      context: context,
      title: 'Schedule Calendar',
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime(2032),
    );

    if (picked != null) {
      setState(() {
        _scheduledFor = picked;
      });
    }
  }

  bool _isSaving = false;

  Future<void> _savePost() async {
    final title = _titleController.text.trim();
    final subtitle = _subtitleController.text.trim();
    final meta = _metaController.text.trim();

    if (title.isEmpty || subtitle.isEmpty || meta.isEmpty) {
      Get.snackbar(
        'Complete the post',
        'Add a headline, description, and hashtags before saving.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_status == GbpPostStatus.scheduled && _scheduledFor == null) {
      Get.snackbar(
        'Schedule date required',
        'Pick a publish date before saving a scheduled post.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      GbpPost? backendPost;
      if (!widget.isCreating && widget.initialPost.id.isNotEmpty) {
        // Save to backend
        final controller = Get.find<OnboardingController>();
        await controller.updateAiPost(
          widget.initialPost.id,
          title: title,
          content: subtitle,
        );
        // Note: we're only updating title and subtitle right now on the backend
        
        if (_status == GbpPostStatus.scheduled && _scheduledFor != null) {
          await controller.scheduleAiPost(widget.initialPost.id, _scheduledFor!);
        } else if (_status == GbpPostStatus.draft && widget.initialPost.status != GbpPostStatus.draft) {
          await controller.deleteAiPost(widget.initialPost.id, revertToDraft: true);
        } else if (_status == GbpPostStatus.live && widget.initialPost.status != GbpPostStatus.live) {
          // If they changed to live from editor, publish it
          backendPost = await controller.publishAiPost(widget.initialPost.id);
        }
      }

      final updated = (backendPost ?? widget.initialPost).copyWith(
        status: _status,
        title: title,
        subtitle: subtitle,
        meta: meta,
        scheduledFor: _status == GbpPostStatus.scheduled ? _scheduledFor : null,
      );

      if (mounted) {
        Get.back(result: updated);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Save Failed',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE7F3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F2746),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.brandBlue,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF8F9) : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFD7E0EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? AppColors.primaryDark : AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  const _EditorField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.text,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FBFE),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9E5F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9E5F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

String _statusLabel(GbpPostStatus status) {
  switch (status) {
    case GbpPostStatus.draft:
    case GbpPostStatus.failed:
      return 'Draft';
    case GbpPostStatus.scheduled:
      return 'Scheduled';
    case GbpPostStatus.live:
      return 'Live';
  }
}

String _formatLongDate(DateTime value) {
  const months = [
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
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}
