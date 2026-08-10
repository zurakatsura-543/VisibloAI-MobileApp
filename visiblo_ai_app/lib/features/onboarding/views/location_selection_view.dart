import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_logo.dart';
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
  final TextEditingController _searchController = TextEditingController();

  String get _searchQuery => _searchController.text.trim().toLowerCase();

  List<GoogleBusinessLocation> _filteredLocations(
    List<GoogleBusinessLocation> locations,
  ) {
    final query = _searchQuery;
    if (query.isEmpty) {
      return locations;
    }

    return locations.where((location) {
      final haystack = <String>[
        location.title,
        location.primaryCategory,
        location.conciseAddress,
        location.formattedAddress,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);
  }

  Future<void> _openAddBusinessLink() async {
    final uri = Uri.parse('https://www.visibloai.com');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _changeConnectedEmail() {
    Get.offAllNamed(AppRoutes.signUp);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadAvailableGoogleLocations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Obx(
          () {
            final isGoogleConnected =
                _controller.currentUser.value?.googleBusinessProfileConnected ??
                false;
            final allLocations = _controller.availableGoogleLocations.toList(
              growable: false,
            );
            final filteredLocations = _filteredLocations(allLocations);
            final hasLocations = allLocations.isNotEmpty;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 40,
                          height: 40,
                        ),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.text,
                        ),
                      ),
                      const Spacer(),
                      const AppLogo(iconSize: 42, centered: true),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Select Business',
                    style: GoogleFonts.manrope(
                      fontSize: 30,
                      height: 1.08,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Choose the business or location for which you want to create and manage social media posts.',
                    style: GoogleFonts.manrope(
                      fontSize: 15.5,
                      height: 1.42,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _SearchBusinessField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 126,
                        child: _AddNewButton(
                          onPressed: _openAddBusinessLink,
                        ),
                      ),
                    ],
                  ),
                  if (_controller.locationQuota.value != null) ...[
                    const SizedBox(height: 14),
                    _QuotaChip(quota: _controller.locationQuota.value!),
                  ],
                  const SizedBox(height: 18),
                  if (_controller.isLocationsLoading.value)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 42),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (!isGoogleConnected || !hasLocations)
                    _EmptyBusinessState(
                      onAddBusiness: _openAddBusinessLink,
                      onChangeEmail: _changeConnectedEmail,
                    )
                  else ...[
                    if (filteredLocations.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: _NoSearchResultsState(),
                      )
                    else
                      ...filteredLocations.map((location) {
                      final isSelected =
                          _controller.selectedGoogleLocationId.value ==
                          location.gmbLocationId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _BusinessLocationCard(
                          location: location,
                          isSelected: isSelected,
                          onTap: () => _controller.selectGoogleLocation(location),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    const _ManageMultipleBusinessesCard(),
                  ],
                  const SizedBox(height: 22),
                  AppPrimaryButton(
                    label: 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    isLoading: _controller.isLocationActivationLoading.value,
                    backgroundColor: AppColors.brandBlue,
                    onPressed: hasLocations
                        ? _controller.activateSelectedGoogleLocation
                        : () {},
                    disabledBackgroundColor: const Color(0xFFD6DCE8),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SearchBusinessField extends StatelessWidget {
  const _SearchBusinessField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE6F2)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.manrope(
          fontSize: 14.5,
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          hintText: 'Search business or location',
          hintStyle: GoogleFonts.manrope(
            fontSize: 14.5,
            color: const Color(0xFF99A3B6),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF99A3B6),
            size: 22,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 42,
            minHeight: 22,
          ),
        ),
      ),
    );
  }
}

class _AddNewButton extends StatelessWidget {
  const _AddNewButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Add New'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.manrope(
          fontSize: 15,
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BusinessLocationCard extends StatelessWidget {
  const _BusinessLocationCard({
    required this.location,
    required this.isSelected,
    required this.onTap,
  });

  final GoogleBusinessLocation location;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chipLabel = location.primaryCategory.isNotEmpty
        ? location.primaryCategory
        : 'Business Profile';
    final displayAddress = location.conciseAddress.isNotEmpty
        ? location.conciseAddress
        : location.formattedAddress;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE3EAF3),
              width: isSelected ? 1.4 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B144C86),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                alignment: Alignment.center,
                child: _BusinessLogoBadge(location: location),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 18.2,
                        height: 1.16,
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    if (displayAddress.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: Color(0xFF909CB0),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              displayAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 13.5,
                                color: AppColors.mutedText,
                                height: 1.2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF5FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        chipLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFC3CDDB),
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessLogoBadge extends StatelessWidget {
  const _BusinessLogoBadge({required this.location});

  final GoogleBusinessLocation location;

  @override
  Widget build(BuildContext context) {
    final logoUrl = location.logoUrl.trim();
    final isAimbeat = location.title.toLowerCase().contains('aimbeat');
    if (logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          color: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.all(isAimbeat ? 5.5 : 0),
            child: Image.network(
              logoUrl,
              width: 44,
              height: 44,
              fit: isAimbeat ? BoxFit.contain : BoxFit.cover,
              errorBuilder: (_, _, _) => _buildFallback(),
            ),
          ),
        ),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF245BEB), Color(0xFF39B4BD)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        location.title.isNotEmpty
            ? location.title.trim().characters.first.toUpperCase()
            : 'B',
        style: GoogleFonts.manrope(
          fontSize: 21,
          color: AppColors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NoSearchResultsState extends StatelessWidget {
  const _NoSearchResultsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No businesses match your search.',
        textAlign: TextAlign.center,
        style: GoogleFonts.manrope(
          fontSize: 14.5,
          color: AppColors.mutedText,
          fontWeight: FontWeight.w600,
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
        style: GoogleFonts.manrope(
          fontSize: 12.6,
          color: AppColors.brandBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyBusinessState extends StatelessWidget {
  const _EmptyBusinessState({
    required this.onAddBusiness,
    required this.onChangeEmail,
  });

  final VoidCallback onAddBusiness;
  final VoidCallback onChangeEmail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C144C86),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEFF6FF), Color(0xFFF8FDFF)],
              ),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/gmb.png',
              width: 92,
              height: 92,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'No Google Business Profile Connected',
            textAlign: TextAlign.center,
            style: AppTypography.button(
              fontSize: 18,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'This email address is not currently linked to any Google Business Profile.',
            textAlign: TextAlign.center,
            style: AppTypography.body(
              fontSize: 15,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Please take one of the following actions:',
            textAlign: TextAlign.center,
            style: AppTypography.body(
              fontSize: 15,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onAddBusiness,
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('Add Your Business'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: AppTypography.button(
                fontSize: 16,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppPrimaryButton(
            label: 'Change Connected Email',
            icon: Icons.email_outlined,
            onPressed: onChangeEmail,
            backgroundColor: AppColors.brandBlue,
          ),
        ],
      ),
    );
  }
}

class _ManageMultipleBusinessesCard extends StatelessWidget {
  const _ManageMultipleBusinessesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7FBFF), Color(0xFFF4F8FF)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F5FF),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.business_center_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Multiple Businesses',
                  style: GoogleFonts.manrope(
                    fontSize: 17,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'You can switch between businesses anytime and create content specific to each location.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.mutedText,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
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
