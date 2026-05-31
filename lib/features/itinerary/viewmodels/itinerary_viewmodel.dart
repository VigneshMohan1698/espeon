import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/secrets.dart';
import '../../trips/models/trip.dart';
import '../models/itinerary_item.dart';

class ItineraryViewModel extends ChangeNotifier {
  final Trip trip;
  ItineraryViewModel({required this.trip}) {
    _listenToItems();
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<ItineraryItem> items = [];
  bool isLoading = false;
  bool isGenerating = false;
  String? errorMessage;

  String get _collectionPath => 'trips/${trip.id}/itinerary';

  // ── Real-time listener ───────────────────────────────────────────
  void _listenToItems() {
    _db
        .collection(_collectionPath)
        .orderBy('createdAt')
        .snapshots()
        .listen((snapshot) {
      items = snapshot.docs
          .map((doc) => ItineraryItem.fromFirestore(doc))
          .toList();
      notifyListeners();
    });
  }

  // ── Items grouped by day then time slot ──────────────────────────
  Map<int, Map<TimeSlot, List<ItineraryItem>>> get groupedItems {
    final map = <int, Map<TimeSlot, List<ItineraryItem>>>{};
    for (final item in items) {
      map.putIfAbsent(item.day, () => {});
      map[item.day]!.putIfAbsent(item.timeSlot, () => []);
      map[item.day]![item.timeSlot]!.add(item);
    }
    return map;
  }

  int get totalDays =>
      trip.endDate.difference(trip.startDate).inDays + 1;

  DateTime dateForDay(int day) =>
      trip.startDate.add(Duration(days: day - 1));

  // ── Add item ─────────────────────────────────────────────────────
  Future<void> addItem({
    required int day,
    required TimeSlot timeSlot,
    required String title,
    String? notes,
    String? time,
  }) async {
    final item = ItineraryItem(
      id: '',
      day: day,
      timeSlot: timeSlot,
      title: title.trim(),
      notes: notes?.trim(),
      time: time,
      createdAt: DateTime.now(),
    );
    await _db.collection(_collectionPath).add(item.toFirestore());
  }

  // ── Delete item ──────────────────────────────────────────────────
  Future<void> deleteItem(String itemId) async {
    await _db.collection(_collectionPath).doc(itemId).delete();
  }

  // ── Generate itinerary with Claude ───────────────────────────────
  Future<void> generateItinerary() async {
    isGenerating = true;
    errorMessage = null;
    notifyListeners();

    try {
      final days = totalDays;
      final prompt = '''
Create a detailed $days-day itinerary for a trip to ${trip.destination}.
Trip dates: ${_formatDate(trip.startDate)} to ${_formatDate(trip.endDate)}.
Number of travelers: ${trip.memberIds.length}.

Return ONLY a JSON array with no extra text, in this exact format:
[
  {
    "day": 1,
    "timeSlot": "morning",
    "title": "Activity name",
    "notes": "Brief description or tip"
  }
]

timeSlot must be one of: morning, afternoon, evening.
Include 2-3 activities per time slot per day. Be specific with real place names.
''';

      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': Secrets.anthropicApiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-6',
          'max_tokens': 4096,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'] as String;

        // Extract JSON array from response
        final jsonStart = text.indexOf('[');
        final jsonEnd = text.lastIndexOf(']') + 1;
        final jsonString = text.substring(jsonStart, jsonEnd);
        final List<dynamic> itemsJson = jsonDecode(jsonString);

        // Clear existing items first
        final existing = await _db.collection(_collectionPath).get();
        for (final doc in existing.docs) {
          await doc.reference.delete();
        }

        // Add all generated items
        final batch = _db.batch();
        for (final itemJson in itemsJson) {
          final ref = _db.collection(_collectionPath).doc();
          final item = ItineraryItem(
            id: '',
            day: itemJson['day'] as int,
            timeSlot: TimeSlot.values.firstWhere(
              (e) => e.name == itemJson['timeSlot'],
              orElse: () => TimeSlot.morning,
            ),
            title: itemJson['title'] as String,
            notes: itemJson['notes'] as String?,
            createdAt: DateTime.now(),
          );
          batch.set(ref, item.toFirestore());
        }
        await batch.commit();
      } else {
        errorMessage = 'Failed to generate itinerary. Please try again.';
      }
    } catch (e) {
      debugPrint('Generate itinerary error: $e');
      errorMessage = 'Something went wrong. Please try again.';
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
