import 'package:chating/pages/connection/home_page.dart';
import 'package:chating/pages/identitas/login_page.dart';
import 'package:chating/pages/identitas/register_page.dart';
import 'package:flutter/material.dart';
import '../pages/identitas/onBoarding.dart';
import '../pages/identitas/updatePassword_page.dart';
import '../pages/identitas/verifikasi_page.dart';
import '../widgets/navigasi.dart';

class NavigationService {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  final Map<String, Widget Function(BuildContext)> _routes = {
    '/login': (context) => LoginPage(),
    '/home': (context) => HomePage(),
    '/register': (context) => RegisterPage(),
    '/navigasi': (context) => Navigasi(),
    '/onBoarding': (context) => Boarding(),
  };

  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  Map<String, Widget Function(BuildContext)> get routes => _routes;

  void pushReplacementNamed(String routeName) {
    _navigatorKey.currentState?.pushReplacementNamed(routeName);
  }

  void push(MaterialPageRoute route) {
    _navigatorKey.currentState!.push(route);
  }

  void pushNamed(String routeName) {
    _navigatorKey.currentState?.pushNamed(routeName);
  }

  void goBack() {
    _navigatorKey.currentState?.pop();
  }
}
