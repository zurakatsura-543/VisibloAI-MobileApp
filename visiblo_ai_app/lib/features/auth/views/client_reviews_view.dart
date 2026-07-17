import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_logo.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/gbp_review.dart';
import '../models/test_account.dart';
import '../widgets/auth_navigation_shell.dart';

enum _ClientReviewFilter { all, needsReply, positive, negative }

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
            : (user.backendAuthenticated ||
                      user.googleBusinessProfileConnected)
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
                            reviewCreatedAt:
                                '', // Mock data doesn't have ISO date
                            reviewUpdatedAt: '',
                            ownerReplyText: br.ownerReply,
                            ownerReplyUpdatedAt: br.ownerReply,
                            showSuggestedReplyCard:
                                br.showSuggestedReplyCard,
                          ),
                        )
                        .toList();
        final filteredReviews = _filteredReviews(reviews);
        final averageRating = _controller.averageBusinessReviewScore(
          user: user,
        );

        return Column(
          children: [
            _ReviewsTopBar(onCreatePost: () => Get.toNamed(AppRoutes.gbpPosts)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client Reviews',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F3556),
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF5B6780),
                          height: 1.45,
                        ),
                        children: const [
                          TextSpan(
                            text:
                                'Manage and respond to Google Business Profile reviews powered by ',
                          ),
                          TextSpan(
                            text: 'VisibloAI',
                            style: TextStyle(
                              color: Color(0xFF4B79D8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SyncReviewsButton(
                      onTap: () async {
                        await _controller.syncBusinessReviewsFromGoogle();
                        if (!mounted) {
                          return;
                        }
                        final syncedCount = _controller.liveGbpReviews.length;
                        Get.snackbar(
                          'Sync complete',
                          '$syncedCount reviews synced from Google.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _LocationSummaryCard(
                      user: user,
                      averageRating: averageRating,
                      reviewCount: reviews.length,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Reviews',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3F3F46),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _ClientReviewFilter.values
                            .map(
                              (filter) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _ReviewFilterChip(
                                  label: _filterLabel(filter),
                                  selected: filter == _selectedFilter,
                                  onTap: () {
                                    setState(() {
                                      _selectedFilter = filter;
                                    });
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 6),
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
                            const SizedBox(height: 8),
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
      _ClientReviewFilter.needsReply =>
        reviews.where((review) => !review.hasOwnerReply).toList(),
      _ClientReviewFilter.positive =>
        reviews.where((review) => review.isPositive).toList(),
      _ClientReviewFilter.negative =>
        reviews.where((review) => review.isNegative).toList(),
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
  const _ReviewsTopBar({required this.onCreatePost});

  final VoidCallback onCreatePost;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFD8DFEA))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            const AuthShellBackButton(),
            const SizedBox(width: 10),
            const AppLogo(iconSize: 34, fontSize: 22),
            const Spacer(),
            InkWell(
              onTap: onCreatePost,
              borderRadius: BorderRadius.circular(999),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Create Post',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF275AAE),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncReviewsButton extends StatelessWidget {
  const _SyncReviewsButton({required this.onTap});

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
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xFF44BBC5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sync_rounded, size: 18, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Sync from Google',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
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

class _LocationSummaryCard extends StatelessWidget {
  const _LocationSummaryCard({
    required this.user,
    required this.averageRating,
    required this.reviewCount,
  });

  final TestAccount user;
  final double averageRating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight = constraints.maxWidth < 360;
        final cardHeight = isTight ? 136.0 : 130.0;

        return SizedBox(
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: isTight ? 7 : 8,
                child: _LocationMapPreview(user: user),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: isTight ? 4 : 3,
                child: _ReviewScoreCard(
                  averageRating: averageRating,
                  reviewCount: reviewCount,
                  compact: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LocationMapPreview extends StatelessWidget {
  const _LocationMapPreview({required this.user});

  final TestAccount user;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openBusinessMap(user),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                SvgPicture.asset(
                  'assets/images/location_map_preview.svg',
                  fit: BoxFit.cover,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        const Color(0xFF0F2746).withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.93),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _businessDisplayName(user),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.8,
                            color: Color(0xFF24466F),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.place_rounded,
                                size: 12,
                                color: Color(0xFF6F7B8C),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _businessLocationWords(user),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.8,
                                  height: 1.25,
                                  color: Color(0xFF6F7B8C),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  left: 10,
                  top: 10,
                  child: Icon(
                    Icons.place_rounded,
                    size: 20,
                    color: Color(0xFF33B7C8),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 12,
                          color: Color(0xFF29538A),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Open map',
                          style: TextStyle(
                            fontSize: 10.6,
                            color: Color(0xFF29538A),
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

class _ReviewScoreCard extends StatelessWidget {
  const _ReviewScoreCard({
    required this.averageRating,
    required this.reviewCount,
    this.compact = false,
  });

  final double averageRating;
  final int reviewCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final compactContent = LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 104;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'GOOGLE REVIEW',
                maxLines: 1,
                style: TextStyle(
                  fontSize: isNarrow ? 9.8 : 10.2,
                  color: const Color(0xFF7A8798).withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.35,
                ),
              ),
            ),
            const Spacer(),
            Text(
              averageRating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: isNarrow ? 26 : 28,
                height: 1,
                color: const Color(0xFF214B7B),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            const FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: _StarRatingRow(stars: 5),
            ),
            const SizedBox(height: 3),
            Text(
              '$reviewCount reviews',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isNarrow ? 10.2 : 11,
                color: const Color(0xFF7C8798),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 12,
        compact ? 10 : 14,
        compact ? 10 : 12,
        compact ? 9 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: compact
          ? compactContent
          : Row(
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 34,
                    height: 1,
                    color: Color(0xFF214B7B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _StarRatingRow(stars: 5),
                    const SizedBox(height: 4),
                    Text(
                      'avg rating | $reviewCount Google reviews',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF7C8798),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _ReviewFilterChip extends StatelessWidget {
  const _ReviewFilterChip({
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
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF46BBC4) : AppColors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFF46BBC4)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.8,
              color: selected ? Colors.white : const Color(0xFF546274),
              fontWeight: FontWeight.w600,
            ),
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
    final needsExpand = review.comment.length > 85;

    return InkWell(
      onTap: review.hasOwnerReply ? onEditReply : onCustomizeSuggestion,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE3E8F1)),
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
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF214B7B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        review.reviewDateLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A0B1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _StarRatingRow(stars: review.starRating),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              review.comment,
              maxLines: isExpanded || !needsExpand ? null : 3,
              overflow: isExpanded || !needsExpand
                  ? null
                  : TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF343F52),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (needsExpand) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: onToggleExpanded,
                child: Text(
                  isExpanded ? 'Show less' : 'View full review...',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF1DB3C0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ReviewStatusChip(review: review),
                _ReviewTextAction(
                  label: review.hasOwnerReply ? 'Edit reply' : 'Type reply',
                  color: const Color(0xFFEA8A3A),
                  onTap: onEditReply,
                ),
                _ReviewTextAction(
                  label: review.hasOwnerReply
                      ? 'Delete reply'
                      : 'Apply suggestion',
                  color: review.hasOwnerReply
                      ? const Color(0xFFE45B52)
                      : const Color(0xFF4A20C9),
                  onTap: review.hasOwnerReply
                      ? onDeleteReply
                      : onApplySuggestion,
                ),
              ],
            ),
            if (!review.hasOwnerReply && review.showSuggestedReplyCard) ...[
              const SizedBox(height: 10),
              _SuggestedReplyCard(
                replyText: review.suggestedReply,
                onApply: onApplySuggestion,
                onCustomize: onCustomizeSuggestion,
              ),
            ],
            if (review.hasOwnerReply) ...[
              const SizedBox(height: 10),
              _OwnerReplyCard(review: review),
            ],
          ],
        ),
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
      Color(0xFFE8E3FF),
      Color(0xFFFFE0F1),
      Color(0xFFE5F4FF),
      Color(0xFFE7FFE8),
      Color(0xFFFFF0D8),
      Color(0xFFE1F1FF),
    ];

    final background = tones[tone % tones.length];

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF6C4CE6),
          fontWeight: FontWeight.w700,
        ),
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
          size: 15,
          color: const Color(0xFFF6B600),
        ),
      ),
    );
  }
}

class _ReviewStatusChip extends StatelessWidget {
  const _ReviewStatusChip({required this.review});

  final GbpReview review;

  @override
  Widget build(BuildContext context) {
    final hasReply = review.hasOwnerReply;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasReply ? const Color(0xFFEAF9EE) : const Color(0xFFE8F8FA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: hasReply ? const Color(0xFFB9E5C5) : const Color(0xFFBDE7EA),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasReply
                ? Icons.check_circle_outline_rounded
                : Icons.chat_bubble_outline_rounded,
            size: 13,
            color: hasReply ? const Color(0xFF49A15E) : const Color(0xFF2C98A6),
          ),
          const SizedBox(width: 4),
          Text(
            hasReply ? 'REPLIED' : 'NEEDS REPLY',
            style: TextStyle(
              fontSize: 11,
              color: hasReply
                  ? const Color(0xFF49A15E)
                  : const Color(0xFF2C98A6),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTextAction extends StatelessWidget {
  const _ReviewTextAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE3D7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              _SuggestedReplyBadge(),
              SizedBox(width: 8),
              Text(
                'VISIBLOAI SUGGESTED\nREPLY',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.15,
                  color: Color(0xFF6B38E0),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            replyText,
            style: const TextStyle(
              fontSize: 12.6,
              height: 1.45,
              color: Color(0xFF4D5566),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCustomize,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    side: const BorderSide(color: Color(0xFFCCBEFF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    foregroundColor: const Color(0xFF6B38E0),
                  ),
                  child: const Text(
                    'Edit Reply',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onApply,
                    borderRadius: BorderRadius.circular(6),
                    child: Ink(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A20C9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Text(
                          'Apply Suggestion',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

class _SuggestedReplyBadge extends StatelessWidget {
  const _SuggestedReplyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: const [
          Positioned(
            left: 4.5,
            bottom: 3.5,
            child: Icon(
              Icons.auto_fix_high_rounded,
              size: 10.5,
              color: Color(0xFF5A31E6),
            ),
          ),
          Positioned(
            top: 3.5,
            right: 4,
            child: Icon(Icons.star_rounded, size: 5, color: Color(0xFF5A31E6)),
          ),
          Positioned(
            top: 7.5,
            left: 4,
            child: Icon(
              Icons.star_rounded,
              size: 3.8,
              color: Color(0xFF8A6BFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerReplyCard extends StatelessWidget {
  const _OwnerReplyCard({required this.review});

  final GbpReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBDEBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '# Owner Reply',
            style: TextStyle(
              fontSize: 11.5,
              color: const Color(0xFF1C7E90).withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            review.ownerReply,
            style: const TextStyle(
              fontSize: 13.2,
              height: 1.45,
              color: Color(0xFF4D5566),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (review.ownerReplyUpdatedLabel.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.ownerReplyUpdatedLabel,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6C7A8D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6EDF5)),
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
                      color: const Color(0xFF1F3556),
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
                color: const Color(0xFF68788E),
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
                  backgroundColor: const Color(0xFF44BBC5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EDF5)),
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
                    color: const Color(0xFF1F3556),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330F2746),
              blurRadius: 30,
              offset: Offset(0, 16),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Client Reviews',
                      style: AppTypography.card(
                        fontSize: 18,
                        color: const Color(0xFF1F3556),
                        fontWeight: FontWeight.w700,
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
                  color: const Color(0xFF66778C),
                  fontWeight: FontWeight.w500,
                  height: 1.42,
                ),
              ),
              const SizedBox(height: 12),
              _buildSentimentAnalysis(),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFEFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE6EDF5)),
                ),
                child: Text(
                  '"$quotedReview"',
                  style: AppTypography.body(
                    fontSize: 14,
                    color: const Color(0xFF5A6E87),
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2D7FF)),
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
                              color: const Color(0xFF6B38E0),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.45,
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
                          fontSize: 12.6,
                          color: const Color(0xFF4D5566),
                          fontWeight: FontWeight.w500,
                          height: 1.45,
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
                          foreground: const Color(0xFF6B38E0),
                          onTap: () =>
                              widget.onSave(_replyController.text.trim()),
                        ),
                        _ReplyActionChip(
                          label: 'Edit reply',
                          icon: Icons.edit_outlined,
                          foreground: const Color(0xFF6B38E0),
                          onTap: () => _replyFocusNode.requestFocus(),
                        ),
                        _ReplyActionChip(
                          label: _isGenerating ? 'Generating...' : 'Regenerate',
                          icon: Icons.refresh_rounded,
                          foreground: const Color(0xFF6B38E0),
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
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Write a professional and helpful response.',
                style: AppTypography.body(
                  fontSize: 12.4,
                  color: const Color(0xFF68788E),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF44BBC5)),
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
                    fillColor: const Color(0xFFFBFDFE),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  style: AppTypography.body(
                    fontSize: 13,
                    color: const Color(0xFF44556A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: SizedBox(
                  width: 158,
                  child: FilledButton.icon(
                    onPressed: () =>
                        widget.onSave(_replyController.text.trim()),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF44BBC5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.send_outlined, size: 15),
                    label: Text(
                      'Reply to review',
                      style: AppTypography.button(
                        fontSize: 12.4,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
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
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        side: BorderSide(color: foreground.withValues(alpha: 0.35)),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      icon: Icon(icon, size: 15),
      label: Text(
        label,
        style: AppTypography.label(
          fontSize: 10.8,
          color: foreground,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 32, color: Color(0xFF8AA0B6)),
          SizedBox(height: 10),
          Text(
            'No reviews match this filter.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF4C5A6D),
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
    'needsReply' => _ClientReviewFilter.needsReply,
    'positive' => _ClientReviewFilter.positive,
    'negative' => _ClientReviewFilter.negative,
    _ => _ClientReviewFilter.all,
  };
}

String _filterLabel(_ClientReviewFilter filter) {
  return switch (filter) {
    _ClientReviewFilter.all => 'All',
    _ClientReviewFilter.needsReply => 'Needs reply',
    _ClientReviewFilter.positive => 'Positive',
    _ClientReviewFilter.negative => 'Negative',
  };
}

String _businessDisplayName(TestAccount user) {
  if (user.businessName.trim().isNotEmpty) {
    return user.businessName.trim();
  }
  if (user.fullName.trim().isNotEmpty) {
    return user.fullName.trim();
  }
  return 'Your business';
}

String _businessLocationLabel(TestAccount user) {
  final city = user.city.trim();
  final country = user.country.trim();

  if (city.isNotEmpty && country.isNotEmpty) {
    return '$city, $country';
  }
  if (city.isNotEmpty) {
    return city;
  }
  if (country.isNotEmpty) {
    return country;
  }
  return 'your area';
}

String _businessLocationWords(TestAccount user) {
  final street = user.streetAddress.trim();
  final location = _businessLocationLabel(user);

  if (street.isNotEmpty) {
    return '$street, $location';
  }
  return location;
}

Future<void> _openBusinessMap(TestAccount user) async {
  final query = Uri.encodeComponent(
    '${_businessDisplayName(user)}, ${_businessLocationWords(user)}',
  );
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$query',
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
