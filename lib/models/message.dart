import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { Text, Image, Document, Audio, Video }

class Message {
  final String id;
  String? senderID;
  String? content;
  MessageType? messageType;
  Timestamp? sentAt;
  bool isRead;

  Message({
    required this.id,
    required this.senderID,
    required this.content,
    required this.messageType,
    required this.sentAt,
    required this.isRead,
  });

  factory Message.fromMap(Map<String, dynamic> map, {required String id}) {
    return Message(
      id: id,
      senderID: map['senderID'],
      content: map['content'],
      messageType: MessageType.values.firstWhere(
            (type) => type.toString() == 'MessageType.${map['messageType']}',
      ),
      sentAt: map['sentAt'],
      isRead: map['isRead'] ?? false,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json, {required String id}) {
    return Message(
      id: id,
      senderID: json['senderID'] as String?,
      content: json['content'] as String?,
      messageType: json['messageType'] != null
          ? MessageType.values.byName(json['messageType'])
          : null,
      sentAt: json['sentAt'] as Timestamp?,
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderID': senderID,
      'content': content,
      'messageType': messageType?.name,
      'sentAt': sentAt,
      'isRead': isRead,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'content': content,
      'messageType': messageType?.name,
      'sentAt': sentAt,
      'isRead': isRead,
    };
  }

  factory Message.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderID: data['senderID'] as String?,
      content: data['content'] as String?,
      messageType: data['messageType'] != null
          ? MessageType.values.byName(data['messageType'])
          : null,
      sentAt: data['sentAt'] as Timestamp?,
      isRead: data['isRead'] ?? false,
    );
  }
}