import 'package:flutter/material.dart';
import '../../../app/theme/app_responsive.dart';

abstract final class AuthViewSpacing {
  static const double pageHorizontal = 14;
  static const double pageTop = 12;
  static const double pageBottom = 20;

  static double adaptiveHorizontal(BuildContext context) =>
      context.responsiveHorizontalPadding;

  static EdgeInsets adaptivePagePadding(BuildContext context) => EdgeInsets.fromLTRB(
        context.responsiveHorizontalPadding,
        pageTop,
        context.responsiveHorizontalPadding,
        pageBottom,
      );

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(
    pageHorizontal,
    pageTop,
    pageHorizontal,
    pageBottom,
  );

  static const double cardGap = 10;
  static const double sectionGap = 12;
  static const double titleGap = 4;
}
