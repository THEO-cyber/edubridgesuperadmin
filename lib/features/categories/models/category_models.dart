class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    this.parentId,
    this.courseCount = 0,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // The API returns Prisma's `_count: { courses }`, not a flat courseCount —
    // reading the wrong key made every category report zero courses.
    final count = json['_count'];
    final courses =
        count is Map<String, dynamic> ? (count['courses'] as num?)?.toInt() : null;

    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      icon: json['icon']?.toString(),
      parentId: json['parentId']?.toString(),
      courseCount: courses ?? (json['courseCount'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String name;
  final String slug;
  final String? description;

  /// Emoji shown on the category card in the learner apps.
  final String? icon;
  final String? parentId;
  final int courseCount;

  /// Categories are hidden from learners when false.
  final bool isActive;
  final int sortOrder;
}
