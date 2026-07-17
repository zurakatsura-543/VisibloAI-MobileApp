import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../widgets/auth_navigation_shell.dart';
import '../models/gbp_post.dart';
import 'gbp_post_create_flow_view.dart';

enum _OfferType { discount, festival, newLaunch }

extension _OfferTypeX on _OfferType {
  String get label {
    return switch (this) {
      _OfferType.discount => 'Discount',
      _OfferType.festival => 'Festival',
      _OfferType.newLaunch => 'New Launch',
    };
  }

  String get defaultTitle {
    return switch (this) {
      _OfferType.discount => 'Get 10% off on your first visit',
      _OfferType.festival => 'Festive offer for new walk-ins',
      _OfferType.newLaunch => 'Launch week bonus for early customers',
    };
  }

  String get defaultDescription {
    return switch (this) {
      _OfferType.discount =>
        'Limited-time offer for new customers. Show this offer while visiting to unlock your first-visit discount.',
      _OfferType.festival =>
        'Celebrate the season with a festive package, priority slots, and limited-time savings for new bookings.',
      _OfferType.newLaunch =>
        'Be among the first customers to try our newest service package and unlock an early-access bonus.',
    };
  }

  List<String> get suggestions {
    return switch (this) {
      _OfferType.discount => const ['Monsoon Repair', 'Free Consultation'],
      _OfferType.festival => const ['Festive Package', 'Weekend Bonus'],
      _OfferType.newLaunch => const ['Launch Week Bonus', 'VIP Preview'],
    };
  }

  Color get recentIconColor {
    return switch (this) {
      _OfferType.discount => const Color(0xFF34B9C1),
      _OfferType.festival => const Color(0xFFF2A13C),
      _OfferType.newLaunch => const Color(0xFF4A8BD8),
    };
  }

  Color get recentIconBackground {
    return switch (this) {
      _OfferType.discount => const Color(0xFFEAFBFD),
      _OfferType.festival => const Color(0xFFFFF6EA),
      _OfferType.newLaunch => const Color(0xFFEEF4FF),
    };
  }
}

class _OfferRecord {
  const _OfferRecord({
    required this.type,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.views,
    required this.clicks,
  });

  final _OfferType type;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final int views;
  final int clicks;

  bool get isScheduled =>
      _dateOnly(startDate).isAfter(_dateOnly(DateTime.now()));
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String _formatOfferDate(DateTime value) {
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
  return '${months[value.month - 1]} ${value.day}';
}

int _offerDurationDays(DateTime start, DateTime end) {
  final safeEnd = end.isBefore(start) ? start : end;
  return safeEnd.difference(start).inDays + 1;
}

String _offerStatusLabel(_OfferRecord offer) {
  return offer.isScheduled ? 'Scheduled' : 'Live';
}

Color _offerStatusColor(_OfferRecord offer) {
  return offer.isScheduled ? const Color(0xFFF2A13C) : const Color(0xFF43C79B);
}

String _offerSubtitle(_OfferRecord offer) {
  if (offer.isScheduled) {
    return 'Starts ${_formatOfferDate(offer.startDate)} · Ends ${_formatOfferDate(offer.endDate)}';
  }
  return 'Live · ${offer.views} views · ${offer.clicks} clicks';
}

int _estimateOfferViews(String title) {
  return 24 + (title.trim().length * 2);
}

int _estimateOfferClicks(String description) {
  final words = description
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .length;
  return 4 + (words ~/ 2);
}

class GbpOffersView extends StatelessWidget {
  const GbpOffersView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthNavigationShell(
      currentTab: AuthTab.home,
      backgroundColor: const Color(0xFFF6F8FC),
      child: _GbpOffersContent(controller: Get.find<OnboardingController>()),
    );
  }
}

class _GbpOffersContent extends StatefulWidget {
  const _GbpOffersContent({required this.controller});

  final OnboardingController controller;

