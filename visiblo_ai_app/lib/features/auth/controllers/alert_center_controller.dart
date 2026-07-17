import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/local_auth_service.dart';
import '../models/alert_center_models.dart';
import '../models/test_account.dart';
import '../services/auth_api_service.dart';

class AlertCenterController extends GetxController {
  AlertCenterController({
    AuthApiService? authApiService,
    LocalAuthService? localAuthService,
  }) : _authApiService = authApiService ?? Get.find<AuthApiService>(),
       _localAuthService = localAuthService ?? Get.find<LocalAuthService>();

  final AuthApiService _authApiService;
  final LocalAuthService _localAuthService;

  final isLoading = true.obs;
  final isRefreshing = false.obs;
  final isGenerating = false.obs;
  final openingAlertId = RxnString();
  final markingReadAlertId = RxnString();
  final resolvingAlertId = RxnString();
  final errorMessage = RxnString();
  final infoMessage = RxnString();
  final activeFilter = AlertSignalFilter.all.obs;

  final alerts = <BusinessAlert>[].obs;
  final stats = Rxn<AlertStats>();
  final statsByType = Rxn<AlertStatsByType>();

  @override
  void onInit() {
    super.onInit();
    unawaited(loadAlerts());
  }

  TestAccount? get currentUser => _localAuthService.currentUser.value;

  String get businessName {
    final user = currentUser;
    if (user == null) {
      return 'Your business';
    }

    final trimmedBusinessName = user.businessName.trim();
    if (trimmedBusinessName.isNotEmpty) {
      return trimmedBusinessName;
    }

    final categoryTitle = user.categoryTitle.trim();
    if (categoryTitle.isNotEmpty) {
      return categoryTitle;
    }

    return 'Your business';
  }

  List<BusinessAlert> get sortedAlerts {
    final sortedValues = List<BusinessAlert>.from(alerts);
    sortedValues.sort(
      (left, right) =>
          right.effectivePriorityScore.compareTo(left.effectivePriorityScore),
    );
    return sortedValues;
  }

  List<BusinessAlert> get openAlerts {
    return sortedAlerts
        .where((alert) => !alert.resolved)
        .toList(growable: false);
  }

  List<BusinessAlert> get urgentAlerts {
    return openAlerts
        .where((alert) => alert.severity == AlertSeverity.high)
        .toList(growable: false);
  }

  BusinessAlert? get topAlert => openAlerts.isEmpty ? null : openAlerts.first;

  List<BusinessAlert> get filteredAlerts {
    final selectedType = activeFilter.value.type;
    if (selectedType == null) {
      return sortedAlerts;
    }

    return sortedAlerts
        .where((alert) => alert.type == selectedType)
        .toList(growable: false);
  }

  List<BusinessAlert> get recentActivity {
    return sortedAlerts.take(5).toList(growable: false);
  }

  AlertStats get effectiveStats {
    final currentStats = stats.value;
    if (currentStats != null) {
      return currentStats;
    }

    return AlertStats(
      highPriority: openAlerts
          .where((alert) => alert.severity == AlertSeverity.high)
          .length,
      unread: alerts.where((alert) => !alert.read).length,
      resolvedToday: alerts.where((alert) => alert.resolved).length,
      avgResponseStr: topAlert?.timeLabel.isNotEmpty == true
          ? topAlert!.timeLabel
          : 'clear',
    );
  }

  AlertStatsByType get effectiveStatsByType {
    final currentStats = statsByType.value;
    if (currentStats != null) {
      return currentStats;
    }

    return AlertStatsByType(
      all: alerts.length,
      seo: alerts.where((alert) => alert.type == AlertSignalType.seo).length,
      review: alerts
          .where((alert) => alert.type == AlertSignalType.review)
          .length,
      post: alerts.where((alert) => alert.type == AlertSignalType.post).length,
      competitor: alerts
          .where((alert) => alert.type == AlertSignalType.competitor)
          .length,
      compliance: alerts
          .where((alert) => alert.type == AlertSignalType.compliance)
          .length,
    );
  }

  int countForFilter(AlertSignalFilter filter) {
    return effectiveStatsByType.countFor(filter.type);
  }

