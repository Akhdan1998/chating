import 'package:chating/main.dart';
import 'package:chating/pages/identitas/verifikasi_page.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../consts.dart';
import '../../service/alert_service.dart';
import '../../service/auth_service.dart';
import '../../service/navigation_service.dart';
import '../../widgets/textfield.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  bool isLoading = false;
  bool isLoad = false;
  bool cardEmail = false;
  bool forgotPass = false;
  String phoneNumber = '';
  bool isButtonEnabled = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      _navigationService.pushReplacementNamed("/navigasi");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        leading: Container(),
        centerTitle: true,
        title: Text(
          (cardEmail == true)
              ? 'head_title_email'.tr()
              : 'head_title_number'.tr(),
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.more_vert,
                color: Colors.white,
              )),
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: (cardEmail == true)
                          ? 'title_email'.tr()
                          : 'title_number'.tr(),
                      style: GoogleFonts.poppins(fontSize: 15),
                    ),
                    TextSpan(
                      text: (cardEmail == true)
                          ? 'subtitle_email'.tr()
                          : 'subtitle_number'.tr(),
                      style: GoogleFonts.poppins(
                        color: Colors.blue,
                        fontSize: 15,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          // Aksi ketika "Ketentuan Layanan" ditekan
                          print('WKWKWKWKWK');
                        },
                    ),
                  ],
                ),
              ),
              _logo(),
              // _loginCard(),
              if (cardEmail == true) _loginCard(),
              SizedBox(height: 15),
              (cardEmail == true)
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              cardEmail = !cardEmail;
                            });
                          },
                          child: Container(
                            color: Colors.transparent,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'login_number'.tr(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              forgotPass = !forgotPass;
                            });
                          },
                          child: Container(
                            color: Colors.transparent,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'pass'.tr(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(),
              SizedBox(height: 20),
              _createAnAccountLink(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _logo() {
  //   return Column(
  //     children: [
  //       Image.asset('assets/splash.png', scale: 6),
  //       SizedBox(height: 10),
  //       Text(
  //         'Welcome to AppsKabs!',
  //         style: TextStyle(
  //           fontSize: 22,
  //           fontWeight: FontWeight.bold,
  //           color: Colors.white,
  //         ),
  //       ),
  //       Text(
  //         'Connect easily, anytime, anywhere.',
  //         style: TextStyle(
  //           color: Colors.white70,
  //           fontSize: 16,
  //         ),
  //       ),
  //       SizedBox(height: (cardEmail == false) ? 20 : 0),
  //       if (cardEmail == false)
  //         Container(
  //           padding: EdgeInsets.all(20),
  //           decoration: BoxDecoration(
  //             color: Colors.white.withOpacity(0.95),
  //             borderRadius: BorderRadius.circular(15),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black26,
  //                 blurRadius: 10,
  //                 offset: Offset(0, 5),
  //               ),
  //             ],
  //           ),
  //           child: Column(
  //             children: [
  //               IntlPhoneField(
  //                 controller: phoneController,
  //                 keyboardType: TextInputType.phone,
  //                 invalidNumberMessage: '',
  //                 decoration: InputDecoration(
  //                   filled: true,
  //                   fillColor: Colors.white,
  //                   border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(10),
  //                     borderSide: BorderSide(width: 1),
  //                   ),
  //                   counterText: '',
  //                 ),
  //                 initialCountryCode: 'ID',
  //                 onChanged: (phone) {
  //                   setState(() {
  //                     phoneNumber = phone.completeNumber;
  //                   });
  //                 },
  //               ),
  //               SizedBox(height: 10),
  //               TextFieldCustom(
  //                 controller: nameController,
  //                 onChanged: (value) {
  //                   setState(() {});
  //                 },
  //                 height: MediaQuery.of(context).size.height * 0.1,
  //                 hintText: 'Name',
  //                 obscureText: false,
  //                 borderRadius: 10,
  //                 fillColor: Colors.white,
  //                 borderSide: BorderSide(color: Colors.blue, width: 2.0),
  //                 filled: true,
  //                 validationRegEx: NAME_VALIDATION_REGEX,
  //                 onSaved: (value) {
  //                   nameController.text = value!;
  //                 },
  //               ),
  //               SizedBox(height: 10),
  //               isLoad
  //                   ? CircularProgressIndicator(
  //                       valueColor:
  //                           AlwaysStoppedAnimation<Color>(Colors.blueGrey),
  //                     )
  //                   : SizedBox(
  //                       width: double.infinity,
  //                       child: ElevatedButton(
  //                         style: ElevatedButton.styleFrom(
  //                           backgroundColor: Colors.blueGrey,
  //                           padding: EdgeInsets.symmetric(vertical: 15),
  //                           shape: RoundedRectangleBorder(
  //                             borderRadius: BorderRadius.circular(10),
  //                           ),
  //                         ),
  //                         child: Text(
  //                           'Next',
  //                           style: TextStyle(
  //                             fontSize: 16,
  //                             color: Colors.white,
  //                           ),
  //                         ),
  //                         onPressed: () {
  //                           if (phoneNumber.isEmpty || nameController.text.isEmpty) {
  //                             setState(() {
  //                               isLoad = true;
  //                             });
  //
  //                             Future.delayed(Duration(milliseconds: 500), () {
  //                               setState(() {
  //                                 isLoad = false;
  //                               });
  //                               _alertService.showToast(
  //                                 text: 'Please fill in both fields.',
  //                                 icon: Icons.error,
  //                                 color: Colors.redAccent,
  //                               );
  //                             });
  //                           } else {
  //                             setState(() {
  //                               isLoad = true;
  //                             });
  //                             Navigator.push(
  //                               context,
  //                               MaterialPageRoute(
  //                                 builder: (context) => Verifikasi(
  //                                   phoneNumber: phoneNumber,
  //                                   nama: nameController.text,
  //                                 ),
  //                               ),
  //                             ).whenComplete(() {
  //                               setState(() {
  //                                 isLoad = false;
  //                                 phoneNumber = '';
  //                                 phoneController.clear();
  //                                 nameController.clear();
  //                               });
  //                             });
  //                           }
  //                         },
  //                       ),
  //                     ),
  //             ],
  //           ),
  //         ),
  //       SizedBox(height: 20),
  //       (cardEmail == false)
  //           ? GestureDetector(
  //               onTap: () {
  //                 setState(() {
  //                   cardEmail = !cardEmail;
  //                 });
  //               },
  //               child: Container(
  //                 color: Colors.transparent,
  //                 alignment: Alignment.centerLeft,
  //                 child: Text(
  //                   'Sign in with email',
  //                   style: TextStyle(color: Colors.white, fontSize: 12),
  //                 ),
  //               ),
  //             )
  //           : Container(),
  //     ],
  //   );
  // }

  Widget _logo() {
    return Column(
      children: [
        // Image.asset('assets/splash.png', scale: 6),
        // const SizedBox(height: 10),
        // const Text(
        //   'Welcome to AppsKabs!',
        //   style: TextStyle(
        //     fontSize: 22,
        //     fontWeight: FontWeight.bold,
        //     color: Colors.white,
        //   ),
        // ),
        // const Text(
        //   'Connect easily, anytime, anywhere.',
        //   style: TextStyle(
        //     color: Colors.white70,
        //     fontSize: 16,
        //   ),
        // ),
        if (!cardEmail) const SizedBox(height: 20),
        if (!cardEmail) _buildEmailCard(),
        const SizedBox(height: 20),
        if (!cardEmail) _buildSignInWithEmailText(),
      ],
    );
  }

  Widget _buildEmailCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPhoneField(),
          SizedBox(height: 10),
          // _buildNameField(),
          // SizedBox(height: 10),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return IntlPhoneField(
      autofocus: true,
      controller: phoneController,
      keyboardType: TextInputType.phone,
      invalidNumberMessage: '',
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(width: 1),
        ),
        counterText: '',
      ),
      initialCountryCode: 'ID',
      onChanged: (phone) {
        setState(() {
          phoneNumber = phone.completeNumber;
        });
      },
    );
  }

  // Widget _buildNameField() {
  //   return TextFieldCustom(
  //     controller: nameController,
  //     height: MediaQuery.of(context).size.height * 0.1,
  //     hintText: 'name'.tr(),
  //     borderRadius: 10,
  //     fillColor: Colors.white,
  //     borderSide: BorderSide(color: Colors.blue, width: 2.0),
  //     filled: true,
  //     validationRegEx: NAME_VALIDATION_REGEX,
  //     onChanged: (value) {
  //       setState(() {});
  //     },
  //     onSaved: (value) {
  //       nameController.text = value!;
  //     },
  //   );
  // }

  Widget _buildNextButton() {
    return isLoad
        ? const Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey)))
        : SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'next'.tr(),
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
              ),
              onPressed:  () {
                if (phoneNumber.isNotEmpty) {
                  dialogConfirm();
                } else {
                  _alertService.showToast(
                    text: 'Please fill in both fields.',
                    icon: Icons.error,
                    color: Colors.redAccent,
                  );
                }
              },
            ),
          );
  }

  void dialogConfirm() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return AlertDialog(
          actionsPadding:
              const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          title: Text('Apakah ini nomor yang benar?'.tr(),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: Text(phoneNumber, style: const TextStyle(fontSize: 15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('No',
                  style: GoogleFonts.poppins(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                dialogInformation(context);
              },
              child: Text('Yes',
                  style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(scale: anim1.value, child: child);
      },
    );
  }

  void dialogInformation(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.center,
              width: 300,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Icon(
                Icons.contacts_outlined,
                color: Colors.white,
                size: 40,
              ),
            ),
            Container(
              padding: EdgeInsets.only(top: 20, right: 20, left: 20),
              width: 300,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kontak',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Untuk memverifikasi nomor dan mengirim pesan ke teman dan keluarga dengan mudah, izinkan Appskabs mengakses daftar kontak Anda.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Nanti',
                          style: GoogleFonts.poppins().copyWith(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          PermissionStatus status = await Permission.contacts.request();

                          if (status.isGranted) {
                            Iterable<Contact> contacts = await ContactsService.getContacts();

                            contacts.forEach((contact) {
                              print(contact.displayName);
                              print(contact.phones);
                            });

                            _handleNextButtonPressed().whenComplete(() {
                              Navigator.pop(context);
                            });

                          } else if (status.isDenied) {
                            print('Izin ditolak');
                          } else if (status.isPermanentlyDenied) {
                            openAppSettings();
                          }
                        },
                        child: Text(
                          'next'.tr(),
                          style: GoogleFonts.poppins().copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(scale: anim1.value, child: child);
      },
    );
  }

  // void _handleNextButtonPressed() {
  //   if (phoneNumber.isEmpty) {
  //     _alertService.showToast(
  //               text: 'Please fill in both fields.',
  //               icon: Icons.error,
  //               color: Colors.redAccent,
  //             );
  //     return;
  //   }
  //
  //   setState(() => isLoad = true);
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => Verifikasi(
  //         phoneNumber: phoneNumber,
  //         // nama: nameController.text,
  //       ),
  //     ),
  //   ).whenComplete(() {
  //     setState(() {
  //       isLoad = false;
  //       phoneNumber = '';
  //       phoneController.clear();
  //       // nameController.clear();
  //     });
  //   });
  // }

  Future<void> _handleNextButtonPressed() {
    setState(() => isLoad = true);

    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Verifikasi(
          phoneNumber: phoneNumber,
          // nama: nameController.text,
        ),
      ),
    ).whenComplete(() {
      setState(() {
        isLoad = false;
        phoneNumber = '';
        phoneController.clear();
        // nameController.clear();
      });
    });
  }

  // Widget _buildNextButton() {
  //   return isLoad
  //       ? const CircularProgressIndicator(
  //           valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
  //         )
  //       : SizedBox(
  //           width: double.infinity,
  //           child: ElevatedButton(
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.blueGrey,
  //               padding: const EdgeInsets.symmetric(vertical: 15),
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(10),
  //               ),
  //             ),
  //             child: Text(
  //               'next'.tr(),
  //               style: GoogleFonts.poppins(
  //                 fontSize: 16,
  //                 color: Colors.white,
  //               ),
  //             ),
  //             onPressed: dialogConfirm,
  //           ),
  //         );
  // }
  //
  // void dialogConfirm() {
  //   showGeneralDialog(
  //     context: context,
  //     barrierDismissible: true,
  //     barrierLabel: '',
  //     transitionDuration: Duration(milliseconds: 300),
  //     pageBuilder: (context, anim1, anim2) {
  //       return AlertDialog(
  //         actionsPadding: EdgeInsets.only(top: 1, bottom: 5, right: 10),
  //         title: Text(
  //           'Apakah ini nomor yang benar?'.tr(),
  //           style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
  //         ),
  //         content: Text(
  //           phoneNumber,
  //           style: TextStyle(fontSize: 15),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context);
  //             },
  //             child: Text(
  //               'No',
  //               style: GoogleFonts.poppins().copyWith(
  //                 color: Colors.redAccent,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ),
  //           TextButton(
  //             onPressed: _handleNextButtonPressed,
  //             child: Text(
  //               'Yes',
  //               style: GoogleFonts.poppins().copyWith(
  //                 color: Theme.of(context).colorScheme.primary,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //     transitionBuilder: (context, anim1, anim2, child) {
  //       return Transform.scale(
  //         scale: anim1.value,
  //         child: child,
  //       );
  //     },
  //   );
  // }
  //
  // void _handleNextButtonPressed() {
  //   if (phoneNumber.isEmpty || nameController.text.isEmpty) {
  //     setState(() {
  //       isLoad = true;
  //     });
  //
  //     Future.delayed(Duration(milliseconds: 500), () {
  //       setState(() {
  //         isLoad = false;
  //       });
  //       _alertService.showToast(
  //         text: 'Please fill in both fields.',
  //         icon: Icons.error,
  //         color: Colors.redAccent,
  //       );
  //     });
  //   } else {
  //     setState(() {
  //       isLoad = true;
  //     });
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => Verifikasi(
  //           phoneNumber: phoneNumber,
  //           nama: nameController.text,
  //         ),
  //       ),
  //     ).whenComplete(() {
  //       setState(() {
  //         isLoad = false;
  //         phoneNumber = '';
  //         phoneController.clear();
  //         nameController.clear();
  //       });
  //     });
  //   }
  // }

  Widget _buildSignInWithEmailText() {
    return GestureDetector(
      onTap: () {
        setState(() {
          cardEmail = !cardEmail;
        });
      },
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'login_email'.tr(),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _loginCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _loginForm(),
          SizedBox(height: 10),
          isLoading
              ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                )
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      forgotPass ? 'Reset' : 'Login',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    onPressed:
                        forgotPass ? _sendPasswordResetEmail : _handleLogin,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _loginForm() {
    return Column(
      children: [
        TextFieldCustom(
          autoFocus: true,
          controller: emailController,
          onSaved: (value) {
            emailController.text = value!;
          },
          validationRegEx: EMAIL_VALIDATION_REGEX,
          hintText: 'email'.tr(),
          obscureText: false,
          height: MediaQuery.of(context).size.height * 0.1,
          borderSide: BorderSide(color: Colors.purple, width: 2.0),
        ),
        if (!forgotPass) ...[
          SizedBox(height: 10),
          TextFieldCustom(
            controller: passwordController,
            onSaved: (value) {
              passwordController.text = value!;
            },
            validationRegEx: PASSWORD_VALIDATION_REGEX,
            hintText: 'password'.tr(),
            obscureText: true,
            height: MediaQuery.of(context).size.height * 0.1,
            borderSide: BorderSide(color: Colors.purple, width: 2.0),
          ),
        ],
      ],
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    try {
      await _auth.sendPasswordResetEmail(email: emailController.text);
      _alertService.showToast(
        text: 'Email reset kata sandi telah dikirim!',
        icon: Icons.check,
        color: Colors.green,
      );
    } catch (e) {
      _alertService.showToast(
        text: e.toString(),
        icon: Icons.error,
        color: Colors.redAccent,
      );
    }
  }

  Future<void> _handleLogin() async {
    setState(() {
      isLoading = true;
    });

    try {
      String email = emailController.text;
      String password = passwordController.text;

      bool result = await _authService.login(email, password);

      if (result) {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.emailVerified) {
          _alertService.showToast(
            text: 'Please verify your email before logging in.',
            icon: Icons.error,
            color: Colors.redAccent,
          );
          FirebaseAuth.instance.signOut();
          return;
        }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('email', email);

        _navigationService.pushReplacementNamed("/navigasi");
      } else {
        _alertService.showToast(
          text: 'Incorrect email or password!',
          icon: Icons.error,
          color: Colors.redAccent,
        );
      }
    } catch (e) {
      _alertService.showToast(
        text: 'Login failed. Please try again.',
        icon: Icons.error,
        color: Colors.redAccent,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _createAnAccountLink() {
    return (cardEmail == false)
        ? Container()
        : RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'member'.tr(),
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
                TextSpan(
                  text: 'register'.tr(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      _navigationService.pushNamed("/register");
                    },
                ),
              ],
            ),
          );
  }
}
