enum MessageRole { user, assistant }

class Message {
  final String content;
  final MessageRole role;
  final DateTime timestamp;

  Message({
    required this.content,
    required this.role,
    required this.timestamp,
  });

  // Formats for the Claude API
  Map<String, String> toApi() => {
        'role': role == MessageRole.user ? 'user' : 'assistant',
        'content': content,
      };

  // Save to local storage as JSON
  Map<String, dynamic> toJson() => {
        'content': content,
        'role': role.name, // 'user' or 'assistant'
        'timestamp': timestamp.toIso8601String(),
      };

  // Load from local storage JSON
  factory Message.fromJson(Map<String, dynamic> json) => Message(
        content: json['content'] as String,
        role: json['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
