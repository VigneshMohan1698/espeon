import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../itinerary/models/itinerary_item.dart';
import '../../itinerary/screens/add_to_itinerary_sheet.dart';
import '../../trips/models/trip.dart';
import '../models/message.dart';
import '../viewmodels/chat_viewmodel.dart';

class ChatTab extends StatefulWidget {
  final Trip trip;
  final Future<void> Function(int, TimeSlot, String, String?, String?) addItem;

  const ChatTab({super.key, required this.trip, required this.addItem});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send(ChatViewModel chat) async {
    final text = _controller.text.trim();
    if (text.isEmpty || chat.isLoading) return;
    _controller.clear();
    await chat.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatViewModel>();

    return Column(
      children: [
        // ── Messages ──────────────────────────────────────────────
        Expanded(
          child: chat.messages.isEmpty
              ? _EmptyChat()
              : ListView.builder(
                  reverse: true,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 0 && chat.isLoading) {
                      return const _TypingIndicator();
                    }
                    final msgIndex = chat.isLoading
                        ? chat.messages.length - index
                        : chat.messages.length - 1 - index;
                    return _MessageBubble(
                      message: chat.messages[msgIndex],
                      trip: widget.trip,
                      addItem: widget.addItem,
                    );
                  },
                ),
        ),

        // ── Error ─────────────────────────────────────────────────
        if (chat.errorMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            color: AppColors.error.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(chat.errorMessage!,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.error)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: chat.clearError,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

        // ── Input bar ─────────────────────────────────────────────
        Container(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.sm,
            top: AppSpacing.sm,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                AppSpacing.md,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Ask about your trip...',
                    border: InputBorder.none,
                    filled: false,
                  ),
                  onSubmitted: (_) => _send(chat),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () => _send(chat),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: chat.isLoading
                        ? AppColors.textHint
                        : AppColors.primary,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────
class _EmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chat = context.read<ChatViewModel>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.md),
            const Text('Ask me anything!', style: AppTypography.headingMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'I know all about your trip to ${chat.trip.destination}. Ask for recommendations, itineraries, tips — anything!',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Quick suggestion chips
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                '🍕 Best restaurants',
                '🗺️ 3-day itinerary',
                '🏨 Where to stay',
                '💡 Local tips',
              ].map((suggestion) => _SuggestionChip(label: suggestion)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  const _SuggestionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final chat = context.read<ChatViewModel>();
    return GestureDetector(
      onTap: () => chat.sendMessage(label),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final Message message;
  final Trip trip;
  final Future<void> Function(int, TimeSlot, String, String?, String?) addItem;
  const _MessageBubble({required this.message, required this.trip, required this.addItem});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Text('✈️', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppSpacing.radiusLg),
                      topRight: const Radius.circular(AppSpacing.radiusLg),
                      bottomLeft: Radius.circular(
                          isUser ? AppSpacing.radiusLg : AppSpacing.xs),
                      bottomRight: Radius.circular(
                          isUser ? AppSpacing.xs : AppSpacing.radiusLg),
                    ),
                    border: isUser ? null : Border.all(color: AppColors.divider),
                  ),
                  child: isUser
                      ? Text(
                          message.content,
                          style: AppTypography.bodyMedium
                              .copyWith(color: Colors.white),
                        )
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textPrimary),
                            strong: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700),
                            em: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontStyle: FontStyle.italic),
                            listBullet: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textPrimary),
                            h1: AppTypography.headingLarge
                                .copyWith(color: AppColors.textPrimary),
                            h2: AppTypography.headingMedium
                                .copyWith(color: AppColors.textPrimary),
                            h3: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                ),
                // ── Add to itinerary button (Claude messages only) ──
                if (!isUser) ...[
                  const SizedBox(height: AppSpacing.xs),
                  GestureDetector(
                    onTap: () => _showAddToItinerarySheet(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 12, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          'Add to itinerary',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }

  /// Extracts list items from a markdown message.
  /// Handles: `- item`, `* item`, `1. item`, `**Bold** description`
  List<String> _extractSuggestions(String content) {
    final lines = content.split('\n');
    final suggestions = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      String? extracted;

      // Bullet: - item or * item
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        extracted = trimmed.substring(2).trim();
      }
      // Numbered: 1. item
      else if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
        extracted = trimmed.replaceFirst(RegExp(r'^\d+\.\s'), '').trim();
      }
      // Bold heading: **Place Name** - description
      else if (trimmed.startsWith('**') && trimmed.contains('**')) {
        final match = RegExp(r'\*\*(.+?)\*\*').firstMatch(trimmed);
        if (match != null) extracted = match.group(1)!.trim();
      }

      if (extracted != null && extracted.isNotEmpty) {
        // Strip remaining markdown and truncate
        final clean = extracted.replaceAll(RegExp(r'[*`#]'), '').trim();
        // Take only the part before a dash/colon (e.g. "Eiffel Tower - great views" → "Eiffel Tower")
        final short = clean.split(RegExp(r'\s[-–:]\s')).first.trim();
        if (short.isNotEmpty && short.length < 80) {
          suggestions.add(short);
        }
      }
    }

    return suggestions;
  }

  void _showAddToItinerarySheet(BuildContext context) {
    final suggestions = _extractSuggestions(message.content);

    if (suggestions.isEmpty) {
      // No list items — open sheet with empty title for manual entry
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddToItinerarySheet(
          totalDays: trip.endDate.difference(trip.startDate).inDays + 1,
          initialDay: 1,
          initialTitle: '',
          onAdd: addItem,
        ),
      );
    } else {
      // Show suggestion picker first
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SuggestionPickerSheet(
          suggestions: suggestions,
          trip: trip,
          addItem: addItem,
        ),
      );
    }
  }
}

// ── Suggestion picker sheet ───────────────────────────────────────
class _SuggestionPickerSheet extends StatelessWidget {
  final List<String> suggestions;
  final Trip trip;
  final Future<void> Function(int, TimeSlot, String, String?, String?) addItem;

  const _SuggestionPickerSheet({
    required this.suggestions,
    required this.trip,
    required this.addItem,
  });

  void _openAddSheet(BuildContext context, String title) {
    Navigator.pop(context); // close picker
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddToItinerarySheet(
        totalDays: trip.endDate.difference(trip.startDate).inDays + 1,
        initialDay: 1,
        initialTitle: title,
        onAdd: addItem,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      padding: const EdgeInsets.only(
        left: AppSpacing.pagePadding,
        right: AppSpacing.pagePadding,
        top: AppSpacing.md,
        bottom: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('What to add?', style: AppTypography.displayMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tap a suggestion or add your own',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Suggestion chips
              ...suggestions.map(
                (s) => GestureDetector(
                  onTap: () => _openAddSheet(context, s),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(s, style: AppTypography.bodyMedium),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 18, color: AppColors.textHint),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Manual entry option
              GestureDetector(
                onTap: () => _openAddSheet(context, ''),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Add something else',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Text('✈️', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.divider),
            ),
            child: const SizedBox(
              width: 40,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.divider,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