  @override
  State<_GbpOffersContent> createState() => _GbpOffersContentState();
}

class _GbpOffersContentState extends State<_GbpOffersContent> {
  _OfferType _selectedType = _OfferType.discount;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _startDate;
  late DateTime _endDate;
  late final List<_OfferRecord> _offers;
  bool _draftPublished = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _selectedType.defaultTitle);
    _descriptionController = TextEditingController(
      text: _selectedType.defaultDescription,
    );
    _startDate = _dateOnly(DateTime.now());
    _endDate = _startDate.add(const Duration(days: 29));
    _offers = _buildSeedOffers();
    _titleController.addListener(_handleDraftChanged);
    _descriptionController.addListener(_handleDraftChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_handleDraftChanged);
    _descriptionController.removeListener(_handleDraftChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showOfferSnack(String title, String message) {
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
  }

  void _handleDraftChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _draftPublished = false;
    });
  }

  List<_OfferRecord> _buildSeedOffers() {
    final today = _dateOnly(DateTime.now());
    final nextMonday = _nextWeekday(today, DateTime.monday);
    
    final offers = <_OfferRecord>[];
    
    // Add real offers from backend
    final realOffers = widget.controller.liveGbpPosts.where((p) => p.meta == 'OFFER');
    for (final offer in realOffers) {
      offers.add(_OfferRecord(
        type: _OfferType.discount, // Map dynamically if there is a way, defaulting to discount
        title: offer.title.isNotEmpty ? offer.title : 'Live Offer',
        description: offer.subtitle.isNotEmpty ? offer.subtitle : 'Offer Details',
        startDate: offer.createdAt,
        endDate: offer.createdAt.add(const Duration(days: 30)),
        views: 0,
        clicks: 0,
      ));
    }
    
    offers.addAll([
      _OfferRecord(
        type: _OfferType.discount,
        title: 'Summer property consultation',
        description:
            'Offer a discounted consultation for first-time visitors and move more walk-ins to site visits.',
        startDate: today.subtract(const Duration(days: 9)),
        endDate: today.add(const Duration(days: 20)),
        views: 56,
        clicks: 12,
      ),
      _OfferRecord(
        type: _OfferType.festival,
        title: 'Festival booking offer',
        description:
            'Open early festive booking slots and reward new leads with a limited seasonal bundle.',
        startDate: nextMonday,
        endDate: nextMonday.add(const Duration(days: 13)),
        views: 0,
        clicks: 0,
      ),
    ]);
    
    return offers;
  }

  DateTime _nextWeekday(DateTime from, int weekday) {
    var date = from.add(const Duration(days: 1));
    while (date.weekday != weekday) {
      date = date.add(const Duration(days: 1));
    }
    return _dateOnly(date);
  }

  bool get _draftIsScheduled =>
      _dateOnly(_startDate).isAfter(_dateOnly(DateTime.now()));

  String get _draftTitlePreview {
    final title = _titleController.text.trim();
    return title.isEmpty ? _selectedType.defaultTitle : title;
  }

  String get _draftStatusText {
    if (_draftPublished) {
      return _draftIsScheduled ? 'Scheduled on Google' : 'Published to Google';
    }
    return 'Ready to publish';
  }

  String get _previewActionLabel {
    if (_draftPublished) {
      return _draftIsScheduled ? 'Scheduled' : 'Published';
    }
    return _draftIsScheduled ? 'Schedule' : 'Publish';
  }

  Color get _previewActionColor {
    if (_draftPublished) {
      return _draftIsScheduled
          ? const Color(0xFFF2A13C)
          : const Color(0xFF43C79B);
    }
    return const Color(0xFF4AC0C7);
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: _dateOnly(DateTime.now()),
      lastDate: _dateOnly(DateTime.now()).add(const Duration(days: 730)),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _startDate = _dateOnly(picked);
      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate.add(const Duration(days: 29));
      }
      _draftPublished = false;
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365)),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _endDate = _dateOnly(picked);
      _draftPublished = false;
    });
  }

  void _selectOfferType(_OfferType type) {
    if (_selectedType == type) {
      return;
    }

    setState(() {
      _selectedType = type;
      _titleController.text = type.defaultTitle;
      _descriptionController.text = type.defaultDescription;
      _draftPublished = false;
    });
  }

  void _applySuggestion(String suggestion) {
    switch (suggestion) {
      case 'Monsoon Repair':
        _titleController.text = 'Monsoon repair package with 10% off';
        _descriptionController.text =
            'Promote a first-visit repair package designed for the monsoon season with a limited-time 10% discount.';
        break;
      case 'Free Consultation':
        _titleController.text = 'Free consultation for first-time customers';
        _descriptionController.text =
            'Invite new customers to book a free consultation and understand the service plan before they commit.';
        break;
      case 'Festive Package':
        _titleController.text = 'Festive package with limited bonus';
        _descriptionController.text =
            'Bundle your festival offer with a bonus add-on to increase bookings during the seasonal rush.';
        break;
      case 'Weekend Bonus':
        _titleController.text = 'Weekend bonus for festive bookings';
        _descriptionController.text =
            'Encourage weekend bookings with a small festive bonus for customers who reserve in advance.';
        break;
      case 'Launch Week Bonus':
        _titleController.text = 'Launch week bonus for early sign-ups';
        _descriptionController.text =
            'Reward early customers during launch week with a limited bonus that creates urgency and trial.';
        break;
      case 'VIP Preview':
        _titleController.text = 'VIP preview offer for early customers';
        _descriptionController.text =
            'Invite high-intent customers to a VIP preview and offer a limited early-access benefit before launch.';
        break;
    }

    _showOfferSnack(
      'Suggestion applied',
      '$suggestion was added to your offer draft.',
    );
  }

  Future<void> _applyAiPackage() async {
    final template = GbpPost.createEmpty();
    final businessName = widget.controller.currentUser.value?.businessName ?? 'Business';
    
    final created = await Get.to<GbpPost>(
      () => GbpPostCreateMethodView(
        templatePost: template,
        businessName: businessName,
        postType: 'offer',
      ),
    );

    if (created != null) {
      setState(() {
        _titleController.text = created.title;
        _descriptionController.text = created.subtitle;
        _draftPublished = false;
      });
      _showOfferSnack(
        'AI Offer Generated',
        'Your offer was generated. Review and publish when ready.',
      );
    }
  }

  void _publishOffer() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      _showOfferSnack(
        'Complete the offer',
        'Add an offer title and description before publishing.',
      );
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      _showOfferSnack(
        'Fix the dates',
        'The end date must be the same as or later than the start date.',
      );
      return;
    }

    final isScheduled = _draftIsScheduled;
    final offer = _OfferRecord(
      type: _selectedType,
      title: title,
      description: description,
      startDate: _startDate,
      endDate: _endDate,
      views: isScheduled ? 0 : _estimateOfferViews(title),
      clicks: isScheduled ? 0 : _estimateOfferClicks(description),
    );

    setState(() {
      _offers.insert(0, offer);
      _draftPublished = true;
    });

    _showOfferSnack(
      isScheduled ? 'Offer scheduled' : 'Offer published',
      isScheduled
          ? 'This offer will go live on ${_formatOfferDate(_startDate)}.'
          : 'Your offer is now live in the recent offers list.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = widget.controller.currentUser.value;
      if (user == null) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      final businessName = user.businessName.trim().isEmpty
          ? 'Google Business Profile'
          : user.businessName.trim();
      final recentOffers = _offers.take(4).toList();

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AuthShellBackButton(),
                const SizedBox(height: 12),
                Text(
                  'Offers & Promotions',
                  style: AppTypography.section(
                    fontSize: 31,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create and publish special offers directly to your Google Business Profile',
                  style: AppTypography.body(
                    fontSize: 14.2,
                    height: 1.38,
                    color: const Color(0xFF778397),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const _OfferHeroCard(),
                const SizedBox(height: 10),
                _OfferMetricsRow(offers: _offers),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Create New Offer',
                        style: AppTypography.card(
                          fontSize: 25,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _applyAiPackage,
                      icon: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: AppColors.white,
                      ),
                      label: const Text(
                        'Generate AI Offer',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE4EAF3)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08102F5A),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _OfferSectionLabel('OFFER TYPE'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _OfferTypeChip(
                            label: _OfferType.discount.label,
                            selected: _selectedType == _OfferType.discount,
                            onTap: () => _selectOfferType(_OfferType.discount),
                          ),
                          _OfferTypeChip(
                            label: _OfferType.festival.label,
                            selected: _selectedType == _OfferType.festival,
                            onTap: () => _selectOfferType(_OfferType.festival),
                          ),
                          _OfferTypeChip(
                            label: _OfferType.newLaunch.label,
                            selected: _selectedType == _OfferType.newLaunch,
                            onTap: () => _selectOfferType(_OfferType.newLaunch),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _OfferSectionLabel('OFFER TITLE'),
                      const SizedBox(height: 6),
                      _OfferFieldBox(
                        controller: _titleController,
                        hintText: _selectedType.defaultTitle,
                      ),
                      const SizedBox(height: 12),
                      const _OfferSectionLabel('DESCRIPTION'),
                      const SizedBox(height: 6),
                      _OfferFieldBox(
                        controller: _descriptionController,
                        hintText: _selectedType.defaultDescription,
                        minHeight: 92,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stackButtons = constraints.maxWidth < 350;

                          final startButton = _ScheduleActionButton(
                            label: 'Start: ${_formatOfferDate(_startDate)}',
                            icon: Icons.calendar_today_outlined,
                            foreground: const Color(0xFF2EADC0),
                            background: const Color(0xFFF6FEFE),
                            borderColor: const Color(0xFF7FD2DB),
                            onTap: _pickStartDate,
                          );

                          final endButton = _ScheduleActionButton(
                            label: 'Ends: ${_formatOfferDate(_endDate)}',
                            icon: Icons.schedule_outlined,
                            foreground: const Color(0xFFF39457),
                            background: const Color(0xFFFFFBF6),
                            borderColor: const Color(0xFFF3B183),
                            onTap: _pickEndDate,
                          );

                          if (stackButtons) {
                            return Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: startButton,
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: endButton,
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: startButton),
                              const SizedBox(width: 8),
                              Expanded(child: endButton),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _VisibloSuggestionCard(
                        suggestions: _selectedType.suggestions,
                        onSuggestionTap: _applySuggestion,
                        onPackageTap: _applyAiPackage,
                        onInfoTap: () {
                          _showOfferSnack(
                            'VisibloAI suggestions',
                            'Tap a suggestion chip to apply it to the draft instantly.',
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'GBP Preview',
                  style: AppTypography.card(
                    fontSize: 20,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _GbpPreviewCard(
                  businessName: businessName,
                  offerTitle: _draftTitlePreview,
                  durationDays: _offerDurationDays(_startDate, _endDate),
                  statusText: _draftStatusText,
                  actionLabel: _previewActionLabel,
                  actionColor: _previewActionColor,
                  onActionTap: _draftPublished ? null : _publishOffer,
                ),
                const SizedBox(height: 14),
                Text(
                  'Recent Offers',
                  style: AppTypography.card(
                    fontSize: 18,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                for (var index = 0; index < recentOffers.length; index++) ...[
                  _RecentOfferCard(
                    title: recentOffers[index].title,
                    subtitle: _offerSubtitle(recentOffers[index]),
                    statusLabel: _offerStatusLabel(recentOffers[index]),
                    statusColor: _offerStatusColor(recentOffers[index]),
                    iconColor: recentOffers[index].type.recentIconColor,
                    iconBackground:
                        recentOffers[index].type.recentIconBackground,
                  ),
                  if (index != recentOffers.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _OfferHeroCard extends StatelessWidget {
  const _OfferHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2F8EA0),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2C8F97),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  size: 16,
                  color: Color(0xFF2F8EA0),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'UNLOCKED ON GROWTH',
                style: AppTypography.label(
                  fontSize: 9.8,
                  color: AppColors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Offer Publisher',
            style: AppTypography.card(
              fontSize: 27,
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Promote deals, discounts and seasonal campaigns',
            style: AppTypography.body(
              fontSize: 14,
              color: AppColors.white.withValues(alpha: 0.9),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _HeroBadge(label: 'Growth plan active'),
              _HeroBadge(label: '1-3 locations'),
              _HeroBadge(label: 'GBP ready'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: AppTypography.label(
          fontSize: 10.5,
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OfferMetricsRow extends StatelessWidget {
  const _OfferMetricsRow({required this.offers});

  final List<_OfferRecord> offers;

  @override
  Widget build(BuildContext context) {
    final liveCount = offers.where((offer) => !offer.isScheduled).length;
    final scheduledCount = offers.where((offer) => offer.isScheduled).length;
    final totalClicks = offers.fold<int>(0, (sum, offer) => sum + offer.clicks);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useWrap = constraints.maxWidth < 330;
        final cards = [
          _OfferMetricCard(
            value: '$liveCount',
            label: 'Live Offers',
            icon: Icons.card_giftcard_rounded,
            iconColor: Color(0xFF39B4BD),
            iconBackground: Color(0xFFEAFBFD),
          ),
          _OfferMetricCard(
            value: '$scheduledCount',
            label: 'Scheduled',
            icon: Icons.calendar_month_outlined,
            iconColor: Color(0xFF4A8BD8),
            iconBackground: Color(0xFFEEF4FF),
          ),
          _OfferMetricCard(
            value: '$totalClicks',
            label: 'Clicks',
            icon: Icons.bar_chart_rounded,
            iconColor: Color(0xFFF5B24B),
            iconBackground: Color(0xFFFFF6E6),
          ),
        ];

        if (useWrap) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cards
                .map(
                  (card) => SizedBox(
                    width: (constraints.maxWidth - 8) / 2,
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: [
            Expanded(
              child: _OfferMetricCard.inline(
                value: '$liveCount',
                label: 'Live Offers',
                icon: Icons.card_giftcard_rounded,
                iconColor: Color(0xFF39B4BD),
                iconBackground: Color(0xFFEAFBFD),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _OfferMetricCard.inline(
                value: '$scheduledCount',
                label: 'Scheduled',
                icon: Icons.calendar_month_outlined,
                iconColor: Color(0xFF4A8BD8),
                iconBackground: Color(0xFFEEF4FF),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _OfferMetricCard.inline(
                value: '$totalClicks',
                label: 'Clicks',
                icon: Icons.bar_chart_rounded,
                iconColor: Color(0xFFF5B24B),
                iconBackground: Color(0xFFFFF6E6),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OfferMetricCard extends StatelessWidget {
  const _OfferMetricCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  }) : _expanded = false;

  const _OfferMetricCard.inline({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  }) : _expanded = true;

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final bool _expanded;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      constraints: BoxConstraints(minHeight: _expanded ? 112 : 0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EBF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08102F5A),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF2F8EA0),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(13),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 15, color: iconColor),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: AppTypography.card(
                    fontSize: 31,
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label(
                    fontSize: 11.6,
                    color: const Color(0xFF8A97A9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return card;
  }
}

class _OfferSectionLabel extends StatelessWidget {
  const _OfferSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.label(
        fontSize: 10.4,
        color: const Color(0xFF9AA7B8),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _OfferTypeChip extends StatelessWidget {
  const _OfferTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE8FBFD) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFF4CC0CC)
                  : const Color(0xFFDCE4EF),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.label(
              fontSize: 11.2,
              color: selected ? const Color(0xFF2D9FB1) : AppColors.text,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferFieldBox extends StatelessWidget {
  const _OfferFieldBox({
    required this.controller,
    required this.hintText,
    this.minHeight = 48,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final double minHeight;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        style: AppTypography.body(
          fontSize: 13.8,
          color: AppColors.text,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.body(
            fontSize: 13.6,
            color: const Color(0xFF9AA7B8),
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: const Color(0xFFF7F9FC),
          contentPadding: EdgeInsets.fromLTRB(
            12,
            maxLines > 1 ? 12 : 12,
            12,
            maxLines > 1 ? 12 : 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDFE6F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
          ),
        ),
      ),
    );
  }
}

class _ScheduleActionButton extends StatelessWidget {
  const _ScheduleActionButton({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label(
                    fontSize: 12.1,
                    color: foreground,
                    fontWeight: FontWeight.w700,
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

class _VisibloSuggestionCard extends StatelessWidget {
  const _VisibloSuggestionCard({
    required this.suggestions,
    required this.onSuggestionTap,
    required this.onPackageTap,
    required this.onInfoTap,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSuggestionTap;
  final VoidCallback onPackageTap;
  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7CCFB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_fix_high_rounded,
                  size: 18,
                  color: Color(0xFF5E47D7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'VisibloAI Suggestions',
                            style: AppTypography.label(
                              fontSize: 15.2,
                              color: const Color(0xFF5E47D7),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: onInfoTap,
                          borderRadius: BorderRadius.circular(999),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: Color(0xFF8C7FEA),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This lead asked for bridal makeup.\nSend package details now.',
                      style: AppTypography.body(
                        fontSize: 12.8,
                        color: const Color(0xFF44506A),
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: suggestions
                          .map(
                            (suggestion) => _SuggestionPill(
                              label: suggestion,
                              onTap: () => onSuggestionTap(suggestion),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: onPackageTap,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF5C32D5),
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Send Package',
                          style: AppTypography.label(
                            fontSize: 11.8,
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
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

class _GbpPreviewCard extends StatelessWidget {
  const _GbpPreviewCard({
    required this.businessName,
    required this.offerTitle,
    required this.durationDays,
    required this.statusText,
    required this.actionLabel,
    required this.actionColor,
    required this.onActionTap,
  });

  final String businessName;
  final String offerTitle;
  final int durationDays;
  final String statusText;
  final String actionLabel;
  final Color actionColor;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final initial = businessName.trim().isEmpty
        ? 'G'
        : businessName.trim()[0].toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F3F7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05102F5A),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6FF),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppTypography.card(
                fontSize: 18,
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label(
                    fontSize: 14.3,
                    height: 1.2,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: AppTypography.label(
                      fontSize: 11.5,
                      color: const Color(0xFF7E8A9B),
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      const TextSpan(text: 'Special offer · '),
                      TextSpan(
                        text: offerTitle,
                        style: const TextStyle(
                          color: Color(0xFFF05B73),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Valid for $durationDays days · $statusText',
                  style: AppTypography.label(
                    fontSize: 10.4,
                    color: const Color(0xFF9FA8B7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: actionColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    actionLabel,
                    style: AppTypography.label(
                      fontSize: 10.9,
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionPill extends StatelessWidget {
  const _SuggestionPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8DFFF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: AppTypography.label(
              fontSize: 10.9,
              color: const Color(0xFF5E47D7),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentOfferCard extends StatelessWidget {
  const _RecentOfferCard({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
    required this.iconColor,
    required this.iconBackground,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08102F5A),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.card_giftcard_rounded,
              size: 15,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.label(
                    fontSize: 13.6,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.label(
                    fontSize: 10.9,
                    color: const Color(0xFF98A4B4),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusLabel,
              style: AppTypography.label(
                fontSize: 10.2,
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
