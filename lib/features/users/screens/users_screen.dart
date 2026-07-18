import '../../../core/network/api_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/user_models.dart';
import '../providers/users_provider.dart';
import '../repositories/users_repository.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    ref.read(usersFilterProvider.notifier).update(
          (s) => s.copyWith(search: v, page: 1, clearSearch: v.isEmpty),
        );
  }

  void _setRole(String? role) {
    ref.read(usersFilterProvider.notifier).update(
          (s) => s.copyWith(
              role: role, page: 1, clearRole: role == null),
        );
  }

  void _setActive(bool? active) {
    ref.read(usersFilterProvider.notifier).update(
          (s) => s.copyWith(
              isActive: active, page: 1, clearActive: active == null),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = ref.watch(authProvider).isSuperAdmin;
    final filter = ref.watch(usersFilterProvider);
    final usersAsync = ref.watch(usersProvider);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'User Management',
            subtitle: 'View, search, and manage all platform users',
            actions: [
              ElevatedButton.icon(
                onPressed: () => _showCreateUserDialog(context),
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('New User'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filters
          Row(
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Search by name, email, username…',
                    prefixIcon: Icon(Icons.search_rounded, size: 16,
                        color: AppColors.textMuted),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _FilterChip(
                label: 'Role',
                value: filter.role,
                options: const ['STUDENT', 'INSTRUCTOR', 'ADMIN', 'SUPER_ADMIN'],
                onSelected: _setRole,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Status',
                value: filter.isActive == null
                    ? null
                    : filter.isActive! ? 'Active' : 'Inactive',
                options: const ['Active', 'Inactive'],
                onSelected: (v) => _setActive(
                    v == null ? null : v == 'Active'),
              ),
              const Spacer(),
              usersAsync.whenData((p) => Text(
                    '${Formatters.number(p.total)} users',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  )).valueOrNull ??
                  const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 16),

          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: usersAsync.when(
                data: (page) {
                  if (page.users.isEmpty) {
                    return const EmptyState(
                      icon: Icons.people_outline_rounded,
                      title: 'No users found',
                      subtitle: 'Try adjusting your search or filters.',
                    );
                  }
                  return _UsersTable(
                    users: page.users,
                    isSuperAdmin: isSuperAdmin,
                    onDeactivate: (u) => _deactivate(context, ref, u),
                    onActivate: (u) => _activate(context, ref, u),
                    onDelete: (u) => _delete(context, ref, u),
                    onChangeRole: isSuperAdmin
                        ? (u) => _showChangeRole(context, ref, u)
                        : null,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorState(
                  message: apiErrorMessage(e),
                  onRetry: () => ref.invalidate(usersProvider),
                ),
              ),
            ),
          ),

          // Pagination
          usersAsync.whenData((page) {
            final totalPages = (page.total / filter.limit).ceil();
            if (totalPages <= 1) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: filter.page > 1
                        ? () => ref
                            .read(usersFilterProvider.notifier)
                            .update((s) => s.copyWith(page: s.page - 1))
                        : null,
                    child: const Text('Previous'),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Page ${filter.page} of $totalPages',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: filter.page < totalPages
                        ? () => ref
                            .read(usersFilterProvider.notifier)
                            .update((s) => s.copyWith(page: s.page + 1))
                        : null,
                    child: const Text('Next'),
                  ),
                ],
              ),
            );
          }).valueOrNull ??
              const SizedBox.shrink(),
        ],
      ),
    );
  }

  Future<void> _deactivate(BuildContext ctx, WidgetRef ref, AdminUser u) async {
    final ok = await showConfirmDialog(ctx,
        title: 'Deactivate User',
        message: 'Deactivate ${u.displayName}? They will be unable to log in.',
        confirmLabel: 'Deactivate',
        isDanger: true);
    if (!ok) return;
    final success = await ref.read(usersActionProvider.notifier).deactivate(u.id);
    if (ctx.mounted) {
      _showSnack(ctx, success ? '${u.displayName} deactivated.' : 'Action failed.');
    }
  }

  Future<void> _activate(BuildContext ctx, WidgetRef ref, AdminUser u) async {
    final success = await ref.read(usersActionProvider.notifier).activate(u.id);
    if (ctx.mounted) {
      _showSnack(ctx, success ? '${u.displayName} activated.' : 'Action failed.');
    }
  }

  Future<void> _delete(BuildContext ctx, WidgetRef ref, AdminUser u) async {
    final ok = await showConfirmDialog(ctx,
        title: 'Delete User',
        message:
            'Permanently delete ${u.displayName}? This cannot be undone.',
        confirmLabel: 'Delete',
        isDanger: true);
    if (!ok) return;
    final success = await ref.read(usersActionProvider.notifier).delete(u.id);
    if (ctx.mounted) {
      _showSnack(ctx, success ? 'User deleted.' : 'Deletion failed.');
    }
  }

  Future<void> _showChangeRole(
      BuildContext ctx, WidgetRef ref, AdminUser u) async {
    String? selected;
    await showDialog<void>(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Change Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set a new role for ${u.displayName}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              RadioGroup<String>(
                groupValue: selected ?? u.role,
                onChanged: (v) => setState(() => selected = v),
                child: Column(
                  children: [
                    for (final role in [
                      'STUDENT',
                      'INSTRUCTOR',
                      'ADMIN',
                      'SUPER_ADMIN',
                    ])
                      RadioListTile<String>(
                        value: role,
                        title: Text(role,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 13)),
                        dense: true,
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selected == null
                  ? null
                  : () async {
                      Navigator.pop(dialogCtx);
                      await ref
                          .read(usersActionProvider.notifier)
                          .changeRole(u.id, selected!);
                      if (ctx.mounted) {
                        _showSnack(ctx, 'Role updated to $selected.');
                      }
                    },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateUserDialog(BuildContext ctx) {
    showDialog<void>(
      context: ctx,
      builder: (_) => const _CreateUserDialog(),
    );
  }

  void _showSnack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ─── Users Table ─────────────────────────────────────────────────────────────

class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.users,
    required this.isSuperAdmin,
    required this.onDeactivate,
    required this.onActivate,
    required this.onDelete,
    this.onChangeRole,
  });

  final List<AdminUser> users;
  final bool isSuperAdmin;
  final void Function(AdminUser) onDeactivate;
  final void Function(AdminUser) onActivate;
  final void Function(AdminUser) onDelete;
  final void Function(AdminUser)? onChangeRole;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: const [
              _TH('User', flex: 3),
              _TH('Role', flex: 2),
              _TH('Status', flex: 1),
              _TH('Joined', flex: 2),
              _TH('Actions', flex: 2),
            ],
          ),
        ),
        // Rows
        Expanded(
          child: ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, i) => _UserRow(
              user: users[i],
              isSuperAdmin: isSuperAdmin,
              onDeactivate: onDeactivate,
              onActivate: onActivate,
              onDelete: onDelete,
              onChangeRole: onChangeRole,
            ),
          ),
        ),
      ],
    );
  }
}

