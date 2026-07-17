import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../models/lead_record.dart';
import '../widgets/auth_calendar_sheet.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_navigation_shell.dart';
import '../widgets/lead_shared.dart';

class LeadDetailView extends StatefulWidget {
  const LeadDetailView({super.key});

  @override
  State<LeadDetailView> createState() => _LeadDetailViewState();
}

class _LeadDetailViewState extends State<LeadDetailView> {
  late LeadStage _selectedStage;
  late DateTime _followUpDate;
  late TimeOfDay _followUpTime;

  LeadRecord get _lead {
    final arg = Get.arguments;
    if (arg is LeadRecord) {
      return arg;
    }
    return demoLeadRecords.first;
  }

  @override
  void initState() {
    super.initState();
    _selectedStage = _lead.stage;
    _followUpDate = DateTime(2026, 5, 22);
    _followUpTime = const TimeOfDay(hour: 17, minute: 0);
  }

  @override
  Widget build(BuildContext context) {
    final lead = _lead;
    final stageStyle = leadStageStyle(_selectedStage);
    final avatar = leadAvatarPalette(lead.avatarTone);

    return AuthNavigationShell(
      currentTab: AuthTab.home,
      backgroundColor: _LeadDetailPalette.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AuthViewSpacing.pageHorizontal,
          8,
          AuthViewSpacing.pageHorizontal,
          AuthViewSpacing.pageBottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: Get.back,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppColors.brandBlue,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Lead Detail',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Get.snackbar(
                      'More options',
                      'Additional lead actions can be added here.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: AppColors.brandBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AuthViewSpacing.cardGap),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              decoration: _detailCardDecoration(),
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: avatar.background,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              lead.initials,
                              style: TextStyle(
                                fontSize: 20,
                                color: avatar.foreground,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 2,
                            bottom: 1,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: const Color(0xFF42BE67),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lead.name,
                              style: const TextStyle(
                                fontSize: 15.5,
                                color: AppColors.brandBlue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lead.interest,
                              style: const TextStyle(
                                fontSize: 11.5,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: stageStyle.background,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          stageStyle.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: stageStyle.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Source',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.text.withValues(alpha: 0.42),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _LeadChannelIcon(
                        kind: _sourceIconKind(lead.source),
                        size: 18,
                        showBackground: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _PrimaryLeadButton(
                          label: 'Call',
                          leading: const Icon(Icons.call_rounded, size: 18),
                          background: const Color(0xFF355FDE),
                          onTap: () => _showAction('Call'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PrimaryLeadButton(
                          label: 'WhatsApp',
                          leading: const _LeadChannelIcon(
                            kind: _LeadIconKind.whatsapp,
                            size: 18,
                            showBackground: false,
                            colorOverride: AppColors.white,
                          ),
                          background: const Color(0xFF2CB25B),
                          onTap: () => _showAction('WhatsApp'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFE8EDF3)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _LeadInfoItem(
                          iconKind: _LeadIconKind.mobile,
                          label: 'Mobile',
                          value: lead.mobile,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _LeadInfoItem(
                          iconKind: _LeadIconKind.service,
                          label: 'Service Interested',
                          value: lead.serviceInterested,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _LeadInfoItem(
                          iconKind: _sourceIconKind(lead.source),
                          label: 'Source',
                          value: lead.source,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _LeadInfoItem(
                          iconKind: _LeadIconKind.receivedOn,
                          label: 'Received On',
                          value: lead.receivedOn,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _LeadInfoItem(
                          iconKind: _LeadIconKind.followUp,
                          label: 'Follow-up',
                          value: lead.followUp,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _LeadInfoItem(
                          iconKind: _LeadIconKind.notes,
                          label: 'Notes',
                          value: lead.notes,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AuthViewSpacing.cardGap),
            const LeadSuggestionCard(),
            const SizedBox(height: AuthViewSpacing.cardGap),
            _DetailInfoCard(
              title: 'Notes',
              trailing: TextButton.icon(
                onPressed: () => _showAction('Edit notes'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandBlue,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: const Text(
                  'Edit',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
              child: Text(
                'Asked for bridal package details and pricing for December dates.',
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: AuthViewSpacing.cardGap),
            _DetailInfoCard(
              title: 'Update Lead Status',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: LeadStage.values.map((stage) {
                  final selected = stage == _selectedStage;
                  final accent = _stageAccentColor(stage);
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width - 62) / 3,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() {
                          _selectedStage = stage;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? accent.withValues(alpha: 0.09)
                              : const Color(0xFFFBFCFE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? accent.withValues(alpha: 0.45)
                                : const Color(0xFFE4E9F1),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_stageIcon(stage), size: 18, color: accent),
                            const SizedBox(height: 8),
                            Text(
                              _stageShortLabel(stage),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: selected
                                    ? accent
                                    : AppColors.text.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AuthViewSpacing.cardGap),
            _DetailInfoCard(
              title: 'Set Follow-up Date & Time',
              child: Row(
                children: [
                  Expanded(
                    child: _PickerField(
                      icon: Icons.calendar_month_rounded,
                      value: _formatDate(_followUpDate),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerField(
                      icon: Icons.access_time_rounded,
                      value: _formatTime(_followUpTime),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AuthViewSpacing.cardGap),
            _DetailInfoCard(
              title: 'Lead Activity',
              trailing: TextButton(
                onPressed: () => _showAction('View all activity'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandBlue,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
              child: Column(
                children: lead.activity.asMap().entries.map((entry) {
                  final index = entry.key;
                  final event = entry.value;
                  final isLast = index == lead.activity.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 22,
                          child: Column(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _activityColor(event.iconLabel),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 44,
                                  color: const Color(0xFFDDE6F0),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _LeadChannelIcon(
                                    kind: _activityIconKind(event.iconLabel),
                                    size: 14,
                                    showBackground: false,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      event.title,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.brandBlue,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    event.timeLabel,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.text.withValues(
                                        alpha: 0.45,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 20),
                                child: Text(
                                  event.subtitle,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    height: 1.4,
                                    color: AppColors.mutedText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showAuthCalendarSheet(
      context: context,
      title: 'Follow-up Calendar',
      initialDate: _followUpDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _followUpDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _followUpTime,
    );
    if (picked != null) {
      setState(() {
        _followUpTime = picked;
      });
    }
  }

  void _showAction(String label) {
    Get.snackbar(
      label,
      'This action is ready to connect for ${_lead.name}.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String _formatDate(DateTime value) {
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
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  String _formatTime(TimeOfDay value) {
    final hour = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }
}

class _DetailInfoCard extends StatelessWidget {
  const _DetailInfoCard({
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
      padding: const EdgeInsets.all(14),
      decoration: _detailCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PrimaryLeadButton extends StatelessWidget {
  const _PrimaryLeadButton({
    required this.label,
    required this.leading,
    required this.background,
    required this.onTap,
  });

  final String label;
  final Widget leading;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: background,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: leading,
        label: Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _LeadInfoItem extends StatelessWidget {
  const _LeadInfoItem({
    required this.iconKind,
    required this.label,
    required this.value,
  });

  final _LeadIconKind iconKind;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: _leadIconBackground(iconKind),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: _LeadChannelIcon(kind: iconKind, size: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  color: AppColors.text.withValues(alpha: 0.46),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _LeadIconKind {
  mobile,
  service,
  google,
  receivedOn,
  followUp,
  notes,
  whatsapp,
  call,
  form,
  clock,
}

class _LeadChannelIcon extends StatelessWidget {
  const _LeadChannelIcon({
    required this.kind,
    required this.size,
    this.showBackground = true,
    this.colorOverride,
  });

  final _LeadIconKind kind;
  final double size;
  final bool showBackground;
  final Color? colorOverride;

  @override
  Widget build(BuildContext context) {
    final icon = _buildLeadIcon(kind, size, colorOverride: colorOverride);
    if (!showBackground) {
      return icon;
    }
    return SizedBox(width: size, height: size, child: icon);
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE1E7F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.brandBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildLeadIcon(_LeadIconKind kind, double size, {Color? colorOverride}) {
  switch (kind) {
    case _LeadIconKind.google:
      return SvgPicture.asset(
        'assets/icons/google_logo.svg',
        width: size,
        height: size,
      );
    case _LeadIconKind.mobile:
      return Icon(
        Icons.call_rounded,
        size: size,
        color: const Color(0xFF355FDE),
      );
    case _LeadIconKind.service:
      return Icon(
        Icons.content_cut_rounded,
        size: size,
        color: const Color(0xFF39B4BD),
      );
    case _LeadIconKind.receivedOn:
      return Icon(
        Icons.calendar_today_rounded,
        size: size,
        color: const Color(0xFF7A8395),
      );
    case _LeadIconKind.followUp:
      return Icon(
        Icons.access_time_rounded,
        size: size,
        color: const Color(0xFF5A79E7),
      );
    case _LeadIconKind.notes:
      return Icon(
        Icons.note_alt_outlined,
        size: size,
        color: const Color(0xFF7A8395),
      );
    case _LeadIconKind.whatsapp:
      return SvgPicture.asset(
        'assets/icons/whatsapp_mark.svg',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(
          colorOverride ?? const Color(0xFF28B15B),
          BlendMode.srcIn,
        ),
      );
    case _LeadIconKind.call:
      return Icon(
        Icons.call_rounded,
        size: size,
        color: const Color(0xFF355FDE),
      );
    case _LeadIconKind.form:
      return Icon(
        Icons.description_rounded,
        size: size,
        color: const Color(0xFF39B4BD),
      );
    case _LeadIconKind.clock:
      return Icon(
        Icons.schedule_rounded,
        size: size,
        color: const Color(0xFFD97927),
      );
  }
}

Color _leadIconBackground(_LeadIconKind kind) {
  switch (kind) {
    case _LeadIconKind.google:
      return const Color(0xFFF5F7FB);
    case _LeadIconKind.mobile:
    case _LeadIconKind.call:
      return const Color(0xFFEFF4FD);
    case _LeadIconKind.service:
    case _LeadIconKind.form:
      return const Color(0xFFE9FAFB);
    case _LeadIconKind.receivedOn:
    case _LeadIconKind.notes:
      return const Color(0xFFF3F5F8);
    case _LeadIconKind.followUp:
      return const Color(0xFFEEF2FF);
    case _LeadIconKind.whatsapp:
      return const Color(0xFFEAF8ED);
    case _LeadIconKind.clock:
      return const Color(0xFFFFF1E6);
  }
}

_LeadIconKind _activityIconKind(String label) {
  switch (label) {
    case 'google':
      return _LeadIconKind.google;
    case 'call':
      return _LeadIconKind.call;
    case 'clock':
      return _LeadIconKind.clock;
    case 'form':
      return _LeadIconKind.form;
    default:
      return _LeadIconKind.whatsapp;
  }
}

_LeadIconKind _sourceIconKind(String source) {
  final value = source.toLowerCase();
  if (value.contains('whatsapp')) {
    return _LeadIconKind.whatsapp;
  }
  if (value.contains('website') || value.contains('form')) {
    return _LeadIconKind.form;
  }
  return _LeadIconKind.google;
}

Color _activityColor(String label) {
  switch (label) {
    case 'google':
      return const Color(0xFF4285F4);
    case 'call':
      return const Color(0xFF355FDE);
    case 'clock':
      return const Color(0xFFD97927);
    case 'form':
      return AppColors.primary;
    default:
      return const Color(0xFF2CB25B);
  }
}

String _stageShortLabel(LeadStage stage) {
  switch (stage) {
    case LeadStage.newLead:
      return 'New';
    case LeadStage.contacted:
      return 'Contacted';
    case LeadStage.interested:
      return 'Interested';
    case LeadStage.converted:
      return 'Converted';
    case LeadStage.followUpRequired:
      return 'Follow-up Reqd';
    case LeadStage.notInterested:
      return 'Not Interested';
  }
}

IconData _stageIcon(LeadStage stage) {
  switch (stage) {
    case LeadStage.newLead:
      return Icons.person_add_alt_1_rounded;
    case LeadStage.contacted:
      return Icons.phone_in_talk_rounded;
    case LeadStage.interested:
      return Icons.thumb_up_alt_rounded;
    case LeadStage.converted:
      return Icons.verified_rounded;
    case LeadStage.followUpRequired:
      return Icons.notifications_active_rounded;
    case LeadStage.notInterested:
      return Icons.cancel_rounded;
  }
}

Color _stageAccentColor(LeadStage stage) {
  switch (stage) {
    case LeadStage.newLead:
      return const Color(0xFFB22BCB);
    case LeadStage.contacted:
      return const Color(0xFF3E72F2);
    case LeadStage.interested:
      return const Color(0xFF39B4BD);
    case LeadStage.converted:
      return const Color(0xFF2FA84F);
    case LeadStage.followUpRequired:
      return const Color(0xFFF29A38);
    case LeadStage.notInterested:
      return const Color(0xFFF04E4E);
  }
}

BoxDecoration _detailCardDecoration() {
  return BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: const [
      BoxShadow(color: Color(0x120F2746), blurRadius: 16, offset: Offset(0, 7)),
    ],
  );
}

abstract final class _LeadDetailPalette {
  static const canvas = Color(0xFFF6F7FB);
}
