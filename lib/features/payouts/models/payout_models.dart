class Payout {
  const Payout({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.instructorName,
    required this.instructorEmail,
    this.processedAt,
    this.method,
  });

  factory Payout.fromJson(Map<String, dynamic> json) {
    final instructor = json['instructor'] as Map<String, dynamic>? ?? {};
    final user = instructor['user'] as Map<String, dynamic>? ?? instructor;
    return Payout(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      instructorName:
          '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim(),
      instructorEmail: user['email']?.toString() ?? '',
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'].toString())
          : null,
      method: json['method']?.toString(),
    );
  }

  final String id;
  final double amount;
  final String status;
  final DateTime createdAt;
  final String instructorName;
  final String instructorEmail;
  final DateTime? processedAt;
  final String? method;
}