class _TH extends StatelessWidget {
  const _TH(this.label, {required this.flex});
  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.isSuperAdmin,
    required this.onDeactivate,
    required this.onActivate,
    required this.onDelete,
    this.onChangeRole,
  });

  final AdminUser user;
  final bool isSuperAdmin;
  final void Function(AdminUser) onDeactivate;
  final void Function(AdminUser) onActivate;
  final void Function(AdminUser) onDelete;
  final void Function(AdminUser)? onChangeRole;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StatusBadge.fromStatus(user.role),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StatusBadge(
              label: user.isActive ? 'Active' : 'Inactive',
              variant: user.isActive ? BadgeVariant.success : BadgeVariant.error,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              Formatters.date(user.createdAt),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (user.isActive)
                  _ActionBtn(
                    icon: Icons.block_rounded,
                    tooltip: 'Deactivate',
                    color: AppColors.warning,
                    onTap: () => onDeactivate(user),
                  )
                else
                  _ActionBtn(
                    icon: Icons.check_circle_outline_rounded,
                    tooltip: 'Activate',
                    color: AppColors.success,
                    onTap: () => onActivate(user),
                  ),
                if (isSuperAdmin && onChangeRole != null) ...[
                  const SizedBox(width: 4),
                  _ActionBtn(
                    icon: Icons.manage_accounts_rounded,
                    tooltip: 'Change Role',
                    color: AppColors.primary,
                    onTap: () => onChangeRole!(user),
                  ),
                ],
                const SizedBox(width: 4),
                _ActionBtn(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete',
                  color: AppColors.error,
                  onTap: () => onDelete(user),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ─── Create User Dialog ───────────────────────────────────────────────────────

class _CreateUserDialog extends ConsumerStatefulWidget {
  const _CreateUserDialog();

  @override
  ConsumerState<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'STUDENT';
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(usersRepositoryProvider).createUser(
            email: _emailCtrl.text.trim(),
            username: _usernameCtrl.text.trim(),
            firstName: _firstCtrl.text.trim(),
            lastName: _lastCtrl.text.trim(),
            role: _role,
            password: _passCtrl.text,
          );
      ref.invalidate(usersProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New User'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: _Field('First Name', _firstCtrl)),
                  const SizedBox(width: 12),
                  Expanded(child: _Field('Last Name', _lastCtrl)),
                ],
              ),
              const SizedBox(height: 12),
              _Field('Email', _emailCtrl,
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _Field('Username', _usernameCtrl),
              const SizedBox(height: 12),
              _Field('Password', _passCtrl, obscure: true),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_role),
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                dropdownColor: AppColors.surfaceVariant,
                style: const TextStyle(color: AppColors.textPrimary),
                items: ['STUDENT', 'INSTRUCTOR', 'ADMIN', 'SUPER_ADMIN']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _role = v ?? _role),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Create'),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.ctrl,
      {this.keyboard = TextInputType.text, this.obscure = false});
  final String label;
  final TextEditingController ctrl;
  final TextInputType keyboard;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(labelText: label),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }
}

// Chips for filter
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  static const _all = '__all__';

  final String label;
  final String? value;
  final List<String> options;
  final void Function(String?) onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) => onSelected(v == _all ? null : v),
      color: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(value: _all, child: Text('All')),
        ...options.map((o) => PopupMenuItem(value: o, child: Text(o))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value != null
              ? AppColors.primarySurface
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value != null ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value != null ? '$label: $value' : label,
              style: TextStyle(
                color: value != null
                    ? AppColors.primaryLight
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more_rounded,
              size: 14,
              color: value != null
                  ? AppColors.primaryLight
                  : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
