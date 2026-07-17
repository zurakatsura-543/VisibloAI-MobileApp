import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/test_account.dart';

class AccountBusinessProfileDetailView extends StatefulWidget {
  const AccountBusinessProfileDetailView({super.key});

  @override
  State<AccountBusinessProfileDetailView> createState() =>
      _AccountBusinessProfileDetailViewState();
}

class _AccountBusinessProfileDetailViewState
    extends State<AccountBusinessProfileDetailView> {
  final OnboardingController _controller = Get.find<OnboardingController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _businessNameController;
  late final TextEditingController _industryController;
  late final TextEditingController _phoneController;
  late final TextEditingController _websiteController;
  late final TextEditingController _addressController;
  bool _didPrefill = false;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _industryController = TextEditingController();
    _phoneController = TextEditingController();
    _websiteController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _industryController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = _controller.currentUser.value;
      if (user == null) {
        return const Scaffold(
          backgroundColor: _AccountScene.canvas,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      _prefill(user);

      return Scaffold(
        backgroundColor: _AccountScene.canvas,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _AccountBackButton(),
                  const SizedBox(height: 26),
                  _AccountSurfaceCard(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF3FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.apartment_rounded,
                            color: AppColors.primary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BUSINESS PROFILE',
                                style: AppTypography.label(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Brand identity',
                                style: AppTypography.card(
                                  fontSize: 18,
                                  color: const Color(0xFF173A69),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'These details power your dashboard identity and business context.',
                                style: AppTypography.body(
                                  fontSize: 14,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AccountSurfaceCard(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: 'Business name',
                          controller: _businessNameController,
                          validator: (value) => _controller.validateRequired(
                            value,
                            fieldName: 'Business name',
                          ),
                          textStyle: AppTypography.body(
                            fontSize: 14,
                            color: const Color(0xFF1C4B87),
                          ),
                        ),
                        const SizedBox(height: 18),
                        AppTextField(
                          label: 'Industry',
                          controller: _industryController,
                          validator: (value) => _controller.validateRequired(
                            value,
                            fieldName: 'Industry',
                          ),
                          hintText:
                              'e.g. Salon, software, clothing manufacturer',
                          textStyle: AppTypography.body(
                            fontSize: 14,
                            color: const Color(0xFF1C4B87),
                          ),
                          hintStyle: AppTypography.body(
                            fontSize: 14,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 18),
                        AppTextField(
                          label: 'Phone',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textStyle: AppTypography.body(
                            fontSize: 14,
                            color: const Color(0xFF1C4B87),
                          ),
                        ),
                        const SizedBox(height: 18),
                        AppTextField(
                          label: 'Website',
                          controller: _websiteController,
                          keyboardType: TextInputType.url,
                          validator: _validateWebsite,
                          textStyle: AppTypography.body(
                            fontSize: 14,
                            color: const Color(0xFF1C4B87),
                          ),
                        ),
                        const SizedBox(height: 18),
                        AppTextField(
                          label: 'Address',
                          controller: _addressController,
                          textStyle: AppTypography.body(
                            fontSize: 14,
                            color: const Color(0xFF1C4B87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _AccountPrimaryButton(
                    label: 'Save Business Profile',
                    icon: Icons.bookmark_border_rounded,
                    onPressed: () => _saveProfile(user),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  void _prefill(TestAccount user) {
    if (_didPrefill) {
      return;
    }

    _businessNameController.text = user.businessName.trim().isEmpty
        ? 'Web Aimbeat'
        : user.businessName;
    _industryController.text = user.industry.trim();
    _phoneController.text = user.phoneNumber.trim().isEmpty
        ? '099304 21939'
        : user.phoneNumber;
    _websiteController.text = _controller.businessWebsiteFor(user);
    _addressController.text = user.streetAddress.trim().isEmpty
        ? 'Andheri-Kurla Road'
        : user.streetAddress;
    _didPrefill = true;
  }

  String? _validateWebsite(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    final normalized =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : 'https://$trimmed';
    final parsed = Uri.tryParse(normalized);
    if (parsed == null || parsed.host.trim().isEmpty) {
      return 'Enter a valid website URL';
    }
    return null;
  }

  Future<void> _saveProfile(TestAccount user) async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    await _controller.updateBusinessDetails(
      businessName: _businessNameController.text,
      industry: _industryController.text,
      categoryTitle: user.categoryTitle.trim().isEmpty
          ? _industryController.text
          : user.categoryTitle,
      streetAddress: _addressController.text,
      phoneNumber: _phoneController.text,
      websiteUrl: _websiteController.text,
      city: user.city,
      country: user.country,
      timeZone: user.timeZone,
    );

    _accountSnack(
      title: 'Business Profile Saved',
      message: 'Your workspace profile details were updated successfully.',
    );
  }
}

class AccountGrowthPackageView extends GetView<OnboardingController> {
  const AccountGrowthPackageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.currentUser.value;
      if (user == null) {
        return const Scaffold(
          backgroundColor: _AccountScene.canvas,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      final plan = _planSummaryFor(controller, user);
      final renewsOn = _formatDayMonthYear(
        controller.subscriptionRenewalDateFor(user),
      );

      return Scaffold(
        backgroundColor: _AccountScene.canvas,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AccountBackButton(),
                const SizedBox(height: 30),
                Text(
                  '${plan.title} Package',
                  style: AppTypography.section(
                    fontSize: 24,
                    color: const Color(0xFF16345B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your current package, renewal status, and usage limits.',
                  style: AppTypography.body(
                    fontSize: 14,
                    color: const Color(0xFF27466E),
                  ),
                ),
                const SizedBox(height: 24),
                _AccountSurfaceCard(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PackageLabelValue(
                          label: 'STATUS',
                          value: '• Active Plan',
                          valueColor: const Color(0xFF173A69),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _PackageLabelValue(
                          label: 'PACKAGE',
                          value: plan.title,
                          valueColor: const Color(0xFF2DB565),
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'PLAN DETAILS',
                  style: AppTypography.label(
                    fontSize: 16,
                    color: const Color(0xFF6E82A7),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.24,
                  children: [
                    _PackageDetailCard(
                      label: 'MONTHLY PRICE',
                      value: _formatInr(plan.monthlyPrice),
                      borderColor: const Color(0xFFD4E7FF),
                    ),
                    _PackageDetailCard(
                      label: 'RENEWS',
                      value: renewsOn,
                      borderColor: const Color(0xFFD9F5E6),
                    ),
                    _PackageDetailCard(
                      label: 'LOCATIONS',
                      value: plan.locationsLabel,
                      borderColor: const Color(0xFFF0DCF8),
                    ),
                    _PackageDetailCard(
                      label: 'BILLING CYCLE',
                      value: _titleCase(
                        controller.subscriptionBillingCycleFor(user),
                      ),
                      borderColor: const Color(0xFFFDE7C8),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                _AccountPrimaryButton(
                  label: 'Manage Subscription',
                  icon: Icons.settings_outlined,
                  onPressed: () => Get.toNamed(AppRoutes.payment),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class AccountGoogleBusinessProfileView extends GetView<OnboardingController> {
  const AccountGoogleBusinessProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.currentUser.value;
      if (user == null) {
        return const Scaffold(
          backgroundColor: _AccountScene.canvas,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      final isConnected = user.googleBusinessProfileConnected;
      final websiteUrl = controller.businessWebsiteFor(user);

      return Scaffold(
        backgroundColor: _AccountScene.canvas,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AccountScreenHeader(title: 'Settings'),
                const SizedBox(height: 20),
                _AccountSurfaceCard(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFDCE4F2)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x110F2746),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          'assets/icons/google_logo.svg',
                          width: 34,
                          height: 34,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Google Business Profile',
                        textAlign: TextAlign.center,
                        style: AppTypography.section(
                          fontSize: 22,
                          color: const Color(0xFF122C4D),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: isConnected
                                  ? const Color(0xFF2BC06B)
                                  : const Color(0xFFF05454),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isConnected ? 'Connected' : 'Disconnected',
                            style: AppTypography.button(
                              fontSize: 15,
                              color: isConnected
                                  ? const Color(0xFF17B95F)
                                  : const Color(0xFFE94B4B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Connected accounts keep reviews, posts, reports, and insights synced.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body(
                          fontSize: 14,
                          color: const Color(0xFF4E627D),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _AccountPrimaryButton(
                        label: 'Force Sync Now',
                        icon: Icons.sync_rounded,
                        onPressed: () => _forceSync(isConnected),
                      ),
                      const SizedBox(height: 12),
                      _AccountOutlineButton(
                        label: 'Manage Connection',
                        icon: Icons.settings_rounded,
                        onPressed: () => _showConnectionSheet(context, user),
                      ),
                      const SizedBox(height: 12),
                      _AccountOutlineButton(
                        label: 'Switch Profile',
                        icon: Icons.swap_horiz_rounded,
                        onPressed: () =>
                            _showProfileSwitcherSheet(context, user),
                      ),
                      const SizedBox(height: 12),
                      _AccountOutlineButton(
                        label: 'Re-link Account (Fix Auth)',
                        icon: Icons.autorenew_rounded,
                        onPressed: () => Get.toNamed(AppRoutes.googleOAuth),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEBFF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFB8D2FF)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_rounded,
                        color: Color(0xFF38679D),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isConnected
                                  ? 'Sync Status Normal'
                                  : 'Sync Status Paused',
                              style: AppTypography.button(
                                fontSize: 15,
                                color: const Color(0xFF1D4A7D),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isConnected
                                  ? 'All selected areas are actively syncing. The next automatic sync is scheduled in 45 minutes.'
                                  : 'Syncing is paused until the Google Business Profile connection is restored.',
                              style: AppTypography.body(
                                fontSize: 14,
                                color: const Color(0xFF32557E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Account Details',
                  style: AppTypography.section(
                    fontSize: 18,
                    color: const Color(0xFF122C4D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _AccountSurfaceCard(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  child: Column(
                    children: [
                      _ConnectedAccountRow(
                        label: 'WEBSITE',
                        value: _displayWebsite(websiteUrl),
                        icon: Icons.public_rounded,
                        onTap: () => _openUri(websiteUrl),
                        action: TextButton.icon(
                          onPressed: () => _openUri(websiteUrl),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text('Open'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 24, color: Color(0xFFE6EDF7)),
                      _ConnectedAccountRow(
                        label: 'EMAIL',
                        value: _displayEmail(user),
                        icon: Icons.mail_outline_rounded,
                        onTap: () => _openEmail(_displayEmail(user)),
                        action: TextButton.icon(
                          onPressed: () => _openEmail(_displayEmail(user)),
                          icon: const Icon(Icons.arrow_outward_rounded, size: 16),
                          label: const Text('Send'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 24, color: Color(0xFFE6EDF7)),
                      TextButton.icon(
                        onPressed: isConnected ? _disconnectAccount : null,
                        icon: const Icon(
                          Icons.link_off_rounded,
                          size: 19,
                          color: Color(0xFFE53333),
                        ),
                        label: Text(
                          'Disconnect Account',
                          style: AppTypography.button(
                            fontSize: 14,
                            color: const Color(0xFFE53333),
                            fontWeight: FontWeight.w600,
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
      );
    });
  }

  Future<void> _forceSync(bool wasConnected) async {
    if (!wasConnected) {
      await controller.setGoogleBusinessProfileConnected(true);
    }
    await controller.syncBusinessReviewsFromGoogle();
    _accountSnack(
      title: 'Sync Started',
      message:
          'Google Business Profile data is syncing for this workspace now.',
    );
  }

  Future<void> _disconnectAccount() async {
    final shouldDisconnect = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Disconnect Account'),
        content: const Text(
          'This will pause Google Business Profile syncing for the workspace.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (shouldDisconnect != true) {
      return;
    }

    await controller.setGoogleBusinessProfileConnected(false);
    _accountSnack(
      title: 'Account Disconnected',
      message: 'Google Business Profile sync was paused for this workspace.',
    );
  }

  Future<void> _showConnectionSheet(
    BuildContext context,
    TestAccount user,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8E0EC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Connected Accounts',
                style: AppTypography.card(
                  fontSize: 18,
                  color: const Color(0xFF122C4D),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              _ConnectionTile(
                icon: SvgPicture.asset(
                  'assets/icons/google_logo.svg',
                  width: 22,
                  height: 22,
                ),
                title: 'Google Business Profile',
                subtitle: user.googleBusinessProfileConnected
                    ? 'Reviews, posts, directions, and insights synced.'
                    : 'Syncing paused until the account is reconnected.',
                connected: user.googleBusinessProfileConnected,
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await controller.setGoogleBusinessProfileConnected(
                    !user.googleBusinessProfileConnected,
                  );
                  _accountSnack(
                    title: user.googleBusinessProfileConnected
                        ? 'Google Disconnected'
                        : 'Google Connected',
                    message: user.googleBusinessProfileConnected
                        ? 'Google Business Profile syncing was paused.'
                        : 'Google Business Profile syncing is active again.',
                  );
                },
              ),
              const SizedBox(height: 12),
              _ConnectionTile(
                icon: SvgPicture.asset(
                  'assets/icons/whatsapp_mark.svg',
                  width: 22,
                  height: 22,
                ),
                title: 'WhatsApp',
                subtitle: user.whatsAppConnected
                    ? 'Lead conversations and notifications are connected.'
                    : 'Connect WhatsApp to restore chat delivery.',
                connected: user.whatsAppConnected,
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await controller.setWhatsAppConnected(
                    !user.whatsAppConnected,
                  );
                  _accountSnack(
                    title: user.whatsAppConnected
                        ? 'WhatsApp Disconnected'
                        : 'WhatsApp Connected',
                    message: user.whatsAppConnected
                        ? 'WhatsApp connection was removed from this workspace.'
                        : 'WhatsApp is now connected to this workspace.',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showProfileSwitcherSheet(
    BuildContext context,
    TestAccount user,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Obx(() {
          final profiles = user.backendAvailableBusinesses;
          final activeBusinessId = user.backendBusinessId.trim();
          final isBusy =
              controller.isProfileSwitching.value ||
              controller.isLocationActivationLoading.value;

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 54,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8E0EC),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Switch business profile',
                    style: AppTypography.card(
                      fontSize: 18,
                      color: const Color(0xFF122C4D),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the active workspace for this email or add another Google Business Profile.',
                    style: AppTypography.body(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (profiles.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFD),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F2)),
                      ),
                      child: Text(
                        'No activated profiles are available yet. Add another profile to connect one.',
                        style: AppTypography.body(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: profiles.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final profile = profiles[index];
                          final profileBusinessId =
                              profile['id']?.toString().trim() ?? '';
                          return _BusinessProfileSwitchTile(
                            businessName: _firstNonEmpty([
                              profile['name']?.toString() ?? '',
                              profile['businessName']?.toString() ?? '',
                              'Business profile',
                            ]),
                            subtitle: _firstNonEmpty([
                              profile['address']?.toString() ?? '',
                              profile['locationId']?.toString() ?? '',
                              profile['gmbLocationId']?.toString() ?? '',
                            ]),
                            isActive: profileBusinessId == activeBusinessId,
                            isBusy: isBusy,
                            onPressed: profileBusinessId == activeBusinessId
                                ? null
                                : () async {
                                    Navigator.of(sheetContext).pop();
                                    await controller
                                        .switchActiveGoogleBusinessProfile(
                                          profile,
                                        );
                                  },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 18),
                  _AccountPrimaryButton(
                    label: 'Add another profile',
                    icon: Icons.add_business_rounded,
                    onPressed: () async {
                      if (isBusy) {
                        return;
                      }
                      Navigator.of(sheetContext).pop();
                      await controller.startAdditionalBusinessOnboarding();
                    },
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }

  Future<void> _openUri(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      _accountSnack(
        title: 'Unable To Open',
        message: 'The link could not be opened from this device.',
      );
    }
  }

  Future<void> _openEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      _accountSnack(
        title: 'Unable To Open',
        message: 'The email app could not be opened from this device.',
      );
    }
  }
}

class AccountWorkspaceHealthView extends StatelessWidget {
  const AccountWorkspaceHealthView({super.key});

  @override
  Widget build(BuildContext context) {
    const cards = [
      _WorkspaceHealthMetric(
        icon: Icons.location_on_outlined,
        iconColor: Color(0xFFFB8C00),
        iconBackground: Color(0xFFFFF6E8),
        value: '8',
        status: 'HEALTHY',
        statusColor: Color(0xFF26C06B),
        title: 'Business profiles',
        subtitle: 'Connected profiles',
        progressColor: Color(0xFF28BD76),
        progressBackground: Color(0xFFE7F7ED),
        borderColor: Color(0xFFD8E5F6),
      ),
      _WorkspaceHealthMetric(
        icon: Icons.auto_awesome_outlined,
        iconColor: Color(0xFF6847E8),
        iconBackground: Color(0xFFF0EAFF),
        value: '16',
        status: 'HEALTHY',
        statusColor: Color(0xFF26C06B),
        title: 'AI posts left',
        subtitle: '0/8 used this month',
        progressColor: Color(0xFF28BD76),
        progressBackground: Color(0xFFE7F7ED),
        borderColor: Color(0xFFD8E5F6),
      ),
      _WorkspaceHealthMetric(
        icon: Icons.draw_outlined,
        iconColor: Color(0xFFA23CF1),
        iconBackground: Color(0xFFF7EAFB),
        value: '3',
        status: 'LOW',
        statusColor: Color(0xFFF05454),
        title: 'Creative capacity',
        subtitle: 'Profiles allowed',
        progressColor: Color(0xFFF4E4E4),
        progressBackground: Color(0xFFF8EEEE),
        borderColor: Color(0xFFD8E5F6),
      ),
      _WorkspaceHealthMetric(
        icon: Icons.calendar_month_outlined,
        iconColor: Color(0xFFD230A8),
        iconBackground: Color(0xFFF8E8F7),
        value: '10',
        status: 'HEALTHY',
        statusColor: Color(0xFF26C06B),
        title: 'SEO keywords',
        subtitle: 'SEO tracking limit',
        progressColor: Color(0xFFECECEC),
        progressBackground: Color(0xFFF1F1F1),
        borderColor: Color(0xFFF0DDED),
      ),
    ];

    return Scaffold(
      backgroundColor: _AccountScene.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AccountScreenHeader(title: 'Workspace Health'),
              const SizedBox(height: 22),
              GridView.builder(
                itemCount: cards.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, index) {
                  final metric = cards[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () =>
                        Get.toNamed(AppRoutes.accountWorkspaceHealthChecklist),
                    child: _WorkspaceHealthCard(metric: metric),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountWorkspaceHealthChecklistView
    extends GetView<OnboardingController> {
  const AccountWorkspaceHealthChecklistView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.currentUser.value;
      if (user == null) {
        return const Scaffold(
          backgroundColor: _AccountScene.canvas,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      final items = [
        _HealthChecklistItem(
          label: 'Business name is saved',
          isComplete: _displayBusinessName(user).trim().isNotEmpty,
        ),
        _HealthChecklistItem(
          label: 'Business phone is available for reports and citations',
          isComplete: user.phoneNumber.trim().isNotEmpty,
        ),
        _HealthChecklistItem(
          label: 'Website is connected for conversion tracking',
          isComplete: controller.businessWebsiteFor(user).trim().isNotEmpty,
        ),
        _HealthChecklistItem(
          label: 'Google Business Profile is connected',
          isComplete: user.googleBusinessProfileConnected,
        ),
      ];
      final completedCount = items.where((item) => item.isComplete).length;

      return Scaffold(
        backgroundColor: _AccountScene.canvas,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 18, 26, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AccountBackButton(),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F8FB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sync_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'WORKSPACE HEALTH',
                      style: AppTypography.label(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Text(
                  'What happens next',
                  style: AppTypography.section(
                    fontSize: 26,
                    color: const Color(0xFF173A69),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Keep these items healthy so the dashboard stays accurate.',
                  style: AppTypography.body(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 30),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _HealthChecklistCard(item: item),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF2DB565)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF2DB565),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF2DB565),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$completedCount of ${items.length} complete',
                              style: AppTypography.card(
                                fontSize: 16,
                                color: const Color(0xFF173A69),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              completedCount == items.length
                                  ? 'Great job! Your workspace health is perfect.'
                                  : 'A few items still need attention to reach full health.',
                              style: AppTypography.body(
                                fontSize: 14,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _PackageDetailCard extends StatelessWidget {
  const _PackageDetailCard({
    required this.label,
    required this.value,
    required this.borderColor,
  });

  final String label;
  final String value;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.label(
              fontSize: 12,
              color: const Color(0xFF7184A8),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.card(
              fontSize: 18,
              color: const Color(0xFF173A69),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageLabelValue extends StatelessWidget {
  const _PackageLabelValue({
    required this.label,
    required this.value,
    required this.valueColor,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label(
            fontSize: 12,
            color: const Color(0xFF7184A8),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: AppTypography.card(
            fontSize: 18,
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ConnectedAccountRow extends StatelessWidget {
  const _ConnectedAccountRow({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.action,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8FB),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.label(
                    fontSize: 12,
                    color: const Color(0xFF7C8AA3),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: AppTypography.body(
                    fontSize: 14,
                    color: const Color(0xFF143861),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            action!,
          ],
        ],
      ),
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.connected,
    required this.onPressed,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final bool connected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: icon,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.button(
                    fontSize: 15,
                    color: const Color(0xFF15365E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTypography.body(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onPressed,
            child: Text(
              connected ? 'Disconnect' : 'Connect',
              style: AppTypography.button(
                fontSize: 13,
                color: connected ? const Color(0xFFE53333) : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessProfileSwitchTile extends StatelessWidget {
  const _BusinessProfileSwitchTile({
    required this.businessName,
    required this.subtitle,
    required this.isActive,
    required this.isBusy,
    required this.onPressed,
  });

  final String businessName;
  final String subtitle;
  final bool isActive;
  final bool isBusy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF0FBFA) : const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? const Color(0xFF9EE6E0) : const Color(0xFFE2E8F2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              isActive ? Icons.check_circle_rounded : Icons.storefront_rounded,
              color: isActive ? const Color(0xFF18AA96) : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName,
                  style: AppTypography.button(
                    fontSize: 15,
                    color: const Color(0xFF15365E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: isActive || isBusy ? null : onPressed,
            child: Text(
              isActive ? 'Active' : 'Switch',
              style: AppTypography.button(
                fontSize: 13,
                color: isActive ? const Color(0xFF18AA96) : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceHealthCard extends StatelessWidget {
  const _WorkspaceHealthCard({required this.metric});

  final _WorkspaceHealthMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: metric.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2746),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: metric.iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(metric.icon, color: metric.iconColor, size: 24),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    metric.value,
                    style: AppTypography.section(
                      fontSize: 22,
                      color: const Color(0xFF173A69),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metric.status,
                    style: AppTypography.label(
                      fontSize: 11,
                      color: metric.statusColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(
            metric.title,
            style: AppTypography.card(
              fontSize: 17,
              color: const Color(0xFF173A69),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metric.subtitle,
            style: AppTypography.body(
              fontSize: 14,
              color: const Color(0xFF6B7A91),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: metric.progressBackground,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.centerLeft,
            child: Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: metric.progressColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthChecklistCard extends StatelessWidget {
  const _HealthChecklistCard({required this.item});

  final _HealthChecklistItem item;

  @override
  Widget build(BuildContext context) {
    final iconColor = item.isComplete
        ? AppColors.primary
        : const Color(0xFF94A3B8);
    final iconBackground = item.isComplete
        ? const Color(0xFFEAF8FB)
        : const Color(0xFFF1F5F9);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.isComplete ? Icons.check_rounded : Icons.remove_rounded,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              item.label,
              style: AppTypography.body(
                fontSize: 14,
                color: const Color(0xFF173A69),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountScreenHeader extends StatelessWidget {
  const _AccountScreenHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _AccountBackButton(),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.card(
              fontSize: 20,
              color: const Color(0xFF122C4D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 58),
      ],
    );
  }
}

class _AccountBackButton extends StatelessWidget {
  const _AccountBackButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _handleAccountBack,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD9E3EF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F2746),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF122C4D),
          size: 18,
        ),
      ),
    );
  }
}

class _AccountPrimaryButton extends StatelessWidget {
  const _AccountPrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: AppTypography.button(
            fontSize: 14,
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AccountOutlineButton extends StatelessWidget {
  const _AccountOutlineButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF123D73),
          side: const BorderSide(color: Color(0xFF184C87)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: AppTypography.button(
            fontSize: 14,
            color: const Color(0xFF123D73),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AccountSurfaceCard extends StatelessWidget {
  const _AccountSurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2746),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _WorkspaceHealthMetric {
  const _WorkspaceHealthMetric({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.value,
    required this.status,
    required this.statusColor,
    required this.title,
    required this.subtitle,
    required this.progressColor,
    required this.progressBackground,
    required this.borderColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String value;
  final String status;
  final Color statusColor;
  final String title;
  final String subtitle;
  final Color progressColor;
  final Color progressBackground;
  final Color borderColor;
}

class _HealthChecklistItem {
  const _HealthChecklistItem({required this.label, required this.isComplete});

  final String label;
  final bool isComplete;
}

class _PlanSummary {
  const _PlanSummary({
    required this.title,
    required this.monthlyPrice,
    required this.locationsLabel,
  });

  final String title;
  final int monthlyPrice;
  final String locationsLabel;
}

abstract final class _AccountScene {
  static const canvas = Color(0xFFF6F8FC);
}

_PlanSummary _planSummaryFor(
  OnboardingController controller,
  TestAccount user,
) {
  final planId = controller.subscriptionPlanIdFor(user);
  switch (planId) {
    case 'starter':
      return const _PlanSummary(
        title: 'Starter',
        monthlyPrice: 3999,
        locationsLabel: '1 Included',
      );
    case 'enterprise':
      return const _PlanSummary(
        title: 'Enterprise',
        monthlyPrice: 24999,
        locationsLabel: 'Unlimited',
      );
    case 'premium':
      return const _PlanSummary(
        title: 'Premium',
        monthlyPrice: 14999,
        locationsLabel: 'Unlimited',
      );
    default:
      return const _PlanSummary(
        title: 'Growth',
        monthlyPrice: 7999,
        locationsLabel: '3 Included',
      );
  }
}

String _formatInr(int amount) {
  final digits = amount.toString();
  if (digits.length <= 3) {
    return '₹$digits';
  }

  final lastThree = digits.substring(digits.length - 3);
  final prefix = digits.substring(0, digits.length - 3);
  final parts = <String>[];
  for (int index = prefix.length; index > 0; index -= 2) {
    final start = (index - 2).clamp(0, prefix.length);
    parts.insert(0, prefix.substring(start, index));
  }
  return '₹${parts.join(',')},$lastThree';
}

String _formatDayMonthYear(DateTime value) {
  const months = [
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
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

String _titleCase(String value) {
  if (value.isEmpty) {
    return value;
  }
  return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}

String _displayWebsite(String value) {
  return value
      .replaceFirst(RegExp(r'^https?://'), '')
      .replaceFirst(RegExp(r'/$'), '');
}

String _displayEmail(TestAccount user) {
  final email = user.email.trim();
  return email.isEmpty ? 'zoneuprealty@gmail.com' : email;
}

String _displayBusinessName(TestAccount user) {
  final businessName = user.businessName.trim();
  return businessName.isEmpty ? 'Web Aimbeat' : businessName;
}

void _accountSnack({required String title, required String message}) {
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(14),
    backgroundColor: const Color(0xFF16345B),
    colorText: AppColors.white,
  );
}

void _handleAccountBack() {
  if (Get.previousRoute.isNotEmpty) {
    Get.back();
    return;
  }
  Get.offNamed(AppRoutes.account);
}
