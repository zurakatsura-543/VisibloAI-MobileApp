import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../controllers/gbp_manager_controller.dart';
import '../models/gbp_manager_models.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_navigation_shell.dart';

class GbpManagerView extends GetView<GbpManagerController> {
  const GbpManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthNavigationShell(
      currentTab: AuthTab.home,
      backgroundColor: _GbpPalette.canvas,
      child: Obx(() {
        if (controller.isLoading.value) {
          return const _LoadingState();
        }

        final locations = controller.locations.toList(growable: false);
        final hasLocations = locations.isNotEmpty;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.refreshLocations,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AuthViewSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderBar(
                  isRefreshing: controller.isRefreshing.value,
                  onBack: _handleBackTap,
                  onRefresh: controller.refreshLocations,
                ),
                const SizedBox(height: AuthViewSpacing.sectionGap),
                _HeroCard(
                  totalLocations: controller.totalLocations,
                  averageRating: controller.averageRatingLabel,
                  totalReviews: controller.totalReviews,
                ),
                if (controller.hasQuotaData) ...[
                  const SizedBox(height: AuthViewSpacing.cardGap),
                  _QuotaSummaryCard(controller: controller),
                ],
                if (controller.errorMessage.value != null) ...[
                  const SizedBox(height: AuthViewSpacing.cardGap),
                  _InlineBanner(
                    title: 'Something needs attention',
                    message: controller.errorMessage.value!,
                    accent: const Color(0xFFD64545),
                    background: const Color(0xFFFFF1F1),
                    icon: Icons.error_outline_rounded,
                    onDismiss: controller.clearError,
                  ),
                ],
                if (controller.infoMessage.value != null) ...[
                  const SizedBox(height: AuthViewSpacing.cardGap),
                  _InlineBanner(
                    title: 'GBP Manager',
                    message: controller.infoMessage.value!,
                    accent: const Color(0xFF188B63),
                    background: const Color(0xFFEFFBF5),
                    icon: Icons.info_outline_rounded,
                    onDismiss: controller.clearInfo,
                  ),
                ],
                const SizedBox(height: AuthViewSpacing.cardGap),
                _VerificationBanner(
                  verifiedLocations: controller.verifiedLocations,
                  totalLocations: controller.totalLocations,
                  onFixNow: hasLocations
                      ? () {
                          GbpManagerLocation? pendingLocation;
                          for (final location in locations) {
                            if (!location.isVerified) {
                              pendingLocation = location;
                              break;
                            }
                          }
                          if (pendingLocation != null) {
                            controller.verifyLocation(pendingLocation.id);
                          }
                        }
                      : null,
                ),
                const SizedBox(height: AuthViewSpacing.sectionGap),
                const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AuthViewSpacing.cardGap),
                Row(
                  children: [
                    Expanded(
                      child: _GbpMetricCard(
                        icon: Icons.location_on_outlined,
                        iconColor: const Color(0xFF416EE2),
                        iconBackground: const Color(0xFFEFF2FF),
                        label: 'Total Locations',
                        value: '${controller.totalLocations}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _GbpMetricCard(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFF59D2A),
                        iconBackground: const Color(0xFFFFF2E6),
                        label: 'Avg Rating',
                        value: controller.averageRatingLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AuthViewSpacing.cardGap),
                Row(
                  children: [
                    Expanded(
                      child: _GbpMetricCard(
                        icon: Icons.trending_up_rounded,
                        iconColor: const Color(0xFFE66355),
                        iconBackground: const Color(0xFFFFEEEC),
                        label: 'Total Reviews',
                        value: '${controller.totalReviews}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _GbpMetricCard(
                        icon: Icons.verified_outlined,
                        iconColor: const Color(0xFF41A85F),
                        iconBackground: const Color(0xFFEAF7ED),
                        label: 'Verified',
                        value:
                            '${controller.verifiedLocations}/${controller.totalLocations}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AuthViewSpacing.sectionGap),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Your Locations',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: controller.canAddLocation
                          ? _showAddLocationSheet
                          : null,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.brandBlue,
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.add_business_rounded, size: 18),
                      label: const Text(
                        'Add Location',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AuthViewSpacing.cardGap),
                if (!hasLocations)
                  _EmptyLocationsCard(
                    onAddLocation: controller.canAddLocation
                        ? _showAddLocationSheet
                        : null,
                  )
                else
                  Column(
                    children: locations
                        .map(
                          (location) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AuthViewSpacing.cardGap,
                            ),
                            child: _LocationCard(
                              location: location,
                              isVerifying:
                                  controller.verifyingLocationId.value ==
                                  location.id,
                              isSyncing:
                                  controller.syncingLocationId.value ==
                                  location.id,
                              isDeleting:
                                  controller.deletingLocationId.value ==
                                  location.id,
                              onVerify: () =>
                                  controller.verifyLocation(location.id),
                              onSyncReviews: () =>
                                  controller.syncReviews(location.id),
                              onManageProfile: () =>
                                  Get.toNamed(AppRoutes.audit),
                              onOpenMaps: () => _openGoogleMaps(location),
                              onVisitWebsite: location.websiteUrl.isEmpty
                                  ? null
                                  : () => _openUrl(location.websiteUrl),
                              onDelete: location.isManual
                                  ? () => _confirmDelete(location)
                                  : null,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _handleBackTap() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
      return;
    }
    Get.offNamed(AppRoutes.dashboard);
  }

  Future<void> _showAddLocationSheet() async {
    if (!controller.canAddLocation) {
      _showSnack(
        title: 'Location quota reached',
        message:
            'All location slots are used. Upgrade or free a slot before adding another location.',
        accent: const Color(0xFFD64545),
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    var countryCode = '+91';

    await Get.bottomSheet<void>(
      StatefulBuilder(
        builder: (context, setSheetState) {
          final phoneLength = phoneController.text.trim().length;
          final isPhoneValid = phoneLength == 0 || phoneLength == 10;

          return SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Obx(() {
                final isSubmitting = controller.isSubmittingLocation.value;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD8E2EE),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Add New Location',
                        style: AppTypography.section(
                          fontSize: 22,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter the business details to create a manual GBP location like the customer dashboard flow.',
                        style: AppTypography.body(
                          fontSize: 12.8,
                          color: AppColors.mutedText,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SheetField(
                        controller: nameController,
                        label: 'Business Name*',
                        hint: 'e.g. Aimbeat Web Services',
                        icon: Icons.storefront_rounded,
                      ),
                      const SizedBox(height: 14),
                      _SheetField(
                        controller: addressController,
                        label: 'Address*',
                        hint: 'e.g. 706/A, HDIL Premier...',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Phone Number (Optional)',
                        style: AppTypography.label(
                          fontSize: 12.3,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 96,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: _sheetDropdownDecoration(),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: countryCode,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                    value: '+91',
                                    child: Text('IN +91'),
                                  ),
                                  DropdownMenuItem(
                                    value: '+1',
                                    child: Text('US +1'),
                                  ),
                                  DropdownMenuItem(
                                    value: '+44',
                                    child: Text('UK +44'),
                                  ),
                                  DropdownMenuItem(
                                    value: '+61',
                                    child: Text('AU +61'),
                                  ),
                                  DropdownMenuItem(
                                    value: '+971',
                                    child: Text('AE +971'),
                                  ),
                                ],
                                onChanged: isSubmitting
                                    ? null
                                    : (value) {
                                        if (value == null) {
                                          return;
                                        }
                                        setSheetState(() {
                                          countryCode = value;
                                        });
                                      },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: phoneController,
                              enabled: !isSubmitting,
                              keyboardType: TextInputType.phone,
                              onChanged: (value) {
                                final digits = value.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                );
                                if (digits != value) {
                                  phoneController.value = TextEditingValue(
                                    text: digits,
                                    selection: TextSelection.collapsed(
                                      offset: digits.length,
                                    ),
                                  );
                                }
                                setSheetState(() {});
                              },
                              decoration: _sheetInputDecoration(
                                hint: '9870066177',
                                icon: Icons.call_outlined,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isPhoneValid) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Phone number must be exactly 10 digits.',
                          style: AppTypography.body(
                            fontSize: 11.4,
                            color: const Color(0xFFD64545),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting ? null : Get.back,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.brandBlue,
                                side: const BorderSide(
                                  color: Color(0xFFD9E2EE),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  isSubmitting ||
                                      nameController.text.trim().isEmpty ||
                                      addressController.text.trim().isEmpty ||
                                      !isPhoneValid
                                  ? null
                                  : () async {
                                      final formattedPhone =
                                          phoneController.text.trim().isEmpty
                                          ? ''
                                          : '$countryCode ${phoneController.text.trim()}';
                                      try {
                                        await controller.addLocation(
                                          name: nameController.text,
                                          addressLine1: addressController.text,
                                          phone: formattedPhone,
                                        );
                                        if (context.mounted) {
                                          Get.back<void>();
                                        }
                                      } catch (_) {
                                        // Controller already surfaces the error.
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: AppColors.brandBlue,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              icon: isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.add_business_rounded,
                                      size: 18,
                                    ),
                              label: Text(
                                isSubmitting ? 'Adding...' : 'Add Location',
                                style: AppTypography.button(
                                  fontSize: 13,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );

    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
  }

  Future<void> _confirmDelete(GbpManagerLocation location) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete location?'),
        content: Text(
          'Delete "${location.name}"? This only applies to manually added locations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFD64545)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.deleteLocation(location.id);
    }
  }

  Future<void> _openGoogleMaps(GbpManagerLocation location) async {
    final query = Uri.encodeComponent('${location.name} ${location.address}');
    final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$query';
    await _openUrl(mapsUrl);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      _showSnack(
        title: 'Invalid link',
        message: 'This link could not be opened.',
        accent: const Color(0xFFD64545),
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      _showSnack(
        title: 'Could not open link',
        message: 'The external app could not open this link right now.',
        accent: const Color(0xFFD64545),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  void _showSnack({
    required String title,
    required String message,
    required Color accent,
    required IconData icon,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.white,
      colorText: AppColors.text,
      borderRadius: 12,
      margin: const EdgeInsets.all(12),
      borderWidth: 1,
      borderColor: accent.withValues(alpha: 0.18),
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 17, color: accent),
      ),
      duration: const Duration(seconds: 2),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.isRefreshing,
    required this.onBack,
    required this.onRefresh,
  });

  final bool isRefreshing;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onBack,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: AppColors.brandBlue,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Color(0xFFF2F5F9),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_on_outlined,
            size: 16,
            color: AppColors.brandBlue,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'VisibloAI',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.brandBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: isRefreshing ? null : onRefresh,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.1,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Loading your live GBP manager...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.totalLocations,
    required this.averageRating,
    required this.totalReviews,
  });

  final int totalLocations;
  final String averageRating;
  final int totalReviews;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF22558C), Color(0xFF39C2C6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2233A9BD),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GBP Manager',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage your Google Business Profile locations with live backend data synced from the dashboard APIs.',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFFE8F9FC),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroInfoChip(
                label:
                    '$totalLocations Total Location${totalLocations == 1 ? '' : 's'}',
              ),
              _HeroInfoChip(label: '$averageRating Avg Rating'),
              _HeroInfoChip(label: '$totalReviews Reviews'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroInfoChip extends StatelessWidget {
  const _HeroInfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x25FFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _QuotaSummaryCard extends StatelessWidget {
  const _QuotaSummaryCard({required this.controller});

  final GbpManagerController controller;

  @override
  Widget build(BuildContext context) {
    final exhausted = !controller.canAddLocation;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: exhausted ? const Color(0xFFFFF5F5) : const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: exhausted ? const Color(0xFFFFD7D7) : const Color(0xFFDCEAF8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: exhausted
                      ? const Color(0xFFFFE8E8)
                      : const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  exhausted
                      ? Icons.lock_outline_rounded
                      : Icons.space_dashboard_rounded,
                  size: 18,
                  color: exhausted
                      ? const Color(0xFFD64545)
                      : AppColors.brandBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exhausted ? 'Location quota used up' : 'Location quota',
                      style: const TextStyle(
                        fontSize: 14.2,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      exhausted
                          ? 'Manual add is disabled until a slot becomes available.'
                          : 'Backend-enforced slot usage for this workspace.',
                      style: const TextStyle(
                        fontSize: 12.2,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _QuotaMetricTile(
                  label: 'Used',
                  value: controller.quotaUsedLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuotaMetricTile(
                  label: 'Max',
                  value: controller.quotaMaxLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuotaMetricTile(
                  label: 'Remaining',
                  value: controller.quotaRemainingLabel,
                  valueColor: exhausted
                      ? const Color(0xFFD64545)
                      : const Color(0xFF188B63),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuotaMetricTile extends StatelessWidget {
  const _QuotaMetricTile({
    required this.label,
    required this.value,
    this.valueColor = AppColors.brandBlue,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E8F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.2,
              color: AppColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              height: 1,
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationBanner extends StatelessWidget {
  const _VerificationBanner({
    required this.verifiedLocations,
    required this.totalLocations,
    required this.onFixNow,
  });

  final int verifiedLocations;
  final int totalLocations;
  final VoidCallback? onFixNow;

  @override
  Widget build(BuildContext context) {
    final pendingCount = totalLocations - verifiedLocations;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: _gbpCardDecoration(),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF2E8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFF58220),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pendingCount > 0 ? 'Verification pending' : 'All set',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pendingCount > 0
                      ? '$verifiedLocations/$totalLocations locations verified. Complete verification to unlock trust.'
                      : 'All locations are verified and ready to manage.',
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
          const SizedBox(width: 10),
          SizedBox(
            height: 38,
            child: OutlinedButton(
              onPressed: pendingCount > 0 ? onFixNow : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                pendingCount > 0 ? 'Fix now' : 'Verified',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GbpMetricCard extends StatelessWidget {
  const _GbpMetricCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _gbpCardDecoration(),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
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

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.isVerifying,
    required this.isSyncing,
    required this.isDeleting,
    required this.onVerify,
    required this.onSyncReviews,
    required this.onManageProfile,
    required this.onOpenMaps,
    this.onVisitWebsite,
    this.onDelete,
  });

  final GbpManagerLocation location;
  final bool isVerifying;
  final bool isSyncing;
  final bool isDeleting;
  final VoidCallback onVerify;
  final VoidCallback onSyncReviews;
  final VoidCallback onManageProfile;
  final VoidCallback onOpenMaps;
  final VoidCallback? onVisitWebsite;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final badge = _statusBadgeFor(location.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: _gbpCardDecoration(),
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
                  color: const Color(0xFFE7FBFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      location.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _LocationBadge(config: badge),
            ],
          ),
          const SizedBox(height: 12),
          _WorkspaceInfoRow(
            icon: Icons.location_on_outlined,
            text: location.address.isEmpty
                ? 'Address not available'
                : location.address,
          ),
          const SizedBox(height: 10),
          _WorkspaceInfoRow(
            icon: Icons.call_rounded,
            text: location.phone.isEmpty
                ? 'Phone not available'
                : location.phone,
          ),
          if (location.websiteUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            _WorkspaceInfoRow(
              icon: Icons.language_rounded,
              text: location.websiteUrl,
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EDF3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _WorkspaceMetric(
                    value: location.rating.toStringAsFixed(1),
                    label: 'Rating',
                  ),
                ),
                const _WorkspaceDivider(),
                Expanded(
                  child: _WorkspaceMetric(
                    value: '${location.reviews}',
                    label: 'Reviews',
                  ),
                ),
                const _WorkspaceDivider(),
                Expanded(
                  child: _WorkspaceMetric(
                    value: '${location.completeness}%',
                    label: 'Complete',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionChip(
                icon: isSyncing ? Icons.sync_rounded : Icons.refresh_rounded,
                label: isSyncing ? 'Syncing...' : 'Sync Reviews',
                color: AppColors.brandBlue,
                background: const Color(0xFFEAF2FF),
                onTap: isSyncing || isVerifying || isDeleting
                    ? null
                    : onSyncReviews,
                spinning: isSyncing,
              ),
              if (!location.isVerified)
                _ActionChip(
                  icon: isVerifying
                      ? Icons.verified_rounded
                      : Icons.shield_outlined,
                  label: isVerifying ? 'Verifying...' : 'Verify',
                  color: const Color(0xFF1B9E5A),
                  background: const Color(0xFFEAF7ED),
                  onTap: isSyncing || isVerifying || isDeleting
                      ? null
                      : onVerify,
                  spinning: isVerifying,
                ),
              _ActionChip(
                icon: Icons.map_outlined,
                label: 'Google Maps',
                color: AppColors.primary,
                background: const Color(0xFFEAF9FB),
                onTap: isSyncing || isVerifying || isDeleting
                    ? null
                    : onOpenMaps,
              ),
              if (onVisitWebsite != null)
                _ActionChip(
                  icon: Icons.open_in_new_rounded,
                  label: 'Visit Website',
                  color: const Color(0xFF6C7DE2),
                  background: const Color(0xFFF0F2FF),
                  onTap: isSyncing || isVerifying || isDeleting
                      ? null
                      : onVisitWebsite,
                ),
              if (onDelete != null)
                _ActionChip(
                  icon: isDeleting
                      ? Icons.delete_forever_rounded
                      : Icons.delete_outline_rounded,
                  label: isDeleting ? 'Deleting...' : 'Delete',
                  color: const Color(0xFFD64545),
                  background: const Color(0xFFFFECEC),
                  onTap: isSyncing || isVerifying || isDeleting
                      ? null
                      : onDelete,
                  spinning: isDeleting,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: location.isVerified
                        ? onManageProfile
                        : (isVerifying || isSyncing || isDeleting
                              ? null
                              : onVerify),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: location.isVerified
                          ? AppColors.white
                          : AppColors.primary,
                      foregroundColor: location.isVerified
                          ? AppColors.brandBlue
                          : AppColors.white,
                      side: location.isVerified
                          ? const BorderSide(color: Color(0xFFD9E2EE))
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      location.isVerified
                          ? 'Manage Profile'
                          : (isVerifying ? 'Verifying...' : 'Verify Now'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 46,
                height: 46,
                child: OutlinedButton(
                  onPressed: isVerifying || isSyncing || isDeleting
                      ? null
                      : onOpenMaps,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandBlue,
                    side: const BorderSide(color: Color(0xFFD9E2EE)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.open_in_new_rounded, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label(
            fontSize: 12.3,
            color: AppColors.brandBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: _sheetInputDecoration(hint: hint, icon: icon),
        ),
      ],
    );
  }
}

class _EmptyLocationsCard extends StatelessWidget {
  const _EmptyLocationsCard({required this.onAddLocation});

  final VoidCallback? onAddLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE6F1)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.location_off_outlined,
            size: 42,
            color: AppColors.mutedText,
          ),
          const SizedBox(height: 12),
          Text(
            'No locations found',
            style: AppTypography.section(
              fontSize: 18,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have not added any Google Business Profile locations yet. Add one manually or continue onboarding.',
            textAlign: TextAlign.center,
            style: AppTypography.body(
              fontSize: 12.8,
              color: AppColors.mutedText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.toNamed(AppRoutes.locationSelection),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandBlue,
                    side: const BorderSide(color: Color(0xFFD9E2EE)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text(
                    'Onboarding',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAddLocation,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text(
                    'Add Location',
                    style: TextStyle(fontWeight: FontWeight.w700),
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

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({
    required this.title,
    required this.message,
    required this.accent,
    required this.background,
    required this.icon,
    required this.onDismiss,
  });

  final String title;
  final String message;
  final Color accent;
  final Color background;
  final IconData icon;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.button(
                    fontSize: 13.5,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTypography.body(
                    fontSize: 12.4,
                    color: AppColors.mutedText,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationBadge extends StatelessWidget {
  const _LocationBadge({required this.config});

  final _LocationStatusBadgeConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: 10.6,
          color: config.foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WorkspaceInfoRow extends StatelessWidget {
  const _WorkspaceInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.brandBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceMetric extends StatelessWidget {
  const _WorkspaceMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            height: 1,
            color: AppColors.brandBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.8,
            color: AppColors.mutedText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WorkspaceDivider extends StatelessWidget {
  const _WorkspaceDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 38, color: const Color(0xFFE1E7EE));
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
    this.spinning = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback? onTap;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: onTap == null ? 0.48 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              spinning
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: color,
                      ),
                    )
                  : Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.2,
                  color: color,
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

class _LocationStatusBadgeConfig {
  const _LocationStatusBadgeConfig({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;
}

_LocationStatusBadgeConfig _statusBadgeFor(GbpManagerLocationStatus status) {
  switch (status) {
    case GbpManagerLocationStatus.verified:
      return const _LocationStatusBadgeConfig(
        label: 'VERIFIED',
        foreground: Color(0xFF1B9E5A),
        background: Color(0xFFE9F8EF),
      );
    case GbpManagerLocationStatus.pending:
      return const _LocationStatusBadgeConfig(
        label: 'PENDING',
        foreground: Color(0xFFF58220),
        background: Color(0xFFFFF2E7),
      );
    case GbpManagerLocationStatus.issues:
      return const _LocationStatusBadgeConfig(
        label: 'ACTION NEEDED',
        foreground: Color(0xFFD64545),
        background: Color(0xFFFFECEC),
      );
  }
}

InputDecoration _sheetInputDecoration({String? hint, IconData? icon}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon, size: 18),
    filled: true,
    fillColor: const Color(0xFFF9FBFD),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE0E8F1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE0E8F1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
  );
}

BoxDecoration _sheetDropdownDecoration() {
  return BoxDecoration(
    color: const Color(0xFFF9FBFD),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFE0E8F1)),
  );
}

BoxDecoration _gbpCardDecoration() {
  return BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFDCE6F1)),
    boxShadow: const [
      BoxShadow(color: Color(0x120F2746), blurRadius: 18, offset: Offset(0, 7)),
    ],
  );
}

abstract final class _GbpPalette {
  static const canvas = Color(0xFFF4F7FB);
}
