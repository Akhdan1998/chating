import 'package:chating/models/chat.dart';
import 'package:chating/models/message.dart';
import 'package:chating/models/user_profile.dart';
import 'package:chating/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import '../models/group.dart';
import 'auth_service.dart';

class DatabaseService {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final GetIt _getIt = GetIt.instance;

  CollectionReference? _usersCollection;
  CollectionReference? _chatCollection;
  CollectionReference? _groupsCollection;

  late AuthService _authService;

  DatabaseService() {
    _authService = _getIt.get<AuthService>();
    _setupCollectionReferences();
  }

  User? getCurrentUser() {
    return _authService.getCurrentUser();
  }

  void _setupCollectionReferences() {
    _usersCollection =
        _firebaseFirestore.collection('users').withConverter<UserProfile>(
              fromFirestore: (snapshot, _) =>
                  UserProfile.fromJson(snapshot.data()!),
              toFirestore: (userProfile, _) => userProfile.toJson(),
            );

    _chatCollection = _firebaseFirestore
        .collection('chats')
        .withConverter<Chat>(
            fromFirestore: (snapshots, _) => Chat.fromJson(snapshots.data()!),
            toFirestore: (chat, _) => chat.toJson());

    _groupsCollection = _firebaseFirestore.collection('groups');
  }

  Future<void> createUserProfile({required UserProfile userProfile}) async {
    await _usersCollection?.doc(userProfile.uid).set(userProfile);
    await _firebaseFirestore
        .collection('users')
        .doc(userProfile.uid)
        .set(userProfile.toMap());
  }

  Stream<QuerySnapshot<UserProfile>> getUserProfiles() {
    if (_usersCollection == null) {
      throw Exception("Users collection is not initialized.");
    }

    if (_authService.user == null) {
      throw Exception("User is not authenticated.");
    }

    return _usersCollection!
        .where("uid", isNotEqualTo: _authService.user!.uid)
        .snapshots()
        .map((snapshot) => snapshot as QuerySnapshot<UserProfile>);
  }

  Future<void> addMembersToGroup(String groupId, List<String> memberIds) async {
    // Reference to the group document
    DocumentReference groupRef =
        _firebaseFirestore.collection('groups').doc(groupId);

    // Perform the update
    await _firebaseFirestore.runTransaction((transaction) async {
      // Get the group document snapshot
      DocumentSnapshot groupSnapshot = await transaction.get(groupRef);

      if (groupSnapshot.exists) {
        // Get current members
        List<dynamic> currentMembers = groupSnapshot.get('members');

        // Add new members to the current members list
        List<String> updatedMembers = List<String>.from(currentMembers)
          ..addAll(memberIds);

        // Remove duplicates by converting to a Set and back to a List
        updatedMembers = updatedMembers.toSet().toList();

        // Update the group document with the new members list
        transaction.update(groupRef, {'members': updatedMembers});
      }
    });
  }

  Future<bool> checkChatExist(String uid1, String uid2) async {
    String chatID = genereteChatID(uid1: uid1, uid2: uid2);
    final result = await _chatCollection!.doc(chatID).get();
    if (result != null && result.exists) {
      return result.exists;
    }
    return false;
  }

  Future<void> createNewChat(String uid1, String uid2) async {
    String chatID = genereteChatID(uid1: uid1, uid2: uid2);
    final docRef = _chatCollection!.doc(chatID);
    final chat = Chat(
      id: chatID,
      participants: [uid1, uid2],
      messages: [],
    );
    await docRef.set(chat);
  }

  Future<void> sendChatMessage(
      String uid1, String uid2, Message message) async {
    String chatID = genereteChatID(uid1: uid1, uid2: uid2);
    final docRef = _chatCollection!.doc(chatID);

    try {
      // Cek apakah dokumen sudah ada
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        // Perbarui pesan jika dokumen ada
        await docRef.update({
          "messages": FieldValue.arrayUnion([message.toJson()]),
        });
      } else {
        // Buat dokumen baru jika belum ada
        await docRef.set({
          "participants": [uid1, uid2],
          "messages": [message.toJson()],
        });
      }
    } catch (e) {
      print("Error updating chat message: $e");
    }
  }

  Future<void> deleteChatMessage(
      String currentUserId,
      String otherUserId,
      String messageId,
      ) async {
    try {
      await _firebaseFirestore
          .collection('chats')
          .doc(currentUserId)
          .collection('messages')
          .doc(messageId)
          .delete();
      print("Pesan berhasil dihapus dari database.");
    } catch (e) {
      print("Error saat menghapus pesan: $e");
      rethrow;
    }
  }

  // Future<void> sendChatMessage(
  //     String uid1, String uid2, Message message) async {
  //   String ChatID = genereteChatID(uid1: uid1, uid2: uid2);
  //   final docRef = _chatCollection!.doc(ChatID);
  //   await docRef.update({
  //     "messages": FieldValue.arrayUnion(
  //       [
  //         message.toJson(),
  //       ],
  //     ),
  //   });
  // }

  Stream<DocumentSnapshot<Chat>> getChatData(String uid1, String uid2) {
    String chatID = genereteChatID(uid1: uid1, uid2: uid2);
    return _chatCollection!.doc(chatID).snapshots()
        as Stream<DocumentSnapshot<Chat>>;
  }

  Future<String> getPhoneNumberFromFirestore(String uid) async {
    try {
      DocumentSnapshot<UserProfile> userProfileSnapshot =
          await _usersCollection!.doc(uid).get()
              as DocumentSnapshot<UserProfile>;
      if (userProfileSnapshot.exists) {
        UserProfile userProfile = userProfileSnapshot.data()!;
        return userProfile.phoneNumber ?? '';
      } else {
        throw Exception('User profile not found');
      }
    } catch (e) {
      throw Exception('Error fetching phone number: $e');
    }
  }

  Stream<QuerySnapshot> getChatGroups() {
    return _groupsCollection!.snapshots();
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .update({
        'members': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      print('Error leaving group: $e');
      throw Exception('Failed to leave the group');
    }
  }

  Future<void> deleteMessage(
      String currentUserId, String otherUserId, String messageId) async {
    try {
      await _firebaseFirestore
          .collection('chats')
          .doc(currentUserId)
          .collection(otherUserId)
          .doc(messageId)
          .delete();
    } catch (e) {
      print('Error deleting message: $e');
      throw Exception('Failed to delete message');
    }
  }

  Future<Group> getGroupById(String groupId) async {
    DocumentSnapshot groupSnapshot =
        await _firebaseFirestore.collection('groups').doc(groupId).get();

    if (groupSnapshot.exists) {
      return Group.fromMap(groupSnapshot.data() as Map<String, dynamic>);
    } else {
      throw Exception('Group not found');
    }
  }

  void online(String userId) {
    _firebaseFirestore.collection('users').doc(userId).update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  void offline(String userId) {
    _firebaseFirestore.collection('users').doc(userId).update({
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}
