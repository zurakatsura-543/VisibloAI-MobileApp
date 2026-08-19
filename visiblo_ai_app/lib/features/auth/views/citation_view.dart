import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../controllers/citation_manager_controller.dart';
import '../controllers/payment_controller.dart';
import '../models/citation_manager_models.dart';
import '../models/website_manager_models.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_navigation_shell.dart';
import '../widgets/billing_access_banner.dart';
import '../widgets/visiblo_brand_wordmark.dart';

const Map<String, String> _dayLabels = <String, String>{
  'MONDAY': 'Monday',
  'TUESDAY': 'Tuesday',
  'WEDNESDAY': 'Wednesday',
  'THURSDAY': 'Thursday',
  'FRIDAY': 'Friday',
  'SATURDAY': 'Saturday',
  'SUNDAY': 'Sunday',
};

const List<String> _allDays = <String>[
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY',
];

const Set<String> _commonDirectoryDomains = <String>{
  'google.com',
  'bing.com',
  'apple.com',
  'justdial.com',
  'sulekha.com',
  'indiamart.com',
  'tradeindia.com',
  'cylex.in',
  'yellowpages.com',
  'yelp.com',
};

const int _discoverPageSize = 2;

class _DaySchedule {
  const _DaySchedule({
    required this.closed,
    required this.open,
    required this.close,
  });

  final bool closed;
  final String open;
  final String close;

  _DaySchedule copyWith({bool? closed, String? open, String? close}) {
    return _DaySchedule(
      closed: closed ?? this.closed,
      open: open ?? this.open,
      close: close ?? this.close,
    );
  }
}

String _formatHourTime(int? hours, int? minutes) {
  final h = (hours ?? 0).toString().padLeft(2, '0');
  final m = (minutes ?? 0).toString().padLeft(2, '0');
  return '$h:$m';
}

Map<String, _DaySchedule> _buildSchedule(CitationRegularHours? hours) {
  final base = <String, _DaySchedule>{
    for (final day in _allDays)
      day: const _DaySchedule(closed: true, open: '09:00', close: '18:00'),
  };

  for (final period in hours?.periods ?? const <CitationRegularHourPeriod>[]) {
    final day = period.openDay.trim().toUpperCase();
    if (!base.containsKey(day)) {
      continue;
    }
    base[day] = _DaySchedule(
      closed: false,
      open: _formatHourTime(period.openTime?.hours, period.openTime?.minutes),
      close: _formatHourTime(
        period.closeTime?.hours,
        period.closeTime?.minutes,
      ),
    );
  }

  return base;
}

Map<String, dynamic> _buildRegularHoursPayload(
  Map<String, _DaySchedule> schedule,
) {
  return <String, dynamic>{
    'periods': _allDays
        .where((day) => !(schedule[day]?.closed ?? true))
        .map((day) {
          final slot = schedule[day]!;
          final openParts = slot.open.split(':').map(int.parse).toList();
          final closeParts = slot.close.split(':').map(int.parse).toList();
          return <String, dynamic>{
            'openDay': day,
            'openTime': <String, dynamic>{
              'hours': openParts[0],
              'minutes': openParts[1],
            },
            'closeDay': day,
            'closeTime': <String, dynamic>{
              'hours': closeParts[0],
              'minutes': closeParts[1],
            },
          };
        })
        .toList(growable: false),
  };
}

String _normalizeWebsiteInput(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return 'https://$trimmed';
}

bool _isValidWebsite(String value) {
  if (value.trim().isEmpty) {
    return true;
  }
  try {
    final parsed = Uri.parse(_normalizeWebsiteInput(value));
    return (parsed.host).contains('.');
  } catch (_) {
    return false;
  }
}

bool _isValidIndianPhone(String value) {
  if (value.trim().isEmpty) {
    return true;
  }
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(digits);
  }
  if (digits.length == 12 && digits.startsWith('91')) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(digits.substring(2));
  }
  return false;
}

String _formatIndianPhoneInput(String value) {
  final hasPlus = value.trim().startsWith('+');
  var digits = value.replaceAll(RegExp(r'\D'), '');

  if (digits.startsWith('91') && digits.length > 12) {
    digits = digits.substring(0, 12);
  } else if (!digits.startsWith('91') && digits.length > 10) {
    digits = digits.substring(0, 10);
  }

  if (digits.startsWith('91') || hasPlus) {
    final endIndex = digits.length > 12 ? 12 : digits.length;
    final local = digits.startsWith('91')
        ? digits.substring(2, endIndex)
        : digits;
    if (local.isEmpty) {
      return '+91 ';
    }
    final first = local.length >= 5 ? local.substring(0, 5) : local;
    final second = local.length > 5 ? local.substring(5) : '';
    return ('+91 $first ${second.trim()}').trim();
  }

  if (digits.length <= 5) {
    return digits;
  }
  return '${digits.substring(0, 5)} ${digits.substring(5)}'.trim();
}

String _displayHour(String value) {
  final parts = value.split(':');
  if (parts.length != 2) {
    return value;
  }
  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts[1]) ?? 0;
  final period = hours >= 12 ? 'PM' : 'AM';
  final hour12 = hours % 12 == 0 ? 12 : hours % 12;
  final minuteLabel = minutes.toString().padLeft(2, '0');
  return '${hour12.toString().padLeft(2, '0')}:$minuteLabel $period';
}

String _hoursSummary(CitationRegularHours? hours) {
  final schedule = _buildSchedule(hours);
  final openDays = _allDays.where((day) => !(schedule[day]?.closed ?? true));
  if (openDays.isEmpty) {
    return 'Hours not added yet';
  }

  final monday = schedule['MONDAY'];
  final uniqueRanges = _allDays
      .where((day) => !(schedule[day]?.closed ?? true))
      .map((day) => '${schedule[day]!.open}-${schedule[day]!.close}')
      .toSet();

  if (uniqueRanges.length == 1 && monday != null && !monday.closed) {
    return 'Daily ${_displayHour(monday.open)} to ${_displayHour(monday.close)}';
  }

  final firstOpenDay = openDays.first;
  final slot = schedule[firstOpenDay]!;
  return '${_dayLabels[firstOpenDay]} ${_displayHour(slot.open)} to ${_displayHour(slot.close)}';
}

({String label, Color foreground, Color background}) _gmbSyncStyleFor(
  CitationGmbSyncStatus status,
) {
  switch (status) {
    case CitationGmbSyncStatus.synced:
      return (
        label: 'Synced to GBP',
        foreground: const Color(0xFF1B9E5A),
        background: const Color(0xFFE9F8EF),
      );
    case CitationGmbSyncStatus.manualConfirmation:
      return (
        label: 'Needs Google confirmation',
        foreground: const Color(0xFFB8700B),
        background: const Color(0xFFFFF5E6),
      );
    case CitationGmbSyncStatus.failed:
      return (
        label: 'GBP sync failed',
        foreground: const Color(0xFFD64545),
        background: const Color(0xFFFFECEC),
      );
    case CitationGmbSyncStatus.savedLocally:
      return (
        label: 'Saved in VisibloAI',
        foreground: const Color(0xFF2368D8),
        background: const Color(0xFFEAF2FF),
      );
  }
}

typedef _DiscoverGroupTheme = ({
  Color surface,
  Color border,
  Color accent,
  Color softAccent,
});

_DiscoverGroupTheme _discoverGroupThemeFor(String key) {
  switch (key) {
    case 'core':
      return (
        surface: Colors.white,
        border: const Color(0xFFC7DDF7),
        accent: const Color(0xFF0B4F93),
        softAccent: const Color(0xFFEAF4FF),
      );
    case 'social':
      return (
        surface: Colors.white,
        border: const Color(0xFFD6C4FF),
        accent: const Color(0xFF6A39C9),
        softAccent: const Color(0xFFF2ECFF),
      );
    case 'industry':
      return (
        surface: Colors.white,
        border: const Color(0xFFFFD59B),
        accent: const Color(0xFFD46D00),
        softAccent: const Color(0xFFFFF0DA),
      );
    default:
      return (
        surface: Colors.white,
        border: const Color(0xFFCDEBD9),
        accent: const Color(0xFF087A42),
        softAccent: const Color(0xFFEAF8EF),
      );
  }
}

class CitationView extends GetView<CitationManagerController> {
  const CitationView({super.key});

  PaymentController _paymentController() {
    if (Get.isRegistered<PaymentController>()) {
      return Get.find<PaymentController>();
    }
    return Get.put(PaymentController());
  }

