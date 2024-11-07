import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:chating/service/alert_service.dart';
import 'package:chating/service/auth_service.dart';
import 'package:chating/service/database_service.dart';
import 'package:chating/service/media_service.dart';
import 'package:chating/service/navigation_service.dart';
import 'package:chating/service/storage_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/painting/text_style.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
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
    '007eJxTYBAXOmMdpSyYNCWI+/78MC1O5uQ6mWW/ZZ+mRrc9bgvoCVZgSEk1N0wxM7FMM041MjGxsEwySTIzS0xOMTC3tDBOtDRLD1BIbwhkZLiRc4uJkQECQXw2htLi1CLPFAYGAG1kHPo=';

String appIdGroupAudio = '3cdecaec34ea49c38355b28f5d803ac0';
String tokenGroupAudio =
    '007eJxTYDAL+CBQtsSwomzmMa+6P883ODy9y+7U41n7fI28Nss6k0cKDMbJKanJianJxiapiSaWycYWxqamSUYWaaYpFgbGickGrQEK6Q2BjAxPZzQzMEIhiM/GUFqcWuSZwsAAALYuILw=';

String appIdAudio = 'fecb15824e0c4e888662459c3b74c273';
String tokenAudio =
    '007eJxTYJh+O1Kib+qi2eVPpG8cPXQ5by33+8is5mk9FWUqpzZFiv9WYEhLTU4yNLUwMkk1SDZJtbCwMDMzMjG1TDZOMjdJNjI3ntmlk94QyMgQ8PQAAyMUgvhsDKXFqUWeKQwMACOTIdY=';

String appIdVideo = 'be76645285084ce7a1d7d4cd2bd94dd0';
String tokenVideo =
    '007eJxTYChI22i75uRG52XBs1jqLsxak/Axf3Ggh39+4/Z9vh0TZ5YrMCSlmpuZmZgaWZgaWJgkp5onGqaYp5gkpxglpViapKQYHAlQSG8IZGTwvsDIysgAgSA+G0NpcWqRZwoDAwDIZCCL';

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

TextStyle StyleText({
  double fontSize = 15,
  FontWeight fontWeight = FontWeight.normal,
  Color color = Colors.black,
}) {
  return GoogleFonts.poppins(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );
}
