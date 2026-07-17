class SubscriptionPaymentRecord {
  const SubscriptionPaymentRecord({
    required this.planId,
    required this.billingCycle,
    required this.amountInr,
    required this.paidOnIso,
    this.status = 'Paid',
  });

  final String planId;
  final String billingCycle;
  final int amountInr;
  final String paidOnIso;
  final String status;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'planId': planId,
      'billingCycle': billingCycle,
      'amountInr': amountInr,
      'paidOnIso': paidOnIso,
      'status': status,
    };
  }

  factory SubscriptionPaymentRecord.fromMap(Map<String, dynamic> map) {
    return SubscriptionPaymentRecord(
      planId: map['planId'] as String? ?? 'growth',
      billingCycle: map['billingCycle'] as String? ?? 'monthly',
      amountInr: map['amountInr'] as int? ?? 5000,
      paidOnIso: map['paidOnIso'] as String? ?? '',
      status: map['status'] as String? ?? 'Paid',
    );
  }

  SubscriptionPaymentRecord copyWith({
    String? planId,
    String? billingCycle,
    int? amountInr,
    String? paidOnIso,
    String? status,
  }) {
    return SubscriptionPaymentRecord(
      planId: planId ?? this.planId,
      billingCycle: billingCycle ?? this.billingCycle,
      amountInr: amountInr ?? this.amountInr,
      paidOnIso: paidOnIso ?? this.paidOnIso,
      status: status ?? this.status,
    );
  }
}
