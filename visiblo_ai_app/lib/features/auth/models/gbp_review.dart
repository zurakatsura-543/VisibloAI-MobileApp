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
    return GbpReview(
      id: _readString(map['id']),
      reviewId: _readString(map['reviewId']),
      reviewerName: _readString(map['reviewerName']),
      starRating: (map['starRating'] as num?)?.toInt() ?? 0,
      commentText: _readString(map['commentText']),
      reviewCreatedAt: _readString(map['reviewCreatedAt']),
      reviewUpdatedAt: _readString(map['reviewUpdatedAt']),
      ownerReplyText: _readString(map['ownerReplyText']),
      ownerReplyUpdatedAt: _readString(map['ownerReplyUpdatedAt']),
      showSuggestedReplyCard: map['showSuggestedReplyCard'] ?? false,
    );
  }

  final bool showSuggestedReplyCard;

  bool get hasOwnerReply => ownerReplyText.isNotEmpty;
  bool get isPositive => starRating >= 4;
  bool get isNegative => starRating <= 2;
  String get comment => commentText.isNotEmpty ? commentText : 'No comment provided.';
  String get ownerReply => ownerReplyText;
  String get ownerReplyUpdatedLabel => ownerReplyUpdatedAt;
  String get suggestedReply {
    final text = commentText.trim().toLowerCase();
    final name = reviewerName.split(' ').first;
    final safeName = name.isNotEmpty ? name : 'Customer';
    
    if (text.isEmpty || text == 'no comment provided.' || text == 'no comment provided') {
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
  
  String get reviewerInitial => reviewerName.isNotEmpty ? reviewerName.substring(0, 1).toUpperCase() : '?';
  String get reviewDateLabel {
    if (reviewCreatedAt.isEmpty) return '';
    final date = DateTime.tryParse(reviewCreatedAt);
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  int get avatarTone {
    return reviewerName.length % 5;
  }

  static String _readString(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}
