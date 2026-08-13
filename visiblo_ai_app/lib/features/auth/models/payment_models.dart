class BillingPlanDefinition {
  const BillingPlanDefinition({
    required this.code,
    required this.key,
    required this.name,
    required this.monthlyPriceInr,
    required this.yearlyMonthlyPriceInr,
    this.yearlyTotalInr,
    required this.setupFeeLabel,
    required this.eyebrow,
    required this.description,
    required this.capacityLabel,
    required this.suitableFor,
    required this.features,
    this.recommended = false,
  });

  final String code;
  final String key;
  final String name;
  final int monthlyPriceInr;
  final int yearlyMonthlyPriceInr;
  final int? yearlyTotalInr;
  final String setupFeeLabel;
  final String eyebrow;
  final String description;
  final String capacityLabel;
  final String suitableFor;
  final List<String> features;
  final bool recommended;

  int priceFor(String billingCycle) {
    return normalizeBillingCycle(billingCycle) == 'yearly'
        ? yearlyMonthlyPriceInr
        : monthlyPriceInr;
  }

  int subtotalFor(String billingCycle) {
    final normalizedCycle = normalizeBillingCycle(billingCycle);
    if (normalizedCycle == 'yearly') {
      return yearlyTotalInr ?? yearlyMonthlyPriceInr * 12;
    }
    return monthlyPriceInr;
  }

  int annualSavingsInr() {
    final fullYear = monthlyPriceInr * 12;
    final discountedYear = subtotalFor('yearly');
    return fullYear - discountedYear;
  }

  static const plans = <BillingPlanDefinition>[
    BillingPlanDefinition(
      code: 'SINGLE',
      key: 'STARTER',
      name: 'Starter',
      monthlyPriceInr: 1999,
      yearlyMonthlyPriceInr: 1599,
      yearlyTotalInr: 19190,
      setupFeeLabel: 'Razorpay verified',
      eyebrow: 'Single business',
      description:
          'Best For: Small businesses starting their online growth journey.',
      capacityLabel: '1 Business Location',
      suitableFor: 'Small businesses, single-location shops, and startups',
      features: <String>[
        '1 Business Location',
        'Google Business Profile management',
        'Facebook and Instagram',
        '20 AI posts/month',
        'AI review reply suggestions',
      ],
    ),
    BillingPlanDefinition(
      code: 'PRO',
      key: 'GROWTH',
      name: 'Growth',
      monthlyPriceInr: 2999,
      yearlyMonthlyPriceInr: 2399,
      yearlyTotalInr: 28790,
      setupFeeLabel: 'Razorpay verified',
      eyebrow: 'Most popular',
      description:
          'Best For: Businesses looking for continuous inquiries and stronger local branding.',
      capacityLabel: '1 to 3 Business Locations',
      suitableFor: 'Growing businesses that want more leads and visibility',
      recommended: true,
      features: <String>[
        '1 to 3 Business Locations',
        'Everything in Starter PLUS',
        '60 AI posts/month',
        'AI review auto-reply',
        'Competitor analysis',
      ],
    ),
    BillingPlanDefinition(
      code: 'PREMIUM',
      key: 'PREMIUM',
      name: 'Business Pro',
      monthlyPriceInr: 4999,
      yearlyMonthlyPriceInr: 3999,
      yearlyTotalInr: 47990,
      setupFeeLabel: 'Razorpay verified',
      eyebrow: 'Full automation',
      description:
          'Best For: Businesses serious about dominating local search and generating continuous leads.',
      capacityLabel: 'Up to 5 Business Locations',
      suitableFor:
          'Serious businesses that want full automation and better growth',
      features: <String>[
        'Up to 5 Business Locations',
        'Everything in Growth PLUS',
        '150 AI posts/month',
        'AI auto post',
        'Advanced analytics dashboard',
      ],
    ),
  ];

  static BillingPlanDefinition forCode(String? rawCode) {
    final normalized = (rawCode ?? '').trim().toUpperCase();
    for (final plan in plans) {
      if (plan.code == normalized || plan.key == normalized) {
        return plan;
      }
    }
    return plans.first;
  }

  static String recommendedCodeForProfileCount(int profiles) {
    if (profiles <= 1) {
      return 'SINGLE';
    }
    if (profiles <= 3) {
      return 'PRO';
    }
    if (profiles <= 5) {
      return 'PREMIUM';
    }
    return 'PREMIUM';
  }

  factory BillingPlanDefinition.fromCatalog(BillingPlanCatalog catalog) {
    final monthlyInr = ((catalog.pricing.monthly ?? 0) / 100).round();
    final yearlyTotalInr = ((catalog.pricing.yearly ?? 0) / 100).round();
    final yearlyMonthlyInr = yearlyTotalInr > 0
        ? (yearlyTotalInr / 12).round()
        : monthlyInr;

    return BillingPlanDefinition(
      code: catalog.code.toUpperCase(),
      key: catalog.code.toUpperCase(),
      name: catalog.displayName,
      monthlyPriceInr: monthlyInr,
      yearlyMonthlyPriceInr: yearlyMonthlyInr,
      yearlyTotalInr: yearlyTotalInr > 0 ? yearlyTotalInr : null,
      setupFeeLabel: 'Razorpay verified',
      eyebrow: catalog.locationQuota <= 1
          ? 'Single business'
          : catalog.locationQuota >= 999
          ? 'Custom scale'
          : '${catalog.locationQuota} business locations',
      description:
          'Use this plan across ${catalog.locationQuota >= 999 ? 'unlimited' : catalog.locationQuota} activated business locations with backend-enforced billing limits.',
      capacityLabel: catalog.locationQuota >= 999
          ? 'Unlimited business locations'
          : 'Up to ${catalog.locationQuota} business locations',
      suitableFor: catalog.locationQuota <= 1
          ? 'Single-location businesses'
          : catalog.locationQuota <= 3
          ? 'Growing multi-location businesses'
          : catalog.locationQuota <= 5
          ? 'High-growth teams'
          : 'Agencies and enterprise operators',
      recommended: catalog.code.toUpperCase() == 'PRO',
      features: <String>[
        '${catalog.usageLimits.aiContentCreationsPerMonth} AI content creations / month',
        '${catalog.usageLimits.keywordsLimit} tracked keywords',
        '${catalog.usageLimits.keywordChecksPerMonth} keyword ranking checks / month',
        '${catalog.usageLimits.heatmapScansPerMonth} heatmap scans / month',
      ],
    );
  }
}

