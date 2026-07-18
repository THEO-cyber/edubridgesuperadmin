import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/providers/dashboard_provider.dart';
import '../theme/app_colors.dart';
import 'edubridge_logo.dart';
import 'app_sidebar.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final route = GoRouterState.of(context).uri.toString();

    final pendingCourses = stats.valueOrNull?.pendingReview ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          AppSidebar(
            currentRoute: route,
            isSuperAdmin: authState.isSuperAdmin,
            userName: authState.displayName,
            userEmail: authState.email,
            pendingApplications: authState.pendingApplications,
            pendingReports: authState.pendingReports,
            pendingCourses: pendingCourses,
            onLogout: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              }
            },
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(route: route),
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.route});
  final String route;

  String get _title => switch (route) {
        '/dashboard' => 'Dashboard',
        '/users' => 'User Management',
        '/courses' => 'Course Moderation',
        '/categories' => 'Categories',
        '/applications' => 'Instructor Applications',
        '/reports' => 'Content Reports',
        '/video-processing' => 'Video Processing',
        '/payouts' => 'Payouts',
        '/settings' => 'System Settings',
        _ => 'EduBridge Admin',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const EduBridgeMark(size: 16),
          const SizedBox(width: 7),
          const EduBridgeWordmark(fontSize: 12, baseColor: AppColors.textMuted),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded,
              size: 14, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            _title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          _NotificationBell(),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      icon: const Icon(Icons.notifications_none_rounded),
      color: AppColors.textSecondary,
      iconSize: 18,
      tooltip: 'Notifications',
    );
  }
}
