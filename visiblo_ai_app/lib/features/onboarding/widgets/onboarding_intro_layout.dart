import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/widgets/app_logo.dart';
import '../../../app/widgets/app_primary_button.dart';

class OnboardingIntroLayout extends StatelessWidget {
  const OnboardingIntroLayout({
    super.key,
    required this.onPressed,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    this.buttonLabel = 'Get started',
  });

  final VoidCallback onPressed;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTabletLandscape = constraints.maxWidth >= 768 &&
            MediaQuery.orientationOf(context) == Orientation.landscape;
        final isTabletPortrait = constraints.maxWidth >= 600 && !isTabletLandscape;

        if (isTabletLandscape) {
          return _buildTabletLandscape(context);
        } else if (isTabletPortrait) {
          return _buildTabletPortrait(context);
        } else {
          return _buildMobile(context);
        }
      },
    );
  }

  Widget _buildTabletLandscape(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Hero Banner Column
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const AppLogo(iconSize: 64, fontSize: 32, centered: true),
                    const SizedBox(height: 20),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandBlue,
                        ),
                        children: const [
                          TextSpan(text: 'Create, Schedule &\nPublish with '),
                          TextSpan(
                            text: 'AI',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Generate social media posts in seconds, schedule them automatically, and publish across multiple platforms from one place.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body(
                        fontSize: 15,
                        height: 1.35,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Image.asset(
                        'assets/images/banner1.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              // Right Card Column
              Expanded(
                flex: 5,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE3EBF5)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x140F2746),
                            blurRadius: 28,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'All-In-One AI Platform',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandBlue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _FeatureCard(
                            title: 'AI Post Creation',
                            subtitle: 'Create captions and creatives quickly.',
                            icon: Icons.auto_awesome_rounded,
                            colors: [Color(0xFF1E4ED8), Color(0xFF1A66F3)],
                            isFirst: true,
                            isLast: false,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFE3EBF5),
                            indent: 59,
                          ),
                          const _FeatureCard(
                            title: 'Auto Scheduling',
                            subtitle: 'Plan for the best posting time automatically.',
                            icon: Icons.calendar_month_rounded,
                            colors: [Color(0xFF2BC7D5), Color(0xFF39B4BD)],
                            isFirst: false,
                            isLast: false,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFE3EBF5),
                            indent: 59,
                          ),
                          const _FeatureCard(
                            title: 'Multi-Platform Publishing',
                            subtitle: 'Publish to multiple social channels together.',
                            icon: Icons.hub_rounded,
                            colors: [Color(0xFF1E4ED8), Color(0xFF1A66F3)],
                            isFirst: false,
                            isLast: true,
                          ),
                          const SizedBox(height: 24),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0xFF0F2B5B), Color(0xFF0F2B5B)],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x2639B4BD),
                                  blurRadius: 18,
                                  offset: Offset(0, 9),
                                ),
                              ],
                            ),
                            child: AppPrimaryButton(
                              label: buttonLabel,
                              onPressed: onPressed,
                              icon: Icons.arrow_forward_rounded,
                              iconSize: 22,
                              height: 56,
                              backgroundColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              labelStyle: AppTypography.button(
                                color: AppColors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletPortrait(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE3EBF5)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F2746),
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(iconSize: 60, fontSize: 32, centered: true),
                const SizedBox(height: 16),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandBlue,
                    ),
                    children: const [
                      TextSpan(text: 'Create, Schedule &\nPublish with '),
                      TextSpan(
                        text: 'AI',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Generate social media posts in seconds, schedule them automatically, and publish across multiple platforms from one place.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    fontSize: 14.5,
                    height: 1.35,
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: Image.asset(
                    'assets/images/banner1.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFE),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE3EBF5)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _FeatureCard(
                        title: 'AI Post Creation',
                        subtitle: 'Create captions and creatives quickly.',
                        icon: Icons.auto_awesome_rounded,
                        colors: [Color(0xFF1E4ED8), Color(0xFF1A66F3)],
                        isFirst: true,
                        isLast: false,
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE3EBF5),
                        indent: 59,
                      ),
                      const _FeatureCard(
                        title: 'Auto Scheduling',
                        subtitle: 'Plan for the best posting time automatically.',
                        icon: Icons.calendar_month_rounded,
                        colors: [Color(0xFF2BC7D5), Color(0xFF39B4BD)],
                        isFirst: false,
                        isLast: false,
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE3EBF5),
                        indent: 59,
                      ),
                      const _FeatureCard(
                        title: 'Multi-Platform Publishing',
                        subtitle: 'Publish to multiple social channels together.',
                        icon: Icons.hub_rounded,
                        colors: [Color(0xFF1E4ED8), Color(0xFF1A66F3)],
                        isFirst: false,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF0F2B5B), Color(0xFF0F2B5B)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2639B4BD),
                        blurRadius: 18,
                        offset: Offset(0, 9),
                      ),
                    ],
                  ),
                  child: AppPrimaryButton(
                    label: buttonLabel,
                    onPressed: onPressed,
                    icon: Icons.arrow_forward_rounded,
                    iconSize: 22,
                    height: 56,
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    labelStyle: AppTypography.button(
                      color: AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Column(
            children: [
              const SizedBox(height: 2),
              const AppLogo(iconSize: 50, fontSize: 28, centered: true),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 23,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandBlue,
                  ),
                  children: const [
                    TextSpan(text: 'Create, Schedule &\nPublish with '),
                    TextSpan(
                      text: 'AI',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Generate social media posts in seconds, schedule them automatically, and publish across multiple platforms from one place.',
                textAlign: TextAlign.center,
                style: AppTypography.body(
                  fontSize: 12.6,
                  height: 1.26,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      flex: 12,
                      child: Image.asset(
                        'assets/images/banner1.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE3EBF5)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0E173A6B),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _FeatureCard(
                            title: 'AI Post Creation',
                            subtitle: 'Create captions and creatives quickly.',
                            icon: Icons.auto_awesome_rounded,
                            colors: [Color(0xFF1E4ED8), Color(0xFF1A66F3)],
                            isFirst: true,
                            isLast: false,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFE3EBF5),
                            indent: 59,
                          ),
                          const _FeatureCard(
                            title: 'Auto Scheduling',
                            subtitle:
                                'Plan for the best posting time automatically.',
                            icon: Icons.calendar_month_rounded,
                            colors: [Color(0xFF2BC7D5), Color(0xFF39B4BD)],
                            isFirst: false,
                            isLast: false,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFE3EBF5),
                            indent: 59,
                          ),
                          const _FeatureCard(
                            title: 'Multi-Platform Publishing',
                            subtitle:
                                'Publish to multiple social channels together.',
                            icon: Icons.hub_rounded,
                            colors: [Color(0xFF1E4ED8), Color(0xFF1A66F3)],
                            isFirst: false,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF0F2B5B), Color(0xFF0F2B5B)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2639B4BD),
                      blurRadius: 18,
                      offset: Offset(0, 9),
                    ),
                  ],
                ),
                child: AppPrimaryButton(
                  label: buttonLabel,
                  onPressed: onPressed,
                  icon: Icons.arrow_forward_rounded,
                  iconSize: 22,
                  height: 54,
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  labelStyle: AppTypography.button(
                    color: AppColors.white,
                    fontSize: 16,
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

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    this.isFirst = false,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 13,
        right: 13,
        top: isFirst ? 10 : 10,
        bottom: isLast ? 10 : 10,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: colors),
            ),
            child: Icon(icon, color: AppColors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.brandBlue,
                    fontSize: 14.6,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.1,
                    color: AppColors.mutedText,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