class BillingOrderResponse {
  const BillingOrderResponse({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.razorpayKeyId,
    this.subtotalAmount = 0,
    this.payableAmount = 0,
    this.plan = '',
    this.billingCycle = 'monthly',
    this.checkoutType = 'MANUAL',
    this.billingMode = 'MANUAL',
    this.couponCode = '',
  });

  final String orderId;
  final int amount;
  final String currency;
  final String razorpayKeyId;
  final int subtotalAmount;
  final int payableAmount;
  final String plan;
  final String billingCycle;
  final String checkoutType;
  final String billingMode;
  final String couponCode;

  factory BillingOrderResponse.fromMap(Map<String, dynamic> map) {
    return BillingOrderResponse(
      orderId: _stringValue(map['orderId']),
      amount: _intValue(map['amount']),
      currency: _stringValue(map['currency']).isEmpty
          ? 'INR'
          : _stringValue(map['currency']).toUpperCase(),
      razorpayKeyId: _stringValue(map['razorpayKeyId']),
      subtotalAmount: _intValue(map['subtotalAmount']),
      payableAmount: _intValue(map['payableAmount']),
      plan: _stringValue(map['plan']).toUpperCase(),
      billingCycle: normalizeBillingCycle(_stringValue(map['billingCycle'])),
      checkoutType: _stringValue(map['checkoutType']).toUpperCase(),
      billingMode: _stringValue(map['billingMode']).toUpperCase(),
      couponCode: _stringValue(map['couponCode']).toUpperCase(),
    );
  }
}

class BillingWarning {
  const BillingWarning({
    required this.code,
    required this.severity,
    required this.title,
    required this.message,
    required this.suggestedAction,
  });

  final String code;
  final String severity;
  final String title;
  final String message;
  final String suggestedAction;

