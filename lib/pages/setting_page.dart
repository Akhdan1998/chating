import 'package:chating/pages/identitas/edit_page.dart';
import 'package:chating/pages/identitas/updatePassword_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../service/alert_service.dart';
import '../service/auth_service.dart';
import '../service/navigation_service.dart';
import '../utils.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final AuthService _authService;
  late final NavigationService _navigationService;
  late final AlertService _alertService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    final GetIt _getIt = GetIt.instance;
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: iconColor ?? Colors.grey,
              child: Icon(icon, color: Colors.white, size: 15),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: StyleText(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: StyleText(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return AlertDialog(
          actionsPadding: EdgeInsets.only(
              top: 5, bottom: 5, right: 10),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'no'.tr(),
                style: StyleText(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                bool result = await _authService.logout();
                if (result) {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.clear();
                  _alertService.showToast(
                    text: 'success_logout'.tr(),
                    icon: Icons.check,
                    color: Colors.green,
                  );
                  _navigationService.pushReplacementNamed("/login");
                }
              },
              child: Text(
                'yes'.tr(),
                style: StyleText(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          title: Text(
              'alert_logout'.tr(),
              style: StyleText(fontSize: 15)),
        );
      },
      transitionBuilder:
          (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'setting'.tr(),
          style: StyleText(fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: _auth.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Container();
          }
          final userProfile = UserProfile.fromMap(
              snapshot.data!.docs[0].data() as Map<String, dynamic>);

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.only(top: 100),
                      color: Colors.white,
                      child: Column(
                        children: [
                          Divider(thickness: 5),
                          _buildListTile(
                            icon: Icons.key,
                            title: 'change_password'.tr(),
                            subtitle: 'change_password'.tr(),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UpdatePasswordPage(
                                  userProfile: userProfile,
                                ),
                              ),
                            ),
                            iconColor: Colors.green,
                          ),
                          Divider(endIndent: 20, indent: 20),
                          _buildListTile(
                            icon: Icons.settings,
                            title: 'setting'.tr(),
                            subtitle: 'Notifications, Language, etc.',
                            onTap: () {},
                            iconColor: Colors.blue,
                          ),
                          Divider(endIndent: 20, indent: 20),
                          _buildListTile(
                            icon: Icons.logout,
                            title: 'logout'.tr(),
                            subtitle: 'deskrip_logout'.tr(),
                            onTap: _showLogoutDialog,
                            iconColor: Colors.red,
                          ),
                          Divider(endIndent: 20, indent: 20),
                        ],
                      ),
                    ),
                    Container(
                      height: 50,
                      width: double.infinity,
                      alignment: Alignment.topRight,
                      padding:
                          EdgeInsets.symmetric(horizontal: 21, vertical: 43),
                      color: Theme.of(context).primaryColor,
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      top: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              spreadRadius: 1,
                              blurRadius: 1,
                              offset: Offset(0, 0),
                              color: Colors.grey,
                            )
                          ],
                        ),
                        padding: EdgeInsets.all(10),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  content: Image.network(userProfile.pfpURL!),
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundImage:
                                    NetworkImage(userProfile.pfpURL!),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userProfile.name ?? '-',
                                    style: StyleText(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    userProfile.email ?? '-',
                                    style: StyleText(fontSize: 10),
                                  ),
                                  Text(
                                    userProfile.phoneNumber ?? '-',
                                    style: StyleText(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditPage(userProfile: userProfile),
                                ),
                              ),
                              child: Icon(Icons.edit,
                                  size: 17,
                                  color: Theme.of(context).primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
