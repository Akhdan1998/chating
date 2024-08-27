import 'dart:io';

import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/panggilan_page.dart';
import '../pages/setting_page.dart';
import '../pages/updates.dart';

class Navigasi extends StatefulWidget {
  const Navigasi({super.key});

  @override
  State<Navigasi> createState() => _NavigasiState();
}

class _NavigasiState extends State<Navigasi> {
  int _selectedIndex = 2;
  PageController controller = PageController(initialPage: 2);

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });

    controller.animateToPage(
      _selectedIndex,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: (Platform.isAndroid)
                ? MediaQuery.of(context).size.height - 58
                : MediaQuery.of(context).size.height - 92,
            width: MediaQuery.of(context).size.width,
            child: PageView(
              physics: NeverScrollableScrollPhysics(),
              controller: controller,
              children: [
                UpdatesPage(),
                PanggilanPage(),
                HomePage(),
                ProfilePage(),
              ],
            ),
          ),
          BottomNavigationBar(
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            onTap: _navigateBottomBar,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                label: 'Updates',
                icon: Icon(Icons.update),
              ),
              BottomNavigationBarItem(
                label: 'Calling',
                icon: Icon(Icons.phone),
              ),
              BottomNavigationBarItem(
                label: 'Chat',
                icon: Icon(Icons.chat),
              ),
              BottomNavigationBarItem(
                label: 'Settings',
                icon: Icon(Icons.settings),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
