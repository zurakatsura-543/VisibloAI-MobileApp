// ignore_for_file: unused_element, unused_element_parameter

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api_client.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/widgets/app_logo.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../../social/controllers/social_accounts_controller.dart';
import '../../social/controllers/social_analytics_controller.dart';
import '../../social/controllers/social_calendar_controller.dart';
import '../../social/controllers/social_create_controller.dart';
import '../../social/controllers/social_creatives_controller.dart';
import '../../social/controllers/social_posts_controller.dart';
import '../../social/controllers/social_reports_controller.dart';
import '../../social/controllers/social_scheduler_controller.dart';
import '../../social/models/social_account.dart';
import '../../social/models/social_engine_models.dart';
import '../../social/services/social_api_service.dart';
import '../controllers/product_mode_controller.dart';
import '../controllers/account_settings_controller.dart';
import '../models/test_account.dart';
import '../widgets/auth_navigation_shell.dart';
import '../widgets/auth_sidebar.dart';

const _socialBrandButtonStart = Color(0xFF0A3F85);
const _socialBrandButtonEnd = Color(0xFF1565C0);
const _socialBrandButtonShadow = Color(0x220A3F85);
const _socialTextLengthOptions = <String>[
  'Short (2-3 lines)',
  'Medium (4-6 lines)',
  'Long (7-10 lines)',
];
const _socialEditImageQualityLabels = <String, String>{
  'good': 'Good (Fast)',
  'high': 'High',
  'highest': 'Highest',
};

String _calendarMonthName(int month) {
  const names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return names[(month - 1).clamp(0, 11)];
}

String _calendarShortMonth(int month) {
  const names = [
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
  return names[(month - 1).clamp(0, 11)];
}

String _calendarShortWeekday(int weekday) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[(weekday - 1).clamp(0, 6)];
}

String _resolveSocialImageUrl(String image) {
  if (image.startsWith('/uploads/') || image.startsWith('/public/')) {
    final apiBase = ApiClient().baseUrl;
    final publicBase = apiBase.replaceAll(RegExp(r'/api/?$'), '');
    return '$publicBase$image';
  }
  return image;
}

String _formatCalendarTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _formatCalendarAgendaTime(DateTime date) {
  return '${_calendarShortWeekday(date.weekday)}, '
      '${_calendarShortMonth(date.month)} ${date.day} at '
      '${_formatCalendarTime(date)}';
}

void _showCalendarPostPreview(
  BuildContext context,
  SocialPostInfo post,
  SocialCalendarController controller,
) {
  final date = controller.postDate(post);
  final hashtags = _extractCalendarPostHashtags(post);
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_calendarPostStatusLabel(controller.normalizeStatus(post))} Post',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF101A35),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.mediaUrls.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            post.mediaUrls.first,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 180,
                                  alignment: Alignment.center,
                                  color: const Color(0xFFF3F6FA),
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    color: Color(0xFF8A96AD),
                                  ),
                                ),
                          ),
                        ),
                      if (post.mediaUrls.isNotEmpty) const SizedBox(height: 14),
                      Text(
                        post.content.isEmpty
                            ? 'Untitled social post'
                            : post.content,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF101A35),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                      if (hashtags.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F8FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDDE6FF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hashtags',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFF64728F),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                hashtags,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFF395CFF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Image.asset(
                    controller.platformIconPath(post),
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatCalendarAgendaTime(date),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF64728F),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _calendarPostStatusLabel(String status) {
  return switch (status) {
    'published' => 'Published',
    'scheduled' => 'Scheduled',
    'failed' => 'Failed',
    _ => 'Draft',
  };
}

String _extractCalendarPostHashtags(SocialPostInfo post) {
  final values = <String>[
    _readCalendarHashtagValue(post.raw['hashtags']),
    _readCalendarHashtagValue(post.raw['hashtag']),
    _readCalendarHashtagValue(post.raw['tags']),
  ];

  final content = post.raw['content'];
  if (content is Map) {
    final nested = Map<String, dynamic>.from(content);
    values.addAll([
      _readCalendarHashtagValue(nested['hashtags']),
      _readCalendarHashtagValue(nested['hashtag']),
      _readCalendarHashtagValue(nested['tags']),
    ]);
  } else if (content is String) {
    final match = RegExp(
      r'"hashtags"\s*:\s*("((?:\\.|[^"\\])*)"|\[[^\]]*\])',
    ).firstMatch(content);
    if (match != null) {
      values.add(_cleanCalendarHashtagText(match.group(1) ?? ''));
    }
  }

  return values
      .expand((value) => value.split(RegExp(r'[\n,]+')))
      .map(_cleanCalendarHashtagText)
      .where((value) => value.isNotEmpty)
      .map((value) => value.startsWith('#') ? value : '#$value')
      .toSet()
      .join(' ');
}

String _readCalendarHashtagValue(dynamic value) {
  if (value is List) return value.map((item) => item.toString()).join(' ');
  return _cleanCalendarHashtagText(value?.toString() ?? '');
}

String _cleanCalendarHashtagText(String value) {
  return value
      .replaceAll('[', ' ')
      .replaceAll(']', ' ')
      .replaceAll('"', ' ')
      .replaceAll("'", ' ')
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\"', '"')
      .trim();
}

class SocialAccountsView extends StatefulWidget {
  const SocialAccountsView({super.key});

  @override
  State<SocialAccountsView> createState() => _SocialAccountsViewState();
}

class _SocialAccountsViewState extends State<SocialAccountsView> {
  final OnboardingController _controller = Get.find<OnboardingController>();
  late final SocialAccountsController _socialAccountsController =
      Get.isRegistered<SocialAccountsController>()
      ? Get.find<SocialAccountsController>()
      : Get.put(SocialAccountsController());
  bool _isSidebarOpen = false;
  bool _awaitingExternalSocialAuth = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _socialAccountsController.loadAccounts();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  late final WidgetsBindingObserver _lifecycleObserver =
      _SocialAccountsLifecycleObserver(
        onResumed: () {
          if (_awaitingExternalSocialAuth) {
            _awaitingExternalSocialAuth = false;
            _socialAccountsController.loadAccounts(refresh: true);
          }
        },
      );

  Future<void> _launchConnectFlow(String platform) async {
    try {
      final url = await _socialAccountsController.getConnectUrl(platform);
      _awaitingExternalSocialAuth = true;
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _awaitingExternalSocialAuth = false;
        Get.snackbar(
          'Could not open browser',
          'Please try connecting your $platform account again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (mounted) {
        Get.snackbar(
          'Continue in browser',
          'Complete the $platform connection, then return here to refresh your accounts.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      Get.snackbar(
        'Connection failed',
        _humanizeError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _openConnectOptions() {
    final availablePlatforms = _socialAccountsController.availablePlatforms;
    if (availablePlatforms.isEmpty) {
      Get.snackbar(
        'All supported platforms connected',
        'Your Facebook, Instagram, and LinkedIn accounts are already connected.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.bottomSheet<void>(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connect a platform',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF111827),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              for (final platform in availablePlatforms) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _platformAvatar(_platformLogoPath(platform)),
                  title: Text(
                    _platformTitle(platform),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Open the secure browser flow to connect ${_platformTitle(platform)}.',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF6C7692),
                      fontSize: 12.8,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Get.back<void>();
                    _launchConnectFlow(platform);
                  },
                ),
                if (platform != availablePlatforms.last)
                  const Divider(color: Color(0xFFE7EDF5), height: 1),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDisconnect(SocialAccount account) async {
    final confirmed =
        await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Disconnect account'),
            content: Text(
              'Disconnect ${account.platformAccountName} from ${_platformTitle(account.platform)}?',
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
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    try {
      await _socialAccountsController.disconnect(account);
      if (mounted) {
        Get.snackbar(
          'Account disconnected',
          '${account.platformAccountName} has been disconnected.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      Get.snackbar(
        'Disconnect failed',
        _humanizeError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String _humanizeError(Object error) {
    final message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }
    return message;
  }

  Future<void> _openSidebar(TestAccount user) async {
    if (_isSidebarOpen) {
      return;
    }
    setState(() => _isSidebarOpen = true);
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierLabel: 'Social sidebar',
        barrierDismissible: true,
        barrierColor: const Color(0x800F2746),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          final safeTop = MediaQuery.paddingOf(dialogContext).top;
          final safeBottom = MediaQuery.paddingOf(dialogContext).bottom;
          final screenWidth = MediaQuery.sizeOf(dialogContext).width;
          final sidebarWidth = screenWidth * 0.8;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(dialogContext).pop(),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: TweenAnimationBuilder<Offset>(
                      tween: Tween(
                        begin: const Offset(-1.02, 0),
                        end: Offset.zero,
                      ),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      builder: (context, offset, child) {
                        return FractionalTranslation(
                          translation: offset,
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: sidebarWidth,
                        height: double.infinity,
                        child: SocialSidebarPanel(
                          user: user,
                          safeTopInset: safeTop,
                          safeBottomInset: safeBottom,
                          onDashboardTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialDashboard);
                          },
                          onAccountsTap: () =>
                              Navigator.of(dialogContext).pop(),
                          onCreateTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialCreate);
                          },
                          onCreativesTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialCreatives);
                          },
                          onCalendarTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialCalendar);
                          },
                          onSchedulerTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialScheduler);
                          },
                          onPostsTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialPosts);
                          },
                          onAnalyticsTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialAnalytics);
                          },
                          onProfileTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialProfile);
                          },
                          onPaymentTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.payment);
                          },
                          onSupportTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.toNamed(AppRoutes.support);
                          },
                          onCollapseTap: () =>
                              Navigator.of(dialogContext).pop(),
                          onLogoutTap: () {
                            Navigator.of(dialogContext).pop();
                            _controller.logout();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSidebarOpen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productModeController = Get.isRegistered<ProductModeController>()
        ? Get.find<ProductModeController>()
        : Get.put(ProductModeController(), permanent: true);
    if (!productModeController.isSocialMedia) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        productModeController.selectMode(ProductMode.socialMedia);
      });
    }

    return AuthNavigationShell(
      currentTab: AuthTab.socialAccounts,
      backgroundColor: const Color(0xFFFBFCFF),
      child: Obx(() {
        final user = _controller.currentUser.value;
        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return Obx(
          () => RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () =>
                _socialAccountsController.loadAccounts(refresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SocialAccountsTopBar(onMenuTap: () => _openSidebar(user)),
                  const SizedBox(height: 18),
                  _SocialAccountsHero(
                    onConnectTap: _openConnectOptions,
                    isConnecting:
                        _socialAccountsController.isLaunchingConnect.value,
                  ),
                  const SizedBox(height: 18),
                  _SocialAccountStatsGrid(
                    connectedCount: _socialAccountsController.connectedCount,
                    healthyCount: _socialAccountsController.healthyCount,
                    expiringSoonCount:
                        _socialAccountsController.expiringSoonCount,
                    disconnectedCount:
                        _socialAccountsController.disconnectedCount,
                  ),
                  const SizedBox(height: 18),
                  if (_socialAccountsController.errorMessage.value != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _SocialAccountsErrorBanner(
                        message: _socialAccountsController.errorMessage.value!,
                        onRetry: () => _socialAccountsController.loadAccounts(),
                      ),
                    ),
                  if (_socialAccountsController.isLoading.value)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else ...[
                    _SocialConnectedAccountsSection(
                      accounts: _socialAccountsController.accounts,
                      onReconnect: (account) =>
                          _launchConnectFlow(account.platform),
                      onDisconnect: _handleDisconnect,
                    ),
                    const SizedBox(height: 18),
                    _SocialAvailablePlatformsSection(
                      availablePlatforms:
                          _socialAccountsController.availablePlatforms,
                      isConnecting:
                          _socialAccountsController.isLaunchingConnect.value,
                      connectingPlatform:
                          _socialAccountsController.connectingPlatform.value,
                      onConnect: _launchConnectFlow,
                    ),
                    const SizedBox(height: 18),
                    const _PlatformGrowthStrategiesSection(),
                    const SizedBox(height: 18),
                    const _SocialAccountSecurityCard(),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SocialAccountsLifecycleObserver extends WidgetsBindingObserver {
  _SocialAccountsLifecycleObserver({required this.onResumed});

  final VoidCallback onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}

class SocialCreativesView extends StatefulWidget {
  const SocialCreativesView({super.key});

  @override
  State<SocialCreativesView> createState() => _SocialCreativesViewState();
}

class _SocialCreativesViewState extends State<SocialCreativesView> {
  final OnboardingController _controller = Get.find<OnboardingController>();
  late final SocialCreativesController _creativesController =
      Get.isRegistered<SocialCreativesController>()
      ? Get.find<SocialCreativesController>()
      : Get.put(SocialCreativesController());
  bool _isSidebarOpen = false;
  int _selectedCreativeIndex = 0;
  int _selectedGalleryFilter = 0;
  final TextEditingController _promptController = TextEditingController();
  final Set<String> _selectedPlatforms = <String>{};
  String _selectedAspectRatio = 'Default (1:1 Square)';
  String _selectedImageQuality = 'Good Quality (Wait 15s)';
  String _selectedStyle = 'Modern & Clean';
  String _selectedImageType = 'Realistic Photo';
  String _selectedBusinessType = 'Local Business';
  String _selectedCreativeGoal = 'Boost Engagement';
  Color _selectedThemeColor = const Color(0xFF7B44FF);

  final List<_CreativeTypeOption> _creativeTypes = const [
    _CreativeTypeOption(
      title: 'AI Image\nGenerator',
      assetPath: 'assets/images/AI_Image_Generator.png',
      accent: Color(0xFF6C4EFF),
      glow: Color(0xFFF3EEFF),
    ),
    _CreativeTypeOption(
      title: 'Offer\nBanner',
      assetPath: 'assets/images/Offer_banner1.png',
      accent: Color(0xFF11C98B),
      glow: Color(0xFFE8FFF7),
    ),
    _CreativeTypeOption(
      title: 'Festival\nPost',
      assetPath: 'assets/images/Festival_Post.png',
      accent: Color(0xFFFF9D1D),
      glow: Color(0xFFFFF6E9),
    ),
    _CreativeTypeOption(
      title: 'Review\nCard',
      assetPath: 'assets/images/Review_card.png',
      accent: Color(0xFF2E86FF),
      glow: Color(0xFFEDF5FF),
    ),
    _CreativeTypeOption(
      title: 'Quote\nPost',
      assetPath: 'assets/images/Quote.png',
      accent: Color(0xFF8B5CF6),
      glow: Color(0xFFF5EEFF),
    ),
    _CreativeTypeOption(
      title: 'Product\nShowcase',
      assetPath: 'assets/images/Product_Showcase.png',
      accent: Color(0xFF18B8D8),
      glow: Color(0xFFEAFBFF),
    ),
  ];

  final List<String> _galleryFilters = const [
    'All',
    'Images',
    'Banners',
    'Festival',
    'Review Cards',
    'Quotes',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _creativesController.loadCreatives();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  String _selectedCreativeTypeKey() {
    switch (_selectedCreativeIndex) {
      case 1:
        return 'offer_banner';
      case 2:
        return 'festival_post';
      case 3:
        return 'review_card';
      case 4:
        return 'quote_post';
      case 5:
        return 'product_showcase';
      default:
        return 'ai_image';
    }
  }

  String _hexFromColor(Color color) =>
      '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  List<String> _selectedPlatformPayload() {
    if (_selectedPlatforms.contains('all')) {
      return const ['facebook', 'instagram', 'linkedin'];
    }
    return _selectedPlatforms.toList(growable: false);
  }

  String? _galleryFilterType(int index) {
    if (index < 0 || index >= _galleryFilters.length) {
      return null;
    }
    switch (_galleryFilters[index]) {
      case 'Images':
        return 'ai_image';
      case 'Banners':
        return 'offer_banner';
      case 'Festival':
        return 'festival_post';
      case 'Review Cards':
        return 'review_card';
      case 'Quotes':
        return 'quote_post';
      default:
        return null;
    }
  }

  Future<void> _generateCreative() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      Get.snackbar(
        'Add a prompt',
        'Describe the creative you want AI to generate.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    try {
      await _creativesController.generateCreative(
        creativeType: _selectedCreativeTypeKey(),
        prompt: prompt,
        platforms: _selectedPlatformPayload(),
        aspectRatio: _selectedAspectRatio,
        imageQuality: _selectedImageQuality,
        style: _selectedStyle,
        imageType: _selectedImageType,
        businessType: _selectedBusinessType,
        creativeGoal: _selectedCreativeGoal,
        colorTheme: _hexFromColor(_selectedThemeColor),
      );
      if (!mounted) return;
      setState(() {
        _selectedGalleryFilter = 0;
      });
      Get.snackbar(
        'Creative generated',
        'Your new creative is now available in the gallery.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } catch (error) {
      Get.snackbar(
        'Generation failed',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  Future<void> _deleteCreative(_DynamicCreativeGalleryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x260F172A),
                  blurRadius: 26,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEEF1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFE11D48),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Delete this creative?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF0F172A),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is a two-step confirmation. The image will be removed from your VisibloAI gallery.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF64748B),
                    fontSize: 12.8,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Keep',
                          style: GoogleFonts.manrope(
                            color: const Color(0xFF334155),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          backgroundColor: const Color(0xFFE11D48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          'Yes, delete',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirmed != true) return;

    try {
      await _creativesController.deleteCreative(item.id);
      Get.snackbar(
        'Creative deleted',
        'The creative was removed successfully.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } catch (error) {
      Get.snackbar(
        'Delete failed',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  Future<void> _downloadCreativeImage(_DynamicCreativeGalleryItem item) async {
    final uri = Uri.tryParse(item.image);
    if (uri == null || !uri.hasScheme) {
      Get.snackbar(
        'Image unavailable',
        'This creative does not have a downloadable image URL.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    try {
      Get.snackbar(
        'Downloading creative',
        'Saving image to your device...',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      );

      final response = await dio.Dio().get<List<int>>(
        item.image,
        options: dio.Options(responseType: dio.ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Image file is empty.');
      }

      final extension = _creativeImageExtension(uri, response);
      final fileName =
          'visiblo_creative_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final directory =
          await getDownloadsDirectory() ??
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      Get.snackbar(
        'Creative downloaded',
        fileName,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        mainButton: TextButton(
          onPressed: () => OpenFilex.open(file.path),
          child: const Text('Open'),
        ),
      );
    } catch (error) {
      Get.snackbar(
        'Download failed',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  String _creativeImageExtension(Uri uri, dio.Response<List<int>> response) {
    final path = uri.path.toLowerCase();
    if (path.endsWith('.png')) return 'png';
    if (path.endsWith('.webp')) return 'webp';
    if (path.endsWith('.jpeg')) return 'jpg';
    if (path.endsWith('.jpg')) return 'jpg';
    final contentType =
        response.headers.value(dio.Headers.contentTypeHeader)?.toLowerCase() ??
        '';
    if (contentType.contains('png')) return 'png';
    if (contentType.contains('webp')) return 'webp';
    return 'jpg';
  }

  void _showFullCreative(_DynamicCreativeGalleryItem item) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xB30F172A),
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.225,
                      child: _CreativeImage(
                        image: item.image,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x260F2746),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: Color(0xFF17213B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF111827),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.type,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF7A87A4),
                                fontSize: 12.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _CreativeGalleryActionButton(
                        icon: Icons.download_rounded,
                        color: const Color(0xFF62708C),
                        onTap: () => _downloadCreativeImage(item),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSidebar(TestAccount user) async {
    if (_isSidebarOpen) {
      return;
    }
    setState(() => _isSidebarOpen = true);
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierLabel: 'Social sidebar',
        barrierDismissible: true,
        barrierColor: const Color(0x800F2746),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          final safeTop = MediaQuery.paddingOf(dialogContext).top;
          final safeBottom = MediaQuery.paddingOf(dialogContext).bottom;
          final screenWidth = MediaQuery.sizeOf(dialogContext).width;
          final sidebarWidth = screenWidth * 0.8;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(dialogContext).pop(),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: TweenAnimationBuilder<Offset>(
                      tween: Tween(
                        begin: const Offset(-1.02, 0),
                        end: Offset.zero,
                      ),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      builder: (context, offset, child) {
                        return FractionalTranslation(
                          translation: offset,
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: sidebarWidth,
                        height: double.infinity,
                        child: SocialSidebarPanel(
                          user: user,
                          safeTopInset: safeTop,
                          safeBottomInset: safeBottom,
                          onDashboardTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialDashboard);
                          },
                          onAccountsTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialAccounts);
                          },
                          onCreateTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialCreate);
                          },
                          onCreativesTap: () =>
                              Navigator.of(dialogContext).pop(),
                          onCalendarTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialCalendar);
                          },
                          onSchedulerTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialScheduler);
                          },
                          onPostsTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialPosts);
                          },
                          onAnalyticsTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialAnalytics);
                          },
                          onProfileTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialProfile);
                          },
                          onPaymentTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.payment);
                          },
                          onSupportTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.toNamed(AppRoutes.support);
                          },
                          onCollapseTap: () =>
                              Navigator.of(dialogContext).pop(),
                          onLogoutTap: () {
                            Navigator.of(dialogContext).pop();
                            _controller.logout();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSidebarOpen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productModeController = Get.isRegistered<ProductModeController>()
        ? Get.find<ProductModeController>()
        : Get.put(ProductModeController(), permanent: true);
    if (!productModeController.isSocialMedia) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        productModeController.selectMode(ProductMode.socialMedia);
      });
    }

    return AuthNavigationShell(
      currentTab: AuthTab.socialCreate,
      backgroundColor: const Color(0xFFFBFCFF),
      child: Obx(() {
        final user = _controller.currentUser.value;
        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _creativesController.loadIfBusinessChanged();
        });
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SocialCreateTopBar(onMenuTap: () => _openSidebar(user)),
              const SizedBox(height: 14),
              const Text(
                'Creatives',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF111827),
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.45,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create and manage social media creatives.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF7180A3),
                  fontSize: 14.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Choose a Creative Type',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF0F1737),
                  fontSize: 17.6,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _creativeTypes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (context, index) {
                  final item = _creativeTypes[index];
                  final isSelected = index == _selectedCreativeIndex;
                  return _CreativeTypeCard(
                    option: item,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedCreativeIndex = index;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 14),
              Obx(
                () => _CreativePromptCard(
                  promptController: _promptController,
                  selectedType: _creativeTypes[_selectedCreativeIndex].title
                      .replaceAll('\n', ' '),
                  selectedPlatforms: _selectedPlatforms,
                  onPlatformTap: (platform) {
                    setState(() {
                      if (platform == 'all') {
                        if (_selectedPlatforms.contains('all')) {
                          _selectedPlatforms.remove('all');
                        } else {
                          _selectedPlatforms
                            ..clear()
                            ..add('all');
                        }
                      } else {
                        _selectedPlatforms.remove('all');
                        if (_selectedPlatforms.contains(platform)) {
                          _selectedPlatforms.remove(platform);
                        } else {
                          _selectedPlatforms.add(platform);
                        }
                      }
                    });
                  },
                  selectedAspectRatio: _selectedAspectRatio,
                  onAspectRatioSelected: (value) {
                    setState(() {
                      _selectedAspectRatio = value;
                    });
                  },
                  selectedImageQuality: _selectedImageQuality,
                  onImageQualitySelected: (value) {
                    setState(() {
                      _selectedImageQuality = value;
                    });
                  },
                  isGenerating: _creativesController.isGenerating.value,
                  onGenerate: _generateCreative,
                ),
              ),
              const SizedBox(height: 14),
              _CreativeSettingsCard(
                selectedStyle: _selectedStyle,
                onStyleSelected: (value) {
                  setState(() {
                    _selectedStyle = value;
                  });
                },
                selectedImageType: _selectedImageType,
                onImageTypeSelected: (value) {
                  setState(() {
                    _selectedImageType = value;
                  });
                },
                selectedBusinessType: _selectedBusinessType,
                onBusinessTypeSelected: (value) {
                  setState(() {
                    _selectedBusinessType = value;
                  });
                },
                selectedCreativeGoal: _selectedCreativeGoal,
                onCreativeGoalSelected: (value) {
                  setState(() {
                    _selectedCreativeGoal = value;
                  });
                },
                selectedThemeColor: _selectedThemeColor,
                onThemeSelected: (value) {
                  setState(() {
                    _selectedThemeColor = value;
                  });
                },
              ),
              const SizedBox(height: 18),
              Obx(
                () => _CreativeGallerySection(
                  filters: _galleryFilters,
                  selectedFilterIndex: _selectedGalleryFilter,
                  creatives: _creativesController.creatives.toList(),
                  isLoading: _creativesController.isLoading.value,
                  errorMessage: _creativesController.errorMessage.value,
                  onFilterSelected: (index) {
                    setState(() {
                      _selectedGalleryFilter = index;
                    });
                    _creativesController.loadCreatives(
                      type: _galleryFilterType(index),
                    );
                  },
                  onRetry: () => _creativesController.loadCreatives(
                    type: _galleryFilterType(_selectedGalleryFilter),
                  ),
                  onViewItem: _showFullCreative,
                  onDownloadItem: _downloadCreativeImage,
                  onDeleteItem: _deleteCreative,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class SocialCreateView extends StatefulWidget {
  const SocialCreateView({super.key});

  @override
  State<SocialCreateView> createState() => _SocialCreateViewState();
}

class _SocialCreateViewState extends State<SocialCreateView> {
  final OnboardingController _controller = Get.find<OnboardingController>();
  late final SocialCreateController _createController =
      Get.isRegistered<SocialCreateController>()
      ? Get.find<SocialCreateController>()
      : Get.put(SocialCreateController());
  late final SocialAccountsController _accountsController =
      Get.isRegistered<SocialAccountsController>()
      ? Get.find<SocialAccountsController>()
      : Get.put(SocialAccountsController());
  late final SocialSchedulerController _schedulerController =
      Get.isRegistered<SocialSchedulerController>()
      ? Get.find<SocialSchedulerController>()
      : Get.put(SocialSchedulerController());
  late final TextEditingController _topicController;
  bool _isSidebarOpen = false;
  final bool _includeVisual = true;
  final bool _includeHashtags = true;
  final bool _addEmojis = true;
  final String _selectedTone = 'Friendly';
  String _selectedLanguage = 'Hindi';
  final String _selectedAudience = 'Local Business Owners';
  String _selectedTextLength = 'Short (2-3 lines)';
  String _selectedQuality = 'Good (10s)';
  String _selectedPostType = 'Festival';
  final String _selectedStyle = 'Modern & Clean';
  final String _selectedImageType = 'Realistic Photo';
  final String _selectedBusinessType = 'Local Business';
  String _selectedCreativeGoal = 'Boost Engagement';
  Color _selectedThemeColor = const Color(0xFF5A52FF);
  String? _pendingDraftIdToOpen;
  bool _handledInitialDraftOpen = false;

  String _hexFromColor(Color color) =>
      '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  Future<void> _generateContent() async {
    FocusScope.of(context).unfocus();
    await _createController.generatePosts(
      topic: _topicController.text,
      tone: _selectedTone,
      language: _selectedLanguage,
      textLength: _selectedTextLength,
      audience: _selectedAudience,
      quality: _selectedQuality,
      includeImage: _includeVisual,
      includeHashtags: _includeHashtags,
      addEmojis: _addEmojis,
      style: _selectedStyle,
      imageType: _selectedImageType,
      businessType: _selectedBusinessType,
      creativeGoal: _selectedCreativeGoal,
      colorTheme: _hexFromColor(_selectedThemeColor),
    );
  }

  GeneratedSocialPost? get _previewPost {
    if (_createController.generatedPosts.isEmpty) {
      return null;
    }
    return _createController.generatedPosts.first;
  }

  Future<void> _postNowFromGenerator() async {
    if (_createController.isGenerating.value ||
        _createController.publishingPlatform.value != null) {
      return;
    }
    if (_createController.generatedPosts.isEmpty) {
      return;
    }
    final posts = List<GeneratedSocialPost>.from(
      _createController.generatedPosts,
    );
    for (final post in posts.where((post) => !post.isPublished)) {
      await _createController.publishPost(post);
    }
  }

  Future<void> _openPublishPlatformsSheet(GeneratedSocialPost post) async {
    final connectedPlatforms = _accountsController.connectedPlatforms
        .map((item) => item.toLowerCase())
        .toSet();
    final availablePlatforms = <String>[
      if (connectedPlatforms.contains('instagram')) 'instagram',
      if (connectedPlatforms.contains('facebook')) 'facebook',
      if (connectedPlatforms.contains('linkedin')) 'linkedin',
    ];

    if (availablePlatforms.isEmpty) {
      _createController.errorMessage.value =
          'Connect at least one social platform before publishing.';
      return;
    }

    final initialPlatform = _normalizePublishPlatform(post.platform);
    final selectedPlatforms = <String>{
      availablePlatforms.contains(initialPlatform)
          ? initialPlatform
          : availablePlatforms.first,
    };

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void togglePlatform(String platform) {
              setSheetState(() {
                if (platform == 'all') {
                  if (selectedPlatforms.contains('all')) {
                    selectedPlatforms
                      ..remove('all')
                      ..clear()
                      ..add(
                        availablePlatforms.contains(initialPlatform)
                            ? initialPlatform
                            : availablePlatforms.first,
                      );
                    return;
                  }
                  selectedPlatforms
                    ..clear()
                    ..add('all');
                  return;
                }

                selectedPlatforms.remove('all');
                if (selectedPlatforms.contains(platform)) {
                  if (selectedPlatforms.length > 1) {
                    selectedPlatforms.remove(platform);
                  }
                  return;
                }
                selectedPlatforms.add(platform);
              });
            }

            return _PublishPlatformsSheet(
              selectedPlatforms: selectedPlatforms,
              availablePlatforms: availablePlatforms,
              onTogglePlatform: togglePlatform,
              onConfirm: () {
                final payload = selectedPlatforms.contains('all')
                    ? availablePlatforms
                    : selectedPlatforms.toList(growable: false);
                Navigator.of(sheetContext).pop(payload);
              },
            );
          },
        );
      },
    );

    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    await _createController.publishPost(post, platforms: result);
  }

  String _normalizePublishPlatform(String platform) {
    final value = platform.toLowerCase();
    if (value.contains('facebook')) return 'facebook';
    if (value.contains('linkedin')) return 'linkedin';
    return 'instagram';
  }

  Future<void> _editGeneratedPost(GeneratedSocialPost post) async {
    await _showSocialPostEditDialog(
      context: context,
      title: 'Edit ${post.platform} Post',
      initialCaption: post.content.caption,
      initialHashtags: post.content.hashtags,
      initialImageUrl: post.content.imageUrl,
      initialTextLength: _selectedTextLength,
      initialImageQuality: _qualityKeyFromLabel(_selectedQuality),
      onRegenerateText: (textLength) {
        return _createController.regenerateText(
          post: post,
          topic: _topicController.text,
          tone: _selectedTone,
          language: _selectedLanguage,
          textLength: textLength,
        );
      },
      onRegenerateImage: (imageQuality, cancelToken) {
        return _createController.regenerateImage(
          post: post,
          topic: _topicController.text,
          tone: _selectedTone,
          language: _selectedLanguage,
          textLength: _selectedTextLength,
          imageQuality: imageQuality,
          cancelToken: cancelToken,
        );
      },
      onSave: (caption, hashtags, imageUrl) {
        return _createController.saveEditedPost(
          post: post,
          caption: caption,
          hashtags: hashtags,
          imageUrl: imageUrl,
        );
      },
    );
  }

  Future<void> _confirmDeleteGeneratedPost(GeneratedSocialPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete saved draft?',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF101A35),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '${post.platform} draft will be removed from the AI generator history.',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF64728F),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFE83E5A)),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      await _createController.deleteGeneratedDraft(post);
    } catch (_) {}
  }

  SchedulerQueueItem _generatedPostAsQueueItem(GeneratedSocialPost post) {
    return SchedulerQueueItem(
      id: post.id,
      title: post.content.headline?.trim().isNotEmpty == true
          ? post.content.headline!.trim()
          : post.content.caption,
      caption: post.content.caption,
      imageUrl: post.content.imageUrl,
      platforms: <String>[post.platform.toLowerCase()],
      status: 'DRAFT',
      postType: 'POST',
      aiScore: 70,
      scoreLabel: 'Good',
      scoreDesc: 'Ready to schedule',
      createdAt: post.content.createdAt ?? DateTime.now(),
      raw: const {},
    );
  }

  void _showSuggestedScheduleDialogForGenerated(GeneratedSocialPost post) {
    final queuePost = _generatedPostAsQueueItem(post);
    final suggestedTime = _schedulerController.suggestedTimeFor(queuePost);
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xB3000000),
      builder: (dialogContext) {
        return _SchedulerSuggestedDialog(
          suggestedTime: suggestedTime,
          onPickOwn: () {
            Navigator.of(dialogContext).pop();
            _showManualScheduleDialogForGenerated(
              post,
              initialTime: suggestedTime,
            );
          },
          onSchedule: () async {
            Navigator.of(dialogContext).pop();
            await _scheduleGeneratedPostAt(post, suggestedTime);
          },
        );
      },
    );
  }

  void _showManualScheduleDialogForGenerated(
    GeneratedSocialPost post, {
    DateTime? initialTime,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xB3000000),
      builder: (dialogContext) {
        return _SchedulerManualDialog(
          initialDateTime:
              initialTime ??
              _schedulerController.suggestedTimeFor(
                _generatedPostAsQueueItem(post),
              ),
          onBack: () {
            Navigator.of(dialogContext).pop();
            _showSuggestedScheduleDialogForGenerated(post);
          },
          onSchedule: (scheduledAt) async {
            Navigator.of(dialogContext).pop();
            await _scheduleGeneratedPostAt(post, scheduledAt);
          },
        );
      },
    );
  }

  Future<void> _scheduleGeneratedPostAt(
    GeneratedSocialPost post,
    DateTime scheduledAt,
  ) async {
    try {
      await _schedulerController.schedulePost(
        _generatedPostAsQueueItem(post),
        scheduledAt,
      );
      await _createController.loadDrafts(force: true);
      _createController.successMessage.value =
          '${post.platform} post scheduled for ${_formatSchedulerDateTime(scheduledAt)}.';
    } catch (error) {
      _createController.errorMessage.value = error.toString().replaceFirst(
        'Exception: ',
        '',
      );
    }
  }

  Future<void> _handleInitialCreateArguments() async {
    if (_handledInitialDraftOpen) return;
    _handledInitialDraftOpen = true;

    final args = Get.arguments;
    if (args is! Map) return;

    final map = Map<String, dynamic>.from(args);
    final incomingTopic = (map['topic'] ?? '').toString().trim();
    final incomingDraftId = (map['openDraftId'] ?? '').toString().trim();

    if (incomingTopic.isNotEmpty) {
      _topicController.text = incomingTopic;
      _topicController.selection = TextSelection.collapsed(
        offset: _topicController.text.length,
      );
    }

    if (incomingDraftId.isEmpty) return;
    _pendingDraftIdToOpen = incomingDraftId;

    await _createController.loadDrafts(force: true);
    if (!mounted) return;
    _openPendingDraftIfNeeded();
  }

  void _openPendingDraftIfNeeded() {
    final draftId = _pendingDraftIdToOpen;
    if (draftId == null || draftId.isEmpty) return;

    final match = _createController.generatedPosts.firstWhereOrNull(
      (post) => post.id == draftId,
    );
    if (match == null) return;

    _pendingDraftIdToOpen = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _editGeneratedPost(match);
    });
  }

  Future<void> _pickCustomThemeColor() async {
    final currentHsv = HSVColor.fromColor(_selectedThemeColor);
    double hue = currentHsv.hue;
    double saturation = currentHsv.saturation;
    double value = currentHsv.value;
    const hueColors = [
      Color(0xFFFF0000),
      Color(0xFFFFFF00),
      Color(0xFF00FF00),
      Color(0xFF00FFFF),
      Color(0xFF0000FF),
      Color(0xFFFF00FF),
      Color(0xFFFF0000),
    ];

    final picked = await showModalBottomSheet<Color>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final preview = HSVColor.fromAHSV(
              1,
              hue,
              saturation,
              value,
            ).toColor();

            return SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x220F2746),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pick Theme Color',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: preview,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x180F2746),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _hexFromColor(preview),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFF1B2745),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Choose any theme color for your creative.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFF667392),
                                  fontSize: 12.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final boxSize = constraints.maxWidth;
                        return Column(
                          children: [
                            GestureDetector(
                              onPanDown: (details) {
                                final dx = details.localPosition.dx.clamp(
                                  0.0,
                                  boxSize,
                                );
                                final dy = details.localPosition.dy.clamp(
                                  0.0,
                                  boxSize,
                                );
                                setModalState(() {
                                  saturation = dx / boxSize;
                                  value = 1 - (dy / boxSize);
                                });
                              },
                              onPanUpdate: (details) {
                                final dx = details.localPosition.dx.clamp(
                                  0.0,
                                  boxSize,
                                );
                                final dy = details.localPosition.dy.clamp(
                                  0.0,
                                  boxSize,
                                );
                                setModalState(() {
                                  saturation = dx / boxSize;
                                  value = 1 - (dy / boxSize);
                                });
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: boxSize,
                                    height: boxSize,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.topRight,
                                        colors: [
                                          Colors.white,
                                          HSVColor.fromAHSV(
                                            1,
                                            hue,
                                            1,
                                            1,
                                          ).toColor(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: boxSize,
                                    height: boxSize,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black,
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: saturation * boxSize - 10,
                                    top: (1 - value) * boxSize - 10,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x260F2746),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: const LinearGradient(
                                      colors: hueColors,
                                    ),
                                  ),
                                ),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.transparent,
                                    inactiveTrackColor: Colors.transparent,
                                    overlayColor: Colors.transparent,
                                    thumbColor: Colors.white,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 9,
                                    ),
                                  ),
                                  child: Slider(
                                    value: hue,
                                    min: 0,
                                    max: 360,
                                    onChanged: (next) {
                                      setModalState(() => hue = next);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: const BorderSide(color: Color(0xFFDDE7F2)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF1B2745),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(preview),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xFF184A96),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedThemeColor = picked);
    }
  }

  @override
  void initState() {
    super.initState();
    _topicController =
        TextEditingController(
          text:
              'Special weekend offer for all our customers.\n50% off on website development services.',
        )..addListener(() {
          if (mounted) {
            setState(() {});
          }
        });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _createController.loadDrafts();
      await _accountsController.loadAccounts();
      if (!mounted) return;
      _openPendingDraftIfNeeded();
      await _handleInitialCreateArguments();
    });
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _openSidebar(TestAccount user) async {
    if (_isSidebarOpen) {
      return;
    }
    setState(() => _isSidebarOpen = true);
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierLabel: 'Social sidebar',
        barrierDismissible: true,
        barrierColor: const Color(0x800F2746),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          final safeTop = MediaQuery.paddingOf(dialogContext).top;
          final safeBottom = MediaQuery.paddingOf(dialogContext).bottom;
          final screenWidth = MediaQuery.sizeOf(dialogContext).width;
          final sidebarWidth = screenWidth * 0.8;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(dialogContext).pop(),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: TweenAnimationBuilder<Offset>(
                      tween: Tween(
                        begin: const Offset(-1.02, 0),
                        end: Offset.zero,
                      ),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      builder: (context, offset, child) {
                        return FractionalTranslation(
                          translation: offset,
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: sidebarWidth,
                        height: double.infinity,
                        child: SocialSidebarPanel(
                          user: user,
                          safeTopInset: safeTop,
                          safeBottomInset: safeBottom,
                          onDashboardTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialDashboard);
                          },
                          onAccountsTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialAccounts);
                          },
                          onCreateTap: () => Navigator.of(dialogContext).pop(),
                          onCreativesTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialCreatives);
                          },
                          onCalendarTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialCalendar);
                          },
                          onSchedulerTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialScheduler);
                          },
                          onPostsTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialPosts);
                          },
                          onAnalyticsTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialAnalytics);
                          },
                          onProfileTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialProfile);
                          },
                          onPaymentTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.payment);
                          },
                          onSupportTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.toNamed(AppRoutes.support);
                          },
                          onCollapseTap: () =>
                              Navigator.of(dialogContext).pop(),
                          onLogoutTap: () {
                            Navigator.of(dialogContext).pop();
                            _controller.logout();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSidebarOpen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productModeController = Get.isRegistered<ProductModeController>()
        ? Get.find<ProductModeController>()
        : Get.put(ProductModeController(), permanent: true);
    if (!productModeController.isSocialMedia) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        productModeController.selectMode(ProductMode.socialMedia);
      });
    }

    return AuthNavigationShell(
      currentTab: AuthTab.socialCreate,
      backgroundColor: const Color(0xFFFBFCFF),
      child: Obx(() {
        final user = _controller.currentUser.value;
        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AiGeneratorTopBar(onMenuTap: () => _openSidebar(user)),
              const SizedBox(height: 28),
              const Text(
                'AI Post Generator',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF060B34),
                  fontSize: 26,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.45,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create engaging social media posts with AI.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF243A67),
                  fontSize: 16,
                  height: 1.28,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),
              const _AiGeneratorSectionTitle(
                'What would you like to post about?',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _topicController,
                maxLines: 4,
                minLines: 4,
                maxLength: 300,
                onChanged: (_) => setState(() {}),
                cursorColor: const Color(0xFF075EEB),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF070B2E),
                  fontSize: 16,
                  height: 1.36,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Tell VisibloAI what this post should say.',
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF8792AC),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(color: Color(0xFFD3DDED)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(
                      color: Color(0xFF1768FF),
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_topicController.text.length}/300',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF243A67),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 5,
                    child: _AiQualityPicker(
                      value: _selectedQuality,
                      onSelected: (value) => setState(() {
                        _selectedQuality = value;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _AiFieldLabel('TEXT WORD SIZE'),
                        const SizedBox(height: 7),
                        _AiTextLengthPicker(
                          value: _selectedTextLength,
                          onSelected: (value) => setState(() {
                            _selectedTextLength = value;
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _AiGeneratorSectionTitle('Choose Language'),
              const SizedBox(height: 13),
              _AiLanguageTabs(
                selectedLanguage: _selectedLanguage,
                onSelected: (value) => setState(() {
                  _selectedLanguage = value;
                }),
              ),
              const SizedBox(height: 27),
              const _AiGeneratorSectionTitle('Select Post Type'),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: _AiPostTypeCard(
                      emoji: '🎉',
                      label: 'Festival',
                      selected: _selectedPostType == 'Festival',
                      onTap: () => setState(() {
                        _selectedPostType = 'Festival';
                        _selectedCreativeGoal = 'Boost Engagement';
                      }),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _AiPostTypeCard(
                      emoji: '🏷️',
                      label: 'Offer',
                      selected: _selectedPostType == 'Offer',
                      onTap: () => setState(() {
                        _selectedPostType = 'Offer';
                        _selectedCreativeGoal = 'Drive Sales';
                      }),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _AiPostTypeCard(
                      icon: Icons.article_outlined,
                      label: 'General',
                      selected: _selectedPostType == 'General',
                      onTap: () => setState(() {
                        _selectedPostType = 'General';
                        _selectedCreativeGoal = 'Build Awareness';
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Obx(() {
                final isGenerating = _createController.isGenerating.value;
                final hasPreview = _previewPost != null;
                return _AiPostNowButton(
                  isBusy: isGenerating,
                  icon: isGenerating
                      ? Icons.stop_circle_outlined
                      : Icons.auto_awesome_rounded,
                  label: isGenerating
                      ? 'Stop'
                      : hasPreview
                      ? 'Regenerate Post'
                      : 'Generate Post',
                  onTap: isGenerating
                      ? _createController.stopGeneration
                      : _generateContent,
                );
              }),
              const SizedBox(height: 24),
              _GeneratedSocialPostsSection(
                controller: _createController,
                onPublishPost: _openPublishPlatformsSheet,
                onSchedulePost: _showSuggestedScheduleDialogForGenerated,
                onEditPost: _editGeneratedPost,
                onDeletePost: _confirmDeleteGeneratedPost,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _AiGeneratorTopBar extends StatelessWidget {
  const _AiGeneratorTopBar({required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onMenuTap,
          behavior: HitTestBehavior.opaque,
          child: const AppLogo(iconSize: 48, fontSize: 31),
        ),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.notifications_none_rounded,
                size: 31,
                color: Color(0xFF061044),
              ),
            ),
            Positioned(
              right: 0,
              top: 1,
              child: Container(
                width: 19,
                height: 19,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF2738),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Text(
                  '12',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AiGeneratorSectionTitle extends StatelessWidget {
  const _AiGeneratorSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        color: Color(0xFF070B2E),
        fontSize: 18,
        height: 1.15,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.15,
      ),
    );
  }
}

class _AiFieldLabel extends StatelessWidget {
  const _AiFieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Inter',
        color: Color(0xFF526A96),
        fontSize: 11,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _AiQualityPicker extends StatelessWidget {
  const _AiQualityPicker({required this.value, required this.onSelected});

  final String value;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFD2DCEB)),
      ),
      itemBuilder: (context) =>
          const ['Good (10s)', 'High (20s)', 'Highest (60s)']
              .map(
                (option) => PopupMenuItem<String>(
                  height: 42,
                  value: option,
                  child: Text(
                    option,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF070B2E),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD2DCEB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.star_rounded, size: 21, color: Color(0xFFF3B417)),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quality',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF53658B),
                      fontSize: 10.5,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF070B2E),
                      fontSize: 13,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 21,
              color: Color(0xFF061044),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiTextLengthPicker extends StatelessWidget {
  const _AiTextLengthPicker({required this.value, required this.onSelected});

  final String value;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFD2DCEB)),
      ),
      itemBuilder: (context) =>
          const ['Short (2-3 lines)', 'Medium (4-5 lines)', 'Long (6-8 lines)']
              .map(
                (option) => PopupMenuItem<String>(
                  height: 42,
                  value: option,
                  child: Text(
                    option,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF070B2E),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
      child: Container(
        height: 50,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFD2DCEB)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF070B2E),
                  fontSize: 12.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: Color(0xFF8A97AF),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiLanguageTabs extends StatelessWidget {
  const _AiLanguageTabs({
    required this.selectedLanguage,
    required this.onSelected,
  });

  final String selectedLanguage;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, String value})>[
      (label: 'English', value: 'English'),
      (label: 'हिंदी', value: 'Hindi'),
      (label: 'मराठी', value: 'Marathi'),
    ];
    final moreLanguageLabels = <String, String>{
      'Hinglish': 'Hinglish',
      'Gujarati': 'ગુજરાતી',
      'Bengali': 'বাংলা',
      'Telugu': 'తెలుగు',
      'Punjabi': 'ਪੰਜਾਬੀ',
    };
    final moreLabel = moreLanguageLabels[selectedLanguage] ?? 'More';

    return Container(
      height: 51,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFD2DCEB)),
      ),
      child: Row(
        children: [
          for (final item in items) ...[
            Expanded(
              child: _AiLanguageTab(
                label: item.label,
                selected: selectedLanguage == item.value,
                onTap: () => onSelected(item.value),
              ),
            ),
            if (item != items.last)
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: Color(0xFFD2DCEB),
              ),
          ],
          Expanded(
            child: PopupMenuButton<String>(
              onSelected: onSelected,
              color: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFD2DCEB)),
              ),
              itemBuilder: (context) {
                const languages = <({String label, String value})>[
                  (label: 'Hinglish', value: 'Hinglish'),
                  (label: 'ગુજરાતી', value: 'Gujarati'),
                  (label: 'বাংলা', value: 'Bengali'),
                  (label: 'తెలుగు', value: 'Telugu'),
                  (label: 'ਪੰਜਾਬੀ', value: 'Punjabi'),
                ];
                return languages
                    .map(
                      (language) => PopupMenuItem<String>(
                        height: 42,
                        value: language.value,
                        child: Text(
                          language.label,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF070B2E),
                            fontSize: 14,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    moreLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF070B2E),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiLanguageTab extends StatelessWidget {
  const _AiLanguageTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF075EFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            color: selected ? Colors.white : const Color(0xFF070B2E),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AiPostTypeCard extends StatelessWidget {
  const _AiPostTypeCard({
    required this.label,
    required this.selected,
    required this.onTap,
    this.emoji,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? emoji;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? const Color(0xFF075EFF) : const Color(0xFFD2DCEB),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x100F2746),
              blurRadius: 13,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (emoji != null)
              Text(emoji!, style: const TextStyle(fontSize: 23))
            else
              Icon(icon, size: 24, color: const Color(0xFF070B2E)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF070B2E),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiSecondaryActionButton extends StatelessWidget {
  const _AiSecondaryActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF075EFF),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFD2DCEB)),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 22),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AiPostTargetsRow extends StatelessWidget {
  const _AiPostTargetsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _AiPostTarget(
            assetPath: 'assets/images/google-my-business-icon.png',
            label: 'Google Business\nProfile',
            iconSize: 48,
          ),
        ),
        Expanded(
          child: _AiPostTarget(
            assetPath: 'assets/images/facebook.png',
            label: 'Facebook',
            iconSize: 49,
          ),
        ),
        Expanded(
          child: _AiPostTarget(
            assetPath: 'assets/images/instagram.png',
            label: 'Instagram',
            iconSize: 49,
          ),
        ),
        Expanded(
          child: _AiPostTarget(
            assetPath: 'assets/images/link.png',
            label: 'LinkedIn',
            iconSize: 45,
          ),
        ),
      ],
    );
  }
}

class _AiPostTarget extends StatelessWidget {
  const _AiPostTarget({
    required this.assetPath,
    required this.label,
    required this.iconSize,
  });

  final String assetPath;
  final String label;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Image.asset(
              assetPath,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF22B573),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF061044),
            fontSize: 12.5,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AiPostNowButton extends StatelessWidget {
  const _AiPostNowButton({
    required this.isBusy,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool isBusy;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isBusy
                ? const [Color(0xFF7E93B6), Color(0xFF7E93B6)]
                : const [Color(0xFF063B73), Color(0xFF063B73)],
          ),
          borderRadius: BorderRadius.circular(9),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26063B73),
              blurRadius: 18,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 27, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _qualityKeyFromLabel(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('highest')) return 'highest';
  if (normalized.contains('high')) return 'high';
  return 'good';
}

class _GeneratedSocialPostsSection extends StatefulWidget {
  const _GeneratedSocialPostsSection({
    required this.controller,
    required this.onPublishPost,
    required this.onSchedulePost,
    required this.onEditPost,
    required this.onDeletePost,
  });

  final SocialCreateController controller;
  final ValueChanged<GeneratedSocialPost> onPublishPost;
  final ValueChanged<GeneratedSocialPost> onSchedulePost;
  final ValueChanged<GeneratedSocialPost> onEditPost;
  final ValueChanged<GeneratedSocialPost> onDeletePost;

  @override
  State<_GeneratedSocialPostsSection> createState() =>
      _GeneratedSocialPostsSectionState();
}

class _GeneratedSocialPostsSectionState
    extends State<_GeneratedSocialPostsSection> {
  static const int _pageSize = 20;
  int _currentPage = 0;

  void _goToPage(int page) {
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final posts = widget.controller.generatedPosts;
      final error = widget.controller.errorMessage.value;
      final success = widget.controller.successMessage.value;
      final totalPages = math.max(1, (posts.length / _pageSize).ceil());
      final safePage = posts.isEmpty
          ? 0
          : _currentPage.clamp(0, totalPages - 1).toInt();
      if (safePage != _currentPage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _currentPage = safePage);
          }
        });
      }
      final startIndex = safePage * _pageSize;
      final endIndex = math.min(startIndex + _pageSize, posts.length);
      final pagedPosts = posts.skip(startIndex).take(_pageSize).toList();

      if (posts.isEmpty &&
          error == null &&
          success == null &&
          !widget.controller.isLoadingDrafts.value) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EEF5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F2746),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (error != null) ...[
              _CreateStatusBanner(
                message: error,
                color: const Color(0xFFE83E5A),
                icon: Icons.error_outline_rounded,
              ),
              if (posts.isNotEmpty) const SizedBox(height: 12),
            ],
            if (success != null) ...[
              _CreateStatusBanner(
                message: success,
                color: const Color(0xFF18B884),
                icon: Icons.check_circle_outline_rounded,
              ),
              if (posts.isNotEmpty) const SizedBox(height: 12),
            ],
            if (posts.isNotEmpty ||
                widget.controller.isLoadingDrafts.value) ...[
              Row(
                children: const [
                  Expanded(
                    child: Text(
                      'Generated Content',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF101A35),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _CreateSavedDraftChip(),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.controller.isLoadingDrafts.value && posts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                  ),
                )
              else
                ...pagedPosts.map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GeneratedSocialPostCard(
                      post: post,
                      isPublishing:
                          widget.controller.publishingPlatform.value ==
                          post.platform,
                      onPublish: () => widget.onPublishPost(post),
                      onSchedule: post.isPublished
                          ? null
                          : () => widget.onSchedulePost(post),
                      onEdit: post.isPublished
                          ? null
                          : () => widget.onEditPost(post),
                      onDelete: post.isPublished
                          ? null
                          : () => widget.onDeletePost(post),
                    ),
                  ),
                ),
              if (posts.length > _pageSize)
                _GeneratedPostsPagination(
                  currentPage: safePage,
                  totalPages: totalPages,
                  startItem: startIndex + 1,
                  endItem: endIndex,
                  totalItems: posts.length,
                  onPrevious: safePage == 0
                      ? null
                      : () => _goToPage(safePage - 1),
                  onNext: safePage >= totalPages - 1
                      ? null
                      : () => _goToPage(safePage + 1),
                ),
            ],
          ],
        ),
      );
    });
  }
}

