import 'business_review.dart';
import 'subscription_payment_record.dart';

class TestAccount {
  const TestAccount({
    required this.fullName,
    required this.email,
    required this.password,
    required this.businessName,
    required this.industry,
    required this.categoryTitle,
    required this.categorySubtitle,
    required this.city,
    required this.country,
    required this.timeZone,
    this.streetAddress = '',
    this.phoneNumber = '',
    this.websiteUrl = '',
    this.businessPhotoPath = '',
    this.businessPhotoGalleryPaths,
    this.draftPhotoGalleryPaths,
    this.businessReviews = const <BusinessReview>[],
    this.subscriptionPlanId = 'growth',
    this.subscriptionBillingCycle = 'monthly',
    this.subscriptionPaymentMethodId = 'visa',
    this.subscriptionAutoRenew = true,
    this.subscriptionRenewalDateIso = '',
    this.subscriptionPaymentHistory = const <SubscriptionPaymentRecord>[],
    this.googleBusinessProfileConnected = true,
    this.whatsAppConnected = true,
    this.backendUserId = '',
    this.backendBusinessId = '',
    this.backendAuthenticated = false,
    this.backendAvailableBusinesses = const <Map<String, dynamic>>[],
  });

  final String fullName;
  final String email;
  final String password;
  final String businessName;
  final String industry;
  final String categoryTitle;
  final String categorySubtitle;
  final String city;
  final String country;
  final String timeZone;
  final String streetAddress;
  final String phoneNumber;
  final String websiteUrl;
  final String businessPhotoPath;
  final List<String>? businessPhotoGalleryPaths;
  final List<String>? draftPhotoGalleryPaths;
  final List<BusinessReview> businessReviews;
  final String subscriptionPlanId;
  final String subscriptionBillingCycle;
  final String subscriptionPaymentMethodId;
  final bool subscriptionAutoRenew;
  final String subscriptionRenewalDateIso;
  final List<SubscriptionPaymentRecord> subscriptionPaymentHistory;
  final bool googleBusinessProfileConnected;
  final bool whatsAppConnected;
  final String backendUserId;
  final String backendBusinessId;
  final bool backendAuthenticated;
  final List<Map<String, dynamic>> backendAvailableBusinesses;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'fullName': fullName,
      'email': email,
      'password': password,
      'businessName': businessName,
      'industry': industry,
      'categoryTitle': categoryTitle,
      'categorySubtitle': categorySubtitle,
      'city': city,
      'country': country,
      'timeZone': timeZone,
      'streetAddress': streetAddress,
      'phoneNumber': phoneNumber,
      'websiteUrl': websiteUrl,
      'businessPhotoPath': businessPhotoPath,
      'businessPhotoGalleryPaths':
          businessPhotoGalleryPaths ?? const <String>[],
      'draftPhotoGalleryPaths': draftPhotoGalleryPaths ?? const <String>[],
      'businessReviews': businessReviews
          .map((review) => review.toMap())
          .toList(),
      'subscriptionPlanId': subscriptionPlanId,
      'subscriptionBillingCycle': subscriptionBillingCycle,
      'subscriptionPaymentMethodId': subscriptionPaymentMethodId,
      'subscriptionAutoRenew': subscriptionAutoRenew,
      'subscriptionRenewalDateIso': subscriptionRenewalDateIso,
      'subscriptionPaymentHistory': subscriptionPaymentHistory
          .map((record) => record.toMap())
          .toList(),
      'googleBusinessProfileConnected': googleBusinessProfileConnected,
      'whatsAppConnected': whatsAppConnected,
      'backendUserId': backendUserId,
      'backendBusinessId': backendBusinessId,
      'backendAuthenticated': backendAuthenticated,
      'backendAvailableBusinesses': backendAvailableBusinesses,
    };
  }

  factory TestAccount.fromMap(Map<String, dynamic> map) {
    final rawBusinessPhotoPath = (map['businessPhotoPath'] as String?)?.trim();
    final rawBusinessPhotoGalleryPaths =
        ((map['businessPhotoGalleryPaths'] as List<dynamic>?) ?? const [])
            .map((path) => path.toString().trim())
            .where((path) => path.isNotEmpty)
            .toList();
    final normalizedBusinessPhotoGalleryPaths = <String>[];
    final seenBusinessPhotoPaths = <String>{};
    for (final path in rawBusinessPhotoGalleryPaths) {
      if (seenBusinessPhotoPaths.add(path)) {
        normalizedBusinessPhotoGalleryPaths.add(path);
      }
    }

    final rawDraftPhotoGalleryPaths =
        ((map['draftPhotoGalleryPaths'] as List<dynamic>?) ?? const [])
            .map((path) => path.toString().trim())
            .where((path) => path.isNotEmpty)
            .toList();
    final normalizedDraftPhotoGalleryPaths = <String>[];
    final seenDraftPhotoPaths = <String>{};
    for (final path in rawDraftPhotoGalleryPaths) {
      if (seenDraftPhotoPaths.add(path)) {
        normalizedDraftPhotoGalleryPaths.add(path);
      }
    }

    if (rawBusinessPhotoPath != null &&
        rawBusinessPhotoPath.isNotEmpty &&
        seenBusinessPhotoPaths.add(rawBusinessPhotoPath)) {
      normalizedBusinessPhotoGalleryPaths.add(rawBusinessPhotoPath);
    }

    return TestAccount(
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
      businessName: map['businessName'] as String? ?? '',
      industry: map['industry'] as String? ?? '',
      categoryTitle: map['categoryTitle'] as String? ?? '',
      categorySubtitle: map['categorySubtitle'] as String? ?? '',
      city: map['city'] as String? ?? '',
      country: map['country'] as String? ?? '',
      timeZone: map['timeZone'] as String? ?? '',
      streetAddress: map['streetAddress'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      websiteUrl: map['websiteUrl'] as String? ?? '',
      businessPhotoPath: rawBusinessPhotoPath ?? '',
      businessPhotoGalleryPaths: normalizedBusinessPhotoGalleryPaths,
      draftPhotoGalleryPaths: normalizedDraftPhotoGalleryPaths,
      businessReviews: ((map['businessReviews'] as List<dynamic>?) ?? const [])
          .map(
            (review) => BusinessReview.fromMap(
              Map<String, dynamic>.from(review as Map),
            ),
          )
          .toList(),
      subscriptionPlanId: map['subscriptionPlanId'] as String? ?? 'growth',
      subscriptionBillingCycle:
          map['subscriptionBillingCycle'] as String? ?? 'monthly',
      subscriptionPaymentMethodId:
          map['subscriptionPaymentMethodId'] as String? ?? 'visa',
      subscriptionAutoRenew: map['subscriptionAutoRenew'] as bool? ?? true,
      subscriptionRenewalDateIso:
          map['subscriptionRenewalDateIso'] as String? ?? '',
      subscriptionPaymentHistory:
          ((map['subscriptionPaymentHistory'] as List<dynamic>?) ?? const [])
              .map(
                (record) => SubscriptionPaymentRecord.fromMap(
                  Map<String, dynamic>.from(record as Map),
                ),
              )
              .toList(),
      googleBusinessProfileConnected:
          map['googleBusinessProfileConnected'] as bool? ?? true,
      whatsAppConnected: map['whatsAppConnected'] as bool? ?? true,
      backendUserId: map['backendUserId'] as String? ?? '',
      backendBusinessId: map['backendBusinessId'] as String? ?? '',
      backendAuthenticated: map['backendAuthenticated'] as bool? ?? false,
      backendAvailableBusinesses:
          ((map['backendAvailableBusinesses'] as List<dynamic>?) ?? const [])
              .whereType<Map>()
              .map((business) => Map<String, dynamic>.from(business))
              .toList(),
    );
  }

  TestAccount copyWith({
    String? fullName,
    String? email,
    String? password,
    String? businessName,
    String? industry,
    String? categoryTitle,
    String? categorySubtitle,
    String? city,
    String? country,
    String? timeZone,
    String? streetAddress,
    String? phoneNumber,
    String? websiteUrl,
    String? businessPhotoPath,
    List<String>? businessPhotoGalleryPaths,
    List<String>? draftPhotoGalleryPaths,
    List<BusinessReview>? businessReviews,
    String? subscriptionPlanId,
    String? subscriptionBillingCycle,
    String? subscriptionPaymentMethodId,
    bool? subscriptionAutoRenew,
    String? subscriptionRenewalDateIso,
    List<SubscriptionPaymentRecord>? subscriptionPaymentHistory,
    bool? googleBusinessProfileConnected,
    bool? whatsAppConnected,
    String? backendUserId,
    String? backendBusinessId,
    bool? backendAuthenticated,
    List<Map<String, dynamic>>? backendAvailableBusinesses,
  }) {
    return TestAccount(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      businessName: businessName ?? this.businessName,
      industry: industry ?? this.industry,
      categoryTitle: categoryTitle ?? this.categoryTitle,
      categorySubtitle: categorySubtitle ?? this.categorySubtitle,
      city: city ?? this.city,
      country: country ?? this.country,
      timeZone: timeZone ?? this.timeZone,
      streetAddress: streetAddress ?? this.streetAddress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      businessPhotoPath: businessPhotoPath ?? this.businessPhotoPath,
      businessPhotoGalleryPaths: businessPhotoGalleryPaths != null
          ? List<String>.from(businessPhotoGalleryPaths)
          : this.businessPhotoGalleryPaths,
      draftPhotoGalleryPaths: draftPhotoGalleryPaths != null
          ? List<String>.from(draftPhotoGalleryPaths)
          : this.draftPhotoGalleryPaths,
      businessReviews: businessReviews ?? this.businessReviews,
      subscriptionPlanId: subscriptionPlanId ?? this.subscriptionPlanId,
      subscriptionBillingCycle:
          subscriptionBillingCycle ?? this.subscriptionBillingCycle,
      subscriptionPaymentMethodId:
          subscriptionPaymentMethodId ?? this.subscriptionPaymentMethodId,
      subscriptionAutoRenew:
          subscriptionAutoRenew ?? this.subscriptionAutoRenew,
      subscriptionRenewalDateIso:
          subscriptionRenewalDateIso ?? this.subscriptionRenewalDateIso,
      subscriptionPaymentHistory:
          subscriptionPaymentHistory ?? this.subscriptionPaymentHistory,
      googleBusinessProfileConnected:
          googleBusinessProfileConnected ?? this.googleBusinessProfileConnected,
      whatsAppConnected: whatsAppConnected ?? this.whatsAppConnected,
      backendUserId: backendUserId ?? this.backendUserId,
      backendBusinessId: backendBusinessId ?? this.backendBusinessId,
      backendAuthenticated: backendAuthenticated ?? this.backendAuthenticated,
      backendAvailableBusinesses:
          backendAvailableBusinesses ?? this.backendAvailableBusinesses,
    );
  }
}