  factory BillingWarning.fromMap(Map<String, dynamic> map) {
    return BillingWarning(
      code: _stringValue(map['code']).toUpperCase(),
      severity: _stringValue(map['severity']).toLowerCase(),
      title: _stringValue(map['title']),
      message: _stringValue(map['message']),
      suggestedAction: _stringValue(map['suggestedAction']).toUpperCase(),
    );
  }
}

class BillingUiActions {
  const BillingUiActions({
    required this.canStartTrial,
    required this.canPayManual,
    required this.canEnableAutopay,
    required this.canCancelAutopay,
    required this.canResumeAutopay,
    required this.canRetryPayment,
    required this.canUpgrade,
  });

  final bool canStartTrial;
  final bool canPayManual;
  final bool canEnableAutopay;
  final bool canCancelAutopay;
  final bool canResumeAutopay;
  final bool canRetryPayment;
  final bool canUpgrade;

  factory BillingUiActions.fromMap(Map<String, dynamic> map) {
    return BillingUiActions(
      canStartTrial: _boolValue(map['canStartTrial']),
      canPayManual: _boolValue(map['canPayManual']),
      canEnableAutopay: _boolValue(map['canEnableAutopay']),
      canCancelAutopay: _boolValue(map['canCancelAutopay']),
      canResumeAutopay: _boolValue(map['canResumeAutopay']),
      canRetryPayment: _boolValue(map['canRetryPayment']),
      canUpgrade: _boolValue(map['canUpgrade']),
    );
  }
}

class BillingUiState {
  const BillingUiState({
    required this.state,
    required this.tone,
    required this.warnings,
    required this.actions,
  });

  final String state;
  final String tone;
  final List<BillingWarning> warnings;
  final BillingUiActions actions;

  bool get hasWarnings => warnings.isNotEmpty;

  factory BillingUiState.fromMap(Map<String, dynamic> map) {
    final warningsRaw = map['warnings'];
    final warnings = warningsRaw is List
        ? warningsRaw
              .map((item) => BillingWarning.fromMap(_mapValue(item)))
              .toList(growable: false)
        : const <BillingWarning>[];

    return BillingUiState(
      state: _stringValue(map['state']).toUpperCase(),
      tone: _stringValue(map['tone']).toLowerCase(),
      warnings: warnings,
      actions: BillingUiActions.fromMap(_mapValue(map['actions'])),
    );
  }
}

class BillingPlanPricing {
  const BillingPlanPricing({required this.monthly, required this.yearly});

  final int? monthly;
  final int? yearly;

  factory BillingPlanPricing.fromMap(Map<String, dynamic> map) {
    final monthly = _nullableIntValue(map['monthly']);
    final yearly = _nullableIntValue(map['yearly']);
    return BillingPlanPricing(monthly: monthly, yearly: yearly);
  }
}

class BillingPlanUsageLimits {
  const BillingPlanUsageLimits({
    required this.aiContentCreationsPerMonth,
    required this.keywordsLimit,
    required this.keywordChecksPerMonth,
    required this.heatmapScansPerMonth,
  });

  final int aiContentCreationsPerMonth;
  final int keywordsLimit;
  final int keywordChecksPerMonth;
  final int heatmapScansPerMonth;

  factory BillingPlanUsageLimits.fromMap(Map<String, dynamic> map) {
    return BillingPlanUsageLimits(
      aiContentCreationsPerMonth: _intValue(map['aiContentCreationsPerMonth']),
      keywordsLimit: _intValue(map['keywordsLimit']),
      keywordChecksPerMonth: _intValue(map['keywordChecksPerMonth']),
      heatmapScansPerMonth: _intValue(map['heatmapScansPerMonth']),
    );
  }
}

class BillingPlanCatalog {
  const BillingPlanCatalog({
    required this.code,
    required this.displayName,
    required this.pricing,
    required this.locationQuota,
    required this.usageLimits,
  });

  final String code;
  final String displayName;
  final BillingPlanPricing pricing;
  final int locationQuota;
  final BillingPlanUsageLimits usageLimits;

