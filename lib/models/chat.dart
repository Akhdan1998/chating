import 'message.dart';

class Chat {
  String? id;
  List<String>? participants;
  List<Message>? messages;

  Chat({
    required this.id,
    required this.participants,
    required this.messages,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String?,
      participants: List<String>.from(json['participants'] ?? []),
      messages: json['messages'] != null
          ? List<Message>.from(
        json['messages'].map((x) {
          try {
            return Message.fromJson(x, id: x['id'] ?? 'unknown_id');
          } catch (e) {
            print('Error parsing Message: $e');
            return Message(
              id: 'error_id',
              senderID: null,
              content: null,
              messageType: null,
              sentAt: null,
              isRead: false,
            );
          }
        }),
      )
          : [],
    );
  }

  factory Chat.fromFirestore(Map<String, dynamic> data) {
    return Chat(
      id: data['id'] as String?,
      participants: List<String>.from(data['participants'] ?? []),
      messages: (data['messages'] ?? []).map<Message>((e) {
        try {
          return Message.fromJson(e, id: e['id'] ?? 'unknown_id');
        } catch (e) {
          print('Error parsing Message: $e');
          return Message(
            id: 'error_id',
            senderID: null,
            content: null,
            messageType: null,
            sentAt: null,
            isRead: false,
          );
        }
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants ?? [], // Pastikan null-safe
      'messages': messages?.map((e) => e.toJson()).toList() ?? [],
    };
  }
}