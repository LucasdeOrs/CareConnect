class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      conversationId: map['conversa_id'],
      senderId: map['sender_id'],
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']),
      isRead: map['is_read'] ?? false,
    );
  }
}
