import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/trip.dart';
import '../../chat/screens/chats_tab.dart';
import '../../itinerary/screens/itinerary_tab.dart';
import '../../itinerary/viewmodels/itinerary_viewmodel.dart';
import 'members_tab.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  int _selectedTab = 0;

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ItineraryViewModel(trip: widget.trip),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.trip.name),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Row(
              children: [
                _TabButton(label: 'Members', icon: Icons.people_outline, index: 0, selected: _selectedTab, onTap: (i) => setState(() => _selectedTab = i)),
                _TabButton(label: 'Chats', icon: Icons.chat_bubble_outline, index: 1, selected: _selectedTab, onTap: (i) => setState(() => _selectedTab = i)),
                _TabButton(label: 'Itinerary', icon: Icons.map_outlined, index: 2, selected: _selectedTab, onTap: (i) => setState(() => _selectedTab = i)),
                _TabButton(label: 'Expenses', icon: Icons.receipt_long_outlined, index: 3, selected: _selectedTab, onTap: (i) => setState(() => _selectedTab = i)),
              ],
            ),
          ),
        ),

        body: Column(
          children: [
            // ── Trip header ───────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(widget.trip.destination,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          )),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${_formatDate(widget.trip.startDate)} → ${_formatDate(widget.trip.endDate)}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Tab content — IndexedStack keeps all tabs alive ───
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  MembersTab(trip: widget.trip),
                  ChatsTab(trip: widget.trip),
                  const ItineraryTab(),
                  const _PlaceholderTab(
                    icon: Icons.receipt_long_outlined,
                    label: 'Expenses coming soon',
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

// ── Custom tab button ─────────────────────────────────────────────
class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final int index;
  final int selected;
  final ValueChanged<int> onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PlaceholderTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.md),
          Text(label,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              )),
        ],
      ),
    );
  }
}