class _PublishPlatformsSheet extends StatelessWidget {
  const _PublishPlatformsSheet({
    required this.selectedPlatforms,
    required this.availablePlatforms,
    required this.onTogglePlatform,
    required this.onConfirm,
  });

  final Set<String> selectedPlatforms;
  final List<String> availablePlatforms;
  final ValueChanged<String> onTogglePlatform;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedPlatforms.contains('all');
    final options = <({String key, String label, String asset})>[
      (
        key: 'instagram',
        label: 'Instagram',
        asset: 'assets/images/instagram.png',
      ),
      (key: 'facebook', label: 'Facebook', asset: 'assets/images/facebook.png'),
      (key: 'linkedin', label: 'LinkedIn', asset: 'assets/images/link.png'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9E2EE),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Where do you want to publish?',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF101A35),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose one or more connected social platforms for this post.',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF66748E),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((option) {
              final isAvailable = availablePlatforms.contains(option.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PublishPlatformOptionTile(
                  title: option.label,
                  assetPath: option.asset,
                  selected: selectedPlatforms.contains(option.key),
                  disabled: !isAvailable || allSelected,
                  onTap: isAvailable && !allSelected
                      ? () => onTogglePlatform(option.key)
                      : null,
                ),
              );
            }),
            _PublishPlatformOptionTile(
              title: 'All',
              icon: Icons.public_rounded,
              selected: allSelected,
              disabled: false,
              onTap: () => onTogglePlatform('all'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A3F85),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Publish now',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublishPlatformOptionTile extends StatelessWidget {
  const _PublishPlatformOptionTile({
    required this.title,
    required this.selected,
    required this.disabled,
    required this.onTap,
    this.assetPath,
    this.icon,
  });

  final String title;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;
  final String? assetPath;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFF0A3F85)
        : const Color(0xFFDDE6F0);
    final backgroundColor = selected
        ? const Color(0xFFF0F7FF)
        : disabled
        ? const Color(0xFFF7F9FC)
        : Colors.white;
    final titleColor = disabled
        ? const Color(0xFF9AA7BA)
        : const Color(0xFF111827);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE1E9F2)),
              ),
              padding: const EdgeInsets.all(8),
              child: assetPath != null
                  ? Opacity(
                      opacity: disabled ? 0.45 : 1,
                      child: Image.asset(assetPath!, fit: BoxFit.contain),
                    )
                  : Icon(
                      icon,
                      color: disabled
                          ? const Color(0xFF9AA7BA)
                          : const Color(0xFF0A3F85),
                      size: 20,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: titleColor,
                  fontSize: 14.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF0A3F85) : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF0A3F85)
                      : const Color(0xFFCAD5E3),
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateStatusBanner extends StatelessWidget {
  const _CreateStatusBanner({
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Inter',
                color: color,
                fontSize: 12.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateSavedDraftChip extends StatelessWidget {
  const _CreateSavedDraftChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FAF2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Auto-saved',
        style: TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF09A86F),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GeneratedPostsPagination extends StatelessWidget {
  const _GeneratedPostsPagination({
    required this.currentPage,
    required this.totalPages,
    required this.startItem,
    required this.endItem,
    required this.totalItems,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final int startItem;
  final int endItem;
  final int totalItems;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$startItem-$endItem of $totalItems posts',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF61708E),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _GeneratedPostsPageButton(
            icon: Icons.chevron_left_rounded,
            onTap: onPrevious,
          ),
          const SizedBox(width: 8),
          Text(
            '${currentPage + 1}/$totalPages',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF0A3F85),
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          _GeneratedPostsPageButton(
            icon: Icons.chevron_right_rounded,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _GeneratedPostsPageButton extends StatelessWidget {
  const _GeneratedPostsPageButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFEAF3FF) : const Color(0xFFF3F6FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? const Color(0xFFBFD3EC) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? const Color(0xFF0A3F85) : const Color(0xFF9AA7BA),
        ),
      ),
    );
  }
}

class _GeneratedSocialPostCard extends StatelessWidget {
  const _GeneratedSocialPostCard({
    required this.post,
    required this.isPublishing,
    required this.onPublish,
    this.onSchedule,
    this.onEdit,
    this.onDelete,
  });

  final GeneratedSocialPost post;
  final bool isPublishing;
  final VoidCallback onPublish;
  final VoidCallback? onSchedule;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final content = post.content;
    final hasImage = (content.imageUrl ?? '').trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: post.isPublished
              ? const Color(0xFFBDEFD9)
              : const Color(0xFFE0E7F2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                Image.asset(
                  _createPlatformLogo(post.platform),
                  width: 28,
                  height: 28,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '${post.platform} Post',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF101A35),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: post.isPublished
                        ? const Color(0xFFE8FAF2)
                        : const Color(0xFFF1F5FA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    post.isPublished ? 'Published' : 'Draft',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: post.isPublished
                          ? const Color(0xFF09A86F)
                          : const Color(0xFF61708E),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (onEdit != null) ...[
                  const SizedBox(width: 8),
                  _GeneratedPostActionIcon(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF315C8C),
                    onTap: onEdit!,
                  ),
                ],
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  _GeneratedPostActionIcon(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFE83E5A),
                    onTap: onDelete!,
                  ),
                ],
              ],
            ),
          ),
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: double.infinity,
                height: 170,
                child: _analyticsImageWidget(
                  content.imageUrl ?? '',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.caption.isEmpty
                      ? 'No caption generated yet.'
                      : content.caption,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF1B2745),
                    fontSize: 13.2,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
                if (content.hashtags.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    content.hashtags,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF4F46E5),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: post.isPublished || isPublishing
                            ? null
                            : onSchedule,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: post.isPublished
                                  ? const Color(0xFFD9E3F0)
                                  : const Color(0xFF0A3F85),
                              width: 1.4,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                color: post.isPublished
                                    ? const Color(0xFF9AA7BA)
                                    : const Color(0xFF0A3F85),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Schedule for Later',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: post.isPublished
                                        ? const Color(0xFF9AA7BA)
                                        : const Color(0xFF0A3F85),
                                    fontSize: 12.6,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: post.isPublished || isPublishing
                            ? null
                            : onPublish,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: post.isPublished
                                ? const Color(0xFFE8FAF2)
                                : const Color(0xFF0A3F85),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isPublishing)
                                const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              if (isPublishing) const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isPublishing
                                      ? 'Publishing...'
                                      : post.isPublished
                                      ? 'Published'
                                      : 'Publish Now',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: post.isPublished
                                        ? const Color(0xFF09A86F)
                                        : Colors.white,
                                    fontSize: 13.2,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratedPostActionIcon extends StatelessWidget {
  const _GeneratedPostActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

Future<void> _showSocialPostEditDialog({
  required BuildContext context,
  required String title,
  required String initialCaption,
  required String initialHashtags,
  required String? initialImageUrl,
  required String initialTextLength,
  required String initialImageQuality,
  required Future<SocialContentResult> Function(String textLength)
  onRegenerateText,
  required Future<SocialContentResult> Function(
    String imageQuality,
    dio.CancelToken cancelToken,
  )
  onRegenerateImage,
  required Future<void> Function(
    String caption,
    String hashtags,
    String? imageUrl,
  )
  onSave,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _SocialPostEditDialog(
        title: title,
        initialCaption: initialCaption,
        initialHashtags: initialHashtags,
        initialImageUrl: initialImageUrl,
        initialTextLength: initialTextLength,
        initialImageQuality: initialImageQuality,
        onRegenerateText: onRegenerateText,
        onRegenerateImage: onRegenerateImage,
        onSave: onSave,
      );
    },
  );
}

class _SocialPostEditDialog extends StatefulWidget {
  const _SocialPostEditDialog({
    required this.title,
    required this.initialCaption,
    required this.initialHashtags,
    required this.initialImageUrl,
    required this.initialTextLength,
    required this.initialImageQuality,
    required this.onRegenerateText,
    required this.onRegenerateImage,
    required this.onSave,
  });

  final String title;
  final String initialCaption;
  final String initialHashtags;
  final String? initialImageUrl;
  final String initialTextLength;
  final String initialImageQuality;
  final Future<SocialContentResult> Function(String textLength)
  onRegenerateText;
  final Future<SocialContentResult> Function(
    String imageQuality,
    dio.CancelToken cancelToken,
  )
  onRegenerateImage;
  final Future<void> Function(String caption, String hashtags, String? imageUrl)
  onSave;

  @override
  State<_SocialPostEditDialog> createState() => _SocialPostEditDialogState();
}

class _SocialPostEditDialogState extends State<_SocialPostEditDialog> {
  late final TextEditingController _captionController;
  late final TextEditingController _hashtagsController;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSaving = false;
  bool _isRegeneratingText = false;
  bool _isRegeneratingImage = false;
  late String _selectedTextLength;
  late String _selectedImageQuality;
  String? _imageUrl;
  dio.CancelToken? _activeImageCancelToken;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.initialCaption);
    _hashtagsController = TextEditingController(text: widget.initialHashtags);
    _selectedTextLength = widget.initialTextLength;
    _selectedImageQuality = widget.initialImageQuality;
    _imageUrl = widget.initialImageUrl;
  }

  @override
  void dispose() {
    _activeImageCancelToken?.cancel('Edit dialog closed');
    _activeImageCancelToken = null;
    _captionController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 70,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (bytes.length > 900 * 1024) {
      _showEditSnack(
        'Selected image is still too large. Please choose a smaller image.',
      );
      return;
    }
    final mime = _mimeTypeForPath(picked.path);
    setState(() {
      _imageUrl = 'data:$mime;base64,${base64Encode(bytes)}';
    });
  }

  Future<void> _handleRegenerateText() async {
    setState(() => _isRegeneratingText = true);
    try {
      final result = await widget.onRegenerateText(_selectedTextLength);
      if (!mounted) return;
      setState(() {
        if (result.caption.trim().isNotEmpty) {
          _captionController.text = result.caption.trim();
        }
        if (result.hashtags.trim().isNotEmpty) {
          _hashtagsController.text = result.hashtags.trim();
        }
      });
    } catch (error) {
      _showEditSnack(error);
    } finally {
      if (mounted) setState(() => _isRegeneratingText = false);
    }
  }

  Future<void> _handleRegenerateImage() async {
    setState(() => _isRegeneratingImage = true);
    final cancelToken = dio.CancelToken();
    _activeImageCancelToken = cancelToken;
    try {
      final result = await widget.onRegenerateImage(
        _selectedImageQuality,
        cancelToken,
      );
      if (!mounted) return;
      setState(() {
        if ((result.imageUrl ?? '').trim().isNotEmpty) {
          _imageUrl = result.imageUrl!.trim();
        }
      });
    } catch (error) {
      if (!_isGenerationStopped(error)) {
        _showEditSnack(error);
      }
    } finally {
      _activeImageCancelToken = null;
      if (mounted) setState(() => _isRegeneratingImage = false);
    }
  }

  void _stopRegeneratingImage() {
    _activeImageCancelToken?.cancel();
    _activeImageCancelToken = null;
    if (mounted) {
      setState(() => _isRegeneratingImage = false);
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        _captionController.text,
        _hashtagsController.text,
        _imageUrl,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      _showEditSnack(error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showEditSnack(Object error) {
    if (!mounted) return;
    final message = error.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isGenerationStopped(Object error) {
    return error.toString().toLowerCase().contains('generation stopped');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF101A35),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Post Caption',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF101A35),
                  fontSize: 12.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _CreateSelectField(
                      icon: Icons.notes_rounded,
                      iconColor: const Color(0xFF0A3F85),
                      label: 'Text Length',
                      value: _selectedTextLength,
                      options: _socialTextLengthOptions,
                      onSelected: (value) {
                        setState(() => _selectedTextLength = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 154,
                    child: _EditModalActionButton(
                      label: _isRegeneratingText
                          ? 'Working...'
                          : 'Regenerate Text',
                      icon: Icons.refresh_rounded,
                      onTap: _isRegeneratingText || _isSaving
                          ? null
                          : _handleRegenerateText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _captionController,
                maxLines: 6,
                minLines: 4,
                decoration: _editInputDecoration(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF1B2745),
                  fontSize: 13.4,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hashtags',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF101A35),
                  fontSize: 12.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _hashtagsController,
                minLines: 1,
                maxLines: 3,
                decoration: _editInputDecoration(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF4F46E5),
                  fontSize: 12.8,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Post Image',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF101A35),
                  fontSize: 12.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFCFF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDDE6F2)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 190,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _imageUrl == null || _imageUrl!.trim().isEmpty
                              ? const Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: Color(0xFF9BA8BC),
                                    size: 36,
                                  ),
                                )
                              : AnimatedOpacity(
                                  duration: const Duration(milliseconds: 220),
                                  opacity: _isRegeneratingImage ? 0.25 : 1,
                                  child: _analyticsImageWidget(
                                    _imageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                          if (_isRegeneratingImage)
                            Container(
                              color: const Color(0xCC0F2746),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.6,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Generating new image...',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Colors.white,
                                      fontSize: 13.2,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Please wait while AI creates a fresh version.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Color(0xFFD6E1F2),
                                      fontSize: 11.6,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  GestureDetector(
                                    onTap: _stopRegeneratingImage,
                                    child: Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.14,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.26,
                                          ),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.stop_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Stop',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Colors.white,
                                      fontSize: 11.8,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EditModalActionButton(
                      label: 'Upload Custom Image',
                      icon: Icons.file_upload_outlined,
                      onTap: _isSaving ? null : _pickCustomImage,
                      filled: false,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _EditModalActionButton(
                            label: _isRegeneratingImage
                                ? 'Generating...'
                                : 'Regenerate Image via AI',
                            icon: Icons.auto_awesome_rounded,
                            onTap: _isRegeneratingImage || _isSaving
                                ? null
                                : _handleRegenerateImage,
                            filled: false,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CreateSelectField(
                            icon: Icons.flash_on_rounded,
                            iconColor: const Color(0xFFE0A11B),
                            label: 'Image Quality',
                            value:
                                _socialEditImageQualityLabels[_selectedImageQuality] ??
                                'Good (Fast)',
                            options: _socialEditImageQualityLabels.values
                                .toList(),
                            onSelected: (value) {
                              final selected = _socialEditImageQualityLabels
                                  .entries
                                  .firstWhere(
                                    (entry) => entry.value == value,
                                    orElse: () =>
                                        const MapEntry('good', 'Good (Fast)'),
                                  );
                              setState(
                                () => _selectedImageQuality = selected.key,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A3F85),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _editInputDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFDDE6F2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.3),
    ),
  );
}

String _mimeTypeForPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}

class _EditModalActionButton extends StatelessWidget {
  const _EditModalActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: filled && onTap != null
              ? const LinearGradient(
                  colors: [_socialBrandButtonStart, _socialBrandButtonEnd],
                )
              : null,
          color: filled
              ? (onTap == null ? const Color(0xFFC7D2E6) : null)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled ? Colors.transparent : const Color(0xFFDDE6F2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: filled ? Colors.white : const Color(0xFF4F46E5),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: filled ? Colors.white : const Color(0xFF4F46E5),
                  fontSize: 12.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _createPlatformLogo(String platform) {
  final value = platform.toLowerCase();
  if (value.contains('facebook')) return 'assets/images/facebook.png';
  if (value.contains('linkedin')) return 'assets/images/link.png';
  return 'assets/images/instagram.png';
}

String _normalizePlatformLabel(String platform) {
  final value = platform.toLowerCase();
  if (value.contains('facebook')) return 'Facebook';
  if (value.contains('linkedin')) return 'LinkedIn';
  if (value.contains('instagram')) return 'Instagram';
  return platform;
}

String _normalizeBackendPostStatus(String status) {
  final value = status.toLowerCase();
  if (value.contains('publish')) return 'PUBLISHED';
  if (value.contains('schedule')) return 'SCHEDULED';
  if (value.contains('fail')) return 'FAILED';
  return 'DRAFT';
}

class SocialCalendarView extends StatefulWidget {
  const SocialCalendarView({super.key});

  @override
  State<SocialCalendarView> createState() => _SocialCalendarViewState();
}

class _SocialCalendarViewState extends State<SocialCalendarView> {
  final OnboardingController _controller = Get.find<OnboardingController>();
  late final SocialCalendarController _calendarController =
      Get.isRegistered<SocialCalendarController>()
      ? Get.find<SocialCalendarController>()
      : Get.put(SocialCalendarController());
  bool _isSidebarOpen = false;
  int _selectedViewIndex = 0;
  int _selectedStatusIndex = 0;
  int _selectedPlatformIndex = 0;
  late DateTime _visibleMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  String get _selectedPlatformFilter => switch (_selectedPlatformIndex) {
    1 => 'facebook',
    2 => 'instagram',
    3 => 'linkedin',
    _ => 'all',
  };

  String get _visibleMonthLabel =>
      '${_calendarMonthName(_visibleMonth.month)} ${_visibleMonth.year}';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _calendarController.loadMonth(_visibleMonth));
  }

  void _goToPreviousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
    _calendarController.loadMonth(_visibleMonth);
  }

  void _goToNextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
    _calendarController.loadMonth(_visibleMonth);
  }

  Future<void> _pickCalendarDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _calendarController.selectedDay.value,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030, 12, 31),
      helpText: 'Select calendar month',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3168FF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF111827),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _visibleMonth = DateTime(picked.year, picked.month);
      });
      _calendarController.selectedDay.value = picked;
      _calendarController.loadMonth(_visibleMonth);
    }
  }

  Future<void> _openSidebar(TestAccount user) async {
    if (_isSidebarOpen) {
      return;
    }
    setState(() => _isSidebarOpen = true);
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierLabel: 'Social sidebar',
        barrierDismissible: true,
        barrierColor: const Color(0x800F2746),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          final safeTop = MediaQuery.paddingOf(dialogContext).top;
          final safeBottom = MediaQuery.paddingOf(dialogContext).bottom;
          final screenWidth = MediaQuery.sizeOf(dialogContext).width;
          final sidebarWidth = screenWidth * 0.8;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(dialogContext).pop(),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: TweenAnimationBuilder<Offset>(
                      tween: Tween(
                        begin: const Offset(-1.02, 0),
                        end: Offset.zero,
                      ),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      builder: (context, offset, child) {
                        return FractionalTranslation(
                          translation: offset,
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: sidebarWidth,
                        height: double.infinity,
                        child: SocialSidebarPanel(
                          user: user,
                          safeTopInset: safeTop,
                          safeBottomInset: safeBottom,
                          onDashboardTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialDashboard);
                          },
                          onAccountsTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialAccounts);
                          },
                          onCreateTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialCreate);
                          },
                          onCreativesTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialCreatives);
                          },
                          onCalendarTap: () =>
                              Navigator.of(dialogContext).pop(),
                          onSchedulerTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialScheduler);
                          },
                          onPostsTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialPosts);
                          },
                          onAnalyticsTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialAnalytics);
                          },
                          onProfileTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialProfile);
                          },
                          onPaymentTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.payment);
                          },
                          onSupportTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.toNamed(AppRoutes.support);
                          },
                          onCollapseTap: () =>
                              Navigator.of(dialogContext).pop(),
                          onLogoutTap: () {
                            Navigator.of(dialogContext).pop();
                            _controller.logout();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSidebarOpen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productModeController = Get.isRegistered<ProductModeController>()
        ? Get.find<ProductModeController>()
        : Get.put(ProductModeController(), permanent: true);
    if (!productModeController.isSocialMedia) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        productModeController.selectMode(ProductMode.socialMedia);
      });
    }

    return AuthNavigationShell(
      currentTab: AuthTab.socialCalendar,
      backgroundColor: const Color(0xFFFBFCFF),
      child: Obx(() {
        final user = _controller.currentUser.value;
        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SocialCreateTopBar(onMenuTap: () => _openSidebar(user)),
              const SizedBox(height: 18),
              const Text(
                'Social Media Calendar',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF101A35),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Plan, view and manage your content calendar.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF64728F),
                  fontSize: 13.8,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              _CalendarViewSwitch(
                selectedIndex: _selectedViewIndex,
                onSelected: (index) {
                  setState(() => _selectedViewIndex = index);
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _CalendarMonthPicker(
                      monthLabel: _visibleMonthLabel,
                      onPrevious: _goToPreviousMonth,
                      onNext: _goToNextMonth,
                      onCalendarTap: _pickCalendarDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CalendarCreateButton(
                      onTap: () => Get.offNamed(AppRoutes.socialCreate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _CalendarStatusFilters(
                selectedIndex: _selectedStatusIndex,
                onSelected: (index) {
                  setState(() => _selectedStatusIndex = index);
                },
              ),
              const SizedBox(height: 14),
              Obx(() {
                if (_calendarController.isLoading.value) {
                  return const _CalendarLoadingCard();
                }
                final error = _calendarController.errorMessage.value;
                if (error != null) {
                  return _CalendarErrorCard(
                    message: error,
                    onRetry: () => _calendarController.loadMonth(_visibleMonth),
                  );
                }

                final visiblePosts = _calendarController.visiblePosts(
                  statusIndex: _selectedStatusIndex,
                  platformFilter: _selectedPlatformFilter,
                );
                return Column(
                  children: [
                    _CalendarScheduleBody(
                      selectedViewIndex: _selectedViewIndex,
                      visibleMonth: _visibleMonth,
                      selectedDay: _calendarController.selectedDay.value,
                      posts: visiblePosts,
                      controller: _calendarController,
                    ),
                    const SizedBox(height: 16),
                    _CalendarOverviewCard(
                      monthLabel: _visibleMonthLabel,
                      scheduledCount: _calendarController.countStatus(
                        'scheduled',
                      ),
                      publishedCount: _calendarController.countStatus(
                        'published',
                      ),
                      draftCount: _calendarController.countStatus('draft'),
                      failedCount: _calendarController.countStatus('failed'),
                    ),
                    const SizedBox(height: 16),
                    _CalendarPlatformFilters(
                      selectedIndex: _selectedPlatformIndex,
                      allCount: _calendarController.platformCount('all'),
                      facebookCount: _calendarController.platformCount(
                        'facebook',
                      ),
                      instagramCount: _calendarController.platformCount(
                        'instagram',
                      ),
                      linkedinCount: _calendarController.platformCount(
                        'linkedin',
                      ),
                      onSelected: (index) {
                        setState(() => _selectedPlatformIndex = index);
                      },
                    ),
                    const SizedBox(height: 16),
                    _UpcomingScheduledCard(
                      posts: _calendarController.upcomingScheduled(
                        _selectedPlatformFilter,
                      ),
                      controller: _calendarController,
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      }),
    );
  }
}

class _CalendarViewSwitch extends StatelessWidget {
  const _CalendarViewSwitch({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const labels = ['Month', 'Week', 'Day'];

    return Container(
      height: 52,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDDE6F1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F2746),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [
                            _socialBrandButtonStart,
                            _socialBrandButtonEnd,
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(11),
                  border: index == 1 && !selected
                      ? const Border.symmetric(
                          vertical: BorderSide(color: Color(0xFFE1E8F2)),
                        )
                      : null,
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: selected ? Colors.white : const Color(0xFF58657F),
                    fontSize: 14.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CalendarLoadingCard extends StatelessWidget {
  const _CalendarLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEF5)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF3168FF)),
      ),
    );
  }
}

class _CalendarErrorCard extends StatelessWidget {
  const _CalendarErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD7D7)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFEF4444),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF64728F),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF3168FF),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarEmptyMessage extends StatelessWidget {
  const _CalendarEmptyMessage(this.message, {this.showCreateButton = false});

  final String message;
  final bool showCreateButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEF5)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF7A87A4),
              fontSize: 12.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (showCreateButton) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Get.offNamed(AppRoutes.socialCreate),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_socialBrandButtonStart, _socialBrandButtonEnd],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Create Post',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
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

