class AdminNotification {
  const AdminNotification({
    required this.id,
    required this.batchId,
    required this.type,
    required this.title,
    required this.message,
    required this.allRead,
    required this.recipientCount,
    required this.createdAt,
    this.actionUrl,
  });

  factory AdminNotification.fromJson(Map<String, dynamic> json) {
    return AdminNotification(
      id: json['id']?.toString() ?? '',
      batchId: json['batchId']?.toString() ?? json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      allRead: json['allRead'] as bool? ?? false,
      recipientCount: (json['recipientCount'] as num?)?.toInt() ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      actionUrl: json['actionUrl']?.toString(),
    );
  }

  final String id;
  final String batchId;
  final String type;
  final String title;
  final String message;
  final bool allRead;
  final int recipientCount;
  final DateTime createdAt;
  final String? actionUrl;
}

class NotificationsPage {
  const NotificationsPage({
    required this.notifications,
    required this.total,
    required this.page,
  });
  final List<AdminNotification> notifications;
  final int total;
  final int page;
}
