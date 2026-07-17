// Models for the GBP Audit API response.
//
// These mirror the TypeScript interfaces in `src/api/auditApi.ts` on the
// web dashboard so both clients consume the same backend shape.

class AuditFinding {
  const AuditFinding({
    required this.status,
    required this.label,
    required this.detail,
    this.evidence,
    this.action,
  });

  final String status; // 'pass' | 'warning' | 'fail'
  final String label;
  final String detail;
  final String? evidence;
  final String? action;

  factory AuditFinding.fromMap(Map<String, dynamic> map) {
    return AuditFinding(
      status: (map['status'] ?? 'warning').toString(),
      label: (map['label'] ?? '').toString(),
      detail: (map['detail'] ?? '').toString(),
      evidence: map['evidence']?.toString(),
      action: map['action']?.toString(),
    );
  }
}

class AuditSection {
  const AuditSection({
    required this.key,
    required this.title,
    required this.score,
    required this.status,
    required this.findings,
    this.suggestions,
    this.currentValue,
    this.meta,
    this.weight,
    this.impact,
  });

  final String key;
  final String title;
  final int score;
  final String status; // 'pass' | 'warning' | 'fail'
  final List<AuditFinding> findings;
  final List<String>? suggestions;
  final String? currentValue;
  final Map<String, dynamic>? meta;
  final int? weight;
  final String? impact; // 'high' | 'medium' | 'low'

  factory AuditSection.fromMap(Map<String, dynamic> map) {
    final findingsRaw = map['findings'] as List? ?? [];
    final suggestionsRaw = map['suggestions'] as List?;

    return AuditSection(
      key: (map['key'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      score: (map['score'] as num?)?.toInt() ?? 0,
      status: (map['status'] ?? 'warning').toString(),
      findings: findingsRaw
          .map((f) => AuditFinding.fromMap(Map<String, dynamic>.from(f as Map)))
          .toList(),
      suggestions: suggestionsRaw?.map((s) => s.toString()).toList(),
      currentValue: map['currentValue']?.toString(),
      meta: map['meta'] is Map
          ? Map<String, dynamic>.from(map['meta'] as Map)
          : null,
      weight: (map['weight'] as num?)?.toInt(),
      impact: map['impact']?.toString(),
    );
  }
}

class AuditSummaryMetrics {
  const AuditSummaryMetrics({
    this.profileViews30d,
    this.customerActions30d,
    this.actionRate,
    this.averageRating,
    this.reviewCount,
    this.repliedRate,
    this.top3Keywords,
    this.activeCitations,
  });

  final int? profileViews30d;
  final int? customerActions30d;
  final double? actionRate;
  final double? averageRating;
  final int? reviewCount;
  final double? repliedRate;
  final int? top3Keywords;
  final int? activeCitations;

  factory AuditSummaryMetrics.fromMap(Map<String, dynamic> map) {
    return AuditSummaryMetrics(
      profileViews30d: (map['profileViews30d'] as num?)?.toInt(),
      customerActions30d: (map['customerActions30d'] as num?)?.toInt(),
      actionRate: (map['actionRate'] as num?)?.toDouble(),
      averageRating: (map['averageRating'] as num?)?.toDouble(),
      reviewCount: (map['reviewCount'] as num?)?.toInt(),
      repliedRate: (map['repliedRate'] as num?)?.toDouble(),
      top3Keywords: (map['top3Keywords'] as num?)?.toInt(),
      activeCitations: (map['activeCitations'] as num?)?.toInt(),
    );
  }
}

class AuditSummary {
  const AuditSummary({
    required this.verdict,
    required this.strongestSignal,
    required this.biggestLeak,
    required this.confidence,
    required this.dataSources,
    required this.nextBestActions,
    required this.metrics,
  });

  final String verdict;
  final String strongestSignal;
  final String biggestLeak;
  final String confidence; // 'high' | 'medium' | 'low'
  final List<String> dataSources;
  final List<String> nextBestActions;
  final AuditSummaryMetrics metrics;

  factory AuditSummary.fromMap(Map<String, dynamic> map) {
    final dsRaw = map['dataSources'] as List? ?? [];
    final nbaRaw = map['nextBestActions'] as List? ?? [];
    final metricsRaw = map['metrics'] is Map
        ? Map<String, dynamic>.from(map['metrics'] as Map)
        : <String, dynamic>{};

    return AuditSummary(
      verdict: (map['verdict'] ?? '').toString(),
      strongestSignal: (map['strongestSignal'] ?? '').toString(),
      biggestLeak: (map['biggestLeak'] ?? '').toString(),
      confidence: (map['confidence'] ?? 'medium').toString(),
      dataSources: dsRaw.map((d) => d.toString()).toList(),
      nextBestActions: nbaRaw.map((a) => a.toString()).toList(),
      metrics: AuditSummaryMetrics.fromMap(metricsRaw),
    );
  }
}

class AuditResult {
  const AuditResult({
    required this.overallScore,
    required this.sections,
    required this.businessName,
    required this.auditedAt,
    this.summary,
  });

  final int overallScore;
  final List<AuditSection> sections;
  final String businessName;
  final String auditedAt;
  final AuditSummary? summary;

  factory AuditResult.fromMap(Map<String, dynamic> map) {
    final sectionsRaw = map['sections'] as List? ?? [];
    final summaryRaw = map['summary'];

    return AuditResult(
      overallScore: (map['overallScore'] as num?)?.toInt() ?? 0,
      sections: sectionsRaw
          .map((s) =>
              AuditSection.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList(),
      businessName: (map['businessName'] ?? '').toString(),
      auditedAt: (map['auditedAt'] ?? '').toString(),
      summary: summaryRaw is Map
          ? AuditSummary.fromMap(Map<String, dynamic>.from(summaryRaw))
          : null,
    );
  }
}
