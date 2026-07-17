import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/services/local_auth_service.dart';
import '../models/review_poster_models.dart';
import '../models/test_account.dart';
import '../models/website_manager_models.dart';
import '../services/auth_api_service.dart';

class ReviewPosterController extends GetxController {
  ReviewPosterController({
    AuthApiService? authApiService,
    LocalAuthService? localAuthService,
  }) : _authApiService = authApiService ?? Get.find<AuthApiService>(),
       _localAuthService = localAuthService ?? Get.find<LocalAuthService>();

  static const defaultTitle = 'Rate us on Google';
  static const defaultDescription = 'We value your feedback!';
  static const brandColors = <Color>[
    Color(0xFF179CA3),
    Color(0xFFBFDBFE),
    Color(0xFFBBF7D0),
    Color(0xFFE9D5FF),
    Color(0xFFFBCFE8),
    Color(0xFFFEF08A),
    Color(0xFFFED7AA),
    Color(0xFFF1F5F9),
    Color(0xFF1E293B),
  ];

  final AuthApiService _authApiService;
  final LocalAuthService _localAuthService;

  final isLoading = true.obs;
  final isResolvingReviewUrl = false.obs;
  final errorMessage = RxnString();
  final infoMessage = RxnString();

  final locations = <BusinessLocationSummary>[].obs;
  final selectedLocationId = ''.obs;
  final selectedPaperSize = ReviewPosterPaperSize.a4.obs;
  final selectedTemplate = ReviewPosterTemplate.split.obs;
  final selectedBrandColorValue = Color(0xFF179CA3).toARGB32().obs;
  final showFooter = true.obs;
  final titleText = defaultTitle.obs;
  final descriptionText = defaultDescription.obs;
  final reviewUrlText = ''.obs;
  final resolvedReviewUrl = RxnString();

  final reviewUrlController = TextEditingController();
  final titleController = TextEditingController(text: defaultTitle);
  final descriptionController = TextEditingController(text: defaultDescription);

  bool _manualReviewUrlOverride = false;
  bool _isSyncingReviewUrlController = false;
  String _lastAutoReviewUrl = '';
  int _resolveAttempt = 0;

  @override
  void onInit() {
    super.onInit();
    reviewUrlController.addListener(_handleReviewUrlEdited);
    titleController.addListener(_handleTitleEdited);
    descriptionController.addListener(_handleDescriptionEdited);
    titleText.value = titleValue;
    descriptionText.value = descriptionValue;
    unawaited(loadInitialData());
  }

  @override
  void onClose() {
    reviewUrlController
      ..removeListener(_handleReviewUrlEdited)
      ..dispose();
    titleController
      ..removeListener(_handleTitleEdited)
      ..dispose();
    descriptionController
      ..removeListener(_handleDescriptionEdited)
      ..dispose();
    super.onClose();
  }

  TestAccount? get currentUser => _localAuthService.currentUser.value;

  BusinessLocationSummary? get selectedLocation {
    final locationId = selectedLocationId.value.trim();
    if (locationId.isEmpty) {
      return null;
    }

    for (final location in locations) {
      if (location.id == locationId) {
        return location;
      }
    }
    return null;
  }

  Color get brandColor => Color(selectedBrandColorValue.value);

  String get titleValue {
    final trimmed = titleController.text.trim();
    return trimmed.isEmpty ? defaultTitle : trimmed;
  }

  String get descriptionValue {
    final trimmed = descriptionController.text.trim();
    return trimmed.isEmpty ? defaultDescription : trimmed;
  }

  String get businessName {
    final locationName = selectedLocation?.name.trim() ?? '';
    if (locationName.isNotEmpty) {
      return locationName;
    }

    final user = currentUser;
    if (user == null) {
      return 'Your Business';
    }

    final businessName = user.businessName.trim();
    if (businessName.isNotEmpty) {
      return businessName;
    }

    final categoryTitle = user.categoryTitle.trim();
    if (categoryTitle.isNotEmpty) {
      return categoryTitle;
    }

    return 'Your Business';
  }