  factory BillingPlanCatalog.fromMap(Map<String, dynamic> map) {
    return BillingPlanCatalog(
      code: _stringValue(map['code']).toUpperCase(),
      displayName: _stringValue(map['displayName']),
      pricing: BillingPlanPricing.fromMap(_mapValue(map['pricing'])),
      locationQuota: _intValue(map['locationQuota']),
      usageLimits: BillingPlanUsageLimits.fromMap(
        _mapValue(map['usageLimits']),
      ),
    );
  }
}

class BillingLocationQuota {
  const BillingLocationQuota({
    required this.used,
    required this.max,
    required this.remaining,
  });

  final int used;
  final int max;
  final int remaining;

  factory BillingLocationQuota.fromMap(Map<String, dynamic> map) {
    return BillingLocationQuota(
      used: _intValue(map['used']),
      max: _intValue(map['max']),
      remaining: _intValue(map['remaining']),
    );
  }
}

class BillingCheckoutSubscription {
  const BillingCheckoutSubscription({
    required this.id,
    required this.plan,
    required this.planDisplayName,
    required this.status,
    required this.billingCycle,
    required this.billingMode,
    required this.autopayEnabled,
    required this.cancelAtPeriodEnd,
    this.razorpaySubscriptionId,
    this.paidAt,
    this.expiresAt,
    this.cancelReason,
  });

  final String id;
  final String plan;
  final String planDisplayName;
  final String status;
  final String billingCycle;
  final String billingMode;
  final bool autopayEnabled;
  final String? razorpaySubscriptionId;
  final String? paidAt;
  final String? expiresAt;
  final bool cancelAtPeriodEnd;
  final String? cancelReason;

  factory BillingCheckoutSubscription.fromMap(Map<String, dynamic> map) {
    return BillingCheckoutSubscription(
      id: _stringValue(map['id']),
      plan: _stringValue(map['plan']).toUpperCase(),
      planDisplayName: _stringValue(map['planDisplayName']),
      status: _stringValue(map['status']).toUpperCase(),
      billingCycle: normalizeBillingCycle(_stringValue(map['billingCycle'])),
      billingMode: _stringValue(map['billingMode']).toUpperCase(),
      autopayEnabled: _boolValue(map['autopayEnabled']),
      razorpaySubscriptionId: _nullableStringValue(
        map['razorpaySubscriptionId'],
      ),
      paidAt: _nullableStringValue(map['paidAt']),
      expiresAt: _nullableStringValue(map['expiresAt']),
      cancelAtPeriodEnd: _boolValue(map['cancelAtPeriodEnd']),
      cancelReason: _nullableStringValue(map['cancelReason']),
    );
  }
}

class BillingCheckoutTrial {
  const BillingCheckoutTrial({required this.eligible, required this.active});

  final bool eligible;
  final bool active;

  factory BillingCheckoutTrial.fromMap(Map<String, dynamic> map) {
    return BillingCheckoutTrial(
      eligible: _boolValue(map['eligible']),
      active: _boolValue(map['active']),
    );
  }
}

class BillingPaymentModeInfo {
  const BillingPaymentModeInfo({
    required this.available,
    required this.label,
    required this.description,
    this.currentStatus,
  });

  final bool available;
  final String label;
  final String description;
  final String? currentStatus;

  factory BillingPaymentModeInfo.fromMap(Map<String, dynamic> map) {
    return BillingPaymentModeInfo(
      available: _boolValue(map['available']),
      label: _stringValue(map['label']),
      description: _stringValue(map['description']),
      currentStatus: _nullableStringValue(map['currentStatus']),
    );
  }
}

class BillingPaymentModes {
  const BillingPaymentModes({required this.manual, required this.autopay});

  final BillingPaymentModeInfo manual;
  final BillingPaymentModeInfo autopay;

  factory BillingPaymentModes.fromMap(Map<String, dynamic> map) {
    return BillingPaymentModes(
      manual: BillingPaymentModeInfo.fromMap(_mapValue(map['manual'])),
      autopay: BillingPaymentModeInfo.fromMap(_mapValue(map['autopay'])),
    );
  }
}

class BillingCheckoutBusiness {
  const BillingCheckoutBusiness({
    required this.id,
    required this.name,
    this.primaryDomain,
  });

  final String id;
  final String name;
  final String? primaryDomain;

