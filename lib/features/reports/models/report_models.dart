class ContentReport {
  const ContentReport({
    required this.id,
    required this.status,
    required this.targetType,
    required this.reason,
    required this.createdAt,
    required this.reporterName,
    required this.reporterEmail,
    this.resolution,
    this.reviewedAt,
    this.targetTitle,
  });

  factory ContentReport.fromJson(Map<String, dynamic> json) {
    final reporter = json['reporter'] as Map<String, dynamic>? ?? {};
    final target = json['target'] as Map<String, dynamic>? ?? {};
    return ContentReport(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      targetType: json['targetType']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      reporterName:
          '${reporter['firstName'] ?? ''} ${reporter['lastName'] ?? ''}'.trim(),
      reporterEmail: reporter['email']?.toString() ?? '',
      resolution: json['resolution']?.toString(),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
      targetTitle: target['title']?.toString() ?? target['content']?.toString(),
    );
  }

  final String id;
  final String status;
  final String targetType;
  final String reason;
  final DateTime createdAt;
  final String reporterName;
  final String reporterEmail;
  final String? resolution;
  final DateTime? reviewedAt;
  final String? targetTitle;
}

class ReportStats {
  const ReportStats({
    required this.pending,
    required this.reviewed,
    required this.actioned,
    required this.total,
  });

  factory ReportStats.fromJson(Map<String, dynamic> json) => ReportStats(
        pending: json['pending'] as int? ?? 0,
        reviewed: json['reviewed'] as int? ?? 0,
        actioned: json['actioned'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
      );

  final int pending;
  final int reviewed;
  final int actioned;
  final int total;
}
