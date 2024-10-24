// import 'package:chating/service/alert_service.dart';
// import 'package:chating/service/auth_service.dart';
// import 'package:chating/service/database_service.dart';
// import 'package:chating/service/media_service.dart';
// import 'package:chating/service/navigation_service.dart';
// import 'package:chating/service/storage_service.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:get_it/get_it.dart';
//
// import 'firebase_options.dart';
//
// Future<void> setupFirebase() async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
// }
//
// Future<void> registerService() async {
//   final GetIt getIt = GetIt.instance;
//   getIt.registerSingleton<AuthService>(
//     AuthService(),
//   );
//   getIt.registerSingleton<NavigationService>(
//     NavigationService(),
//   );
//   getIt.registerSingleton<AlertService>(
//     AlertService(),
//   );
//   getIt.registerSingleton<MediaService>(
//     MediaService(),
//   );
//   getIt.registerSingleton<StorageService>(
//     StorageService(),
//   );
//   getIt.registerSingleton<DatabaseService>(
//     DatabaseService(),
//   );
// }
//
// String genereteChatID({required String uid1, required String uid2}) {
//   List uids = [uid1, uid2];
//   uids.sort();
//   String chatID = uids.fold("", (id, uid) => "$id$uid");
//   return chatID;
// }
//
// String generateChatIDGrup({required List<String> uids}) {
//   uids.sort();
//   String chatID =
//       uids.fold("", (id, uid) => "$id$uid"); // Menggabungkan semua UID
//   return chatID;
// }

import 'package:chating/service/alert_service.dart';
import 'package:chating/service/auth_service.dart';
import 'package:chating/service/database_service.dart';
import 'package:chating/service/media_service.dart';
import 'package:chating/service/navigation_service.dart';
import 'package:chating/service/storage_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';

import 'firebase_options.dart';

Future<void> setupFirebase() async {
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    print(e);
    // Handle initialization error here
  }
}

Future<void> registerService() async {
  final GetIt getIt = GetIt.instance;
  getIt.registerSingleton<AuthService>(AuthService());
  getIt.registerSingleton<NavigationService>(NavigationService());
  getIt.registerSingleton<AlertService>(AlertService());
  getIt.registerSingleton<MediaService>(MediaService());
  getIt.registerSingleton<StorageService>(StorageService());
  getIt.registerSingleton<DatabaseService>(DatabaseService());
}

String genereteChatID({required String uid1, required String uid2}) {
  List<String> uids = [uid1, uid2];
  uids.sort();
  String chatID = uids.join();
  return chatID;
}

String appIdGroupVideo = 'de71d649f3e24489b4b66acd07983a96';
String tokenGroupVideo =
    '007eJxTYDjbmqm7PE/TM7FEiDfTkGFCrsDafQyut/2uHzY/pbU7+7YCQ0qquWGKmYllmnGqkYmJhWWSSZKZWWJyioG5pYVxoqXZux+S6Q2BjAweZSeYGRkgEMRnYygtTi3yTGFgAADk2B6b';

String appIdGroupAudio = '3cdecaec34ea49c38355b28f5d803ac0';
String tokenGroupAudio =
    '007eJxTYDDM97+26S9/xhwjRsMAUXXT5K42O7aip3eO2/+paS7Nf63AYJyckpqcmJpsbJKaaGKZbGxhbGqaZGSRZppiYWCcmGwg/FMyvSGQkeHRrzxmRgYIBPHZGEqLU4s8UxgYADx5H+Q=';

String appIdAudio = 'fecb15824e0c4e888662459c3b74c273';
String tokenAudio =
    '007eJxTYNBxbbx6b/6S3u2XfM1sFUqUs5j/t0Y3KfZvslP4F/ZO+5YCQ1pqcpKhqYWRSapBskmqhYWFmZmRiallsnGSuUmykbmx/k/J9IZARga+fcdZGBkgEMRnYygtTi3yTGFgAABg1B9T';

String appIdVideo = 'be76645285084ce7a1d7d4cd2bd94dd0';
String tokenVideo =
    '007eJxTYFinz6afk67VZiNd4jf7QVNKZnXaj6o7AptKOmbV3+fZxqPAkJRqbmZmYmpkYWpgYZKcap5omGKeYpKcYpSUYmmSkmLg+VMyvSGQkSF8yTYWRgYIBPHZGEqLU4s8UxgYAAQzHvM=';

String channel = "userId";
