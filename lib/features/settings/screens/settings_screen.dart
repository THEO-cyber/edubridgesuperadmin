import '../../../core/network/api_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/setting_models.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'System Settings',
            subtitle:
                'Manage platform-wide configuration (SUPER_ADMIN only)',
            actions: [
              OutlinedButton.icon(
                onPressed: () => _showSeedDialog(context, ref),
                icon: const Icon(Icons.auto_fix_high_rounded, size: 15),
                label: const Text('Seed Defaults'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('New Setting'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Warning banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning, size: 16),
                SizedBox(width: 10),
                Text(
                  'Changes take effect immediately and affect all users. Handle with care.',
                  style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: settingsAsync.when(
              data: (settings) {
                if (settings.isEmpty) {
                  return EmptyState(
                    icon: Icons.tune_outlined,
                    title: 'No settings configured',
                    subtitle:
                        'Seed the default settings to get started.',
                    action: OutlinedButton(
                      onPressed: () => _showSeedDialog(context, ref),
                      child: const Text('Seed Defaults'),
                    ),
                  );
                }
                return _SettingsTable(
                  settings: settings,
                  onEdit: (s) => _showEditDialog(context, ref, s),
                  onDelete: (s) => _delete(context, ref, s),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                message: apiErrorMessage(e),
                onRetry: () => ref.invalidate(settingsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext ctx, WidgetRef ref) {
    showDialog<void>(
      context: ctx,
      builder: (_) => _SettingDialog(
        onSave: (s) =>
            ref.read(settingsActionProvider.notifier).create(s),
      ),
    );
  }

  void _showEditDialog(
      BuildContext ctx, WidgetRef ref, SystemSetting setting) {
    showDialog<void>(
      context: ctx,
      builder: (_) => _SettingDialog(
        initial: setting,
        onSave: (s) => ref
            .read(settingsActionProvider.notifier)
            .update(s.key, s.value),
      ),
    );
  }

  Future<void> _delete(
      BuildContext ctx, WidgetRef ref, SystemSetting setting) async {
    final ok = await showConfirmDialog(ctx,
        title: 'Delete Setting',
        message:
            'Delete "${setting.key}"? This may break platform functionality.',
        confirmLabel: 'Delete',
        isDanger: true);
    if (!ok) return;
    await ref.read(settingsActionProvider.notifier).delete(setting.key);
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('"${setting.key}" deleted.')),
      );
    }
  }

  void _showSeedDialog(BuildContext ctx, WidgetRef ref) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Seed Default Settings'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The following settings will be created or updated:',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...kRecommendedSettings.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 220,
                          child: Text(s.$1,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontFamily: 'monospace')),
                        ),
                        Text(s.$2,
                            style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 12)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final settings = kRecommendedSettings
                  .map((s) => SystemSetting(
                        key: s.$1,
                        value: s.$2,
                        description: s.$3,
                      ))
                  .toList();
              await ref
                  .read(settingsActionProvider.notifier)
                  .bulkUpsert(settings);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text('Default settings applied.')),
                );
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTable extends StatelessWidget {
  const _SettingsTable({
    required this.settings,
    required this.onEdit,
    required this.onDelete,
  });
  final List<SystemSetting> settings;
  final void Function(SystemSetting) onEdit;
  final void Function(SystemSetting) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: [
                _TH('Key', flex: 3),
                _TH('Value', flex: 2),
                _TH('Description', flex: 4),
                _TH('Public', flex: 1),
                _TH('Actions', flex: 1),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: settings.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (_, i) => _SettingRow(
                setting: settings[i],
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ),
          ),
        ],
      ),
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

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.setting,
    required this.onEdit,
    required this.onDelete,
  });
  final SystemSetting setting;
  final void Function(SystemSetting) onEdit;
  final void Function(SystemSetting) onDelete;

  Color get _valueColor {
    if (setting.value == 'true') return AppColors.success;
    if (setting.value == 'false') return AppColors.error;
    final n = double.tryParse(setting.value);
    if (n != null) return AppColors.amber;
    return AppColors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              setting.key,
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                setting.value,
                style: TextStyle(
                  color: _valueColor,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              setting.description ?? '—',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StatusBadge(
              label: setting.isPublic ? 'Yes' : 'No',
              variant: setting.isPublic
                  ? BadgeVariant.success
                  : BadgeVariant.neutral,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _Btn(
                  icon: Icons.edit_outlined,
                  color: AppColors.primary,
                  tooltip: 'Edit',
                  onTap: () => onEdit(setting),
                ),
                const SizedBox(width: 4),
                _Btn(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.error,
                  tooltip: 'Delete',
                  onTap: () => onDelete(setting),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.color, required this.tooltip, required this.onTap});
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 15, color: color),
          ),
        ),
      );
}

class _SettingDialog extends StatefulWidget {
  const _SettingDialog({this.initial, required this.onSave});
  final SystemSetting? initial;
  final Future<bool> Function(SystemSetting) onSave;

  @override
  State<_SettingDialog> createState() => _SettingDialogState();
}

class _SettingDialogState extends State<_SettingDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _keyCtrl;
  late final TextEditingController _valueCtrl;
  late final TextEditingController _descCtrl;
  late bool _isPublic;
  bool _loading = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _keyCtrl = TextEditingController(text: widget.initial?.key);
    _valueCtrl = TextEditingController(text: widget.initial?.value);
    _descCtrl = TextEditingController(text: widget.initial?.description);
    _isPublic = widget.initial?.isPublic ?? false;
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _valueCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final setting = SystemSetting(
      key: _keyCtrl.text.trim(),
      value: _valueCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      isPublic: _isPublic,
    );
    final ok = await widget.onSave(setting);
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
      } else {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Setting' : 'New Setting'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _keyCtrl,
                readOnly: _isEdit,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontFamily: 'monospace'),
                decoration: const InputDecoration(
                    labelText: 'Key',
                    hintText: 'platform.feature_name'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Key required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueCtrl,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Value'),
                validator: (v) =>
                    v == null ? 'Value required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                    labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _isPublic,
                    onChanged: (v) =>
                        setState(() => _isPublic = v ?? false),
                    activeColor: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Public (readable by frontend without auth)',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
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
              : Text(_isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
