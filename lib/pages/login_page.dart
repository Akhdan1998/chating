import 'package:chating/pages/verifikasi_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../consts.dart';
import '../service/alert_service.dart';
import '../service/auth_service.dart';
import '../service/navigation_service.dart';
import '../widgets/textfield.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  bool isLoading = false;
  bool cardEmail = false;
  String phoneNumber = '';
  bool isButtonEnabled = false;
  FirebaseAuth _auth = FirebaseAuth.instance;
  String? verificationId;

  // Fungsi untuk memeriksa apakah kedua field terisi
  void _checkFields() {
    setState(() {
      isButtonEnabled =
          phoneNumber.isNotEmpty && nameController.text.isNotEmpty;
    });
  }

  // Future<void> _verifyPhoneNumber() async {
  //   try {
  //     await _auth.verifyPhoneNumber(
  //       phoneNumber: phoneNumber,
  //       verificationCompleted: (PhoneAuthCredential credential) async {
  //
  //         UserCredential userCredential = await _auth.signInWithCredential(credential);
  //
  //         if (userCredential.user != null) {
  //           await FirebaseFirestore.instance.collection('users').add({
  //             'name': nameController.text,
  //             'phone': phoneNumber,
  //             'uid': userCredential.user!.uid,
  //           });
  //         }
  //       },
  //       verificationFailed: (FirebaseAuthException e) {
  //         print('Verifikasi gagal: ${e.message}');
  //       },
  //       codeSent: (String verificationId, int? resendToken) {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => Verifikasi(
  //               verificationId: verificationId,
  //               phoneNumber: phoneNumber,
  //             ),
  //           ),
  //         );
  //       },
  //       codeAutoRetrievalTimeout: (String verificationId) {
  //         print('Timeout');
  //       },
  //     );
  //   } catch (e) {
  //     print('Gagal menyimpan data atau mengirim OTP: $e');
  //   }
  // }

  Future<void> sendOtp() async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber, // Gunakan variabel phoneNumber langsung
        timeout: Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Jika verifikasi otomatis berhasil
          await _auth.signInWithCredential(credential);
          print('Verifikasi berhasil, login otomatis');
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verifikasi gagal: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          print('Kode OTP dikirim ke $phoneNumber');
          setState(() {
            this.verificationId = verificationId; // Simpan verificationId
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Waktu habis untuk auto-retrieve OTP');
        },
      );
    } catch (e) {
      print('Gagal mengirim OTP: $e');
    }
  }

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
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _logo(),
                SizedBox(height: 20),
                if (cardEmail == true) _loginCard(),
                SizedBox(height: 15),
                (cardEmail == true)
                    ? GestureDetector(
                        onTap: () {
                          setState(() {
                            cardEmail = !cardEmail;
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Sign in with phone number',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    : Container(),
                SizedBox(height: 20),
                _createAnAccountLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return Column(
      children: [
        Image.asset('assets/splash.png', scale: 6),
        SizedBox(height: 10),
        Text(
          'Welcome to AppsKabs!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          'Connect easily, anytime, anywhere.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        (cardEmail == false) ? SizedBox(height: 20) : SizedBox(height: 0),
        if (cardEmail == false)
          Column(
            children: [
              IntlPhoneField(
                invalidNumberMessage: '',
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                initialCountryCode: 'ID',
                onChanged: (phone) {
                  setState(() {
                    phoneNumber = phone.completeNumber;
                    _checkFields();
                  });
                },
              ),
              TextFieldCustom(
                controller: nameController,
                onSaved: (value) {
                  nameController.text = value!;
                },
                onChanged: (value) {
                  _checkFields();
                },
                validationRegEx: NAME_VALIDATION_REGEX,
                height: MediaQuery.of(context).size.height * 0.1,
                hintText: 'Name',
                obscureText: false,
                borderRadius: 10,
                fillColor: Colors.grey[200]!,
                borderSide: BorderSide(color: Colors.blue, width: 2.0),
                // Border yang terlihat dengan warna biru
                filled: true,
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isButtonEnabled
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: isButtonEnabled
                      ? () {
                          sendOtp();
                        }
                      : null,
                ),
              ),
            ],
          ),
        SizedBox(height: 15),
        (cardEmail == false)
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    cardEmail = !cardEmail;
                  });
                },
                child: Container(
                  color: Colors.transparent,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sign in with email',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            : Container(),
      ],
    );
  }

  Widget _loginCard() {
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
          _loginForm(),
          const SizedBox(height: 20),
          _loginButton(),
        ],
      ),
    );
  }

  Widget _loginForm() {
    return Column(
      children: [
        TextFieldCustom(
          controller: emailController,
          onSaved: (value) {
            emailController.text = value!;
          },
          validationRegEx: EMAIL_VALIDATION_REGEX,
          hintText: 'Email',
          obscureText: false,
          height: MediaQuery.of(context).size.height * 0.1,
        ),
        const SizedBox(height: 10),
        TextFieldCustom(
          controller: passwordController,
          onSaved: (value) {
            passwordController.text = value!;
          },
          validationRegEx: PASSWORD_VALIDATION_REGEX,
          hintText: 'Password',
          obscureText: true,
          height: MediaQuery.of(context).size.height * 0.1,
        ),
      ],
    );
  }

  Widget _loginButton() {
    return isLoading
        ? const CircularProgressIndicator(
            color: Colors.blueGrey,
          )
        : SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              onPressed: _handleLogin,
            ),
          );
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
    return GestureDetector(
      onTap: () {
        _navigationService.pushNamed("/register");
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Not a member?', style: TextStyle(color: Colors.white70)),
          const SizedBox(width: 5),
          const Text(
            'Register now',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