  @override
  Widget build(BuildContext context) {
    final paymentController = _paymentController();
    return AuthNavigationShell(
      currentTab: AuthTab.home,
      backgroundColor: _CitationPalette.canvas,
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.05)),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const _LoadingState();
          }

          if (!controller.hasLocations) {
            return _EmptyLocationsState(onRefresh: controller.refreshData);
          }

          final selectedLocation = controller.selectedLocation;
          final dropdownValue =
              controller.locations.any(
                (location) =>
                    location.id == controller.selectedLocationId.value,
              )
              ? controller.selectedLocationId.value
              : null;
          final showLocationCard =
              controller.locations.length > 1 || selectedLocation == null;
          final napInfo = controller.effectiveNapInfo;
          final jobStats = controller.jobStats.value;
          final filteredCitations = controller.filteredCitations;
          final billingBanner = _buildBillingBanner(paymentController);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: controller.refreshData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                AuthViewSpacing.pageHorizontal,
                12,
                AuthViewSpacing.pageHorizontal,
                24,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeaderCard(
                          onRefresh: controller.refreshData,
                          isRefreshing: controller.isRefreshing.value,
                        ),
                        const SizedBox(height: 12),
                        if (controller.errorMessage.value != null) ...[
                          _FeedbackBanner(
                            message: controller.errorMessage.value!,
                            isError: true,
                            onDismiss: controller.clearError,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (billingBanner != null) ...[
                          billingBanner,
                          const SizedBox(height: 12),
                        ],
                        if (controller.infoMessage.value != null) ...[
                          _FeedbackBanner(
                            message: controller.infoMessage.value!,
                            onDismiss: controller.clearInfo,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _MetricSection(
                          controller: controller,
                          onFixIssues:
                              controller.inconsistentActiveCitations.isEmpty
                              ? null
                              : () => _showNapIssues(context),
                          onDiscover: controller.discoverDirectories,
                          onAddCitation: () =>
                              _showAddCitationSheet(context, paymentController),
                        ),
                        const SizedBox(height: 12),
                        _QuickActionsCard(
                          isScanning: controller.isScanning.value,
                          trackedCount: controller.stats.value?.all ?? 0,
                          onScan: controller.scanNap,
                          onAddCitation: () =>
                              _showAddCitationSheet(context, paymentController),
                        ),
                        const SizedBox(height: 12),
                        _NapCard(
                          napInfo: napInfo,
                          onEdit: () => _showNapEditor(context, napInfo),
                          onOpenExternal: _openExternal,
                        ),
                        if (showLocationCard) ...[
                          const SizedBox(height: 12),
                          _LocationCard(
                            selectedLocation: selectedLocation,
                            locations: controller.locations,
                            dropdownValue: dropdownValue,
                            onLocationChanged: controller.selectLocation,
                            isRefreshing: controller.isRefreshing.value,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _DiscoverSection(
                          controller: controller,
                          onOpenExternal: _openExternal,
                          onTrackSuggestion: (suggestion) =>
                              _handleTrackSuggestion(
                                context,
                                paymentController,
                                suggestion,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _FilterTabs(
                          activeFilter: controller.activeFilter.value,
                          stats: controller.stats.value,
                          onFilterChanged: controller.setFilter,
                        ),
                        const SizedBox(height: 10),
                        _SearchAndActionRow(
                          initialValue: controller.searchQuery.value,
                          todoCount: controller.todoCount,
                          isSubmittingAll: controller.isSubmittingAll.value,
                          onSearchChanged: controller.updateSearchQuery,
                          onAddCitation: () =>
                              _showAddCitationSheet(context, paymentController),
                          onSubmitAll: controller.submitAllTodo,
                        ),
                        if (jobStats != null && jobStats.total > 0) ...[
                          const SizedBox(height: 12),
                          _JobQueueCard(jobStats: jobStats),
                        ],
                        const SizedBox(height: 12),
                        _TrackedCitationsSection(
                          citations: filteredCitations,
                          allCitationsCount: controller.citations.length,
                          onOpenExternal: _openExternal,
                          onOpenCitationProof: _openCitationProof,
                          onChangeStatus: controller.updateStatus,
                          onSubmit: controller.submitCitation,
                          onReviewIssues: () => _showNapIssues(context),
                          onDelete: (citation) =>
                              _confirmDelete(context, citation),
                          isSubmittingCitation: controller.isSubmittingCitation,
                          isDeletingCitation: controller.isDeletingCitation,
                          isUpdatingCitation: controller.isUpdatingCitation,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Future<void> _showAddCitationSheet(
    BuildContext context,
    PaymentController paymentController,
  ) async {
    final allowed = await _guardCitationSubmission(
      context,
      paymentController,
      actionLabel: 'add a manual citation',
    );
    if (!allowed) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder: (sheetContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
          child: _ManualCitationSheet(controller: controller),
        );
      },
    );
  }

  Future<void> _handleTrackSuggestion(
    BuildContext context,
    PaymentController paymentController,
    DirectorySuggestion suggestion,
  ) async {
    final allowed = await _guardCitationSubmission(
      context,
      paymentController,
      actionLabel: 'track ${suggestion.name}',
    );
    if (!allowed) {
      return;
    }
    await controller.addSuggestion(suggestion);
  }

  Future<void> _showNapEditor(
    BuildContext context,
    CitationNapInfo? napInfo,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _NapEditorSheet(controller: controller, napInfo: napInfo);
      },
    );
  }

  Future<void> _showNapIssues(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _NapIssuesSheet(
          citations: controller.inconsistentActiveCitations,
          napInfo: controller.effectiveNapInfo,
          onOpenExternal: _openExternal,
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CitationRecord citation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete citation?',
            style: AppTypography.card(fontSize: 18, color: AppColors.brandBlue),
          ),
          content: Text(
            'Remove ${citation.directory} from your citation tracker?',
            style: AppTypography.body(
              fontSize: 13.5,
              color: AppColors.mutedText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: AppTypography.button(
                  fontSize: 13.5,
                  color: AppColors.mutedText,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD64545),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Delete',
                style: AppTypography.button(
                  fontSize: 13.5,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await controller.deleteCitation(citation);
    }
  }

  Future<void> _openCitationProof(CitationRecord citation) async {
    final target = (citation.proofUrl ?? '').trim().isNotEmpty
        ? citation.proofUrl!
        : (citation.directoryUrl ?? '').trim().isNotEmpty
        ? citation.directoryUrl!
        : citation.directory;
    await _openExternal(target);
  }

  Widget? _buildBillingBanner(PaymentController paymentController) {
    final usage = paymentController.billingUsage.value;
    if (usage == null) {
      return null;
    }
    final entitlement = usage.featureEntitlements['CITATION_SUBMISSION'];
    if (usage.locked) {
      return BillingAccessBanner(
        eyebrow: 'workspace billing',
        title: 'This business is waiting for activation.',
        message:
            'Citations stay protected until the selected workspace is covered by an active plan. Activate this business first, then track directories from mobile.',
        badge: usage.planDisplayName,
        primaryLabel: 'Open plans',
        onPrimaryTap: () => Get.toNamed(AppRoutes.payment),
      );
    }
    if (entitlement != null && !entitlement.included) {
      return BillingAccessBanner(
        eyebrow: 'feature lock',
        title: 'Citation submission needs a higher plan.',
        message: entitlement.upgradeMessage,
        badge: usage.planDisplayName,
        primaryLabel: 'Upgrade to unlock',
        onPrimaryTap: () => Get.toNamed(AppRoutes.payment),
      );
    }
    return null;
  }

  Future<bool> _guardCitationSubmission(
    BuildContext context,
    PaymentController paymentController, {
    required String actionLabel,
  }) async {
    final usage = paymentController.billingUsage.value;
    if (usage == null) {
      return true;
    }
    if (usage.locked) {
      await showBillingAccessSheet(
        context: context,
        title: 'Activate this business first',
        message:
            'You need an active billing plan for this workspace before you can $actionLabel in the citation manager.',
        badge: usage.planDisplayName,
        primaryLabel: 'Open plans',
        onPrimaryTap: () => Get.toNamed(AppRoutes.payment),
        secondaryLabel: 'Maybe later',
        onSecondaryTap: () {},
      );
      return false;
    }

    final entitlement = usage.featureEntitlements['CITATION_SUBMISSION'];
    if (entitlement != null && !entitlement.included) {
      await showBillingAccessSheet(
        context: context,
        title: 'Citation submission is locked',
        message: entitlement.upgradeMessage,
        badge: usage.planDisplayName,
        primaryLabel: 'Upgrade plan',
        onPrimaryTap: () => Get.toNamed(AppRoutes.payment),
        secondaryLabel: 'Stay on current plan',
        onSecondaryTap: () {},
      );
      return false;
    }
    return true;
  }

  Future<void> _openExternal(String rawUrl) async {
    final uri = _normalizeUri(rawUrl);
    if (uri == null) {
      Get.snackbar(
        'Link unavailable',
        'This link could not be opened.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: AppColors.text,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      Get.snackbar(
        'Open failed',
        'Could not open ${uri.toString()}.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: AppColors.text,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  Uri? _normalizeUri(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return null;
    }
    if (uri.hasScheme) {
      return uri;
    }
    return Uri.tryParse('https://$trimmed');
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.onRefresh, required this.isRefreshing});

  final Future<void> Function() onRefresh;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.menu_rounded,
                  size: 22,
                  color: AppColors.brandBlue,
                ),
                const SizedBox(width: 8),
                const VisibloBrandWordmark(iconSize: 22, fontSize: 16.5),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Citation Manager',
          style: const TextStyle(
            fontSize: 25.5,
            height: 1.04,
            color: AppColors.brandBlue,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                'Manage your business listings across directories',
                style: AppTypography.body(
                  fontSize: 12.5,
                  color: const Color(0xFF6F7F93),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isRefreshing)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.selectedLocation,
    required this.locations,
    required this.dropdownValue,
    required this.onLocationChanged,
    required this.isRefreshing,
  });

  final BusinessLocationSummary? selectedLocation;
  final List<BusinessLocationSummary> locations;
  final String? dropdownValue;
  final Future<void> Function(String? value) onLocationChanged;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Business Location',
                  style: AppTypography.card(
                    fontSize: 17,
                    color: AppColors.brandBlue,
                  ),
                ),
              ),
              if (isRefreshing)
                Text(
                  'Syncing...',
                  style: AppTypography.label(
                    fontSize: 11.5,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(dropdownValue ?? 'citation-location'),
            initialValue: dropdownValue,
            isExpanded: true,
            decoration: _inputDecoration(hintText: 'Select location'),
            items: locations
                .map(
                  (location) => DropdownMenuItem<String>(
                    value: location.id,
                    child: Text(
                      location.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        fontSize: 13,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: onLocationChanged,
          ),
          if (selectedLocation != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.storefront_rounded,
                  label: selectedLocation!.primaryCategory.isEmpty
                      ? 'Business location'
                      : selectedLocation!.primaryCategory,
                ),
                if (selectedLocation!.displayAddress.isNotEmpty)
                  _InfoChip(
                    icon: Icons.location_on_outlined,
                    label: selectedLocation!.displayAddress,
                  ),
                if (selectedLocation!.phone.isNotEmpty)
                  _InfoChip(
                    icon: Icons.phone_outlined,
                    label: selectedLocation!.phone,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricSection extends StatelessWidget {
  const _MetricSection({
    required this.controller,
    required this.onFixIssues,
    required this.onDiscover,
    required this.onAddCitation,
  });

  final CitationManagerController controller;
  final VoidCallback? onFixIssues;
  final Future<void> Function() onDiscover;
  final VoidCallback onAddCitation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 280;
        final itemWidth = useTwoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _ScoreMetricCard(
                title: 'Directory Coverage',
                score: controller.coverageScore,
                accentColor: AppColors.brandBlue,
                icon: Icons.travel_explore_rounded,
                description:
                    '${controller.stats.value?.active ?? 0}/${controller.stats.value?.all ?? 0} live listings',
                footerLabel: 'Improve coverage',
                footerOutlined: false,
                onFooterTap: onDiscover,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _ScoreMetricCard(
                title: 'NAP Consistency',
                score: controller.napScore,
                accentColor: AppColors.primary,
                icon: Icons.verified_user_outlined,
                description: controller.checkedCitationCount == 0
                    ? 'Scan tracked listings'
                    : controller.inconsistentActiveCitations.isEmpty
                    ? 'Name, address, phone match'
                    : '${controller.inconsistentActiveCitations.length} listings need review',
                footerLabel: controller.inconsistentActiveCitations.isEmpty
                    ? 'Add citation'
                    : 'Fix issues',
                footerOutlined: controller.inconsistentActiveCitations.isEmpty,
                onFooterTap: controller.inconsistentActiveCitations.isEmpty
                    ? onAddCitation
                    : onFixIssues,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.isScanning,
    required this.trackedCount,
    required this.onScan,
    required this.onAddCitation,
  });

  final bool isScanning;
  final int trackedCount;
  final Future<void> Function() onScan;
  final VoidCallback onAddCitation;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF9FB),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: AppTypography.card(
                        fontSize: 15.8,
                        color: AppColors.brandBlue,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      trackedCount == 0
                          ? 'Add a listing first, then scan NAP.'
                          : '$trackedCount tracked listings ready to scan.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        fontSize: 11.2,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickActionCapsule(
                  icon: Icons.radar_rounded,
                  label: isScanning ? 'Scanning...' : 'Scan NAP',
                  filled: false,
                  isLoading: isScanning,
                  expand: true,
                  onTap: isScanning ? null : onScan,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionCapsule(
                  icon: Icons.add_business_rounded,
                  label: 'Add listing',
                  expand: true,
                  onTap: onAddCitation,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ActionHint(
                  icon: Icons.fact_check_outlined,
                  text: 'Scan verifies name, address and phone.',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionHint(
                  icon: Icons.post_add_rounded,
                  text: 'Add listing tracks one directory.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionHint extends StatelessWidget {
  const _ActionHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF7A8DA5)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label(
              fontSize: 9.6,
              color: const Color(0xFF7A8DA5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _NapCard extends StatelessWidget {
  const _NapCard({
    required this.napInfo,
    required this.onEdit,
    required this.onOpenExternal,
  });

  final CitationNapInfo? napInfo;
  final VoidCallback onEdit;
  final Future<void> Function(String url) onOpenExternal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Your NAP Information',
                style: AppTypography.card(
                  fontSize: 17,
                  color: AppColors.brandBlue,
                ),
              ),
            ),
            if (napInfo != null && !napInfo!.isEmpty)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: napInfo!.gmbLinked
                      ? const Color(0xFFE9F8EF)
                      : const Color(0xFFFFF5E6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  napInfo!.gmbLinked
                      ? 'GBP Sync Enabled'
                      : 'Local Profile Editing',
                  style: AppTypography.label(
                    fontSize: 10.5,
                    color: napInfo!.gmbLinked
                        ? const Color(0xFF1B9E5A)
                        : const Color(0xFFB8700B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandBlue,
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Edit',
                style: AppTypography.label(
                  fontSize: 11.8,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (napInfo == null || napInfo!.isEmpty)
          _PanelCard(
            child: _EmptySectionState(
              icon: Icons.info_outline_rounded,
              title: 'NAP information not available yet',
              description:
                  'Save your business name, address, phone, and website to use this as the source of truth for citation checks.',
            ),
          )
        else
          Column(
            children: [
              _NapDetailTile(
                icon: Icons.business_outlined,
                title: 'BUSINESS NAME',
                value: napInfo!.businessName,
                iconBackground: const Color(0xFFF0EAFE),
                iconColor: const Color(0xFF7450C8),
              ),
              const SizedBox(height: 10),
              _NapDetailTile(
                icon: Icons.location_on_outlined,
                title: 'ADDRESS',
                value: napInfo!.address,
                iconBackground: const Color(0xFFE8F6FF),
                iconColor: const Color(0xFF3594E8),
              ),
              const SizedBox(height: 10),
              _NapDetailTile(
                icon: Icons.phone_outlined,
                title: 'PHONE',
                value: napInfo!.phone,
                iconBackground: const Color(0xFFE7F9EA),
                iconColor: const Color(0xFF34A853),
              ),
              const SizedBox(height: 10),
              _NapDetailTile(
                icon: Icons.language_rounded,
                title: 'WEBSITE',
                value: napInfo!.website.isEmpty
                    ? 'No website added yet'
                    : napInfo!.website,
                iconBackground: const Color(0xFFFFF2E8),
                iconColor: const Color(0xFFE3832A),
              ),
              const SizedBox(height: 10),
              _NapDetailTile(
                icon: Icons.schedule_rounded,
                title: 'BUSINESS HOURS',
                value: _hoursSummary(napInfo!.regularHours),
                iconBackground: const Color(0xFFF0EAFE),
                iconColor: const Color(0xFF7450C8),
              ),
              if ((napInfo!.gmbSyncFields ?? const <CitationGmbSyncField>[])
                  .isNotEmpty) ...[
                const SizedBox(height: 12),
                _PanelCard(
                  backgroundColor: const Color(0xFFFDFEFF),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Sync Status',
                        style: AppTypography.card(
                          fontSize: 16,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'VisibloAI is your source of truth. If Google rejects a field, use the actions below to confirm it manually in your live profile.',
                        style: AppTypography.body(
                          fontSize: 12.2,
                          color: AppColors.mutedText,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if ((napInfo!.googleSearchUrl ?? '')
                              .trim()
                              .isNotEmpty)
                            _InlineAction(
                              icon: Icons.open_in_new_rounded,
                              label: 'Open In Google',
                              onPressed: () =>
                                  onOpenExternal(napInfo!.googleSearchUrl!),
                            ),
                          if ((napInfo!.googleBusinessProfileUrl ?? '')
                              .trim()
                              .isNotEmpty)
                            _InlineAction(
                              icon: Icons.storefront_rounded,
                              label: 'Open GBP Manager',
                              onPressed: () => onOpenExternal(
                                napInfo!.googleBusinessProfileUrl!,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: napInfo!.gmbSyncFields!
                            .map(
                              (field) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _GmbSyncFieldCard(
                                  field: field,
                                  googleSearchUrl: napInfo!.googleSearchUrl,
                                  onOpenExternal: onOpenExternal,
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _GmbSyncFieldCard extends StatelessWidget {
  const _GmbSyncFieldCard({
    required this.field,
    required this.googleSearchUrl,
    required this.onOpenExternal,
  });

  final CitationGmbSyncField field;
  final String? googleSearchUrl;
  final Future<void> Function(String url) onOpenExternal;

  @override
  Widget build(BuildContext context) {
    final style = _gmbSyncStyleFor(field.status);
    final needsConfirmation =
        field.status == CitationGmbSyncStatus.manualConfirmation ||
        field.status == CitationGmbSyncStatus.failed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EDF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  field.label,
                  style: AppTypography.card(
                    fontSize: 14.2,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _Badge(
                label: style.label,
                foreground: style.foreground,
                background: style.background,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            field.detail,
            style: AppTypography.body(
              fontSize: 12.1,
              color: AppColors.mutedText,
              height: 1.45,
            ),
          ),
          if (needsConfirmation &&
              (googleSearchUrl ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _InlineAction(
              icon: Icons.open_in_new_rounded,
              label: 'Confirm In Google',
              onPressed: () => onOpenExternal(googleSearchUrl!),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiscoverSection extends StatefulWidget {
  const _DiscoverSection({
    required this.controller,
    required this.onOpenExternal,
    required this.onTrackSuggestion,
  });

  final CitationManagerController controller;
  final Future<void> Function(String url) onOpenExternal;
  final Future<void> Function(DirectorySuggestion suggestion) onTrackSuggestion;

  @override
  State<_DiscoverSection> createState() => _DiscoverSectionState();
}

class _DiscoverSectionState extends State<_DiscoverSection> {
  late Map<String, int> _visibleCount;
  String _discoverQuery = '';
  String _discoverFilter = 'all';

  @override
  void initState() {
    super.initState();
    _visibleCount = <String, int>{
      'core': _discoverPageSize,
      'social': _discoverPageSize,
      'industry': _discoverPageSize,
      'more': _discoverPageSize,
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final shouldShow = controller.showSuggestions.value;
    final suggestionsLabel = controller.suggestions.isEmpty
        ? 'India directories like Justdial, IndiaMart, Sulekha, and Cylex are prioritized when relevant.'
        : controller.suggestions.take(5).map((item) => item.name).join(', ');
    final filteredSuggestions = controller.suggestions
        .where((suggestion) {
          final query = _discoverQuery.trim().toLowerCase();
          if (query.isEmpty) {
            return true;
          }
          return suggestion.name.toLowerCase().contains(query) ||
              suggestion.domain.toLowerCase().contains(query);
        })
        .toList(growable: false);
    final groupedSuggestions = _groupSuggestions(filteredSuggestions);
    final visibleGroups = groupedSuggestions.entries
        .where((entry) {
          if (entry.value.isEmpty) return false;
          return _discoverFilter == 'all' || _discoverFilter == entry.key;
        })
        .toList(growable: false);
    final selectedCategory =
        (controller.selectedLocation?.primaryCategory ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Find directories to track',
                      style: AppTypography.card(
                        fontSize: 17,
                        color: AppColors.brandBlue,
                      ),
                    ),
                  ),
                  if (shouldShow)
                    TextButton(
                      onPressed: controller.hideSuggestions,
                      child: Text(
                        'Hide',
                        style: AppTypography.button(
                          fontSize: 12.8,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                suggestionsLabel,
                style: AppTypography.body(
                  fontSize: 11.9,
                  color: AppColors.mutedText,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              _QuickActionCapsule(
                icon: Icons.travel_explore_rounded,
                label: controller.isDiscovering.value
                    ? 'Finding...'
                    : 'Find directories to track',
                isLoading: controller.isDiscovering.value,
                expand: true,
                onTap: controller.isDiscovering.value
                    ? null
                    : controller.discoverDirectories,
              ),
            ],
          ),
        ),
        if (shouldShow) ...[
          const SizedBox(height: 12),
          _PanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested next directories',
                  style: AppTypography.card(
                    fontSize: 17,
                    color: AppColors.brandBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track these first, then run NAP Scan to verify whether the listing is already live.',
                  style: AppTypography.body(
                    fontSize: 12.5,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _discoverQuery,
                  onChanged: (value) => setState(() => _discoverQuery = value),
                  decoration: _inputDecoration(
                    hintText: 'Search directories or domains',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.mutedText,
                    ),
                  ),
                  style: AppTypography.body(
                    fontSize: 13,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All (${filteredSuggestions.length})',
                        selected: _discoverFilter == 'all',
                        onTap: () => setState(() => _discoverFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label:
                            'Core (${groupedSuggestions['core']?.length ?? 0})',
                        selected: _discoverFilter == 'core',
                        onTap: () => setState(() => _discoverFilter = 'core'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label:
                            'Social (${groupedSuggestions['social']?.length ?? 0})',
                        selected: _discoverFilter == 'social',
                        onTap: () => setState(() => _discoverFilter = 'social'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label:
                            'Category fit (${groupedSuggestions['industry']?.length ?? 0})',
                        selected: _discoverFilter == 'industry',
                        onTap: () =>
                            setState(() => _discoverFilter = 'industry'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (controller.isDiscovering.value)
                  const _CenteredLoadingMessage(
                    label:
                        'Analyzing this location and finding the best directories...',
                  )
                else if (controller.suggestions.isEmpty)
                  const _EmptySectionState(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'No more suggestions right now',
                    description:
                        'You have likely already added the best available directories for this location.',
                  )
                else if (visibleGroups.isEmpty)
                  const _EmptySectionState(
                    icon: Icons.search_off_rounded,
                    title: 'No directories match this filter',
                    description:
                        'Try a different search term or switch back to All directories.',
                  )
                else
                  Column(
                    children: visibleGroups
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _DiscoverGroupSection(
                              groupKey: entry.key,
                              title: _groupTitle(entry.key),
                              subtitle: _groupSubtitle(
                                entry.key,
                                selectedCategory,
                              ),
                              visibleCount:
                                  _visibleCount[entry.key] ?? _discoverPageSize,
                              suggestions: entry.value,
                              onToggle: () {
                                setState(() {
                                  final isExpanded =
                                      (_visibleCount[entry.key] ??
                                          _discoverPageSize) >=
                                      entry.value.length;
                                  _visibleCount[entry.key] = isExpanded
                                      ? _discoverPageSize
                                      : entry.value.length;
                                });
                              },
                              controller: controller,
                              onOpenExternal: widget.onOpenExternal,
                              onTrackSuggestion: widget.onTrackSuggestion,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Map<String, List<DirectorySuggestion>> _groupSuggestions(
    List<DirectorySuggestion> suggestions,
  ) {
    final core = <DirectorySuggestion>[];
    final social = <DirectorySuggestion>[];
    final industry = <DirectorySuggestion>[];
    final more = <DirectorySuggestion>[];

    for (final suggestion in suggestions) {
      final domain = suggestion.domain.trim().toLowerCase();
      if (suggestion.isSocialDirectory) {
        social.add(suggestion);
      } else if (_commonDirectoryDomains.contains(domain)) {
        core.add(suggestion);
      } else if (suggestion.industries.isNotEmpty) {
        industry.add(suggestion);
      } else {
        more.add(suggestion);
      }
    }

    int byName(DirectorySuggestion left, DirectorySuggestion right) =>
        left.name.toLowerCase().compareTo(right.name.toLowerCase());

    core.sort(byName);
    social.sort(byName);
    industry.sort(byName);
    more.sort(byName);

    return <String, List<DirectorySuggestion>>{
      'core': core,
      'social': social,
      'industry': industry,
      'more': more,
    };
  }

  String _groupTitle(String key) {
    switch (key) {
      case 'core':
        return 'Core directories';
      case 'social':
        return 'Social profiles';
      case 'industry':
        return 'Category fit';
      default:
        return 'More opportunities';
    }
  }

  String _groupSubtitle(String key, String selectedCategory) {
    switch (key) {
      case 'core':
        return 'High-utility listings most owners should keep consistent first.';
      case 'social':
        return 'Useful where your brand identity matters, but often needs manual verification.';
      case 'industry':
        return selectedCategory.isEmpty
            ? 'Directories chosen because they fit this business category.'
            : 'Your category looks like $selectedCategory, so these directories fit that business type best.';
      default:
        return 'Additional niche and supporting directories to strengthen coverage.';
    }
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.activeFilter,
    required this.stats,
    required this.onFilterChanged,
  });

  final String activeFilter;
  final CitationStats? stats;
  final void Function(String value) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = <({String id, String label, int count})>[
      (id: 'ALL', label: 'All', count: stats?.all ?? 0),
      (
        id: CitationStatus.todo.apiValue,
        label: 'To-do',
        count: stats?.todo ?? 0,
      ),
      (
        id: CitationStatus.processing.apiValue,
        label: 'Processing',
        count: stats?.processing ?? 0,
      ),
      (
        id: CitationStatus.active.apiValue,
        label: 'Active',
        count: stats?.active ?? 0,
      ),
      (
        id: CitationStatus.lost.apiValue,
        label: 'Lost',
        count: stats?.lost ?? 0,
      ),
      (
        id: CitationStatus.ignored.apiValue,
        label: 'Ignored',
        count: stats?.ignored ?? 0,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs
            .map(
              (tab) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: '${tab.label} (${tab.count})',
                  selected: activeFilter == tab.id,
                  onTap: () => onFilterChanged(tab.id),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _DiscoverGroupSection extends StatelessWidget {
  const _DiscoverGroupSection({
    required this.groupKey,
    required this.title,
    required this.subtitle,
    required this.visibleCount,
    required this.suggestions,
    required this.onToggle,
    required this.controller,
    required this.onOpenExternal,
    required this.onTrackSuggestion,
  });

  final String groupKey;
  final String title;
  final String subtitle;
  final int visibleCount;
  final List<DirectorySuggestion> suggestions;
  final VoidCallback onToggle;
  final CitationManagerController controller;
  final Future<void> Function(String url) onOpenExternal;
  final Future<void> Function(DirectorySuggestion suggestion) onTrackSuggestion;

  @override
  Widget build(BuildContext context) {
    final theme = _discoverGroupThemeFor(groupKey);
    final visibleSuggestions = suggestions
        .take(visibleCount)
        .toList(growable: false);
    final canToggle = suggestions.length > _discoverPageSize;
    final isExpanded = visibleCount >= suggestions.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: theme.softAccent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                title,
                style: AppTypography.label(
                  fontSize: 11.6,
                  color: theme.accent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.body(
              fontSize: 12,
              color: AppColors.mutedText,
              height: 1.42,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: visibleSuggestions
                .map(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DirectorySuggestionCard(
                      groupKey: groupKey,
                      suggestion: suggestion,
                      isAdding:
                          controller.addingSuggestionId.value == suggestion.id,
                      onAdd: () => onTrackSuggestion(suggestion),
                      onOpenExternal: onOpenExternal,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          if (canToggle) ...[
            const SizedBox(height: 2),
            Center(
              child: TextButton.icon(
                onPressed: onToggle,
                icon: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: theme.accent,
                ),
                label: Text(
                  isExpanded ? 'Show less' : 'See more in this section',
                  style: AppTypography.button(
                    fontSize: 12.2,
                    color: theme.accent,
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

class _SearchAndActionRow extends StatelessWidget {
  const _SearchAndActionRow({
    required this.initialValue,
    required this.todoCount,
    required this.isSubmittingAll,
    required this.onSearchChanged,
    required this.onAddCitation,
    required this.onSubmitAll,
  });

  final String initialValue;
  final int todoCount;
  final bool isSubmittingAll;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddCitation;
  final Future<void> Function() onSubmitAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: initialValue,
          onChanged: onSearchChanged,
          decoration: _inputDecoration(
            hintText: 'Search',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.mutedText,
            ),
          ),
          style: AppTypography.body(
            fontSize: 13,
            color: AppColors.brandBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        if (todoCount > 0)
          Row(
            children: [
              Expanded(
                child: _QuickActionCapsule(
                  icon: Icons.add_rounded,
                  label: 'Add manual citation',
                  expand: true,
                  onTap: onAddCitation,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionCapsule(
                  icon: Icons.sync_rounded,
                  label: isSubmittingAll
                      ? 'Submitting...'
                      : 'Submit All ($todoCount)',
                  isLoading: isSubmittingAll,
                  expand: true,
                  onTap: isSubmittingAll ? null : onSubmitAll,
                ),
              ),
            ],
          )
        else
          _QuickActionCapsule(
            icon: Icons.add_rounded,
            label: 'Add manual citation',
            expand: true,
            onTap: onAddCitation,
          ),
      ],
    );
  }
}

class _JobQueueCard extends StatelessWidget {
  const _JobQueueCard({required this.jobStats});

  final CitationJobStats jobStats;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      backgroundColor: const Color(0xFFF9FBFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submission Queue',
            style: AppTypography.card(fontSize: 17, color: AppColors.brandBlue),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QueueBadge(
                label: '${jobStats.queued} queued',
                color: const Color(0xFFF1A43B),
                background: const Color(0xFFFFF5E6),
              ),
              _QueueBadge(
                label: '${jobStats.running} running',
                color: const Color(0xFF2368D8),
                background: const Color(0xFFEAF2FF),
              ),
              _QueueBadge(
                label: '${jobStats.awaitingVerification} awaiting',
                color: const Color(0xFF7A58D1),
                background: const Color(0xFFF2EDFF),
              ),
              _QueueBadge(
                label: '${jobStats.completed} completed',
                color: const Color(0xFF1B9E5A),
                background: const Color(0xFFE9F8EF),
              ),
              _QueueBadge(
                label: '${jobStats.failed} failed',
                color: const Color(0xFFD64545),
                background: const Color(0xFFFFECEC),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackedCitationsSection extends StatelessWidget {
  const _TrackedCitationsSection({
    required this.citations,
    required this.allCitationsCount,
    required this.onOpenExternal,
    required this.onOpenCitationProof,
    required this.onChangeStatus,
    required this.onSubmit,
    required this.onReviewIssues,
    required this.onDelete,
    required this.isSubmittingCitation,
    required this.isDeletingCitation,
    required this.isUpdatingCitation,
  });

  final List<CitationRecord> citations;
  final int allCitationsCount;
  final Future<void> Function(String url) onOpenExternal;
  final Future<void> Function(CitationRecord citation) onOpenCitationProof;
  final Future<void> Function(CitationRecord citation, CitationStatus status)
  onChangeStatus;
  final Future<void> Function(CitationRecord citation) onSubmit;
  final VoidCallback onReviewIssues;
  final Future<void> Function(CitationRecord citation) onDelete;
  final bool Function(String citationId) isSubmittingCitation;
  final bool Function(String citationId) isDeletingCitation;
  final bool Function(String citationId) isUpdatingCitation;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tracked Citations',
            style: AppTypography.card(fontSize: 17, color: AppColors.brandBlue),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage status, proof, and submission actions for each tracked directory.',
            style: AppTypography.body(
              fontSize: 12.5,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 12),
          if (citations.isEmpty)
            _EmptySectionState(
              icon: Icons.public_off_outlined,
              title: allCitationsCount == 0
                  ? 'No citations yet'
                  : 'No citations match this filter',
              description: allCitationsCount == 0
                  ? 'Add a manual citation or discover suggested directories to start tracking live listings.'
                  : 'Try a different status filter or search term.',
            )
          else
            Column(
              children: citations
                  .map(
                    (citation) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CitationCard(
                        citation: citation,
                        onOpenExternal: onOpenExternal,
                        onOpenCitationProof: onOpenCitationProof,
                        onChangeStatus: onChangeStatus,
                        onSubmit: onSubmit,
                        onReviewIssues: onReviewIssues,
                        onDelete: onDelete,
                        isSubmitting: isSubmittingCitation(citation.id),
                        isDeleting: isDeletingCitation(citation.id),
                        isUpdating: isUpdatingCitation(citation.id),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _CitationCard extends StatelessWidget {
  const _CitationCard({
    required this.citation,
    required this.onOpenExternal,
    required this.onOpenCitationProof,
    required this.onChangeStatus,
    required this.onSubmit,
    required this.onReviewIssues,
    required this.onDelete,
    required this.isSubmitting,
    required this.isDeleting,
    required this.isUpdating,
  });

  final CitationRecord citation;
  final Future<void> Function(String url) onOpenExternal;
  final Future<void> Function(CitationRecord citation) onOpenCitationProof;
  final Future<void> Function(CitationRecord citation, CitationStatus status)
  onChangeStatus;
  final Future<void> Function(CitationRecord citation) onSubmit;
  final VoidCallback onReviewIssues;
  final Future<void> Function(CitationRecord citation) onDelete;
  final bool isSubmitting;
  final bool isDeleting;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyleFor(citation.status);
    final verificationStyle = _verificationStyleFor(
      citation.verificationStatus,
    );
    final directoryLink = (citation.directoryUrl ?? '').trim().isNotEmpty
        ? citation.directoryUrl!
        : citation.directory;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE7F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F2746),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            width: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [Color(0xFF0FA4AF), Color(0xFF2368D8)],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DirectoryAvatar(directory: citation.directory),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      citation.directory,
                      style: AppTypography.card(
                        fontSize: 15.5,
                        color: AppColors.brandBlue,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(citation.updatedAt),
                      style: AppTypography.label(
                        fontSize: 11.5,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<CitationStatus>(
                enabled: !isUpdating && !isDeleting,
                tooltip: 'Change status',
                position: PopupMenuPosition.under,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (status) => onChangeStatus(citation, status),
                itemBuilder: (context) {
                  return CitationStatus.values
                      .map(
                        (status) => PopupMenuItem<CitationStatus>(
                          value: status,
                          child: Text(
                            status.label,
                            style: AppTypography.body(
                              fontSize: 13,
                              color: AppColors.text,
                              fontWeight: citation.status == status
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false);
                },
                child: _Badge(
                  label: isUpdating ? 'Updating...' : statusStyle.label,
                  foreground: statusStyle.foreground,
                  background: statusStyle.background,
                  icon: Icons.keyboard_arrow_down_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(
                label: citation.confidenceScore > 0
                    ? '${verificationStyle.label} · ${citation.confidenceScore}%'
                    : verificationStyle.label,
                foreground: verificationStyle.foreground,
                background: verificationStyle.background,
              ),
              if (citation.backlink)
                const _Badge(
                  label: 'Backlink',
                  foreground: Color(0xFF1B9E5A),
                  background: Color(0xFFE9F8EF),
                ),
              if ((citation.proofUrl ?? '').trim().isNotEmpty)
                const _Badge(
                  label: 'Proof available',
                  foreground: Color(0xFF2368D8),
                  background: Color(0xFFEAF2FF),
                ),
            ],
          ),
          if (citation.matchedFields.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: citation.matchedFields
                  .take(4)
                  .map((field) => _TinyChip(label: field.replaceAll('_', ' ')))
                  .toList(growable: false),
            ),
          ],
          if (citation.verificationIssues.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              citation.verificationIssues.first,
              style: AppTypography.body(
                fontSize: 12.5,
                color: AppColors.mutedText,
              ),
            ),
          ],
          if ((citation.foundName ?? '').trim().isNotEmpty ||
              (citation.foundAddress ?? '').trim().isNotEmpty ||
              (citation.foundPhone ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEAF2FA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detected listing details',
                    style: AppTypography.label(
                      fontSize: 11.5,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if ((citation.foundName ?? '').trim().isNotEmpty)
                    _DetectedInfoRow(title: 'Name', value: citation.foundName!),
                  if ((citation.foundAddress ?? '').trim().isNotEmpty)
                    _DetectedInfoRow(
                      title: 'Address',
                      value: citation.foundAddress!,
                    ),
                  if ((citation.foundPhone ?? '').trim().isNotEmpty)
                    _DetectedInfoRow(
                      title: 'Phone',
                      value: citation.foundPhone!,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (citation.status == CitationStatus.todo)
                _InlineAction(
                  icon: isSubmitting ? null : Icons.sync_rounded,
                  label: isSubmitting ? 'Submitting...' : 'Submit',
                  isLoading: isSubmitting,
                  customForeground: const Color(0xFF0E6C74),
                  customBackground: const Color(0xFFE7FAFC),
                  onPressed: isSubmitting ? null : () => onSubmit(citation),
                ),
              if (citation.status == CitationStatus.processing)
                const _InlineInfoBadge(
                  label: 'Awaiting verification',
                  foreground: Color(0xFFF1A43B),
                  background: Color(0xFFFFF5E6),
                ),
              if (citation.status == CitationStatus.active &&
                  !citation.napConsistent)
                _InlineAction(
                  icon: Icons.rule_folder_outlined,
                  label: 'Review NAP issue',
                  customForeground: const Color(0xFFB8700B),
                  customBackground: const Color(0xFFFFF6E7),
                  onPressed: onReviewIssues,
                ),
              if (citation.hasProofLink)
                _InlineAction(
                  icon: Icons.open_in_new_rounded,
                  label: 'Proof',
                  customForeground: const Color(0xFF2368D8),
                  customBackground: const Color(0xFFEAF2FF),
                  onPressed: () => onOpenCitationProof(citation),
                ),
              _InlineAction(
                icon: Icons.language_rounded,
                label: 'Open site',
                customForeground: AppColors.brandBlue,
                customBackground: const Color(0xFFF3F8FE),
                onPressed: () => onOpenExternal(directoryLink),
              ),
              _InlineAction(
                icon: isDeleting ? null : Icons.delete_outline_rounded,
                label: isDeleting ? 'Removing...' : 'Delete',
                isDestructive: true,
                isLoading: isDeleting,
                onPressed: isDeleting ? null : () => onDelete(citation),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DirectorySuggestionCard extends StatefulWidget {
  const _DirectorySuggestionCard({
    required this.groupKey,
    required this.suggestion,
    required this.isAdding,
    required this.onAdd,
    required this.onOpenExternal,
  });

  final String groupKey;
  final DirectorySuggestion suggestion;
  final bool isAdding;
  final Future<void> Function() onAdd;
  final Future<void> Function(String url) onOpenExternal;

  @override
  State<_DirectorySuggestionCard> createState() =>
      _DirectorySuggestionCardState();
}

class _DirectorySuggestionCardState extends State<_DirectorySuggestionCard> {
  bool _showReasons = false;

  @override
  Widget build(BuildContext context) {
    final suggestion = widget.suggestion;
    final theme = _discoverGroupThemeFor(widget.groupKey);
    final whyReasons = suggestion.recommendationReasons
        .take(3)
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100D2544),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.softAccent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.border),
                ),
                child: Icon(
                  Icons.travel_explore_rounded,
                  size: 21,
                  color: theme.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.name,
                      style: AppTypography.card(
                        fontSize: 16.2,
                        color: theme.accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      suggestion.domain,
                      style: AppTypography.label(
                        fontSize: 11.5,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.auto_awesome_rounded, size: 18, color: theme.accent),
            ],
          ),
          if (whyReasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _showReasons = !_showReasons),
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.softAccent.withValues(alpha: 0.64),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.border.withValues(alpha: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: theme.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _showReasons
                            ? 'Hide directory details'
                            : 'Why this directory?',
                        style: AppTypography.label(
                          fontSize: 12.2,
                          color: theme.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _showReasons ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: theme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: whyReasons
                        .map(
                          (reason) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    size: 12,
                                    color: theme.accent,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    reason,
                                    style: AppTypography.body(
                                      fontSize: 12.1,
                                      color: AppColors.mutedText,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
              crossFadeState: _showReasons
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
            ),
          ],
          if ((suggestion.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              suggestion.notes!,
              style: AppTypography.body(
                fontSize: 12.4,
                color: AppColors.mutedText,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InlineAction(
                  icon: widget.isAdding ? null : Icons.add_task_outlined,
                  label: widget.isAdding ? 'Adding...' : 'Track directory',
                  isLoading: widget.isAdding,
                  customForeground: Colors.white,
                  customBackground: theme.accent,
                  onPressed: widget.isAdding ? null : widget.onAdd,
                ),
              ),
              if ((suggestion.submissionUrl ?? '').trim().isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _InlineAction(
                    icon: Icons.open_in_new_rounded,
                    label: 'Open site',
                    customForeground: theme.accent,
                    customBackground: Colors.white,
                    borderColor: theme.border,
                    onPressed: () =>
                        widget.onOpenExternal(suggestion.submissionUrl!),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ManualCitationSheet extends StatefulWidget {
  const _ManualCitationSheet({required this.controller});

  final CitationManagerController controller;

  @override
  State<_ManualCitationSheet> createState() => _ManualCitationSheetState();
}

class _ManualCitationSheetState extends State<_ManualCitationSheet> {
  late final TextEditingController _directoryController;
  late final TextEditingController _directoryUrlController;
  CitationStatus _status = CitationStatus.todo;
  bool _backlink = false;

  @override
  void initState() {
    super.initState();
    _directoryController = TextEditingController();
    _directoryUrlController = TextEditingController();
  }

  @override
  void dispose() {
    _directoryController.dispose();
    _directoryUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 410),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330F2746),
              blurRadius: 30,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add manual citation',
                      style: AppTypography.card(
                        fontSize: 18,
                        color: AppColors.brandBlue,
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
              const SizedBox(height: 10),
              Text(
                'Directory',
                style: AppTypography.button(
                  fontSize: 13.6,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Enter the directory domain where your business is or will be listed (e.g., example.com).',
                style: AppTypography.body(
                  fontSize: 12.6,
                  color: const Color(0xFF708197),
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _directoryController,
                decoration: _inputDecoration(hintText: 'example.com'),
                style: AppTypography.body(
                  fontSize: 13,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Backlink',
                style: AppTypography.button(
                  fontSize: 13.6,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(-6, -4),
                    child: Checkbox(
                      value: _backlink,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _backlink = value ?? false;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Select this option if this directory allows you to include a clickable link to your website.',
                      style: AppTypography.body(
                        fontSize: 12.6,
                        color: const Color(0xFF708197),
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Status',
                style: AppTypography.button(
                  fontSize: 13.6,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select the appropriate status: to-do, processing (for the actioned listings awaiting indexing), or active.',
                style: AppTypography.body(
                  fontSize: 12.6,
                  color: const Color(0xFF708197),
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<CitationStatus>(
                initialValue: _status,
                decoration: _inputDecoration(hintText: 'Status'),
                items: CitationStatus.values
                    .map(
                      (status) => DropdownMenuItem<CitationStatus>(
                        value: status,
                        child: Text(
                          status.label,
                          style: AppTypography.body(
                            fontSize: 13,
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _status = value;
                  });
                },
              ),
              const SizedBox(height: 22),
              Obx(() {
                final isSubmitting = widget.controller.isAddingCitation.value;
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.brandBlue,
                          side: const BorderSide(color: Color(0xFFD8E0EA)),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTypography.button(
                            fontSize: 13.2,
                            color: AppColors.brandBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final success = await widget.controller
                                    .addCitation(
                                      directory: _directoryController.text,
                                      directoryUrl:
                                          _directoryUrlController.text,
                                      backlink: _backlink,
                                      status: _status,
                                    );
                                if (!context.mounted || !success) return;
                                Navigator.of(context).pop();
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Add directory',
                                style: AppTypography.button(
                                  fontSize: 13.2,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _NapEditorSheet extends StatefulWidget {
  const _NapEditorSheet({required this.controller, required this.napInfo});

  final CitationManagerController controller;
  final CitationNapInfo? napInfo;

  @override
  State<_NapEditorSheet> createState() => _NapEditorSheetState();
}

class _NapEditorSheetState extends State<_NapEditorSheet> {
  late final TextEditingController _businessNameController;
  late final TextEditingController _completeAddressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _websiteController;
  late Map<String, _DaySchedule> _editHours;
  String? _businessNameError;
  String? _addressError;
  String? _phoneError;
  String? _websiteError;

  @override
  void initState() {
    super.initState();
    final nap = widget.napInfo;
    _businessNameController = TextEditingController(
      text: nap?.businessName ?? '',
    );
    _completeAddressController = TextEditingController(
      text: nap?.address ?? '',
    );
    _phoneController = TextEditingController(text: nap?.phone ?? '');
    _websiteController = TextEditingController(text: nap?.website ?? '');
    _editHours = _buildSchedule(nap?.regularHours);
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _completeAddressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final nap = widget.napInfo;
    final profileFields = <String>[
      _businessNameController.text.trim(),
      _completeAddressController.text.trim(),
      _phoneController.text.trim(),
      _websiteController.text.trim(),
    ].where((value) => value.isNotEmpty).length;

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.94,
        child: Container(
          padding: EdgeInsets.fromLTRB(18, 18, 18, bottomInset + 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8E0EA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Business Information',
                          style: AppTypography.card(
                            fontSize: 20,
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          nap?.gmbLinked == true
                              ? 'Saving here also syncs name, address, phone, website, and hours to your connected Google Business Profile.'
                              : 'Use this as your source of truth so citations stay consistent everywhere.',
                          style: AppTypography.body(
                            fontSize: 12.6,
                            color: AppColors.mutedText,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F8FE),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD9E7F5)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'PROFILE',
                          style: AppTypography.label(
                            fontSize: 10,
                            color: const Color(0xFF8DA0B9),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$profileFields/4',
                          style: AppTypography.card(
                            fontSize: 20,
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFEFF),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFDCEAF6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Core business profile',
                                    style: AppTypography.card(
                                      fontSize: 16,
                                      color: AppColors.brandBlue,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                _TinyChip(
                                  label: nap?.gmbLinked == true
                                      ? 'GBP Sync Enabled'
                                      : 'Local only',
                                  foreground: nap?.gmbLinked == true
                                      ? const Color(0xFF1B9E5A)
                                      : const Color(0xFFB8700B),
                                  background: nap?.gmbLinked == true
                                      ? const Color(0xFFE9F8EF)
                                      : const Color(0xFFFFF5E6),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _LabeledField(
                              label: 'Business name',
                              controller: _businessNameController,
                              errorText: _businessNameError,
                              onChanged: (_) => setState(() {
                                _businessNameError = null;
                              }),
                            ),
                            _LabeledField(
                              label: 'Complete address',
                              hintText:
                                  '196, G Floor, Ziba Creations, Kherwadi Rd, near Sahil Hotel, Bairam Naupada, Bandra East, Mumbai, Maharashtra 400051',
                              helperText:
                                  'Paste the full visible business address exactly as it should appear publicly.',
                              controller: _completeAddressController,
                              errorText: _addressError,
                              maxLines: 3,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              onChanged: (_) => setState(() {
                                _addressError = null;
                              }),
                            ),
                            _LabeledField(
                              label: 'Phone',
                              hintText: '+91 73048 88042',
                              helperText:
                                  'India validation is enabled. We accept a 10-digit mobile number or +91 format.',
                              controller: _phoneController,
                              errorText: _phoneError,
                              keyboardType: TextInputType.phone,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9+\s-]'),
                                ),
                              ],
                              onChanged: (value) {
                                final formatted = _formatIndianPhoneInput(
                                  value,
                                );
                                if (formatted != value) {
                                  _phoneController.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                      offset: formatted.length,
                                    ),
                                  );
                                }
                                setState(() {
                                  _phoneError = null;
                                });
                              },
                            ),
                            _LabeledField(
                              label: 'Website',
                              hintText: 'https://yourwebsite.com',
                              helperText:
                                  "You can paste without 'https://' and we'll normalize it for you.",
                              controller: _websiteController,
                              errorText: _websiteError,
                              keyboardType: TextInputType.url,
                              onChanged: (_) => setState(() {
                                _websiteError = null;
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFEFF),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFDCEAF6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Business hours',
                                        style: AppTypography.card(
                                          fontSize: 16,
                                          color: AppColors.brandBlue,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Review each day carefully before syncing it live.',
                                        style: AppTypography.body(
                                          fontSize: 12.2,
                                          color: AppColors.mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _InlineAction(
                                  icon: Icons.copy_all_rounded,
                                  label: 'Apply Monday to weekdays',
                                  onPressed: _applyMondayToWeekdays,
                                ),
                                _InlineAction(
                                  icon: Icons.event_repeat_rounded,
                                  label: 'Apply Monday to weekend',
                                  onPressed: _applyMondayToWeekend,
                                ),
                                _InlineAction(
                                  icon: Icons.refresh_rounded,
                                  label: 'Reset hours',
                                  onPressed: _resetHours,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ..._allDays.map(
                              (day) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _BusinessHourRow(
                                  dayLabel: _dayLabels[day] ?? day,
                                  schedule: _editHours[day]!,
                                  onClosedChanged: (closed) {
                                    setState(() {
                                      _editHours[day] = _editHours[day]!
                                          .copyWith(closed: closed);
                                    });
                                  },
                                  onOpenChanged: (value) {
                                    setState(() {
                                      _editHours[day] = _editHours[day]!
                                          .copyWith(open: value);
                                    });
                                  },
                                  onCloseChanged: (value) {
                                    setState(() {
                                      _editHours[day] = _editHours[day]!
                                          .copyWith(close: value);
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Obx(() {
                final isSaving = widget.controller.isSavingNap.value;
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.mutedText,
                          side: const BorderSide(color: Color(0xFFD8E0EA)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTypography.button(
                            fontSize: 13,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: isSaving ? null : _handleSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Save Business Info',
                                style: AppTypography.button(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final businessName = _businessNameController.text.trim();
    final address = _completeAddressController.text.trim();
    final phone = _phoneController.text.trim();
    final website = _websiteController.text.trim();

    setState(() {
      _businessNameError = businessName.isEmpty
          ? 'Business name is required.'
          : null;
      _addressError = address.isEmpty ? 'Complete address is required.' : null;
      _phoneError = _isValidIndianPhone(phone)
          ? null
          : 'Enter a valid Indian mobile number.';
      _websiteError = _isValidWebsite(website)
          ? null
          : 'Enter a valid website URL.';
    });

    if (_businessNameError != null ||
        _addressError != null ||
        _phoneError != null ||
        _websiteError != null) {
      return;
    }

    final success = await widget.controller.saveNap(
      businessName: businessName,
      completeAddress: address,
      phone: phone,
      website: website,
      regularHours: _buildRegularHoursPayload(_editHours),
    );
    if (!mounted || !success) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _applyMondayToWeekdays() {
    final source = _editHours['MONDAY']!;
    setState(() {
      for (final day in const <String>[
        'MONDAY',
        'TUESDAY',
        'WEDNESDAY',
        'THURSDAY',
        'FRIDAY',
      ]) {
        _editHours[day] = source;
      }
    });
  }

  void _applyMondayToWeekend() {
    final source = _editHours['MONDAY']!;
    setState(() {
      _editHours['SATURDAY'] = source;
      _editHours['SUNDAY'] = source;
    });
  }

  void _resetHours() {
    setState(() {
      _editHours = _buildSchedule(widget.napInfo?.regularHours);
    });
  }
}

class _BusinessHourRow extends StatelessWidget {
  const _BusinessHourRow({
    required this.dayLabel,
    required this.schedule,
    required this.onClosedChanged,
    required this.onOpenChanged,
    required this.onCloseChanged,
  });

  final String dayLabel;
  final _DaySchedule schedule;
  final ValueChanged<bool> onClosedChanged;
  final ValueChanged<String> onOpenChanged;
  final ValueChanged<String> onCloseChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FCFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCEAF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayLabel,
                      style: AppTypography.card(
                        fontSize: 15,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      schedule.closed ? 'Closed all day' : 'Open for business',
                      style: AppTypography.body(
                        fontSize: 11.8,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              FilterChip(
                selected: schedule.closed,
                label: Text(
                  'Closed',
                  style: AppTypography.button(
                    fontSize: 12,
                    color: schedule.closed
                        ? AppColors.brandBlue
                        : AppColors.mutedText,
                  ),
                ),
                onSelected: onClosedChanged,
                selectedColor: const Color(0xFFEAF2FF),
                checkmarkColor: AppColors.primary,
                side: const BorderSide(color: Color(0xFFD8E0EA)),
                backgroundColor: Colors.white,
              ),
            ],
          ),
          if (!schedule.closed) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimePickerChip(
                    label: 'Opens',
                    value: schedule.open,
                    onSelected: onOpenChanged,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimePickerChip(
                    label: 'Closes',
                    value: schedule.close,
                    onSelected: onCloseChanged,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimePickerChip extends StatelessWidget {
  const _TimePickerChip({
    required this.label,
    required this.value,
    required this.onSelected,
  });

  final String label;
  final String value;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final parts = value.split(':');
        final initialTime = TimeOfDay(
          hour: int.tryParse(parts.first) ?? 9,
          minute: int.tryParse(parts.last) ?? 0,
        );
        final selected = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );
        if (selected == null) {
          return;
        }
        final next =
            '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
        onSelected(next);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD8E0EA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTypography.label(
                fontSize: 10.3,
                color: const Color(0xFF8DA0B9),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _displayHour(value),
                    style: AppTypography.card(
                      fontSize: 15,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: AppColors.mutedText,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NapIssuesSheet extends StatelessWidget {
  const _NapIssuesSheet({
    required this.citations,
    required this.napInfo,
    required this.onOpenExternal,
  });

  final List<CitationRecord> citations;
  final CitationNapInfo? napInfo;
  final Future<void> Function(String url) onOpenExternal;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(18, 18, 18, bottomInset + 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8E0EA),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'NAP inconsistencies',
              style: AppTypography.card(
                fontSize: 18,
                color: AppColors.brandBlue,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              citations.isEmpty
                  ? 'All active listings currently match your master NAP.'
                  : 'Compare the live listing details with your master NAP below.',
              style: AppTypography.body(
                fontSize: 12.6,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (citations.isEmpty)
                      const _EmptySectionState(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'All clear',
                        description:
                            'No active listings currently need manual NAP correction.',
                      )
                    else
                      ...citations.map(
                        (citation) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBFB),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFFFE1E1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        citation.directory,
                                        style: AppTypography.card(
                                          fontSize: 15,
                                          color: AppColors.brandBlue,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => onOpenExternal(
                                        (citation.directoryUrl ?? '')
                                                .trim()
                                                .isNotEmpty
                                            ? citation.directoryUrl!
                                            : citation.directory,
                                      ),
                                      icon: const Icon(
                                        Icons.open_in_new_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      label: Text(
                                        'Open',
                                        style: AppTypography.button(
                                          fontSize: 12.5,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if ((citation.foundName ?? '')
                                    .trim()
                                    .isNotEmpty)
                                  _DetectedInfoRow(
                                    title: 'Name',
                                    value: citation.foundName!,
                                  ),
                                if ((citation.foundAddress ?? '')
                                    .trim()
                                    .isNotEmpty)
                                  _DetectedInfoRow(
                                    title: 'Address',
                                    value: citation.foundAddress!,
                                  ),
                                if ((citation.foundPhone ?? '')
                                    .trim()
                                    .isNotEmpty)
                                  _DetectedInfoRow(
                                    title: 'Phone',
                                    value: citation.foundPhone!,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFBF4),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFCFEEDB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Master NAP',
                            style: AppTypography.label(
                              fontSize: 11.8,
                              color: const Color(0xFF1B9E5A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _DetectedInfoRow(
                            title: 'Name',
                            value: napInfo?.businessName ?? 'Not set',
                          ),
                          _DetectedInfoRow(
                            title: 'Address',
                            value: napInfo?.address ?? 'Not set',
                          ),
                          _DetectedInfoRow(
                            title: 'Phone',
                            value: napInfo?.phone ?? 'Not set',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

class _EmptyLocationsState extends StatelessWidget {
  const _EmptyLocationsState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _PanelCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8FA),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.location_city_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No business locations found',
                  textAlign: TextAlign.center,
                  style: AppTypography.card(
                    fontSize: 19,
                    color: AppColors.brandBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect or create a business location first so the citation manager can load real NAP data and tracked directories.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    fontSize: 13,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRefresh,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    'Refresh',
                    style: AppTypography.button(
                      fontSize: 13,
                      color: Colors.white,
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

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.child,
    this.backgroundColor = Colors.white,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EDF6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F2746),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.message,
    this.isError = false,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFF2F2) : const Color(0xFFEFFBF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isError ? const Color(0xFFFFD6D6) : const Color(0xFFCFEEDB),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            color: isError ? const Color(0xFFD64545) : const Color(0xFF1B9E5A),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(
                fontSize: 12.6,
                color: isError
                    ? const Color(0xFF9F2F2F)
                    : const Color(0xFF196F43),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(
              Icons.close_rounded,
              color: isError
                  ? const Color(0xFFD64545)
                  : const Color(0xFF1B9E5A),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreMetricCard extends StatelessWidget {
  const _ScoreMetricCard({
    required this.title,
    required this.score,
    required this.accentColor,
    required this.icon,
    required this.description,
    required this.footerLabel,
    required this.footerOutlined,
    required this.onFooterTap,
  });

  final String title;
  final int score;
  final Color accentColor;
  final IconData icon;
  final String description;
  final String footerLabel;
  final bool footerOutlined;
  final VoidCallback? onFooterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 170),
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandBlue.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 17),
              ),
              const Spacer(),
              _ScoreCircle(score: score, accentColor: accentColor),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.button(
              fontSize: 14,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body(
              fontSize: 11.2,
              color: const Color(0xFF617085),
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onFooterTap != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: footerOutlined
                  ? OutlinedButton(
                      onPressed: onFooterTap,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.brandBlue,
                        side: const BorderSide(
                          color: AppColors.brandBlue,
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        footerLabel,
                        style: AppTypography.button(
                          fontSize: 12.6,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : FilledButton(
                      onPressed: onFooterTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        footerLabel,
                        style: AppTypography.button(
                          fontSize: 12.6,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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

class _ScoreCircle extends StatelessWidget {
  const _ScoreCircle({required this.score, required this.accentColor});

  final int score;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final progress = (score.clamp(0, 100)) / 100;

    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: progress.toDouble(),
              strokeWidth: 4.5,
              backgroundColor: accentColor.withValues(alpha: 0.14),
              color: accentColor,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: AppTypography.card(
                  fontSize: 20,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '/100',
                style: AppTypography.label(
                  fontSize: 9.8,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCapsule extends StatelessWidget {
  const _QuickActionCapsule({
    required this.icon,
    required this.label,
    this.filled = true,
    this.expand = false,
    this.isLoading = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final bool expand;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final button = filled
        ? FilledButton.icon(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(icon, size: 16),
            label: Text(
              label,
              style: AppTypography.button(
                fontSize: 11.6,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        : OutlinedButton.icon(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandBlue,
              side: const BorderSide(color: AppColors.brandBlue, width: 1.1),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brandBlue,
                    ),
                  )
                : Icon(icon, size: 16),
            label: Text(
              label,
              style: AppTypography.button(
                fontSize: 11.6,
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          );

    if (!expand) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}

class _NapDetailTile extends StatelessWidget {
  const _NapDetailTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconBackground,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color iconBackground;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4EDF6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x090F2746),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.label(
                    fontSize: 10.8,
                    color: const Color(0xFF606F83),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? 'Not set' : value,
                  style: AppTypography.body(
                    fontSize: 13.1,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEFBFC) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFBDE7EA) : const Color(0xFFD8E0EA),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.label(
            fontSize: 11.2,
            color: selected ? AppColors.primary : AppColors.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _QueueBadge extends StatelessWidget {
  const _QueueBadge({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.label(
          fontSize: 11.5,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.label(
              fontSize: 11.5,
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 14, color: foreground),
          ],
        ],
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.label,
    this.icon,
    this.isLoading = false,
    this.isDestructive = false,
    this.customForeground,
    this.customBackground,
    this.borderColor,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final bool isDestructive;
  final Color? customForeground;
  final Color? customBackground;
  final Color? borderColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground =
        customForeground ??
        (isDestructive ? const Color(0xFFD64545) : AppColors.brandBlue);
    final background =
        customBackground ??
        (isDestructive ? const Color(0xFFFFF2F2) : const Color(0xFFF4F8FC));

    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: background,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: borderColor == null
              ? BorderSide.none
              : BorderSide(color: borderColor!),
        ),
      ),
      icon: isLoading
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foreground,
              ),
            )
          : Icon(icon, size: 16),
      label: Text(
        label,
        style: AppTypography.button(fontSize: 12.2, color: foreground),
      ),
    );
  }
}

class _InlineInfoBadge extends StatelessWidget {
  const _InlineInfoBadge({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: AppTypography.button(fontSize: 12.2, color: foreground),
      ),
    );
  }
}

class _DirectoryAvatar extends StatelessWidget {
  const _DirectoryAvatar({required this.directory});

  final String directory;

  @override
  Widget build(BuildContext context) {
    final label = _directoryMonogram(directory);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTypography.card(
          fontSize: 14,
          color: AppColors.brandBlue,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TinyChip extends StatelessWidget {
  const _TinyChip({
    required this.label,
    this.foreground = AppColors.mutedText,
    this.background = const Color(0xFFF3F5F8),
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.label(
          fontSize: 10.7,
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4EDF6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: AppTypography.label(
                fontSize: 11.2,
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.hintText,
    this.helperText,
    this.errorText,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.label(
              fontSize: 11.5,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            decoration: _inputDecoration(
              hintText: hintText,
              helperText: helperText,
              errorText: errorText,
              alignLabelWithHint: maxLines > 1,
            ),
            style: AppTypography.body(
              fontSize: 13,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectedInfoRow extends StatelessWidget {
  const _DetectedInfoRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            child: Text(
              '$title:',
              style: AppTypography.label(
                fontSize: 11.2,
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body(
                fontSize: 12.4,
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredLoadingMessage extends StatelessWidget {
  const _CenteredLoadingMessage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.body(
              fontSize: 12.6,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySectionState extends StatelessWidget {
  const _EmptySectionState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAF2FA)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.card(fontSize: 16, color: AppColors.brandBlue),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTypography.body(
              fontSize: 12.5,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({
  String? hintText,
  Widget? prefixIcon,
  String? helperText,
  String? errorText,
  bool alignLabelWithHint = false,
}) {
  return InputDecoration(
    hintText: hintText,
    helperText: helperText,
    errorText: errorText,
    alignLabelWithHint: alignLabelWithHint,
    hintStyle: AppTypography.body(
      fontSize: 12.8,
      color: const Color(0xFF90A0B2),
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: const Color(0xFFF8FBFF),
    prefixIcon: prefixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFD8E0EA)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFD8E0EA)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
    ),
  );
}

_StatusStyle _statusStyleFor(CitationStatus status) {
  switch (status) {
    case CitationStatus.todo:
      return const _StatusStyle(
        label: 'To-do',
        foreground: Color(0xFFB8700B),
        background: Color(0xFFFFF5E6),
      );
    case CitationStatus.processing:
      return const _StatusStyle(
        label: 'Processing',
        foreground: Color(0xFF2368D8),
        background: Color(0xFFEAF2FF),
      );
    case CitationStatus.active:
      return const _StatusStyle(
        label: 'Active',
        foreground: Color(0xFF1B9E5A),
        background: Color(0xFFE9F8EF),
      );
    case CitationStatus.lost:
      return const _StatusStyle(
        label: 'Lost',
        foreground: Color(0xFFD64545),
        background: Color(0xFFFFECEC),
      );
    case CitationStatus.ignored:
      return const _StatusStyle(
        label: 'Ignored',
        foreground: Color(0xFF617085),
        background: Color(0xFFF3F5F8),
      );
  }
}

_StatusStyle _verificationStyleFor(CitationVerificationStatus status) {
  switch (status) {
    case CitationVerificationStatus.activeVerified:
      return const _StatusStyle(
        label: 'Verified proof',
        foreground: Color(0xFF1B9E5A),
        background: Color(0xFFE9F8EF),
      );
    case CitationVerificationStatus.activeNeedsReview:
      return const _StatusStyle(
        label: 'Needs review',
        foreground: Color(0xFF2368D8),
        background: Color(0xFFEAF2FF),
      );
    case CitationVerificationStatus.napIssue:
      return const _StatusStyle(
        label: 'NAP issue',
        foreground: Color(0xFFD64545),
        background: Color(0xFFFFECEC),
      );
    case CitationVerificationStatus.notFoundConfirmed:
      return const _StatusStyle(
        label: 'Not found',
        foreground: Color(0xFF617085),
        background: Color(0xFFF3F5F8),
      );
    case CitationVerificationStatus.unableToVerify:
      return const _StatusStyle(
        label: 'Manual check needed',
        foreground: Color(0xFFB8700B),
        background: Color(0xFFFFF5E6),
      );
  }
}

String _formatDate(String? raw) {
  final normalized = (raw ?? '').trim();
  if (normalized.isEmpty) {
    return 'Updated recently';
  }

  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) {
    return normalized;
  }

  final local = parsed.toLocal();
  final month = _monthName(local.month);
  return 'Updated $month ${local.day}, ${local.year}';
}

String _monthName(int month) {
  const names = <String>[
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
  if (month < 1 || month > 12) {
    return '';
  }
  return names[month - 1];
}

String _directoryMonogram(String directory) {
  final normalized = directory.trim().toLowerCase();
  if (normalized.contains('google')) {
    return 'G';
  }
  if (normalized.contains('facebook')) {
    return 'f';
  }
  if (normalized.contains('yelp')) {
    return 'Y';
  }
  if (normalized.contains('instagram')) {
    return 'I';
  }
  if (normalized.contains('twitter') || normalized.contains('x.com')) {
    return 'X';
  }
  if (normalized.contains('justdial')) {
    return 'J';
  }
  if (normalized.contains('indiamart')) {
    return 'IM';
  }
  if (normalized.contains('sulekha')) {
    return 'S';
  }
  if (normalized.isEmpty) {
    return '?';
  }
  return normalized
      .substring(0, normalized.length > 1 ? 1 : normalized.length)
      .toUpperCase();
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;
}

abstract final class _CitationPalette {
  static const canvas = Color(0xFFF3F7FC);
}
