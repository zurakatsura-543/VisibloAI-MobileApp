import 'package:flutter/foundation.dart';

/// Centralized configuration location for Apple In-App Purchase product IDs
/// and plan mappings for Visiblo AI iOS subscriptions.
///
/// Update these product IDs if custom product IDs are configured in App Store Connect.
abstract class AppleIapConfig {
  // Visiblo Plan Keys
  static const String planStarter = 'STARTER';
  static const String planGrowth = 'GROWTH';
  static const String planBusinessPro = 'BUSINESS_PRO';

  // App Store Connect Product Identifiers
  static const String productIdStarterMonthly = 'com.visiblo.ai.starter.monthly';
  static const String productIdStarterYearly = 'com.visiblo.ai.starter.yearly';

  static const String productIdGrowthMonthly = 'com.visiblo.ai.growth.monthly';
  static const String productIdGrowthYearly = 'com.visiblo.ai.growth.yearly';

  static const String productIdBusinessMonthly = 'com.visiblo.ai.business.monthly';
  static const String productIdBusinessYearly = 'com.visiblo.ai.business.yearly';

  /// All iOS product IDs to query from StoreKit
  static Set<String> get allProductIds => <String>{
        productIdStarterMonthly,
        productIdStarterYearly,
        productIdGrowthMonthly,
        productIdGrowthYearly,
        productIdBusinessMonthly,
        productIdBusinessYearly,
      };

  /// Returns the Apple product ID for a given plan and billing cycle
  static String getProductId({
    required String plan,
    required String billingCycle,
  }) {
    final normalizedPlan = plan.trim().toUpperCase();
    final isYearly = billingCycle.trim().toLowerCase() == 'yearly' ||
        billingCycle.trim().toLowerCase() == 'year' ||
        billingCycle.trim().toLowerCase() == 'annually';

    switch (normalizedPlan) {
      case 'STARTER':
        return isYearly ? productIdStarterYearly : productIdStarterMonthly;
      case 'GROWTH':
        return isYearly ? productIdGrowthYearly : productIdGrowthMonthly;
      case 'BUSINESS_PRO':
      case 'BUSINESS':
      case 'PRO':
        return isYearly ? productIdBusinessYearly : productIdBusinessMonthly;
      default:
        debugPrint('AppleIapConfig: Unknown plan $plan, defaulting to starter');
        return isYearly ? productIdStarterYearly : productIdStarterMonthly;
    }
  }

  /// Map an Apple Product ID back to Visiblo plan name
  static String getPlanFromProductId(String productId) {
    if (productId.contains('starter')) return planStarter;
    if (productId.contains('growth')) return planGrowth;
    if (productId.contains('business')) return planBusinessPro;
    return planStarter;
  }

  /// Map an Apple Product ID back to billing cycle ('monthly' or 'yearly')
  static String getBillingCycleFromProductId(String productId) {
    if (productId.contains('yearly') || productId.contains('annual')) {
      return 'yearly';
    }
    return 'monthly';
  }
}
