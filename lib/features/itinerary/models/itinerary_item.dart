import 'package:cloud_firestore/cloud_firestore.dart';

enum TimeSlot { morning, afternoon, evening }

extension TimeSlotExtension on TimeSlot {
  String get label {
    switch (this) {
      case TimeSlot.morning:
        return 'Morning';
      case TimeSlot.afternoon:
        return 'Afternoon';
      case TimeSlot.evening:
        return 'Evening';
    }
  }

  String get emoji {
    switch (this) {
      case TimeSlot.morning:
        return '🌅';
      case TimeSlot.afternoon:
        return '☀️';
      case TimeSlot.evening:
        return '🌙';
    }
  }
}

class ItineraryItem {
  final String id;
  final int day;
  final TimeSlot timeSlot;
  final String title;
  final String? notes;
  final String? time; // e.g. "9:00 AM"
  final DateTime createdAt;

  ItineraryItem({
    required this.id,
    required this.day,
    required this.timeSlot,
    required this.title,
    this.notes,
    this.time,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() => {
        'day': day,
        'timeSlot': timeSlot.name,
        'title': title,
        'notes': notes,
        'time': time,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory ItineraryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItineraryItem(
      id: doc.id,
      day: data['day'] as int,
      timeSlot: TimeSlot.values.firstWhere(
        (e) => e.name == data['timeSlot'],
        orElse: () => TimeSlot.morning,
      ),
      title: data['title'] as String,
      notes: data['notes'] as String?,
      time: data['time'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
