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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList());
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
}
