import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../viewmodels/trip_viewmodel.dart';
import '../models/trip.dart';
import '../widgets/trip_card.dart';
import 'create_trip_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firstName = user?.displayName?.split(' ').first ?? 'Traveler';
    final auth = context.read<AuthViewModel>();
    final tripVM = context.read<TripViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Espeon ✈️'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => auth.signOut(),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting ─────────────────────────────────────────
              Text(
                'Hey $firstName 👋',
                style: AppTypography.displayMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Where are you headed next?',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Trips list ────────────────────────────────────────
              Text('Your Trips', style: AppTypography.headingLarge),
              const SizedBox(height: AppSpacing.md),

              Expanded(
                child: StreamBuilder<List<Trip>>(
                  stream: tripVM.tripsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final trips = snapshot.data ?? [];

                    if (trips.isEmpty) {
                      return _EmptyState(
                        onCreateTap: () => _showCreateSheet(context),
                      );
                    }

                    return ListView.separated(
                      itemCount: trips.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) =>
                          TripCard(trip: trips[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // ── Create trip button ──────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Trip',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateTripSheet(),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.luggage_rounded, size: 72, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.md),
          const Text('No trips yet', style: AppTypography.headingMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap "New Trip" to start planning',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