  factory BillingCheckoutBusiness.fromMap(Map<String, dynamic> map) {
    return BillingCheckoutBusiness(
      id: _stringValue(map['id']),
      name: _stringValue(map['name']),
      primaryDomain: _nullableStringValue(map['primaryDomain']),
    );
  }
}

class BillingCheckoutContext {
  const BillingCheckoutContext({
    required this.business,
    required this.trial,
    required this.recommendedMode,
    required this.uiState,
    required this.paymentModes,
    required this.plans,
    this.subscription,
    this.locationQuota,
  });

  final BillingCheckoutBusiness business;
  final BillingCheckoutSubscription? subscription;
  final BillingCheckoutTrial trial;
  final BillingLocationQuota? locationQuota;
  final String recommendedMode;
  final BillingUiState uiState;
  final BillingPaymentModes paymentModes;
  final List<BillingPlanCatalog> plans;

  factory BillingCheckoutContext.fromMap(Map<String, dynamic> map) {
    final plansRaw = map['plans'];
    final plans = plansRaw is List
        ? plansRaw
              .map((item) => BillingPlanCatalog.fromMap(_mapValue(item)))
              .toList(growable: false)
        : const <BillingPlanCatalog>[];

    final subscriptionMap = _mapValue(map['subscription']);
    final quotaMap = _mapValue(map['locationQuota']);

    return BillingCheckoutContext(
      business: BillingCheckoutBusiness.fromMap(_mapValue(map['business'])),
      subscription: subscriptionMap.isEmpty
          ? null
          : BillingCheckoutSubscription.fromMap(subscriptionMap),
      trial: BillingCheckoutTrial.fromMap(_mapValue(map['trial'])),
      locationQuota: quotaMap.isEmpty
          ? null
          : BillingLocationQuota.fromMap(quotaMap),
      recommendedMode: _stringValue(map['recommendedMode']).toUpperCase(),
      uiState: BillingUiState.fromMap(_mapValue(map['uiState'])),
      paymentModes: BillingPaymentModes.fromMap(_mapValue(map['paymentModes'])),
      plans: plans,
    );
  }
}

class BillingStatusSubscription {
  const BillingStatusSubscription({
    required this.id,
    required this.businessId,
    required this.plan,
    required this.status,
    required this.billingCycle,
    this.paidAt,
    this.expiresAt,
    this.activationSource,
  });

  final String id;
  final String businessId;
  final String plan;
  final String status;
  final String billingCycle;
  final String? paidAt;
  final String? expiresAt;
  final String? activationSource;

  factory BillingStatusSubscription.fromMap(Map<String, dynamic> map) {
    return BillingStatusSubscription(
      id: _stringValue(map['id']),
      businessId: _stringValue(map['businessId']),
      plan: _stringValue(map['plan']).toUpperCase(),
      status: _stringValue(map['status']).toUpperCase(),
      billingCycle: normalizeBillingCycle(_stringValue(map['billingCycle'])),
      paidAt: _nullableStringValue(map['paidAt']),
      expiresAt: _nullableStringValue(map['expiresAt']),
      activationSource: _nullableStringValue(map['activationSource']),
    );
  }
}

class BillingAutopayStatus {
  const BillingAutopayStatus({
    required this.enabled,
    this.razorpaySubscriptionId,
    this.nextBillingAt,
    this.cancelRequested = false,
  });

  final bool enabled;
  final String? razorpaySubscriptionId;
  final String? nextBillingAt;
  final bool cancelRequested;

  factory BillingAutopayStatus.fromMap(Map<String, dynamic> map) {
    return BillingAutopayStatus(
      enabled: _boolValue(map['enabled']),
      razorpaySubscriptionId: _nullableStringValue(
        map['razorpaySubscriptionId'],
      ),
      nextBillingAt: _nullableStringValue(map['nextBillingAt']),
      cancelRequested: _boolValue(map['cancelRequested']),
    );
  }
}

class BillingSubscriptionStatus {
  const BillingSubscriptionStatus({
    required this.uiState,
    this.subscription,
    this.autopay,
  });

  final BillingStatusSubscription? subscription;
  final BillingAutopayStatus? autopay;
  final BillingUiState uiState;

