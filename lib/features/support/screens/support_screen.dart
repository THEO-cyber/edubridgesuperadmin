import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../models/support_models.dart';
import '../providers/support_provider.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convosAsync = ref.watch(supportConversationsProvider);
    final selected = ref.watch(selectedSupportRoomProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Support',
            subtitle: 'Answer questions learners and instructors send from the app.',
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
                onPressed: () => ref.invalidate(supportConversationsProvider),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  // ── Conversation list ──
                  SizedBox(
                    width: 320,
                    child: convosAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => ErrorState(
                        message: apiErrorMessage(e),
                        onRetry: () => ref.invalidate(supportConversationsProvider),
                      ),
                      data: (convos) {
                        if (convos.isEmpty) {
                          return const EmptyState(
                            icon: Icons.forum_outlined,
                            title: 'No support messages yet',
                          );
                        }
                        return ListView.separated(
                          itemCount: convos.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: AppColors.border),
                          itemBuilder: (_, i) => _ConversationRow(
                            convo: convos[i],
                            selected: convos[i].id == selected,
                            onTap: () => ref
                                .read(selectedSupportRoomProvider.notifier)
                                .state = convos[i].id,
                          ),
                        );
                      },
                    ),
                  ),
                  const VerticalDivider(width: 1, color: AppColors.border),
                  // ── Reading pane ──
                  Expanded(
                    child: selected == null
                        ? const EmptyState(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'Select a conversation to read and reply',
                          )
                        : _ConversationPane(roomId: selected),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.convo, required this.selected, required this.onTap});
  final SupportConversation convo;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? AppColors.primarySurface : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primarySurface,
              child: Text(
                convo.userName.isNotEmpty ? convo.userName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppColors.primaryLight, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(convo.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                      Text(Formatters.timeAgo(convo.lastActivityAt),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    convo.lastMessage == null
                        ? convo.userEmail
                        : '${convo.lastFromUser ? '' : 'You: '}${convo.lastMessage}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationPane extends ConsumerStatefulWidget {
  const _ConversationPane({required this.roomId});
  final String roomId;

  @override
  ConsumerState<_ConversationPane> createState() => _ConversationPaneState();
}

class _ConversationPaneState extends ConsumerState<_ConversationPane> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    final ok =
        await ref.read(supportReplyProvider.notifier).send(widget.roomId, text);
    if (!ok && mounted) {
      _ctrl.text = text; // restore on failure
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send your reply. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(supportMessagesProvider(widget.roomId));
    final sending = ref.watch(supportReplyProvider) is AsyncLoading;

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(
              message: apiErrorMessage(e),
              onRetry: () => ref.invalidate(supportMessagesProvider(widget.roomId)),
            ),
            data: (messages) {
              if (messages.isEmpty) {
                return const EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'No messages yet',
                );
              }
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(20),
                itemCount: messages.length,
                itemBuilder: (_, i) => _Bubble(msg: messages[i]),
              );
            },
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Type a reply…',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: sending ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: sending
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final SupportMessage msg;

  @override
  Widget build(BuildContext context) {
    final fromSupport = msg.fromSupport;
    return Align(
      alignment: fromSupport ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: fromSupport ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg.content,
                style: TextStyle(
                    color: fromSupport ? Colors.white : AppColors.textPrimary, fontSize: 13)),
            const SizedBox(height: 3),
            Text(
              '${fromSupport ? 'Support' : msg.senderName} · ${Formatters.timeAgo(msg.createdAt)}',
              style: TextStyle(
                color: fromSupport ? Colors.white70 : AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
