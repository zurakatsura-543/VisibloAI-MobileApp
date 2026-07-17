import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_primary_button.dart';
import '../controllers/onboarding_controller.dart';
import '../models/google_business_location.dart';

class LocationSelectionView extends StatefulWidget {
  const LocationSelectionView({super.key});

  @override
  State<LocationSelectionView> createState() => _LocationSelectionViewState();
}

class _LocationSelectionViewState extends State<LocationSelectionView> {
  final OnboardingController _controller = Get.find<OnboardingController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadAvailableGoogleLocations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(
          () => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose the Google\nlocation to activate',
                  style: AppTypography.section(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pick the Business Profile location you want to connect to this account.',
                  style: AppTypography.body(color: AppColors.mutedText),
                ),
                if (_controller.locationQuota.value != null) ...[
                  const SizedBox(height: 14),
                  _QuotaChip(quota: _controller.locationQuota.value!),
                ],
                const SizedBox(height: 20),
                if (_controller.isLocationsLoading.value)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (_controller.availableGoogleLocations.isEmpty)
                  _EmptyLocationsCard(
                    onReload: _controller.loadAvailableGoogleLocations,
                  )
                else
                  ..._controller.availableGoogleLocations.map((location) {
                    final isSelected =
                        _controller.selectedGoogleLocationId.value ==
                        location.gmbLocationId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _LocationCard(
                        location: location,
                        isSelected: isSelected,
                        onTap: () => _controller.selectGoogleLocation(location),
                      ),
                    );
                  }),
                const SizedBox(height: 18),
                AppPrimaryButton(
                  label: 'Activate Location',
                  isLoading: _controller.isLocationActivationLoading.value,
                  onPressed: _controller.activateSelectedGoogleLocation,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.isSelected,
    required this.onTap,
  });

  final GoogleBusinessLocation location;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    location.title,
                    style: AppTypography.button(
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFB6C1CF),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              location.primaryCategory,
              style: AppTypography.label(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (location.formattedAddress.isNotEmpty)
              Text(
                location.formattedAddress,
                style: AppTypography.body(
                  color: AppColors.mutedText,
                  height: 1.4,
                ),
              ),
            if (location.primaryPhone.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                location.primaryPhone,
                style: AppTypography.body(color: AppColors.text),
              ),
            ],
            if (location.websiteUrl.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                location.websiteUrl,
                style: AppTypography.label(
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuotaChip extends StatelessWidget {
  const _QuotaChip({required this.quota});

  final Map<String, dynamic> quota;

  @override
  Widget build(BuildContext context) {
    final used = quota['used']?.toString() ?? '0';
    final max = quota['max']?.toString() ?? '0';
    final remaining = quota['remaining']?.toString() ?? '0';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Used $used / $max locations • $remaining remaining',
        style: AppTypography.label(
          color: AppColors.brandBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyLocationsCard extends StatelessWidget {
  const _EmptyLocationsCard({required this.onReload});

  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.storefront_outlined,
            color: AppColors.primary,
            size: 26,
          ),
          const SizedBox(height: 12),
          Text(
            'No Google locations found yet.',
            style: AppTypography.button(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Make sure Google Business Profile is connected, then reload.',
            textAlign: TextAlign.center,
            style: AppTypography.body(color: AppColors.mutedText),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onReload,
            child: const Text('Reload locations'),
          ),
        ],
      ),
    );
  }
}
