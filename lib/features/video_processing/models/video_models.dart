class VideoQualityVariant {
  const VideoQualityVariant({
    required this.quality,
    required this.url,
    this.fileSize,
  });

  factory VideoQualityVariant.fromJson(Map<String, dynamic> json) =>
      VideoQualityVariant(
        quality: json['quality']?.toString() ?? json['resolution']?.toString() ?? '',
        url: json['url']?.toString() ?? json['s3Key']?.toString() ?? '',
        fileSize: (json['fileSize'] as num?)?.toInt(),
      );

  final String quality;
  final String url;
  final int? fileSize;
}

class PendingVideo {
  const PendingVideo({
    required this.id,
    required this.filename,
    required this.lessonId,
    required this.lessonTitle,
    required this.courseTitle,
    required this.sectionTitle,
    required this.instructorName,
    required this.instructorEmail,
    required this.createdAt,
    this.thumbnailUrl,
    this.originalUrl,
    this.duration,
    this.fileSize,
    this.variants = const [],
  });

  factory PendingVideo.fromJson(Map<String, dynamic> json) {
    final lessonRaw = json['lesson'];
    final lesson = lessonRaw is Map<String, dynamic> ? lessonRaw : <String, dynamic>{};
    final sectionRaw = lesson['section'];
    final section = sectionRaw is Map<String, dynamic>
        ? sectionRaw
        : <String, dynamic>{'title': sectionRaw?.toString()};
    final course = section['course'] as Map<String, dynamic>? ?? json['course'] as Map<String, dynamic>? ?? {};
    final instructor = json['instructor'] as Map<String, dynamic>?
        ?? course['instructor'] as Map<String, dynamic>?
        ?? {};
    final variantsList = json['variants'] as List<dynamic>?
        ?? json['transcodedVideos'] as List<dynamic>?
        ?? [];
    return PendingVideo(
      id: json['id']?.toString() ?? '',
      filename: json['filename']?.toString()
          ?? json['originalFilename']?.toString()
          ?? lesson['title']?.toString()
          ?? 'Untitled',
      lessonId: lesson['id']?.toString() ?? json['lessonId']?.toString() ?? '',
      lessonTitle: lesson['title']?.toString() ?? json['lessonTitle']?.toString() ?? '—',
      sectionTitle: section['title']?.toString() ?? json['sectionTitle']?.toString() ?? '—',
      courseTitle: course['title']?.toString() ?? json['courseTitle']?.toString() ?? '—',
      instructorName: _name(instructor),
      instructorEmail: instructor['email']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? json['thumbnail']?.toString(),
      originalUrl: json['originalUrl']?.toString(),
      duration: _n(json['duration']),
      fileSize: _n(json['fileSize']) ?? _n(json['size']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      variants: variantsList
          .map((e) => VideoQualityVariant.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static int? _n(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static String _name(Map<String, dynamic> m) {
    final first = m['firstName']?.toString() ?? '';
    final last = m['lastName']?.toString() ?? '';
    final full = '$first $last'.trim();
    return full.isNotEmpty ? full : m['name']?.toString() ?? '—';
  }

  final String id;
  final String filename;
  final String lessonId;
  final String lessonTitle;
  final String sectionTitle;
  final String courseTitle;
  final String instructorName;
  final String instructorEmail;
  final String? thumbnailUrl;
  final String? originalUrl;
  final int? duration;
  final int? fileSize;
  final DateTime createdAt;
  final List<VideoQualityVariant> variants;
}

class VideoProcessingStats {
  const VideoProcessingStats({
    required this.pending,
    required this.processing,
    required this.ready,
    required this.failed,
  });

  factory VideoProcessingStats.fromJson(Map<String, dynamic> json) =>
      VideoProcessingStats(
        pending: json['pending'] as int? ?? 0,
        processing: json['processing'] as int? ?? 0,
        ready: json['ready'] as int? ?? 0,
        failed: json['failed'] as int? ?? 0,
      );

  final int pending;
  final int processing;
  final int ready;
  final int failed;

  int get total => pending + processing + ready + failed;
}

class VideoJob {
  const VideoJob({
    required this.id,
    required this.status,
    required this.title,
    required this.createdAt,
    this.errorMessage,
    this.duration,
  });

  factory VideoJob.fromJson(Map<String, dynamic> json) => VideoJob(
        id: json['id']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        title: json['title']?.toString() ??
            json['filename']?.toString() ??
            'Untitled video',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        errorMessage: json['errorMessage']?.toString(),
        duration: (json['duration'] as num?)?.toInt(),
      );

  final String id;
  final String status;
  final String title;
  final DateTime createdAt;
  final String? errorMessage;
  final int? duration;
}
