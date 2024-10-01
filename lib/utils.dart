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
    '007eJxTYNDb/GiZO1v7qn+7OucVtHjNvXH3dc4Wmc95unsfaS1uY3FUYEhJNTdMMTOxTDNONTIxsbBMMkkyM0tMTjEwt7QwTrQ0+7/kd1pDICODquB6VkYGCATx2RhKi1OLPFMYGAA2jCIz';

String appIdGroupAudio = '3cdecaec34ea49c38355b28f5d803ac0';
String tokenGroupAudio =
    '007eJxTYLjKNElMRf+jEN/F1BNS38+6mm6bUrA2+VrelvzGN5qiS2UVGIyTU1KTE1OTjU1SE00sk40tjE1Nk4ws0kxTLAyME5MNJJf9TmsIZGSYJVTCyMgAgSA+G0NpcWqRZwoDAwBj6x+9';

String appIdAudio = 'fecb15824e0c4e888662459c3b74c273';
String tokenAudio =
    '007eJxTYHh98K+V/wfNN7sn1b44tOrh7uCLTuLhTCkKe5d3KGXuXf9OgSEtNTnJ0NTCyCTVINkk1cLCwszMyMTUMtk4ydwk2cjcWGHJ77SGQEaGlzY1TIwMEAjiszGUFqcWeaYwMAAAdWcirg==';

String appIdVideo = 'be76645285084ce7a1d7d4cd2bd94dd0';
String tokenVideo =
    '007eJxTYLj2rfV94ryD5ge2VousfRYfcnDhmxZzrrX8FzXKb2aVG/QpMCSlmpuZmZgaWZgaWJgkp5onGqaYp5gkpxglpViapKQYVC/+ndYQyMjgcF+GmZEBAkF8NobS4tQizxQGBgBAIiJG';

String channel = "userId";
