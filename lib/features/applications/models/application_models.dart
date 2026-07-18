class InstructorApplication {
  const InstructorApplication({
    required this.id,
    required this.status,
    required this.motivation,
    required this.expertise,
    required this.createdAt,
    required this.userName,
    required this.userEmail,
    this.rejectionReason,
    this.reviewedAt,
  });

  factory InstructorApplication.fromJson(Map<String, dynamic> json) {
    // Public (pre-account) applications have no linked user until approval — fall
    // back to the applicant details captured on the application itself.
    final user = json['user'] as Map<String, dynamic>?;
    final firstName = (user?['firstName'] ?? json['firstName'] ?? '').toString();
    final lastName = (user?['lastName'] ?? json['lastName'] ?? '').toString();
    final email = (user?['email'] ?? json['email'] ?? '').toString();

    final subjects = json['subjectExpertise'];
    final expertise = subjects is List
        ? subjects.join(', ')
        : (json['expertise'] ?? subjects ?? '').toString();

    return InstructorApplication(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      motivation: json['motivation']?.toString() ?? '',
      expertise: expertise,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      userName: '$firstName $lastName'.trim(),
      userEmail: email,
      rejectionReason: json['rejectionReason']?.toString(),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
    );
  }

  final String id;
  final String status;
  final String motivation;
  final String expertise;
  final DateTime createdAt;
  final String userName;
  final String userEmail;
  final String? rejectionReason;
  final DateTime? reviewedAt;
}

class ApplicationStats {
  const ApplicationStats({
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.total,
  });

  factory ApplicationStats.fromJson(Map<String, dynamic> json) =>
      ApplicationStats(
        pending: json['pending'] as int? ?? 0,
        approved: json['approved'] as int? ?? 0,
        rejected: json['rejected'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
      );

  final int pending;
  final int approved;
  final int rejected;
  final int total;
}
