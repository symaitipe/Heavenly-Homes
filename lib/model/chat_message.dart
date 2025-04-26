import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String senderId;
  final String type;
  final String? message;
  final String? imagePath;
  final Timestamp timestamp;

  ChatMessage({
    required this.senderId,
    required this.type,
    this.message,
    this.imagePath,
    required this.timestamp,
  });

  factory ChatMessage.fromFirestore(Map<String, dynamic> data) {
    return ChatMessage(
      senderId: data['senderId'] as String,
      type: data['type'] as String? ?? 'text',
      message: data['message'] as String?,
      imagePath: data['imagePath'] as String?,
      timestamp: data['timestamp'] as Timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'type': type,
      if (message != null) 'message': message,
      if (imagePath != null) 'imagePath': imagePath,
      'timestamp': timestamp,
    };
  }
}