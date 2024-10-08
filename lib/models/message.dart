import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { Text, Image, Document, Audio, Video }

class Message {
  String? senderID;
  String? content;
  MessageType? messageType;
  Timestamp? sentAt;
  bool isRead;

  Message({
    required this.senderID,
    required this.content,
    required this.messageType,
    required this.sentAt,
    required this.isRead,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderID: map['senderID'],
      content: map['content'],
      messageType: MessageType.values.firstWhere(
            (type) => type.toString() == 'MessageType.${map['messageType']}',
      ),
      sentAt: map['sentAt'],
      isRead: map['isRead'] ?? false,
    );
  }

  Message.fromJson(Map<String, dynamic> json)
      : senderID = json['senderID'] as String?,
        content = json['content'] as String?,
        messageType = json['messageType'] != null
            ? MessageType.values.byName(json['messageType'])
            : null,
        sentAt = json['sentAt'] as Timestamp?,
        isRead = json['isRead'] ?? false;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['senderID'] = senderID;
    data['content'] = content;
    data['messageType'] = messageType?.name;
    data['sentAt'] = sentAt;
    data['isRead'] = isRead;
    return data;
  }

  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'content': content,
      'messageType': messageType.toString().split('.').last,
      'sentAt': sentAt,
      'isRead': isRead,
    };
  }

  factory Message.fromDocument(DocumentSnapshot doc) {
    return Message(
      senderID: doc['senderID'],
      content: doc['content'],
      messageType: MessageType.values.firstWhere((type) => type.toString() == 'MessageType.${doc['messageType']}'),
      sentAt: doc['sentAt'],
      isRead: doc['isRead'] ?? false,
    );
  }
}