  String get reviewUrl {
    final manualUrl = reviewUrlText.value.trim();
    if (manualUrl.isNotEmpty) {
      return normalizeWriteReviewUrl(manualUrl) ?? manualUrl;
    }
    return _autoReviewUrl;
  }

  bool get hasDirectReviewUrl {
    final manualUrl = reviewUrlText.value.trim();
    if (manualUrl.isNotEmpty) {
      return normalizeWriteReviewUrl(manualUrl) != null;
    }
    return (resolvedReviewUrl.value ?? '').trim().isNotEmpty;
  }

  String get previewLinkLabel {
    final uri = Uri.tryParse(reviewUrl);
    if (uri == null) {
      return reviewUrl;
    }

    final host = uri.host.replaceFirst('www.', '');
    final path = uri.path.isEmpty ? '/' : uri.path;
    final query = uri.query;
    final compact = query.isEmpty ? '$host$path' : '$host$path?$query';
    if (compact.length <= 44) {
      return compact;
    }
    return '${compact.substring(0, 41)}...';
  }

  String get shortDisplayUrl {
    final location = selectedLocation;
    if (location == null || location.name.trim().isEmpty) {
      return 'google.com/review';
    }

    final slug = location.name
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .take(3)
        .join('-')
        .replaceAll(RegExp(r'[^a-z0-9-]'), '');
    return slug.isEmpty ? 'google.com/review' : 'g.page/$slug/review';
  }

  String get whatsAppShareMessage {
    return [
      titleValue,
      descriptionValue,
      'Leave a review for $businessName:',
      reviewUrl,
    ].join('\n\n');
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    errorMessage.value = null;
    infoMessage.value = null;

    try {
      final loadedLocations = await _authApiService.fetchBusinessLocations();
      locations.assignAll(_sortedLocations(loadedLocations));
      _syncSelectedLocation();
      await resolveReviewUrlForSelectedLocation();
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Unable to load business locations right now.',
      );
      _syncReviewUrlController();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    await loadInitialData();
  }

  Future<void> selectLocation(String? locationId) async {
    final normalized = (locationId ?? '').trim();
    if (normalized == selectedLocationId.value) {
      return;
    }

    selectedLocationId.value = normalized;
    resolvedReviewUrl.value = null;
    errorMessage.value = null;
    await resolveReviewUrlForSelectedLocation();
  }

  void setPaperSize(ReviewPosterPaperSize paperSize) {
    selectedPaperSize.value = paperSize;
  }

  void setTemplate(ReviewPosterTemplate template) {
    selectedTemplate.value = template;
  }

  void setBrandColor(Color color) {
    selectedBrandColorValue.value = color.toARGB32();
  }

  void setShowFooter(bool value) {
    showFooter.value = value;
  }

  void clearError() {
    errorMessage.value = null;
  }

  void clearInfo() {
    infoMessage.value = null;
  }

  Future<void> resolveReviewUrlForSelectedLocation() async {
    final selectedLocation = this.selectedLocation;
    final resolveToken = ++_resolveAttempt;

    if (selectedLocation == null) {
      resolvedReviewUrl.value = null;
      _syncReviewUrlController();
      return;
    }

    final existingReviewUrl = extractWriteReviewUrlFromLocation(
      selectedLocation,
    );
    if (existingReviewUrl != null) {
      resolvedReviewUrl.value = existingReviewUrl;
      _syncReviewUrlController();
      return;
    }

    final existingPlaceId = extractPlaceIdFromLocation(selectedLocation);
    if (existingPlaceId != null) {
      resolvedReviewUrl.value = buildGoogleWriteReviewUrl(existingPlaceId);
      _syncReviewUrlController();
      return;
    }

    isResolvingReviewUrl.value = true;
    resolvedReviewUrl.value = null;
    _syncReviewUrlController();

    try {
      final lookupIds = <String>{
        if (selectedLocation.id.trim().isNotEmpty) selectedLocation.id.trim(),
        if (selectedLocation.gmbLocationId.trim().isNotEmpty)
          selectedLocation.gmbLocationId.trim(),
      };

      for (final lookupId in lookupIds) {
        GoogleReviewLinkLookup? lookup;
        try {
          lookup = await _authApiService.fetchGoogleReviewLinkLookup(lookupId);
        } catch (_) {
          lookup = null;
        }

        if (resolveToken != _resolveAttempt) {
          return;
        }

        final normalizedReviewUrl = normalizeWriteReviewUrl(
          lookup?.writeReviewUrl,
        );
        if (normalizedReviewUrl != null) {
          resolvedReviewUrl.value = normalizedReviewUrl;
          _syncReviewUrlController();
          return;
        }

        final normalizedPlaceId = normalizePlaceId(lookup?.placeId);
        if (normalizedPlaceId != null) {
          resolvedReviewUrl.value = buildGoogleWriteReviewUrl(
            normalizedPlaceId,
          );
          _syncReviewUrlController();
          return;
        }
      }

      resolvedReviewUrl.value = null;
      _syncReviewUrlController();
    } finally {
      if (resolveToken == _resolveAttempt) {
        isResolvingReviewUrl.value = false;
      }
    }
  }

