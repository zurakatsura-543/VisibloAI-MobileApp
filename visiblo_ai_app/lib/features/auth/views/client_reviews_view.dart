import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_logo.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/gbp_review.dart';
import '../widgets/auth_navigation_shell.dart';

enum _ClientReviewFilter { all, unread, replied }

const String _reviewFontFamily = 'Inter';
const Color _reviewInk = Color(0xFF102641);
const Color _reviewBlue = Color(0xFF11418C);
const Color _reviewMuted = Color(0xFF61738C);
const Color _reviewBorder = Color(0xFFDCE6F1);
const Color _reviewPurple = Color(0xFF6D45F4);

class ClientReviewsView extends StatefulWidget {
  const ClientReviewsView({super.key});

  @override
  State<ClientReviewsView> createState() => _ClientReviewsViewState();
}

class _ClientReviewsViewState extends State<ClientReviewsView> {
  final OnboardingController _controller = Get.find<OnboardingController>();
  final Set<String> _expandedReviewIds = <String>{};

  late _ClientReviewFilter _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = _filterFromArgument(Get.arguments);
  }

  @override
  Widget build(BuildContext context) {
    return AuthNavigationShell(
      currentTab: AuthTab.home,
      backgroundColor: const Color(0xFFF4F6FA),
      child: Obx(() {
        final user = _controller.currentUser.value;
        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final reviews = _controller.liveGbpReviews.isNotEmpty
            ? _controller.liveGbpReviews
            : (user.backendAuthenticated || user.googleBusinessProfileConnected)
            ? const <GbpReview>[]
            : _controller
                  .businessReviewsFor(user)
                  .map(
                    (br) => GbpReview(
                      id: br.id,
                      reviewId: br.id,
                      reviewerName: br.reviewerName,
                      starRating: br.rating,
                      commentText: br.comment,
                      reviewCreatedAt: '', // Mock data doesn't have ISO date
                      reviewUpdatedAt: '',
                      ownerReplyText: br.ownerReply,
                      ownerReplyUpdatedAt: br.ownerReply,
                      showSuggestedReplyCard: br.showSuggestedReplyCard,
                    ),
                  )
                  .toList();
        final filteredReviews = _filteredReviews(reviews);
        final allCount = reviews.length;
        final unreadCount = reviews
            .where((review) => !review.hasOwnerReply)
            .length;
        final repliedCount = reviews
            .where((review) => review.hasOwnerReply)
            .length;

        return Column(
          children: [
            const _ReviewsTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review Management',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: _reviewFontFamily,
                        fontSize: 21,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        color: _reviewInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage and reply to your customer reviews',
                      style: TextStyle(
                        fontFamily: _reviewFontFamily,
                        fontSize: 14,
                        height: 1.2,
                        color: Color(0xFF42516A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ReviewFilterChip(
                            label: 'All',
                            count: allCount,
                            selected:
                                _selectedFilter == _ClientReviewFilter.all,
                            onTap: () {
                              setState(() {
                                _selectedFilter = _ClientReviewFilter.all;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ReviewFilterChip(
                            label: 'Unread',
                            count: unreadCount,
                            selected:
                                _selectedFilter == _ClientReviewFilter.unread,
                            onTap: () {
                              setState(() {
                                _selectedFilter = _ClientReviewFilter.unread;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ReviewFilterChip(
                            label: 'Replied',
                            count: repliedCount,
                            selected:
                                _selectedFilter == _ClientReviewFilter.replied,
                            onTap: () {
                              setState(() {
                                _selectedFilter = _ClientReviewFilter.replied;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (filteredReviews.isEmpty)
                      const _EmptyReviewState()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        primary: false,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredReviews.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final review = filteredReviews[index];
                          final isExpanded = _expandedReviewIds.contains(
                            review.id,
                          );

                          return _ReviewCard(
                            review: review,
                            isExpanded: isExpanded,
                            onToggleExpanded: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedReviewIds.remove(review.id);
                                } else {
                                  _expandedReviewIds.add(review.id);
                                }
                              });
                            },
                            onApplySuggestion: () async {
                              await _controller.applySuggestedBusinessReply(
                                review.id,
                              );
                              if (!mounted) {
                                return;
                              }
                              Get.snackbar(
                                'Reply applied',
                                'Suggested reply added for ${review.reviewerName}.',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            },
                            onCustomizeSuggestion: () =>
                                _openReplyEditor(review),
                            onEditReply: () => _openReplyEditor(review),
                            onDeleteReply: () => _deleteReply(review),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  List<GbpReview> _filteredReviews(List<GbpReview> reviews) {
    return switch (_selectedFilter) {
      _ClientReviewFilter.all => reviews,
      _ClientReviewFilter.unread =>
        reviews.where((review) => !review.hasOwnerReply).toList(),
      _ClientReviewFilter.replied =>
        reviews.where((review) => review.hasOwnerReply).toList(),
    };
  }

  Future<void> _openReplyEditor(GbpReview review) async {
    final initialText = review.hasOwnerReply
        ? review.ownerReply
        : review.suggestedReply;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder: (sheetContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 18,
          ),
          child: _ReplyEditorSheet(
            review: review,
            initialText: initialText,
            onSave: (trimmedReply) async {
              if (trimmedReply.isEmpty) {
                Get.snackbar(
                  'Reply required',
                  'Please write a reply before saving.',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }

              final shouldPost = await showDialog<bool>(
                context: sheetContext,
                builder: (ctx) => AlertDialog(
                  title: const Text('Post Reply?'),
                  content: const Text(
                    'Are you sure you want to post this reply to Google Business Profile? The reviewer will be notified.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text(
                        'Post Reply',
                        style: TextStyle(
                          color: Color(0xFF44BBC5),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (shouldPost != true) return;

              if (!sheetContext.mounted) return;
              Navigator.of(sheetContext).pop();
              await _controller.saveBusinessReviewReply(
                reviewId: review.id,
                reply: trimmedReply,
              );
              if (!mounted) {
                return;
              }
              Get.snackbar(
                'Reply saved',
                'Owner reply updated for ${review.reviewerName}.',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteReply(GbpReview review) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete reply?'),
            content: Text(
              'Remove the current owner reply for ${review.reviewerName}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Color(0xFFE35B52)),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    await _controller.deleteBusinessReviewReply(review.id);
    if (!mounted) {
      return;
    }
    Get.snackbar(
      'Reply deleted',
      'Owner reply removed for ${review.reviewerName}.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

class _ReviewsTopBar extends StatelessWidget {
  const _ReviewsTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5EDF6))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            const AppLogo(iconSize: 33, fontSize: 23),
            const Spacer(),
            IconButton(
              onPressed: () => Get.toNamed(AppRoutes.alerts),
              splashRadius: 22,
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: _reviewInk,
                size: 25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewFilterChip extends StatelessWidget {
  const _ReviewFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
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
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE8F1FF) : AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? const Color(0xFFDCE8FF) : _reviewBorder,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C0F2746),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: _reviewFontFamily,
                  fontSize: 14,
                  color: selected ? const Color(0xFF1768E8) : _reviewInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontFamily: _reviewFontFamily,
                      fontSize: 12,
                      color: Color(0xFF1768E8),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onApplySuggestion,
    required this.onCustomizeSuggestion,
    required this.onEditReply,
    required this.onDeleteReply,
  });

  final GbpReview review;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onApplySuggestion;
  final VoidCallback onCustomizeSuggestion;
  final VoidCallback onEditReply;
  final VoidCallback onDeleteReply;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE3EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2746),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewerAvatar(
                label: review.reviewerInitial,
                tone: review.avatarTone,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: _reviewFontFamily,
                        fontSize: 14.3,
                        height: 1.05,
                        color: _reviewInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _StarRatingRow(stars: review.starRating),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _reviewTimeLabel(review),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: _reviewFontFamily,
                              fontSize: 10.5,
                              color: Color(0xFF6B7586),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const _GoogleBusinessBadge(),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            review.comment,
            maxLines: isExpanded ? null : 3,
            overflow: isExpanded ? null : TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: _reviewFontFamily,
              fontSize: 13.2,
              height: 1.24,
              color: Color(0xFF101827),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (review.comment.length > 95) ...[
            const SizedBox(height: 5),
            InkWell(
              onTap: onToggleExpanded,
              child: Text(
                isExpanded ? 'Show less' : 'Read more',
                style: const TextStyle(
                  fontFamily: _reviewFontFamily,
                  fontSize: 12,
                  color: Color(0xFF1768E8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (!review.hasOwnerReply) ...[
            const SizedBox(height: 13),
            _SuggestedReplyCard(
              replyText: review.suggestedReply,
              onApply: onApplySuggestion,
              onCustomize: onCustomizeSuggestion,
            ),
          ] else ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF8E7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Replied',
                  style: TextStyle(
                    fontFamily: _reviewFontFamily,
                    fontSize: 12,
                    color: Color(0xFF26A45F),
                    fontWeight: FontWeight.w800,
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

class _ReviewerAvatar extends StatelessWidget {
  const _ReviewerAvatar({required this.label, required this.tone});

  final String label;
  final int tone;

  @override
  Widget build(BuildContext context) {
    const tones = <Color>[
      Color(0xFF7247D8),
      Color(0xFF8B5CF6),
      Color(0xFF7C6A64),
      Color(0xFF2563EB),
      Color(0xFF0F766E),
      Color(0xFFB45309),
    ];

    final background = tones[tone % tones.length];

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x160F2746),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: _reviewFontFamily,
          fontSize: 17,
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GoogleBusinessBadge extends StatelessWidget {
  const _GoogleBusinessBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 91,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/google-my-business-icon.png',
            width: 34,
            height: 34,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 5),
          const Flexible(
            child: Text(
              'Google\nBusiness Profile',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: _reviewFontFamily,
                fontSize: 9.6,
                height: 1.05,
                color: _reviewInk,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRatingRow extends StatelessWidget {
  const _StarRatingRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(
        5,
        (index) => Icon(
          index < stars ? Icons.star_rounded : Icons.star_border_rounded,
          size: 15.5,
          color: const Color(0xFFF6B600),
        ),
      ),
    );
  }
}

class _SuggestedReplyCard extends StatelessWidget {
  const _SuggestedReplyCard({
    required this.replyText,
    required this.onApply,
    required this.onCustomize,
  });

  final String replyText;
  final VoidCallback onApply;
  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF2F9FF), Color(0xFFEAF5FF)],
        ),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFD8E7F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.auto_awesome_rounded,
                size: 17,
                color: Color(0xFF0BBBD3),
              ),
              SizedBox(width: 7),
              Text(
                'AI Suggested Reply',
                style: TextStyle(
                  fontFamily: _reviewFontFamily,
                  fontSize: 12.8,
                  height: 1.1,
                  color: _reviewInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFCBDCEC)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    replyText,
                    style: const TextStyle(
                      fontFamily: _reviewFontFamily,
                      fontSize: 12.8,
                      height: 1.28,
                      color: Color(0xFF182236),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: replyText));
                    Get.snackbar(
                      'Copied',
                      'AI suggested reply copied.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: Color(0xFF66779A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCustomize,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFFD4DFEC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    foregroundColor: _reviewInk,
                    backgroundColor: Colors.white,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_outlined, size: 17),
                      SizedBox(width: 7),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontFamily: _reviewFontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onApply,
                    borderRadius: BorderRadius.circular(999),
                    child: Ink(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1768FF), Color(0xFF075EEB)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'Reply',
                            style: TextStyle(
                              fontFamily: _reviewFontFamily,
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _ReplyEditorSheet extends StatefulWidget {
  const _ReplyEditorSheet({
    required this.review,
    required this.initialText,
    required this.onSave,
  });

  final GbpReview review;
  final String initialText;
  final Future<void> Function(String) onSave;

  @override
  State<_ReplyEditorSheet> createState() => _ReplyEditorSheetState();
}

class _ReplyEditorSheetState extends State<_ReplyEditorSheet> {
  bool _isGenerating = false;
  Map<String, dynamic>? _aiResult;
  late TextEditingController _replyController;
  late FocusNode _replyFocusNode;

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController(text: widget.initialText);
    _replyFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _generateAiReply({String? manualReviewType}) async {
    setState(() {
      _isGenerating = true;
    });
    try {
      final controller = Get.find<OnboardingController>();
      final result = await controller.generateAiReviewReply(
        widget.review,
        manualReviewType: manualReviewType,
      );
      if (result['reply'] != null && result['reply'].toString().isNotEmpty) {
        _replyController.text = result['reply'].toString();
      }
      setState(() {
        _aiResult = result;
      });
    } catch (e) {
      Get.snackbar(
        'AI Generation Failed',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Widget _buildSentimentAnalysis() {
    if (_aiResult == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF7FBFF)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _reviewBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F8FA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_outlined,
                    size: 16,
                    color: Color(0xFF2C98A6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI Sentiment Analysis',
                    style: AppTypography.button(
                      fontSize: 14.2,
                      color: _reviewInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Generate an analysis to classify the review, estimate confidence, and draft a safer reply.',
              style: AppTypography.body(
                fontSize: 12.4,
                color: _reviewMuted,
                fontWeight: FontWeight.w500,
                height: 1.42,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isGenerating ? null : _generateAiReply,
                style: FilledButton.styleFrom(
                  backgroundColor: _reviewBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_fix_high_rounded, size: 16),
                label: Text(
                  _isGenerating ? 'Analyzing...' : 'Analyze with VisibloAI',
                  style: AppTypography.button(
                    fontSize: 13.3,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final sentiment =
        _aiResult!['sentiment']?.toString().toUpperCase() ?? 'UNKNOWN';
    final sentimentColor = sentiment == 'POSITIVE'
        ? const Color(0xFF49A15E)
        : sentiment == 'NEGATIVE'
        ? const Color(0xFFE35B52)
        : const Color(0xFFEA8A3A);
    final sentimentBg = sentiment == 'POSITIVE'
        ? const Color(0xFFEAF9EE)
        : sentiment == 'NEGATIVE'
        ? const Color(0xFFFDECEA)
        : const Color(0xFFFEF3EB);

    final confidence = ((_aiResult!['confidence'] as num?) ?? 0) * 100;

    final riskLevel =
        _aiResult!['riskLevel']?.toString().toUpperCase() ?? 'UNKNOWN RISK';
    final riskColor = riskLevel == 'LOW RISK' || riskLevel == 'LOW'
        ? const Color(0xFF49A15E)
        : riskLevel.contains('HIGH')
        ? const Color(0xFFE35B52)
        : const Color(0xFFEA8A3A);
    final riskBg = riskLevel == 'LOW RISK' || riskLevel == 'LOW'
        ? const Color(0xFFEAF9EE)
        : riskLevel.contains('HIGH')
        ? const Color(0xFFFDECEA)
        : const Color(0xFFFEF3EB);

    final reviewTypeRaw = _aiResult!['reviewType']?.toString() ?? 'unknown';
    final reviewTypeLabel =
        reviewTypeRaw.replaceAll('_', ' ').capitalizeFirst ?? reviewTypeRaw;

    final reason = _aiResult!['reason']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF8FBFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _reviewBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F8FA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.thumb_up_alt_outlined,
                  size: 16,
                  color: Color(0xFF2C98A6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Sentiment Analysis',
                  style: AppTypography.button(
                    fontSize: 14.2,
                    color: _reviewInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: sentimentBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  sentiment,
                  style: AppTypography.label(
                    fontSize: 9.8,
                    color: sentimentColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Confidence:',
                style: AppTypography.body(
                  fontSize: 12.5,
                  color: const Color(0xFF4B79D8),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6EEF5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor:
                        (_aiResult!['confidence'] as num?)?.toDouble() ?? 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C98A6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${confidence.toInt()}%',
                style: AppTypography.button(
                  fontSize: 12.8,
                  color: const Color(0xFF1F3556),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8FA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  reviewTypeLabel,
                  style: AppTypography.label(
                    fontSize: 10.6,
                    color: const Color(0xFF2C98A6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: riskBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  riskLevel.contains('RISK') ? riskLevel : '$riskLevel RISK',
                  style: AppTypography.label(
                    fontSize: 10.6,
                    color: riskColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                reason,
                style: AppTypography.body(
                  fontSize: 12,
                  color: const Color(0xFF6F7D90),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'AI GOT IT WRONG? ADJUST ANALYSIS',
            style: AppTypography.label(
              fontSize: 9.8,
              color: const Color(0xFF6F7D90),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.55,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAdjustChip('Positive', 'positive'),
              _buildAdjustChip('Neutral', 'neutral'),
              _buildAdjustChip('Complaint', 'genuine_negative'),
              _buildAdjustChip('Wrong business', 'wrong_business'),
              _buildAdjustChip('No comment', 'no_comment'),
              _buildAdjustChip(
                'Rating mismatch',
                widget.review.starRating <= 2
                    ? 'rating_mismatch_positive'
                    : 'rating_mismatch_negative',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustChip(String label, String value) {
    return InkWell(
      onTap: () => _generateAiReply(manualReviewType: value),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE1E8F2)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTypography.label(
            fontSize: 10.6,
            color: const Color(0xFF4C5A6D),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final suggestedReply = _replyController.text.trim();
    final quotedReview = widget.review.comment;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFCFEFF), Colors.white],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330F2746),
              blurRadius: 30,
              offset: Offset(0, 16),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE5F1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Client Reviews',
                      style: AppTypography.card(
                        fontSize: 18,
                        color: _reviewInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 18,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF7B8A9E),
                    ),
                  ),
                ],
              ),
              Text(
                'Manage and respond to Google Business Profile reviews powered by VisibloAI',
                style: AppTypography.body(
                  fontSize: 12.6,
                  color: _reviewMuted,
                  fontWeight: FontWeight.w500,
                  height: 1.42,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _reviewBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE9F9FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.format_quote_rounded,
                        color: _reviewBlue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '"$quotedReview"',
                        style: AppTypography.body(
                          fontSize: 15,
                          color: _reviewInk,
                          fontWeight: FontWeight.w600,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildSentimentAnalysis(),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFCFAFF), Color(0xFFF6F1FF)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE8DEFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 15,
                            color: Color(0xFF6B38E0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'VISIBLOAI SUGGESTED REPLY',
                            style: AppTypography.label(
                              fontSize: 10.5,
                              color: _reviewPurple,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.45,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'AI Draft',
                            style: TextStyle(
                              fontFamily: _reviewFontFamily,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _reviewPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        suggestedReply.isEmpty
                            ? 'Generate a reply or type your own response below.'
                            : suggestedReply,
                        style: AppTypography.body(
                          fontSize: 13.4,
                          color: _reviewInk,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ReplyActionChip(
                          label: 'Use this reply',
                          icon: Icons.send_outlined,
                          foreground: _reviewBlue,
                          filled: true,
                          onTap: () =>
                              widget.onSave(_replyController.text.trim()),
                        ),
                        _ReplyActionChip(
                          label: 'Edit reply',
                          icon: Icons.edit_outlined,
                          foreground: _reviewPurple,
                          onTap: () => _replyFocusNode.requestFocus(),
                        ),
                        _ReplyActionChip(
                          label: _isGenerating ? 'Generating...' : 'Regenerate',
                          icon: Icons.refresh_rounded,
                          foreground: _reviewPurple,
                          onTap: _isGenerating ? null : _generateAiReply,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Write your reply',
                style: AppTypography.button(
                  fontSize: 18,
                  color: _reviewInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Write a professional and helpful response.',
                style: AppTypography.body(
                  fontSize: 12.4,
                  color: _reviewMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFCBE3F4)),
                  color: const Color(0xFFFCFEFF),
                ),
                child: TextField(
                  controller: _replyController,
                  focusNode: _replyFocusNode,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Craft your perfect response here...',
                    hintStyle: AppTypography.body(
                      fontSize: 12.6,
                      color: const Color(0xFF9AA5B4),
                      fontWeight: FontWeight.w500,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFCFEFF),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  style: AppTypography.body(
                    fontSize: 13.4,
                    color: const Color(0xFF44556A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => widget.onSave(_replyController.text.trim()),
                  style: FilledButton.styleFrom(
                    backgroundColor: _reviewBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.send_outlined, size: 17),
                  label: Text(
                    'Reply to review',
                    style: AppTypography.button(
                      fontSize: 13.2,
                      color: Colors.white,
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
}

class _ReplyActionChip extends StatelessWidget {
  const _ReplyActionChip({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: filled ? Colors.white : foreground,
        side: BorderSide(
          color: filled
              ? Colors.transparent
              : foreground.withValues(alpha: 0.35),
        ),
        backgroundColor: filled ? foreground : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      icon: Icon(icon, size: 15),
      label: Text(
        label,
        style: AppTypography.label(
          fontSize: 10.8,
          color: filled ? Colors.white : foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyReviewState extends StatelessWidget {
  const _EmptyReviewState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _reviewBorder),
      ),
      child: const Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 32, color: Color(0xFF8AA0B6)),
          SizedBox(height: 10),
          Text(
            'No reviews match this filter.',
            style: TextStyle(
              fontFamily: _reviewFontFamily,
              fontSize: 14,
              color: _reviewMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

_ClientReviewFilter _filterFromArgument(Object? argument) {
  final filterValue = argument is String ? argument : 'all';
  return switch (filterValue) {
    'needsReply' || 'unread' => _ClientReviewFilter.unread,
    'replied' => _ClientReviewFilter.replied,
    _ => _ClientReviewFilter.all,
  };
}

String _reviewTimeLabel(GbpReview review) {
  final createdAt = review.reviewCreatedAt.trim();
  if (createdAt.isEmpty) {
    return review.reviewDateLabel;
  }
  final date = DateTime.tryParse(createdAt);
  if (date == null) {
    return review.reviewDateLabel;
  }
  final diff = DateTime.now().difference(date.toLocal());
  if (diff.inMinutes < 1) {
    return 'Just now';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes} min ago';
  }
  if (diff.inDays < 1) {
    return '${diff.inHours} hours ago';
  }
  if (diff.inDays == 1) {
    return '1 day ago';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays} days ago';
  }
  return review.reviewDateLabel;
}
