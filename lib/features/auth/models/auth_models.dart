class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.token,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json, String token) {
    final user = json['user'] as Map<String, dynamic>? ?? json;
    return AuthUser(
      id: user['id']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      firstName: user['firstName']?.toString() ?? '',
      lastName: user['lastName']?.toString() ?? '',
      role: user['role']?.toString() ?? 'ADMIN',
      token: token,
    );
  }

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String token;

  String get displayName => '$firstName $lastName'.trim();
  bool get isSuperAdmin => role == 'SUPER_ADMIN';
}

class LoginResult {
  const LoginResult._({this.user, this.tempToken});

  factory LoginResult.authenticated(AuthUser user) =>
      LoginResult._(user: user);

  factory LoginResult.requires2FA(String tempToken) =>
      LoginResult._(tempToken: tempToken);

  final AuthUser? user;
  final String? tempToken;

  bool get needs2FA => tempToken != null;
}

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.pendingApplications = 0,
    this.pendingReports = 0,
    this.pending2FA = false,
    this.tempToken,
  });

  const AuthState.initial()
      : user = null,
        isLoading = false,
        error = null,
        pendingApplications = 0,
        pendingReports = 0,
        pending2FA = false,
        tempToken = null;

  final AuthUser? user;
  final bool isLoading;
  final String? error;
  final int pendingApplications;
  final int pendingReports;
  final bool pending2FA;
  final String? tempToken;

  bool get isAuthenticated => user != null;
  bool get isSuperAdmin => user?.isSuperAdmin ?? false;
  String get displayName => user?.displayName ?? '';
  String get email => user?.email ?? '';

  AuthState copyWith({
    AuthUser? user,
    bool? isLoading,
    String? error,
    int? pendingApplications,
    int? pendingReports,
    bool? pending2FA,
    String? tempToken,
    bool clearUser = false,
    bool clearError = false,
    bool clearPending2FA = false,
  }) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        pendingApplications: pendingApplications ?? this.pendingApplications,
        pendingReports: pendingReports ?? this.pendingReports,
        pending2FA: clearPending2FA ? false : (pending2FA ?? this.pending2FA),
        tempToken: clearPending2FA ? null : (tempToken ?? this.tempToken),
      );
}
