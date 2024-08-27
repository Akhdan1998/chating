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
      id: json['id'],
      participants: List<String>.from(json['participants'] ?? []),
      messages: json['messages'] != null
          ? List<Message>.from(json['messages'].map((x) => Message.fromJson(x)))
          : [],
    );
  }

  factory Chat.fromFirestore(Map<String, dynamic> data) {
    return Chat(
      id: data['id'],
      participants: List<String>.from(data['participants'] ?? []),
      messages: (data['messages'] ?? []).map<Message>((e) => Message.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['participants'] = participants;
    data['messages'] = messages!.map((e) => e.toJson()).toList();
    return data;
  }
}