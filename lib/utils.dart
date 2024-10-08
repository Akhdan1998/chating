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
    '007eJxTYJhiwtloftVL7sG8aj2GUo3UJU2ycd6d+VaqRYdO+ZqJiCkwpKSaG6aYmVimGacamZhYWCaZJJmZJSanGJhbWhgnWprx9zKnNwQyMmxeZcDACIUgPhtDaXFqkWcKAwMAOSIbcw==';

String appIdGroupAudio = '3cdecaec34ea49c38355b28f5d803ac0';
String tokenGroupAudio =
    '007eJxTYJB9lZeTtGlVq2nEvV08MZ7uRgxVR3p2FPszSnt2shZtOK7AYJyckpqcmJpsbJKaaGKZbGxhbGqaZGSRZppiYWCcmGyg6cic3hDIyFC/4hkjIwMEgvhsDKXFqUWeKQwMAPVsHho=';

String appIdAudio = 'fecb15824e0c4e888662459c3b74c273';
String tokenAudio =
    '007eJxTYKhMvbhNu3rRbOsk4ZPNlTum7G5QSg9X8v6vr+Ttcv36r0IFhrTU5CRDUwsjk1SDZJNUCwsLMzMjE1PLZOMkc5NkI3Pjaz//pDUEMjJwqi5hYWSAQBCfjaG0OLXIM4WBAQCTrSBa';

String appIdVideo = 'be76645285084ce7a1d7d4cd2bd94dd0';
String tokenVideo =
    '007eJxTYJi722fKo5Tbp/pao4LmeRcIe0/NrFRL/hnB13VKUtZ2A6cCQ1KquZmZiamRhamBhUlyqnmiYYp5iklyilFSiqVJSooB/68/aQ2BjAyeexewMDJAIIjPxlBanFrkmcLAAABhdB/e';

String channel = "userId";
