class SupportConversation {
  const SupportConversation({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.messageCount,
    required this.lastActivityAt,
    this.lastMessage,
    this.lastFromUser = true,
  });

  factory SupportConversation.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final last = json['lastMessage'] as Map<String, dynamic>?;
    return SupportConversation(
      id: json['id']?.toString() ?? '',
      userName: (user?['name'] ?? '').toString().trim().isEmpty
          ? (user?['email'] ?? 'Unknown user').toString()
          : user!['name'].toString(),
      userEmail: (user?['email'] ?? '').toString(),
      messageCount: json['messageCount'] as int? ?? 0,
      lastActivityAt: DateTime.tryParse(json['lastActivityAt']?.toString() ?? '') ??
          DateTime.now(),
      lastMessage: last?['content']?.toString(),
      lastFromUser: last?['fromUser'] as bool? ?? true,
    );
  }

  final String id;
  final String userName;
  final String userEmail;
  final int messageCount;
  final DateTime lastActivityAt;
  final String? lastMessage;
  final bool lastFromUser;
}

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.senderName,
    required this.fromSupport,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
        id: json['id']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        senderName: json['senderName']?.toString() ?? '',
        fromSupport: json['fromSupport'] as bool? ?? false,
      );

  final String id;
  final String content;
  final DateTime createdAt;
  final String senderName;
  final bool fromSupport;
}