  factory BillingSubscriptionStatus.fromMap(Map<String, dynamic> map) {
    final subscriptionMap = _mapValue(map['subscription']);
    final autopayMap = _mapValue(map['autopay']);
    return BillingSubscriptionStatus(
      subscription: subscriptionMap.isEmpty
          ? null
          : BillingStatusSubscription.fromMap(subscriptionMap),
      autopay: autopayMap.isEmpty
          ? null
          : BillingAutopayStatus.fromMap(autopayMap),
      uiState: BillingUiState.fromMap(_mapValue(map['uiState'])),
    );
  }
}

class BillingUsageFeature {
  const BillingUsageFeature({
    required this.feature,
    required this.featureLabel,
    required this.used,
    required this.limit,
    required this.remaining,
    required this.canUse,
    required this.warningLevel,
    required this.warningThresholds,
    this.resetsAt,
  });

  final String feature;
  final String featureLabel;
  final int used;
  final int limit;
  final int remaining;
  final bool canUse;
  final String warningLevel;
  final BillingUsageWarningThresholds warningThresholds;
  final String? resetsAt;

  factory BillingUsageFeature.fromMap(Map<String, dynamic> map) {
    return BillingUsageFeature(
      feature: _stringValue(map['feature']).toUpperCase(),
      featureLabel: _stringValue(map['featureLabel']),
      used: _intValue(map['used']),
      limit: _intValue(map['limit']),
      remaining: _intValue(map['remaining']),
      canUse: _boolValue(map['canUse']),
      warningLevel: _stringValue(map['warningLevel']).toUpperCase(),
      warningThresholds: BillingUsageWarningThresholds.fromMap(
        _mapValue(map['warningThresholds']),
      ),
      resetsAt: _nullableStringValue(map['resetsAt']),
    );
  }
}

class BillingUsageWarningThresholds {
  const BillingUsageWarningThresholds({
    required this.half,
    required this.ninety,
  });

  final int half;
  final int ninety;

  factory BillingUsageWarningThresholds.fromMap(Map<String, dynamic> map) {
    return BillingUsageWarningThresholds(
      half: _intValue(map['half']),
      ninety: _intValue(map['ninety']),
    );
  }
}

class BillingPeriodInfo {
  const BillingPeriodInfo({
    required this.key,
    required this.startsAt,
    required this.endsAt,
  });

  final String key;
  final String startsAt;
  final String endsAt;

  factory BillingPeriodInfo.fromMap(Map<String, dynamic> map) {
    return BillingPeriodInfo(
      key: _stringValue(map['key']),
      startsAt: _stringValue(map['startsAt']),
      endsAt: _stringValue(map['endsAt']),
    );
  }
}

class BillingFeatureEntitlement {
  const BillingFeatureEntitlement({
    required this.feature,
    required this.included,
    required this.label,
    required this.upgradeMessage,
  });

  final String feature;
  final bool included;
  final String label;
  final String upgradeMessage;

  factory BillingFeatureEntitlement.fromMap(Map<String, dynamic> map) {
    return BillingFeatureEntitlement(
      feature: _stringValue(map['feature']).toUpperCase(),
      included: _boolValue(map['included']),
      label: _stringValue(map['label']),
      upgradeMessage: _stringValue(map['upgradeMessage']),
    );
  }
}

class BillingUsageInfo {
  const BillingUsageInfo({
    required this.businessId,
    required this.locked,
    required this.subscriptionStatus,
    required this.plan,
    required this.planDisplayName,
    required this.period,
    required this.featureEntitlements,
    this.locationQuota,
    required this.aiPosts,
    required this.keywords,
    required this.keywordChecks,
    required this.heatmapScans,
  });

  final String businessId;
  final bool locked;
  final String subscriptionStatus;
  final String plan;
  final String planDisplayName;
  final BillingPeriodInfo period;
  final BillingLocationQuota? locationQuota;
  final Map<String, BillingFeatureEntitlement> featureEntitlements;
  final BillingUsageFeature aiPosts;
  final BillingUsageFeature keywords;
  final BillingUsageFeature keywordChecks;
  final BillingUsageFeature heatmapScans;

