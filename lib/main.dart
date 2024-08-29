// import 'package:chating/service/auth_service.dart';
// import 'package:chating/service/navigation_service.dart';
// import 'package:chating/utils.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:get_it/get_it.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await setup();
//   runApp(MyApp());
// }
//
// Future<void> setup() async {
//   await setupFirebase();
//   await registerService();
// }
//
// class MyApp extends StatelessWidget {
//   final GetIt _getIt = GetIt.instance;
//   late NavigationService _navigationService;
//   late AuthService _authService;
//
//   MyApp({super.key}) {
//     _navigationService = _getIt.get<NavigationService>();
//     _authService = _getIt.get<AuthService>();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       color: Theme.of(context).colorScheme.primary,
//       navigatorKey: _navigationService.navigatorKey,
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         textTheme: GoogleFonts.montserratTextTheme(),
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       initialRoute: _authService.user != null ? "/navigasi" : "/login",
//       routes: _navigationService.routes,
//     );
//   }
// }

import 'package:chating/service/auth_service.dart';
import 'package:chating/service/navigation_service.dart';
import 'package:chating/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setup();
  runApp(MyApp());
}

Future<void> setup() async {
  await setupFirebase();
  await registerService();
}

class MyApp extends StatelessWidget {
  final GetIt _getIt = GetIt.instance;

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Theme.of(context).colorScheme.primary,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.montserratTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(), // SplashScreen sebagai halaman awal
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NavigationService _navigationService;

  @override
  void initState() {
    super.initState();
    _authService = _getIt<AuthService>();
    _navigationService = _getIt<NavigationService>();

    Future.delayed(Duration(seconds: 3), () {
      if (_authService.user != null) {
        print("User terdeteksi, navigasi ke /navigasi");
        _navigationService.pushNamed("/navigasi");
        // _navigationService.navigatorKey.currentState?.pushReplacementNamed('/navigasi'); // Jika user login, arahkan ke navigasi
      } else {
        print("User tidak terdeteksi, navigasi ke /login");
        _navigationService.pushNamed("/login");
        // _navigationService.navigatorKey.currentState?.pushReplacementNamed('/login'); // Jika belum login, arahkan ke login
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Image.asset(
          'assets/splash.png',
          scale: 6,
        ),
      ),
    );
  }
}