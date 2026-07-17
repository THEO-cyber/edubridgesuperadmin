class AdminCourse {
  const AdminCourse({
    required this.id,
    required this.title,
    required this.status,
    required this.isPublished,
    required this.price,
    required this.instructorName,
    required this.instructorEmail,
    required this.categoryName,
    required this.enrollmentCount,
    required this.createdAt,
    this.publishedAt,
    this.rejectionReason,
    this.suspensionReason,
  });

  factory AdminCourse.fromJson(Map<String, dynamic> json) {
    final instructor = json['instructor'] as Map<String, dynamic>? ?? {};
    final user = instructor['user'] as Map<String, dynamic>? ?? instructor;
    final category = json['category'] as Map<String, dynamic>? ?? {};
    final count = json['_count'] as Map<String, dynamic>? ?? {};
    return AdminCourse(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'DRAFT',
      isPublished: json['isPublished'] as bool? ?? false,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      instructorName:
          '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim(),
      instructorEmail: user['email']?.toString() ?? '',
      categoryName: category['name']?.toString() ?? '—',
      enrollmentCount: (count['enrollments'] as num?)?.toInt()
          ?? (json['enrollmentCount'] as num?)?.toInt()
          ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      rejectionReason: json['rejectionReason']?.toString(),
      suspensionReason: json['suspensionReason']?.toString(),
    );
  }

  final String id;
  final String title;
  final String status;
  final bool isPublished;
  final double price;
  final String instructorName;
  final String instructorEmail;
  final String categoryName;
  final int enrollmentCount;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final String? rejectionReason;
  final String? suspensionReason;
}

// ─── Review detail models ─────────────────────────────────────────────────────

class ReviewLesson {
  const ReviewLesson({
    required this.id,
    required this.title,
    required this.order,
    this.videoStatus,
    this.videoId,
    this.videoUrl,
    this.videoError,
    this.duration,
    this.quizCount = 0,
  });

  factory ReviewLesson.fromJson(Map<String, dynamic> json) {
    // Backend returns `videos` (array); take the first entry
    final videosList = json['videos'] as List<dynamic>?;
    final video = (videosList != null && videosList.isNotEmpty)
        ? videosList.first as Map<String, dynamic>?
        : (json['video'] as Map<String, dynamic>?);
    // Prefer processedUrl, fall back to originalUrl or first variant s3Url
    String? videoUrl = video?['processedUrl']?.toString()
        ?? video?['originalUrl']?.toString();
    if (videoUrl == null && video != null) {
      final variants = video['variants'] as List<dynamic>?;
      if (variants != null && variants.isNotEmpty) {
        videoUrl = (variants.first as Map<String, dynamic>?)?['s3Url']?.toString();
      }
    }
    // Backend returns quiz._count.questions
    final quiz = json['quiz'] as Map<String, dynamic>?;
    final quizCount = (quiz?['_count'] as Map<String, dynamic>?)?['questions'] as num?;
    return ReviewLesson(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      order: (json['sortOrder'] as num?)?.toInt()
          ?? (json['order'] as num?)?.toInt()
          ?? 0,
      videoStatus: video?['status']?.toString(),
      videoId: video?['id']?.toString(),
      videoUrl: videoUrl,
      videoError: video?['errorMessage']?.toString(),
      duration: (video?['duration'] as num?)?.toInt(),
      quizCount: quizCount?.toInt()
          ?? (json['quizCount'] as num?)?.toInt()
          ?? 0,
    );
  }

  final String id;
  final String title;
  final int order;
  final String? videoStatus;
  final String? videoId;
  final String? videoUrl;
  final String? videoError;
  final int? duration;
  final int quizCount;
}

class ReviewSection {
  const ReviewSection({
    required this.id,
    required this.title,
    required this.order,
    required this.lessons,
  });

