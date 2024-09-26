import 'package:chating/pages/edit_page.dart';
import 'package:chating/pages/updatePassword_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../service/alert_service.dart';
import '../service/auth_service.dart';
import '../service/navigation_service.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final currentUser = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('uid', isEqualTo: currentUser.currentUser!.uid)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasData) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary,),);
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              var userProfile = UserProfile.fromMap(
                  snapshot.data!.docs[0].data() as Map<String, dynamic>);
              return Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: EdgeInsets.only(top: 100),
                        alignment: Alignment.topCenter,
                        height: MediaQuery.sizeOf(context).height,
                        color: Colors.white,
                        child: Column(
                          children: [
                            Divider(thickness: 5, color: Colors.grey.shade300,),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UpdatePasswordPage(userProfile: userProfile),
                                  ),
                                );
                                // _navigationService.pushNamed("/updatePass");
                              },
                              child: Container(
                                color: Colors.transparent,
                                padding: EdgeInsets.only(
                                    left: 20, right: 20, top: 10, bottom: 5),
                                child: Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.green,
                                      ),
                                      child: Icon(
                                        Icons.key,
                                        color: Colors.white,
                                        size: 15,
                                      ),),
                                    SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Change password',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Change your password.',
                                          style: TextStyle(fontSize: 12),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                              indent: 20,
                              endIndent: 20,
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                color: Colors.transparent,
                                padding: EdgeInsets.only(
                                    left: 20, right: 20, top: 10, bottom: 5),
                                child: Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.blue,
                                      ),
                                      child: Icon(
                                        Icons.settings,
                                        color: Colors.white,
                                        size: 15,
                                      ),),
                                    SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Settings',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Notifications, Language, etc.',
                                          style: TextStyle(fontSize: 12),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                              indent: 20,
                              endIndent: 20,
                            ),
                            GestureDetector(
                              onTap: () async {
                                showGeneralDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  barrierLabel: '',
                                  barrierColor: Colors.black54,
                                  transitionDuration: Duration(milliseconds: 300),
                                  pageBuilder: (context, anim1, anim2) {
                                    return AlertDialog(
                                      actionsPadding: EdgeInsets.only(
                                          top: 5, bottom: 5, right: 10),
                                      // titlePadding: EdgeInsets.only(bottom: 5),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            'No',
                                            style: GoogleFonts.poppins()
                                                .copyWith(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            // bool result =
                                            //     await _authService.logout();
                                            // if (result) {
                                            //   _alertService.showToast(
                                            //     text:
                                            //         'Successfully logged out!',
                                            //     icon: Icons.check,
                                            //     color: Colors.green,
                                            //   );
                                            //   _navigationService
                                            //       .pushReplacementNamed(
                                            //           "/login");
                                            // }
                                            bool result = await _authService.logout();
                                            if (result) {
                                              SharedPreferences prefs = await SharedPreferences.getInstance();
                                              await prefs.remove('isLoggedIn');
                                              await prefs.remove('email');

                                              _alertService.showToast(
                                                text: 'Successfully logged out!',
                                                icon: Icons.check,
                                                color: Colors.green,
                                              );
                                              _navigationService.pushReplacementNamed("/login");
                                            }
                                          },
                                          child: Text(
                                            'Yes',
                                            style: GoogleFonts.poppins()
                                                .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                      title: Text(
                                          'You need to log in again if you want to continue previous activities.',
                                          style: TextStyle(fontSize: 15)),
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
                              },
                              child: Container(
                                color: Colors.transparent,
                                padding: EdgeInsets.only(
                                    left: 20, right: 20, top: 10, bottom: 5),
                                // margin: EdgeInsets.only(top: 20, left: 20, right: 20),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        padding: EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red,
                                        ),
                                        child: Icon(
                                          Icons.logout,
                                          color: Colors.white,
                                          size: 15,
                                        ),),
                                    SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Logout',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Exit this account.',
                                          style: TextStyle(fontSize: 12),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                              indent: 20,
                              endIndent: 20,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width,
                        alignment: Alignment.topRight,
                        padding: EdgeInsets.only(left: 21, right: 21, top: 43),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        top: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                spreadRadius: 1,
                                blurRadius: 1,
                                offset: Offset(0, 0),
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(10),
                          width: MediaQuery.of(context).size.width,
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  showGeneralDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    barrierLabel: '',
                                    barrierColor: Colors.black54,
                                    transitionDuration:
                                        Duration(milliseconds: 300),
                                    pageBuilder: (context, anim1, anim2) {
                                      return AlertDialog(
                                        elevation: 0,
                                        backgroundColor: Colors.transparent,
                                        content:
                                            Image.network(userProfile.pfpURL!),
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
                                },
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundImage:
                                      NetworkImage(userProfile.pfpURL!),
                                ),
                              ),
                              SizedBox(width: 10),
                              Container(
                                width: MediaQuery.sizeOf(context).width - 130,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userProfile.name ?? '-',
                                          style: GoogleFonts.poppins().copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          userProfile.email ?? '-',
                                          style: GoogleFonts.poppins().copyWith(
                                            fontSize: 10,
                                          ),
                                        ),
                                        Text(
                                          userProfile.phoneNumber ?? '-',
                                          style: GoogleFonts.poppins().copyWith(
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditPage(userProfile: userProfile),
                                          ),
                                        );
                                      },
                                      child: Container(
                                          color: Colors.transparent,
                                          child: Icon(
                                            Icons.edit,
                                            size: 17,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              return Text('-');
            }
          },
        ),
      ),
    );
  }
}
