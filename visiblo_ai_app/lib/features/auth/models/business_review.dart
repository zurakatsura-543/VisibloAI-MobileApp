class BusinessReview {
  const BusinessReview({
    required this.id,
    required this.reviewerName,
    required this.reviewerInitial,
    required this.rating,
    required this.reviewDateLabel,
    required this.comment,
    required this.avatarTone,
    required this.suggestedReply,
    this.ownerReply = '',
    this.ownerReplyUpdatedLabel = '',
    this.showSuggestedReplyCard = false,
  });

  final String id;
  final String reviewerName;
  final String reviewerInitial;
  final int rating;
  final String reviewDateLabel;
  final String comment;
  final int avatarTone;
  final String suggestedReply;
  final String ownerReply;
  final String ownerReplyUpdatedLabel;
  final bool showSuggestedReplyCard;

  bool get hasOwnerReply => ownerReply.trim().isNotEmpty;
  bool get isPositive => rating >= 4;
  bool get isNegative => rating <= 2;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'reviewerName': reviewerName,
      'reviewerInitial': reviewerInitial,
      'rating': rating,
      'reviewDateLabel': reviewDateLabel,
      'comment': comment,
      'avatarTone': avatarTone,
      'suggestedReply': suggestedReply,
      'ownerReply': ownerReply,
      'ownerReplyUpdatedLabel': ownerReplyUpdatedLabel,
      'showSuggestedReplyCard': showSuggestedReplyCard,
    };
  }

  factory BusinessReview.fromMap(Map<String, dynamic> map) {
    return BusinessReview(
      id: map['id'] as String? ?? '',
      reviewerName: map['reviewerName'] as String? ?? '',
      reviewerInitial: map['reviewerInitial'] as String? ?? '',
      rating: map['rating'] as int? ?? 5,
      reviewDateLabel: map['reviewDateLabel'] as String? ?? '',
      comment: map['comment'] as String? ?? '',
      avatarTone: map['avatarTone'] as int? ?? 0,
      suggestedReply: map['suggestedReply'] as String? ?? '',
      ownerReply: map['ownerReply'] as String? ?? '',
      ownerReplyUpdatedLabel: map['ownerReplyUpdatedLabel'] as String? ?? '',
      showSuggestedReplyCard: map['showSuggestedReplyCard'] as bool? ?? false,
    );
  }

  BusinessReview copyWith({
    String? id,
    String? reviewerName,
    String? reviewerInitial,
    int? rating,
    String? reviewDateLabel,
    String? comment,
    int? avatarTone,
    String? suggestedReply,
    String? ownerReply,
    String? ownerReplyUpdatedLabel,
    bool? showSuggestedReplyCard,
  }) {
    return BusinessReview(
      id: id ?? this.id,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerInitial: reviewerInitial ?? this.reviewerInitial,
      rating: rating ?? this.rating,
      reviewDateLabel: reviewDateLabel ?? this.reviewDateLabel,
      comment: comment ?? this.comment,
      avatarTone: avatarTone ?? this.avatarTone,
      suggestedReply: suggestedReply ?? this.suggestedReply,
      ownerReply: ownerReply ?? this.ownerReply,
      ownerReplyUpdatedLabel:
          ownerReplyUpdatedLabel ?? this.ownerReplyUpdatedLabel,
      showSuggestedReplyCard:
          showSuggestedReplyCard ?? this.showSuggestedReplyCard,
    );
  }
}
