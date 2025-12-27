class Message {
  final String? id;
  final String senderId;
  final String? receiverId;
  final String? channelId;
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

  factory Message.fromJson(Map<String, dynamic> json) { //Factory constructor dùng để chuyển dữ liệu từ JSON sang object Message
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

  Map<String, dynamic> toJson() { //Chuyển object Message thành JSON để gửi lên server
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'channel_id': channelId,
      'content': content,
      'is_read': isRead,
    };
  }
}
