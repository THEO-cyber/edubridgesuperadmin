class SystemSetting {
  const SystemSetting({
    required this.key,
    required this.value,
    this.description,
    this.isPublic = false,
  });

  factory SystemSetting.fromJson(Map<String, dynamic> json) => SystemSetting(
        key: json['key']?.toString() ?? '',
        value: json['value']?.toString() ?? '',
        description: json['description']?.toString(),
        isPublic: json['isPublic'] as bool? ?? false,
      );

  final String key;
  final String value;
  final String? description;
  final bool isPublic;

  SystemSetting copyWith({String? value, String? description, bool? isPublic}) =>
      SystemSetting(
        key: key,
        value: value ?? this.value,
        description: description ?? this.description,
        isPublic: isPublic ?? this.isPublic,
      );
}

const kRecommendedSettings = [
  ('platform.name', 'EduBridge', 'Platform display name'),
  ('platform.currency', 'USD', 'Default currency'),
  ('platform.instructor_revenue_share', '0.70', 'Revenue share for instructors (0–1)'),
  ('platform.max_course_price', '999', 'Maximum allowed course price in USD'),
  ('platform.maintenance_mode', 'false', 'Set to true during deployments'),
  ('platform.free_enrollment_enabled', 'true', 'Allow free courses'),
  ('platform.review_period_days', '30', 'Days students can review after enrollment'),
  ('platform.cert_expiry_years', '0', '0 = certificates never expire'),
];
