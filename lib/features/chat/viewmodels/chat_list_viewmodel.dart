import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat.dart';

class ChatListViewModel extends ChangeNotifier {
  final String tripId;

  ChatListViewModel({required this.tripId}) {
    _loadChats();
  }

  List<Chat> chats = [];
  bool isLoading = true;

  String get _storageKey => 'chats_list_$tripId';

  Future<void> _loadChats() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored != null) {
      final List<dynamic> jsonList = jsonDecode(stored);
      chats = jsonList.map((e) => Chat.fromJson(e)).toList();
      chats.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> _saveChats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageKey, jsonEncode(chats.map((c) => c.toJson()).toList()));
  }

  Future<Chat> createChat(String title) async {
    final chat = Chat(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim().isEmpty ? 'New Chat' : title.trim(),
      createdAt: DateTime.now(),
    );
    chats.insert(0, chat);
    await _saveChats();
    notifyListeners();
    return chat;
  }

  Future<void> deleteChat(String chatId) async {
    chats.removeWhere((c) => c.id == chatId);
    // Also delete messages for this chat
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_$chatId');
    await _saveChats();
    notifyListeners();
  }
}
