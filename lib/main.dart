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

import 'dart:ui';

import 'package:chating/service/auth_service.dart';
import 'package:chating/service/navigation_service.dart';
import 'package:chating/utils.dart';
import 'package:chating/widgets/navigasi.dart';
import 'package:chating/wkwk_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    return MultiBlocProvider(
        providers: [
        BlocProvider(create: (_) => VCCubit()),
      ],
      child: MaterialApp(
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
      ),
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
  double topPosition1 = -30;
  double rightPosition2 = -30;
  double topPosition3 = 150;
  double bottomPosition4 = 150;
  double leftPosition5 = -30;
  double bottomPosition6 = 0;

  @override
  void initState() {
    super.initState();
    _authService = _getIt<AuthService>();

    Future.delayed(Duration.zero, () {
      setState(() {
        topPosition1 = 450;
        rightPosition2 = 450;
        topPosition3 = -200;
        bottomPosition4 = 380;
        leftPosition5 = 350;
        bottomPosition6 = 450;
      });
    });

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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [0.1, 0.5, 0.7, 0.9],
            colors: [
              Colors.deepPurple.shade500,
              Theme.of(context).colorScheme.primary,
              Colors.deepPurple.shade500,
              Theme.of(context).colorScheme.primary,
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildAnimatedCircle(top: topPosition1, right: 130, waktu: 2, size: 100),
            _buildAnimatedCircle(top: -30, right: rightPosition2, waktu: 3, size: 200),
            _buildAnimatedCircle(top: topPosition3, right: -60, waktu: 3, size: 150),
            _buildAnimatedCircle(bottom: bottomPosition4, right: -30, waktu: 4, size: 150),
            _buildAnimatedCircle(bottom: -60, left: leftPosition5, waktu: 5, size: 250),
            _buildAnimatedCircle(bottom: bottomPosition6, left: -30, waktu: 3, size: 200),
            _buildAnimatedCircle(bottom: 0, left: 0, waktu: 0, size: 0), // spam tapi harus ada
            Center(
              child: Image.asset(
                'assets/splash.png',
                scale: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCircle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required int waktu,
    required double size,
  }) {
    return AnimatedPositioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      duration: Duration(seconds: waktu),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.purple.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

// class SplashScreen extends StatefulWidget {
//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   final GetIt _getIt = GetIt.instance;
//   late AuthService _authService;
//   late NavigationService _navigationService;
//   double topPosition1 = -30;
//   double rightPosition2 = -30;
//   double topPosition3 = 150;
//   double bottomPosition4 = 150;
//   double leftPosition5 = -30;
//   double bottomPosition6 = 140;
//
//   @override
//   void initState() {
//     super.initState();
//     _authService = _getIt<AuthService>();
//     _navigationService = _getIt<NavigationService>();
//
//     Future.delayed(Duration(seconds: 3), () {
//       _authService.user != null
//           ? _navigationService.pushReplacementNamed("/navigasi")
//           : _navigationService.pushReplacementNamed("/login");
//     });
//
//     Future.delayed(Duration.zero, () {
//       setState(() {
//         topPosition1 = 450;
//         rightPosition2 = 450;
//         topPosition3 = -200;
//         bottomPosition4 = 380;
//         leftPosition5 = 350;
//         bottomPosition6 = -250;
//       });
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.centerLeft,
//           end: Alignment.centerLeft,
//           stops: [0.1, 0.5, 0.7, 0.9],
//           colors: [
//             Colors.deepPurple.shade500,
//             Theme.of(context).colorScheme.primary,
//             Colors.deepPurple.shade500,
//             Theme.of(context).colorScheme.primary,
//           ],
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         body: Stack(
//           children: [
//             AnimatedPositioned(
//               top: topPosition1,
//               right: 130,
//               duration: Duration(seconds: 10),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
//                 child: Container(
//                   width: 100,
//                   height: 100,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.purple,
//                   ),
//                 ),
//               ),
//             ),
//             AnimatedPositioned(
//               top: -30,
//               right: rightPosition2,
//               duration: Duration(seconds: 10),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
//                 child: Container(
//                   width: 200,
//                   height: 200,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.purple,
//                   ),
//                 ),
//               ),
//             ),
//             AnimatedPositioned(
//               top: topPosition3,
//               right: -60,
//               duration: Duration(seconds: 10),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
//                 child: Container(
//                   width: 150,
//                   height: 150,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.purple,
//                   ),
//                 ),
//               ),
//             ),
//             AnimatedPositioned(
//               bottom: bottomPosition4,
//               right: -30,
//               duration: Duration(seconds: 10),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
//                 child: Container(
//                   width: 150,
//                   height: 150,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.purple,
//                   ),
//                 ),
//               ),
//             ),
//             AnimatedPositioned(
//               bottom: -60,
//               left: leftPosition5,
//               duration: Duration(seconds: 10),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
//                 child: Container(
//                   width: 250,
//                   height: 250,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.purple,
//                   ),
//                 ),
//               ),
//             ),
//             AnimatedPositioned(
//               bottom: bottomPosition6,
//               left: -80,
//               duration: Duration(seconds: 10),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
//                 child: Container(
//                   width: 200,
//                   height: 200,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.purple,
//                   ),
//                 ),
//               ),
//             ),
//             Center(
//               child: Image.asset(
//                 'assets/splash.png',
//                 scale: 6,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }