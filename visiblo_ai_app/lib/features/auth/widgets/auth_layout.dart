import 'package:flutter/material.dart';

abstract final class AuthViewSpacing {
  static const double pageHorizontal = 14;
  static const double pageTop = 12;
  static const double pageBottom = 20;

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
