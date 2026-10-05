class GbpReview {
  const GbpReview({
    required this.id,
    required this.reviewId,
    required this.reviewerName,
    required this.starRating,
    required this.commentText,
    required this.reviewCreatedAt,
    required this.reviewUpdatedAt,
    required this.ownerReplyText,
    required this.ownerReplyUpdatedAt,
    this.showSuggestedReplyCard = false,
  });

  final String id;
  final String reviewId;
  final String reviewerName;
  final int starRating;
  final String commentText;
  final String reviewCreatedAt;
  final String reviewUpdatedAt;
  final String ownerReplyText;
  final String ownerReplyUpdatedAt;

  factory GbpReview.fromMap(Map<String, dynamic> map) {
    final reviewer = _asMap(map['reviewer']);
    final reviewReply = _asMap(map['reviewReply'] ?? map['reply']);
    return GbpReview(
      id: _readString(map['id'] ?? map['name'] ?? map['reviewId']),
      reviewId: _readString(map['reviewId'] ?? map['id'] ?? map['name']),
      reviewerName: _readString(
        map['reviewerName'] ?? reviewer['displayName'] ?? reviewer['name'],
      ),
      starRating: _readRating(map['starRating'] ?? map['rating']),
      commentText: _readString(map['commentText'] ?? map['comment']),
      reviewCreatedAt: _readString(
        map['reviewCreatedAt'] ?? map['createTime'] ?? map['createdAt'],
      ),
      reviewUpdatedAt: _readString(
        map['reviewUpdatedAt'] ?? map['updateTime'] ?? map['updatedAt'],
      ),
      ownerReplyText: _readString(
        map['ownerReplyText'] ??
            reviewReply['comment'] ??
            reviewReply['commentText'] ??
            map['replyText'],
      ),
      ownerReplyUpdatedAt: _readString(
        map['ownerReplyUpdatedAt'] ??
            reviewReply['updateTime'] ??
            reviewReply['updatedAt'],
      ),
      showSuggestedReplyCard: map['showSuggestedReplyCard'] == true,
    );
  }

  final bool showSuggestedReplyCard;

  bool get hasOwnerReply => ownerReplyText.isNotEmpty;
  bool get isPositive => starRating >= 4;
  bool get isNegative => starRating <= 2;
  String get comment =>
      commentText.isNotEmpty ? commentText : 'No comment provided.';
  String get ownerReply => ownerReplyText;
  String get ownerReplyUpdatedLabel => ownerReplyUpdatedAt;
  String get suggestedReply {
    final text = commentText.trim().toLowerCase();
    final name = reviewerName.split(' ').first;
    final safeName = name.isNotEmpty ? name : 'Customer';

    if (text.isEmpty ||
        text == 'no comment provided.' ||
        text == 'no comment provided') {
      if (starRating >= 4) {
        return 'Hi $safeName, thank you for your feedback! We love to assist and help you, and truly appreciate your support.\n\nRegards,\nOur team';
      }
      if (starRating == 3) {
        return 'Hi $safeName, thank you for your feedback. We noticed your rating but there is no written comment. Could you please share how we can improve to make your next experience a 5-star one?\n\nRegards,\nOur team';
      }
      return 'Hi $safeName, we noticed your rating but there is no written feedback. Could you please share what went wrong or what we can improve? If this rating was selected by mistake, we would appreciate it if you could update it.\n\nRegards,\nOur team';
    }

    if (starRating >= 4) {
      return 'Hi $safeName, thank you for your kind review. We are glad you had a good experience with us and truly appreciate your support.\n\nRegards,\nOur team';
    }

    return 'Hi $safeName, thank you for bringing this to our attention. We are sorry your experience did not meet expectations. Please contact us directly so we can understand what happened and work on the right next step.\n\nRegards,\nOur team';
  }

  String get reviewerInitial => reviewerName.isNotEmpty
      ? reviewerName.substring(0, 1).toUpperCase()
      : '?';
  String get reviewDateLabel {
    if (reviewCreatedAt.isEmpty) return '';
    final date = DateTime.tryParse(reviewCreatedAt);
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  int get avatarTone {
    return reviewerName.length % 5;
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  static int _readRating(Object? value) {
    if (value is num) return value.toInt();
    final text = _readString(value).toUpperCase();
    return switch (text) {
      'ONE' || 'ONE_STAR' => 1,
      'TWO' || 'TWO_STAR' => 2,
      'THREE' || 'THREE_STAR' => 3,
      'FOUR' || 'FOUR_STAR' => 4,
      'FIVE' || 'FIVE_STAR' => 5,
      _ => int.tryParse(text) ?? 0,
    };
  }

  static String _readString(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}
