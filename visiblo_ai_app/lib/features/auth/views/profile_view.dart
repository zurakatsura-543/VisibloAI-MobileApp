import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../controllers/account_settings_controller.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_navigation_shell.dart';

class AccountView extends GetView<AccountSettingsController> {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthNavigationShell(
      currentTab: AuthTab.account,
      backgroundColor: const Color(0xFFF5F8FC),
      child: Obx(() {
        final liveSettings = controller.settings.value;
        if (controller.isLoading.value && liveSettings == null) {
          return const _LoadingState();
        }

        if (liveSettings == null) {
          return _ErrorState(
            message:
                controller.errorMessage.value ??
                'Unable to load workspace settings right now.',
            onRetry: controller.refreshData,
            onLogout: controller.logout,
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.refreshData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              AuthViewSpacing.pageHorizontal,
              10,
              AuthViewSpacing.pageHorizontal,
              26,
            ),
            children: [
              const _AccountHeader(),
              const SizedBox(height: 12),
              if (controller.errorMessage.value != null) ...[
                _BannerMessage(
                  message: controller.errorMessage.value!,
                  accent: const Color(0xFFE24B4B),
                  background: const Color(0xFFFFF1F1),
                  icon: Icons.error_outline_rounded,
                  onDismiss: controller.clearError,
                ),
                const SizedBox(height: 12),
              ],
              if (controller.infoMessage.value != null) ...[
                _BannerMessage(
                  message: controller.infoMessage.value!,
                  accent: const Color(0xFF179CA3),
                  background: const Color(0xFFEAF9FB),
                  icon: Icons.check_circle_outline_rounded,
                  onDismiss: controller.clearInfo,
                ),
                const SizedBox(height: 12),
              ],
              _WorkspaceSummaryCard(controller: controller),
              const SizedBox(height: 12),
              _WorkspaceMetricsGrid(controller: controller),
              const SizedBox(height: 12),
              _AccountNavigationCard(controller: controller),
              const SizedBox(height: 12),
              _LogoutCard(onTap: controller.logout),
              const SizedBox(height: 12),
              _DeleteAccountCard(
                onDelete: () => _confirmDeleteAccount(context),
                businessName: controller.businessNameValue,
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text(
                'Delete business profile',
                style: AppTypography.card(
                  fontSize: 20,
                  color: AppColors.brandBlue,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ This will remove the current Google Business Profile from your VisibloAI workspace.',
                    style: AppTypography.body(
                      fontSize: 13.5,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'For safety, we will send a 6-digit OTP to your email before anything is deleted.',
                    style: AppTypography.body(
                      fontSize: 13.2,
                      color: AppColors.mutedText,
                      height: 1.45,
                    ),
                  ),
                ],
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
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Send OTP',
                    style: AppTypography.button(
                      fontSize: 13.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    try {
      await controller.requestBusinessDeleteOtp();
    } catch (_) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    await _showDeleteOtpDialog(context);
  }

  Future<void> _showDeleteOtpDialog(BuildContext context) async {
    final otpController = TextEditingController();
    String? localError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return Obx(() {
              final isBusy = controller.isDeleteConfirming.value;
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                title: Text(
                  'Verify deletion OTP',
                  style: AppTypography.card(
                    fontSize: 20,
                    color: AppColors.brandBlue,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter the 6-digit OTP sent to your account email to delete this business profile safely.',
                      style: AppTypography.body(
                        fontSize: 13.2,
                        color: AppColors.mutedText,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: 'Deletion OTP',
                        counterText: '',
                        errorText: localError,
                        prefixIcon: const Icon(Icons.verified_user_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isBusy
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      'Cancel',
                      style: AppTypography.button(
                        fontSize: 13.5,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: isBusy
                        ? null
                        : () async {
                            final otp = otpController.text.trim();
                            if (otp.length != 6) {
                              setState(() {
                                localError = 'Enter the 6-digit OTP.';
                              });
                              return;
                            }
                            setState(() {
                              localError = null;
                            });
                            try {
                              final deleted =
                                  await controller.confirmBusinessDelete(otp);
                              if (deleted && dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            } catch (_) {
                              setState(() {
                                localError =
                                    controller.errorMessage.value ??
                                    'Unable to verify the OTP right now.';
                              });
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B6B),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      isBusy ? 'Deleting...' : 'Verify & delete',
                      style: AppTypography.button(
                        fontSize: 13.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            });
          },
        );
      },
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.onLogout,
  });

  final String message;
  final Future<void> Function() onRetry;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFFD9D9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12003F70),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEFF1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFFE24B4B),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Account unavailable',
                style: AppTypography.card(
                  fontSize: 20,
                  color: AppColors.brandBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body(
                  fontSize: 13.5,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandBlue,
                  side: const BorderSide(color: Color(0xFFD9E2F1)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AuthShellBackButton(),
        const Expanded(
          child: Text(
            'Account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 38),
      ],
    );
  }
}

class _BannerMessage extends StatelessWidget {
  const _BannerMessage({
    required this.message,
    required this.accent,
    required this.background,
    required this.icon,
    required this.onDismiss,
  });

  final String message;
  final Color accent;
  final Color background;
  final IconData icon;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(
                fontSize: 12.8,
                color: const Color(0xFF29415E),
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            splashRadius: 18,
            icon: Icon(Icons.close_rounded, size: 18, color: accent),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceSummaryCard extends StatelessWidget {
  const _WorkspaceSummaryCard({required this.controller});

  final AccountSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final logoPath = controller.logoPath.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D11345F),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ACTIVE WORKSPACE',
                style: AppTypography.label(
                  fontSize: 10.6,
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.75,
                ),
              ),
              const Spacer(),
              _WorkspaceStatusBadge(
                label: controller.isGoogleConnected
                    ? 'GBP connected'
                    : 'GBP pending',
                foreground: controller.isGoogleConnected
                    ? const Color(0xFF1FA971)
                    : const Color(0xFFD1821F),
                background: controller.isGoogleConnected
                    ? const Color(0xFFE8FFF2)
                    : const Color(0xFFFFF4E4),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WorkspaceAvatar(
                initials: controller.workspaceInitials,
                logoPath: logoPath,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.businessNameValue,
                      style: AppTypography.card(
                        fontSize: 23,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _WorkspacePill(
                      icon: Icons.person_outline_rounded,
                      label: controller.ownerNameValue,
                    ),
                    const SizedBox(height: 8),
                    _WorkspacePill(
                      icon: Icons.mail_outline_rounded,
                      label: controller.email,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.accountBusinessProfile),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: Text(
                'Edit workspace',
                style: AppTypography.button(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceAvatar extends StatelessWidget {
  const _WorkspaceAvatar({required this.initials, required this.logoPath});

  final String initials;
  final String logoPath;

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoPath.isNotEmpty;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBFC),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD7EEF2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasLogo
          ? Image.file(
              File(logoPath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _AvatarInitials(initials: initials),
            )
          : _AvatarInitials(initials: initials),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  const _AvatarInitials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: AppTypography.button(
          fontSize: 14,
          color: const Color(0xFF2C98A6),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WorkspaceStatusBadge extends StatelessWidget {
  const _WorkspaceStatusBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: AppTypography.label(
          fontSize: 9.8,
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WorkspacePill extends StatelessWidget {
  const _WorkspacePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFD),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD6DEE9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6E8098)),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(
                fontSize: 12.5,
                color: const Color(0xFF516174),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceMetricsGrid extends StatelessWidget {
  const _WorkspaceMetricsGrid({required this.controller});

  final AccountSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final profileLimit = controller.planConfig.maxLocations;
    final profileProgress = profileLimit == 999
        ? 1.0
        : (controller.usedProfiles / profileLimit).clamp(0.0, 1.0);
    final postLimit = controller.postLimit <= 0 ? 1 : controller.postLimit;
    final postsProgress = controller.remainingPosts == 999
        ? 1.0
        : (controller.remainingPosts / postLimit).clamp(0.0, 1.0);
    final creativesProgress = (controller.planConfig.maxCreativesPerMonth / 30)
        .clamp(0.0, 1.0);
    final keywordsProgress = (controller.planConfig.maxKeywords / 50).clamp(
      0.0,
      1.0,
    );

    final metrics = [
      _MetricCardData(
        icon: Icons.location_on_outlined,
        iconColor: const Color(0xFFFF9A3E),
        iconBackground: const Color(0xFFFFF4E8),
        value: profileLimit == 999
            ? '${controller.usedProfiles}/∞'
            : '${controller.usedProfiles}/$profileLimit',
        statusLabel:
            profileLimit == 999 || controller.usedProfiles < profileLimit
            ? 'HEALTHY'
            : 'LOW',
        statusColor:
            profileLimit == 999 || controller.usedProfiles < profileLimit
            ? const Color(0xFF1FA971)
            : const Color(0xFFE84E4E),
        title: 'Business profiles',
        subtitle: 'Connected profiles',
        progress: profileProgress,
        progressColor: const Color(0xFF2CC384),
      ),
      _MetricCardData(
        icon: Icons.auto_awesome_outlined,
        iconColor: const Color(0xFF5D8EFF),
        iconBackground: const Color(0xFFEFF4FF),
        value: controller.remainingPosts == 999
            ? '∞'
            : controller.remainingPosts.toString(),
        statusLabel: controller.remainingPosts == 0 ? 'LOW' : 'HEALTHY',
        statusColor: controller.remainingPosts == 0
            ? const Color(0xFFE84E4E)
            : const Color(0xFF1FA971),
        title: 'AI posts left',
        subtitle: controller.usageHint,
        progress: postsProgress,
        progressColor: const Color(0xFF2CC384),
      ),
      _MetricCardData(
        icon: Icons.edit_square,
        iconColor: const Color(0xFFAF63FF),
        iconBackground: const Color(0xFFF6EEFF),
        value: _limitLabel(controller.planConfig.maxCreativesPerMonth),
        statusLabel: controller.planConfig.maxCreativesPerMonth < 10
            ? 'LOW'
            : 'HEALTHY',
        statusColor: controller.planConfig.maxCreativesPerMonth < 10
            ? const Color(0xFFE84E4E)
            : const Color(0xFF1FA971),
        title: 'Creative capacity',
        subtitle: 'Profiles allowed',
        progress: creativesProgress,
        progressColor: controller.planConfig.maxCreativesPerMonth < 10
            ? const Color(0xFFFF5353)
            : const Color(0xFF2CC384),
      ),
      _MetricCardData(
        icon: Icons.wallet_giftcard_rounded,
        iconColor: const Color(0xFFE15ED7),
        iconBackground: const Color(0xFFFFF0FD),
        value: _limitLabel(controller.planConfig.maxKeywords),
        statusLabel: controller.planConfig.maxKeywords > 0 ? 'HEALTHY' : 'LOW',
        statusColor: controller.planConfig.maxKeywords > 0
            ? const Color(0xFF1FA971)
            : const Color(0xFFE84E4E),
        title: 'SEO keywords',
        subtitle: 'SEO tracking limit',
        progress: keywordsProgress,
        progressColor: controller.planConfig.maxKeywords > 0
            ? const Color(0xFF2CC384)
            : const Color(0xFFFF5353),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.98,
      ),
      itemBuilder: (context, index) {
        return _AccountMetricCard(data: metrics[index]);
      },
    );
  }

  static String _limitLabel(int value) {
    if (value == 999) {
      return '∞';
    }
    return value.toString();
  }
}

class _MetricCardData {
  const _MetricCardData({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.value,
    required this.statusLabel,
    required this.statusColor,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.progressColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String value;
  final String statusLabel;
  final Color statusColor;
  final String title;
  final String subtitle;
  final double progress;
  final Color progressColor;
}

class _AccountMetricCard extends StatelessWidget {
  const _AccountMetricCard({required this.data});

  final _MetricCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0911345F),
            blurRadius: 10,
            offset: Offset(0, 4),
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
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: data.iconBackground,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(data.icon, size: 16, color: data.iconColor),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data.value,
                    style: AppTypography.card(
                      fontSize: 18,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    data.statusLabel,
                    style: AppTypography.label(
                      fontSize: 10,
                      color: data.statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(
            data.title,
            style: AppTypography.button(
              fontSize: 13.5,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body(
              fontSize: 11.6,
              color: const Color(0xFF8290A5),
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: data.progress,
              backgroundColor: const Color(0xFFF1F4F8),
              valueColor: AlwaysStoppedAnimation<Color>(data.progressColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountNavigationCard extends StatelessWidget {
  const _AccountNavigationCard({required this.controller});

  final AccountSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final items = [
      _AccountMenuData(
        title: 'Business Profile',
        subtitle: 'business name, phone, website, address.',
        icon: Icons.business_rounded,
        iconColor: const Color(0xFF22A56A),
        iconBackground: const Color(0xFFEAF8F0),
        onTap: () => Get.toNamed(AppRoutes.accountBusinessProfile),
      ),
      _AccountMenuData(
        title: 'Package & Billing',
        subtitle: '/ current plan, billing, usage limits.',
        icon: Icons.credit_card_rounded,
        iconColor: const Color(0xFFF17735),
        iconBackground: const Color(0xFFFFF1E8),
        onTap: controller.openBilling,
      ),
      _AccountMenuData(
        title: 'Google Business Profile',
        subtitle: 'reviews, posts, directions, and insights synced.',
        icon: Icons.language_rounded,
        iconColor: const Color(0xFF4285F4),
        iconBackground: const Color(0xFFF1F6FF),
        trailingBadge: 'G',
        trailingBadgeColor: const Color(0xFF4285F4),
        onTap: () => Get.toNamed(AppRoutes.accountGoogleBusinessProfile),
      ),
      _AccountMenuData(
        title: 'Connected Accounts',
        subtitle: controller.isGoogleConnected
            ? 'Google Business Profile, WhatsApp'
            : 'Connect Google Business Profile',
        icon: Icons.link_rounded,
        iconColor: const Color(0xFF47B987),
        iconBackground: const Color(0xFFEAF9F1),
        onTap: () => Get.toNamed(AppRoutes.accountGoogleBusinessProfile),
      ),
      _AccountMenuData(
        title: 'AI token Health',
        subtitle: 'keep these items healthy .',
        icon: Icons.shield_outlined,
        iconColor: const Color(0xFFFF5A5A),
        iconBackground: const Color(0xFFFFEEF0),
        onTap: controller.openWorkspaceHealth,
      ),
      _AccountMenuData(
        title: 'Workplace health',
        subtitle: 'AI chat, raise ticket, FAQ',
        icon: Icons.help_outline_rounded,
        iconColor: const Color(0xFF53BFE8),
        iconBackground: const Color(0xFFEAF9FF),
        onTap: controller.openSupport,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D11345F),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            _AccountMenuTile(data: items[index]),
            if (index != items.length - 1)
              const Divider(height: 1, color: Color(0xFFF1F4F8)),
          ],
        ],
      ),
    );
  }
}

class _AccountMenuData {
  const _AccountMenuData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
    this.trailingBadge,
    this.trailingBadgeColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;
  final String? trailingBadge;
  final Color? trailingBadgeColor;
}

class _AccountMenuTile extends StatelessWidget {
  const _AccountMenuTile({required this.data});

  final _AccountMenuData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: data.iconBackground,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: data.trailingBadge == null
                    ? Icon(data.icon, size: 18, color: data.iconColor)
                    : Text(
                        data.trailingBadge!,
                        style: AppTypography.button(
                          fontSize: 17,
                          color: data.trailingBadgeColor ?? data.iconColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: AppTypography.button(
                        fontSize: 14,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        fontSize: 11.6,
                        color: const Color(0xFF7B8A9F),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB7C1CF),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD6D6)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFFF5A5A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log out',
                        style: AppTypography.button(
                          fontSize: 15,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Log out from this Google Business Profile.',
                        style: AppTypography.body(
                          fontSize: 11.5,
                          color: const Color(0xFF7E8798),
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB4BCCE),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountCard extends StatelessWidget {
  const _DeleteAccountCard({
    required this.onDelete,
    required this.businessName,
  });

  final VoidCallback onDelete;
  final String businessName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFCACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFEF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFF6B6B),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delete business profile',
                  style: AppTypography.button(
                    fontSize: 14.2,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '⚠️ Remove "$businessName" from VisibloAI only after OTP verification by email.',
                  style: AppTypography.body(
                    fontSize: 11.2,
                    color: const Color(0xFF7E8798),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onDelete,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Delete',
              style: AppTypography.label(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
