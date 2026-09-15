import 'package:flutter/material.dart';

abstract final class AppBreakpoints {
  static const double mobileMax = 599;
  static const double tabletMin = 600;
  static const double desktopMin = 1100;

  static const double maxFormWidth = 520;
  static const double maxContentWidth = 1200;
  static const double maxDashboardWidth = 1380;
}

class AppResponsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppBreakpoints.tabletMin;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= AppBreakpoints.tabletMin && width < AppBreakpoints.desktopMin;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppBreakpoints.desktopMin;

  static bool isTabletOrLarger(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppBreakpoints.tabletMin;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppBreakpoints.desktopMin) {
      return 40;
    } else if (width >= AppBreakpoints.tabletMin) {
      return 28;
    } else {
      return 18;
    }
  }

  static double contentMaxWidth(
    BuildContext context, {
    double defaultMax = AppBreakpoints.maxContentWidth,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < AppBreakpoints.tabletMin) {
      return double.infinity;
    }
    return defaultMax;
  }

  static int gridColumns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppBreakpoints.desktopMin) {
      return desktop;
    } else if (width >= AppBreakpoints.tabletMin) {
      return tablet;
    } else {
      return mobile;
    }
  }

  static double responsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppBreakpoints.desktopMin) {
      return baseSize * 1.15;
    } else if (width >= AppBreakpoints.tabletMin) {
      return baseSize * 1.08;
    }
    return baseSize;
  }
}

extension AppResponsiveExtension on BuildContext {
  bool get isMobile => AppResponsive.isMobile(this);
  bool get isTablet => AppResponsive.isTablet(this);
  bool get isDesktop => AppResponsive.isDesktop(this);
  bool get isTabletOrLarger => AppResponsive.isTabletOrLarger(this);
  bool get isLandscape => AppResponsive.isLandscape(this);

  double get responsiveHorizontalPadding => AppResponsive.horizontalPadding(this);

  int gridColumns({int mobile = 1, int tablet = 2, int desktop = 3}) =>
      AppResponsive.gridColumns(
        this,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      );
}

class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    this.padding,
    this.useHorizontalPadding = true,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool useHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    final effectiveHorizontalPadding = useHorizontalPadding
        ? AppResponsive.horizontalPadding(context)
        : 0.0;

    final effectivePadding = padding != null
        ? padding!.add(EdgeInsets.symmetric(horizontal: effectiveHorizontalPadding))
        : EdgeInsets.symmetric(horizontal: effectiveHorizontalPadding);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      ),
    );
  }
}

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.desktopMin) {
          if (desktop != null) return desktop!(context);
          if (tablet != null) return tablet!(context);
          return mobile(context);
        }

        if (constraints.maxWidth >= AppBreakpoints.tabletMin) {
          if (tablet != null) return tablet!(context);
          return mobile(context);
        }

        return mobile(context);
      },
    );
  }
}
