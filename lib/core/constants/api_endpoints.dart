abstract final class ApiEndpoints {
  // Build-time configurable (no hardcoded host in the binary):
  //   flutter build windows --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
  // Default is a local dev fallback only.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://edubridge-proxy.michaelrodri091.workers.dev/api/v1',
  );

  // Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String verify2FA = '/auth/2fa/verify';

  // Dashboard
  static const String dashboardStats = '/admin/dashboard/stats';
  static const String dashboardActivity = '/admin/dashboard/activity';

  // Analytics
  static const String analyticsOverview = '/analytics/platform/overview';
  static const String enrollmentTrends = '/analytics/platform/enrollment-trends';
  static const String analyticsCategories = '/analytics/platform/categories';
  static const String topInstructors = '/analytics/platform/top-instructors';

  // Users
  static const String users = '/admin/users';
  static String user(String id) => '/admin/users/$id';
  static String deactivateUser(String id) => '/admin/users/$id/deactivate';
  static String activateUser(String id) => '/admin/users/$id/activate';
  static String userRole(String id) => '/admin/users/$id/role';

  // Courses
  static const String courses = '/admin/courses';
  static const String pendingCourses = '/admin/courses/pending';
  static String courseReview(String id) => '/admin/courses/$id';
  static String approveCourse(String id) => '/admin/courses/$id/approve';
  static String rejectCourse(String id) => '/admin/courses/$id/reject';
  static String suspendCourse(String id) => '/admin/courses/$id/suspend';

  // Categories
  static const String categories = '/admin/categories';
  static String category(String id) => '/admin/categories/$id';

  // Applications
  static const String instructorApplications = '/applications/instructor';
  static const String applicationStats = '/applications/instructor/stats';
  static String reviewApplication(String id) => '/applications/instructor/$id/review';

  // Support inbox
  static const String supportConversations = '/chat/admin/support';
  static String supportMessages(String roomId) => '/chat/admin/support/$roomId/messages';
  static String supportReply(String roomId) => '/chat/admin/support/$roomId/reply';

  // Reports
  static const String reports = '/reports';
  static const String reportStats = '/reports/stats';
  static String reviewReport(String id) => '/reports/$id/review';

  // Settings
  static const String settings = '/admin/settings';
  static const String settingsBulk = '/admin/settings/bulk';
  static String setting(String key) => '/admin/settings/$key';

  // Payouts
  static const String allPayouts = '/payouts/admin/all';

  // Video processing
  static const String videoProcessingStats = '/video-processing/admin/stats';
  static String retryVideo(String videoId) => '/video-processing/admin/retry/$videoId';
  static String videoStreamUrl(String videoId, {String quality = '720p'}) =>
      '/video-processing/stream-url/$videoId?quality=$quality';

  // Video moderation
  static const String pendingVideos = '/admin/videos/pending';
  static String approveVideo(String id) => '/admin/videos/$id/approve';
  static String rejectVideo(String id) => '/admin/videos/$id/reject';
  static String videoPreviewUrl(String id, {String quality = '720p'}) =>
      '/admin/videos/$id/preview-url?quality=$quality';

  // Notifications
  static const String notifyBroadcast = '/admin/notifications/broadcast';
  static String notifyUser(String userId) => '/admin/notifications/user/$userId';
  static const String notifyUsers = '/admin/notifications/users';
  static const String notificationsList = '/admin/notifications';
  static String notification(String id) => '/admin/notifications/$id';
}
