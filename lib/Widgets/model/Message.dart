class Message {
  final String? id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  Message({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'is_read': isRead,
    };
  }
}
