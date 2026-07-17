class DashboardStats {
  const DashboardStats({
    required this.totalUsers,
    required this.studentCount,
    required this.instructorCount,
    required this.adminCount,
    required this.totalCourses,
    required this.totalEnrollments,
    required this.totalRevenue,
    required this.pendingReview,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>? ?? {};
    return DashboardStats(
      totalUsers: users['total'] as int? ?? 0,
      studentCount: users['student'] as int? ?? 0,
      instructorCount: users['instructor'] as int? ?? 0,
      adminCount: users['admin'] as int? ?? 0,
      totalCourses: json['courses'] as int? ?? 0,
      totalEnrollments: json['enrollments'] as int? ?? 0,
      totalRevenue: json['totalRevenue']?.toString() ?? '0.00',
      pendingReview: json['pendingReview'] as int? ?? 0,
    );
  }

  final int totalUsers;
  final int studentCount;
  final int instructorCount;
  final int adminCount;
  final int totalCourses;
  final int totalEnrollments;
  final String totalRevenue;
  final int pendingReview;
}

class ActivityEvent {
  const ActivityEvent({
    required this.type,
    required this.description,
    required this.timestamp,
  });

  factory ActivityEvent.fromJson(Map<String, dynamic> json) => ActivityEvent(
        type: json['type']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  final String type;
  final String description;
  final DateTime timestamp;
}

class EnrollmentTrendPoint {
  const EnrollmentTrendPoint({required this.date, required this.count});

  factory EnrollmentTrendPoint.fromJson(Map<String, dynamic> json) =>
      EnrollmentTrendPoint(
        date: json['date']?.toString() ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );

  final String date;
  final int count;
}

class CategoryStat {
  const CategoryStat({required this.name, required this.count});

  factory CategoryStat.fromJson(Map<String, dynamic> json) => CategoryStat(
        name: json['name']?.toString() ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );

  final String name;
  final int count;
}

class TopInstructor {
  const TopInstructor({
    required this.id,
    required this.name,
    required this.email,
    required this.revenue,
    required this.courseCount,
    required this.studentCount,
  });

  factory TopInstructor.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? json;
    return TopInstructor(
      id: json['id']?.toString() ?? '',
      name:
          '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim(),
      email: user['email']?.toString() ?? '',
      revenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      courseCount: (json['courseCount'] as num?)?.toInt() ?? 0,
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String name;
  final String email;
  final double revenue;
  final int courseCount;
  final int studentCount;
}
