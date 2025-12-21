class Message {
  final String? id;
  final String senderId;
  final String? receiverId; // Nullable for channel messages
  final String? channelId;  // New field
  final String content;
  final DateTime createdAt;
  final bool isRead;

  Message({
    this.id,
    required this.senderId,
    this.receiverId,
    this.channelId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      channelId: json['channel_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'channel_id': channelId,
      'content': content,
      'is_read': isRead,
    };
  }
}
