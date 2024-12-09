class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool delivered;
  final bool read;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.delivered = false,
    this.read = false,
  });

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? delivered,
    bool? read,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      delivered: delivered ?? this.delivered,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'delivered': delivered ? 1 : 0,
      'read': read ? 1 : 0,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
      delivered: map['delivered'] == 1,
      read: map['read'] == 1,
    );
  }
}
