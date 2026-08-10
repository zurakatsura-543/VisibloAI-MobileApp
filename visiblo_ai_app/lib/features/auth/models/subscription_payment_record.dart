class SubscriptionPaymentRecord {
  const SubscriptionPaymentRecord({
    required this.planId,
    required this.billingCycle,
    required this.amountInr,
    required this.paidOnIso,
    this.status = 'Paid',
    this.invoiceId,
    this.invoiceNumber,
    this.businessName,
    this.businessLocation,
    this.currency = 'INR',
    this.canDownload = false,
  });

  final String planId;
  final String billingCycle;
  final int amountInr;
  final String paidOnIso;
  final String status;
  final String? invoiceId;
  final String? invoiceNumber;
  final String? businessName;
  final String? businessLocation;
  final String currency;
  final bool canDownload;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'planId': planId,
      'billingCycle': billingCycle,
      'amountInr': amountInr,
      'paidOnIso': paidOnIso,
      'status': status,
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'businessName': businessName,
      'businessLocation': businessLocation,
      'currency': currency,
      'canDownload': canDownload,
    };
  }

  factory SubscriptionPaymentRecord.fromMap(Map<String, dynamic> map) {
    return SubscriptionPaymentRecord(
      planId: map['planId'] as String? ?? 'growth',
      billingCycle: map['billingCycle'] as String? ?? 'monthly',
      amountInr: map['amountInr'] as int? ?? 5000,
      paidOnIso: map['paidOnIso'] as String? ?? '',
      status: map['status'] as String? ?? 'Paid',
      invoiceId: map['invoiceId'] as String?,
      invoiceNumber: map['invoiceNumber'] as String?,
      businessName: map['businessName'] as String?,
      businessLocation: map['businessLocation'] as String?,
      currency: map['currency'] as String? ?? 'INR',
      canDownload: map['canDownload'] as bool? ?? false,
    );
  }

  factory SubscriptionPaymentRecord.fromInvoiceMap(Map<String, dynamic> map) {
    final amount = map['amount'];
    final amountPaise = amount is int
        ? amount
        : int.tryParse(amount?.toString() ?? '') ?? 0;
    final planName = map['planName']?.toString().trim() ?? '';
    final planCode = map['planCode']?.toString().trim() ?? '';

    return SubscriptionPaymentRecord(
      planId: planCode.isNotEmpty ? planCode : planName.toLowerCase(),
      billingCycle: map['billingCycle'] as String? ?? 'monthly',
      amountInr: (amountPaise / 100).round(),
      paidOnIso:
          map['paidAt'] as String? ??
          map['issuedAt'] as String? ??
          '',
      status: _normalizeStatus(map['status']?.toString()),
      invoiceId: map['id'] as String?,
      invoiceNumber: map['invoiceNumber'] as String?,
      businessName: map['businessNameSnapshot'] as String?,
      businessLocation: map['businessLocationSnapshot'] as String?,
      currency: map['currency'] as String? ?? 'INR',
      canDownload:
          (map['id'] as String?)?.trim().isNotEmpty == true,
    );
  }

  SubscriptionPaymentRecord copyWith({
    String? planId,
    String? billingCycle,
    int? amountInr,
    String? paidOnIso,
    String? status,
    String? invoiceId,
    String? invoiceNumber,
    String? businessName,
    String? businessLocation,
    String? currency,
    bool? canDownload,
  }) {
    return SubscriptionPaymentRecord(
      planId: planId ?? this.planId,
      billingCycle: billingCycle ?? this.billingCycle,
      amountInr: amountInr ?? this.amountInr,
      paidOnIso: paidOnIso ?? this.paidOnIso,
      status: status ?? this.status,
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      businessName: businessName ?? this.businessName,
      businessLocation: businessLocation ?? this.businessLocation,
      currency: currency ?? this.currency,
      canDownload: canDownload ?? this.canDownload,
    );
  }
}

String _normalizeStatus(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) {
    return 'Paid';
  }
  return value
      .split(RegExp(r'[_\s]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) =>
            '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}