  bool isBusyForAlert(String alertId) {
    final normalizedAlertId = alertId.trim();
    return openingAlertId.value == normalizedAlertId ||
        markingReadAlertId.value == normalizedAlertId ||
        resolvingAlertId.value == normalizedAlertId;
  }

  Future<void> loadAlerts({
    bool manualRefresh = false,
    bool preserveInfoMessage = false,
  }) async {
    if (manualRefresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }

    errorMessage.value = null;
    if (!preserveInfoMessage) {
      infoMessage.value = null;
    }

    try {
      final response = await _authApiService.fetchAlerts();
      alerts.assignAll(response.alerts);
      stats.value = response.stats;
      statsByType.value = response.statsByType;
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Failed to load alert intelligence right now.',
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshData() async {
    await loadAlerts(manualRefresh: true, preserveInfoMessage: true);
  }

  void selectFilter(AlertSignalFilter filter) {
    activeFilter.value = filter;
  }

  Future<void> generateAlertScan() async {
    if (isGenerating.value) {
      return;
    }

    isGenerating.value = true;
    errorMessage.value = null;

    try {
      final newAlertsCount = await _authApiService.generateAlerts();
      final normalizedCount = newAlertsCount < 0 ? 0 : newAlertsCount;
      infoMessage.value = normalizedCount == 0
          ? 'Alert scan finished. No new alerts were detected.'
          : normalizedCount == 1
          ? 'Alert scan finished. 1 new alert was detected.'
          : 'Alert scan finished. $normalizedCount new alerts were detected.';
      await loadAlerts(manualRefresh: true, preserveInfoMessage: true);
    } catch (error) {
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Failed to run the alert scan.',
      );
    } finally {
      isGenerating.value = false;
    }
  }

  Future<void> markAlertAsRead(String alertId) async {
    final normalizedAlertId = alertId.trim();
    if (normalizedAlertId.isEmpty) {
      return;
    }

    final currentAlert = _findAlert(normalizedAlertId);
    if (currentAlert == null || currentAlert.read) {
      return;
    }

    final previousAlerts = List<BusinessAlert>.from(alerts);
    final previousStats = stats.value;
    final previousStatsByType = statsByType.value;

    markingReadAlertId.value = normalizedAlertId;
    errorMessage.value = null;

    _replaceAlert(currentAlert.copyWith(read: true));
    if (stats.value != null) {
      stats.value = stats.value!.copyWith(
        unread: (stats.value!.unread - 1).clamp(0, 1 << 30),
      );
    }

    try {
      await _authApiService.markAlertAsRead(normalizedAlertId);
    } catch (error) {
      alerts.assignAll(previousAlerts);
      stats.value = previousStats;
      statsByType.value = previousStatsByType;
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Failed to mark this alert as read.',
      );
    } finally {
      markingReadAlertId.value = null;
    }
  }

  Future<void> resolveAlert(String alertId) async {
    final normalizedAlertId = alertId.trim();
    if (normalizedAlertId.isEmpty) {
      return;
    }

    final currentAlert = _findAlert(normalizedAlertId);
    if (currentAlert == null || currentAlert.resolved) {
      return;
    }

    final previousAlerts = List<BusinessAlert>.from(alerts);
    final previousStats = stats.value;
    final previousStatsByType = statsByType.value;

    resolvingAlertId.value = normalizedAlertId;
    errorMessage.value = null;

    _replaceAlert(currentAlert.copyWith(read: true, resolved: true));

    if (stats.value != null) {
      final unreadCount = currentAlert.read
          ? stats.value!.unread
          : (stats.value!.unread - 1).clamp(0, 1 << 30);
      final highPriorityCount = currentAlert.severity == AlertSeverity.high
          ? (stats.value!.highPriority - 1).clamp(0, 1 << 30)
          : stats.value!.highPriority;

      stats.value = stats.value!.copyWith(
        unread: unreadCount,
        highPriority: highPriorityCount,
        resolvedToday: stats.value!.resolvedToday + 1,
      );
    }

    try {
      await _authApiService.markAlertAsResolved(normalizedAlertId);
      infoMessage.value = 'Alert resolved successfully.';
    } catch (error) {
      alerts.assignAll(previousAlerts);
      stats.value = previousStats;
      statsByType.value = previousStatsByType;
      errorMessage.value = _humanizeError(
        error,
        fallback: 'Failed to resolve this alert.',
      );
    } finally {
      resolvingAlertId.value = null;
    }
  }

