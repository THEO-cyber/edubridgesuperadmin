import '../../../core/network/api_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/category_models.dart';
import '../providers/categories_provider.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Categories',
            subtitle: 'Organise courses into discoverable categories',
            actions: [
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('New Category'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: categoriesAsync.when(
              data: (cats) {
                if (cats.isEmpty) {
                  return EmptyState(
                    icon: Icons.category_outlined,
                    title: 'No categories yet',
                    subtitle: 'Create your first category to organise courses.',
                    action: ElevatedButton(
                      onPressed: () => _showCreateDialog(context, ref),
                      child: const Text('Create Category'),
                    ),
                  );
                }
                return _CategoriesGrid(
                  categories: cats,
                  onEdit: (c) => _showEditDialog(context, ref, c),
                  onDelete: (c) => _delete(context, ref, c),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                message: apiErrorMessage(e),
                onRetry: () => ref.invalidate(categoriesProvider),
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
      builder: (_) => _CategoryDialog(
        onSave: (name, desc, icon, isActive) async {
          await ref.read(categoriesActionProvider.notifier).create(
                name: name,
                description: desc,
                icon: icon.isEmpty ? null : icon,
                isActive: isActive,
              );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext ctx, WidgetRef ref, Category cat) {
    showDialog<void>(
      context: ctx,
      builder: (_) => _CategoryDialog(
        initialName: cat.name,
        initialDesc: cat.description,
        initialIcon: cat.icon,
        initialActive: cat.isActive,
        isEdit: true,
        onSave: (name, desc, icon, isActive) async {
          await ref.read(categoriesActionProvider.notifier).update(
                cat.id,
                name: name,
                description: desc,
                icon: icon,
                isActive: isActive,
              );
        },
      ),
    );
  }

  Future<void> _delete(BuildContext ctx, WidgetRef ref, Category cat) async {
    if (cat.courseCount > 0) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(
            '"${cat.name}" has ${cat.courseCount} courses and cannot be deleted.'),
      ));
      return;
    }
    final ok = await showConfirmDialog(ctx,
        title: 'Delete Category',
        message: 'Delete "${cat.name}"? This cannot be undone.',
        confirmLabel: 'Delete',
        isDanger: true);
    if (!ok) return;
    await ref.read(categoriesActionProvider.notifier).delete(cat.id);
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('"${cat.name}" deleted.')),
      );
    }
  }
}

class _CategoriesGrid extends StatelessWidget {
  const _CategoriesGrid({
    required this.categories,
    required this.onEdit,
    required this.onDelete,
  });
  final List<Category> categories;
  final void Function(Category) onEdit;
  final void Function(Category) onDelete;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: categories.length,
      itemBuilder: (_, i) => _CategoryCard(
        category: categories[i],
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });
  final Category category;
  final void Function(Category) onEdit;
  final void Function(Category) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                // Show the emoji learners will actually see, when one is set.
                child: (category.icon != null && category.icon!.isNotEmpty)
                    ? Text(category.icon!, style: const TextStyle(fontSize: 16))
                    : const Icon(Icons.category_rounded,
                        color: AppColors.primaryLight, size: 16),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => onEdit(category),
                icon: const Icon(Icons.edit_outlined, size: 15),
                color: AppColors.textMuted,
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              IconButton(
                onPressed: () => onDelete(category),
                icon: const Icon(Icons.delete_outline_rounded, size: 15),
                color: AppColors.error,
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            category.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${category.courseCount} courses',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: category.isActive ? 'Active' : 'Inactive',
                variant: category.isActive
                    ? BadgeVariant.success
                    : BadgeVariant.neutral,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({
    this.initialName,
    this.initialDesc,
    this.initialIcon,
    this.initialActive = true,
    this.isEdit = false,
    required this.onSave,
  });
  final String? initialName;
  final String? initialDesc;
  final String? initialIcon;
  final bool initialActive;
  final bool isEdit;
  final Future<void> Function(String name, String? desc, String icon, bool isActive)
      onSave;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _iconCtrl;
  late bool _active;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _descCtrl = TextEditingController(text: widget.initialDesc);
    _iconCtrl = TextEditingController(text: widget.initialIcon);
    _active = widget.initialActive;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.onSave(
        _nameCtrl.text.trim(),
        _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        _iconCtrl.text.trim(),
        _active,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit Category' : 'Create Category'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _iconCtrl,
                maxLength: 4,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Icon (emoji)',
                  hintText: 'e.g. 💻',
                  helperText: 'Shown on the category card in the apps',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: const Text('Visible to learners',
                    style: TextStyle(
                        color: AppColors.textPrimary, fontSize: 13)),
                subtitle: Text(
                  _active
                      ? 'Shows in the app and website'
                      : 'Hidden — useful while you add courses to it',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                ),
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
              : Text(widget.isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
