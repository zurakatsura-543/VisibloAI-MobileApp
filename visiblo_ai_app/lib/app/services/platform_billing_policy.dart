import 'package:flutter/foundation.dart';

abstract final class PlatformBillingPolicy {
  static bool get usesSupportActivation =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}
