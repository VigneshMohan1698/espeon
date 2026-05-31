import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/config/secrets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../viewmodels/trip_viewmodel.dart';

class CreateTripSheet extends StatefulWidget {
  const CreateTripSheet({super.key});

  @override
  State<CreateTripSheet> createState() => _CreateTripSheetState();
}

class _CreateTripSheetState extends State<CreateTripSheet> {
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  List<Map<String, String>> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _destinationController.text.trim().isNotEmpty &&
      _startDate != null &&
      _endDate != null;

  Future<void> _fetchSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    try {
      final url = Uri.parse(
        'https://places.googleapis.com/v1/places:autocomplete',
      );
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': Secrets.googlePlacesApiKey,
        },
        body: jsonEncode({
          'input': input,
          'includedPrimaryTypes': ['locality', 'country', 'administrative_area_level_1'],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final suggestions = (data['suggestions'] as List? ?? [])
            .map((s) {
              final prediction = s['placePrediction'];
              return {
                'description': prediction['text']['text'] as String,
                'placeId': prediction['placeId'] as String,
              };
            })
            .toList();

        setState(() {
          _suggestions = List<Map<String, String>>.from(suggestions);
          _showSuggestions = suggestions.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Places error: $e');
    }
  }

  void _onDestinationChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetchSuggestions(value);
    });
    setState(() {});
  }

  void _selectSuggestion(String description) {
    _destinationController.text = description;
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_isValid) return;
    final tripVM = context.read<TripViewModel>();
    await tripVM.createTrip(
      name: _nameController.text.trim(),
      destination: _destinationController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tripVM = context.watch<TripViewModel>();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
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
          // ── Handle bar ────────────────────────────────────────
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

          const Text('New Trip', style: AppTypography.displayMedium),
          const SizedBox(height: AppSpacing.lg),

          // ── Trip name ─────────────────────────────────────────
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Trip name (e.g. Europe Summer 2026)',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Destination with autocomplete ─────────────────────
          TextField(
            controller: _destinationController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Destination (e.g. Paris, France)',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            onChanged: _onDestinationChanged,
          ),

          // ── Suggestions dropdown ──────────────────────────────
          if (_showSuggestions)
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.divider),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: AppSpacing.md),
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return Material(
                    color: AppColors.surface,
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on_outlined,
                          size: 18, color: AppColors.textSecondary),
                      title: Text(
                        suggestion['description']!,
                        style: AppTypography.bodyMedium,
                      ),
                      onTap: () =>
                          _selectSuggestion(suggestion['description']!),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: AppSpacing.md),

          // ── Date pickers ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'Start date',
                  date: _startDate,
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DateButton(
                  label: 'End date',
                  date: _endDate,
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Create button ─────────────────────────────────────
          ElevatedButton(
            onPressed: (_isValid && !tripVM.isLoading) ? _submit : null,
            child: tripVM.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Create Trip'),
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: AppSpacing.iconSm, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                date != null
                    ? '${date!.day}/${date!.month}/${date!.year}'
                    : label,
                style: date != null
                    ? AppTypography.bodyMedium
                    : AppTypography.bodyMedium
                        .copyWith(color: AppColors.textHint),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
