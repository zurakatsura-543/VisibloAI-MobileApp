import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: Column(
          children: [
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const AppLogo(iconSize: 54, fontSize: 28, centered: true),
                  const SizedBox(height: 12),
                  Text(
                    'India’s AI Growth Platform for\nLocal Businesses',
                    textAlign: TextAlign.center,
                    style: AppTypography.body(
                      fontSize: AppTypography.bodyText,
                      height: 1.42,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const tickerHeight = 28.0;
                    const tickerSpacing = 2.0;
                    const aspectRatio = 0.92;
                    final maxWidth = math.min(constraints.maxWidth, 354.0);
                    final maxHeight = math.max(
                      0.0,
                      constraints.maxHeight - tickerHeight - tickerSpacing,
                    );
                    final mosaicHeight = math.min(
                      maxWidth / aspectRatio,
                      maxHeight,
                    );
                    final mosaicWidth = mosaicHeight * aspectRatio;

                    return Column(
                      children: [
                        SizedBox(
                          width: mosaicWidth,
                          height: mosaicHeight,
                          child: const _OnboardingPhotoMosaic(),
                        ),
                        const SizedBox(height: tickerSpacing),
                        const _AutoMovingCategoryStrip(),
                      ],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: AppPrimaryButton(label: buttonLabel, onPressed: onPressed),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(34, 0, 34, 18),
              child: Text.rich(
                TextSpan(
                  style: AppTypography.body(
                    fontSize: AppTypography.bodyTextCompact,
                    color: AppColors.mutedText,
                  ),
                  children: [
                    const TextSpan(text: 'By continuing, you agree to our '),
                    TextSpan(
                      text: 'Terms &\nConditions',
                      style: TextStyle(
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w700,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = onOpenTerms,
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy.',
                      style: TextStyle(
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w700,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = onOpenPrivacy,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPhotoMosaic extends StatelessWidget {
  const _OnboardingPhotoMosaic();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Flexible(
          flex: 24,
          child: _MosaicColumn(
            children: [
              _MosaicTile(assetPath: 'assets/images/site.png', flex: 22),
              _MosaicGap(),
              _MosaicTile(assetPath: 'assets/images/doctor.png', flex: 13),
            ],
          ),
        ),
        SizedBox(width: 4),
        Flexible(
          flex: 18,
          child: _MosaicColumn(
            children: [
              _MosaicTile(assetPath: 'assets/images/bakery.png', flex: 9),
              _MosaicGap(),
              _MosaicTile(assetPath: 'assets/images/office.png', flex: 7),
              _MosaicGap(),
              _MosaicTile(assetPath: 'assets/images/facial.png', flex: 10),
            ],
          ),
        ),
        SizedBox(width: 4),
        Flexible(
          flex: 22,
          child: _MosaicColumn(
            children: [
              _MosaicTile(assetPath: 'assets/images/mall.png', flex: 19),
              _MosaicGap(),
              _MosaicTile(assetPath: 'assets/images/coffee.png', flex: 4),
              _MosaicGap(),
              _MosaicTile(assetPath: 'assets/images/cake.png', flex: 12),
            ],
          ),
        ),
        SizedBox(width: 4),
        Flexible(
          flex: 19,
          child: _MosaicColumn(
            children: [
              _MosaicTile(assetPath: 'assets/images/flowers.png', flex: 9),
              _MosaicGap(),
              _MosaicTile(assetPath: 'assets/images/makeup.png', flex: 6),
              _MosaicGap(),
              _MosaicTile(assetPath: 'assets/images/parlour.png', flex: 8),
              _MosaicGap(),
              _MosaicTile(assetPath: 'assets/images/fitness.png', flex: 4),
            ],
          ),
        ),
      ],
    );
  }
}

class _MosaicColumn extends StatelessWidget {
  const _MosaicColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(children: children);
  }
}

class _MosaicTile extends StatelessWidget {
  const _MosaicTile({required this.assetPath, required this.flex});

  final String assetPath;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          width: double.infinity,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

class _MosaicGap extends StatelessWidget {
  const _MosaicGap();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 4);
  }
}

class _AutoMovingCategoryStrip extends StatefulWidget {
  const _AutoMovingCategoryStrip();

  @override
  State<_AutoMovingCategoryStrip> createState() =>
      _AutoMovingCategoryStripState();
}

class _AutoMovingCategoryStripState extends State<_AutoMovingCategoryStrip>
    with SingleTickerProviderStateMixin {
  static const _items = [
    'Construction',
    'Real Estate',
    'Bakery / Cafe',
    'Corporate Office',
    'Clinic / Dentist',
    'Salon / Spa',
    'Gym / Fitness',
    'Boutique / Fashion',
  ];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTypography.body(
      fontSize: AppTypography.bodyTextCompact,
      color: AppColors.text,
      fontWeight: FontWeight.w500,
    );

    final repeatedItems = [..._items, ..._items];
    final itemWidths = repeatedItems
        .map((item) => _estimateItemWidth(item, textStyle))
        .toList();
    final singleRunWidth = itemWidths
        .take(_items.length)
        .fold<double>(0, (total, width) => total + width);

    return ClipRect(
      child: SizedBox(
        height: 28,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset = -singleRunWidth * _controller.value;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: repeatedItems
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text('$item /', style: textStyle),
                        ),
                      )
                      .toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _estimateItemWidth(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: '$text /', style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width + 12;
  }
}
