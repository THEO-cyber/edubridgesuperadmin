import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BadgeVariant { success, warning, error, info, neutral, purple }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.variant,
  });

  factory StatusBadge.fromStatus(String status) {
    final variant = switch (status.toUpperCase()) {
      'PUBLISHED' || 'ACTIVE' || 'APPROVED' || 'ACTIONED' || 'READY' => BadgeVariant.success,
      'UNDER_REVIEW' || 'PENDING' || 'PROCESSING' => BadgeVariant.warning,
      'REJECTED' || 'SUSPENDED' || 'ARCHIVED' || 'INACTIVE' || 'FAILED' => BadgeVariant.error,
      'DRAFT' => BadgeVariant.neutral,
      'SUPER_ADMIN' => BadgeVariant.purple,
      'ADMIN' => BadgeVariant.info,
      _ => BadgeVariant.neutral,
    };
    return StatusBadge(label: _formatLabel(status), variant: variant);
  }

  static String _formatLabel(String s) =>
      s.replaceAll('_', ' ').toLowerCase().replaceFirstMapped(
            RegExp(r'^\w'),
            (m) => m[0]!.toUpperCase(),
          );

  final String label;
  final BadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      BadgeVariant.success => (AppColors.successSurface, AppColors.success),
      BadgeVariant.warning => (AppColors.warningSurface, AppColors.warning),
      BadgeVariant.error => (AppColors.errorSurface, AppColors.error),
      BadgeVariant.info => (AppColors.infoSurface, AppColors.info),
      BadgeVariant.purple => (const Color(0xFF2E1065), const Color(0xFFA78BFA)),
      BadgeVariant.neutral => (AppColors.surfaceVariant, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
