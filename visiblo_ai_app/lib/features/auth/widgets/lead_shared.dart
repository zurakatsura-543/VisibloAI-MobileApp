import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../models/lead_record.dart';

class LeadSuggestionCard extends StatelessWidget {
  const LeadSuggestionCard({super.key});

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

class LeadAvatarPalette {
  const LeadAvatarPalette({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

class LeadStageStyle {
  const LeadStageStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}

LeadAvatarPalette leadAvatarPalette(int tone) {
  switch (tone) {
    case 1:
      return const LeadAvatarPalette(
        background: Color(0xFFE9F0FF),
        foreground: Color(0xFF416EE2),
      );
    case 2:
      return const LeadAvatarPalette(
        background: Color(0xFFE6F7EE),
        foreground: Color(0xFF33A86C),
      );
    default:
      return const LeadAvatarPalette(
        background: Color(0xFFE3F8FB),
        foreground: Color(0xFF3BAEBF),
      );
  }
}

LeadStageStyle leadStageStyle(LeadStage stage) {
  switch (stage) {
    case LeadStage.newLead:
      return const LeadStageStyle(
        label: 'New',
        background: Color(0xFFE6F9F9),
        foreground: AppColors.primaryDark,
      );
    case LeadStage.contacted:
      return const LeadStageStyle(
        label: 'Contacted',
        background: Color(0xFFEAF8ED),
        foreground: Color(0xFF2E9D56),
      );
    case LeadStage.interested:
      return const LeadStageStyle(
        label: 'Interested',
        background: Color(0xFFFFF5DF),
        foreground: Color(0xFFCA8B16),
      );
    case LeadStage.converted:
      return const LeadStageStyle(
        label: 'Converted',
        background: Color(0xFFE8F6ED),
        foreground: Color(0xFF2A8B4C),
      );
    case LeadStage.followUpRequired:
      return const LeadStageStyle(
        label: 'Follow-up Required',
        background: Color(0xFFFFF1E6),
        foreground: Color(0xFFD97927),
      );
    case LeadStage.notInterested:
      return const LeadStageStyle(
        label: 'Not Interested',
        background: Color(0xFFFFEBEE),
        foreground: Color(0xFFD55162),
      );
  }
}