class _CalendarMonthPicker extends StatelessWidget {
  const _CalendarMonthPicker({
    required this.monthLabel,
    required this.onPrevious,
    required this.onNext,
    required this.onCalendarTap,
  });

  final String monthLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCalendarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDDE6F1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPrevious,
            child: const SizedBox(
              width: 26,
              height: 38,
              child: Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF5E6B85),
                size: 24,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                monthLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF111B36),
                  fontSize: 13.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onCalendarTap,
            child: const SizedBox(
              width: 30,
              height: 38,
              child: Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF6D7894),
                size: 18,
              ),
            ),
          ),
          GestureDetector(
            onTap: onNext,
            child: const SizedBox(
              width: 26,
              height: 38,
              child: Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF5E6B85),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarCreateButton extends StatelessWidget {
  const _CalendarCreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3168FF), Color(0xFF6736F4)],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x263168FF),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 25),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Create Post',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: 15.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarStatusFilters extends StatelessWidget {
  const _CalendarStatusFilters({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const filters = [
      (label: 'All', color: Color(0xFF111D36)),
      (label: 'Scheduled', color: Color(0xFF3168FF)),
      (label: 'Published', color: Color(0xFF12B886)),
      (label: 'Draft', color: Color(0xFF6652E8)),
      (label: 'Failed', color: Color(0xFFEF4444)),
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 5),
        itemBuilder: (context, index) {
          final item = filters[index];
          final selected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF101D36) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF101D36)
                      : const Color(0xFFE6ECF4),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A0F2746),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (index > 0) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: selected ? Colors.white : const Color(0xFF5C6880),
                      fontSize: 10.6,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CalendarScheduleBody extends StatelessWidget {
  const _CalendarScheduleBody({
    required this.selectedViewIndex,
    required this.visibleMonth,
    required this.selectedDay,
    required this.posts,
    required this.controller,
  });

  final int selectedViewIndex;
  final DateTime visibleMonth;
  final DateTime selectedDay;
  final List<SocialPostInfo> posts;
  final SocialCalendarController controller;

  @override
  Widget build(BuildContext context) {
    return switch (selectedViewIndex) {
      1 => _CalendarWeekView(
        visibleMonth: visibleMonth,
        selectedDay: selectedDay,
        posts: posts,
        controller: controller,
      ),
      2 => _CalendarDayView(
        selectedDay: selectedDay,
        posts: posts,
        controller: controller,
      ),
      _ => _CalendarMonthGrid(
        visibleMonth: visibleMonth,
        posts: posts,
        controller: controller,
      ),
    };
  }
}

class _CalendarMonthGrid extends StatelessWidget {
  const _CalendarMonthGrid({
    required this.visibleMonth,
    required this.posts,
    required this.controller,
  });

  final DateTime visibleMonth;
  final List<SocialPostInfo> posts;
  final SocialCalendarController controller;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
    final leadingDays = firstDay.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(
      visibleMonth.year,
      visibleMonth.month,
    );
    final previousMonth = DateTime(visibleMonth.year, visibleMonth.month - 1);
    final previousMonthDays = DateUtils.getDaysInMonth(
      previousMonth.year,
      previousMonth.month,
    );
    final totalCells = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;
    final days = List.generate(totalCells, (index) {
      if (index < leadingDays) {
        return (
          label: '${previousMonthDays - leadingDays + index + 1}',
          muted: true,
          date: DateTime(
            previousMonth.year,
            previousMonth.month,
            previousMonthDays - leadingDays + index + 1,
          ),
        );
      }
      final dayNumber = index - leadingDays + 1;
      if (dayNumber > daysInMonth) {
        return (
          label: '${dayNumber - daysInMonth}',
          muted: true,
          date: DateTime(
            visibleMonth.year,
            visibleMonth.month + 1,
            dayNumber - daysInMonth,
          ),
        );
      }
      return (
        label: '$dayNumber',
        muted: false,
        date: DateTime(visibleMonth.year, visibleMonth.month, dayNumber),
      );
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE6F1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFFBFCFF),
              border: Border(bottom: BorderSide(color: Color(0xFFE3EAF3))),
            ),
            child: const Row(
              children: [
                _CalendarWeekdayLabel('SUN'),
                _CalendarWeekdayLabel('MON'),
                _CalendarWeekdayLabel('TUE'),
                _CalendarWeekdayLabel('WED'),
                _CalendarWeekdayLabel('THU'),
                _CalendarWeekdayLabel('FRI'),
                _CalendarWeekdayLabel('SAT'),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              final dayPosts = posts
                  .where((post) {
                    final postDate = controller.postDate(post);
                    return postDate.year == day.date.year &&
                        postDate.month == day.date.month &&
                        postDate.day == day.date.day;
                  })
                  .toList(growable: false);
              return _CalendarDayCell(
                day: day.label,
                muted: day.muted,
                posts: dayPosts,
                controller: controller,
                onTap: () {
                  controller.selectedDay.value = day.date;
                  if (!day.muted && dayPosts.isNotEmpty) {
                    _showCalendarPostPreview(
                      context,
                      dayPosts.first,
                      controller,
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarWeekView extends StatelessWidget {
  const _CalendarWeekView({
    required this.visibleMonth,
    required this.selectedDay,
    required this.posts,
    required this.controller,
  });

  final DateTime visibleMonth;
  final DateTime selectedDay;
  final List<SocialPostInfo> posts;
  final SocialCalendarController controller;

  @override
  Widget build(BuildContext context) {
    final anchor = selectedDay.month == visibleMonth.month
        ? selectedDay
        : DateTime(visibleMonth.year, visibleMonth.month);
    final weekStart = anchor.subtract(Duration(days: anchor.weekday - 1));
    final weekDays = List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final selected =
          date.year == anchor.year &&
          date.month == anchor.month &&
          date.day == anchor.day;
      return (date: date, selected: selected);
    });
    final weekPosts = posts
        .where((post) {
          final date = controller.postDate(post);
          final weekEnd = weekStart.add(const Duration(days: 7));
          return !date.isBefore(weekStart) && date.isBefore(weekEnd);
        })
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE6F1)),
      ),
      child: Column(
        children: [
          Row(
            children: weekDays.map((day) {
              final selected = day.selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.selectedDay.value = day.date,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFEAF2FF)
                          : const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF3168FF)
                            : const Color(0xFFE8EEF5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _calendarShortWeekday(day.date.weekday),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: selected
                                ? const Color(0xFF3168FF)
                                : const Color(0xFF64728F),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.date.day}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF111827),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          if (weekPosts.isEmpty)
            const _CalendarEmptyMessage(
              'No scheduled or published posts for this week.',
              showCreateButton: true,
            )
          else
            ...List.generate(weekPosts.length, (index) {
              final post = weekPosts[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == weekPosts.length - 1 ? 0 : 10,
                ),
                child: _CalendarAgendaRow(
                  iconPath: controller.platformIconPath(post),
                  time: _formatCalendarAgendaTime(controller.postDate(post)),
                  title: post.content,
                  color: controller.platformColor(post),
                  onTap: () =>
                      _showCalendarPostPreview(context, post, controller),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _CalendarDayView extends StatelessWidget {
  const _CalendarDayView({
    required this.selectedDay,
    required this.posts,
    required this.controller,
  });

  final DateTime selectedDay;
  final List<SocialPostInfo> posts;
  final SocialCalendarController controller;

  @override
  Widget build(BuildContext context) {
    final dayPosts = posts
        .where((post) {
          final date = controller.postDate(post);
          return date.year == selectedDay.year &&
              date.month == selectedDay.month &&
              date.day == selectedDay.day;
        })
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE6F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_calendarMonthName(selectedDay.month)} ${selectedDay.day}, ${selectedDay.year}',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (dayPosts.isEmpty)
            const _CalendarEmptyMessage(
              'No scheduled or published posts for this day.',
              showCreateButton: true,
            )
          else
            ...List.generate(dayPosts.length, (index) {
              final post = dayPosts[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == dayPosts.length - 1 ? 0 : 10,
                ),
                child: _CalendarAgendaRow(
                  iconPath: controller.platformIconPath(post),
                  time: _formatCalendarTime(controller.postDate(post)),
                  title: post.content,
                  color: controller.platformColor(post),
                  onTap: () =>
                      _showCalendarPostPreview(context, post, controller),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _CalendarWeekdayLabel extends StatelessWidget {
  const _CalendarWeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF66748F),
            fontSize: 10.8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.muted,
    required this.posts,
    required this.controller,
    required this.onTap,
  });

  final String day;
  final bool muted;
  final List<SocialPostInfo> posts;
  final SocialCalendarController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final events = posts
        .take(3)
        .map((post) {
          final color = controller.platformColor(post);
          return _CalendarCellEvent(
            iconPath: controller.platformIconPath(post),
            color: color,
            background: color.withValues(alpha: 0.12),
          );
        })
        .toList(growable: false);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(3, 5, 3, 3),
        decoration: BoxDecoration(
          color: posts.isNotEmpty && !muted
              ? const Color(0xFFFAFCFF)
              : Colors.white,
          border: const Border(
            right: BorderSide(color: Color(0xFFE7EDF5)),
            bottom: BorderSide(color: Color(0xFFE7EDF5)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              day,
              style: TextStyle(
                fontFamily: 'Inter',
                color: muted
                    ? const Color(0xFF98A4B8)
                    : const Color(0xFF101A35),
                fontSize: 11.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (events.isNotEmpty)
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Wrap(
                      spacing: 2,
                      runSpacing: 2,
                      alignment: WrapAlignment.center,
                      children: events,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CalendarCellEvent extends StatelessWidget {
  const _CalendarCellEvent({
    required this.iconPath,
    required this.color,
    required this.background,
  });

  final String iconPath;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      padding: const EdgeInsets.all(2),
      child: Image.asset(iconPath, fit: BoxFit.contain),
    );
  }
}

class _CalendarAgendaRow extends StatelessWidget {
  const _CalendarAgendaRow({
    required this.iconPath,
    required this.time,
    required this.title,
    required this.color,
    this.onTap,
  });

  final String iconPath;
  final String time;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EEF5)),
        ),
        child: Row(
          children: [
            Image.asset(iconPath, width: 32, height: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: color,
                      fontSize: 12.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF111827),
                      fontSize: 12.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarOverviewCard extends StatelessWidget {
  const _CalendarOverviewCard({
    required this.monthLabel,
    required this.scheduledCount,
    required this.publishedCount,
    required this.draftCount,
    required this.failedCount,
  });

  final String monthLabel;
  final int scheduledCount;
  final int publishedCount;
  final int draftCount;
  final int failedCount;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        icon: Icons.calendar_month_outlined,
        count: '$scheduledCount',
        label: 'Scheduled',
        color: Color(0xFF3168FF),
        bg: Color(0xFFEAF2FF),
      ),
      (
        icon: Icons.near_me_outlined,
        count: '$publishedCount',
        label: 'Published',
        color: Color(0xFF10B981),
        bg: Color(0xFFE6FBF4),
      ),
      (
        icon: Icons.description_outlined,
        count: '$draftCount',
        label: 'Draft',
        color: Color(0xFF6652E8),
        bg: Color(0xFFF0EEFF),
      ),
      (
        icon: Icons.warning_amber_rounded,
        count: '$failedCount',
        label: 'Failed',
        color: Color(0xFFEF4444),
        bg: Color(0xFFFFF0F0),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F2746),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Calendar Overview',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8FC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE0E8F2)),
                ),
                child: Text(
                  monthLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF66748F),
                    fontSize: 12.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(stats.length, (index) {
              final stat = stats[index];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == stats.length - 1 ? 0 : 8,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 96),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: stat.bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: stat.color.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(stat.icon, color: stat.color, size: 21),
                        const SizedBox(height: 4),
                        Text(
                          stat.count,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF111827),
                            fontSize: 19,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stat.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF64728F),
                            fontSize: 10,
                            height: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CalendarPlatformFilters extends StatelessWidget {
  const _CalendarPlatformFilters({
    required this.selectedIndex,
    required this.allCount,
    required this.facebookCount,
    required this.instagramCount,
    required this.linkedinCount,
    required this.onSelected,
  });

  final int selectedIndex;
  final int allCount;
  final int facebookCount;
  final int instagramCount;
  final int linkedinCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final platforms = [
      (
        label: 'All Platforms',
        count: '$allCount',
        icon: null,
        color: Color(0xFF6652E8),
      ),
      (
        label: 'Facebook',
        count: '$facebookCount',
        icon: 'assets/images/facebook.png',
        color: Color(0xFF1877F2),
      ),
      (
        label: 'Instagram',
        count: '$instagramCount',
        icon: 'assets/images/instagram.png',
        color: Color(0xFFE4408F),
      ),
      (
        label: 'LinkedIn',
        count: '$linkedinCount',
        icon: 'assets/images/link.png',
        color: Color(0xFF0A66C2),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F2746),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Platform',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF111827),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(platforms.length, (index) {
                  final item = platforms[index];
                  final selected = index == selectedIndex;
                  return GestureDetector(
                    onTap: () => onSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: itemWidth,
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFF5F2FF)
                            : const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF6652E8)
                              : const Color(0xFFE1E8F2),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (item.icon == null)
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: item.color,
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            Image.asset(item.icon!, width: 24, height: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: selected
                                    ? const Color(0xFF5A4CFF)
                                    : const Color(0xFF26324D),
                                fontSize: 11.6,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F5FA),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              item.count,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: selected
                                    ? const Color(0xFF5A4CFF)
                                    : const Color(0xFF64728F),
                                fontSize: 10.8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UpcomingScheduledCard extends StatelessWidget {
  const _UpcomingScheduledCard({required this.posts, required this.controller});

  final List<SocialPostInfo> posts;
  final SocialCalendarController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F2746),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Upcoming Scheduled',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF111827),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Get.offNamed(AppRoutes.socialScheduler),
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF5A4CFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF5A4CFF),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8EEF5)),
            ),
            child: Column(
              children: posts.isEmpty
                  ? [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 18,
                        ),
                        child: Text(
                          'No scheduled posts for this platform.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF7A87A4),
                            fontSize: 12.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ]
                  : List.generate(posts.length, (index) {
                      final post = posts[index];
                      final date = controller.postDate(post);
                      final color = controller.platformColor(post);
                      return GestureDetector(
                        onTap: () => Get.offNamed(AppRoutes.socialScheduler),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                          decoration: BoxDecoration(
                            border: index == posts.length - 1
                                ? null
                                : const Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFE8EEF5),
                                    ),
                                  ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _calendarShortMonth(
                                        date.month,
                                      ).toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: color,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      '${date.day}',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: Color(0xFF111827),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Image.asset(
                                controller.platformIconPath(post),
                                width: 36,
                                height: 36,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatCalendarTime(date),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: color,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      post.content.isEmpty
                                          ? 'Untitled social post'
                                          : post.content,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: Color(0xFF111827),
                                        fontSize: 13.1,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 9),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF66748F),
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
            ),
          ),
        ],
      ),
    );
  }
}

class SocialPostsView extends StatefulWidget {
  const SocialPostsView({super.key});

  @override
  State<SocialPostsView> createState() => _SocialPostsViewState();
}

class _SocialPostsViewState extends State<SocialPostsView> {
  final OnboardingController _controller = Get.find<OnboardingController>();
  late final SocialPostsController _socialPostsController =
      Get.isRegistered<SocialPostsController>()
      ? Get.find<SocialPostsController>()
      : Get.put(SocialPostsController());
  late final SocialApiService _socialApiService =
      Get.isRegistered<SocialApiService>()
      ? Get.find<SocialApiService>()
      : Get.put(SocialApiService());
  final TextEditingController _searchController = TextEditingController();
  bool _isSidebarOpen = false;
  String _selectedFilter = 'All';
  String _query = '';
  int _page = 1;

  static const _filters = ['All', 'Draft', 'Scheduled', 'Published', 'Failed'];
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _socialPostsController.loadPosts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_SocialPostItem> get _visiblePosts {
    final posts = _socialPostsController.posts.map(_mapPostItem).where((post) {
      final matchesFilter =
          _selectedFilter == 'All' || post.status == _selectedFilter;
      final normalizedQuery = _query.trim().toLowerCase();
      final matchesQuery =
          normalizedQuery.isEmpty ||
          post.caption.toLowerCase().contains(normalizedQuery) ||
          post.hashtags.toLowerCase().contains(normalizedQuery);
      return matchesFilter && matchesQuery;
    }).toList();

    posts.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return posts;
  }

  _SocialPostItem _mapPostItem(SocialPostInfo post) {
    final date =
        post.publishedAt ??
        post.scheduledAt ??
        post.createdAt ??
        DateTime.now();
    return _SocialPostItem(
      id: post.id,
      status: _normalizePostStatus(post.status),
      platform: post.platforms.isEmpty ? 'generic' : post.platforms.first,
      image: post.mediaUrls.isEmpty ? null : post.mediaUrls.first,
      caption: post.content.isEmpty ? 'Untitled social post' : post.content,
      hashtags: _extractPostHashtags(post),
      date: _formatSocialPostDate(date),
      sortDate: date,
      scheduledAt: post.scheduledAt,
    );
  }

  String _extractPostHashtags(SocialPostInfo post) {
    final values = <String>[
      _readHashtagValue(post.raw['hashtags']),
      _readHashtagValue(post.raw['hashtag']),
      _readHashtagValue(post.raw['tags']),
    ];

    final content = post.raw['content'];
    if (content is Map) {
      final nested = Map<String, dynamic>.from(content);
      values.addAll([
        _readHashtagValue(nested['hashtags']),
        _readHashtagValue(nested['hashtag']),
        _readHashtagValue(nested['tags']),
      ]);
    } else if (content is String) {
      final match = RegExp(
        r'"hashtags"\s*:\s*("((?:\\.|[^"\\])*)"|\[[^\]]*\])',
      ).firstMatch(content);
      if (match != null) {
        values.add(_cleanHashtagText(match.group(1) ?? ''));
      }
    }

    final normalized = values
        .expand((value) => value.split(RegExp(r'[\n,]+')))
        .map(_cleanHashtagText)
        .where((value) => value.isNotEmpty)
        .map((value) => value.startsWith('#') ? value : '#$value')
        .toSet()
        .join(' ');

    return normalized;
  }

  String _readHashtagValue(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).join(' ');
    }
    return _cleanHashtagText(value?.toString() ?? '');
  }

  String _cleanHashtagText(String value) {
    return value
        .replaceAll('[', ' ')
        .replaceAll(']', ' ')
        .replaceAll('"', ' ')
        .replaceAll("'", ' ')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\"', '"')
        .trim();
  }

  String _normalizePostStatus(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.contains('publish')) return 'Published';
    if (normalized.contains('schedule')) return 'Scheduled';
    if (normalized.contains('fail')) return 'Failed';
    return 'Draft';
  }

  void _showFullPost(_SocialPostItem post) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 28,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${post.status} Post',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF101A35),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FullPostPreviewMedia(post: post),
                        const SizedBox(height: 14),
                        Text(
                          post.caption,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF101A35),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                        if (post.hashtags.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F8FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFDDE6FF),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hashtags',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF64728F),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  post.hashtags,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF395CFF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: Color(0xFF74839D),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        post.date,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF64728F),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteDraft(_SocialPostItem post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete draft post?',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF101A35),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'This draft will be removed from your social workspace. This action cannot be undone.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF64728F),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFE83E5A)),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      await _socialPostsController.deleteDraftPost(post.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Draft post deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _editPost(_SocialPostItem post) async {
    await _showSocialPostEditDialog(
      context: context,
      title: 'Edit ${_normalizePlatformLabel(post.platform)} Post',
      initialCaption: post.caption,
      initialHashtags: post.hashtags,
      initialImageUrl: post.image,
      initialTextLength: 'Short (2-3 lines)',
      initialImageQuality: 'good',
      onRegenerateText: (textLength) {
        return _socialApiService.generateContent(
          businessId: _socialPostsController.businessId,
          topic: post.caption,
          platform: _normalizePlatformLabel(post.platform),
          tone: 'friendly',
          includeImage: false,
          language: 'English',
          textLength: textLength,
          imageQuality: 'good',
          noAutoSave: true,
        );
      },
      onRegenerateImage: (imageQuality, cancelToken) {
        return _socialApiService.generateContent(
          businessId: _socialPostsController.businessId,
          topic: post.caption,
          platform: _normalizePlatformLabel(post.platform),
          tone: 'friendly',
          includeImage: true,
          language: 'English',
          textLength: 'Short (2-3 lines)',
          imageQuality: imageQuality,
          noAutoSave: true,
          cancelToken: cancelToken,
        );
      },
      onSave: (caption, hashtags, imageUrl) async {
        await _socialApiService.updatePost(
          businessId: _socialPostsController.businessId,
          postId: post.id,
          data: <String, dynamic>{
            'content': jsonEncode(<String, dynamic>{
              'caption': caption.trim(),
              'hashtags': hashtags.trim(),
              'cta': '',
              'platform': post.platform.toLowerCase(),
            }),
            'mediaUrls': imageUrl == null || imageUrl.trim().isEmpty
                ? <String>[]
                : <String>[imageUrl],
            'platforms': <String>[post.platform.toUpperCase()],
            'status': _normalizeBackendPostStatus(post.status),
            if (post.scheduledAt != null)
              'scheduledAt': post.scheduledAt!.toUtc().toIso8601String(),
          },
        );
        await _socialPostsController.loadPosts(refresh: true);
      },
    );
  }

  Future<void> _openSidebar(TestAccount user) async {
    if (_isSidebarOpen) return;
    setState(() => _isSidebarOpen = true);
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierLabel: 'Social sidebar',
        barrierDismissible: true,
        barrierColor: const Color(0x800F2746),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          final safeTop = MediaQuery.paddingOf(dialogContext).top;
          final safeBottom = MediaQuery.paddingOf(dialogContext).bottom;
          final sidebarWidth = MediaQuery.sizeOf(dialogContext).width * 0.8;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(dialogContext).pop(),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: TweenAnimationBuilder<Offset>(
                      tween: Tween(
                        begin: const Offset(-1.02, 0),
                        end: Offset.zero,
                      ),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      builder: (context, offset, child) {
                        return FractionalTranslation(
                          translation: offset,
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: sidebarWidth,
                        height: double.infinity,
                        child: SocialSidebarPanel(
                          user: user,
                          safeTopInset: safeTop,
                          safeBottomInset: safeBottom,
                          onDashboardTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialDashboard);
                          },
                          onAccountsTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialAccounts);
                          },
                          onCreateTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialCreate);
                          },
                          onCreativesTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialCreatives);
                          },
                          onCalendarTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialCalendar);
                          },
                          onSchedulerTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialScheduler);
                          },
                          onPostsTap: () => Navigator.of(dialogContext).pop(),
                          onAnalyticsTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialAnalytics);
                          },
                          onProfileTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialProfile);
                          },
                          onPaymentTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.payment);
                          },
                          onSupportTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.toNamed(AppRoutes.support);
                          },
                          onCollapseTap: () =>
                              Navigator.of(dialogContext).pop(),
                          onLogoutTap: () {
                            Navigator.of(dialogContext).pop();
                            _controller.logout();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _isSidebarOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productModeController = Get.isRegistered<ProductModeController>()
        ? Get.find<ProductModeController>()
        : Get.put(ProductModeController(), permanent: true);
    if (!productModeController.isSocialMedia) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        productModeController.selectMode(ProductMode.socialMedia);
      });
    }

    return AuthNavigationShell(
      currentTab: AuthTab.socialPosts,
      backgroundColor: const Color(0xFFFBFCFF),
      child: Obx(() {
        final user = _controller.currentUser.value;
        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        final posts = _visiblePosts;
        final totalPages = math.max(1, (posts.length / _pageSize).ceil());
        final activePage = _page.clamp(1, totalPages);
        if (activePage != _page) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _page = activePage);
            }
          });
        }
        final start = (activePage - 1) * _pageSize;
        final end = math.min(start + _pageSize, posts.length);
        final pagedPosts = posts.sublist(start, end);
        final isLoading = _socialPostsController.isLoading.value;
        final errorMessage = _socialPostsController.errorMessage.value;

        return RefreshIndicator(
          color: const Color(0xFF4F3CF0),
          onRefresh: () async {
            await _socialPostsController.loadPosts(refresh: true);
            if (mounted) {
              setState(() => _page = 1);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SocialCreateTopBar(onMenuTap: () => _openSidebar(user)),
                const SizedBox(height: 18),
                const Text(
                  'Posts',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF101A35),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage your drafted, scheduled, and published content.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF64728F),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _PostsActionButton(
                        label: 'Calendar',
                        icon: Icons.calendar_month_outlined,
                        outlined: true,
                        onTap: () => Get.offNamed(AppRoutes.socialCalendar),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PostsActionButton(
                        label: 'Create Post',
                        icon: Icons.add_rounded,
                        onTap: () => Get.offNamed(AppRoutes.socialCreate),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _PostsSearchField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {
                    _query = value;
                    _page = 1;
                  }),
                ),
                const SizedBox(height: 16),
                _PostsFilterChips(
                  filters: _filters,
                  selectedFilter: _selectedFilter,
                  onSelected: (filter) => setState(() {
                    _selectedFilter = filter;
                    _page = 1;
                  }),
                ),
                const SizedBox(height: 18),
                if (isLoading)
                  const _PostsLoadingState()
                else if (errorMessage != null)
                  _PostsErrorState(
                    message: errorMessage,
                    onRetry: () => _socialPostsController.loadPosts(),
                  )
                else if (posts.isEmpty)
                  const _PostsEmptyState()
                else
                  ...pagedPosts.map(
                    (post) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _SocialPostCard(
                        post: post,
                        onView: () => _showFullPost(post),
                        onEdit: post.status == 'Published'
                            ? null
                            : () => _editPost(post),
                        onDeleteDraft: post.status == 'Draft'
                            ? () => _confirmDeleteDraft(post)
                            : null,
                      ),
                    ),
                  ),
                if (!isLoading && errorMessage == null && posts.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _PostsPagination(
                    page: activePage,
                    totalPages: totalPages,
                    startItem: start + 1,
                    endItem: end,
                    totalItems: posts.length,
                    onPrevious: activePage == 1
                        ? null
                        : () => setState(() => _page = activePage - 1),
                    onNext: activePage >= totalPages
                        ? null
                        : () => setState(() => _page = activePage + 1),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _SocialPostItem {
  const _SocialPostItem({
    required this.id,
    required this.status,
    required this.platform,
    required this.caption,
    required this.hashtags,
    required this.date,
    required this.sortDate,
    this.scheduledAt,
    this.image,
  });

  final String id;
  final String status;
  final String platform;
  final String caption;
  final String hashtags;
  final String date;
  final DateTime sortDate;
  final DateTime? scheduledAt;
  final String? image;
}

class _PostsActionButton extends StatelessWidget {
  const _PostsActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: outlined
              ? null
              : const LinearGradient(
                  colors: [_socialBrandButtonStart, _socialBrandButtonEnd],
                ),
          color: outlined ? Colors.white : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: outlined ? const Color(0xFFD8E1EF) : Colors.transparent,
          ),
          boxShadow: outlined
              ? null
              : const [
                  BoxShadow(
                    color: _socialBrandButtonShadow,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: outlined ? const Color(0xFF101A35) : Colors.white,
              size: 22,
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: outlined ? const Color(0xFF101A35) : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostsPagination extends StatelessWidget {
  const _PostsPagination({
    required this.page,
    required this.totalPages,
    required this.startItem,
    required this.endItem,
    required this.totalItems,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final int startItem;
  final int endItem;
  final int totalItems;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBF3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$startItem-$endItem of $totalItems posts',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF64728F),
                fontSize: 12.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _PostsPaginationButton(
            icon: Icons.chevron_left_rounded,
            enabled: onPrevious != null,
            onTap: onPrevious,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$page/$totalPages',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF101A35),
                fontSize: 12.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _PostsPaginationButton(
            icon: Icons.chevron_right_rounded,
            enabled: onNext != null,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _PostsPaginationButton extends StatelessWidget {
  const _PostsPaginationButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF3F6FB) : const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE1E8F2)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? const Color(0xFF0A3F85) : const Color(0xFFB5C0D1),
        ),
      ),
    );
  }
}

class _PostsSearchField extends StatelessWidget {
  const _PostsSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Inter',
        color: Color(0xFF101A35),
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: 'Search posts...',
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF8B98B1),
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFF6A7892),
          size: 25,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDDE6F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF4F3CF0), width: 1.4),
        ),
      ),
    );
  }
}

class _PostsFilterChips extends StatelessWidget {
  const _PostsFilterChips({
    required this.filters,
    required this.selectedFilter,
    required this.onSelected,
  });

  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onSelected(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFF286DFF), Color(0xFF22C7BC)],
                        )
                      : null,
                  color: selected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : const Color(0xFFDDE6F2),
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: selected ? Colors.white : const Color(0xFF101A35),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SocialPostCard extends StatelessWidget {
  const _SocialPostCard({
    required this.post,
    required this.onView,
    this.onEdit,
    this.onDeleteDraft,
  });

  final _SocialPostItem post;
  final VoidCallback onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDeleteDraft;

  Color get _statusColor => switch (post.status) {
    'Published' => const Color(0xFF22C7A2),
    'Scheduled' => const Color(0xFFFFB020),
    'Failed' => const Color(0xFFE83E5A),
    _ => const Color(0xFFE8EDF4),
  };

  Color get _statusTextColor =>
      post.status == 'Draft' ? const Color(0xFF52627F) : Colors.white;

  String get _logo => switch (post.platform) {
    'INSTAGRAM' || 'instagram' => 'assets/images/instagram.png',
    'LINKEDIN' || 'linkedin' => 'assets/images/link.png',
    _ => 'assets/images/facebook.png',
  };

  String? get _resolvedImage =>
      post.image == null ? null : _resolveSocialImageUrl(post.image!);

  bool get _hasNetworkImage =>
      _resolvedImage?.startsWith('http://') == true ||
      _resolvedImage?.startsWith('https://') == true;

  bool get _hasBase64Image => _resolvedImage?.startsWith('data:image') == true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE6F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x090F2746),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_resolvedImage != null)
              Stack(
                children: [
                  if (_hasNetworkImage)
                    Image.network(
                      _resolvedImage!,
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const _PostImageFallback(),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const _PostImageFallback(showLoader: true);
                      },
                    )
                  else if (_hasBase64Image)
                    Image.memory(
                      base64Decode(_resolvedImage!.split(';base64,').last),
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const _PostImageFallback(),
                    )
                  else
                    Image.asset(
                      _resolvedImage!,
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const _PostImageFallback(),
                    ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _PostStatusBadge(
                      label: post.status,
                      color: _statusColor,
                      textColor: _statusTextColor,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _PostPlatformBubble(logo: _logo),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PostStatusBadge(
                      label: post.status,
                      color: _statusColor,
                      textColor: _statusTextColor,
                    ),
                    const Spacer(),
                    _PostPlatformBubble(logo: _logo),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.caption,
                    maxLines: post.image == null ? 5 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF101A35),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(height: 1, color: const Color(0xFFEAF0F7)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: Color(0xFF74839D),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          post.date,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF64728F),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _PostCardActions(
                        onView: onView,
                        onEdit: onEdit,
                        onDeleteDraft: onDeleteDraft,
                        compact: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostStatusBadge extends StatelessWidget {
  const _PostStatusBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PostPlatformBubble extends StatelessWidget {
  const _PostPlatformBubble({required this.logo});

  final String logo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F2746),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Image.asset(logo, fit: BoxFit.contain),
    );
  }
}

class _PostCardActions extends StatelessWidget {
  const _PostCardActions({
    required this.onView,
    this.onEdit,
    this.onDeleteDraft,
    this.compact = false,
  });

  final VoidCallback onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDeleteDraft;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PostActionIcon(
          icon: Icons.visibility_outlined,
          color: const Color(0xFF315C8C),
          onTap: onView,
          compact: compact,
        ),
        if (onEdit != null) ...[
          const SizedBox(width: 8),
          _PostActionIcon(
            icon: Icons.edit_outlined,
            color: const Color(0xFF2563EB),
            onTap: onEdit!,
            compact: compact,
          ),
        ],
        if (onDeleteDraft != null) ...[
          const SizedBox(width: 8),
          _PostActionIcon(
            icon: Icons.delete_outline_rounded,
            color: const Color(0xFFE83E5A),
            onTap: onDeleteDraft!,
            compact: compact,
          ),
        ],
      ],
    );
  }
}

