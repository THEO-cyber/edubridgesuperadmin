import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 200;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                    minHeight: constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
                  ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(compact ? 20 : 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!compact) ...[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: AppColors.textMuted, size: 24),
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      Icon(icon, color: AppColors.textMuted, size: 20),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: compact ? 13 : 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (action != null && !compact) ...[
                      const SizedBox(height: 18),
                      action!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 200;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                    minHeight: constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
                  ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(compact ? 20 : 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!compact) ...[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.errorSurface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 18),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontSize: compact ? 13 : 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    if (onRetry != null && !compact) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 15),
                        label: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
