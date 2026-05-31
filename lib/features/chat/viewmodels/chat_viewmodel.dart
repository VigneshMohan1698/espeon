import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../trips/models/trip.dart';
import '../models/message.dart';
import '../../../core/config/secrets.dart';

class ChatViewModel extends ChangeNotifier {
  final Trip trip;
  final String chatId;

  ChatViewModel({required this.trip, required this.chatId}) {
    _loadMessages();
  }

  final List<Message> messages = [];
  bool isLoading = false;
  String? errorMessage;

  String get _storageKey => 'chat_$chatId';

  // ── Load messages from local storage ────────────────────────────
  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored != null) {
      final List<dynamic> jsonList = jsonDecode(stored);
      messages.addAll(jsonList.map((e) => Message.fromJson(e)));
      notifyListeners();
    }
  }

  // ── Save messages to local storage ───────────────────────────────
  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = messages.map((m) => m.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  // ── Clear chat history ───────────────────────────────────────────
  Future<void> clearChat() async {
    messages.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }

  // System prompt gives Claude context about the trip
  String get _systemPrompt => '''
You are Espeon, an AI travel assistant helping a group plan their trip.

Trip details:
- Trip name: ${trip.name}
- Destination: ${trip.destination}
- Dates: ${_formatDate(trip.startDate)} to ${_formatDate(trip.endDate)}
- Number of travelers: ${trip.memberIds.length}

Be helpful, friendly, and specific to this trip. Suggest real places, restaurants, activities, and tips for ${trip.destination}. Keep responses concise and practical.
''';

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Add user message
    messages.add(Message(
      content: content.trim(),
      role: MessageRole.user,
      timestamp: DateTime.now(),
    ));
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': Secrets.anthropicApiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-6',
          'max_tokens': 1024,
          'system': _systemPrompt,
          'messages': messages.map((m) => m.toApi()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['content'][0]['text'] as String;
        messages.add(Message(
          content: reply,
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
        ));
        await _saveMessages();
      } else {
        final error = jsonDecode(response.body);
        debugPrint('Claude API error: ${response.statusCode} — $error');
        errorMessage = 'Failed to get a response. Please try again.';
        // Remove the user message since it failed
        messages.removeLast();
      }
    } catch (e) {
      debugPrint('Chat error: $e');
      errorMessage = 'Network error. Check your connection.';
      messages.removeLast();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
