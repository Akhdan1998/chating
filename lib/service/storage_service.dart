import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  StorageService() {}

  Future<String?> uploadUserPfp({
    required File file,
    required String uid,
  }) async {
    Reference fileRef = _firebaseStorage
        .ref('users/pfps')
        .child('$uid${p.extension(file.path)}');
    UploadTask task = fileRef.putFile(file);
    return task.then((e) {
      if (e.state == TaskState.success) {
        return fileRef.getDownloadURL();
      }
    });
  }

  Future<String?> uploadImageToChat(
      {required File file, required String chatID}) async {
    Reference fileRef = _firebaseStorage
        .ref('chats/$chatID')
        .child('${DateTime.now().toIso8601String()}${p.extension(file.path)}');
    UploadTask task = fileRef.putFile(file);
    return task.then((e) {
      if (e.state == TaskState.success) {
        return fileRef.getDownloadURL();
      }
      return null;
    });
  }

  Future<String?> uploadVideoToChat({required File file, required String chatID}) async {
    try {
      String fileName = 'videoMedia/${DateTime.now().toIso8601String()}${p.extension(file.path)}.mp4';
      Reference ref = _firebaseStorage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading video: $e');
      return null;
    }
  }

  // Future<String?> saveChatImageToStorage({required File file, required String chatID}) async {
  //   try {
  //     String fileName = p.basename(file.path);
  //     Reference storageRef = _firebaseStorage.ref().child('chats/$chatID/images/$fileName');
  //     UploadTask uploadTask = storageRef.putFile(file);
  //     TaskSnapshot snapshot = await uploadTask;
  //     String downloadURL = await snapshot.ref.getDownloadURL();
  //     return downloadURL;
  //   } catch (e) {
  //     print('Error uploading image: $e');
  //     return null;
  //   }
  // }

}
