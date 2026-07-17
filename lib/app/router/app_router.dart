import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_shell.dart';
import '../../features/applications/screens/applications_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/categories/screens/categories_screen.dart';
import '../../features/courses/screens/course_review_screen.dart';
import '../../features/courses/screens/courses_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/payouts/screens/payouts_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/users/screens/users_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/video_processing/screens/video_processing_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isAuth = authState.isAuthenticated;
      final isLogin = state.uri.path == '/login';

      if (isLoading) return null;
      if (!isAuth && !isLogin) return '/login';
      if (isAuth && isLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/users',
            builder: (_, __) => const UsersScreen(),
          ),
          GoRoute(
            path: '/courses',
            builder: (_, __) => const CoursesScreen(),
          ),
          GoRoute(
            path: '/courses/:courseId',
            builder: (_, state) => CourseReviewScreen(
              courseId: state.pathParameters['courseId']!,
            ),
          ),
          GoRoute(
            path: '/categories',
            builder: (_, __) => const CategoriesScreen(),
          ),
          GoRoute(
            path: '/applications',
            builder: (_, __) => const ApplicationsScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (_, __) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/video-processing',
            builder: (_, __) => const VideoProcessingScreen(),
          ),
          GoRoute(
            path: '/payouts',
            builder: (_, __) => const PayoutsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/settings',
            redirect: (ctx, state) {
              final auth = ProviderScope.containerOf(ctx).read(authProvider);
              return auth.isSuperAdmin ? null : '/dashboard';
            },
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text(
          'Page not found: ${state.uri}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
});
