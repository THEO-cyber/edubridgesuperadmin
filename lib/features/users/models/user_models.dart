class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString() ?? '',
        role: json['role']?.toString() ?? 'STUDENT',
        isActive: json['isActive'] as bool? ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  final String id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  String get displayName => '$firstName $lastName'.trim();
  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }
}

class UsersPage {
  const UsersPage({required this.users, required this.total, required this.page});
  final List<AdminUser> users;
  final int total;
  final int page;
}

class UsersFilter {
  const UsersFilter({
    this.page = 1,
    this.limit = 20,
    this.role,
    this.isActive,
    this.search,
    this.createdAfter,
    this.createdBefore,
  });

  final int page;
  final int limit;
  final String? role;
  final bool? isActive;
  final String? search;
  final DateTime? createdAfter;
  final DateTime? createdBefore;

  Map<String, dynamic> toQuery() => {
        'page': page,
        'limit': limit,
        if (role != null) 'role': role,
        if (isActive != null) 'isActive': isActive,
        if (search != null && search!.isNotEmpty) 'search': search,
        if (createdAfter != null) 'createdAfter': createdAfter!.toIso8601String(),
        if (createdBefore != null) 'createdBefore': createdBefore!.toIso8601String(),
      };

  UsersFilter copyWith({
    int? page,
    int? limit,
    String? role,
    bool? isActive,
    String? search,
    DateTime? createdAfter,
    DateTime? createdBefore,
    bool clearRole = false,
    bool clearActive = false,
    bool clearSearch = false,
    bool clearDates = false,
  }) =>
      UsersFilter(
        page: page ?? this.page,
        limit: limit ?? this.limit,
        role: clearRole ? null : (role ?? this.role),
        isActive: clearActive ? null : (isActive ?? this.isActive),
        search: clearSearch ? null : (search ?? this.search),
        createdAfter: clearDates ? null : (createdAfter ?? this.createdAfter),
        createdBefore: clearDates ? null : (createdBefore ?? this.createdBefore),
      );
}