class _PostActionIcon extends StatelessWidget {
  const _PostActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.compact,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 34.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.14)),
          ),
          child: Icon(icon, color: color, size: compact ? 17 : 19),
        ),
      ),
    );
  }
}

class _FullPostPreviewMedia extends StatelessWidget {
  const _FullPostPreviewMedia({required this.post});

  final _SocialPostItem post;

  String? get _resolvedImage =>
      post.image == null ? null : _resolveSocialImageUrl(post.image!);

  bool get _hasNetworkImage =>
      _resolvedImage?.startsWith('http://') == true ||
      _resolvedImage?.startsWith('https://') == true;

  bool get _hasBase64Image => _resolvedImage?.startsWith('data:image') == true;

  String get _logo => switch (post.platform) {
    'INSTAGRAM' || 'instagram' => 'assets/images/instagram.png',
    'LINKEDIN' || 'linkedin' => 'assets/images/link.png',
    _ => 'assets/images/facebook.png',
  };

  Color get _statusColor => switch (post.status) {
    'Published' => const Color(0xFF22C7A2),
    'Scheduled' => const Color(0xFFFFB020),
    'Failed' => const Color(0xFFE83E5A),
    _ => const Color(0xFFE8EDF4),
  };

  Color get _statusTextColor =>
      post.status == 'Draft' ? const Color(0xFF52627F) : Colors.white;

  @override
  Widget build(BuildContext context) {
    if (_resolvedImage == null) {
      return Row(
        children: [
          _PostStatusBadge(
            label: post.status,
            color: _statusColor,
            textColor: _statusTextColor,
          ),
          const Spacer(),
          _PostPlatformBubble(logo: _logo),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          if (_hasNetworkImage)
            Image.network(
              _resolvedImage!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const _PostImageFallback(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const _PostImageFallback(showLoader: true);
              },
            )
          else if (_hasBase64Image)
            Image.memory(
              base64Decode(_resolvedImage!.split(';base64,').last),
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const _PostImageFallback(),
            )
          else
            Image.asset(
              _resolvedImage!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const _PostImageFallback(),
            ),
          Positioned(
            left: 12,
            top: 12,
            child: _PostStatusBadge(
              label: post.status,
              color: _statusColor,
              textColor: _statusTextColor,
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: _PostPlatformBubble(logo: _logo),
          ),
        ],
      ),
    );
  }
}

class _PostsEmptyState extends StatelessWidget {
  const _PostsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE6F2)),
      ),
      child: const Text(
        'No posts match this filter yet.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF64728F),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PostsLoadingState extends StatelessWidget {
  const _PostsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE6F2)),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: Color(0xFF4F3CF0)),
          SizedBox(height: 16),
          Text(
            'Loading your social posts...',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF64728F),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostsErrorState extends StatelessWidget {
  const _PostsErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD6DF)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFE83E5A),
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF64728F),
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Try again',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF4F3CF0),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostImageFallback extends StatelessWidget {
  const _PostImageFallback({this.showLoader = false});

  final bool showLoader;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      width: double.infinity,
      color: const Color(0xFFF3F7FD),
      child: Center(
        child: showLoader
            ? const CircularProgressIndicator(color: Color(0xFF4F3CF0))
            : const Icon(
                Icons.image_not_supported_outlined,
                color: Color(0xFF8B98B1),
                size: 36,
              ),
      ),
    );
  }
}

String _formatSocialPostDate(DateTime value) {
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
  final local = value.toLocal();
  final month = months[(local.month - 1).clamp(0, 11)];
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$month ${local.day}, ${local.year} at $hour12:$minute $period';
}

class SocialReportsView extends StatefulWidget {
  const SocialReportsView({super.key});

  @override
  State<SocialReportsView> createState() => _SocialReportsViewState();
}

class _SocialReportsViewState extends State<SocialReportsView> {
  final OnboardingController _controller = Get.find<OnboardingController>();
  late final SocialReportsController _reportsController =
      Get.isRegistered<SocialReportsController>()
      ? Get.find<SocialReportsController>()
      : Get.put(SocialReportsController());
  bool _isSidebarOpen = false;
  String _range = 'Last 28 days';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reportsController.loadReports(range: _range);
    });
  }

  Future<void> _openSidebar(TestAccount user) async {
    if (_isSidebarOpen) return;
    setState(() => _isSidebarOpen = true);
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierLabel: 'Social sidebar',
        barrierDismissible: true,
        barrierColor: const Color(0x800F2746),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          final safeTop = MediaQuery.paddingOf(dialogContext).top;
          final safeBottom = MediaQuery.paddingOf(dialogContext).bottom;
          final sidebarWidth = MediaQuery.sizeOf(dialogContext).width * 0.8;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(dialogContext).pop(),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: TweenAnimationBuilder<Offset>(
                  tween: Tween(begin: const Offset(-1.02, 0), end: Offset.zero),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  builder: (context, offset, child) {
                    return FractionalTranslation(
                      translation: offset,
                      child: child,
                    );
                  },
                  child: SizedBox(
                    width: sidebarWidth,
                    height: double.infinity,
                    child: SocialSidebarPanel(
                      user: user,
                      safeTopInset: safeTop,
                      safeBottomInset: safeBottom,
                      onDashboardTap: () {
                        Navigator.of(dialogContext).pop();
                        Get.offNamed(AppRoutes.socialDashboard);
                      },
                      onAccountsTap: () {
                        Navigator.of(dialogContext).pop();
                        Get.offNamed(AppRoutes.socialAccounts);
                      },
                      onCreateTap: () {
                        Navigator.of(dialogContext).pop();
                        Get.offNamed(AppRoutes.socialCreate);
                      },
                      onCreativesTap: () {
                        Navigator.of(dialogContext).pop();
                        Get.offNamed(AppRoutes.socialCreatives);
                      },
                      onCalendarTap: () {
                        Navigator.of(dialogContext).pop();
                        Get.offNamed(AppRoutes.socialCalendar);
                      },
                      onSchedulerTap: () {
                        Navigator.of(dialogContext).pop();
                        Get.offNamed(AppRoutes.socialScheduler);
                      },
                      onPostsTap: () {
                        Navigator.of(dialogContext).pop();
                        Get.offNamed(AppRoutes.socialPosts);
                      },
                      onAnalyticsTap: () {
                        Navigator.of(dialogContext).pop();
                        Get.offNamed(AppRoutes.socialAnalytics);
                      },
                      onReportsTap: () => Navigator.of(dialogContext).pop(),
                      onProfileTap: () {
                        Navigator.of(dialogContext).pop();
                        Get.offNamed(AppRoutes.socialProfile);
                      },
                      onPaymentTap: () {
                        Navigator.of(dialogContext).pop();
                        Get.offNamed(AppRoutes.payment);
                      },
                      onSupportTap: () {
                        Navigator.of(dialogContext).pop();
                        Get.toNamed(AppRoutes.support);
                      },
                      onCollapseTap: () => Navigator.of(dialogContext).pop(),
                      onLogoutTap: () {
                        Navigator.of(dialogContext).pop();
                        _controller.logout();
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _isSidebarOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productModeController = Get.isRegistered<ProductModeController>()
        ? Get.find<ProductModeController>()
        : Get.put(ProductModeController(), permanent: true);
    if (!productModeController.isSocialMedia) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        productModeController.selectMode(ProductMode.socialMedia);
      });
    }

    return AuthNavigationShell(
      currentTab: AuthTab.socialAnalytics,
      backgroundColor: const Color(0xFFFBFCFF),
      child: Obx(() {
        final user = _controller.currentUser.value;
        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        _reportsController.loadIfBusinessOrRangeChanged(_range);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SocialCreateTopBar(onMenuTap: () => _openSidebar(user)),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reports',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF101A35),
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Create, analyze and export performance reports.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF64728F),
                            fontSize: 12.8,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ReportsExportButton(label: 'Export', onTap: () {}),
                ],
              ),
              const SizedBox(height: 14),
              _AnalyticsRangeButton(
                value: _range,
                onSelected: (value) {
                  setState(() => _range = value);
                  _reportsController.loadReports(range: value);
                },
              ),
              const SizedBox(height: 14),
              Obx(() {
                final dashboard = _reportsController.dashboard.value;
                final isLoading = _reportsController.isLoading.value;
                final error = _reportsController.errorMessage.value;

                if (isLoading && dashboard == null) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 42),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF563DF1),
                      ),
                    ),
                  );
                }

                if (error != null && dashboard == null) {
                  return _ReportsErrorState(
                    message: error,
                    onRetry: () => _reportsController.loadReports(
                      range: _range,
                      forceRefresh: true,
                    ),
                  );
                }

                if (dashboard == null) {
                  return const _ReportsEmptyState(
                    message: 'No report data available yet.',
                  );
                }

                if (dashboard.raw['connected'] == false) {
                  return const _ReportsEmptyState(
                    message:
                        'Connect Facebook, Instagram, or LinkedIn accounts to unlock reports.',
                  );
                }

                return Column(
                  children: [
                    _ReportsMetricGrid(dashboard: dashboard),
                    const SizedBox(height: 18),
                    _ReportsSummaryCard(dashboard: dashboard),
                    const SizedBox(height: 18),
                    _ReportsTimelineCard(dashboard: dashboard),
                    const SizedBox(height: 18),
                    _ReportsPlatformExecutionCard(dashboard: dashboard),
                    const SizedBox(height: 18),
                    _ReportsMixAndQueueSection(dashboard: dashboard),
                    const SizedBox(height: 18),
                    _ReportsRecentActivityCard(dashboard: dashboard),
                  ],
                );
              }),
            ],
          ),
        );
      }),
    );
  }
}

class _ReportsExportButton extends StatelessWidget {
  const _ReportsExportButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF286DFF), Color(0xFF6D35F5)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2A573EF2),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _reportsFmt(dynamic value) => _analyticsFmt(value);

String _reportsPlatformName(String platform) {
  final value = platform.toLowerCase();
  if (value.contains('facebook')) return 'Facebook';
  if (value.contains('instagram')) return 'Instagram';
  if (value.contains('linkedin')) return 'LinkedIn';
  return platform.isEmpty ? 'Platform' : platform;
}

String _reportsPlatformLogo(String platform) {
  final value = platform.toLowerCase();
  if (value.contains('facebook')) return 'assets/images/facebook.png';
  if (value.contains('instagram')) return 'assets/images/instagram.png';
  if (value.contains('linkedin')) return 'assets/images/link.png';
  return 'assets/images/link.png';
}

Color _reportsPlatformColor(String platform) {
  final value = platform.toLowerCase();
  if (value.contains('facebook')) return const Color(0xFF2373FF);
  if (value.contains('instagram')) return const Color(0xFFE23FA5);
  if (value.contains('linkedin')) return const Color(0xFF0A75BD);
  return const Color(0xFF6545F6);
}

String _reportsDate(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return value?.toString() ?? '';
  return '${parsed.month}/${parsed.day}/${parsed.year}';
}

String _reportsTime(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return '';
  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final period = parsed.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

class _ReportsEmptyState extends StatelessWidget {
  const _ReportsEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _ReportsSectionCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Column(
          children: [
            const Icon(
              Icons.insights_outlined,
              color: Color(0xFF7C6CF5),
              size: 34,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF64728F),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportsErrorState extends StatelessWidget {
  const _ReportsErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _ReportsSectionCard(
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFE83E5A),
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF64728F),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _ReportsOutlineButton(label: 'Retry', onTap: onRetry),
        ],
      ),
    );
  }
}

class _ReportsMetricGrid extends StatelessWidget {
  const _ReportsMetricGrid({required this.dashboard});

  final ReportsDashboard dashboard;

  List<_ReportsMetricData> get _items {
    final summary = dashboard.summary;
    return [
      _ReportsMetricData(
        title: 'Connected\nAccounts',
        value: _reportsFmt(summary['connectedAccounts']),
        detail: '${_reportsFmt(summary['activeAccounts'])} active now',
        icon: Icons.groups_outlined,
        tint: const Color(0xFFEAF1FF),
        color: const Color(0xFF286DFF),
      ),
      _ReportsMetricData(
        title: 'Creatives\nCreated',
        value: _reportsFmt(summary['creativesCreated']),
        detail: '${_reportsFmt(summary['creativesCreatedPct'])}% vs prev.',
        icon: Icons.auto_awesome_rounded,
        tint: const Color(0xFFF0EAFF),
        color: const Color(0xFF7446F8),
      ),
      _ReportsMetricData(
        title: 'Posts\nCreated',
        value: _reportsFmt(summary['postsCreated']),
        detail: '${_reportsFmt(summary['postsCreatedPct'])}% vs prev.',
        icon: Icons.description_outlined,
        tint: const Color(0xFFE8F6FF),
        color: const Color(0xFF168CEB),
      ),
      _ReportsMetricData(
        title: 'Media\nPublished',
        value: _reportsFmt(summary['mediaPublished']),
        detail: '${_reportsFmt(summary['mediaPublishedPct'])}% vs prev.',
        icon: Icons.near_me_outlined,
        tint: const Color(0xFFE7FAF1),
        color: const Color(0xFF15B882),
      ),
      _ReportsMetricData(
        title: 'Scheduled',
        value: _reportsFmt(summary['scheduledItems']),
        detail: '${_reportsFmt(summary['scheduledItemsPct'])}% vs prev.',
        icon: Icons.calendar_month_outlined,
        tint: const Color(0xFFFFF4E4),
        color: const Color(0xFFFF8A00),
      ),
      _ReportsMetricData(
        title: 'Pending\nApproval',
        value: _reportsFmt(summary['pendingApproval']),
        detail: '${_reportsFmt(summary['draftItems'])} drafts',
        icon: Icons.schedule_rounded,
        tint: const Color(0xFFFFEEE8),
        color: const Color(0xFFFF5A24),
      ),
      _ReportsMetricData(
        title: 'Queue\nActive',
        value: _reportsFmt(summary['queueActive']),
        detail: '${_reportsFmt(summary['queueCompleted'])} completed',
        icon: Icons.layers_outlined,
        tint: const Color(0xFFE6F9FC),
        color: const Color(0xFF18AFC6),
      ),
      _ReportsMetricData(
        title: 'Failed\nItems',
        value: _reportsFmt(summary['failedItems']),
        detail: '${_reportsFmt(summary['failedItemsPct'])}% vs prev.',
        icon: Icons.gpp_maybe_outlined,
        tint: const Color(0xFFFFEAF0),
        color: const Color(0xFFE83E5A),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 9,
        crossAxisSpacing: 9,
        childAspectRatio: 2.06,
      ),
      itemBuilder: (context, index) => _ReportsMetricCard(data: _items[index]),
    );
  }
}

class _ReportsMetricData {
  const _ReportsMetricData({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.tint,
    required this.color,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color tint;
  final Color color;
}

class _ReportsMetricCard extends StatelessWidget {
  const _ReportsMetricCard({required this.data});

  final _ReportsMetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE6F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F2746),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: data.tint, shape: BoxShape.circle),
            child: Icon(data.icon, color: data.color, size: 19),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title.replaceAll('\n', ' '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF61708E),
                    fontSize: 10.4,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      data.value,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF101A35),
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: Text(
                          data.detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: data.detail.contains('active')
                                ? const Color(0xFF09A86F)
                                : const Color(0xFF64728F),
                            fontSize: 9.4,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsSectionCard extends StatelessWidget {
  const _ReportsSectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE6F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F2746),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ReportsSummaryCard extends StatelessWidget {
  const _ReportsSummaryCard({required this.dashboard});

  final ReportsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final performance = dashboard.performanceSummary;
    final bestPlatform = (performance['bestPlatform'] ?? '').toString();
    final queueScore = _reportsFmt(performance['queueHealthScore']);
    final summaryText = bestPlatform.isEmpty
        ? 'Connect channels to start generating real operational summaries.'
        : '${_reportsPlatformName(bestPlatform)} led publishing volume while queue health held at $queueScore.';
    return _ReportsSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Report Summary',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF101A35),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _ReportsOutlineButton(label: 'Download', onTap: () {}),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF2F6FF),
                  Color(0xFFF9F3FF),
                  Color(0xFFFFFBFF),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE4E9FF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x105843F5),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -24,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6545F6).withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const _ReportsHealthPulse(),
                    const SizedBox(width: 15),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF64728F),
                            fontSize: 13.2,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Operations pulse\n',
                              style: TextStyle(
                                color: Color(0xFF101A35),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const TextSpan(
                              text: 'looks healthy\n',
                              style: TextStyle(
                                color: Color(0xFF6545F6),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextSpan(text: summaryText),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsOutlineButton extends StatelessWidget {
  const _ReportsOutlineButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF5B47F6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.download_rounded,
              size: 18,
              color: Color(0xFF5B47F6),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF4938D8),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportsHealthPulse extends StatelessWidget {
  const _ReportsHealthPulse();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.84 + (value * 0.16),
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF5849F5).withValues(alpha: 0.16),
                  const Color(0xFF5849F5).withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF7764FF), Color(0xFF4E38E8)],
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReportsTimelineCard extends StatelessWidget {
  const _ReportsTimelineCard({required this.dashboard});

  final ReportsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final timeline = dashboard.timeline;
    final summary = dashboard.summary;
    final series = [
      (
        color: const Color(0xFF6D4BF6),
        values: timeline
            .map((row) => _analyticsNum(row['creativesCreated']).toDouble())
            .toList(growable: false),
      ),
      (
        color: const Color(0xFF286DFF),
        values: timeline
            .map((row) => _analyticsNum(row['postsCreated']).toDouble())
            .toList(growable: false),
      ),
      (
        color: const Color(0xFF18B884),
        values: timeline
            .map((row) => _analyticsNum(row['mediaPublished']).toDouble())
            .toList(growable: false),
      ),
      (
        color: const Color(0xFFFF9D12),
        values: timeline
            .map((row) => _analyticsNum(row['scheduled']).toDouble())
            .toList(growable: false),
      ),
      (
        color: const Color(0xFFE83E5A),
        values: timeline
            .map((row) => _analyticsNum(row['failed']).toDouble())
            .toList(growable: false),
      ),
    ];
    final maxY = math.max(
      1,
      series
          .expand((line) => line.values)
          .fold<double>(0, (maxValue, value) => math.max(maxValue, value))
          .ceil(),
    );
    final labels = timeline.isEmpty
        ? <String>[]
        : timeline
              .where(
                (row) =>
                    timeline.indexOf(row) % math.max(1, timeline.length ~/ 5) ==
                    0,
              )
              .map((row) {
                final parsed = DateTime.tryParse(row['date']?.toString() ?? '');
                final month = _calendarShortMonth(
                  parsed?.month ?? DateTime.now().month,
                );
                final day = (parsed?.day ?? 0).toString().padLeft(2, '0');
                return '$month $day';
              })
              .take(6)
              .toList(growable: false);

    return _ReportsSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Production Timeline',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF101A35),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _ReportsLegendDot(
                'Creatives',
                _reportsFmt(summary['creativesCreated']),
                const Color(0xFF6D4BF6),
              ),
              _ReportsLegendDot(
                'Posts',
                _reportsFmt(summary['postsCreated']),
                const Color(0xFF286DFF),
              ),
              _ReportsLegendDot(
                'Published',
                _reportsFmt(summary['mediaPublished']),
                const Color(0xFF18B884),
              ),
              _ReportsLegendDot(
                'Scheduled',
                _reportsFmt(summary['scheduledItems']),
                const Color(0xFFFF9D12),
              ),
              _ReportsLegendDot(
                'Failed',
                _reportsFmt(summary['failedItems']),
                const Color(0xFFE83E5A),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: _AnalyticsLinePainter(
                      series: series,
                      maxY: maxY.toDouble(),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: labels
                      .map((label) => _AxisLabel(label))
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsLegendDot extends StatelessWidget {
  const _ReportsLegendDot(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF64728F),
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF101A35),
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ReportsPlatformExecutionCard extends StatelessWidget {
  const _ReportsPlatformExecutionCard({required this.dashboard});

  final ReportsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final rows = dashboard.platformBreakdown;
    return _ReportsSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Platform Execution',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF101A35),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View all',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF563DF1),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            const _ReportsEmptyState(
              message: 'No platform execution data for this range.',
            )
          else
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReportsPlatformCard(
                  name: _reportsPlatformName(row['platform']?.toString() ?? ''),
                  logo: _reportsPlatformLogo(row['platform']?.toString() ?? ''),
                  topColor: _reportsPlatformColor(
                    row['platform']?.toString() ?? '',
                  ),
                  activeAccounts: _reportsFmt(row['activeAccounts']),
                  connectedAccounts: _reportsFmt(row['connectedAccounts']),
                  posts: _reportsFmt(row['postsCreated']),
                  published: _reportsFmt(row['mediaPublished']),
                  scheduled: _reportsFmt(row['scheduledItems']),
                  failed: _reportsFmt(row['failedItems']),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportsPlatformCard extends StatelessWidget {
  const _ReportsPlatformCard({
    required this.name,
    required this.logo,
    required this.topColor,
    required this.posts,
    required this.published,
    required this.scheduled,
    required this.failed,
    required this.activeAccounts,
    required this.connectedAccounts,
  });

  final String name;
  final String logo;
  final Color topColor;
  final String posts;
  final String published;
  final String scheduled;
  final String failed;
  final String activeAccounts;
  final String connectedAccounts;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE6F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F2746),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [topColor, topColor.withValues(alpha: 0.55)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(logo, width: 36, height: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF101A35),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5FA),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$activeAccounts/$connectedAccounts active',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF61708E),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ReportsMiniStat(label: 'Posts', value: posts),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: _ReportsMiniStat(
                          label: 'Published',
                          value: published,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: _ReportsMiniStat(
                          label: 'Scheduled',
                          value: scheduled,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: _ReportsMiniStat(
                          label: 'Failed',
                          value: failed,
                          alert: failed != '0',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportsMiniStat extends StatelessWidget {
  const _ReportsMiniStat({
    required this.label,
    required this.value,
    this.alert = false,
  });

  final String label;
  final String value;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE7EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF64728F),
              fontSize: 9.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              color: alert ? const Color(0xFFE83E5A) : const Color(0xFF101A35),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsMixAndQueueSection extends StatelessWidget {
  const _ReportsMixAndQueueSection({required this.dashboard});

  final ReportsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ReportsOutputMixCard(dashboard: dashboard),
        const SizedBox(height: 18),
        _ReportsQueueHealthCard(dashboard: dashboard),
      ],
    );
  }
}

class _ReportsOutputMixCard extends StatelessWidget {
  const _ReportsOutputMixCard({required this.dashboard});

  final ReportsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final rows = dashboard.creativeBreakdown;
    final total = rows.fold<num>(
      0,
      (sum, row) => sum + _analyticsNum(row['count']),
    );
    final colors = [
      const Color(0xFF6545F6),
      const Color(0xFF8B4AF5),
      const Color(0xFF13BBD0),
      const Color(0xFF18B884),
      const Color(0xFFFF9D12),
      const Color(0xFFE83E5A),
    ];

    return _ReportsSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReportsCardTitleWithBadge(
            title: 'Creative Output Mix',
            badge: 'Total ${total.toInt()}',
            icon: Icons.pie_chart_outline_rounded,
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            const _ReportsInlineEmpty('No creative output recorded.')
          else
            ...rows.take(6).toList().asMap().entries.map((entry) {
              final row = entry.value;
              final count = _analyticsNum(row['count']);
              final pct = total == 0 ? 0 : (count / total) * 100;
              return _ReportsProgressRow(
                (row['type'] ?? 'creative').toString(),
                _reportsFmt(count),
                '${pct.toStringAsFixed(1)}%',
                colors[entry.key % colors.length],
                total == 0 ? 0 : count / total,
              );
            }),
        ],
      ),
    );
  }
}

class _ReportsQueueHealthCard extends StatelessWidget {
  const _ReportsQueueHealthCard({required this.dashboard});

  final ReportsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final health = dashboard.queueHealth;
    final rows = [
      (
        Icons.schedule_rounded,
        'Queued',
        _analyticsNum(health['queued']),
        const Color(0xFF8B98B1),
      ),
      (
        Icons.settings_outlined,
        'Processing',
        _analyticsNum(health['processing']),
        const Color(0xFF8B98B1),
      ),
      (
        Icons.sync_rounded,
        'Retrying',
        _analyticsNum(health['retrying']),
        const Color(0xFF8B98B1),
      ),
      (
        Icons.check_circle_outline_rounded,
        'Completed',
        _analyticsNum(health['completed']),
        const Color(0xFF18B884),
      ),
      (
        Icons.error_outline_rounded,
        'Failed',
        _analyticsNum(health['failed']),
        const Color(0xFFE83E5A),
      ),
    ];
    final maxValue = rows.fold<num>(
      1,
      (maxValue, row) => math.max(maxValue, row.$3),
    );

    return _ReportsSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReportsCardTitleWithBadge(
            title: 'Queue Health',
            badge: 'Healthy',
            icon: Icons.check_circle_outline_rounded,
            healthy: true,
          ),
          const SizedBox(height: 16),
          ...rows.map(
            (row) => _ReportsQueueRow(
              row.$1,
              row.$2,
              _reportsFmt(row.$3),
              row.$4,
              maxValue == 0 ? 0 : row.$3 / maxValue,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsInlineEmpty extends StatelessWidget {
  const _ReportsInlineEmpty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EDF5)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF64728F),
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReportsCardTitleWithBadge extends StatelessWidget {
  const _ReportsCardTitleWithBadge({
    required this.title,
    required this.badge,
    required this.icon,
    this.healthy = false,
  });

  final String title;
  final String badge;
  final IconData icon;
  final bool healthy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFFF0EAFF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF6545F6), size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF101A35),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: healthy ? const Color(0xFFE8FAF2) : const Color(0xFFF4F1FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            badge,
            style: TextStyle(
              fontFamily: 'Inter',
              color: healthy
                  ? const Color(0xFF09A86F)
                  : const Color(0xFF6545F6),
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportsProgressRow extends StatelessWidget {
  const _ReportsProgressRow(
    this.label,
    this.value,
    this.percent,
    this.color,
    this.progress,
  );

  final String label;
  final String value;
  final String percent;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _ReportsAnimatedIconBubble(
            icon: Icons.auto_awesome_rounded,
            color: color,
            size: 28,
            iconSize: 16,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 118,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF101A35),
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: _ReportsProgressMeter(
              progress: progress,
              color: color,
              height: 7,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$value  ($percent)',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF101A35),
              fontSize: 11.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsProgressMeter extends StatefulWidget {
  const _ReportsProgressMeter({
    required this.progress,
    required this.color,
    required this.height,
  });

  final double progress;
  final Color color;
  final double height;

  @override
  State<_ReportsProgressMeter> createState() => _ReportsProgressMeterState();
}

class _ReportsProgressMeterState extends State<_ReportsProgressMeter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1650),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetProgress = widget.progress.clamp(0.02, 1).toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: targetProgress),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, fillValue, child) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final shimmerX = -1.0 + (_controller.value * 2.4);
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0F7),
                borderRadius: BorderRadius.circular(999),
              ),
              clipBehavior: Clip.antiAlias,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fillValue,
                child: ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment(shimmerX - 0.6, 0),
                      end: Alignment(shimmerX + 0.6, 0),
                      colors: [
                        widget.color.withValues(alpha: 0.76),
                        widget.color,
                        Colors.white.withValues(alpha: 0.58),
                        widget.color,
                        widget.color.withValues(alpha: 0.8),
                      ],
                      stops: const [0, 0.34, 0.5, 0.66, 1],
                    ).createShader(rect);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ReportsAnimatedIconBubble extends StatelessWidget {
  const _ReportsAnimatedIconBubble({
    required this.icon,
    required this.color,
    required this.size,
    required this.iconSize,
    this.shape = BoxShape.rectangle,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.84 + (value * 0.16),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: shape,
              borderRadius: shape == BoxShape.rectangle
                  ? BorderRadius.circular(8)
                  : null,
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
        );
      },
    );
  }
}

class _ReportsQueueRow extends StatelessWidget {
  const _ReportsQueueRow(
    this.icon,
    this.label,
    this.value,
    this.color,
    this.progress,
  );

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          _ReportsAnimatedIconBubble(
            icon: icon,
            color: color,
            size: 26,
            iconSize: 15,
            shape: BoxShape.circle,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF64728F),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: _ReportsProgressMeter(
              progress: progress,
              color: color,
              height: 6,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF101A35),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsRecentActivityCard extends StatefulWidget {
  const _ReportsRecentActivityCard({required this.dashboard});

  final ReportsDashboard dashboard;

  @override
  State<_ReportsRecentActivityCard> createState() =>
      _ReportsRecentActivityCardState();
}

class _ReportsRecentActivityCardState
    extends State<_ReportsRecentActivityCard> {
  static const int _pageSize = 10;
  int _page = 1;

  @override
  void didUpdateWidget(covariant _ReportsRecentActivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dashboard != widget.dashboard) {
      _page = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allRows = widget.dashboard.recentActivity;
    final totalPages = math.max(1, (allRows.length / _pageSize).ceil());
    final activePage = _page.clamp(1, totalPages);
    if (activePage != _page) {
      _page = activePage;
    }
    final start = (activePage - 1) * _pageSize;
    final end = math.min(start + _pageSize, allRows.length);
    final rows = allRows.sublist(start, end);

    return _ReportsSectionCard(
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF101A35),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'View all',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF563DF1),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (rows.isEmpty)
            const _ReportsInlineEmpty(
              'No report activity landed inside this time window.',
            )
          else
            ...rows.asMap().entries.map((entry) {
              final row = entry.value;
              final kind = (row['kind'] ?? '').toString();
              final tone = _reportsActivityTone(kind);
              return _ReportsActivityRow(
                title: (row['title'] ?? 'Untitled activity').toString(),
                type: tone.$1,
                platform: (row['platform'] ?? '').toString().toUpperCase(),
                detail: (row['detail'] ?? '').toString(),
                date: _reportsDate(row['happenedAt']),
                time: _reportsTime(row['happenedAt']),
                icon: tone.$2,
                iconColor: tone.$3,
                isLast: entry.key == rows.length - 1,
              );
            }),
          if (allRows.length > _pageSize) ...[
            const SizedBox(height: 14),
            _ReportsActivityPagination(
              start: start + 1,
              end: end,
              total: allRows.length,
              page: activePage,
              totalPages: totalPages,
              onPrevious: activePage == 1
                  ? null
                  : () => setState(() => _page = activePage - 1),
              onNext: activePage == totalPages
                  ? null
                  : () => setState(() => _page = activePage + 1),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportsActivityPagination extends StatelessWidget {
  const _ReportsActivityPagination({
    required this.start,
    required this.end,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int start;
  final int end;
  final int total;
  final int page;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE7EDF5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $start-$end of $total',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF64728F),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '$page/$totalPages',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF101A35),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          _ReportsPagerButton(
            icon: Icons.chevron_left_rounded,
            onTap: onPrevious,
          ),
          const SizedBox(width: 8),
          _ReportsPagerButton(icon: Icons.chevron_right_rounded, onTap: onNext),
        ],
      ),
    );
  }
}

class _ReportsPagerButton extends StatelessWidget {
  const _ReportsPagerButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF4F1FF) : const Color(0xFFF3F6FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? const Color(0xFFD8D2FF) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? const Color(0xFF563DF1) : const Color(0xFF9AA8BF),
          size: 20,
        ),
      ),
    );
  }
}

(String, IconData, Color) _reportsActivityTone(String kind) {
  final value = kind.toLowerCase();
  if (value.contains('creative')) {
    return ('Creative', Icons.auto_awesome_rounded, const Color(0xFF7446F8));
  }
  if (value.contains('publish')) {
    return ('Published', Icons.near_me_outlined, const Color(0xFF18B884));
  }
  if (value.contains('failure') || value.contains('failed')) {
    return ('Failed', Icons.error_outline_rounded, const Color(0xFFE83E5A));
  }
  if (value.contains('schedule')) {
    return (
      'Scheduled',
      Icons.calendar_month_outlined,
      const Color(0xFFFF8A00),
    );
  }
  return ('Post', Icons.description_outlined, const Color(0xFF286DFF));
}

class _ReportsActivityRow extends StatelessWidget {
  const _ReportsActivityRow({
    required this.title,
    required this.type,
    required this.platform,
    required this.detail,
    required this.date,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isLast = false,
  });

  final String title;
  final String type;
  final String platform;
  final String detail;
  final String date;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EDF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF101A35),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _ReportsPill(label: type, color: const Color(0xFF7446F8)),
                    _ReportsPill(
                      label: platform,
                      color: const Color(0xFF64728F),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF64728F),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF101A35),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                time,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF64728F),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportsPill extends StatelessWidget {
  const _ReportsPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class SocialAnalyticsView extends StatefulWidget {
  const SocialAnalyticsView({super.key});

  @override
  State<SocialAnalyticsView> createState() => _SocialAnalyticsViewState();
}

class _SocialAnalyticsViewState extends State<SocialAnalyticsView> {
  final OnboardingController _controller = Get.find<OnboardingController>();
  late final SocialAnalyticsController _analyticsController =
      Get.isRegistered<SocialAnalyticsController>()
      ? Get.find<SocialAnalyticsController>()
      : Get.put(SocialAnalyticsController());
  bool _isSidebarOpen = false;
  int _selectedTab = 0;
  String _range = 'Last 28 days';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analyticsController.loadAnalytics(range: _range);
    });
  }

  Future<void> _openSidebar(TestAccount user) async {
    if (_isSidebarOpen) {
      return;
    }
    setState(() => _isSidebarOpen = true);
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierLabel: 'Social sidebar',
        barrierDismissible: true,
        barrierColor: const Color(0x800F2746),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          final safeTop = MediaQuery.paddingOf(dialogContext).top;
          final safeBottom = MediaQuery.paddingOf(dialogContext).bottom;
          final sidebarWidth = MediaQuery.sizeOf(dialogContext).width * 0.8;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(dialogContext).pop(),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: TweenAnimationBuilder<Offset>(
                      tween: Tween(
                        begin: const Offset(-1.02, 0),
                        end: Offset.zero,
                      ),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      builder: (context, offset, child) {
                        return FractionalTranslation(
                          translation: offset,
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: sidebarWidth,
                        height: double.infinity,
                        child: SocialSidebarPanel(
                          user: user,
                          safeTopInset: safeTop,
                          safeBottomInset: safeBottom,
                          onDashboardTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialDashboard);
                          },
                          onAccountsTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialAccounts);
                          },
                          onCreateTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialCreate);
                          },
                          onCreativesTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialCreatives);
                          },
                          onCalendarTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialCalendar);
                          },
                          onSchedulerTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialScheduler);
                          },
                          onPostsTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialPosts);
                          },
                          onAnalyticsTap: () =>
                              Navigator.of(dialogContext).pop(),
                          onProfileTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialProfile);
                          },
                          onPaymentTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.payment);
                          },
                          onSupportTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.toNamed(AppRoutes.support);
                          },
                          onCollapseTap: () =>
                              Navigator.of(dialogContext).pop(),
                          onLogoutTap: () {
                            Navigator.of(dialogContext).pop();
                            _controller.logout();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSidebarOpen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productModeController = Get.isRegistered<ProductModeController>()
        ? Get.find<ProductModeController>()
        : Get.put(ProductModeController(), permanent: true);
    if (!productModeController.isSocialMedia) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        productModeController.selectMode(ProductMode.socialMedia);
      });
    }

    return AuthNavigationShell(
      currentTab: AuthTab.socialAnalytics,
      backgroundColor: const Color(0xFFFBFCFF),
      child: Obx(() {
        final user = _controller.currentUser.value;
        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _analyticsController.loadIfBusinessOrRangeChanged(_range);
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SocialCreateTopBar(onMenuTap: () => _openSidebar(user)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedTab == 2
                              ? 'Analytics'
                              : 'Social Media Analytics',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF101A35),
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _selectedTab == 2
                              ? 'Instagram performance overview'
                              : 'Track performance across your social media accounts.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF64728F),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _AnalyticsTabBar(
                selectedIndex: _selectedTab,
                onSelected: (index) {
                  setState(() {
                    _selectedTab = index;
                    _range = index >= 2 ? 'Last 60 days' : 'Last 28 days';
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _AnalyticsRangeButton(
                    value: _range,
                    onSelected: (value) {
                      setState(() => _range = value);
                      _analyticsController.loadAnalytics(range: value);
                    },
                  ),
                  const Spacer(),
                  _AnalyticsExportButton(
                    showText: _selectedTab != 0,
                    onTap: () {
                      Get.snackbar(
                        'Export ready',
                        'Analytics export will use the currently loaded report data.',
                        snackPosition: SnackPosition.BOTTOM,
                        margin: const EdgeInsets.all(12),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Obx(() {
                final dashboard = _analyticsController.dashboard.value;
                final error = _analyticsController.errorMessage.value;
                if (_analyticsController.isLoading.value && dashboard == null) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 34),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5A4CFF),
                      ),
                    ),
                  );
                }
                if (error != null && dashboard == null) {
                  return _AnalyticsErrorState(
                    message: error,
                    onRetry: () =>
                        _analyticsController.loadAnalytics(range: _range),
                  );
                }
                if (dashboard == null) {
                  return _AnalyticsErrorState(
                    message: 'No analytics data is available yet.',
                    onRetry: () =>
                        _analyticsController.loadAnalytics(range: _range),
                  );
                }

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: switch (_selectedTab) {
                    0 => _AnalyticsAllSection(
                      key: const ValueKey('all'),
                      dashboard: dashboard,
                    ),
                    1 => _AnalyticsFacebookSection(
                      key: const ValueKey('facebook'),
                      dashboard: dashboard,
                    ),
                    2 => _AnalyticsInstagramSection(
                      key: const ValueKey('instagram'),
                      dashboard: dashboard,
                    ),
                    _ => _AnalyticsLinkedInSection(
                      key: const ValueKey('linkedin'),
                      dashboard: dashboard,
                    ),
                  },
                );
              }),
            ],
          ),
        );
      }),
    );
  }
}

