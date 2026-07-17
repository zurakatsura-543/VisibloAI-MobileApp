import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.iconSize = 40,
    this.fontSize = 24,
    this.centered = false,
  });

  final double iconSize;
  final double fontSize;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/icons/brand_mark.png',
      height: iconSize,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    return centered ? Center(child: logo) : logo;
  }
}
