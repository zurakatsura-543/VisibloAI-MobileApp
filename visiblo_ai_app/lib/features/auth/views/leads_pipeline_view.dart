import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../models/lead_record.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_navigation_shell.dart';

class LeadsPipelineView extends StatefulWidget {
  const LeadsPipelineView({super.key});

  @override
  State<LeadsPipelineView> createState() => _LeadsPipelineViewState();
}

class _LeadsPipelineViewState extends State<LeadsPipelineView> {
  _LeadFilter _selectedFilter = _LeadFilter.all;

  List<LeadRecord> get _visibleLeads {
    switch (_selectedFilter) {
      case _LeadFilter.all:
        return demoLeadRecords;
      case _LeadFilter.newLead:
        return demoLeadRecords
            .where((lead) => lead.stage == LeadStage.newLead)
            .toList();
      case _LeadFilter.contacted:
        return demoLeadRecords
            .where((lead) => lead.stage == LeadStage.contacted)
            .toList();
      case _LeadFilter.followUp:
        return demoLeadRecords
            .where((lead) => lead.stage == LeadStage.followUpRequired)
            .toList();
      case _LeadFilter.converted:
        return demoLeadRecords
            .where((lead) => lead.stage == LeadStage.converted)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthNavigationShell(
      currentTab: AuthTab.home,
      backgroundColor: _LeadPalette.canvas,
      child: SingleChildScrollView(
        padding: AuthViewSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthShellBackButton(),
            const SizedBox(height: AuthViewSpacing.cardGap),
            const _LeadSummaryCard(),
            const SizedBox(height: AuthViewSpacing.cardGap),
            const _LeadSuggestionCard(),
            const SizedBox(height: AuthViewSpacing.sectionGap),
            const Text(
              'Lead Pipeline',
              style: TextStyle(
                fontSize: 23,
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AuthViewSpacing.cardGap),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _LeadFilter.values.map((filter) {
                  final isSelected = filter == _selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFFE3E8EF),
                          ),
                        ),
                        child: Text(
                          filter.label,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.brandBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AuthViewSpacing.cardGap),
            ..._visibleLeads.map(
              (lead) => Padding(
                padding: const EdgeInsets.only(bottom: AuthViewSpacing.cardGap),
                child: _LeadPipelineCard(
                  lead: lead,
                  onOpen: () =>
                      Get.toNamed(AppRoutes.leadDetail, arguments: lead),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _LeadFilter {
  all('All'),
  newLead('New'),
  contacted('Contacted'),
  followUp('Follow-up'),
  converted('Converted');

  const _LeadFilter(this.label);

  final String label;
}

class _LeadSummaryCard extends StatelessWidget {
  const _LeadSummaryCard();

  static const _metrics = [
    _LeadSummaryMetric(label: 'Total\nLeads', value: '52'),
    _LeadSummaryMetric(label: 'New', value: '12'),
    _LeadSummaryMetric(label: 'Follow-\nup', value: '8'),
    _LeadSummaryMetric(label: 'Conver\nted', value: '6'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 340;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0F4F8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F2746),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var index = 0; index < _metrics.length; index++) ...[
                Expanded(
                  child: _LeadSummaryMetricTile(
                    metric: _metrics[index],
                    isCompact: isCompact,
                  ),
                ),
                if (index != _metrics.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LeadSummaryMetric {
  const _LeadSummaryMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class _LeadSummaryMetricTile extends StatelessWidget {
  const _LeadSummaryMetricTile({required this.metric, required this.isCompact});

  final _LeadSummaryMetric metric;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, isCompact ? 8 : 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5EAF0)),
      ),
      child: SizedBox(
        height: isCompact ? 54 : 58,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              metric.label,
              maxLines: 2,
              overflow: TextOverflow.fade,
              style: TextStyle(
                fontSize: isCompact ? 9.2 : 9.8,
                height: 1.2,
                color: AppColors.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                metric.value,
                style: TextStyle(
                  fontSize: isCompact ? 17 : 18,
                  height: 1,
                  color: AppColors.brandBlue,
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

class _LeadSuggestionCard extends StatelessWidget {
  const _LeadSuggestionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9CCFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Color(0xFF5E47D7),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'AI Suggestion',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5E47D7),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: Color(0xFF8B79E8),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.only(left: 38),
            child: Text(
              'This lead asked for bridal makeup.\nSend package details now.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: () {
                  Get.snackbar(
                    'Package ready',
                    'Bridal package details can be shared from this action.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF5E47D7),
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Send Package',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadPipelineCard extends StatelessWidget {
  const _LeadPipelineCard({required this.lead, required this.onOpen});

  final LeadRecord lead;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final style = _leadStageStyle(lead.stage);
    final avatar = _leadAvatarPalette(lead.avatarTone);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F2746),
                blurRadius: 16,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: avatar.background,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      lead.initials,
                      style: TextStyle(
                        fontSize: 14,
                        color: avatar.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead.name,
                          style: const TextStyle(
                            fontSize: 15,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: style.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      style.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: style.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _LeadDetailCell(label: 'Source', value: lead.source),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LeadDetailCell(label: 'Mobile', value: lead.mobile),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _LeadDetailCell(
                      label: 'Follow-up',
                      value: lead.followUp,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LeadDetailCell(label: 'Notes', value: lead.notes),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _PipelineActionButton(
                      label: 'Call',
                      background: const Color(0xFF355FDE),
                      foreground: AppColors.white,
                      leading: const Icon(
                        Icons.call_rounded,
                        size: 16,
                        color: AppColors.white,
                      ),
                      onTap: () => _showAction('Call'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PipelineActionButton(
                      label: 'WhatsApp',
                      background: const Color(0xFF2CB25B),
                      foreground: AppColors.white,
                      leading: SvgPicture.asset(
                        'assets/icons/whatsapp_mark.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          AppColors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      onTap: () => _showAction('WhatsApp'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PipelineActionButton(
                      label: 'View Detail',
                      background: const Color(0xFFF4F7FB),
                      foreground: AppColors.brandBlue,
                      onTap: onOpen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAction(String action) {
    Get.snackbar(
      '$action action',
      '$action integration can be connected here for ${lead.name}.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

class _LeadDetailCell extends StatelessWidget {
  const _LeadDetailCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: AppColors.text.withValues(alpha: 0.44),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.35,
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PipelineActionButton extends StatelessWidget {
  const _PipelineActionButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.leading,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: background,
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadAvatarPalette {
  const _LeadAvatarPalette({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}

class _LeadStageStyle {
  const _LeadStageStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}

_LeadAvatarPalette _leadAvatarPalette(int tone) {
  switch (tone) {
    case 1:
      return const _LeadAvatarPalette(
        background: Color(0xFFE9F0FF),
        foreground: Color(0xFF416EE2),
      );
    case 2:
      return const _LeadAvatarPalette(
        background: Color(0xFFE6F7EE),
        foreground: Color(0xFF33A86C),
      );
    default:
      return const _LeadAvatarPalette(
        background: Color(0xFFE3F8FB),
        foreground: Color(0xFF3BAEBF),
      );
  }
}

_LeadStageStyle _leadStageStyle(LeadStage stage) {
  switch (stage) {
    case LeadStage.newLead:
      return const _LeadStageStyle(
        label: 'New',
        background: Color(0xFFE6F9F9),
        foreground: AppColors.primaryDark,
      );
    case LeadStage.contacted:
      return const _LeadStageStyle(
        label: 'Contacted',
        background: Color(0xFFEAF8ED),
        foreground: Color(0xFF2E9D56),
      );
    case LeadStage.interested:
      return const _LeadStageStyle(
        label: 'Interested',
        background: Color(0xFFFFF5DF),
        foreground: Color(0xFFCA8B16),
      );
    case LeadStage.converted:
      return const _LeadStageStyle(
        label: 'Converted',
        background: Color(0xFFE8F6ED),
        foreground: Color(0xFF2A8B4C),
      );
    case LeadStage.followUpRequired:
      return const _LeadStageStyle(
        label: 'Follow-up Required',
        background: Color(0xFFFFF1E6),
        foreground: Color(0xFFD97927),
      );
    case LeadStage.notInterested:
      return const _LeadStageStyle(
        label: 'Not Interested',
        background: Color(0xFFFFEBEE),
        foreground: Color(0xFFD55162),
      );
  }
}

abstract final class _LeadPalette {
  static const canvas = Color(0xFFF7F8FB);
}
