import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../itinerary/models/itinerary_item.dart';
import '../../itinerary/viewmodels/itinerary_viewmodel.dart';
import '../../trips/models/trip.dart';
import '../models/chat.dart';
import '../viewmodels/chat_list_viewmodel.dart';
import '../viewmodels/chat_viewmodel.dart';
import 'chat_tab.dart';

class ChatsTab extends StatelessWidget {
  final Trip trip;
  const ChatsTab({super.key, required this.trip});

  void _openChat(BuildContext context, Chat chat) {
    final itineraryVM = context.read<ItineraryViewModel>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ChatViewModel(trip: trip, chatId: chat.id),
          child: ChatScreen(
            title: chat.title,
            trip: trip,
            addItem: (day, slot, title, notes, time) => itineraryVM.addItem(
              day: day,
              timeSlot: slot,
              title: title,
              notes: notes,
              time: time,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showNewChatDialog(
      BuildContext context, ChatListViewModel vm) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Chat'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'e.g. Restaurants, Day 1 Itinerary...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (title != null && context.mounted) {
      final chat = await vm.createChat(title);
      if (context.mounted) _openChat(context, chat);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatListViewModel(tripId: trip.id),
      child: Consumer<ChatListViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            body: vm.chats.isEmpty
                ? _EmptyChats(
                    onCreateTap: () => _showNewChatDialog(context, vm))
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.pagePadding),
                    itemCount: vm.chats.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final chat = vm.chats[index];
                      return Dismissible(
                        key: ValueKey(chat.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusLg),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white, size: 24),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Chat'),
                              content: Text('Delete "${chat.title}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  style: TextButton.styleFrom(
                                      foregroundColor: AppColors.error),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) => vm.deleteChat(chat.id),
                        child: _ChatListTile(
                          chat: chat,
                          onTap: () => _openChat(context, chat),
                        ),
                      );
                    },
                  ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'chats_fab',
              onPressed: () => _showNewChatDialog(context, vm),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Chat',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          );
        },
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────
class _EmptyChats extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyChats({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline,
              size: 64, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.md),
          const Text('No chats yet', style: AppTypography.headingMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start a chat with Claude about your trip',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Chat list tile ────────────────────────────────────────────────
class _ChatListTile extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;

  const _ChatListTile({
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chat.title, style: AppTypography.headingMedium),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(chat.createdAt),
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ── Individual chat screen ────────────────────────────────────────
class ChatScreen extends StatelessWidget {
  final String title;
  final Trip trip;
  final Future<void> Function(int, TimeSlot, String, String?, String?) addItem;
  const ChatScreen({super.key, required this.title, required this.trip, required this.addItem});

  @override
  Widget build(BuildContext context) {
    final chat = context.read<ChatViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear chat',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Chat'),
                  content: const Text('Clear all messages? This cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.error),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await chat.clearChat();
              }
            },
          ),
        ],
      ),
      body: ChatTab(trip: trip, addItem: addItem),
    );
  }
}
