import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/itinerary_item.dart';

/// Shared bottom sheet used by both the Itinerary tab and the Chat screen.
/// Calls [onAdd] with the selected day, time slot, title, notes and time.
class AddToItinerarySheet extends StatefulWidget {
  final int totalDays;
  final int initialDay;
  final String initialTitle;
  final Future<void> Function(int day, TimeSlot slot, String title,
      String? notes, String? time) onAdd;

  const AddToItinerarySheet({
    super.key,
    required this.totalDays,
    required this.initialDay,
    required this.initialTitle,
    required this.onAdd,
  });

  @override
  State<AddToItinerarySheet> createState() => _AddToItinerarySheetState();
}

class _AddToItinerarySheetState extends State<AddToItinerarySheet> {
  late final TextEditingController _titleController;
  final TextEditingController _notesController = TextEditingController();
  late int _selectedDay;
  TimeSlot _selectedSlot = TimeSlot.morning;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDay;
    _titleController = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? get _formattedTime {
    if (_selectedTime == null) return null;
    final hour =
        _selectedTime!.hourOfPeriod == 0 ? 12 : _selectedTime!.hourOfPeriod;
    final minute = _selectedTime!.minute.toString().padLeft(2, '0');
    final period = _selectedTime!.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    await widget.onAdd(
      _selectedDay,
      _selectedSlot,
      _titleController.text.trim(),
      _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      _formattedTime,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.pagePadding,
        right: AppSpacing.pagePadding,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ────────────────────────────────────────────
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
          const Text('Add to Itinerary', style: AppTypography.displayMedium),
          const SizedBox(height: AppSpacing.lg),

          // ── Title ─────────────────────────────────────────────
          TextField(
            controller: _titleController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Activity title',
              prefixIcon: Icon(Icons.place_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Day picker ────────────────────────────────────────
          Text('Day',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.totalDays,
              itemBuilder: (context, index) {
                final day = index + 1;
                final isSelected = day == _selectedDay;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
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
                    child: Text(
                      'Day $day',
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Time slot ─────────────────────────────────────────
          Text('Time of day',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: TimeSlot.values.map((slot) {
              final isSelected = slot == _selectedSlot;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSlot = slot),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(
                        right: slot != TimeSlot.evening ? AppSpacing.sm : 0),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Column(
                      children: [
                        Text(slot.emoji),
                        Text(
                          slot.label,
                          style: AppTypography.bodySmall.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Notes ─────────────────────────────────────────────
          TextField(
            controller: _notesController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Notes (optional)',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Time picker ───────────────────────────────────────
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_outlined,
                      size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    _selectedTime == null
                        ? 'Add time (optional)'
                        : _formattedTime!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: _selectedTime == null
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedTime != null)
                    GestureDetector(
                      onTap: () => setState(() => _selectedTime = null),
                      child: const Icon(Icons.close,
                          size: 16, color: AppColors.textHint),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Submit ────────────────────────────────────────────
          ElevatedButton(
            onPressed:
                (_titleController.text.trim().isNotEmpty && !_isLoading)
                    ? _submit
                    : null,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Add to Itinerary'),
          ),
        ],
      ),
    );
  }
}
