import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip.dart';

class TripViewModel extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Trip> trips = [];
  bool isLoading = false;
  String? errorMessage;

  String? get currentUserId => _auth.currentUser?.uid;

  // ── Listen to trips in real-time ────────────────────────────────
  // Returns a stream so the UI updates automatically when Firestore changes
  Stream<List<Trip>> get tripsStream {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('trips')
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final trips = snapshot.docs
              .map((doc) => Trip.fromFirestore(doc))
              .toList();
          // Sort locally — avoids needing a Firestore composite index
          trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return trips;
        });
  }

  // ── Create a new trip ────────────────────────────────────────────
  Future<void> createTrip({
    required String name,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final trip = Trip(
        id: '',
        name: name,
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        memberIds: [uid], // creator is the first member
        createdBy: uid,
        createdAt: DateTime.now(),
      );

      await _db.collection('trips').add(trip.toFirestore());
    } catch (e) {
      debugPrint('Error creating trip: $e');
      errorMessage = 'Failed to create trip. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Delete a trip ────────────────────────────────────────────────
  Future<void> deleteTrip(String tripId) async {
    try {
      await _db.collection('trips').doc(tripId).delete();
    } catch (e) {
      debugPrint('Error deleting trip: $e');
    }
  }

  // ── Add a member to a trip by email ─────────────────────────────
  // Returns an error string if something goes wrong, null on success.
  Future<String?> addMemberByEmail(Trip trip, String email) async {
    try {
      final query = await _db
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return 'No user found with that email. They need to sign up first.';
      }

      final invitedUid = query.docs.first.id;

      if (trip.memberIds.contains(invitedUid)) {
        return 'This person is already in the trip.';
      }

      await _db.collection('trips').doc(trip.id).update({
        'memberIds': FieldValue.arrayUnion([invitedUid]),
      });

      return null; // success
    } catch (e) {
      debugPrint('Invite error: $e');
      return 'Something went wrong. Try again.';
    }
  }
}