class _AnalyticsTabBar extends StatelessWidget {
  const _AnalyticsTabBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      ('All', Icons.grid_view_rounded, null),
      ('Facebook', null, 'assets/images/facebook.png'),
      ('Instagram', null, 'assets/images/instagram.png'),
      ('LinkedIn', null, 'assets/images/link.png'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE6F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F2746),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 6) / 2;
          return Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: const _AnalyticsTabDividerPainter(),
                  ),
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(tabs.length, (index) {
                  final selected = selectedIndex == index;
                  final tab = tabs[index];
                  final assetPath = tab.$3;
                  return SizedBox(
                    width: itemWidth,
                    child: GestureDetector(
                      onTap: () => onSelected(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: selected
                              ? const LinearGradient(
                                  colors: [
                                    _socialBrandButtonStart,
                                    _socialBrandButtonEnd,
                                  ],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (assetPath != null)
                                Image.asset(assetPath, width: 17, height: 17)
                              else
                                Icon(
                                  tab.$2,
                                  size: 16,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF5F6F8D),
                                ),
                              const SizedBox(width: 7),
                              Text(
                                tab.$1,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF273656),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnalyticsTabDividerPainter extends CustomPainter {
  const _AnalyticsTabDividerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE7EDF6)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width / 2, 6),
      Offset(size.width / 2, size.height - 6),
      paint,
    );
    canvas.drawLine(
      Offset(8, size.height / 2),
      Offset(size.width - 8, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _AnalyticsTabDividerPainter oldDelegate) {
    return false;
  }
}

class _AnalyticsErrorState extends StatelessWidget {
  const _AnalyticsErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      child: Column(
        children: [
          const Icon(
            Icons.insights_outlined,
            color: Color(0xFF6C4EFF),
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF52627F),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic> _analyticsMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<Map<String, dynamic>> _analyticsList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

num _analyticsNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

String _analyticsFmt(
  dynamic value, {
  bool percent = false,
  bool signed = false,
}) {
  final number = _analyticsNum(value);
  if (percent) {
    return '${number.toStringAsFixed(2)}%';
  }
  if (signed && number >= 0) {
    return '+${number.toInt()}';
  }
  if (number % 1 == 0) {
    return number.toInt().toString();
  }
  return number.toStringAsFixed(1);
}

Map<String, dynamic> _analyticsPlatformInsight(
  AnalyticsDashboard dashboard,
  String platform,
) {
  final insights = _analyticsMap(dashboard.raw['platformInsights']);
  return _analyticsMap(insights[platform]);
}

Map<String, dynamic> _analyticsPlatformRow(
  AnalyticsDashboard dashboard,
  String platform,
) {
  return dashboard.platformBreakdown.firstWhere(
    (row) =>
        (row['platform'] ?? row['name'] ?? '').toString().toLowerCase() ==
        platform.toLowerCase(),
    orElse: () => const {},
  );
}

String _analyticsImage(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text;
}

String _analyticsContentImage(Map<String, dynamic> row) {
  final image = _analyticsImage(
    row['previewImageUrl'] ??
        row['thumbnailUrl'] ??
        row['thumbnail'] ??
        row['imageUrl'] ??
        row['image'] ??
        row['mediaUrl'] ??
        row['media_url'] ??
        row['picture'] ??
        row['url'],
  );
  if (image.isNotEmpty) return image;

  final media = _analyticsMap(row['media']);
  return _analyticsImage(
    media['previewImageUrl'] ??
        media['thumbnailUrl'] ??
        media['imageUrl'] ??
        media['url'],
  );
}

num _analyticsContentMetric(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    final value = _analyticsNum(row[key]);
    if (value != 0) return value;
  }

  final metrics = _analyticsMap(row['metrics']);
  for (final key in keys) {
    final value = _analyticsNum(metrics[key]);
    if (value != 0) return value;
  }

  final insights = _analyticsMap(row['insights']);
  for (final key in keys) {
    final value = _analyticsNum(insights[key]);
    if (value != 0) return value;
  }

  return 0;
}

String _analyticsContentDate(Map<String, dynamic> row) {
  final value =
      row['createdAt'] ??
      row['publishedAt'] ??
      row['date'] ??
      row['publishedDate'];
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return value?.toString() ?? '';
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
  return '${months[parsed.month - 1]} ${parsed.day}';
}

Widget _analyticsImageWidget(String image, {required BoxFit fit}) {
  if (image.startsWith('data:image')) {
    final base64Data = image.split(';base64,').last;
    return Image.memory(base64Decode(base64Data), fit: fit);
  }
  if (image.startsWith('http://') || image.startsWith('https://')) {
    return Image.network(image, fit: fit);
  }
  if (image.isNotEmpty) return Image.asset(image, fit: fit);
  return Container(
    color: const Color(0xFFF1F5F9),
    alignment: Alignment.center,
    child: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
  );
}

class _AnalyticsRangeButton extends StatelessWidget {
  const _AnalyticsRangeButton({required this.value, required this.onSelected});

  final String value;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: value,
      elevation: 16,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: onSelected,
      constraints: const BoxConstraints(minWidth: 138, maxWidth: 156),
      itemBuilder: (context) => _compactRangeMenuItems(),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDE6F2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D0F2746),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Color(0xFF61708E),
            ),
            const SizedBox(width: 10),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF172342),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF61708E),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsExportButton extends StatelessWidget {
  const _AnalyticsExportButton({required this.onTap, this.showText = true});

  final VoidCallback onTap;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: showText ? 14 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDE6F2)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.ios_share_rounded,
              color: Color(0xFF5741F2),
              size: 20,
            ),
            if (showText) ...[
              const SizedBox(width: 8),
              const Text(
                'Export',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF4E3BF1),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

List<PopupMenuEntry<String>> _compactRangeMenuItems() {
  const values = [
    'Last 7 days',
    'Last 28 days',
    'Last 60 days',
    'Last 90 days',
  ];
  return values
      .map(
        (value) => PopupMenuItem<String>(
          value: value,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF101A35),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      )
      .toList(growable: false);
}

class _AnalyticsAllSection extends StatelessWidget {
  const _AnalyticsAllSection({super.key, required this.dashboard});

  final AnalyticsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final summary = dashboard.summary;
    return Column(
      key: key,
      children: [
        _AnalyticsMetricGrid(
          metrics: [
            _AnalyticsMetric(
              'Total Followers',
              _analyticsFmt(summary['totalFollowers']),
              Icons.groups_2_outlined,
              const Color(0xFFEDE8FF),
            ),
            _AnalyticsMetric(
              'Reach',
              _analyticsFmt(summary['totalReach']),
              Icons.public_rounded,
              const Color(0xFFEAF3FF),
            ),
            _AnalyticsMetric(
              'Impressions',
              _analyticsFmt(summary['totalImpressions']),
              Icons.visibility_outlined,
              const Color(0xFFF4E8FF),
            ),
            _AnalyticsMetric(
              'Engagements',
              _analyticsFmt(summary['totalEngagement']),
              Icons.favorite_border_rounded,
              const Color(0xFFFFE8F2),
            ),
            _AnalyticsMetric(
              'Link Clicks',
              _analyticsFmt(summary['totalClicks']),
              Icons.ads_click_rounded,
              const Color(0xFFFFF4D9),
            ),
            _AnalyticsMetric(
              'Posts Published',
              _analyticsFmt(summary['totalPosts']),
              Icons.insert_chart_outlined_rounded,
              const Color(0xFFE1FAF1),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _AnalyticsPerformanceCard(dashboard: dashboard),
        const SizedBox(height: 14),
        _AnalyticsSplitCards(
          left: _TopPostsCard(posts: dashboard.topPosts),
          right: _EngagementDonutCard(breakdown: dashboard.engagementBreakdown),
        ),
        const SizedBox(height: 14),
        _PlatformComparisonCard(dashboard: dashboard),
        const SizedBox(height: 14),
        _RecentContentCard(posts: dashboard.topPosts),
      ],
    );
  }
}

class _AnalyticsFacebookSection extends StatelessWidget {
  const _AnalyticsFacebookSection({super.key, required this.dashboard});

  final AnalyticsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final insight = _analyticsPlatformInsight(dashboard, 'facebook');
    final row = _analyticsPlatformRow(dashboard, 'Facebook');
    return Column(
      key: key,
      children: [
        _AnalyticsMetricGrid(
          metrics: [
            _AnalyticsMetric(
              'Total Followers',
              _analyticsFmt(insight['followers'] ?? row['followers']),
              Icons.groups_2_outlined,
              const Color(0xFFEDE8FF),
            ),
            _AnalyticsMetric(
              'Reach',
              _analyticsFmt(insight['reach'] ?? row['reach']),
              Icons.public_rounded,
              const Color(0xFFEAF3FF),
            ),
            _AnalyticsMetric(
              'Impressions',
              _analyticsFmt(insight['impressions'] ?? row['impressions']),
              Icons.visibility_outlined,
              const Color(0xFFF4E8FF),
            ),
            _AnalyticsMetric(
              'Engagements',
              _analyticsFmt(insight['engagement'] ?? row['engagement']),
              Icons.favorite_border_rounded,
              const Color(0xFFFFE8F2),
            ),
            _AnalyticsMetric(
              'Engagement Rate',
              _analyticsFmt(
                insight['engagementRate'] ?? row['engagementRate'],
                percent: true,
              ),
              Icons.monitor_heart_outlined,
              const Color(0xFFE1FAF1),
            ),
            _AnalyticsMetric(
              'Posts Published',
              _analyticsFmt(
                insight['posts'] ?? row['posts'] ?? row['postsPublished'],
              ),
              Icons.insert_chart_outlined_rounded,
              const Color(0xFFE1FAF1),
            ),
            _AnalyticsMetric(
              'Link Clicks',
              _analyticsFmt(insight['clicks'] ?? row['clicks']),
              Icons.ads_click_rounded,
              const Color(0xFFFFF4D9),
            ),
            _AnalyticsMetric(
              'Follower Growth',
              _analyticsFmt(insight['followerGrowth'], signed: true),
              Icons.trending_up_rounded,
              const Color(0xFFF1E8FF),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _FacebookWorkspaceCard(dashboard: dashboard),
        const SizedBox(height: 14),
        _AnalyticsSplitCards(
          left: _ContentTypeCard(
            title: 'Views by content type',
            value: 'Photo',
            percent:
                '${_analyticsNum(_analyticsMap(dashboard.raw['viewsByContentType'])['photo']).toInt()}%',
          ),
          right: _FollowersDonutCard(dashboard: dashboard),
        ),
        const SizedBox(height: 14),
        _AnalyticsSplitCards(
          left: const _OrganicAdsCard(),
          right: _EngagementDonutCard(breakdown: dashboard.engagementBreakdown),
        ),
        const SizedBox(height: 14),
        _AnalyticsSplitCards(
          left: _TopPostsCard(posts: dashboard.topPosts),
          right: _RecentPostsMiniCard(posts: dashboard.topPosts),
        ),
        const SizedBox(height: 14),
        _ContentLibraryCard(posts: dashboard.topPosts),
      ],
    );
  }
}

class _AnalyticsInstagramSection extends StatelessWidget {
  const _AnalyticsInstagramSection({super.key, required this.dashboard});

  final AnalyticsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final insight = _analyticsPlatformInsight(dashboard, 'instagram');
    final row = _analyticsPlatformRow(dashboard, 'Instagram');
    final workspace = _analyticsMap(dashboard.raw['instagramWorkspace']);
    return Column(
      key: key,
      children: [
        _AnalyticsMetricGrid(
          metrics: [
            _AnalyticsMetric(
              'Followers',
              _analyticsFmt(insight['followers'] ?? row['followers']),
              Icons.person_outline_rounded,
              const Color(0xFFEDE8FF),
            ),
            _AnalyticsMetric(
              'Reach',
              _analyticsFmt(insight['reach'] ?? row['reach']),
              Icons.public_rounded,
              const Color(0xFFEAF3FF),
            ),
            _AnalyticsMetric(
              'Impressions',
              _analyticsFmt(insight['impressions'] ?? row['impressions']),
              Icons.visibility_outlined,
              const Color(0xFFF4E8FF),
            ),
            _AnalyticsMetric(
              'Engagement Rate',
              _analyticsFmt(
                insight['engagementRate'] ?? row['engagementRate'],
                percent: true,
              ),
              Icons.monitor_heart_outlined,
              const Color(0xFFE1FAF1),
            ),
            _AnalyticsMetric(
              'Link Clicks',
              _analyticsFmt(insight['clicks'] ?? row['clicks']),
              Icons.ads_click_rounded,
              const Color(0xFFFFF4D9),
            ),
            _AnalyticsMetric(
              'Posts Published',
              _analyticsFmt(
                workspace['providerPostCount'] ??
                    insight['posts'] ??
                    row['posts'] ??
                    row['postsPublished'],
              ),
              Icons.insert_chart_outlined_rounded,
              const Color(0xFFE1FAF1),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _AnalyticsSplitCards(
          left: _InstagramInsightsCard(workspace: workspace, insight: insight),
          right: _EngagementDonutCard(breakdown: dashboard.engagementBreakdown),
        ),
        const SizedBox(height: 14),
        _AnalyticsSplitCards(
          left: _ContentMixCard(dashboard: dashboard),
          right: _TopContentCard(workspace: workspace),
        ),
        const SizedBox(height: 14),
        _InstagramContentInsightsCard(workspace: workspace),
        const SizedBox(height: 14),
        const _AudienceDemographicsCard(),
      ],
    );
  }
}

class _AnalyticsLinkedInSection extends StatelessWidget {
  const _AnalyticsLinkedInSection({super.key, required this.dashboard});

  final AnalyticsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final insight = _analyticsPlatformInsight(dashboard, 'linkedin');
    final row = _analyticsPlatformRow(dashboard, 'LinkedIn');
    final availability = _analyticsMap(dashboard.raw['dataAvailability']);
    final isPending = availability['linkedin'] == 'pending_provider_access';
    return Column(
      key: key,
      children: [
        _AnalyticsMetricGrid(
          metrics: [
            _AnalyticsMetric(
              'Total Followers',
              isPending
                  ? '0'
                  : _analyticsFmt(insight['followers'] ?? row['followers']),
              Icons.groups_2_outlined,
              const Color(0xFFEDE8FF),
            ),
            _AnalyticsMetric(
              'Reach',
              isPending ? '0' : _analyticsFmt(insight['reach'] ?? row['reach']),
              Icons.public_rounded,
              const Color(0xFFEAF3FF),
            ),
            _AnalyticsMetric(
              'Impressions',
              isPending
                  ? '0'
                  : _analyticsFmt(insight['impressions'] ?? row['impressions']),
              Icons.visibility_outlined,
              const Color(0xFFF4E8FF),
            ),
            _AnalyticsMetric(
              'Engagements',
              isPending
                  ? '0'
                  : _analyticsFmt(insight['engagement'] ?? row['engagement']),
              Icons.favorite_border_rounded,
              const Color(0xFFFFE8F2),
            ),
            _AnalyticsMetric(
              'Engagement Rate',
              isPending
                  ? '0.00%'
                  : _analyticsFmt(
                      insight['engagementRate'] ?? row['engagementRate'],
                      percent: true,
                    ),
              Icons.monitor_heart_outlined,
              const Color(0xFFE1FAF1),
            ),
            _AnalyticsMetric(
              'Posts Published',
              isPending
                  ? '0'
                  : _analyticsFmt(row['posts'] ?? row['postsPublished']),
              Icons.insert_chart_outlined_rounded,
              const Color(0xFFE1FAF1),
            ),
            _AnalyticsMetric(
              'Link Clicks',
              isPending
                  ? '0'
                  : _analyticsFmt(insight['clicks'] ?? row['clicks']),
              Icons.ads_click_rounded,
              const Color(0xFFFFF4D9),
            ),
            _AnalyticsMetric(
              'Follower Growth',
              isPending
                  ? '+0'
                  : _analyticsFmt(insight['followerGrowth'], signed: true),
              Icons.trending_up_rounded,
              const Color(0xFFF1E8FF),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _LinkedInPendingCard(),
        const SizedBox(height: 14),
        const _LinkedInApprovalList(),
        const SizedBox(height: 14),
        const _AnalyticsSplitCards(
          left: _EmptyAnalyticsCard(
            title: 'Top Performing Posts',
            subtitle: 'No posts data yet',
            detail: 'Insights will appear here once reporting is approved.',
            icon: Icons.bolt_rounded,
          ),
          right: _EmptyAnalyticsCard(
            title: 'Audience Demographics',
            subtitle: 'No audience data yet',
            detail:
                'Audience demographics will appear here once reporting is approved.',
            icon: Icons.pie_chart_outline_rounded,
          ),
        ),
      ],
    );
  }
}

class _AnalyticsMetric {
  const _AnalyticsMetric(this.label, this.value, this.icon, this.tint);

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
}

class _AnalyticsMetricGrid extends StatelessWidget {
  const _AnalyticsMetricGrid({required this.metrics});

  final List<_AnalyticsMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 8,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: itemWidth,
                  child: _AnalyticsMetricCard(metric: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _AnalyticsMetricCard extends StatelessWidget {
  const _AnalyticsMetricCard({required this.metric});

  final _AnalyticsMetric metric;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: metric.tint,
              shape: BoxShape.circle,
            ),
            child: Icon(metric.icon, color: const Color(0xFF5741F2), size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF5C6C8A),
                    fontSize: 11.2,
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          metric.value,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF07122D),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 1),
                      child: Text(
                        'up 0.0%',
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF00A86B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E8F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x090F2746),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AnalyticsSectionTitle extends StatelessWidget {
  const _AnalyticsSectionTitle(this.title, {this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF101A35),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _AnalyticsPerformanceCard extends StatelessWidget {
  const _AnalyticsPerformanceCard({required this.dashboard});

  final AnalyticsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final summary = dashboard.summary;
    final series = dashboard.timeSeries;
    final reach = series
        .map((p) => _analyticsNum(p['reach']).toDouble())
        .toList();
    final engagement = series
        .map((p) => _analyticsNum(p['engagement']).toDouble())
        .toList();
    final impressions = series
        .map((p) => _analyticsNum(p['impressions']).toDouble())
        .toList();
    final clicks = series
        .map((p) => _analyticsNum(p['clicks']).toDouble())
        .toList();
    final maxY = [
      ...reach,
      ...engagement,
      ...impressions,
      ...clicks,
      1.0,
    ].reduce(math.max);
    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _AnalyticsSectionTitle('Performance Over Time')),
              SizedBox(width: 10),
              _PerformanceRangeDropdown(),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PerformanceMetricChip(
                color: const Color(0xFF2F7DFF),
                label: 'Reach',
                value: _analyticsFmt(summary['totalReach']),
              ),
              _PerformanceMetricChip(
                color: const Color(0xFF10B981),
                label: 'Engagement',
                value: _analyticsFmt(summary['totalEngagement']),
              ),
              _PerformanceMetricChip(
                color: const Color(0xFF8A45F8),
                label: 'Impressions',
                value: _analyticsFmt(summary['totalImpressions']),
              ),
              _PerformanceMetricChip(
                color: const Color(0xFFFF9F1A),
                label: 'Clicks',
                value: _analyticsFmt(summary['totalClicks']),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: CustomPaint(
              painter: _AnalyticsLinePainter(
                series: [
                  (
                    color: const Color(0xFF2F7DFF),
                    values: reach.isEmpty ? [0, 0] : reach,
                  ),
                  (
                    color: const Color(0xFF10B981),
                    values: engagement.isEmpty ? [0, 0] : engagement,
                  ),
                  (
                    color: const Color(0xFF8A45F8),
                    values: impressions.isEmpty ? [0, 0] : impressions,
                  ),
                  (
                    color: const Color(0xFFFF9F1A),
                    values: clicks.isEmpty ? [0, 0] : clicks,
                  ),
                ],
                maxY: maxY <= 0 ? 1 : maxY,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AxisLabel('Jul 6'),
              _AxisLabel('Jul 13'),
              _AxisLabel('Jul 20'),
              _AxisLabel('Jul 27'),
              _AxisLabel('Aug 3'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformanceRangeDropdown extends StatefulWidget {
  const _PerformanceRangeDropdown();

  @override
  State<_PerformanceRangeDropdown> createState() =>
      _PerformanceRangeDropdownState();
}

class _PerformanceRangeDropdownState extends State<_PerformanceRangeDropdown> {
  String _value = 'Last 60 days';

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: _value,
      elevation: 16,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) => setState(() => _value = value),
      constraints: const BoxConstraints(minWidth: 138, maxWidth: 156),
      itemBuilder: (context) => _compactRangeMenuItems(),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFDCE5F2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D0F2746),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: Color(0xFF7C8AA5),
            ),
            const SizedBox(width: 7),
            Text(
              _value,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF172342),
                fontSize: 12.2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Color(0xFF7C8AA5),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceMetricChip extends StatelessWidget {
  const _PerformanceMetricChip({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 102,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3EAF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF5C6C8A),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF07122D),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        color: Color(0xFF70809D),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _AnalyticsSplitCards extends StatelessWidget {
  const _AnalyticsSplitCards({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(children: [left, const SizedBox(height: 14), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 14),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _TopPostsCard extends StatelessWidget {
  const _TopPostsCard({required this.posts});

  final List<Map<String, dynamic>> posts;

  @override
  Widget build(BuildContext context) {
    final rows = posts.take(3).toList(growable: false);
    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AnalyticsSectionTitle(
            'Top Performing Posts',
            trailing: Text(
              'See all',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF4F3CF0),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const _AnalyticsEmptyLine('No top posts yet for this range.')
          else
            ...rows.asMap().entries.map((entry) {
              final post = entry.value;
              final image = _analyticsContentImage(post);
              final title =
                  (post['title'] ?? post['caption'] ?? post['content'] ?? '')
                      .toString();
              final reach = _analyticsFmt(post['reach']);
              final engagementRate = _analyticsFmt(
                post['engagementRate'],
                percent: true,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '#${entry.key + 1}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF637392),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: _analyticsImageWidget(image, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.isEmpty ? 'Untitled post' : title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF101A35),
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              _AnalyticsPlatformTinyIcon(
                                platform: post['platform']?.toString() ?? '',
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$reach reach',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFF61708E),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '$engagementRate eng.',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF00A86B),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AnalyticsEmptyLine extends StatelessWidget {
  const _AnalyticsEmptyLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF7A89A4),
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AnalyticsPlatformTinyIcon extends StatelessWidget {
  const _AnalyticsPlatformTinyIcon({required this.platform});

  final String platform;

  @override
  Widget build(BuildContext context) {
    final lower = platform.toLowerCase();
    final asset = lower.contains('instagram')
        ? 'assets/images/instagram.png'
        : lower.contains('linkedin')
        ? 'assets/images/link.png'
        : 'assets/images/facebook.png';
    return Image.asset(asset, width: 14, height: 14);
  }
}

class _EngagementDonutCard extends StatefulWidget {
  const _EngagementDonutCard({required this.breakdown});

  final Map<String, dynamic> breakdown;

  @override
  State<_EngagementDonutCard> createState() => _EngagementDonutCardState();
}

class _EngagementDonutCardState extends State<_EngagementDonutCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final likes = _analyticsNum(widget.breakdown['likes']);
    final comments = _analyticsNum(widget.breakdown['comments']);
    final shares = _analyticsNum(widget.breakdown['shares']);
    final saves = _analyticsNum(widget.breakdown['saves']);
    final total = math.max(likes + comments + shares + saves, 1);
    String line(num value) =>
        '${value.toInt()} (${((value / total) * 100).round()}%)';
    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AnalyticsSectionTitle('Engagement Breakdown'),
          const SizedBox(height: 16),
          Row(
            children: [
              AnimatedBuilder(
                animation: _progress,
                builder: (context, child) {
                  return SizedBox(
                    width: 122,
                    height: 122,
                    child: CustomPaint(
                      painter: _DonutPainter(
                        progress: _progress.value,
                        segments: [
                          (const Color(0xFF6457F5), likes / total),
                          (const Color(0xFFE83E8C), comments / total),
                          (const Color(0xFFFFA51A), shares / total),
                          (const Color(0xFF11B886), saves / total),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              SizedBox(
                width: 118,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BreakdownLine(
                      color: const Color(0xFF6457F5),
                      label: 'Likes',
                      value: line(likes),
                    ),
                    _BreakdownLine(
                      color: const Color(0xFFE83E8C),
                      label: 'Comments',
                      value: line(comments),
                    ),
                    _BreakdownLine(
                      color: const Color(0xFFFFA51A),
                      label: 'Shares',
                      value: line(shares),
                    ),
                    _BreakdownLine(
                      color: const Color(0xFF11B886),
                      label: 'Saves',
                      value: line(saves),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownLine extends StatelessWidget {
  const _BreakdownLine({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label\n$value',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF2D3953),
                fontSize: 12.8,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformComparisonCard extends StatelessWidget {
  const _PlatformComparisonCard({required this.dashboard});

  final AnalyticsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final availability = _analyticsMap(dashboard.raw['dataAvailability']);
    _PlatformComparisonPanel panel(
      String platform,
      String logo,
      Color accent,
      Color tint,
    ) {
      final lower = platform.toLowerCase();
      final row = _analyticsPlatformRow(dashboard, platform);
      final pending =
          lower == 'linkedin' &&
          availability['linkedin'] == 'pending_provider_access';
      final metrics = pending
          ? const [
              _PlatformMetric('Followers', 'Pending', 'awaiting approval'),
              _PlatformMetric('Reach', 'Pending', 'awaiting approval'),
              _PlatformMetric('Impressions', 'Pending', 'awaiting approval'),
              _PlatformMetric('Engagement', 'Pending', 'awaiting approval'),
              _PlatformMetric('Eng. Rate', 'Pending', 'awaiting approval'),
              _PlatformMetric('Link Clicks', 'Pending', 'awaiting approval'),
            ]
          : [
              _PlatformMetric(
                'Followers',
                _analyticsFmt(row['followers']),
                '+0 this period',
              ),
              _PlatformMetric(
                'Reach',
                _analyticsFmt(row['reach']),
                'unique accounts',
              ),
              _PlatformMetric(
                'Impressions',
                _analyticsFmt(row['impressions']),
                'total views',
              ),
              _PlatformMetric(
                'Engagement',
                _analyticsFmt(row['engagement']),
                'interactions',
              ),
              _PlatformMetric(
                'Eng. Rate',
                _analyticsFmt(row['engagementRate'], percent: true),
                'of reach',
              ),
              _PlatformMetric(
                'Link Clicks',
                _analyticsFmt(row['clicks']),
                'CTA clicks',
              ),
            ];
      return _PlatformComparisonPanel(
        platform: platform,
        logo: logo,
        accent: accent,
        status: pending ? 'PENDING' : 'LIVE DATA',
        statusColor: pending
            ? const Color(0xFFFF9F1A)
            : const Color(0xFF10B981),
        helper: pending ? 'Pending provider approval' : null,
        metricTint: tint,
        metrics: metrics,
      );
    }

    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AnalyticsSectionTitle('Platform Comparison'),
          const SizedBox(height: 14),
          panel(
            'Facebook',
            'assets/images/facebook.png',
            const Color(0xFF1877F2),
            const Color(0xFFEAF3FF),
          ),
          const SizedBox(height: 12),
          panel(
            'Instagram',
            'assets/images/instagram.png',
            const Color(0xFFE83E8C),
            const Color(0xFFFFEEF7),
          ),
          const SizedBox(height: 12),
          panel(
            'LinkedIn',
            'assets/images/link.png',
            const Color(0xFF0A66C2),
            const Color(0xFFFFF7E8),
          ),
        ],
      ),
    );
  }
}

class _PlatformMetric {
  const _PlatformMetric(this.label, this.value, this.helper);

  final String label;
  final String value;
  final String helper;
}

class _PlatformComparisonPanel extends StatelessWidget {
  const _PlatformComparisonPanel({
    required this.platform,
    required this.logo,
    required this.accent,
    required this.status,
    required this.statusColor,
    required this.metricTint,
    required this.metrics,
    this.helper,
  });

  final String platform;
  final String logo;
  final Color accent;
  final String status;
  final Color statusColor;
  final Color metricTint;
  final List<_PlatformMetric> metrics;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5ECF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F2746),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border(top: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(logo, width: 34, height: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      platform,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF101A35),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          status,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: statusColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (helper != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              helper!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF8A98B3),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status == 'PENDING' ? '...' : '0.0%',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: metrics
                    .map(
                      (metric) => SizedBox(
                        width: width,
                        child: _PlatformMetricTile(
                          metric: metric,
                          accent: accent,
                          tint: metricTint,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PlatformMetricTile extends StatelessWidget {
  const _PlatformMetricTile({
    required this.metric,
    required this.accent,
    required this.tint,
  });

  final _PlatformMetric metric;
  final Color accent;
  final Color tint;

  IconData get _icon {
    final label = metric.label.toLowerCase();
    if (label.contains('impression') || label.contains('view')) {
      return Icons.visibility_outlined;
    }
    if (label.contains('click')) return Icons.link_rounded;
    if (label.contains('rate')) return Icons.trending_up_rounded;
    if (label.contains('video') || label.contains('reel')) {
      return Icons.play_arrow_rounded;
    }
    if (label.contains('save')) return Icons.bookmark_border_rounded;
    return Icons.groups_2_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEF6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: accent, size: 19),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF637392),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF07122D),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  metric.helper,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF8A98B3),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
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

class _RecentContentCard extends StatelessWidget {
  const _RecentContentCard({required this.posts});

  final List<Map<String, dynamic>> posts;

  @override
  Widget build(BuildContext context) {
    final rows = posts.take(8).toList(growable: false);
    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AnalyticsSectionTitle(
            'Recent Content',
            trailing: Text(
              'See all',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF4F3CF0),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) => _RecentContentTile(
                image: _analyticsContentImage(rows[index]),
                views: _analyticsContentMetric(rows[index], [
                  'views',
                  'reach',
                  'impressions',
                ]).toInt(),
                likes: _analyticsContentMetric(rows[index], [
                  'likes',
                  'reactions',
                ]).toInt(),
                comments: _analyticsContentMetric(rows[index], [
                  'comments',
                ]).toInt(),
              ),
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemCount: rows.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentContentTile extends StatelessWidget {
  const _RecentContentTile({
    required this.image,
    required this.views,
    required this.likes,
    required this.comments,
  });

  final String image;
  final int views;
  final int likes;
  final int comments;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 154,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E8F2)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: SizedBox(
              height: 104,
              width: double.infinity,
              child: _analyticsImageWidget(image, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniIconMetric(
                  icon: Icons.visibility_outlined,
                  value: '$views',
                ),
                _MiniIconMetric(
                  icon: Icons.favorite_border_rounded,
                  value: '$likes',
                ),
                _MiniIconMetric(
                  icon: Icons.chat_bubble_outline_rounded,
                  value: '$comments',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniIconMetric extends StatelessWidget {
  const _MiniIconMetric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF5741F2)),
        const SizedBox(width: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF1C2949),
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _FacebookWorkspaceCard extends StatefulWidget {
  const _FacebookWorkspaceCard({required this.dashboard});

  final AnalyticsDashboard dashboard;

  @override
  State<_FacebookWorkspaceCard> createState() => _FacebookWorkspaceCardState();
}

class _FacebookWorkspaceCardState extends State<_FacebookWorkspaceCard> {
  int _selectedIndex = 0;

  static const _tabs = ['All Posts', 'Posts', 'Reels', 'Stories'];

  _FacebookWorkspaceData get _data {
    final workspace = _analyticsMap(widget.dashboard.raw['facebookWorkspace']);
    final tabData = _analyticsMap(workspace['tabData']);
    final tabKey = _tabs[_selectedIndex].toLowerCase().replaceAll(' ', '_');
    final selected = _analyticsMap(tabData[tabKey]);
    final source = selected.isEmpty ? workspace : selected;
    final cards = _analyticsList(source['summaryCards']);
    String cardValue(String key) {
      final card = cards.firstWhere(
        (item) => item['key'] == key || item['label'] == key,
        orElse: () => const {},
      );
      return _analyticsFmt(card['value']);
    }

    final timeSeries = _analyticsList(source['timeSeries']);
    return _FacebookWorkspaceData(
      views: cardValue('views'),
      uniqueViewers: cardValue('uniqueViewers'),
      postClicks: cardValue('postClicks'),
      interactions: cardValue('interactions'),
      viewsSub:
          'up ${_analyticsFmt(cards.isEmpty ? 0 : cards.first['deltaPct'], percent: true)}',
      viewersSub: 'up 0.0%',
      clicksSub: 'up 0.0%',
      interactionsSub: 'up 0.0%',
      blue: timeSeries
          .map((item) => _analyticsNum(item['views']).toDouble())
          .toList(),
      teal: timeSeries
          .map((item) => _analyticsNum(item['pageViews']).toDouble())
          .toList(),
      purple: timeSeries
          .map((item) => _analyticsNum(item['interactions']).toDouble())
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/facebook.png', width: 26, height: 26),
              const SizedBox(width: 8),
              const Expanded(
                child: _AnalyticsSectionTitle('Facebook Views Workspace'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Facebook workspace uses supported provider media-view signals: views, unique viewers, clicks, reactions, comments, and shares.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF61708E),
              fontSize: 11.8,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _FacebookWorkspaceTabs(
            tabs: _tabs,
            selectedIndex: _selectedIndex,
            onSelected: (index) => setState(() => _selectedIndex = index),
          ),
          const SizedBox(height: 10),
          const _FacebookViewsNote(),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: width,
                    child: _MiniMetricBox(
                      title: 'Views',
                      value: data.views,
                      sub: data.viewsSub,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _MiniMetricBox(
                      title: 'Unique Viewers',
                      value: data.uniqueViewers,
                      sub: data.viewersSub,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _MiniMetricBox(
                      title: 'Post Clicks',
                      value: data.postClicks,
                      sub: data.clicksSub,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _MiniMetricBox(
                      title: 'Interactions',
                      value: data.interactions,
                      sub: data.interactionsSub,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 162,
            child: CustomPaint(
              painter: _AnalyticsLinePainter(
                series: [
                  (color: Color(0xFF2F7DFF), values: data.blue),
                  (color: Color(0xFF0F9F95), values: data.teal),
                  (color: Color(0xFF8A45F8), values: data.purple),
                ],
                maxY: 60,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AxisLabel('Jun 5'),
              _AxisLabel('Jun 17'),
              _AxisLabel('Jun 29'),
              _AxisLabel('Jul 11'),
              _AxisLabel('Jul 23'),
              _AxisLabel('Aug 4'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FacebookWorkspaceData {
  const _FacebookWorkspaceData({
    required this.views,
    required this.uniqueViewers,
    required this.postClicks,
    required this.interactions,
    required this.viewsSub,
    required this.viewersSub,
    required this.clicksSub,
    required this.interactionsSub,
    required this.blue,
    required this.teal,
    required this.purple,
  });

  final String views;
  final String uniqueViewers;
  final String postClicks;
  final String interactions;
  final String viewsSub;
  final String viewersSub;
  final String clicksSub;
  final String interactionsSub;
  final List<double> blue;
  final List<double> teal;
  final List<double> purple;
}

class _FacebookWorkspaceTabs extends StatelessWidget {
  const _FacebookWorkspaceTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE6F2)),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFF286DFF), Color(0xFF7438F2)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  tabs[index],
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: selected ? Colors.white : const Color(0xFF40516F),
                    fontSize: 10.2,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _FacebookViewsNote extends StatelessWidget {
  const _FacebookViewsNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC66)),
      ),
      child: const Text(
        'Why "All Posts" views are higher: Facebook counts views from all content that appeared in feeds, while Posts only counts published media posts.',
        style: TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFFE27600),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    );
  }
}

class _MiniMetricBox extends StatelessWidget {
  const _MiniMetricBox({
    required this.title,
    required this.value,
    required this.sub,
  });

  final String title;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E8F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF61708E),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF07122D),
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              fontFamily: 'Inter',
              color: sub.startsWith('down')
                  ? const Color(0xFFE83E5A)
                  : const Color(0xFF00A86B),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentTypeCard extends StatelessWidget {
  const _ContentTypeCard({
    required this.title,
    required this.value,
    required this.percent,
    this.icon = Icons.photo_library_outlined,
    this.accent = const Color(0xFF2F7DFF),
    this.accentEnd = const Color(0xFF22C7BC),
    this.tint = const Color(0xFFEAF3FF),
  });

  final String title;
  final String value;
  final String percent;
  final IconData icon;
  final Color accent;
  final Color accentEnd;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E8F2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: 0.8), Colors.white],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x090F2746),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: accent, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(child: _AnalyticsSectionTitle(title)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.18)),
                ),
                child: Text(
                  percent,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF101A35),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const Text(
                'dominant source',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF7A89A4),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _GradientProgressBar(colors: [accent, accentEnd]),
        ],
      ),
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 9,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(colors: colors),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudienceSourcePill extends StatelessWidget {
  const _AudienceSourcePill({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE6EDF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF5C6C8A),
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF101A35),
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowersDonutCard extends StatelessWidget {
  const _FollowersDonutCard({required this.dashboard});

  final AnalyticsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final split = _analyticsMap(dashboard.raw['viewsByFollowers']);
    final followers = _analyticsNum(split['followers']);
    final nonFollowers = _analyticsNum(split['nonFollowers']);
    final total = math.max(followers + nonFollowers, 1);
    final followerPct = ((followers / total) * 100).round();
    final nonFollowerPct = ((nonFollowers / total) * 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E8F2)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF3FF), Colors.white],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x090F2746),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AnalyticsSectionTitle('Followers vs Non-followers'),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: CustomPaint(
                  painter: _DonutPainter(
                    segments: [
                      (const Color(0xFF2F7DFF), nonFollowers / total),
                      (const Color(0xFFB8C3D6), followers / total),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _AudienceSourcePill(
                      color: const Color(0xFF2F7DFF),
                      label: 'Non-followers',
                      value: '$nonFollowerPct%',
                    ),
                    const SizedBox(height: 8),
                    _AudienceSourcePill(
                      color: const Color(0xFFB8C3D6),
                      label: 'Followers',
                      value: '$followerPct%',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Text(
              'Discovery is coming from new audiences.',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF52627F),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganicAdsCard extends StatelessWidget {
  const _OrganicAdsCard();

  @override
  Widget build(BuildContext context) {
    return const _ContentTypeCard(
      title: 'Organic vs Ads',
      value: 'Organic',
      percent: '100%',
      icon: Icons.eco_outlined,
      accent: Color(0xFF10B981),
      accentEnd: Color(0xFF22C7BC),
      tint: Color(0xFFE9FBF4),
    );
  }
}

class _RecentPostsMiniCard extends StatelessWidget {
  const _RecentPostsMiniCard({required this.posts});

  final List<Map<String, dynamic>> posts;

  @override
  Widget build(BuildContext context) {
    return _RecentContentCard(posts: posts);
  }
}

class _ContentLibraryCard extends StatelessWidget {
  const _ContentLibraryCard({required this.posts});

  final List<Map<String, dynamic>> posts;

  @override
  Widget build(BuildContext context) {
    final rows = posts.take(5).toList(growable: false);
    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AnalyticsSectionTitle(
            'Content Library',
            trailing: Text(
              'See all',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF4F3CF0),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            const _AnalyticsEmptyLine('No content library rows yet.')
          else
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: _analyticsImageWidget(
                          _analyticsContentImage(row),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        (row['title'] ??
                                row['caption'] ??
                                row['content'] ??
                                'Untitled post')
                            .toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF14213F),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_analyticsFmt(row['reach'])}\nViews',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF14213F),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_analyticsFmt(row['engagement'])}\nInt.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF14213F),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF6E7D98),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InstagramInsightsCard extends StatelessWidget {
  const _InstagramInsightsCard({
    required this.workspace,
    required this.insight,
  });

  final Map<String, dynamic> workspace;
  final Map<String, dynamic> insight;

  @override
  Widget build(BuildContext context) {
    final account = _analyticsMap(workspace['accountSummary']);
    final items = [
      (
        Icons.visibility_outlined,
        'Views',
        _analyticsFmt(account['views'] ?? insight['impressions']),
      ),
      (
        Icons.groups_2_outlined,
        'Accounts Reached',
        _analyticsFmt(account['accountsReached'] ?? insight['reach']),
      ),
      (
        Icons.favorite_border_rounded,
        'Interactions',
        _analyticsFmt(account['interactions'] ?? insight['engagement']),
      ),
      (
        Icons.person_outline_rounded,
        'Profile Visits',
        _analyticsFmt(account['profileVisits']),
      ),
      (
        Icons.trending_up_rounded,
        'Accounts Engaged',
        _analyticsFmt(account['accountsEngaged']),
      ),
      (
        Icons.group_add_outlined,
        'Followers',
        _analyticsFmt(account['followers'] ?? insight['followers']),
      ),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E8F2)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFEEF7), Colors.white, Color(0xFFF4F0FF)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x090F2746),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1AE83E8C),
                      blurRadius: 14,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/instagram.png',
                  width: 22,
                  height: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(child: _AnalyticsSectionTitle('Account Insights')),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFFD7EA)),
                ),
                child: const Text(
                  'Live',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFFE83E8C),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: width,
                        child: _InstagramInsightTile(
                          icon: item.$1,
                          label: item.$2,
                          value: item.$3,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InstagramInsightTile extends StatelessWidget {
  const _InstagramInsightTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE9DFF8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F2746),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF7),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: const Color(0xFFE83E8C), size: 18),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF52627F),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF101A35),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    height: 1,
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

class _ContentMixCard extends StatelessWidget {
  const _ContentMixCard({required this.dashboard});

  final AnalyticsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final mix = _analyticsList(dashboard.raw['contentMix']);
    final first = mix.isEmpty ? const {} : mix.first;
    final split = _analyticsMap(dashboard.raw['viewsByFollowers']);
    final followers = _analyticsNum(split['followers']);
    final nonFollowers = _analyticsNum(split['nonFollowers']);
    final total = math.max(followers + nonFollowers, 1);
    final followerPct = ((followers / total) * 100).round();
    final nonFollowerPct = ((nonFollowers / total) * 100).round();
    final contentPct = _analyticsNum(first['pct']).round();

    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AnalyticsSectionTitle('Content Mix'),
          const SizedBox(height: 16),
          _ContentTypeCard(
            title: (first['type'] ?? 'Photo').toString(),
            value: 'Views: $nonFollowerPct% Non-followers',
            percent: '${contentPct == 0 ? 100 : contentPct}%',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _DonutPainter(
                    segments: [
                      (const Color(0xFF6457F5), nonFollowers / total),
                      (const Color(0xFFB8C3D6), followers / total),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$nonFollowerPct% Non-followers\n$followerPct% Followers',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF273656),
                    fontWeight: FontWeight.w800,
                    height: 1.7,
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

class _TopContentCard extends StatelessWidget {
  const _TopContentCard({required this.workspace});

  final Map<String, dynamic> workspace;

  @override
  Widget build(BuildContext context) {
    final rows =
        (_analyticsList(workspace['topContentByViews']).isNotEmpty
                ? _analyticsList(workspace['topContentByViews'])
                : _analyticsList(workspace['contentGrid']))
            .take(6)
            .toList(growable: false);
    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AnalyticsSectionTitle(
            'Top Content',
            trailing: Text(
              'View all',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF4F3CF0),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const _AnalyticsEmptyLine('No Instagram top content yet.')
          else
            SizedBox(
              height: 124,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return SizedBox(
                    width: 104,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 104,
                                height: 88,
                                child: _analyticsImageWidget(
                                  _analyticsContentImage(row),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Image.asset(
                                'assets/images/instagram.png',
                                width: 18,
                                height: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_analyticsFmt(row['views'])} views',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF273656),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemCount: rows.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _InstagramContentInsightsCard extends StatefulWidget {
  const _InstagramContentInsightsCard({required this.workspace});

  final Map<String, dynamic> workspace;

  @override
  State<_InstagramContentInsightsCard> createState() =>
      _InstagramContentInsightsCardState();
}

class _InstagramContentInsightsCardState
    extends State<_InstagramContentInsightsCard> {
  String _type = 'Posts';
  String _sort = 'Newest';

  List<_InstagramContentItem> get _items {
    final contentGrid = _analyticsList(widget.workspace['contentGrid']);
    final rows = contentGrid.isNotEmpty
        ? contentGrid
        : _analyticsList(widget.workspace['topContentByViews']);
    return rows
        .map(
          (row) => _InstagramContentItem(
            _analyticsContentImage(row),
            _instagramTypeLabel(row['mediaType'] ?? row['type']),
            _analyticsContentMetric(row, [
              'views',
              'reach',
              'impressions',
            ]).toInt(),
            _analyticsContentMetric(row, [
              'interactions',
              'engagement',
              'engagements',
              'comments',
              'likes',
            ]).toInt(),
            _analyticsContentDate(row),
            DateTime.tryParse((row['createdAt'] ?? '').toString()) ??
                DateTime.tryParse((row['publishedAt'] ?? '').toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0),
          ),
        )
        .toList(growable: false);
  }

  List<_InstagramContentItem> get _filteredItems {
    final filtered = _items.where((item) => item.type == _type).toList();
    switch (_sort) {
      case 'Highest':
        filtered.sort((a, b) {
          final byInteractions = b.interactions.compareTo(a.interactions);
          return byInteractions == 0
              ? b.views.compareTo(a.views)
              : byInteractions;
        });
      case 'Lowest':
        filtered.sort((a, b) {
          final byInteractions = a.interactions.compareTo(b.interactions);
          return byInteractions == 0
              ? a.views.compareTo(b.views)
              : byInteractions;
        });
      default:
        filtered.sort((a, b) => b.sortDate.compareTo(a.sortDate));
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final typeValues = _items.map((item) => item.type).toSet().toList();
    if (typeValues.isNotEmpty && !typeValues.contains(_type)) {
      _type = typeValues.first;
    }
    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _AnalyticsSectionTitle('Content Insights')),
              const SizedBox(width: 8),
              _InstagramFilterButton(
                value: _type,
                values: typeValues.isEmpty
                    ? const ['Posts', 'Reels', 'Stories']
                    : typeValues,
                onSelected: (value) => setState(() => _type = value),
              ),
              const SizedBox(width: 8),
              _InstagramFilterButton(
                value: _sort,
                values: const ['Newest', 'Highest', 'Lowest'],
                onSelected: (value) => setState(() => _sort = value),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 12,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: width,
                        child: _InstagramContentInsightTile(item: item),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          if (items.isEmpty)
            const _AnalyticsEmptyLine(
              'No Instagram content matched this filter.',
            ),
        ],
      ),
    );
  }
}

String _instagramTypeLabel(dynamic value) {
  final text = value?.toString().toLowerCase() ?? '';
  if (text.contains('reel')) return 'Reels';
  if (text.contains('stor')) return 'Stories';
  return 'Posts';
}

class _InstagramContentItem {
  const _InstagramContentItem(
    this.asset,
    this.type,
    this.views,
    this.interactions,
    this.date,
    this.sortDate,
  );

  final String asset;
  final String type;
  final int views;
  final int interactions;
  final String date;
  final DateTime sortDate;
}

class _InstagramFilterButton extends StatelessWidget {
  const _InstagramFilterButton({
    required this.value,
    required this.values,
    required this.onSelected,
  });

  final String value;
  final List<String> values;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: value,
      elevation: 14,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      constraints: const BoxConstraints(minWidth: 104, maxWidth: 124),
      onSelected: onSelected,
      itemBuilder: (context) => values
          .map(
            (item) => PopupMenuItem<String>(
              value: item,
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                item,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF101A35),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(growable: false),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFD8D7FF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x080F2746),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF172342),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 17,
              color: Color(0xFF172342),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstagramContentInsightTile extends StatelessWidget {
  const _InstagramContentInsightTile({required this.item});

  final _InstagramContentItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E8F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  height: 132,
                  width: double.infinity,
                  child: _analyticsImageWidget(item.asset, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Image.asset(
                  'assets/images/instagram.png',
                  width: 20,
                  height: 20,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.type.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF637392),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _InstagramContentMetric(
                        value: '${item.views}',
                        label: 'Views',
                      ),
                    ),
                    Expanded(
                      child: _InstagramContentMetric(
                        value: '${item.interactions}',
                        label: 'Interactions',
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.date,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF9AA8BF),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
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

class _InstagramContentMetric extends StatelessWidget {
  const _InstagramContentMetric({
    required this.value,
    required this.label,
    this.alignEnd = false,
  });

  final String value;
  final String label;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF07122D),
            fontSize: 15,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF7A89A4),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AudienceDemographicsCard extends StatelessWidget {
  const _AudienceDemographicsCard();

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      child: Row(
        children: const [
          CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFEDE8FF),
            child: Icon(Icons.groups_2_outlined, color: Color(0xFF5741F2)),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Audience Demographics\nAudience demographics are not available yet for this account.',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF273656),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.45,
              ),
            ),
          ),
          Icon(Icons.shield_outlined, color: Color(0xFF8B5CF6)),
        ],
      ),
    );
  }
}

class _LinkedInPendingCard extends StatelessWidget {
  const _LinkedInPendingCard();

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LINKEDIN ANALYTICS',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF1A73E8),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Professional reporting is staged and ready for provider approval.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF101A35),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'The LinkedIn workspace will light up once Community Management reporting access is approved. At that point we can show page statistics, follower growth, post performance, reactions, and audience reporting.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF61708E),
              fontSize: 13.2,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _PendingBox('FOLLOWERS'),
              _PendingBox('IMPRESSIONS'),
              _PendingBox('ENGAGEMENT'),
              _PendingBox('CLICKS'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingBox extends StatelessWidget {
  const _PendingBox(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE1E8F2)),
      ),
      child: Text(
        '$label\nPending',
        style: const TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF172342),
          fontSize: 15,
          fontWeight: FontWeight.w900,
          height: 1.55,
        ),
      ),
    );
  }
}

class _LinkedInApprovalList extends StatelessWidget {
  const _LinkedInApprovalList();

  @override
  Widget build(BuildContext context) {
    const rows = [
      (Icons.trending_up_rounded, 'Post performance'),
      (Icons.groups_2_outlined, 'Audience reporting'),
      (Icons.trending_up_rounded, 'Follower growth'),
      (Icons.description_outlined, 'Content analytics'),
    ];
    return _AnalyticsCard(
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Icon(row.$1, color: const Color(0xFF5741F2), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        row.$2,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF172342),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Text(
                      'Pending provider approval',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF5741F2),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _EmptyAnalyticsCard extends StatelessWidget {
  const _EmptyAnalyticsCard({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      child: Column(
        children: [
          _AnalyticsSectionTitle(title),
          const SizedBox(height: 22),
          Icon(icon, color: const Color(0xFF9AABC5), size: 52),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF52627F),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF70809D),
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsLinePainter extends CustomPainter {
  const _AnalyticsLinePainter({required this.series, this.maxY});

  final List<({Color color, List<double> values})>? series;
  final double? maxY;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFDDE6F2)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (final item in series ?? const []) {
      _drawLine(canvas, size, item.values, item.color);
    }
  }

  void _drawLine(Canvas canvas, Size size, List<double> values, Color color) {
    final maxValue =
        maxY ?? math.max(1, values.isEmpty ? 1 : values.reduce(math.max));
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] / maxValue * (size.height - 8)) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _AnalyticsLinePainter oldDelegate) {
    return oldDelegate.series != series || oldDelegate.maxY != maxY;
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.segments, this.progress = 1});

  final List<(Color, double)> segments;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide * 0.18;
    final rect =
        Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);
    final bgPaint = Paint()
      ..color = const Color(0xFFE9EEF7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, bgPaint);
    var start = -math.pi / 2;
    for (final segment in segments) {
      final sweep = math.pi * 2 * segment.$2 * progress.clamp(0, 1);
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = segment.$1
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.segments != segments || oldDelegate.progress != progress;
  }
}

class SocialProfileView extends StatefulWidget {
  const SocialProfileView({super.key});

  @override
  State<SocialProfileView> createState() => _SocialProfileViewState();
}

class _SocialProfileViewState extends State<SocialProfileView> {
  late final SocialAccountsController _accountsController =
      Get.isRegistered<SocialAccountsController>()
      ? Get.find<SocialAccountsController>()
      : Get.put(SocialAccountsController());
  late final AccountSettingsController _accountController =
      Get.isRegistered<AccountSettingsController>()
      ? Get.find<AccountSettingsController>()
      : Get.put(AccountSettingsController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _accountsController.loadAccounts();
      if (_accountController.settings.value == null &&
          !_accountController.isLoading.value) {
        _accountController.loadInitialData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthNavigationShell(
      currentTab: AuthTab.socialProfile,
      backgroundColor: const Color(0xFFF5F8FC),
      child: Obx(() {
        final businessName = _accountController.businessNameValue;
        final owner = _accountController.ownerNameValue;
        final email = _accountController.email;
        final connectedPlatforms = _accountsController.connectedPlatforms;
        final healthyCount = _accountsController.healthyCount;
        final disconnectedCount = _accountsController.disconnectedCount;
        final aiLimit = _accountController.postLimit;
        final aiUsed = _accountController.postsUsedThisMonth;
        final aiRemaining = _accountController.remainingPosts;
        final creativesLimit = _accountController.creativeLimit;
        final creativesUsed = _accountController.creativeUsedThisMonth;
        final creativesRemaining = _accountController.remainingCreatives;

        return RefreshIndicator(
          color: AppColors.brandBlue,
          onRefresh: () async {
            await Future.wait([
              _accountsController.loadAccounts(refresh: true),
              _accountController.refreshData(),
            ]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              const Row(children: [AuthShellBackButton()]),
              const SizedBox(height: 2),
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 18),
                  child: AppLogo(iconSize: 48),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE3EAF3)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D11345F),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _SocialProfilePlatformCluster(
                          connectedPlatforms: connectedPlatforms,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Social Profile',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF111827),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'manage your connected social workspace',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: AppColors.brandBlue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      businessName,
                      style: GoogleFonts.inter(
                        color: AppColors.brandBlue,
                        fontSize: 28,
                        height: 1.02,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Social publishing, account sync, and AI content usage for this workspace.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF61758D),
                        fontSize: 13.2,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SocialProfileIdentityPill(
                          icon: Icons.person_outline_rounded,
                          label: owner,
                        ),
                        _SocialProfileIdentityPill(
                          icon: Icons.mail_outline_rounded,
                          label: email,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SocialProfileSummaryChip(
                            label: 'Connected',
                            value: '${_accountsController.connectedCount}/3',
                            tone: const Color(0xFF0A66C2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SocialProfileSummaryChip(
                            label: 'Active',
                            value: '$healthyCount running',
                            tone: const Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SocialProfileSummaryChip(
                            label: 'Need connect',
                            value: '$disconnectedCount left',
                            tone: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0A3F85), Color(0xFF1256B4)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x220A3F85),
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: TextButton.icon(
                          onPressed: () =>
                              Get.offNamed(AppRoutes.socialDashboard),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          label: Text(
                            'Open social workspace',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 0.79,
                children: [
                  _SocialProfileMetricCard(
                    icon: Icons.groups_rounded,
                    iconColor: const Color(0xFF0A66C2),
                    iconBackground: const Color(0xFFEFF6FF),
                    title: 'Connected accounts',
                    subtitle: 'Live publishing channels',
                    value: '${_accountsController.connectedCount}/3',
                    statusLabel: disconnectedCount == 0 ? 'READY' : 'SETUP',
                    statusColor: disconnectedCount == 0
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFF59E0B),
                    progress: (_accountsController.connectedCount / 3).clamp(
                      0.0,
                      1.0,
                    ),
                    progressColor: const Color(0xFF2373FF),
                    footerValue: connectedPlatforms.isEmpty
                        ? 'No platforms linked'
                        : '${_accountsController.connectedCount} platforms linked',
                  ),
                  _SocialProfileMetricCard(
                    icon: Icons.auto_awesome_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    iconBackground: const Color(0xFFF4EEFF),
                    title: 'AI posts left',
                    subtitle:
                        '$aiUsed/${_socialUsageLimitLabel(aiLimit)} used this month',
                    value: aiRemaining == 999 ? '∞' : '$aiRemaining',
                    statusLabel: aiRemaining == 0 ? 'LOW' : 'HEALTHY',
                    statusColor: aiRemaining == 0
                        ? const Color(0xFFE84E4E)
                        : const Color(0xFF1FA971),
                    progress: aiLimit <= 0
                        ? 0
                        : (aiUsed / aiLimit).clamp(0.0, 1.0),
                    progressColor: aiRemaining == 0
                        ? const Color(0xFFFF5353)
                        : const Color(0xFF2CC384),
                    footerValue: aiRemaining == 999
                        ? 'Unlimited remaining'
                        : '$aiRemaining remaining',
                  ),
                  _SocialProfileMetricCard(
                    icon: Icons.palette_outlined,
                    iconColor: const Color(0xFFE4408F),
                    iconBackground: const Color(0xFFFFEEF7),
                    title: 'Creative usage',
                    subtitle:
                        '$creativesUsed/${_socialUsageLimitLabel(creativesLimit)} generated this month',
                    value: creativesUsed == 999
                        ? '∞'
                        : '$creativesUsed/${_socialUsageLimitLabel(creativesLimit)}',
                    statusLabel: creativesRemaining == 0 ? 'LOW' : 'HEALTHY',
                    statusColor: creativesRemaining == 0
                        ? const Color(0xFFE84E4E)
                        : const Color(0xFF1FA971),
                    progress: creativesLimit <= 0
                        ? 0
                        : (creativesUsed / creativesLimit).clamp(0.0, 1.0),
                    progressColor: creativesRemaining == 0
                        ? const Color(0xFFFF5353)
                        : const Color(0xFF2CC384),
                    footerValue: creativesRemaining == 999
                        ? 'Unlimited capacity'
                        : '$creativesRemaining capacity left',
                  ),
                  _SocialProfileMetricCard(
                    icon: Icons.schedule_send_rounded,
                    iconColor: const Color(0xFF0F766E),
                    iconBackground: const Color(0xFFE8FFFB),
                    title: 'Automation health',
                    subtitle: 'Connected platforms ready to publish',
                    value:
                        '$healthyCount/${_accountsController.connectedCount}',
                    statusLabel: healthyCount > 0 ? 'RUNNING' : 'PENDING',
                    statusColor: healthyCount > 0
                        ? const Color(0xFF1FA971)
                        : const Color(0xFFF59E0B),
                    progress: _accountsController.connectedCount == 0
                        ? 0
                        : (healthyCount / _accountsController.connectedCount)
                              .clamp(0.0, 1.0),
                    progressColor: const Color(0xFF22C7BC),
                    footerValue: healthyCount > 0
                        ? '$healthyCount active sync${healthyCount == 1 ? '' : 's'}'
                        : 'Connect a channel to start',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connected platforms',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF111827),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Review live account connections, sync state, and where your posts can publish.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF61758D),
                        fontSize: 13.3,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_accountsController.isLoading.value &&
                        _accountsController.accounts.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(
                            color: AppColors.brandBlue,
                          ),
                        ),
                      )
                    else if (_accountsController.accounts.isEmpty)
                      _SocialProfileEmptyPlatformsCard(
                        onTap: () => Get.offNamed(AppRoutes.socialAccounts),
                      )
                    else
                      ..._accountsController.accounts.map(
                        (account) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SocialProfilePlatformTile(account: account),
                        ),
                      ),
                    if (_accountsController.errorMessage.value != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _accountsController.errorMessage.value!,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFE84E4E),
                          fontSize: 12.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SocialProfilePlatformCluster extends StatelessWidget {
  const _SocialProfilePlatformCluster({required this.connectedPlatforms});

  final List<String> connectedPlatforms;

  @override
  Widget build(BuildContext context) {
    final platforms = connectedPlatforms.take(3).toList(growable: false);
    final resolved = platforms.isEmpty
        ? const ['FACEBOOK', 'INSTAGRAM', 'LINKEDIN']
        : platforms;

    return SizedBox(
      width: 98,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < resolved.length; i++)
            Positioned(
              left: i * 28,
              top: 0,
              child: Image.asset(
                _socialProfilePlatformAsset(resolved[i]),
                width: 34,
                height: 34,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }
}

class _SocialProfileIdentityPill extends StatelessWidget {
  const _SocialProfileIdentityPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFD),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFB7CDEA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brandBlue),
          const SizedBox(width: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFF111827),
                fontSize: 12.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialProfileSummaryChip extends StatelessWidget {
  const _SocialProfileSummaryChip({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: tone,
              fontSize: 11.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF111827),
              fontSize: 13.4,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialProfileMetricCard extends StatelessWidget {
  const _SocialProfileMetricCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.statusLabel,
    required this.statusColor,
    required this.progress,
    required this.progressColor,
    required this.footerValue,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String value;
  final String statusLabel;
  final Color statusColor;
  final double progress;
  final Color progressColor;
  final String footerValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0911345F),
            blurRadius: 12,
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      color: AppColors.brandBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    statusLabel,
                    style: GoogleFonts.inter(
                      color: statusColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.brandBlue,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF8290A5),
              fontSize: 11.2,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE7EEF7)),
            ),
            child: Text(
              footerValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFF1F3368),
                fontSize: 11.2,
                height: 1.18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: _SocialProfileAnimatedBar(
              progress: progress,
              color: progressColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialProfileAnimatedBar extends StatefulWidget {
  const _SocialProfileAnimatedBar({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  State<_SocialProfileAnimatedBar> createState() =>
      _SocialProfileAnimatedBarState();
}

class _SocialProfileAnimatedBarState extends State<_SocialProfileAnimatedBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress.clamp(0.0, 1.0);
    return SizedBox(
      height: 6,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, animatedProgress, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final fillWidth = constraints.maxWidth * animatedProgress;
              return Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0xFFF1F4F8)),
                  ),
                  if (fillWidth > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: fillWidth,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ColoredBox(color: widget.color),
                            ),
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    (fillWidth + 30) * _controller.value - 30,
                                    0,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: 30,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withValues(alpha: 0),
                                            Colors.white.withValues(
                                              alpha: 0.42,
                                            ),
                                            Colors.white.withValues(alpha: 0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SocialProfilePlatformTile extends StatelessWidget {
  const _SocialProfilePlatformTile({required this.account});

  final SocialAccount account;

  @override
  Widget build(BuildContext context) {
    final active = account.isActive;
    final updatedAt = account.updatedAt ?? account.createdAt;
    final subtitle = updatedAt == null
        ? 'Connected and ready to publish'
        : 'Last synced ${_formatSchedulerShortDate(updatedAt)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EAF3)),
      ),
      child: Row(
        children: [
          Image.asset(
            _socialProfilePlatformAsset(account.platform),
            width: 38,
            height: 38,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _socialProfilePlatformLabel(account.platform),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF111827),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  account.platformAccountName.trim().isEmpty
                      ? subtitle
                      : '${account.platformAccountName} • $subtitle',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF66778D),
                    fontSize: 12.4,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFE8FFF2) : const Color(0xFFFFF4E4),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color:
                    (active ? const Color(0xFF1FA971) : const Color(0xFFD1821F))
                        .withValues(alpha: 0.22),
              ),
            ),
            child: Text(
              active ? 'Active' : 'Pending',
              style: GoogleFonts.inter(
                color: active
                    ? const Color(0xFF1FA971)
                    : const Color(0xFFD1821F),
                fontSize: 11.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialProfileEmptyPlatformsCard extends StatelessWidget {
  const _SocialProfileEmptyPlatformsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No social platforms connected yet',
            style: GoogleFonts.inter(
              color: const Color(0xFF111827),
              fontSize: 14.6,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Connect Facebook, Instagram, and LinkedIn so posts, scheduling, and analytics can work from one place.',
            style: GoogleFonts.inter(
              color: const Color(0xFF61758D),
              fontSize: 12.8,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFCFDBEA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Open social accounts',
              style: GoogleFonts.inter(
                color: const Color(0xFF0A3F85),
                fontSize: 13.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _socialProfilePlatformAsset(String platform) {
  switch (platform.trim().toUpperCase()) {
    case 'INSTAGRAM':
      return 'assets/images/instagram.png';
    case 'LINKEDIN':
      return 'assets/images/link.png';
    case 'FACEBOOK':
    default:
      return 'assets/images/facebook.png';
  }
}

String _socialProfilePlatformLabel(String platform) {
  switch (platform.trim().toUpperCase()) {
    case 'INSTAGRAM':
      return 'Instagram';
    case 'LINKEDIN':
      return 'LinkedIn';
    case 'FACEBOOK':
    default:
      return 'Facebook';
  }
}

String _socialUsageLimitLabel(int limit) {
  if (limit >= 999) {
    return '∞';
  }
  return '$limit';
}

String _formatSchedulerTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _formatSchedulerDateOnly(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/${date.year}';
}

String _formatSchedulerShortDate(DateTime date) {
  return '${_calendarShortMonth(date.month)} ${date.day}, ${date.year}';
}

String _formatSchedulerDateTime(DateTime date) {
  return '${_formatSchedulerShortDate(date)} at ${_formatSchedulerTime(date)}';
}

DateTime? _readSchedulerNextPostDate(Map<String, dynamic>? nextPost) {
  if (nextPost == null) return null;
  final raw = nextPost['scheduledAt'];
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

String _schedulerStatusLabel(String status) {
  final value = status.toUpperCase();
  if (value == 'PENDING_APPROVAL') return 'Pending';
  if (value == 'SCHEDULED') return 'Scheduled';
  if (value == 'FAILED') return 'Failed';
  return 'Draft';
}

String _schedulerPlatformIconPath(SchedulerQueueItem post) {
  final platforms = post.platforms.map((item) => item.toLowerCase()).toList();
  if (platforms.contains('instagram')) return 'assets/images/instagram.png';
  if (platforms.contains('linkedin')) return 'assets/images/link.png';
  return 'assets/images/facebook.png';
}

Color _schedulerPlatformColor(SchedulerQueueItem post) {
  final platforms = post.platforms.map((item) => item.toLowerCase()).toList();
  if (platforms.contains('instagram')) return const Color(0xFFE4408F);
  if (platforms.contains('linkedin')) return const Color(0xFF0A66C2);
  return const Color(0xFF1877F2);
}

Color _schedulerScoreColor(int score) {
  if (score >= 85) return const Color(0xFF10B981);
  if (score >= 55) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

class SocialSchedulerView extends StatefulWidget {
  const SocialSchedulerView({super.key});

  @override
  State<SocialSchedulerView> createState() => _SocialSchedulerViewState();
}

class _SocialSchedulerViewState extends State<SocialSchedulerView> {
  final OnboardingController _controller = Get.find<OnboardingController>();
  late final SocialSchedulerController _schedulerController =
      Get.isRegistered<SocialSchedulerController>()
      ? Get.find<SocialSchedulerController>()
      : Get.put(SocialSchedulerController());
  bool _isSidebarOpen = false;
  int _selectedTabIndex = 0;
  String _selectedQueuePlatform = 'all';
  String _selectedQueueStatus = 'all';
  String? _pendingSchedulePostId;
  bool _handledInitialSchedulerArgs = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      _readInitialSchedulerArguments();
      await _schedulerController.loadDashboard();
      if (!mounted) return;
      _openPendingSchedulePostIfNeeded();
    });
  }

  void _readInitialSchedulerArguments() {
    if (_handledInitialSchedulerArgs) return;
    _handledInitialSchedulerArgs = true;

    final args = Get.arguments;
    if (args is! Map) return;

    final map = Map<String, dynamic>.from(args);
    final selectedStatus = (map['selectedStatus'] ?? '').toString().trim();
    final selectedPlatform = (map['selectedPlatform'] ?? '').toString().trim();
    final pendingPostId = (map['openSchedulePostId'] ?? '').toString().trim();

    if (selectedStatus.isNotEmpty) {
      _selectedQueueStatus = selectedStatus;
    }
    if (selectedPlatform.isNotEmpty) {
      _selectedQueuePlatform = selectedPlatform;
    }
    if (pendingPostId.isNotEmpty) {
      _pendingSchedulePostId = pendingPostId;
    }
  }

  void _openPendingSchedulePostIfNeeded() {
    final postId = _pendingSchedulePostId;
    final dashboard = _schedulerController.dashboard.value;
    if (postId == null || postId.isEmpty || dashboard == null) return;

    final match = dashboard.queue.firstWhereOrNull((post) => post.id == postId);
    if (match == null) return;

    _pendingSchedulePostId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showSuggestedScheduleDialog(match);
    });
  }

  Future<void> _toggleAutoSchedule(bool value) async {
    try {
      await _schedulerController.updateAutoSchedule(value);
    } catch (error) {
      _showSchedulerSnack(
        'Unable to update scheduler',
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _deleteQueuePost(SchedulerQueueItem post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Delete queued post?'),
          content: const Text(
            'This will remove the queued post from your social scheduler.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFE83E5A)),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      await _schedulerController.deletePost(post);
      _showSchedulerSnack('Deleted', 'Queued post removed successfully.');
    } catch (error) {
      _showSchedulerSnack(
        'Delete failed',
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _rejectQueuePost(SchedulerQueueItem post) async {
    try {
      await _schedulerController.rejectPost(post);
      _showSchedulerSnack('Rejected', 'Post moved back to draft.');
    } catch (error) {
      _showSchedulerSnack(
        'Reject failed',
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _showSchedulerSnack(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
    );
  }

  void _showSuggestedScheduleDialog(SchedulerQueueItem post) {
    final suggestedTime = _schedulerController.suggestedTimeFor(post);
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xB3000000),
      builder: (dialogContext) {
        return _SchedulerSuggestedDialog(
          suggestedTime: suggestedTime,
          onPickOwn: () {
            Navigator.of(dialogContext).pop();
            _showManualScheduleDialog(post, initialTime: suggestedTime);
          },
          onSchedule: () async {
            Navigator.of(dialogContext).pop();
            await _schedulePostAt(post, suggestedTime);
          },
        );
      },
    );
  }

  void _showManualScheduleDialog(
    SchedulerQueueItem post, {
    DateTime? initialTime,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xB3000000),
      builder: (dialogContext) {
        return _SchedulerManualDialog(
          initialDateTime:
              initialTime ?? _schedulerController.suggestedTimeFor(post),
          onBack: () {
            Navigator.of(dialogContext).pop();
            _showSuggestedScheduleDialog(post);
          },
          onSchedule: (scheduledAt) async {
            Navigator.of(dialogContext).pop();
            await _schedulePostAt(post, scheduledAt);
          },
        );
      },
    );
  }

  Future<void> _schedulePostAt(
    SchedulerQueueItem post,
    DateTime scheduledAt,
  ) async {
    try {
      await _schedulerController.schedulePost(post, scheduledAt);
      _showSchedulerSnack(
        'Post scheduled',
        'This post will publish automatically at ${_formatSchedulerDateTime(scheduledAt)}.',
      );
    } catch (error) {
      _showSchedulerSnack(
        'Schedule failed',
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _approveQueuePost(SchedulerQueueItem post) async {
    try {
      await _schedulerController.approvePost(post);
      _showSchedulerSnack('Approved', 'Post approved for scheduling.');
    } catch (error) {
      _showSchedulerSnack(
        'Approve failed',
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _openSidebar(TestAccount user) async {
    if (_isSidebarOpen) {
      return;
    }
    setState(() => _isSidebarOpen = true);
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierLabel: 'Social sidebar',
        barrierDismissible: true,
        barrierColor: const Color(0x800F2746),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          final safeTop = MediaQuery.paddingOf(dialogContext).top;
          final safeBottom = MediaQuery.paddingOf(dialogContext).bottom;
          final screenWidth = MediaQuery.sizeOf(dialogContext).width;
          final sidebarWidth = screenWidth * 0.8;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(dialogContext).pop(),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: TweenAnimationBuilder<Offset>(
                      tween: Tween(
                        begin: const Offset(-1.02, 0),
                        end: Offset.zero,
                      ),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      builder: (context, offset, child) {
                        return FractionalTranslation(
                          translation: offset,
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: sidebarWidth,
                        height: double.infinity,
                        child: SocialSidebarPanel(
                          user: user,
                          safeTopInset: safeTop,
                          safeBottomInset: safeBottom,
                          onDashboardTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialDashboard);
                          },
                          onAccountsTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialAccounts);
                          },
                          onCreateTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialCreate);
                          },
                          onCreativesTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialCreatives);
                          },
                          onCalendarTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialCalendar);
                          },
                          onSchedulerTap: () =>
                              Navigator.of(dialogContext).pop(),
                          onPostsTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialPosts);
                          },
                          onAnalyticsTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialAnalytics);
                          },
                          onProfileTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.socialProfile);
                          },
                          onPaymentTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.offNamed(AppRoutes.payment);
                          },
                          onSupportTap: () {
                            Navigator.of(dialogContext).pop();
                            Get.toNamed(AppRoutes.support);
                          },
                          onCollapseTap: () =>
                              Navigator.of(dialogContext).pop(),
                          onLogoutTap: () {
                            Navigator.of(dialogContext).pop();
                            _controller.logout();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSidebarOpen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productModeController = Get.isRegistered<ProductModeController>()
        ? Get.find<ProductModeController>()
        : Get.put(ProductModeController(), permanent: true);
    if (!productModeController.isSocialMedia) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        productModeController.selectMode(ProductMode.socialMedia);
      });
    }

    return AuthNavigationShell(
      currentTab: AuthTab.socialCalendar,
      backgroundColor: const Color(0xFFFBFCFF),
      child: Obx(() {
        final user = _controller.currentUser.value;
        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SocialCreateTopBar(onMenuTap: () => _openSidebar(user)),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scheduler',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF101A35),
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                            height: 1.05,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Manage, optimize, and automate your social posts.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF64728F),
                            fontSize: 14.2,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _SchedulerAutoSwitch(
                    value:
                        _schedulerController
                            .dashboard
                            .value
                            ?.settings
                            .autoScheduleMode ??
                        false,
                    onChanged: _toggleAutoSchedule,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SchedulerTabs(
                selectedIndex: _selectedTabIndex,
                onSelected: (index) {
                  setState(() => _selectedTabIndex = index);
                },
              ),
              const SizedBox(height: 16),
              if (_schedulerController.isLoading.value)
                const _SchedulerLoadingCard()
              else if (_schedulerController.errorMessage.value != null)
                _SchedulerErrorCard(
                  message: _schedulerController.errorMessage.value!,
                  onRetry: _schedulerController.loadDashboard,
                )
              else if (_schedulerController.dashboard.value == null)
                _SchedulerErrorCard(
                  message: 'Scheduler data is not available right now.',
                  onRetry: _schedulerController.loadDashboard,
                )
              else
                _SchedulerTabContent(
                  dashboard: _schedulerController.dashboard.value!,
                  selectedTabIndex: _selectedTabIndex,
                  selectedPlatform: _selectedQueuePlatform,
                  selectedStatus: _selectedQueueStatus,
                  onPlatformSelected: (value) {
                    setState(() {
                      _selectedQueuePlatform = value;
                      _pendingSchedulePostId = null;
                    });
                  },
                  onStatusSelected: (value) {
                    setState(() {
                      _selectedQueueStatus = value;
                      _pendingSchedulePostId = null;
                    });
                  },
                  onSchedulePost: _showSuggestedScheduleDialog,
                  onDeletePost: _deleteQueuePost,
                  onApprovePost: _approveQueuePost,
                  onRejectPost: _rejectQueuePost,
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _SchedulerAutoSwitch extends StatelessWidget {
  const _SchedulerAutoSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Auto Schedule',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF15213D),
              fontSize: 12.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          Transform.scale(
            scale: 0.78,
            child: Switch(
              value: value,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF10B981),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFD5DFEC),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SchedulerLoadingCard extends StatelessWidget {
  const _SchedulerLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F2)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF5A4CFF)),
      ),
    );
  }
}

class _SchedulerErrorCard extends StatelessWidget {
  const _SchedulerErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD7D7)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFEF4444),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF64728F),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF5A4CFF),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SchedulerTabContent extends StatelessWidget {
  const _SchedulerTabContent({
    required this.dashboard,
    required this.selectedTabIndex,
    required this.selectedPlatform,
    required this.selectedStatus,
    required this.onPlatformSelected,
    required this.onStatusSelected,
    required this.onSchedulePost,
    required this.onDeletePost,
    required this.onApprovePost,
    required this.onRejectPost,
  });

  final SchedulerDashboard dashboard;
  final int selectedTabIndex;
  final String selectedPlatform;
  final String selectedStatus;
  final ValueChanged<String> onPlatformSelected;
  final ValueChanged<String> onStatusSelected;
  final ValueChanged<SchedulerQueueItem> onSchedulePost;
  final ValueChanged<SchedulerQueueItem> onDeletePost;
  final ValueChanged<SchedulerQueueItem> onApprovePost;
  final ValueChanged<SchedulerQueueItem> onRejectPost;

  @override
  Widget build(BuildContext context) {
    final commonTop = <Widget>[
      _SchedulerStatusCard(settings: dashboard.settings),
      const SizedBox(height: 14),
      _SchedulerMetricGrid(stats: dashboard.stats),
      const SizedBox(height: 14),
    ];

    if (selectedTabIndex == 1) {
      return Column(
        children: [
          _BestTimesCard(bestTimes: dashboard.bestTimes),
          const SizedBox(height: 14),
          _SchedulerInsightsCard(insights: dashboard.aiInsights),
        ],
      );
    }

    if (selectedTabIndex == 2) {
      return Column(
        children: [
          ...commonTop,
          const _SchedulerRulesCard(),
          const SizedBox(height: 14),
          _SchedulerInsightsCard(insights: dashboard.aiInsights),
        ],
      );
    }

    return Column(
      children: [
        ...commonTop,
        _ScheduledQueueCard(
          queue: dashboard.queue,
          selectedPlatform: selectedPlatform,
          selectedStatus: selectedStatus,
          onPlatformSelected: onPlatformSelected,
          onStatusSelected: onStatusSelected,
          onSchedulePost: onSchedulePost,
          onDeletePost: onDeletePost,
          onApprovePost: onApprovePost,
          onRejectPost: onRejectPost,
        ),
        const SizedBox(height: 14),
        _BestTimesCard(bestTimes: dashboard.bestTimes),
        const SizedBox(height: 14),
        _SchedulerInsightsCard(insights: dashboard.aiInsights),
      ],
    );
  }
}

class _SchedulerTabs extends StatelessWidget {
  const _SchedulerTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const tabs = ['Queue', 'Best Times', 'Rules'];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFDDE6F1))),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: Container(
              padding: const EdgeInsets.fromLTRB(2, 0, 30, 12),
              decoration: BoxDecoration(
                border: selected
                    ? const Border(
                        bottom: BorderSide(
                          color: Color(0xFF5A4CFF),
                          width: 2.4,
                        ),
                      )
                    : null,
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: selected
                      ? const Color(0xFF5A4CFF)
                      : const Color(0xFF64728F),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SchedulerStatusCard extends StatelessWidget {
  const _SchedulerStatusCard({required this.settings});

  final SchedulerSettings settings;

  @override
  Widget build(BuildContext context) {
    final features = [
      (
        icon: Icons.schedule_rounded,
        title: 'Best Time\nScheduling',
        color: Color(0xFF5A4CFF),
      ),
      (
        icon: Icons.language_rounded,
        title: 'Time Zone\nOptimization',
        color: Color(0xFF10B981),
      ),
      (
        icon: Icons.bolt_rounded,
        title: 'Engagement\nPrediction',
        color: Color(0xFF10B981),
      ),
      (
        icon: Icons.autorenew_rounded,
        title: 'Auto\nReschedule',
        color: Color(0xFF5A4CFF),
      ),
    ];
    final active = settings.autoScheduleMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E0F2746),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Scheduler Status',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF111827),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFE8FFF7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: active ? Color(0xFF10B981) : Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      active ? 'Active' : 'Paused',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: active ? Color(0xFF059669) : Color(0xFF64748B),
                        fontSize: 12.6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(features.length, (index) {
              final item = features[index];
              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: item.color, size: 19),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF1B2745),
                        fontSize: 9.8,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      index == 3 && !settings.autoScheduleMode
                          ? 'Paused'
                          : 'Enabled',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: index == 3 && !settings.autoScheduleMode
                            ? Color(0xFF64748B)
                            : Color(0xFF10B981),
                        fontSize: 9.8,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SchedulerMetricGrid extends StatelessWidget {
  const _SchedulerMetricGrid({required this.stats});

  final SchedulerStats stats;

  @override
  Widget build(BuildContext context) {
    final nextPost = stats.nextPost;
    final nextPostDate = _readSchedulerNextPostDate(nextPost);
    final metrics = [
      (
        icon: Icons.event_available_rounded,
        title: 'Total Posts in Queue',
        value: '${stats.totalInQueue}',
        detail: 'Queue Active',
        color: Color(0xFF5A4CFF),
        bg: Color(0xFFF0EEFF),
      ),
      (
        icon: Icons.event_repeat_rounded,
        title: 'Scheduled This Week',
        value: '${stats.scheduledThisWeek}',
        detail: 'Upcoming',
        color: Color(0xFF10B981),
        bg: Color(0xFFE6FBF4),
      ),
      (
        icon: Icons.trending_up_rounded,
        title: 'AI Recommended Times',
        value: '92%',
        detail: 'Engagement accuracy',
        color: Color(0xFFF59E0B),
        bg: Color(0xFFFFF7E6),
      ),
      (
        icon: Icons.schedule_rounded,
        title: 'Next Post',
        value: nextPostDate == null
            ? 'None'
            : _formatSchedulerTime(nextPostDate),
        detail: nextPostDate == null
            ? 'No post scheduled'
            : _formatSchedulerShortDate(nextPostDate),
        color: Color(0xFFEC4899),
        bg: Color(0xFFFDF2F8),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.62,
      ),
      itemBuilder: (context, index) {
        final item = metrics[index];
        return Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F2)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF64728F),
                        fontSize: 10.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF111827),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: index == 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFF64728F),
                        fontSize: 10.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScheduledQueueCard extends StatefulWidget {
  const _ScheduledQueueCard({
    required this.queue,
    required this.selectedPlatform,
    required this.selectedStatus,
    required this.onPlatformSelected,
    required this.onStatusSelected,
    required this.onSchedulePost,
    required this.onDeletePost,
    required this.onApprovePost,
    required this.onRejectPost,
  });

  final List<SchedulerQueueItem> queue;
  final String selectedPlatform;
  final String selectedStatus;
  final ValueChanged<String> onPlatformSelected;
  final ValueChanged<String> onStatusSelected;
  final ValueChanged<SchedulerQueueItem> onSchedulePost;
  final ValueChanged<SchedulerQueueItem> onDeletePost;
  final ValueChanged<SchedulerQueueItem> onApprovePost;
  final ValueChanged<SchedulerQueueItem> onRejectPost;

  @override
  State<_ScheduledQueueCard> createState() => _ScheduledQueueCardState();
}

class _ScheduledQueueCardState extends State<_ScheduledQueueCard> {
  static const int _pageSize = 10;
  int _pageIndex = 0;

  @override
  void didUpdateWidget(covariant _ScheduledQueueCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPlatform != widget.selectedPlatform ||
        oldWidget.selectedStatus != widget.selectedStatus ||
        oldWidget.queue.length != widget.queue.length) {
      _pageIndex = 0;
    }
  }

  bool _matchesStatus(SchedulerQueueItem post) {
    switch (widget.selectedStatus) {
      case 'draft':
        return post.status.toUpperCase() == 'DRAFT';
      case 'scheduled':
        return post.status.toUpperCase() == 'SCHEDULED';
      case 'failed':
        return post.status.toUpperCase() == 'FAILED';
      default:
        return true;
    }
  }

  DateTime _sortValue(SchedulerQueueItem post) {
    return post.createdAt ??
        post.scheduledAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    final visiblePosts = widget.queue.where((post) {
      final matchesPlatform =
          widget.selectedPlatform == 'all' ||
          post.platforms
              .map((item) => item.toLowerCase().trim())
              .contains(widget.selectedPlatform);
      return matchesPlatform && _matchesStatus(post);
    }).toList()..sort((a, b) => _sortValue(b).compareTo(_sortValue(a)));
    final totalPages = visiblePosts.isEmpty
        ? 1
        : ((visiblePosts.length + _pageSize - 1) ~/ _pageSize);
    if (_pageIndex >= totalPages) _pageIndex = totalPages - 1;
    final start = _pageIndex * _pageSize;
    final pagedPosts = visiblePosts
        .skip(start)
        .take(_pageSize)
        .toList(growable: false);
    final avgScore = visiblePosts.isEmpty
        ? 0
        : (visiblePosts.fold<int>(0, (sum, post) => sum + post.aiScore) /
                  visiblePosts.length)
              .round();
    final draftCount = visiblePosts
        .where((post) => post.status.toUpperCase() == 'DRAFT')
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2746),
            blurRadius: 22,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scheduled Queue',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF08112F),
                        fontSize: 24,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Manage upcoming posts with AI recommendations',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF64728F),
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _SchedulerPlatformDropdown(
                selectedPlatform: widget.selectedPlatform,
                onSelected: widget.onPlatformSelected,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SchedulerQueueStatusChips(
            selectedStatus: widget.selectedStatus,
            onSelected: widget.onStatusSelected,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SchedulerQueueSummaryTile(
                  icon: Icons.event_available_rounded,
                  label: 'Queue Active',
                  value: '${visiblePosts.length}',
                  color: const Color(0xFF10B981),
                  bg: const Color(0xFFE8FFF7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SchedulerQueueSummaryTile(
                  icon: Icons.trending_up_rounded,
                  label: 'Avg Score',
                  value: '$avgScore',
                  color: const Color(0xFFF59E0B),
                  bg: const Color(0xFFFFF7E6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SchedulerQueueSummaryTile(
                  icon: Icons.description_outlined,
                  label: 'Draft Posts',
                  value: '$draftCount',
                  color: const Color(0xFF6652E8),
                  bg: const Color(0xFFF0EEFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (visiblePosts.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                widget.selectedStatus == 'all'
                    ? 'No queued posts for this platform.'
                    : 'No ${_schedulerQueueStatusLabel(widget.selectedStatus).toLowerCase()} posts for this platform.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF64728F),
                  fontSize: 12.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...List.generate(pagedPosts.length, (index) {
              final post = pagedPosts[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == pagedPosts.length - 1 ? 0 : 10,
                ),
                child: _SchedulerQueuePostCard(
                  post: post,
                  onSchedule: () => widget.onSchedulePost(post),
                  onDelete: () => widget.onDeletePost(post),
                  onApprove: () => widget.onApprovePost(post),
                  onReject: () => widget.onRejectPost(post),
                ),
              );
            }),
          if (visiblePosts.length > _pageSize) ...[
            const SizedBox(height: 14),
            _SchedulerQueuePagination(
              currentPage: _pageIndex + 1,
              totalPages: totalPages,
              startItem: start + 1,
              endItem: (start + pagedPosts.length).clamp(
                0,
                visiblePosts.length,
              ),
              totalItems: visiblePosts.length,
              onPrevious: _pageIndex == 0
                  ? null
                  : () => setState(() => _pageIndex -= 1),
              onNext: _pageIndex >= totalPages - 1
                  ? null
                  : () => setState(() => _pageIndex += 1),
            ),
          ],
          if (visiblePosts.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFAF8FF), Color(0xFFF8FBFF)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5DEFF)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0EEFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF6652E8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      avgScore >= 70
                          ? 'Posts with a score above 70 perform better on average.'
                          : 'Improve captions, hashtags, and images to raise queue scores.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF34405E),
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _schedulerQueueStatusLabel(String value) {
  switch (value) {
    case 'draft':
      return 'Draft';
    case 'scheduled':
      return 'Scheduled';
    case 'failed':
      return 'Failed';
    default:
      return 'All';
  }
}

class _SchedulerQueueStatusChips extends StatelessWidget {
  const _SchedulerQueueStatusChips({
    required this.selectedStatus,
    required this.onSelected,
  });

  final String selectedStatus;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = <(String, String)>[
      ('all', 'All'),
      ('draft', 'Draft'),
      ('scheduled', 'Scheduled'),
      ('failed', 'Failed'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          final selected = selectedStatus == item.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(item.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [
                            _socialBrandButtonStart,
                            _socialBrandButtonEnd,
                          ],
                        )
                      : null,
                  color: selected ? null : const Color(0xFFF8FAFD),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : const Color(0xFFE0E8F2),
                  ),
                ),
                child: Text(
                  item.$2,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: selected ? Colors.white : const Color(0xFF1B2745),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SchedulerQueueSummaryTile extends StatelessWidget {
  const _SchedulerQueueSummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF64728F),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              color: color,
              fontSize: 21,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SchedulerQueuePostCard extends StatelessWidget {
  const _SchedulerQueuePostCard({
    required this.post,
    required this.onSchedule,
    required this.onDelete,
    required this.onApprove,
    required this.onReject,
  });

  final SchedulerQueueItem post;
  final VoidCallback onSchedule;
  final VoidCallback onDelete;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final scoreColor = _schedulerScoreColor(post.aiScore);
    final statusLabel = _schedulerStatusLabel(post.status);
    final scheduledLabel = post.scheduledAt == null
        ? 'Unscheduled'
        : _formatSchedulerDateTime(post.scheduledAt!);
    final title = post.title.isEmpty ? post.caption : post.title;
    final pendingApproval = post.status.toUpperCase() == 'PENDING_APPROVAL';

    return Container(
      padding: const EdgeInsets.fromLTRB(9, 9, 9, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F2746),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: post.imageUrl == null
                ? Container(
                    width: 64,
                    height: 72,
                    color: const Color(0xFFF0F4FA),
                    child: Icon(
                      Icons.article_outlined,
                      color: _schedulerPlatformColor(post),
                      size: 24,
                    ),
                  )
                : Image.network(
                    post.imageUrl!,
                    width: 64,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 64,
                      height: 72,
                      color: const Color(0xFFF0F4FA),
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: _schedulerPlatformColor(post),
                        size: 22,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF08112F),
                    fontSize: 13.1,
                    height: 1.18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF9CA8C0),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        scheduledLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF64728F),
                          fontSize: 10.6,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Image.asset(
                      _schedulerPlatformIconPath(post),
                      width: 23,
                      height: 23,
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F8FC),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE0E8F2)),
                      ),
                      child: Text(
                        statusLabel,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF2743A6),
                          fontSize: 10.4,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            children: [
              _SchedulerLargeScoreBadge(
                score: post.aiScore,
                label: post.scoreLabel.isEmpty ? 'Needs Work' : post.scoreLabel,
                color: scoreColor,
              ),
            ],
          ),
          const SizedBox(width: 6),
          Column(
            children: [
              _SchedulerQueueActionButton(
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFF10B981),
                background: const Color(0xFFE6FBF4),
                onTap: onSchedule,
              ),
              const SizedBox(height: 10),
              if (pendingApproval) ...[
                _SchedulerQueueActionButton(
                  icon: Icons.check_rounded,
                  color: const Color(0xFF3168FF),
                  background: const Color(0xFFEAF2FF),
                  onTap: onApprove,
                ),
                const SizedBox(height: 10),
                _SchedulerQueueActionButton(
                  icon: Icons.close_rounded,
                  color: const Color(0xFFF59E0B),
                  background: const Color(0xFFFFF7E6),
                  onTap: onReject,
                ),
                const SizedBox(height: 10),
              ],
              _SchedulerQueueActionButton(
                icon: Icons.delete_outline_rounded,
                color: const Color(0xFFE11D48),
                background: const Color(0xFFFFF1F2),
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SchedulerLargeScoreBadge extends StatelessWidget {
  const _SchedulerLargeScoreBadge({
    required this.score,
    required this.label,
    required this.color,
  });

  final int score;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3.4),
            ),
            child: Text(
              '$score',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF08112F),
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: color,
              fontSize: 8.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SchedulerQueuePagination extends StatelessWidget {
  const _SchedulerQueuePagination({
    required this.currentPage,
    required this.totalPages,
    required this.startItem,
    required this.endItem,
    required this.totalItems,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final int startItem;
  final int endItem;
  final int totalItems;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5ECF5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $startItem-$endItem of $totalItems',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF64728F),
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _SchedulerPageButton(
            icon: Icons.chevron_left_rounded,
            onTap: onPrevious,
          ),
          const SizedBox(width: 8),
          Text(
            '$currentPage / $totalPages',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF111827),
              fontSize: 12.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          _SchedulerPageButton(
            icon: Icons.chevron_right_rounded,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _SchedulerPageButton extends StatelessWidget {
  const _SchedulerPageButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFEFF3F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDDE6F1)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? const Color(0xFF5A4CFF) : const Color(0xFF9AA7BA),
        ),
      ),
    );
  }
}

class _SchedulerQueueActionButton extends StatelessWidget {
  const _SchedulerQueueActionButton({
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }
}

class _SchedulerPlatformDropdown extends StatelessWidget {
  const _SchedulerPlatformDropdown({
    required this.selectedPlatform,
    required this.onSelected,
  });

  final String selectedPlatform;
  final ValueChanged<String> onSelected;

  String get _label => switch (selectedPlatform) {
    'facebook' => 'Facebook',
    'instagram' => 'Instagram',
    'linkedin' => 'LinkedIn',
    _ => 'All Platforms',
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: selectedPlatform,
      color: Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'all', child: Text('All Platforms')),
        PopupMenuItem(value: 'facebook', child: Text('Facebook')),
        PopupMenuItem(value: 'instagram', child: Text('Instagram')),
        PopupMenuItem(value: 'linkedin', child: Text('LinkedIn')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFE0E8F2)),
        ),
        child: Row(
          children: [
            Text(
              _label,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF1B2745),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _BestTimesCard extends StatefulWidget {
  const _BestTimesCard({required this.bestTimes});

  final Map<String, List<SchedulerBestTime>> bestTimes;

  @override
  State<_BestTimesCard> createState() => _BestTimesCardState();
}

class _BestTimesCardState extends State<_BestTimesCard> {
  String _selectedPlatform = 'facebook';

  @override
  Widget build(BuildContext context) {
    final times = _readBestTimesForPlatform(
      widget.bestTimes,
      _selectedPlatform,
    );

    return _SchedulerSectionCard(
      title: 'Best Times to Post',
      trailing: const Icon(
        Icons.insights_rounded,
        color: Color(0xFF5A4CFF),
        size: 22,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FD),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFE4EBF5)),
            ),
            child: Row(
              children: [
                _BestTimePlatformPill(
                  iconPath: 'assets/images/facebook.png',
                  label: 'Facebook',
                  selected: _selectedPlatform == 'facebook',
                  onTap: () => setState(() => _selectedPlatform = 'facebook'),
                ),
                _BestTimePlatformPill(
                  iconPath: 'assets/images/instagram.png',
                  label: 'Instagram',
                  selected: _selectedPlatform == 'instagram',
                  onTap: () => setState(() => _selectedPlatform = 'instagram'),
                ),
                _BestTimePlatformPill(
                  iconPath: 'assets/images/link.png',
                  label: 'LinkedIn',
                  selected: _selectedPlatform == 'linkedin',
                  onTap: () => setState(() => _selectedPlatform = 'linkedin'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (times.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Best-time recommendations will appear after scheduler data is ready.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF64728F),
                  fontSize: 12.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...times.take(4).map((time) {
              final color = time.level.toLowerCase().contains('high')
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B);
              return Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFCFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE7EEF7)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        time.time,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF111827),
                          fontSize: 11.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            time.days,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF1B2745),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: (time.barPct.clamp(0, 100)) / 100,
                              minHeight: 5,
                              color: color,
                              backgroundColor: const Color(0xFFE7EDF5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        time.level,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  List<SchedulerBestTime> _readBestTimesForPlatform(
    Map<String, List<SchedulerBestTime>> source,
    String platform,
  ) {
    return source[platform] ??
        source[platform.capitalizeFirst ?? platform] ??
        const <SchedulerBestTime>[];
  }
}

class _BestTimePlatformPill extends StatelessWidget {
  const _BestTimePlatformPill({
    required this.iconPath,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String iconPath;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF3168FF), Color(0xFF6736F4)],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(iconPath, width: 15, height: 15),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: selected ? Colors.white : const Color(0xFF64728F),
                    fontSize: 10.6,
                    fontWeight: FontWeight.w900,
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

class _SchedulerRulesCard extends StatelessWidget {
  const _SchedulerRulesCard();

  @override
  Widget build(BuildContext context) {
    const rules = [
      (
        title: 'Avoid duplicate platform posts',
        detail: 'Keep a minimum 2 hour gap between similar posts.',
        enabled: true,
      ),
      (
        title: 'Prefer AI recommended windows',
        detail: 'Queue drafts into high engagement slots first.',
        enabled: true,
      ),
      (
        title: 'Auto retry failed posts',
        detail: 'Retry failed publishing attempts after 30 minutes.',
        enabled: false,
      ),
    ];

    return _SchedulerSectionCard(
      title: 'Content Rules',
      child: Column(
        children: rules.map((rule) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EEF5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: rule.enabled
                        ? const Color(0xFFE6FBF4)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    rule.enabled ? Icons.check_rounded : Icons.pause_rounded,
                    color: rule.enabled
                        ? const Color(0xFF10B981)
                        : const Color(0xFF64728F),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF111827),
                          fontSize: 12.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rule.detail,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF64728F),
                          fontSize: 11.4,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: rule.enabled,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF10B981),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFD5DFEC),
                  onChanged: (_) {},
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SchedulerInsightsCard extends StatelessWidget {
  const _SchedulerInsightsCard({required this.insights});

  final List<String> insights;

  @override
  Widget build(BuildContext context) {
    final visibleInsights = insights.isEmpty
        ? const ['AI insights will appear after scheduler data is analyzed.']
        : insights;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF9F7FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4DEFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F2746),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0EEFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF6652E8),
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Insights',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF111827),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Smart recommendations from your queue',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF64728F),
                        fontSize: 11.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF64728F)),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(visibleInsights.length, (index) {
            final insight = visibleInsights[index];
            final color = index.isEven
                ? const Color(0xFF5A4CFF)
                : const Color(0xFF10B981);
            return Container(
              margin: EdgeInsets.only(
                bottom: index == visibleInsights.length - 1 ? 0 : 9,
              ),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.12)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bolt_rounded, color: color, size: 15),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      insight,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF34405E),
                        fontSize: 12.4,
                        height: 1.32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SchedulerSuggestedDialog extends StatelessWidget {
  const _SchedulerSuggestedDialog({
    required this.suggestedTime,
    required this.onPickOwn,
    required this.onSchedule,
  });

  final DateTime suggestedTime;
  final VoidCallback onPickOwn;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.transparent,
      child: _SchedulerModalCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SchedulerModalHeader(
              title: 'Schedule Post',
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 12),
            const Text(
              'AI has analyzed your audience and found the perfect time to post.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF556987),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 26),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFEFF5FF), Color(0xFFF7FAFF)],
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFF0A3F85),
                    size: 52,
                  ),
                  const Positioned(
                    left: 8,
                    top: 24,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF4478C6),
                      size: 18,
                    ),
                  ),
                  const Positioned(
                    right: 8,
                    bottom: 18,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF4478C6),
                      size: 18,
                    ),
                  ),
                  const Positioned(
                    left: 28,
                    bottom: 10,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF4478C6),
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE3EAF4)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A0A3F85),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'AI Suggested Time',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF1F3765),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatSchedulerDateTime(suggestedTime),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF08112F),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFB9CCE7)),
                      color: const Color(0xFFF7FBFF),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          color: Color(0xFF0A3F85),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'High Engagement Expected',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF0A3F85),
                            fontSize: 13.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPickOwn,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: const BorderSide(color: Color(0xFFDDE6F1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      "No, I’ll pick my own",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF08112F),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSchedule,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF0A3F85),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Yes, schedule at this time',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontSize: 13.8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SchedulerManualDialog extends StatefulWidget {
  const _SchedulerManualDialog({
    required this.initialDateTime,
    required this.onBack,
    required this.onSchedule,
  });

  final DateTime initialDateTime;
  final VoidCallback onBack;
  final ValueChanged<DateTime> onSchedule;

  @override
  State<_SchedulerManualDialog> createState() => _SchedulerManualDialogState();
}

class _SchedulerManualDialogState extends State<_SchedulerManualDialog> {
  late DateTime _selectedDateTime = widget.initialDateTime;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030, 12, 31),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: const Color(0xFF0A3F85),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF08112F),
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: Color(0xFF0A3F85),
              headerForegroundColor: Colors.white,
              dividerColor: Color(0xFFE4EBF4),
            ),
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(28)),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0A3F85),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDateTime.hour,
        _selectedDateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showDialog<TimeOfDay>(
      context: context,
      barrierColor: const Color(0xB3000000),
      builder: (dialogContext) {
        return _SchedulerTimePickerDialog(
          initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
          selectedDateTime: _selectedDateTime,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDateTime = DateTime(
        _selectedDateTime.year,
        _selectedDateTime.month,
        _selectedDateTime.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.transparent,
      child: _SchedulerModalCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SchedulerModalHeader(
              title: 'Schedule Post',
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 12),
            const Text(
              'Select the exact date and time you want this post to be published.',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF556987),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 26),
            _SchedulerManualField(
              label: 'Date',
              value: _formatSchedulerDateOnly(_selectedDateTime),
              icon: Icons.keyboard_arrow_down_rounded,
              leadingIcon: Icons.calendar_today_outlined,
              onTap: _pickDate,
            ),
            const SizedBox(height: 14),
            _SchedulerManualField(
              label: 'Time',
              value: _formatSchedulerTime(_selectedDateTime),
              icon: Icons.keyboard_arrow_down_rounded,
              leadingIcon: Icons.access_time_rounded,
              onTap: _pickTime,
            ),
            const SizedBox(height: 20),
            _SchedulerMessageCard(
              message:
                  'Great choice! Engagement is typically high around this time on ${_schedulerWeekdayLabel(_selectedDateTime)}s.',
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFDDE6F1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF08112F),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onSchedule(_selectedDateTime),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF0A3F85),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Schedule Post',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SchedulerManualField extends StatelessWidget {
  const _SchedulerManualField({
    required this.label,
    required this.value,
    required this.icon,
    required this.leadingIcon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final IconData leadingIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 112,
          height: 94,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FC),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE7EDF6)),
          ),
          child: Icon(leadingIcon, color: const Color(0xFF0A3F85), size: 32),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 94,
              padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFDDE6F1)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A0A3F85),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF425A82),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          value,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF08112F),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(icon, color: const Color(0xFF60789D), size: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _schedulerWeekdayLabel(DateTime date) {
  const values = <int, String>{
    DateTime.monday: 'Monday',
    DateTime.tuesday: 'Tuesday',
    DateTime.wednesday: 'Wednesday',
    DateTime.thursday: 'Thursday',
    DateTime.friday: 'Friday',
    DateTime.saturday: 'Saturday',
    DateTime.sunday: 'Sunday',
  };
  return values[date.weekday] ?? 'day';
}

class _SchedulerModalCard extends StatelessWidget {
  const _SchedulerModalCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x240A1A36),
            blurRadius: 32,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SchedulerModalHeader extends StatelessWidget {
  const _SchedulerModalHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFE4E8EF),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const SizedBox(width: 52),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF08112F),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            GestureDetector(
              onTap: onClose,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE7EDF6)),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF08112F),
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SchedulerMessageCard extends StatelessWidget {
  const _SchedulerMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FDFF), Color(0xFFF7FBFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDECF3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFE8FAF6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Color(0xFF10B981),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF34405E),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SchedulerTimePickerDialog extends StatefulWidget {
  const _SchedulerTimePickerDialog({
    required this.initialTime,
    required this.selectedDateTime,
  });

  final TimeOfDay initialTime;
  final DateTime selectedDateTime;

  @override
  State<_SchedulerTimePickerDialog> createState() =>
      _SchedulerTimePickerDialogState();
}

class _SchedulerTimePickerDialogState
    extends State<_SchedulerTimePickerDialog> {
  late int _selectedHour;
  late int _selectedMinute;
  late bool _isAm;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    final hour24 = widget.initialTime.hour;
    _isAm = hour24 < 12;
    _selectedHour = hour24 % 12 == 0 ? 12 : hour24 % 12;
    _selectedMinute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(
      initialItem: _selectedHour - 1,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  TimeOfDay _buildResult() {
    var hour = _selectedHour % 12;
    if (!_isAm) hour += 12;
    return TimeOfDay(hour: hour, minute: _selectedMinute);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.transparent,
      child: _SchedulerModalCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SchedulerModalHeader(
              title: 'Select Time',
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose the exact time you want your post to be published.',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF556987),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 78,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE7EDF6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: Color(0xFF0A3F85),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Text(
                                  '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF08112F),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isAm ? 'AM' : 'PM',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF0A3F85),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 102,
                  height: 52,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDE6F1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isAm = true),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isAm
                                  ? const Color(0xFF0A3F85)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'AM',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: _isAm
                                    ? Colors.white
                                    : const Color(0xFF556987),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isAm = false),
                          child: Container(
                            decoration: BoxDecoration(
                              color: !_isAm
                                  ? const Color(0xFF0A3F85)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'PM',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: !_isAm
                                    ? Colors.white
                                    : const Color(0xFF556987),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SchedulerWheelField(
                    title: 'HOUR',
                    controller: _hourController,
                    values: List<String>.generate(
                      12,
                      (index) => (index + 1).toString().padLeft(2, '0'),
                    ),
                    onSelected: (index) {
                      setState(() => _selectedHour = index + 1);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 78, 10, 0),
                  child: Text(
                    ':',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF08112F),
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: _SchedulerWheelField(
                    title: 'MINUTE',
                    controller: _minuteController,
                    values: List<String>.generate(
                      60,
                      (index) => index.toString().padLeft(2, '0'),
                    ),
                    onSelected: (index) {
                      setState(() => _selectedMinute = index);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFDDE6F1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF08112F),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_buildResult()),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF0A3F85),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Done',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SchedulerWheelField extends StatelessWidget {
  const _SchedulerWheelField({
    required this.title,
    required this.controller,
    required this.values,
    required this.onSelected,
  });

  final String title;
  final FixedExtentScrollController controller;
  final List<String> values;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF556987),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 214,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFDDE6F1)),
          ),
          child: CupertinoPicker(
            scrollController: controller,
            itemExtent: 40,
            squeeze: 1.1,
            selectionOverlay: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0x664F79C8),
                border: Border.all(color: const Color(0xFFBFD0EA)),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onSelectedItemChanged: onSelected,
            children: values
                .map(
                  (value) => Center(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF08112F),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _SchedulerSectionCard extends StatelessWidget {
  const _SchedulerSectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E0F2746),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SocialAccountsTopBar extends StatelessWidget {
  const _SocialAccountsTopBar({required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SidebarMenuTriggerButton(onTap: onMenuTap, isEmbedded: true),
        const Spacer(),
        const AppLogo(iconSize: 46, centered: true),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 28,
                color: Color(0xFF0E1A3A),
              ),
            ),
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D5A),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '3',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CreativeTypeOption {
  const _CreativeTypeOption({
    required this.title,
    required this.assetPath,
    required this.accent,
    required this.glow,
  });

  final String title;
  final String assetPath;
  final Color accent;
  final Color glow;
}

class _CreativeTypeCard extends StatelessWidget {
  const _CreativeTypeCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _CreativeTypeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, option.glow],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? option.accent : const Color(0xFFE6EDF5),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? option.accent.withValues(alpha: 0.16)
                  : const Color(0x0E0F2746),
              blurRadius: isSelected ? 18 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x140F2746),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(option.assetPath, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    option.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF111827),
                      fontSize: 11.8,
                      height: 1.18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.18,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: option.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: option.accent.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CreativePromptCard extends StatelessWidget {
  const _CreativePromptCard({
    required this.promptController,
    required this.selectedType,
    required this.selectedPlatforms,
    required this.onPlatformTap,
    required this.selectedAspectRatio,
    required this.onAspectRatioSelected,
    required this.selectedImageQuality,
    required this.onImageQualitySelected,
    required this.isGenerating,
    required this.onGenerate,
  });

  final TextEditingController promptController;
  final String selectedType;
  final Set<String> selectedPlatforms;
  final ValueChanged<String> onPlatformTap;
  final String selectedAspectRatio;
  final ValueChanged<String> onAspectRatioSelected;
  final String selectedImageQuality;
  final ValueChanged<String> onImageQualitySelected;
  final bool isGenerating;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2746),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: Color(0xFF5A4CFF),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Create $selectedType',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF111827),
                    fontSize: 16.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: promptController,
            minLines: 4,
            maxLines: 4,
            cursorColor: const Color(0xFF245BEB),
            decoration: InputDecoration(
              hintText: 'Describe the visual you want the AI to generate...',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF94A0BC),
                fontSize: 13.8,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: const Color(0xFFFBFCFE),
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE1E9F2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE1E9F2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF6C4EFF),
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CreativeMiniSection(
                  title: 'Platform Target',
                  child: _CreativePlatformTargets(
                    selectedPlatforms: selectedPlatforms,
                    onPlatformTap: onPlatformTap,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CreativeMiniSection(
                  title: 'Image Size (Aspect Ratio)',
                  child: _CreativeSelectShell(
                    label: selectedAspectRatio,
                    options: const [
                      'Default (1:1 Square)',
                      'Instagram/Facebook Portrait (4:5)',
                      'Instagram Story / Reels (9:16)',
                      'YouTube / Twitter Landscape (16:9)',
                      'Logo / Profile Picture (1:1)',
                    ],
                    onSelected: onAspectRatioSelected,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CreativeMiniSection(
                  title: 'Image Quality',
                  child: _CreativeSelectShell(
                    label: selectedImageQuality,
                    options: const [
                      'Good Quality (Wait 15s)',
                      'Highest Quality (Wait 60s)',
                    ],
                    onSelected: onImageQualitySelected,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: isGenerating ? null : onGenerate,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: isGenerating ? 0.72 : 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2962FF), Color(0xFF8B3DFF)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x262F5FFF),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isGenerating)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      isGenerating
                          ? 'Generating Creative...'
                          : 'Generate Creative',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreativeMiniSection extends StatelessWidget {
  const _CreativeMiniSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF51607F),
            fontSize: 12.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _CreativePlatformTargets extends StatelessWidget {
  const _CreativePlatformTargets({
    required this.selectedPlatforms,
    required this.onPlatformTap,
  });

  final Set<String> selectedPlatforms;
  final ValueChanged<String> onPlatformTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('facebook', 'assets/images/facebook.png'),
      ('instagram', 'assets/images/instagram.png'),
      ('linkedin', 'assets/images/link.png'),
    ];

    return Row(
      children: [
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onPlatformTap(item.$1),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: selectedPlatforms.contains(item.$1)
                      ? const Color(0xFFF7F5FF)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selectedPlatforms.contains(item.$1)
                        ? const Color(0xFF7B44FF)
                        : const Color(0xFFE1E9F2),
                  ),
                ),
                padding: const EdgeInsets.all(10),
                child: Image.asset(item.$2, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onPlatformTap('all'),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: selectedPlatforms.contains('all')
                    ? const Color(0xFFF7F5FF)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selectedPlatforms.contains('all')
                      ? const Color(0xFF7B44FF)
                      : const Color(0xFFE1E9F2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.public_rounded,
                    size: 18,
                    color: selectedPlatforms.contains('all')
                        ? const Color(0xFF6C4EFF)
                        : const Color(0xFF1F3368),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'All',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: selectedPlatforms.contains('all')
                          ? const Color(0xFF6C4EFF)
                          : const Color(0xFF1F3368),
                      fontSize: 13.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CreativeSelectShell extends StatelessWidget {
  const _CreativeSelectShell({
    required this.label,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 10,
      shadowColor: const Color(0x220F2746),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFDDE7F2)),
      ),
      itemBuilder: (context) => options
          .map(
            (option) => PopupMenuItem<String>(
              value: option,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: option == label
                            ? const Color(0xFF4E46F8)
                            : const Color(0xFF1B2745),
                        fontSize: 13.0,
                        fontWeight: option == label
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (option == label)
                    const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Color(0xFF4E46F8),
                    ),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE1E9F2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF111827),
                  fontSize: 13.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF1F3368),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreativeSettingsCard extends StatelessWidget {
  const _CreativeSettingsCard({
    required this.selectedStyle,
    required this.onStyleSelected,
    required this.selectedImageType,
    required this.onImageTypeSelected,
    required this.selectedBusinessType,
    required this.onBusinessTypeSelected,
    required this.selectedCreativeGoal,
    required this.onCreativeGoalSelected,
    required this.selectedThemeColor,
    required this.onThemeSelected,
  });

  final String selectedStyle;
  final ValueChanged<String> onStyleSelected;
  final String selectedImageType;
  final ValueChanged<String> onImageTypeSelected;
  final String selectedBusinessType;
  final ValueChanged<String> onBusinessTypeSelected;
  final String selectedCreativeGoal;
  final ValueChanged<String> onCreativeGoalSelected;
  final Color selectedThemeColor;
  final ValueChanged<Color> onThemeSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2746),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: Color(0xFF4B63FF)),
              SizedBox(width: 8),
              Text(
                'AI Settings',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF111827),
                  fontSize: 16.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _CreateAdvancedField(
                  label: 'Style',
                  value: selectedStyle,
                  options: const [
                    'Modern & Clean',
                    'Bold & Bright',
                    'Luxury',
                    'Minimal',
                  ],
                  onSelected: onStyleSelected,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CreateAdvancedField(
                  label: 'Image Type',
                  value: selectedImageType,
                  options: const [
                    'Realistic Photo',
                    'Studio Product',
                    'Lifestyle Shot',
                    'Illustrated',
                  ],
                  onSelected: onImageTypeSelected,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CreateAdvancedField(
                  label: 'Business Type',
                  value: selectedBusinessType,
                  options: const [
                    'Local Business',
                    'E-commerce Brand',
                    'Agency',
                    'Personal Brand',
                  ],
                  onSelected: onBusinessTypeSelected,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CreateAdvancedField(
                  label: 'Creative Goal',
                  value: selectedCreativeGoal,
                  options: const [
                    'Boost Engagement',
                    'Generate Leads',
                    'Drive Sales',
                    'Build Awareness',
                  ],
                  onSelected: onCreativeGoalSelected,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Color Theme',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF51607F),
              fontSize: 12.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ThemeDot(
                color: const Color(0xFF3B82F6),
                selected:
                    selectedThemeColor.toARGB32() ==
                    const Color(0xFF3B82F6).toARGB32(),
                onTap: () => onThemeSelected(const Color(0xFF3B82F6)),
              ),
              const SizedBox(width: 12),
              _ThemeDot(
                color: const Color(0xFF10B981),
                selected:
                    selectedThemeColor.toARGB32() ==
                    const Color(0xFF10B981).toARGB32(),
                onTap: () => onThemeSelected(const Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),
              _ThemeDot(
                color: const Color(0xFF06B6D4),
                selected:
                    selectedThemeColor.toARGB32() ==
                    const Color(0xFF06B6D4).toARGB32(),
                onTap: () => onThemeSelected(const Color(0xFF06B6D4)),
              ),
              const SizedBox(width: 12),
              _ThemeDot(
                color: const Color(0xFF7B44FF),
                selected:
                    selectedThemeColor.toARGB32() ==
                    const Color(0xFF7B44FF).toARGB32(),
                onTap: () => onThemeSelected(const Color(0xFF7B44FF)),
              ),
              const SizedBox(width: 12),
              _ThemeDot(
                color: const Color(0xFFF43F5E),
                selected:
                    selectedThemeColor.toARGB32() ==
                    const Color(0xFFF43F5E).toARGB32(),
                onTap: () => onThemeSelected(const Color(0xFFF43F5E)),
              ),
              const SizedBox(width: 12),
              _ThemeDot(
                color: const Color(0xFFF59E0B),
                selected:
                    selectedThemeColor.toARGB32() ==
                    const Color(0xFFF59E0B).toARGB32(),
                onTap: () => onThemeSelected(const Color(0xFFF59E0B)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeDot extends StatelessWidget {
  const _ThemeDot({
    required this.color,
    required this.onTap,
    this.selected = false,
  });

  final Color color;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: selected ? 30 : 24,
        height: selected ? 30 : 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : color,
            width: selected ? 4 : 1,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: color.withValues(alpha: 0.24),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: selected
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}

// Kept with its original hot-reload shape so running sessions do not reject
// reloads after the dynamic gallery migration.
class _CreativeGalleryItem {
  const _CreativeGalleryItem({
    required this.image,
    required this.title,
    required this.type,
    required this.category,
  });

  final String image;
  final String title;
  final String type;
  final String category;
}

class _DynamicCreativeGalleryItem {
  _DynamicCreativeGalleryItem({
    required this.id,
    required this.image,
    required this.title,
    required this.type,
    required this.category,
    this.prompt,
    this.createdAt,
  });

  final String id;
  final String image;
  final String title;
  final String type;
  final String category;
  final String? prompt;
  final DateTime? createdAt;
}

class _CreativeGallerySection extends StatelessWidget {
  const _CreativeGallerySection({
    required this.filters,
    required this.selectedFilterIndex,
    required this.creatives,
    required this.isLoading,
    required this.errorMessage,
    required this.onFilterSelected,
    required this.onRetry,
    required this.onViewItem,
    required this.onDownloadItem,
    required this.onDeleteItem,
  });

  final List<String> filters;
  final int selectedFilterIndex;
  final List<SocialCreative> creatives;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<int> onFilterSelected;
  final VoidCallback onRetry;
  final ValueChanged<_DynamicCreativeGalleryItem> onViewItem;
  final ValueChanged<_DynamicCreativeGalleryItem> onDownloadItem;
  final ValueChanged<_DynamicCreativeGalleryItem> onDeleteItem;

  String _typeLabel(String value) {
    switch (value) {
      case 'ai_image':
        return 'AI Image';
      case 'offer_banner':
        return 'Offer Banner';
      case 'festival_post':
        return 'Festival Post';
      case 'review_card':
        return 'Review Card';
      case 'quote_post':
        return 'Quote Post';
      case 'product_showcase':
        return 'Product Showcase';
      default:
        return value
            .split('_')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
    }
  }

  String _categoryForType(String value) {
    switch (value) {
      case 'ai_image':
        return 'Images';
      case 'offer_banner':
      case 'product_showcase':
        return 'Banners';
      case 'festival_post':
        return 'Festival';
      case 'review_card':
        return 'Review Cards';
      case 'quote_post':
        return 'Quotes';
      default:
        return 'Images';
    }
  }

  String _titleForCreative(SocialCreative creative) {
    final prompt = creative.promptUsed?.trim();
    if (prompt != null && prompt.isNotEmpty) {
      return prompt.length > 42 ? '${prompt.substring(0, 42)}...' : prompt;
    }
    return _typeLabel(creative.creativeType);
  }

  List<_DynamicCreativeGalleryItem> _itemsForFilter() {
    final selectedFilter = filters[selectedFilterIndex];
    return creatives
        .where((creative) => creative.imageUrl.trim().isNotEmpty)
        .map(
          (creative) => _DynamicCreativeGalleryItem(
            id: creative.id,
            image: creative.imageUrl,
            title: _titleForCreative(creative),
            type: _typeLabel(creative.creativeType),
            category: _categoryForType(creative.creativeType),
            prompt: creative.promptUsed,
            createdAt: creative.createdAt,
          ),
        )
        .where(
          (item) => selectedFilter == 'All' || item.category == selectedFilter,
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsForFilter();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2746),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 18,
                color: Color(0xFF4B63FF),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your Gallery',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF111827),
                    fontSize: 16.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'View all',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF5A4CFF),
                  fontSize: 13.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == selectedFilterIndex;
                return GestureDetector(
                  onTap: () => onFilterSelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF5A4CFF) : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF5A4CFF)
                            : const Color(0xFFE2E8F2),
                      ),
                    ),
                    child: Text(
                      filters[index],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: selected
                            ? Colors.white
                            : const Color(0xFF4E5879),
                        fontSize: 12.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          if (isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFD),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5ECF5)),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF5A4CFF)),
              ),
            )
          else if (errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFD7DD)),
              ),
              child: Column(
                children: [
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFFB42335),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFD),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5ECF5)),
              ),
              child: const Text(
                'No creatives in this category yet. Generate one above and it will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF7A87A4),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 14,
                childAspectRatio: 0.68,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return _CreativeGalleryCard(
                  item: item,
                  onView: () => onViewItem(item),
                  onDownload: () => onDownloadItem(item),
                  onDelete: () => onDeleteItem(item),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CreativeGalleryCard extends StatelessWidget {
  const _CreativeGalleryCard({
    required this.item,
    required this.onView,
    required this.onDownload,
    required this.onDelete,
  });

  final _DynamicCreativeGalleryItem item;
  final VoidCallback onView;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5ECF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F2746),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: onView,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: _CreativeImage(image: item.image, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF0F172A),
                    fontSize: 12.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _CreativeGalleryActionButton(
                      icon: Icons.remove_red_eye_outlined,
                      color: const Color(0xFF667392),
                      onTap: onView,
                    ),
                    const Spacer(),
                    _CreativeGalleryActionButton(
                      icon: Icons.download_rounded,
                      color: const Color(0xFF2563EB),
                      onTap: onDownload,
                    ),
                    const SizedBox(width: 8),
                    _CreativeGalleryActionButton(
                      icon: Icons.delete_outline_rounded,
                      color: const Color(0xFFFF5A66),
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreativeImage extends StatelessWidget {
  const _CreativeImage({required this.image, required this.fit});

  final String image;
  final BoxFit fit;

  bool get _isNetworkImage =>
      image.startsWith('http://') || image.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isNetworkImage) {
      return Image.network(
        image,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFFF6F8FC),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF5A4CFF),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const _CreativeImageFallback();
        },
      );
    }

    return Image.asset(
      image,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return const _CreativeImageFallback();
      },
    );
  }
}

class _CreativeImageFallback extends StatelessWidget {
  const _CreativeImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F8FC),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Color(0xFF94A0B8),
        size: 30,
      ),
    );
  }
}

class _CreativeGalleryActionButton extends StatelessWidget {
  const _CreativeGalleryActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 27,
        height: 27,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16.5, color: color),
      ),
    );
  }
}

class _SocialCreateTopBar extends StatelessWidget {
  const _SocialCreateTopBar({required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SidebarMenuTriggerButton(onTap: onMenuTap, isEmbedded: true),
        const Spacer(),
        const AppLogo(iconSize: 46, centered: true),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 28,
                color: Color(0xFF0E1A3A),
              ),
            ),
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D5A),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '12',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialCreateStepper extends StatelessWidget {
  const _SocialCreateStepper();

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('1', 'Enter Topic', true),
      ('2', 'Select Type', false),
      ('3', 'Generate', false),
      ('4', 'Review', false),
    ];

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(steps.length * 2 - 1, (index) {
            if (index.isOdd) {
              return const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Divider(
                    color: Color(0xFFDCE5F1),
                    thickness: 1.2,
                    height: 1.2,
                  ),
                ),
              );
            }

            final step = steps[index ~/ 2];
            return Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: step.$3 ? const Color(0xFF184A96) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: step.$3
                      ? const Color(0xFF184A96)
                      : const Color(0xFFDCE5F1),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                step.$1,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: step.$3 ? Colors.white : const Color(0xFF3A4767),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(steps.length, (index) {
            final step = steps[index];
            double dx = 0;
            if (index == 0) dx = -6;
            if (index == 2) dx = 4;
            if (index == 3) dx = 6;

            return Expanded(
              child: Transform.translate(
                offset: Offset(dx, 0),
                child: Text(
                  step.$2,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: step.$3
                        ? const Color(0xFF184A96)
                        : const Color(0xFF5D6988),
                    fontSize: 11.2,
                    height: 1.0,
                    fontWeight: step.$3 ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _CreateSelectField extends StatelessWidget {
  const _CreateSelectField({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    this.optionLabels = const {},
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final Map<String, String> optionLabels;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 12,
      shadowColor: const Color(0x220F2746),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFDDE7F2)),
      ),
      itemBuilder: (context) => options
          .map(
            (option) => PopupMenuItem<String>(
              value: option,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      optionLabels[option] ?? option,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: option == value
                            ? const Color(0xFF4E46F8)
                            : const Color(0xFF1B2745),
                        fontSize: 13.1,
                        fontWeight: option == value
                            ? FontWeight.w600
                            : FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                  if (option == value)
                    const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Color(0xFF4E46F8),
                    ),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDE7F2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF7080A3),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF111827),
                      fontSize: 13.4,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: Color(0xFF1F3368),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateToggleRow extends StatelessWidget {
  const _CreateToggleRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF1B2745),
              fontSize: 14.2,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
          ),
        ),
        SizedBox(
          width: 50,
          height: 28,
          child: FittedBox(
            fit: BoxFit.contain,
            child: CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: const Color(0xFF5A52FF),
              inactiveTrackColor: const Color(0xFFD8DDEE),
              thumbColor: Colors.white,
              trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
                (_) => Colors.transparent,
              ),
              trackOutlineWidth: WidgetStateProperty.resolveWith<double?>(
                (_) => 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateAdvancedOptionsCard extends StatelessWidget {
  const _CreateAdvancedOptionsCard({
    required this.isExpanded,
    required this.selectedStyle,
    required this.selectedImageType,
    required this.selectedBusinessType,
    required this.selectedCreativeGoal,
    required this.selectedThemeColor,
    required this.onToggle,
    required this.onStyleSelected,
    required this.onImageTypeSelected,
    required this.onBusinessTypeSelected,
    required this.onCreativeGoalSelected,
    required this.onThemeSelected,
    required this.onCustomThemeTap,
  });

  final bool isExpanded;
  final String selectedStyle;
  final String selectedImageType;
  final String selectedBusinessType;
  final String selectedCreativeGoal;
  final Color selectedThemeColor;
  final VoidCallback onToggle;
  final ValueChanged<String> onStyleSelected;
  final ValueChanged<String> onImageTypeSelected;
  final ValueChanged<String> onBusinessTypeSelected;
  final ValueChanged<String> onCreativeGoalSelected;
  final ValueChanged<Color> onThemeSelected;
  final VoidCallback onCustomThemeTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2746),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_motion_rounded,
                  size: 22,
                  color: Color(0xFF5A52FF),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Advanced Options',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF111827),
                          fontSize: 14.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$selectedStyle  ·  $selectedImageType  ·  $selectedBusinessType  ·  $selectedCreativeGoal',
                        maxLines: isExpanded ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF5F6987),
                          fontSize: 11.9,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.chevron_right_rounded,
                  size: 22,
                  color: const Color(0xFF1F3368),
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE8EEF5)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CreateAdvancedField(
                    label: 'Style',
                    value: selectedStyle,
                    options: const [
                      'Modern & Clean',
                      'Luxury & Premium',
                      'Minimal & Soft',
                      'Bold & Energetic',
                    ],
                    onSelected: onStyleSelected,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CreateAdvancedField(
                    label: 'Image Type',
                    value: selectedImageType,
                    options: const [
                      'Realistic Photo',
                      'Studio Product',
                      'Lifestyle Shot',
                      'Illustrated',
                    ],
                    onSelected: onImageTypeSelected,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _CreateAdvancedField(
                    label: 'Business Type',
                    value: selectedBusinessType,
                    options: const [
                      'Local Business',
                      'E-commerce Brand',
                      'Agency',
                      'Personal Brand',
                    ],
                    onSelected: onBusinessTypeSelected,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CreateAdvancedField(
                    label: 'Creative Goal',
                    value: selectedCreativeGoal,
                    options: const [
                      'Boost Engagement',
                      'Generate Leads',
                      'Drive Sales',
                      'Build Awareness',
                    ],
                    onSelected: onCreativeGoalSelected,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Color Theme',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF637292),
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        [
                            const Color(0xFF5A52FF),
                            const Color(0xFF15B8A6),
                            const Color(0xFFF59E0B),
                            const Color(0xFFEF4444),
                            const Color(0xFF8B5CF6),
                          ].map((color) {
                            final selected =
                                color.toARGB32() ==
                                selectedThemeColor.toARGB32();
                            return GestureDetector(
                              onTap: () => onThemeSelected(color),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: selected ? 34 : 30,
                                height: selected ? 34 : 30,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFFEEF2FF)
                                        : Colors.white,
                                    width: selected ? 3 : 1.4,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x180F2746),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList()
                          ..add(
                            GestureDetector(
                              onTap: onCustomThemeTap,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFD6DDF0),
                                    width: 1.4,
                                  ),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF5A52FF),
                                      Color(0xFF22D3C7),
                                      Color(0xFFF59E0B),
                                      Color(0xFFEF4444),
                                    ],
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x120F2746),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreateAdvancedField extends StatelessWidget {
  const _CreateAdvancedField({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF637292),
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        PopupMenuButton<String>(
          onSelected: onSelected,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 10,
          shadowColor: const Color(0x220F2746),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFDDE7F2)),
          ),
          itemBuilder: (context) => options
              .map(
                (option) => PopupMenuItem<String>(
                  value: option,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: option == value
                                ? const Color(0xFF4E46F8)
                                : const Color(0xFF1B2745),
                            fontSize: 13.0,
                            fontWeight: option == value
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (option == value)
                        const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Color(0xFF4E46F8),
                        ),
                    ],
                  ),
                ),
              )
              .toList(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDE7F2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF111827),
                      fontSize: 13.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: Color(0xFF1F3368),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateAssistantCard extends StatelessWidget {
  const _CreateAssistantCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2746),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.auto_awesome_rounded,
                size: 22,
                color: Color(0xFF5A52FF),
              ),
              SizedBox(width: 10),
              Text(
                'AI Assistant',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF5A52FF),
                  fontSize: 14.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CreateAssistantIcon(
                icon: Icons.schedule_rounded,
                color: Color(0xFF22C55E),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Best time to post',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF1F3368),
                        fontSize: 12.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Today 5:00 PM - 7:00 PM',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF5A52FF),
                        fontSize: 13.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CreateAssistantIcon(
                icon: Icons.show_chart_rounded,
                color: Color(0xFF22C55E),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Engagement prediction',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF1F3368),
                        fontSize: 12.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'High',
                            style: TextStyle(
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: ' (82% chance)',
                            style: TextStyle(
                              color: Color(0xFF5F6987),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13.8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateAssistantIcon extends StatelessWidget {
  const _CreateAssistantIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EBF4)),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _SocialAccountsHero extends StatelessWidget {
  const _SocialAccountsHero({
    required this.onConnectTap,
    required this.isConnecting,
  });

  final VoidCallback onConnectTap;
  final bool isConnecting;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Social Accounts',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF111827),
                  fontSize: 18.5,
                  height: 1.12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.25,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Connect and manage your\nsocial media accounts.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF6C7692),
                  fontSize: 13.2,
                  height: 1.34,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: isConnecting ? null : onConnectTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_socialBrandButtonStart, _socialBrandButtonEnd],
              ),
              borderRadius: BorderRadius.circular(17),
              boxShadow: const [
                BoxShadow(
                  color: _socialBrandButtonShadow,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isConnecting)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  isConnecting ? 'Opening...' : 'Connect Account',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialAccountStatsGrid extends StatelessWidget {
  const _SocialAccountStatsGrid({
    required this.connectedCount,
    required this.healthyCount,
    required this.expiringSoonCount,
    required this.disconnectedCount,
  });

  final int connectedCount;
  final int healthyCount;
  final int expiringSoonCount;
  final int disconnectedCount;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.groups_rounded,
        iconColor: const Color(0xFF19B970),
        tint: const Color(0xFFEAFBF4),
        title: 'Connected',
        value: '$connectedCount',
        footer: 'Accounts',
      ),
      (
        icon: Icons.verified_user_outlined,
        iconColor: const Color(0xFF22B46B),
        tint: const Color(0xFFEFFFF5),
        title: 'Healthy',
        value: '$healthyCount',
        footer: connectedCount == 0
            ? 'No active accounts'
            : '${((healthyCount / connectedCount) * 100).round()}% Active',
      ),
      (
        icon: Icons.access_time_rounded,
        iconColor: const Color(0xFFF3B51A),
        tint: const Color(0xFFFFF8E7),
        title: 'Expiring Soon',
        value: '$expiringSoonCount',
        footer: 'Accounts',
      ),
      (
        icon: Icons.link_off_rounded,
        iconColor: const Color(0xFFFF6A6A),
        tint: const Color(0xFFFFF0F0),
        title: 'Disconnected',
        value: '$disconnectedCount',
        footer: 'Accounts',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.42,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.fromLTRB(13, 9, 13, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEBF0F6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x100F2746),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFF184A96),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: item.tint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.iconColor, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF111827),
                        fontSize: 12.6,
                        height: 1.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.value,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF111827),
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.footer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF4E5879),
                  fontSize: 11.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SocialConnectedAccountsSection extends StatelessWidget {
  const _SocialConnectedAccountsSection({
    required this.accounts,
    required this.onReconnect,
    required this.onDisconnect,
  });

  final List<SocialAccount> accounts;
  final ValueChanged<SocialAccount> onReconnect;
  final ValueChanged<SocialAccount> onDisconnect;

  @override
  Widget build(BuildContext context) {
    return _SocialCardSection(
      title: 'Connected Accounts',
      actionLabel: 'View all',
      child: accounts.isEmpty
          ? const _SocialAccountsEmptyState()
          : Column(
              children: accounts
                  .map(
                    (account) => Padding(
                      padding: EdgeInsets.only(
                        bottom: account == accounts.last ? 0 : 12,
                      ),
                      child: _ConnectedSocialAccountTile(
                        logoPath: _platformLogoPath(account.platform),
                        title: _platformTitle(account.platform),
                        subtitle: _accountHandle(account),
                        tag: _platformTag(account.platform),
                        status: account.isActive ? 'Connected' : 'Inactive',
                        statusColor: account.isActive
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFFF6A6A),
                        syncText: _lastSyncLabel(account),
                        onReconnect: () => onReconnect(account),
                        onDisconnect: () => onDisconnect(account),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _SocialAvailablePlatformsSection extends StatelessWidget {
  const _SocialAvailablePlatformsSection({
    required this.availablePlatforms,
    required this.onConnect,
    required this.isConnecting,
    required this.connectingPlatform,
  });

  final List<String> availablePlatforms;
  final ValueChanged<String> onConnect;
  final bool isConnecting;
  final String? connectingPlatform;

  @override
  Widget build(BuildContext context) {
    return _SocialCardSection(
      title: 'Available Platforms',
      child: availablePlatforms.isEmpty
          ? const _SocialAvailablePlatformsEmptyState()
          : Column(
              children: availablePlatforms
                  .map(
                    (platform) => Padding(
                      padding: EdgeInsets.only(
                        bottom: platform == availablePlatforms.last ? 0 : 12,
                      ),
                      child: _AvailablePlatformTile(
                        logoPath: _platformLogoPath(platform),
                        title: _platformConnectTitle(platform),
                        subtitle: _platformDescription(platform),
                        isLoading:
                            isConnecting && connectingPlatform == platform,
                        onConnect: () => onConnect(platform),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _SocialAccountSecurityCard extends StatelessWidget {
  const _SocialAccountSecurityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAE6FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F2746),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF7C63FF),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your accounts are secure',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF111827),
                    fontSize: 15.0,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'We use industry-standard encryption to keep your account connections safe and secure.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF6A7592),
                    fontSize: 12.6,
                    height: 1.28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Learn more',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF5C4CFF),
                  fontSize: 13.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF5C4CFF),
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlatformGrowthStrategiesSection extends StatelessWidget {
  const _PlatformGrowthStrategiesSection();

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        logo: 'assets/images/instagram.png',
        title: 'Instagram Visuals',
        subtitle: 'High-quality visuals drive engagement.',
        tag: 'BRAND AESTHETIC',
        accent: const Color(0xFFE43B7A),
        tagBg: const Color(0xFFFFEFF5),
      ),
      (
        logo: 'assets/images/link.png',
        title: 'LinkedIn B2B',
        subtitle: 'The #1 platform for B2B lead generation.',
        tag: 'THOUGHT LEADERSHIP',
        accent: const Color(0xFF2E6BFF),
        tagBg: const Color(0xFFEEF3FF),
      ),
      (
        logo: 'assets/images/facebook.png',
        title: 'Facebook Local',
        subtitle: 'Essential for local community engagement.',
        tag: 'LOCAL REACH',
        accent: const Color(0xFF2E6BFF),
        tagBg: const Color(0xFFEEF3FF),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F2746),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: Color(0xFFF3B51A),
              ),
              SizedBox(width: 8),
              Text(
                'Platform Growth Strategies',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF111827),
                  fontSize: 17.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _PlatformStrategyTile(
                  logoPath: items[i].logo,
                  title: items[i].title,
                  subtitle: items[i].subtitle,
                  tag: items[i].tag,
                  accentColor: items[i].accent,
                  tagBackground: items[i].tagBg,
                ),
                if (i != items.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialCardSection extends StatelessWidget {
  const _SocialCardSection({
    required this.title,
    required this.child,
    this.actionLabel,
  });

  final String title;
  final Widget child;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F2746),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (actionLabel != null)
                Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF5B63FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PlatformStrategyTile extends StatelessWidget {
  const _PlatformStrategyTile({
    required this.logoPath,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.accentColor,
    required this.tagBackground,
  });

  final String logoPath;
  final String title;
  final String subtitle;
  final String tag;
  final Color accentColor;
  final Color tagBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F2746),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  logoPath,
                  width: 58,
                  height: 58,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF0F1737),
                          fontSize: 16.5,
                          height: 1.16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF66718D),
                          fontSize: 13.6,
                          height: 1.34,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: tagBackground,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tag,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: accentColor,
                            fontSize: 11.5,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 34,
                  color: Color(0xFF6C7692),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedSocialAccountTile extends StatelessWidget {
  const _ConnectedSocialAccountTile({
    required this.logoPath,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.status,
    required this.statusColor,
    required this.syncText,
    required this.onReconnect,
    required this.onDisconnect,
  });

  final String logoPath;
  final String title;
  final String subtitle;
  final String tag;
  final String status;
  final Color statusColor;
  final String syncText;
  final VoidCallback onReconnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              logoPath,
              width: 52,
              height: 52,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF111827),
                    fontSize: 15.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF4C5676),
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tag,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF5D63FF),
                      fontSize: 11.7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 90, maxWidth: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: statusColor,
                            fontSize: 13.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    syncText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF6F7894),
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reconnect') {
                onReconnect();
              }
              if (value == 'disconnect') {
                onDisconnect();
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'reconnect',
                height: 38,
                child: Row(
                  children: [
                    Icon(
                      Icons.sync_rounded,
                      size: 18,
                      color: Color(0xFF1267F1),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Reconnect',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 4),
              const PopupMenuItem<String>(
                value: 'disconnect',
                height: 38,
                child: Row(
                  children: [
                    Icon(
                      Icons.link_off_rounded,
                      size: 18,
                      color: Color(0xFFE94363),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Disconnect',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE94363),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: const Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: Color(0xFF6B728A),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailablePlatformTile extends StatelessWidget {
  const _AvailablePlatformTile({
    required this.logoPath,
    required this.title,
    required this.subtitle,
    required this.onConnect,
    this.isLoading = false,
  });

  final String logoPath;
  final String title;
  final String subtitle;
  final VoidCallback onConnect;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              logoPath,
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF111827),
                    fontSize: 15.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF5F6987),
                    fontSize: 13.1,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isLoading ? null : onConnect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFD8D6FF)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF5A4CFF),
                        ),
                      ),
                    )
                  : const Text(
                      'Connect',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF5A4CFF),
                        fontSize: 14.0,
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

class _SocialAccountsErrorBanner extends StatelessWidget {
  const _SocialAccountsErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF6D0D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF7F1D1D),
                fontSize: 12.8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SocialAccountsEmptyState extends StatelessWidget {
  const _SocialAccountsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'No social accounts are connected yet. Connect a platform below to get started.',
        style: TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF6C7692),
          fontSize: 13.2,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SocialAvailablePlatformsEmptyState extends StatelessWidget {
  const _SocialAvailablePlatformsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'All currently supported social platforms are already connected for this workspace.',
        style: TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF6C7692),
          fontSize: 13.2,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

String _platformLogoPath(String platform) {
  switch (platform.trim().toUpperCase()) {
    case 'INSTAGRAM':
      return 'assets/images/instagram.png';
    case 'LINKEDIN':
      return 'assets/images/link.png';
    case 'FACEBOOK':
    default:
      return 'assets/images/facebook.png';
  }
}

String _platformTitle(String platform) {
  switch (platform.trim().toUpperCase()) {
    case 'INSTAGRAM':
      return 'Instagram';
    case 'LINKEDIN':
      return 'LinkedIn';
    case 'FACEBOOK':
    default:
      return 'Facebook';
  }
}

String _platformConnectTitle(String platform) {
  switch (platform.trim().toUpperCase()) {
    case 'LINKEDIN':
      return 'LinkedIn';
    case 'FACEBOOK':
      return 'Facebook Page';
    case 'INSTAGRAM':
    default:
      return 'Instagram';
  }
}

String _platformTag(String platform) {
  switch (platform.trim().toUpperCase()) {
    case 'INSTAGRAM':
      return 'Business Account';
    case 'LINKEDIN':
      return 'Company Page';
    case 'FACEBOOK':
    default:
      return 'Page';
  }
}

String _platformDescription(String platform) {
  switch (platform.trim().toUpperCase()) {
    case 'INSTAGRAM':
      return 'Connect your Instagram Business account to publish posts and manage engagement.';
    case 'LINKEDIN':
      return 'Connect your LinkedIn Company Page to share professional content.';
    case 'FACEBOOK':
    default:
      return 'Connect your Facebook Page to share updates and engage with your audience.';
  }
}

String _accountHandle(SocialAccount account) {
  final name = account.platformAccountName.trim();
  if (account.platform == 'INSTAGRAM' && !name.startsWith('@')) {
    return '@$name';
  }
  return name;
}

String _lastSyncLabel(SocialAccount account) {
  final reference = account.updatedAt ?? account.createdAt;
  if (reference == null) {
    return 'Last sync: recently';
  }

  final difference = DateTime.now().difference(reference.toLocal());
  if (difference.inMinutes < 1) {
    return 'Last sync: just now';
  }
  if (difference.inHours < 1) {
    return 'Last sync: ${difference.inMinutes}m ago';
  }
  if (difference.inDays < 1) {
    return 'Last sync: ${difference.inHours}h ago';
  }
  return 'Last sync: ${difference.inDays}d ago';
}

Widget _platformAvatar(String logoPath) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.asset(logoPath, width: 42, height: 42, fit: BoxFit.contain),
  );
}

class _SocialWorkspacePlaceholderView extends StatelessWidget {
  const _SocialWorkspacePlaceholderView({
    required this.currentTab,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bullets,
  });

  final AuthTab currentTab;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final productModeController = Get.isRegistered<ProductModeController>()
        ? Get.find<ProductModeController>()
        : Get.put(ProductModeController(), permanent: true);
    if (!productModeController.isSocialMedia) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        productModeController.selectMode(ProductMode.socialMedia);
      });
    }

    return AuthNavigationShell(
      currentTab: currentTab,
      backgroundColor: const Color(0xFFF5F8FC),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            const Center(child: AppLogo(iconSize: 44)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5ECF5)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x120F2746),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: AppColors.brandBlue, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF111827),
                      fontSize: 24,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.brandBlue.withValues(alpha: 0.72),
                      fontSize: 14.5,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...bullets.map(
                    (bullet) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C7BC),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              bullet,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF1F3368),
                                fontSize: 14.1,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => Get.offNamed(AppRoutes.socialDashboard),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      side: const BorderSide(color: Color(0xFFCFDBEA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Back to Social Dashboard',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF0A3F85),
                        fontSize: 14.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