  factory BillingUsageInfo.fromMap(Map<String, dynamic> map) {
    final entitlementsMap = _mapValue(map['featureEntitlements']);
    final parsedEntitlements = <String, BillingFeatureEntitlement>{};
    entitlementsMap.forEach((key, value) {
      parsedEntitlements[key] = BillingFeatureEntitlement.fromMap(
        _mapValue(value),
      );
    });

    final quotaMap = _mapValue(map['locationQuota']);
    final featuresMap = _mapValue(map['features']);
    final scanMap = _mapValue(map['scanBudgets']);

    return BillingUsageInfo(
      businessId: _stringValue(map['businessId']),
      locked: _boolValue(map['locked']),
      subscriptionStatus: _stringValue(map['subscriptionStatus']).toUpperCase(),
      plan: _stringValue(map['plan']).toUpperCase(),
      planDisplayName: _stringValue(map['planDisplayName']),
      period: BillingPeriodInfo.fromMap(_mapValue(map['period'])),
      locationQuota: quotaMap.isEmpty
          ? null
          : BillingLocationQuota.fromMap(quotaMap),
      featureEntitlements: parsedEntitlements,
      aiPosts: BillingUsageFeature.fromMap(_mapValue(featuresMap['aiPosts'])),
      keywords: BillingUsageFeature.fromMap(_mapValue(featuresMap['keywords'])),
      keywordChecks: BillingUsageFeature.fromMap(
        _mapValue(scanMap['keywordChecks']),
      ),
      heatmapScans: BillingUsageFeature.fromMap(
        _mapValue(scanMap['heatmapScans']),
      ),
    );
  }
}

class BillingSubscriptionCheckoutResponse {
  const BillingSubscriptionCheckoutResponse({
    required this.ok,
    required this.checkoutType,
    required this.billingMode,
    required this.plan,
    required this.billingCycle,
    required this.businessId,
    required this.razorpayKeyId,
    required this.customerId,
    required this.subscriptionId,
    required this.razorpayPlanId,
    required this.razorpaySubscriptionId,
    required this.status,
    required this.mandateStatus,
    this.shortUrl,
    this.notes = const <String, String>{},
    this.alreadyActive = false,
    this.subscription,
    this.message,
    this.resumed = false,
    this.uiState,
  });

  final bool ok;
  final String checkoutType;
  final String billingMode;
  final String plan;
  final String billingCycle;
  final String businessId;
  final String razorpayKeyId;
  final String customerId;
  final String subscriptionId;
  final String razorpayPlanId;
  final String razorpaySubscriptionId;
  final String status;
  final String mandateStatus;
  final String? shortUrl;
  final Map<String, String> notes;
  final bool alreadyActive;
  final BillingSubscriptionCheckoutActiveSubscription? subscription;
  final String? message;
  final bool resumed;
  final BillingUiState? uiState;

  factory BillingSubscriptionCheckoutResponse.fromMap(
    Map<String, dynamic> map,
  ) {
    final notesMap = _mapValue(
      map['notes'],
    ).map((key, value) => MapEntry(key, _stringValue(value)));
    final subscriptionMap = _mapValue(map['subscription']);
    final uiStateMap = _mapValue(map['uiState']);

    return BillingSubscriptionCheckoutResponse(
      ok: _boolValue(map['ok']),
      checkoutType: _stringValue(map['checkoutType']).toUpperCase(),
      billingMode: _stringValue(map['billingMode']).toUpperCase(),
      plan: _stringValue(map['plan']).toUpperCase(),
      billingCycle: normalizeBillingCycle(_stringValue(map['billingCycle'])),
      businessId: _stringValue(map['businessId']),
      razorpayKeyId: _stringValue(map['razorpayKeyId']),
      customerId: _stringValue(map['customerId']),
      subscriptionId: _stringValue(map['subscriptionId']),
      razorpayPlanId: _stringValue(map['razorpayPlanId']),
      razorpaySubscriptionId: _stringValue(map['razorpaySubscriptionId']),
      status: _stringValue(map['status']).toUpperCase(),
      mandateStatus: _stringValue(map['mandateStatus']).toUpperCase(),
      shortUrl: _nullableStringValue(map['shortUrl']),
      notes: notesMap,
      alreadyActive: _boolValue(map['alreadyActive']),
      subscription: subscriptionMap.isEmpty
          ? null
          : BillingSubscriptionCheckoutActiveSubscription.fromMap(
              subscriptionMap,
            ),
      message: _nullableStringValue(map['message']),
      resumed: _boolValue(map['resumed']),
      uiState: uiStateMap.isEmpty ? null : BillingUiState.fromMap(uiStateMap),
    );
  }
}

