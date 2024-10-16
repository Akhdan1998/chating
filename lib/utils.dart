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
    '007eJxTYMjwyb6zIaLyQcKNg7qWnycFn/x+2oRp74TwyVzS+ffPLF6uwJCSam6YYmZimWacamRiYmGZZJJkZpaYnGJgbmlhnGhp1sbIl94QyMiw7NReZkYGCATx2RhKi1OLPFMYGAD6syFD';

String appIdGroupAudio = '3cdecaec34ea49c38355b28f5d803ac0';
String tokenGroupAudio =
    '007eJxTYGDc/jL1KQ9rh/vbpf7fJZyEzWVXXJwruYvvf3zidtYqN0YFBuPklNTkxNRkY5PURBPLZGMLY1PTJCOLNNMUCwPjxGSDFwx86Q2BjAx2imnMjAwQCOKzMZQWpxZ5pjAwAADtsx1h';

String appIdAudio = 'fecb15824e0c4e888662459c3b74c273';
String tokenAudio =
    '007eJxTYHC3auzumxavVVa/50eg88MdZ2cXtKaIWou0rU+UrlN89kaBIS01OcnQ1MLIJNUg2STVwsLCzMzIxNQy2TjJ3CTZyNzYiJEvvSGQkeFG5C5GRgYIBPHZGEqLU4s8UxgYAEurHrU=';

String appIdVideo = 'be76645285084ce7a1d7d4cd2bd94dd0';
String tokenVideo =
    '007eJxTYDh/we6+iECY3aeCGsX77n7XbXXj9KWO53zZKREk7xV2gFWBISnV3MzMxNTIwtTAwiQ51TzRMMU8xSQ5xSgpxdIkJcUgnZEvvSGQkaH4sDorIwMEgvhsDKXFqUWeKQwMANKtHS0=';

String channel = "userId";
