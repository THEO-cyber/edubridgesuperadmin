import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import '../repositories/auth_repository.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState.initial()) {
    _tryRestore();
  }

  final AuthRepository _repo;

  Future<void> _tryRestore() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repo.restoreSession();
      state = state.copyWith(user: user, isLoading: false, clearError: true);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.login(email, password);
      if (result.needs2FA) {
        state = state.copyWith(
          isLoading: false,
          pending2FA: true,
          tempToken: result.tempToken,
        );
      } else {
        state = state.copyWith(
          user: result.user,
          isLoading: false,
          clearPending2FA: true,
          clearError: true,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractMessage(e));
    }
  }

  Future<void> verify2FA(String totpCode) async {
    final tempToken = state.tempToken;
    if (tempToken == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.verify2FA(tempToken, totpCode);
      state = state.copyWith(
        user: user,
        isLoading: false,
        clearPending2FA: true,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Invalid verification code. Please try again.',
      );
    }
  }

  void cancelTwoFactor() {
    state = state.copyWith(clearPending2FA: true, clearError: true);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState.initial();
  }

  void handleSessionExpired() {
    state = const AuthState.initial();
  }

  void updateBadges({int? applications, int? reports}) {
    state = state.copyWith(
      pendingApplications: applications ?? state.pendingApplications,
      pendingReports: reports ?? state.pendingReports,
    );
  }

  String _extractMessage(Object e) {
    final s = e.toString();
    if (s.contains('401') || s.contains('Unauthorized')) {
      return 'Invalid email or password.';
    }
    if (s.contains('SocketException') || s.contains('Connection refused')) {
      return 'Cannot connect to server. Check the API URL.';
    }
    return 'Login failed. Please try again.';
  }
}