class BillingSubscriptionCheckoutActiveSubscription {
  const BillingSubscriptionCheckoutActiveSubscription({
    required this.id,
    required this.businessId,
    required this.plan,
    required this.billingCycle,
    required this.billingMode,
    required this.razorpaySubscriptionId,
    this.currentPeriodEnd,
    this.nextBillingAt,
    this.status,
    this.expiresAt,
  });

  final String id;
  final String businessId;
  final String plan;
  final String billingCycle;
  final String billingMode;
  final String razorpaySubscriptionId;
  final String? currentPeriodEnd;
  final String? nextBillingAt;
  final String? status;
  final String? expiresAt;

  factory BillingSubscriptionCheckoutActiveSubscription.fromMap(
    Map<String, dynamic> map,
  ) {
    return BillingSubscriptionCheckoutActiveSubscription(
      id: _stringValue(map['id']),
      businessId: _stringValue(map['businessId']),
      plan: _stringValue(map['plan']).toUpperCase(),
      billingCycle: normalizeBillingCycle(_stringValue(map['billingCycle'])),
      billingMode: _stringValue(map['billingMode']).toUpperCase(),
      razorpaySubscriptionId: _stringValue(map['razorpaySubscriptionId']),
      currentPeriodEnd: _nullableStringValue(map['currentPeriodEnd']),
      nextBillingAt: _nullableStringValue(map['nextBillingAt']),
      status: _nullableStringValue(map['status']),
      expiresAt: _nullableStringValue(map['expiresAt']),
    );
  }
}

class BillingCoupon {
  const BillingCoupon({
    required this.code,
    required this.discountType,
    required this.discountValue,
  });

  final String code;
  final String discountType;
  final int discountValue;

  factory BillingCoupon.fromMap(Map<String, dynamic> map) {
    return BillingCoupon(
      code: _stringValue(map['code']).toUpperCase(),
      discountType: _stringValue(map['discountType']).toLowerCase(),
      discountValue: _intValue(map['discountValue']),
    );
  }
}

class BillingCouponValidationResult {
  const BillingCouponValidationResult({
    required this.valid,
    required this.skipPayment,
    required this.discountAmountPaise,
    required this.finalAmountPaise,
    this.coupon,
    this.errorMessage = '',
  });

  final bool valid;
  final bool skipPayment;
  final int discountAmountPaise;
  final int finalAmountPaise;
  final BillingCoupon? coupon;
  final String errorMessage;

  bool get hasDiscount => discountAmountPaise > 0;

  factory BillingCouponValidationResult.fromMap(Map<String, dynamic> map) {
    final couponMap = _mapValue(map['coupon']);
    return BillingCouponValidationResult(
      valid: _boolValue(map['valid']),
      skipPayment: _boolValue(map['skipPayment']),
      discountAmountPaise: _intValue(map['discountAmount']),
      finalAmountPaise: _intValue(map['finalAmount']),
      coupon: couponMap.isEmpty ? null : BillingCoupon.fromMap(couponMap),
      errorMessage: _stringValue(map['error']).isNotEmpty
          ? _stringValue(map['error'])
          : _stringValue(map['message']),
    );
  }
}

Map<String, dynamic> _mapValue(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

String? _nullableStringValue(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int? _nullableIntValue(Object? value) {
  if (value == null) {
    return null;
  }
  return _intValue(value);
}

String _stringValue(Object? value) {
  return value?.toString().trim() ?? '';
}

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(_stringValue(value)) ?? 0;
}

bool _boolValue(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final normalized = _stringValue(value).toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}

String normalizeBillingCycle(String? value) {
  return (value ?? '').trim().toLowerCase() == 'yearly' ? 'yearly' : 'monthly';
}
