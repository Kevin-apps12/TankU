/// One turn in the AI conversation.
class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  /// 'user' or 'assistant'.
  final String role;
  final String content;

  bool get isUser => role == 'user';

  factory ChatMessage.user(String content) =>
      ChatMessage(role: 'user', content: content);
  factory ChatMessage.assistant(String content) =>
      ChatMessage(role: 'assistant', content: content);

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