  factory ReviewSection.fromJson(Map<String, dynamic> json) => ReviewSection(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        order: (json['sortOrder'] as num?)?.toInt()
            ?? (json['order'] as num?)?.toInt()
            ?? 0,
        lessons: (json['lessons'] as List<dynamic>? ?? [])
            .map((l) => ReviewLesson.fromJson(l as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order)),
      );

  final String id;
  final String title;
  final int order;
  final List<ReviewLesson> lessons;
}

class RecentCourseReview {
  const RecentCourseReview({
    required this.studentName,
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  factory RecentCourseReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return RecentCourseReview(
      studentName:
          '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim().isNotEmpty
              ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim()
              : user['email']?.toString() ?? 'Student',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  final String studentName;
  final int rating;
  final String? comment;
  final DateTime createdAt;
}

class CourseReviewDetail {
  const CourseReviewDetail({
    required this.id,
    required this.title,
    required this.status,
    required this.instructorName,
    required this.instructorEmail,
    required this.categoryName,
    required this.price,
    required this.sections,
    required this.recentReviews,
    required this.createdAt,
    this.description,
    this.thumbnailUrl,
    this.avgRating = 0,
    this.enrollmentCount = 0,
    this.rejectionReason,
  });

  factory CourseReviewDetail.fromJson(Map<String, dynamic> json) {
    final instructor = json['instructor'] as Map<String, dynamic>? ?? {};
    final user = instructor['user'] as Map<String, dynamic>? ?? instructor;
    final category = json['category'] as Map<String, dynamic>? ?? {};
    final count = json['_count'] as Map<String, dynamic>? ?? {};
    return CourseReviewDetail(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      description: json['description']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? json['thumbnail']?.toString(),
      instructorName:
          '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim(),
      instructorEmail: user['email']?.toString() ?? '',
      categoryName: category['name']?.toString() ?? '—',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      avgRating: (json['avgRating'] as num?)?.toDouble()
          ?? (json['averageRating'] as num?)?.toDouble()
          ?? 0,
      enrollmentCount: (count['enrollments'] as num?)?.toInt()
          ?? (json['enrollmentCount'] as num?)?.toInt()
          ?? 0,
      sections: (json['sections'] as List<dynamic>? ?? [])
          .map((s) => ReviewSection.fromJson(s as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
      recentReviews: (json['reviews'] as List<dynamic>?
              ?? json['recentReviews'] as List<dynamic>?
              ?? [])
          .map((r) => RecentCourseReview.fromJson(r as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }

  final String id;
  final String title;
  final String status;
  final String? description;
  final String? thumbnailUrl;
  final String instructorName;
  final String instructorEmail;
  final String categoryName;
  final double price;
  final double avgRating;
  final int enrollmentCount;
  final List<ReviewSection> sections;
  final List<RecentCourseReview> recentReviews;
  final DateTime createdAt;
  final String? rejectionReason;

  int get totalLessons =>
      sections.fold(0, (sum, s) => sum + s.lessons.length);
  int get readyVideos => sections
      .expand((s) => s.lessons)
      .where((l) => l.videoStatus == 'READY')
      .length;
  int get totalVideos => sections
      .expand((s) => s.lessons)
      .where((l) => l.videoStatus != null)
      .length;
  int get totalQuizQuestions => sections
      .expand((s) => s.lessons)
      .fold(0, (sum, l) => sum + l.quizCount);
}

class CoursesFilter {
  const CoursesFilter({
    this.page = 1,
    this.limit = 20,
    this.status,
    this.search,
  });

  final int page;
  final int limit;
  final String? status;
  final String? search;

  Map<String, dynamic> toQuery() => {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
        if (search != null && search!.isNotEmpty) 'search': search,
      };

  CoursesFilter copyWith({
    int? page,
    String? status,
    String? search,
    bool clearStatus = false,
    bool clearSearch = false,
  }) =>
      CoursesFilter(
        page: page ?? this.page,
        limit: limit,
        status: clearStatus ? null : (status ?? this.status),
        search: clearSearch ? null : (search ?? this.search),
      );
}
