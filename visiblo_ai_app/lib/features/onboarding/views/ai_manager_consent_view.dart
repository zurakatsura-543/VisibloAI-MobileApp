import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/widgets/app_logo.dart';
import '../../../app/widgets/app_primary_button.dart';
import '../controllers/onboarding_controller.dart';

class AiManagerConsentView extends StatefulWidget {
  const AiManagerConsentView({super.key});

  @override
  State<AiManagerConsentView> createState() => _AiManagerConsentViewState();
}

class _AiManagerConsentViewState extends State<AiManagerConsentView> {
  final OnboardingController _controller = Get.find<OnboardingController>();
  bool _accepted = false;

  Future<void> _continue() async {
    if (!_accepted) {
      Get.snackbar(
        'Authorization required',
        'Please accept the AI Manager authorization to continue.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    await _controller.acceptAiManagerConsentAndContinue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: -92,
              right: -88,
              child: _SoftGlow(color: Color(0x3325C2C9), size: 210),
            ),
            const Positioned(
              bottom: -120,
              left: -96,
              child: _SoftGlow(color: Color(0x332C74FF), size: 240),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      const AppLogo(iconSize: 58, centered: true),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Skip for now',
                        onPressed: () => Get.offAllNamed(AppRoutes.payment),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your AI Marketing Partner for',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 21,
                      height: 1.12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    'Google Business Profile',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      height: 1.14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'VisibloAI takes care of your profile so you can focus on growing your business.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 13.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _PillLabel(),
                  const SizedBox(height: 12),
                  for (final item in _benefits)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _BenefitTile(item: item),
                    ),
                  const SizedBox(height: 8),
                  _ConsentBox(
                    accepted: _accepted,
                    onChanged: (value) {
                      setState(() => _accepted = value ?? false);
                    },
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => AppPrimaryButton(
                      label: 'Yes, I\'m In. Continue to Activate',
                      icon: Icons.auto_awesome_rounded,
                      isLoading: _controller.isAiManagerConsentLoading.value,
                      onPressed: _continue,
                      backgroundColor: const Color(0xFF106CFF),
                      disabledBackgroundColor: const Color(0xFF7BA8F6),
                      height: 58,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 15,
                        color: AppColors.mutedText,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'You can update or stop automation anytime from settings.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedText,
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
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  const _PillLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.line)),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F6FF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFDCE8FF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.diamond_outlined,
                size: 15,
                color: AppColors.brandBlue,
              ),
              const SizedBox(width: 6),
              Text(
                'What You Get with VisibloAI',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandBlue,
                ),
              ),
            ],
          ),
        ),
        const Expanded(child: Divider(color: AppColors.line)),
      ],
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({required this.item});

  final _ConsentBenefit item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13.2,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 10.8,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: Color(0xFF18B76A),
          ),
        ],
      ),
    );
  }
}

class _ConsentBox extends StatelessWidget {
  const _ConsentBox({required this.accepted, required this.onChanged});

  final bool accepted;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FFF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC7EED8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: accepted,
            onChanged: onChanged,
            activeColor: const Color(0xFF18B76A),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: 'I accept the ',
                    children: const [
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: TextStyle(
                          color: Color(0xFF106CFF),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' and authorize VisibloAI to create, schedule and publish posts on my Google Business Profile automatically as per my preferences.',
                      ),
                    ],
                  ),
                  style: GoogleFonts.manrope(
                    fontSize: 11.8,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.terms),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 13,
                        color: Color(0xFF106CFF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'View Terms & Conditions',
                        style: GoogleFonts.manrope(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF106CFF),
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
    );
  }
}

class _SoftGlow extends StatelessWidget {
  const _SoftGlow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 90, spreadRadius: 34),
          ],
        ),
      ),
    );
  }
}

class _ConsentBenefit {
  const _ConsentBenefit({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}

const _benefits = <_ConsentBenefit>[
  _ConsentBenefit(
    icon: Icons.psychology_alt_outlined,
    color: Color(0xFF2F80ED),
    title: 'AI Research & Smart Content Creation',
    subtitle: 'AI understands your business and creates engaging posts.',
  ),
  _ConsentBenefit(
    icon: Icons.calendar_month_outlined,
    color: Color(0xFF1BBF73),
    title: 'Auto Post on Google',
    subtitle: 'Posts are scheduled and published at useful times.',
  ),
  _ConsentBenefit(
    icon: Icons.edit_calendar_outlined,
    color: Color(0xFF8B5CF6),
    title: '30-Day Content Calendar',
    subtitle: 'Get a full content plan every month to stay active.',
  ),
  _ConsentBenefit(
    icon: Icons.track_changes_rounded,
    color: Color(0xFFFF8A00),
    title: 'More Customers & Engagement',
    subtitle: 'Improve visibility, leads, messages, website visits and calls.',
  ),
  _ConsentBenefit(
    icon: Icons.bar_chart_rounded,
    color: Color(0xFF2F80ED),
    title: 'Performance Insights',
    subtitle: 'Track views, clicks, calls, direction requests and more.',
  ),
  _ConsentBenefit(
    icon: Icons.verified_user_outlined,
    color: Color(0xFFFF4E80),
    title: '100% Safe & Policy Compliant',
    subtitle: 'Content is checked before it goes live.',
  ),
  _ConsentBenefit(
    icon: Icons.translate_rounded,
    color: Color(0xFF18A999),
    title: 'Multi-Language Support',
    subtitle: 'Create posts in languages that fit your local customers.',
  ),
  _ConsentBenefit(
    icon: Icons.image_outlined,
    color: Color(0xFF7C3AED),
    title: 'Branded Images & AI Visuals',
    subtitle: 'Beautiful images and creatives that match your brand.',
  ),
  _ConsentBenefit(
    icon: Icons.local_offer_outlined,
    color: Color(0xFFFF8A00),
    title: 'Promote Offers, Events & Services',
    subtitle: 'Highlight approved offers, new services and updates.',
  ),
  _ConsentBenefit(
    icon: Icons.forum_outlined,
    color: Color(0xFF2F80ED),
    title: 'AI Engagement & Review Assistant',
    subtitle: 'AI helps respond to reviews and manage customer messages.',
  ),
  _ConsentBenefit(
    icon: Icons.schedule_rounded,
    color: Color(0xFF1BBF73),
    title: 'Set It Once, AI Does the Rest',
    subtitle: 'Tell us your goals and preferences once.',
  ),
  _ConsentBenefit(
    icon: Icons.lock_outline_rounded,
    color: Color(0xFF7C3AED),
    title: 'Secure, Private & Reliable',
    subtitle: 'Your data is protected with enterprise-grade security.',
  ),
];
