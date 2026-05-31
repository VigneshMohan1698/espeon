import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/itinerary_item.dart';
import '../viewmodels/itinerary_viewmodel.dart';
import 'add_to_itinerary_sheet.dart';

class ItineraryTab extends StatefulWidget {
  const ItineraryTab({super.key});

  @override
  State<ItineraryTab> createState() => _ItineraryTabState();
}

class _ItineraryTabState extends State<ItineraryTab> {
  int _selectedDay = 1;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ItineraryViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Day selector ──────────────────────────────────────
          _DaySelector(
            totalDays: vm.totalDays,
            selectedDay: _selectedDay,
            trip: vm.trip,
            onDaySelected: (day) => setState(() => _selectedDay = day),
          ),

          // ── Content ───────────────────────────────────────────
          Expanded(
            child: vm.isGenerating
                ? _GeneratingState()
                : vm.items.isEmpty
                    ? _EmptyState(
                        onGenerate: () => vm.generateItinerary(),
                      )
                    : _DayView(
                        day: _selectedDay,
                        vm: vm,
                        onAddItem: () => _showAddItemSheet(context, vm),
                      ),
          ),
        ],
      ),
      floatingActionButton: vm.items.isEmpty
          ? null
          : FloatingActionButton.extended(
              heroTag: 'itinerary_fab',
              onPressed: () => _showAddItemSheet(context, vm),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Activity',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
    );
  }

  Future<void> _showAddItemSheet(
      BuildContext context, ItineraryViewModel vm) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddToItinerarySheet(
        initialDay: _selectedDay,
        totalDays: vm.totalDays,
        initialTitle: '',
        onAdd: (day, slot, title, notes, time) =>
            vm.addItem(day: day, timeSlot: slot, title: title, notes: notes, time: time),
      ),
    );
  }
}

// ── Day selector ──────────────────────────────────────────────────
class _DaySelector extends StatelessWidget {
  final int totalDays;
  final int selectedDay;
  final dynamic trip;
  final ValueChanged<int> onDaySelected;

  const _DaySelector({
    required this.totalDays,
    required this.selectedDay,
    required this.trip,
    required this.onDaySelected,
  });

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ItineraryViewModel>();
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              itemCount: totalDays,
              itemBuilder: (context, index) {
                final day = index + 1;
                final date = vm.dateForDay(day);
                final isSelected = day == selectedDay;
                return GestureDetector(
                  onTap: () => onDaySelected(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Day $day',
                          style: AppTypography.bodySmall.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatDate(date),
                          style: AppTypography.bodySmall.copyWith(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.8)
                                : AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

// ── Day view ──────────────────────────────────────────────────────
class _DayView extends StatelessWidget {
  final int day;
  final ItineraryViewModel vm;
  final VoidCallback onAddItem;

  const _DayView({
    required this.day,
    required this.vm,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = vm.groupedItems;
    final dayItems = grouped[day] ?? {};

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        for (final slot in TimeSlot.values) ...[
          _TimeSlotHeader(slot: slot),
          const SizedBox(height: AppSpacing.sm),
          if (dayItems[slot] == null || dayItems[slot]!.isEmpty)
            _EmptySlot(slot: slot)
          else
            for (final item in dayItems[slot]!)
              _ActivityCard(item: item, onDelete: () => vm.deleteItem(item.id)),
          const SizedBox(height: AppSpacing.lg),
        ],
        const SizedBox(height: 80), // FAB padding
      ],
    );
  }
}

// ── Time slot header ──────────────────────────────────────────────
class _TimeSlotHeader extends StatelessWidget {
  final TimeSlot slot;
  const _TimeSlotHeader({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(slot.emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: AppSpacing.sm),
        Text(slot.label, style: AppTypography.headingMedium),
      ],
    );
  }
}

// ── Empty slot ────────────────────────────────────────────────────
class _EmptySlot extends StatelessWidget {
  final TimeSlot slot;
  const _EmptySlot({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
      ),
      child: Text(
        'Nothing planned for ${slot.label.toLowerCase()} yet',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
      ),
    );
  }
}

// ── Activity card ─────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final ItineraryItem item;
  final VoidCallback onDelete;

  const _ActivityCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Activity'),
            content: Text('Remove "${item.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.title,
                            style: AppTypography.headingMedium),
                      ),
                      if (item.time != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time,
                                  size: 12, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Text(
                                item.time!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.notes!,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onGenerate;
  const _EmptyState({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 64, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.md),
            const Text('No itinerary yet', style: AppTypography.headingMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Generate a day-by-day plan with Claude or add activities manually',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: onGenerate,
              icon: const Text('✈️'),
              label: const Text('Generate with Claude'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Generating state ──────────────────────────────────────────────
class _GeneratingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text('Claude is planning your trip...'),
        ],
      ),
    );
  }
}

