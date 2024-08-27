import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  String? uid;
  String? name;
  String? pfpURL;
  String? phoneNumber;
  String? email;
  final bool hasUploadedStory;
  bool isViewed;

  UserProfile({
    this.uid,
    this.name,
    this.pfpURL,
    this.phoneNumber,
    this.email,
    this.hasUploadedStory = false,
    this.isViewed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'pfpURL': pfpURL,
      'phoneNumber': phoneNumber,
      'email': email,
      'hasUploadedStory': hasUploadedStory,
      'isViewed': isViewed,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'],
      name: json['name'],
      pfpURL: json['pfpURL'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'pfpURL': pfpURL,
      'phoneNumber': phoneNumber,
      'email': email,
    };
  }

  factory UserProfile.fromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return UserProfile(
      uid: data['uid'],
      name: data['name'],
      pfpURL: data['pfpURL'],
      phoneNumber: data['phoneNumber'],
      email: data['email'],
    );
  }

  factory UserProfile.fromDocument(DocumentSnapshot document) {
    Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception("DocumentSnapshot is null or empty");
    }
    return UserProfile(
      uid: data['uid'] as String?,
      name: data['name'] as String?,
      pfpURL: data['pfpURL'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      email: data['email'] as String?,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String?,
      name: map['name'] as String?,
      pfpURL: map['pfpURL'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      email: map['email'] as String?,
      hasUploadedStory: map['hasUploadedStory'] as bool? ?? false,
      isViewed: map['isViewed'] ?? false,
    );
  }
}