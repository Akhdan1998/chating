import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../pages/connection/home_page.dart';
import '../pages/connection/panggilan_page.dart';
import '../pages/identitas/setting_page.dart';
import '../pages/Story/updates.dart';

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
            items: [
              BottomNavigationBarItem(
                label: 'update'.tr(),
                icon: Icon(Icons.update),
              ),
              BottomNavigationBarItem(
                label: 'calling'.tr(),
                icon: Icon(Icons.phone),
              ),
              BottomNavigationBarItem(
                label: 'chat'.tr(),
                icon: Icon(Icons.chat),
              ),
              BottomNavigationBarItem(
                label: 'setting'.tr(),
                icon: Icon(Icons.settings),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
