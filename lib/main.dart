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

    if (_authService.user != null) {
      _initialPage = Navigasi();
    } else {
      _initialPage = SplashScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final NavigationService navigationService = _getIt<NavigationService>();
    return MaterialApp(
      navigatorKey: navigationService.navigatorKey,
      color: Colors.blueGrey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.montserratTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
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

  @override
  void initState() {
    super.initState();
    _authService = _getIt<AuthService>();

    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(
        context,
        _authService.user != null ? "/navigasi" : "/login",
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: Colors.blueGrey,
        child: Center(
          child: Image.asset(
            'assets/splash.png',
            scale: 6,
          ),
        ),
      ),
    );
  }
}
