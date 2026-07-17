import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart' show Formatters;
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/notification_models.dart';
import '../repositories/notifications_repository.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final _notificationsPageProvider = StateProvider<int>((ref) => 1);

final _notificationsListProvider =
    FutureProvider.autoDispose<NotificationsPage>((ref) {
  final page = ref.watch(_notificationsPageProvider);
  return ref.read(notificationsRepositoryProvider).listNotifications(page: page);
});

// ─── Screen ───────────────────────────────────────────────────────────────────

enum _SendMode { broadcast, singleUser, group }

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Notifications',
            subtitle: 'Send and manage platform notifications',
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller: _tabs,
              labelColor: AppColors.primaryLight,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Send Notification'),
                Tab(text: 'History'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                _SendTab(),
                _HistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Send Tab ─────────────────────────────────────────────────────────────────

class _SendTab extends ConsumerStatefulWidget {
  const _SendTab();

  @override
  ConsumerState<_SendTab> createState() => _SendTabState();
}

class _SendTabState extends ConsumerState<_SendTab> {
  _SendMode _mode = _SendMode.broadcast;
  String _broadcastRole = 'ALL';
  final _userIdCtrl = TextEditingController();
  final _groupIdsCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _actionUrlCtrl = TextEditingController();
  bool _sending = false;
  String? _resultMsg;
  bool _resultOk = false;

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _groupIdsCtrl.dispose();
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _actionUrlCtrl.dispose();
    super.dispose();
  }

  List<String> get _parsedGroupIds => _groupIdsCtrl.text
      .split(RegExp(r'[\n,]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  bool get _canSend {
    if (_titleCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      return false;
    }
    if (_mode == _SendMode.singleUser && _userIdCtrl.text.trim().isEmpty) {
      return false;
    }
    if (_mode == _SendMode.group && _parsedGroupIds.isEmpty) return false;
    return true;
  }

  Future<void> _send() async {
    if (!_canSend || _sending) return;
    setState(() { _sending = true; _resultMsg = null; });
    try {
      final repo = ref.read(notificationsRepositoryProvider);
      final title = _titleCtrl.text.trim();
      final message = _messageCtrl.text.trim();
      final actionUrl = _actionUrlCtrl.text.trim();
      switch (_mode) {
        case _SendMode.broadcast:
          await repo.broadcast(
            role: _broadcastRole, title: title,
            message: message, actionUrl: actionUrl);
        case _SendMode.singleUser:
          await repo.notifyUser(
            userId: _userIdCtrl.text.trim(), title: title,
            message: message, actionUrl: actionUrl);
        case _SendMode.group:
          await repo.notifyGroup(
            userIds: _parsedGroupIds, title: title,
            message: message, actionUrl: actionUrl);
      }
      _titleCtrl.clear(); _messageCtrl.clear();
      _actionUrlCtrl.clear(); _userIdCtrl.clear(); _groupIdsCtrl.clear();
      setState(() { _resultMsg = _successMsg; _resultOk = true; });
      ref.invalidate(_notificationsListProvider);
    } catch (e) {
      setState(() { _resultMsg = 'Failed: $e'; _resultOk = false; });
    } finally {
      setState(() => _sending = false);
    }
  }

  String get _successMsg {
    switch (_mode) {
      case _SendMode.broadcast:
        return 'Broadcast sent to all $_broadcastRole users.';
      case _SendMode.singleUser:
        return 'Notification sent to user.';
      case _SendMode.group:
        return 'Notification sent to ${_parsedGroupIds.length} users.';
    }
  }

  String get _sendLabel {
    switch (_mode) {
      case _SendMode.broadcast:
        return 'Broadcast to $_broadcastRole';
      case _SendMode.singleUser:
        return 'Send Notification';
      case _SendMode.group:
        final n = _parsedGroupIds.length;
        return n > 0 ? 'Send to $n Users' : 'Send to Group';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel
        SizedBox(
          width: 288,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel('Send Mode'),
                const SizedBox(height: 8),
                _ModeCard(
                  icon: Icons.campaign_rounded,
                  title: 'Broadcast',
                  subtitle: 'Send to an entire role group',
                  selected: _mode == _SendMode.broadcast,
                  onTap: () => setState(() => _mode = _SendMode.broadcast),
                ),
                const SizedBox(height: 8),
                _ModeCard(
                  icon: Icons.person_rounded,
                  title: 'Single User',
                  subtitle: 'Target one specific user',
                  selected: _mode == _SendMode.singleUser,
                  onTap: () => setState(() => _mode = _SendMode.singleUser),
                ),
                const SizedBox(height: 8),
                _ModeCard(
                  icon: Icons.group_rounded,
                  title: 'Group',
                  subtitle: 'Target a list of users',
                  selected: _mode == _SendMode.group,
                  onTap: () => setState(() => _mode = _SendMode.group),
                ),
                const SizedBox(height: 20),
                _SectionLabel('Target'),
                const SizedBox(height: 8),
                _buildTarget(),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Right panel
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel('Message'),
                const SizedBox(height: 8),
                _buildMessageForm(),
                const SizedBox(height: 14),
                if (_resultMsg != null) ...[
                  _ResultBanner(message: _resultMsg!, success: _resultOk),
                  const SizedBox(height: 14),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _canSend && !_sending ? _send : null,
                    icon: _sending
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(_sending ? 'Sending…' : _sendLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTarget() {
    switch (_mode) {
      case _SendMode.broadcast:
        return _buildBroadcastTarget();
      case _SendMode.singleUser:
        return _buildSingleUserTarget();
      case _SendMode.group:
        return _buildGroupTarget();
    }
  }

  Widget _buildBroadcastTarget() {
    return _TargetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Target Role',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          ...['ALL', 'STUDENT', 'INSTRUCTOR', 'ADMIN'].map((role) {
            final selected = _broadcastRole == role;
            return GestureDetector(
              onTap: () => setState(() => _broadcastRole = role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primarySurface
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(_roleIcon(role),
                        size: 14,
                        color: selected
                            ? AppColors.primaryLight
                            : AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text(role,
                        style: TextStyle(
                          color: selected
                              ? AppColors.primaryLight
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        )),
                    if (selected) ...[
                      const Spacer(),
                      const Icon(Icons.check_rounded,
                          size: 13, color: AppColors.primaryLight),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSingleUserTarget() {
    return _TargetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('User ID',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: _userIdCtrl,
            style:
                const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Paste user UUID…',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          const Text('Copy the ID from the Users page.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildGroupTarget() {
    return _TargetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('User IDs',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const Spacer(),
              if (_parsedGroupIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${_parsedGroupIds.length} users',
                      style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _groupIdsCtrl,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontFamily: 'monospace'),
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'uuid-1\nuuid-2\nuuid-3',
              hintStyle:
                  TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          const Text('One ID per line or comma-separated.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildMessageForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel('Title', required: true),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            style:
                const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'e.g. Platform Update',
              hintStyle: TextStyle(color: AppColors.textMuted),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _FieldLabel('Message', required: true),
          const SizedBox(height: 6),
          TextField(
            controller: _messageCtrl,
            style:
                const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Write the notification body…',
              hintStyle: TextStyle(color: AppColors.textMuted),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _FieldLabel('Action URL', required: false),
          const SizedBox(height: 6),
          TextField(
            controller: _actionUrlCtrl,
            style:
                const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: '/dashboard  (optional deep-link)',
              hintStyle: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'ALL':        return Icons.public_rounded;
      case 'STUDENT':    return Icons.school_rounded;
      case 'INSTRUCTOR': return Icons.person_rounded;
      case 'ADMIN':      return Icons.admin_panel_settings_rounded;
      default:           return Icons.group_rounded;
    }
  }
}

// ─── History Tab ──────────────────────────────────────────────────────────────

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_notificationsListProvider);
    final page = ref.watch(_notificationsPageProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: AppColors.error)),
      ),
      data: (data) => Column(
        children: [
          Expanded(
            child: data.notifications.isEmpty
                ? const Center(
                    child: Text('No notifications yet.',
                        style: TextStyle(color: AppColors.textMuted)))
                : ListView.separated(
                    itemCount: data.notifications.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppColors.border, height: 1),
                    itemBuilder: (ctx, i) => _NotificationRow(
                      notif: data.notifications[i],
                      onUpdated: () => ref.invalidate(_notificationsListProvider),
                      onDeleted: () => ref.invalidate(_notificationsListProvider),
                    ),
                  ),
          ),
          _Pagination(
            page: page,
            total: data.total,
            limit: 20,
            onPageChanged: (p) =>
                ref.read(_notificationsPageProvider.notifier).state = p,
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({
    required this.notif,
    required this.onUpdated,
    required this.onDeleted,
  });

  final AdminNotification notif;
  final VoidCallback onUpdated;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.notifications_rounded,
                size: 17, color: AppColors.primaryLight),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(notif.title,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: notif.allRead ? 'All Read' : 'Unread',
                      variant: notif.allRead
                          ? BadgeVariant.neutral
                          : BadgeVariant.info,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(notif.message,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.group_rounded,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('${notif.recipientCount} recipient${notif.recipientCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time_rounded,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(Formatters.dateTime(notif.createdAt),
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                    if (notif.actionUrl != null) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.link_rounded,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(notif.actionUrl!,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showEditDialog(context, ref),
                icon: const Icon(Icons.edit_rounded, size: 16),
                color: AppColors.textSecondary,
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                onPressed: () => _confirmDelete(context, ref),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                color: AppColors.error,
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController(text: notif.title);
    final messageCtrl = TextEditingController(text: notif.message);
    final urlCtrl = TextEditingController(text: notif.actionUrl ?? '');

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Edit Notification'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Title',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(isDense: true),
                ),
                const SizedBox(height: 14),
                const Text('Message',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: messageCtrl,
                  maxLines: 3,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(isDense: true),
                ),
                const SizedBox(height: 14),
                const Text('Action URL (optional)',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: urlCtrl,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(isDense: true),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                try {
                  await ref
                      .read(notificationsRepositoryProvider)
                      .updateNotification(
                        notif.id,
                        title: titleCtrl.text.trim(),
                        message: messageCtrl.text.trim(),
                        actionUrl: urlCtrl.text.trim().isEmpty
                            ? null
                            : urlCtrl.text.trim(),
                      );
                  onUpdated();
                } catch (_) {}
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Notification'),
        content: Text(
          'Delete "${notif.title}"? This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await ref
                    .read(notificationsRepositoryProvider)
                    .deleteNotification(notif.id);
                onDeleted();
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.total,
    required this.limit,
    required this.onPageChanged,
  });

  final int page;
  final int total;
  final int limit;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final pages = (total / limit).ceil();
    if (pages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.textSecondary,
          ),
          Text('$page / $pages',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          IconButton(
            onPressed: page < pages ? () => onPageChanged(page + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.required});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(text,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          if (required)
            const Text(' *',
                style: TextStyle(color: AppColors.error, fontSize: 13)),
        ],
      );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:
                selected ? AppColors.primarySurface : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon,
                    size: 16,
                    color: selected
                        ? AppColors.primaryLight
                        : AppColors.textMuted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          color: selected
                              ? AppColors.primaryLight
                              : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        )),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 15,
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ],
          ),
        ),
      );
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.message, required this.success});
  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:
              success ? AppColors.successSurface : AppColors.errorSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: success
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.error.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              success
                  ? Icons.check_circle_rounded
                  : Icons.error_rounded,
              size: 16,
              color: success ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: TextStyle(
                      color: success
                          ? AppColors.success
                          : AppColors.error,
                      fontSize: 13)),
            ),
          ],
        ),
      );
}
