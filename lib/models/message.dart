// import 'package:cloud_firestore/cloud_firestore.dart';
//
// enum MessageType { Text, Image }
//
// class Message {
//   String? senderID;
//   String? content;
//   MessageType? messageType;
//   Timestamp? sentAt;
//
//   Message({
//     required this.senderID,
//     required this.content,
//     required this.messageType,
//     required this.sentAt,
//   });
//
//   Message.fromJson(Map<String, dynamic> json) {
//     senderID = json['senderID'];
//     content = json['content'];
//     messageType = MessageType.values.byName(json['message']);
//     sentAt = json['sentAt'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['senderID'] = senderID;
//     data['content'] = content;
//     data['messageType'] = messageType!.name;
//     data['sentAt'] = sentAt;
//     return data;
//   }
// }

// import 'package:chating/models/user_profile.dart';
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

  // factory Message.fromFirestore(DocumentSnapshot doc) {
  //   Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  //   return Message(
  //     senderID: data['senderID'] as String?,
  //     content: data['content'] as String?,
  //     messageType: data['messageType'] != null
  //         ? MessageType.values.byName(data['messageType'])
  //         : null,
  //     sentAt: data['sentAt'] as Timestamp?,
  //   );
  // }

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