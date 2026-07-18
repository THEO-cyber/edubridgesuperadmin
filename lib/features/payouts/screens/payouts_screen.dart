import '../../../core/network/api_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/payout_models.dart';
import '../providers/payouts_provider.dart';

class PayoutsScreen extends ConsumerWidget {
  const PayoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(payoutsProvider);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Payouts',
            subtitle: 'Track all instructor payout transactions',
            actions: [
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(payoutsProvider),
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Summary cards from data
          payoutsAsync.when(
            data: (payouts) => _SummaryRow(payouts: payouts),
            loading: () => const SizedBox(height: 80),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: payoutsAsync.when(
                data: (payouts) {
                  if (payouts.isEmpty) {
                    return const EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No payouts yet',
                      subtitle:
                          'Instructor payouts will appear here once processed.',
                    );
                  }
                  return _PayoutsTable(payouts: payouts);
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorState(
                  message: apiErrorMessage(e),
                  onRetry: () => ref.invalidate(payoutsProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.payouts});
  final List<Payout> payouts;

  @override
  Widget build(BuildContext context) {
    final total =
        payouts.fold<double>(0, (s, p) => s + p.amount);
    final processed = payouts
        .where((p) => p.status == 'completed' || p.status == 'processed')
        .fold<double>(0, (s, p) => s + p.amount);
    final pending = payouts
        .where((p) => p.status == 'pending')
        .fold<double>(0, (s, p) => s + p.amount);

    return Row(
      children: [
        _SummaryCard(
          label: 'Total Disbursed',
          value: Formatters.currency(total),
          icon: Icons.payments_rounded,
          color: AppColors.success,
        ),
        const SizedBox(width: 12),
        _SummaryCard(
          label: 'Processed',
          value: Formatters.currency(processed),
          icon: Icons.check_circle_rounded,
          color: AppColors.info,
        ),
        const SizedBox(width: 12),
        _SummaryCard(
          label: 'Pending',
          value: Formatters.currency(pending),
          icon: Icons.pending_rounded,
          color: AppColors.warning,
        ),
        const SizedBox(width: 12),
        _SummaryCard(
          label: 'Transactions',
          value: Formatters.number(payouts.length),
          icon: Icons.receipt_long_rounded,
          color: AppColors.violet,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    )),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PayoutsTable extends StatelessWidget {
  const _PayoutsTable({required this.payouts});
  final List<Payout> payouts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: const Row(
            children: [
              _TH('Instructor', flex: 3),
              _TH('Amount', flex: 2),
              _TH('Status', flex: 2),
              _TH('Method', flex: 2),
              _TH('Date', flex: 2),
              _TH('Processed', flex: 2),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: payouts.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, i) => _PayoutRow(payout: payouts[i]),
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
          child: Text(label.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
        ),
      );
}

class _PayoutRow extends StatelessWidget {
  const _PayoutRow({required this.payout});
  final Payout payout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payout.instructorName,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
                Text(payout.instructorEmail,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              Formatters.currency(payout.amount),
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StatusBadge.fromStatus(payout.status),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              payout.method ?? '—',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              Formatters.date(payout.createdAt),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              payout.processedAt != null
                  ? Formatters.date(payout.processedAt)
                  : '—',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