  Future<void> openAlertAction(BusinessAlert alert) async {
    if (alert.resolved) {
      return;
    }

    final normalizedAlertId = alert.id.trim();
    openingAlertId.value = normalizedAlertId.isEmpty ? null : normalizedAlertId;

    try {
      await markAlertAsRead(alert.id);

      final actionPath = (alert.actionPath ?? '').trim();
      if (actionPath.isEmpty) {
        infoMessage.value = 'This alert does not have a linked fix screen yet.';
        return;
      }

      final route = _routeForActionPath(actionPath);
      if (route == null) {
        infoMessage.value =
            'No matching screen was found for "$actionPath" in the app yet.';
        return;
      }

      if (Get.currentRoute == route) {
        infoMessage.value = 'You are already on the linked screen.';
        return;
      }

      await Get.toNamed<void>(route);
    } finally {
      openingAlertId.value = null;
    }
  }

  void clearError() {
    errorMessage.value = null;
  }

  void clearInfo() {
    infoMessage.value = null;
  }

  BusinessAlert? _findAlert(String alertId) {
    for (final alert in alerts) {
      if (alert.id == alertId) {
        return alert;
      }
    }
    return null;
  }

  void _replaceAlert(BusinessAlert updatedAlert) {
    final alertIndex = alerts.indexWhere(
      (alert) => alert.id == updatedAlert.id,
    );
    if (alertIndex == -1) {
      return;
    }

    final updatedAlerts = List<BusinessAlert>.from(alerts);
    updatedAlerts[alertIndex] = updatedAlert;
    alerts.assignAll(updatedAlerts);
  }

  String? _routeForActionPath(String actionPath) {
    final normalized = actionPath.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    final parsedPath = Uri.tryParse(normalized)?.path ?? normalized;

    if (parsedPath.contains('audit/reviews')) {
      return AppRoutes.auditReviews;
    }
    if (parsedPath.contains('audit/hours')) {
      return AppRoutes.auditHours;
    }
    if (parsedPath.contains('audit/category')) {
      return AppRoutes.auditCategory;
    }
    if (parsedPath.contains('review-poster')) {
      return AppRoutes.reviewPoster;
    }
    if (parsedPath.contains('citations')) {
      return AppRoutes.citations;
    }
    if (parsedPath.contains('content/photos') ||
        parsedPath.endsWith('/photos')) {
      return AppRoutes.gbpPhotos;
    }
    if (parsedPath.contains('content/offers') ||
        parsedPath.endsWith('/offers')) {
      return AppRoutes.gbpOffers;
    }
    if (parsedPath.contains('content/events') ||
        parsedPath.endsWith('/events')) {
      return AppRoutes.gbpEvents;
    }
    if (parsedPath.contains('content/posts') || parsedPath.endsWith('/posts')) {
      return AppRoutes.gbpPosts;
    }
    if (parsedPath.contains('gbp-manager') ||
        parsedPath.contains('locations') && parsedPath.contains('gbp')) {
      return AppRoutes.gbpManager;
    }
    if (parsedPath.contains('website')) {
      return AppRoutes.websiteManager;
    }
    if (parsedPath.contains('reports') || parsedPath.contains('insights')) {
      return AppRoutes.reports;
    }
    if (parsedPath.contains('keyword') ||
        parsedPath.contains('rank') ||
        parsedPath.contains('seo-tools') ||
        parsedPath.contains('heatmap') ||
        parsedPath.contains('competitor')) {
      return AppRoutes.keywordRanking;
    }
    if (parsedPath.contains('reviews')) {
      return AppRoutes.clientReviews;
    }
    if (parsedPath.contains('audit')) {
      return AppRoutes.audit;
    }

    return null;
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
