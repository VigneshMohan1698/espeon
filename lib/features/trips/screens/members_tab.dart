import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/models/app_user.dart';
import '../models/trip.dart';
import '../viewmodels/trip_viewmodel.dart';

class MembersTab extends StatefulWidget {
  final Trip trip;
  const MembersTab({super.key, required this.trip});

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  final _emailController = TextEditingController();
  final _db = FirebaseFirestore.instance;
  bool _isInviting = false;
  String? _inviteError;
  String? _inviteSuccess;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _inviteMember() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isInviting = true;
      _inviteError = null;
      _inviteSuccess = null;
    });

    final tripVM = context.read<TripViewModel>();
    final error = await tripVM.addMemberByEmail(widget.trip, email);

    if (mounted) {
      setState(() {
        _isInviting = false;
        if (error != null) {
          _inviteError = error;
        } else {
          _inviteSuccess = 'Member added!';
          _emailController.clear();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('trips').doc(widget.trip.id).snapshots(),
      builder: (context, tripSnapshot) {
        final memberIds = tripSnapshot.hasData
            ? Trip.fromFirestore(tripSnapshot.data!).memberIds
            : widget.trip.memberIds;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            // ── Invite section ──────────────────────────────────
            Text('Invite someone', style: AppTypography.headingMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      hintText: 'Enter their email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: _isInviting ? null : _inviteMember,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                  ),
                  child: _isInviting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Add'),
                ),
              ],
            ),

            if (_inviteError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_inviteError!,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.error)),
            ],
            if (_inviteSuccess != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_inviteSuccess!,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.success)),
            ],

            const SizedBox(height: AppSpacing.lg),
            Text('Members (${memberIds.length})',
                style: AppTypography.headingMedium),
            const SizedBox(height: AppSpacing.sm),

            // ── Members list ────────────────────────────────────
            ...memberIds.map((uid) => FutureBuilder<DocumentSnapshot>(
                  future: _db.collection('users').doc(uid).get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const ListTile(
                        leading:
                            CircleAvatar(child: Icon(Icons.person)),
                        title: Text('Loading...'),
                      );
                    }

                    final user =
                        AppUser.fromFirestore(userSnapshot.data!);
                    final isYou = uid == currentUid;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(
                        '${user.displayName}${isYou ? ' (you)' : ''}',
                        style: AppTypography.bodyMedium,
                      ),
                      subtitle:
                          Text(user.email, style: AppTypography.bodySmall),
                    );
                  },
                )),
          ],
        );
      },
    );
  }
}
