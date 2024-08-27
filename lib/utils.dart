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
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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