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
import 'package:chating/widgets/navigasi.dart';
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

class MyApp extends StatefulWidget {

  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NavigationService _navigationService;
  late Widget _initialPage;

  @override
  void initState() {
    super.initState();
    _authService = _getIt<AuthService>();
    _navigationService = _getIt<NavigationService>();

    // Cek apakah user sudah login
    if (_authService.user != null) {
      _initialPage = Navigasi(); // Jika sudah login, arahkan langsung ke halaman navigasi
    } else {
      _initialPage = SplashScreen(); // Jika belum login, tampilkan splash screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final NavigationService navigationService = _getIt<NavigationService>();
    return MaterialApp(
      navigatorKey: navigationService.navigatorKey,
      color: Theme.of(context).colorScheme.primary,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.montserratTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: _navigationService.routes,
      home: _initialPage,
      // routes: navigationService.routes,
      // home: SplashScreen(),
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
  double topPosition1 = -30;
  double rightPosition2 = -30;
  double topPosition3 = 150;
  double bottomPosition4 = 150;
  double leftPosition5 = -30;
  double bottomPosition6 = 140;

  @override
  void initState() {
    super.initState();
    _authService = _getIt<AuthService>();
    _navigationService = _getIt<NavigationService>();

    Future.delayed(Duration(seconds: 3), () {
      _authService.user != null
          ? _navigationService.pushReplacementNamed("/navigasi")
          : _navigationService.pushReplacementNamed("/login");
    });

    Future.delayed(Duration.zero, () {
      setState(() {
        topPosition1 = 400;
        rightPosition2 = 400;
        topPosition3 = -150;
        bottomPosition4 = 330;
        leftPosition5 = 300;
        bottomPosition6 = -200;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerLeft,
          stops: [0.1, 0.5, 0.7, 0.9],
          colors: [
            Colors.deepPurple.shade500,
            Theme.of(context).colorScheme.primary,
            Colors.deepPurple.shade500,
            Theme.of(context).colorScheme.primary,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            AnimatedPositioned(
              top: topPosition1,
              right: 130,
              duration: Duration(seconds: 3),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            AnimatedPositioned(
              top: -30,
              right: rightPosition2,
              duration: Duration(seconds: 3),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            AnimatedPositioned(
              top: topPosition3,
              right: -60,
              duration: Duration(seconds: 3),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            Center(
              child: Image.asset(
                'assets/splash.png',
                scale: 6,
              ),
            ),
            AnimatedPositioned(
              bottom: bottomPosition4,
              right: -30,
              duration: Duration(seconds: 3),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            AnimatedPositioned(
              bottom: -60,
              left: leftPosition5,
              duration: Duration(seconds: 3),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            AnimatedPositioned(
              bottom: bottomPosition6,
              left: -80,
              duration: Duration(seconds: 3),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}