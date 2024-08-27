import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final List<MessageGroup>? messagesGroup;
  final String imageUrl;
  final List<String> members;
  final DateTime createdAt;
  final Timestamp latestMessageSentAt;
  // final String createdBy;

  Group({
    required this.id,
    required this.name,
    required this.messagesGroup,
    required this.imageUrl,
    required this.members,
    required this.createdAt,
    required this.latestMessageSentAt,
    // required this.createdBy,
  });

  factory Group.fromMap(Map<String, dynamic> data) {
    return Group(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      imageUrl: data['imageUrl'] ?? '',
      messagesGroup: (data['messagesGroup'] as List<dynamic>?)
          ?.map((item) => MessageGroup.fromMap(item))
          .toList(),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      latestMessageSentAt: data['latestMessageSentAt'] as Timestamp,
      // createdBy: data['createdBy'] ?? '',
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'messagesGroup': messagesGroup?.map((x) => x.toMap()).toList(),
      'imageUrl': imageUrl,
      'members': members,
      'createdAt': createdAt,
      'latestMessageSentAt': latestMessageSentAt,
      // 'createdBy': latestMessageSentAt,
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      messagesGroup: json['messagesGroup'] != null
          ? List<MessageGroup>.from(
          json['messagesGroup'].map((x) => MessageGroup.fromJson(x)))
          : [],
      imageUrl: json['imageUrl'] ?? '',
      members: List<String>.from(json['members'] ?? []),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String()),
      latestMessageSentAt: json['latestMessageSentAt'] is Timestamp
          ? (json['latestMessageSentAt'] as Timestamp)
          : Timestamp.now(),
      // createdBy: json['createdBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'messagesGroup': messagesGroup?.map((x) => x.toJson()).toList(),
      'imageUrl': imageUrl,
      'members': members,
      'createdAt': createdAt.toIso8601String(),
      'latestMessageSentAt': latestMessageSentAt,
      // 'createdBy': createdBy,
    };
  }
}

enum MessageTypeGroup {
  Text,
  Image,
  Document,
  Audio,
  Video,
}

class MessageGroup {
  final String senderID;
  final String content;
  final MessageTypeGroup messageTypeGroup;
  final Timestamp sentAt;
  final String groupId;

  MessageGroup({
    required this.senderID,
    required this.content,
    required this.messageTypeGroup,
    required this.sentAt,
    required this.groupId,
  });

  factory MessageGroup.fromMap(Map<String, dynamic> data) {
    return MessageGroup(
      senderID: data['senderID'],
      content: data['content'],
      messageTypeGroup: MessageTypeGroup.values[data['messageTypeGroup']],
      sentAt: data['sentAt'] as Timestamp,
      groupId: data['groupId'] ?? '',
    );
  }

  factory MessageGroup.fromJson(Map<String, dynamic> json) {
    return MessageGroup(
      senderID: json['senderID'],
      content: json['content'],
      messageTypeGroup: MessageTypeGroup.values[json['messageTypeGroup']],
      sentAt: json['sentAt'] as Timestamp,
      groupId: json['groupId'] ?? '',
    );
  }

  factory MessageGroup.fromDocument(DocumentSnapshot doc) {
    return MessageGroup(
      senderID: doc['senderID'],
      content: doc['content'],
      messageTypeGroup: MessageTypeGroup.values.firstWhere(
            (e) => e.toString() == 'MessageTypeGroup.${doc['messageTypeGroup']}',
      ),
      sentAt: doc['sentAt'] as Timestamp,
      groupId: doc['groupId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['senderID'] = senderID;
    data['content'] = content;
    data['messageTypeGroup'] = messageTypeGroup.index;
    data['sentAt'] = sentAt;
    data['groupId'] = groupId;
    return data;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['senderID'] = senderID;
    data['content'] = content;
    data['messageTypeGroup'] = messageTypeGroup.index;
    data['sentAt'] = sentAt.millisecondsSinceEpoch;
    data['groupId'] = groupId;
    return data;
  }
}