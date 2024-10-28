import 'package:audioplayers/audioplayers.dart';
import 'package:chating/service/alert_service.dart';
import 'package:chating/service/auth_service.dart';
import 'package:chating/service/database_service.dart';
import 'package:chating/service/media_service.dart';
import 'package:chating/service/navigation_service.dart';
import 'package:chating/service/storage_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'main.dart';

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
    '007eJxTYGhXT/75sGu6tYHJp/u/r4W53rcyLlyYfJVb8kea1MU5k3YqMKSkmhummJlYphmnGpmYWFgmmSSZmSUmpxiYW1oYJ1qaHXgvl94QyMjQcMOElZEBAkF8NobS4tQizxQGBgD/yCGa';

String appIdGroupAudio = '3cdecaec34ea49c38355b28f5d803ac0';
String tokenGroupAudio =
    '007eJxTYMhVlljxRr1De0f/mnvHuZotJ+/98Zwpa9ItwZUn9C03fZJQYDBOTklNTkxNNjZJTTSxTDa2MDY1TTKySDNNsTAwTkw2ePteLr0hkJGBhaGJgREKQXw2htLi1CLPFAYGAMwdIK0=';

String appIdAudio = 'fecb15824e0c4e888662459c3b74c273';
String tokenAudio =
    '007eJxTYLgjWSnqtI67eVbtr+bzG3jnTgqQSbvC9JwrMl0yNHX3H2kFhrTU5CRDUwsjk1SDZJNUCwsLMzMjE1PLZOMkc5NkI3Nj3Q9y6Q2BjAxTa5WYGBkgEMRnYygtTi3yTGFgAAAIOh3w';

String appIdVideo = 'be76645285084ce7a1d7d4cd2bd94dd0';
String tokenVideo =
    '007eJxTYOg4LKDrlpjgsXGuoZyMT86bHgO/HvcrvCx/0+7OcZHtYlZgSEk1N0wxM7FMM041MjGxsEwySTIzS0xOMTC3tDBOtDSr/SCX3hDIyKD3ppyVkQECQXw2htLi1CLPFAYGAJplHUs=';

String channel = "userId";

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    if (message.notification != null) {
      print('Title: ${message.notification!.title}');
      print('Body: ${message.notification!.body}');
    } else {
      print('No notification data.');
    }
    print('Payload: ${message.data}');
  }

  Future<void> initNotification() async {
    await _firebaseMessaging.requestPermission();
    final FCMToken = await _firebaseMessaging.getToken();
    print('TOKEN: $FCMToken');
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  }
}