class Message {
  final int? id;
  final String chatId;
  final String role; // "user" o "assistant"
  final String content;
  final DateTime createdAt;
  final bool isError;
  final bool isStreaming;

  Message({
    this.id,
    required this.chatId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isError = false,
    this.isStreaming = false,
  });
}