  String _buildFallbackSearchUrl(TestAccount? user) {
    if (user == null) {
      return 'https://www.google.com/maps';
    }

    final queryParts = <String>[
      businessName,
      if (user.streetAddress.trim().isNotEmpty) user.streetAddress.trim(),
      if (user.city.trim().isNotEmpty) user.city.trim(),
      if (user.country.trim().isNotEmpty) user.country.trim(),
    ];
    return buildGoogleMapsSearchUrl(queryParts.join(', '));
  }

  String get _autoReviewUrl {
    final resolved = (resolvedReviewUrl.value ?? '').trim();
    if (resolved.isNotEmpty) {
      return resolved;
    }

    final location = selectedLocation;
    if (location != null && location.name.trim().isNotEmpty) {
      return buildGoogleMapsSearchUrl(location.name);
    }

    return _buildFallbackSearchUrl(currentUser);
  }

  void _handleReviewUrlEdited() {
    if (_isSyncingReviewUrlController) {
      return;
    }

    final trimmed = reviewUrlController.text.trim();
    if (trimmed.isEmpty) {
      _manualReviewUrlOverride = false;
      _syncReviewUrlController();
      return;
    }

    _manualReviewUrlOverride = trimmed != _lastAutoReviewUrl;
    reviewUrlText.value = trimmed;
  }

  void _handleTitleEdited() {
    titleText.value = titleValue;
  }

  void _handleDescriptionEdited() {
    descriptionText.value = descriptionValue;
  }

  void _syncSelectedLocation() {
    if (locations.isEmpty) {
      selectedLocationId.value = '';
      return;
    }

    final currentLocationId = selectedLocationId.value.trim();
    final hasCurrentSelection = locations.any(
      (location) => location.id == currentLocationId,
    );
    if (hasCurrentSelection) {
      return;
    }

    selectedLocationId.value = locations.first.id;
  }

  void _syncReviewUrlController() {
    if (_manualReviewUrlOverride) {
      reviewUrlText.value = reviewUrlController.text.trim();
      return;
    }

    final autoUrl = _autoReviewUrl;
    _lastAutoReviewUrl = autoUrl;
    reviewUrlText.value = autoUrl;
    _isSyncingReviewUrlController = true;
    reviewUrlController.value = TextEditingValue(
      text: autoUrl,
      selection: TextSelection.collapsed(offset: autoUrl.length),
    );
    _isSyncingReviewUrlController = false;
  }

  List<BusinessLocationSummary> _sortedLocations(
    List<BusinessLocationSummary> values,
  ) {
    final sortedValues = List<BusinessLocationSummary>.from(values);
    sortedValues.sort(
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );
    return sortedValues;
  }

  String _humanizeError(Object error, {required String fallback}) {
    final message = error.toString().trim();
    if (message.isEmpty) {
      return fallback;
    }
    if (message.startsWith('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }
    return message;
  }
}
