// import 'package:chating/consts.dart';
// import 'package:chating/service/alert_service.dart';
// import 'package:chating/service/auth_service.dart';
// import 'package:chating/service/navigation_service.dart';
// import 'package:flutter/material.dart';
// import 'package:get_it/get_it.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../widgets/textfield.dart';
//
// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});
//
//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }
//
// class _LoginPageState extends State<LoginPage> {
//   final TextEditingController emailController =
//       TextEditingController(text: '@test.com');
//   final TextEditingController passwordController =
//       TextEditingController(text: 'Test123!');
//   final GetIt _getIt = GetIt.instance;
//   late AuthService _authService;
//   late NavigationService _navigationService;
//   late AlertService _alertService;
//   bool isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _authService = _getIt.get<AuthService>();
//     _navigationService = _getIt.get<NavigationService>();
//     _alertService = _getIt.get<AlertService>();
//     _checkLoginStatus();
//   }
//
//   Future<void> _checkLoginStatus() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
//
//     if (isLoggedIn) {
//       _navigationService.pushReplacementNamed("/navigasi");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       body: _buildUI(),
//     );
//   }
//
//   Widget _buildUI() {
//     return SafeArea(
//       child: Container(
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(context).viewInsets.bottom,
//           top: 20,
//           left: 20,
//           right: 20,
//         ),
//         child: SingleChildScrollView(
//           reverse: true,
//           child: Column(
//             children: [
//               _headerText(),
//               _loginForm(),
//               _createAnAccountLink(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _headerText() {
//     return SizedBox(
//       width: MediaQuery.of(context).size.width,
//       child: Column(
//         mainAxisSize: MainAxisSize.max,
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Text(
//             'Hi, Welcome back!',
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//           Text('Hello Again you\'ve been missed'),
//           Icon(
//             Icons.message,
//             size: 100,
//             color: Theme.of(context).colorScheme.primary,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _loginForm() {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.40,
//       margin: EdgeInsets.symmetric(
//         vertical: MediaQuery.of(context).size.height * 0.05,
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.max,
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           TextFieldCustom(
//             controller: emailController,
//             onSaved: (value) {
//               emailController.text = value!;
//             },
//             validationRegEx: EMAIL_VALIDATION_REGEX,
//             height: MediaQuery.of(context).size.height * 0.1,
//             hintText: 'Email',
//             obscureText: false,
//           ),
//           TextFieldCustom(
//             controller: passwordController,
//             onSaved: (value) {
//               passwordController.text = value!;
//             },
//             validationRegEx: PASSWORD_VALIDATION_REGEX,
//             height: MediaQuery.of(context).size.height * 0.1,
//             hintText: 'Password',
//             obscureText: true,
//           ),
//           _loginButton(),
//         ],
//       ),
//     );
//   }
//
//   Widget _loginButton() {
//     return (isLoading)
//         ? CircularProgressIndicator(
//             color: Theme.of(context).colorScheme.primary,
//           )
//         : SizedBox(
//             width: MediaQuery.of(context).size.width,
//             child: MaterialButton(
//               color: Theme.of(context).colorScheme.primary,
//               child: Text(
//                 'Login',
//                 style: TextStyle(color: Colors.white),
//               ),
//               onPressed: () async {
//                 String email = emailController.text.trim();
//                 String password = passwordController.text;
//                 print('Email: $email');
//                 print('Password: $password');
//
//                 if (password.isEmpty) {
//                   _alertService.showToast(
//                     text: 'Password is empty',
//                     icon: Icons.error,
//                     color: Colors.redAccent,
//                   );
//                   return;
//                 }
//
//                 if (email.isEmpty) {
//                   _alertService.showToast(
//                     text: 'Email is empty',
//                     icon: Icons.error,
//                     color: Colors.redAccent,
//                   );
//                   return;
//                 }
//
//                 try {
//                   setState(() {
//                     isLoading = true;
//                   });
//
//                   bool result = await _authService.login(email, password);
//
//                   if (result) {
//                     print('Login successful $result');
//                     SharedPreferences prefs = await SharedPreferences.getInstance();
//                     await prefs.setBool('isLoggedIn', true);
//                     await prefs.setString('email', email);
//
//                     _navigationService.pushReplacementNamed("/navigasi");
//                   } else {
//                     setState(() {
//                       isLoading = false;
//                     });
//                     _alertService.showToast(
//                       text: 'Incorrect email or password!',
//                       icon: Icons.error,
//                       color: Colors.redAccent,
//                     );
//                   }
//                 } catch (e) {
//                   setState(() {
//                     isLoading = false;
//                   });
//                   print('Error during login: $e');
//                   _alertService.showToast(
//                     text: e.toString(),
//                     icon: Icons.error,
//                     color: Colors.redAccent,
//                   );
//                 }
//               },
//             ),
//           );
//   }
//
//   Widget _createAnAccountLink() {
//     return Row(
//       mainAxisSize: MainAxisSize.max,
//       mainAxisAlignment: MainAxisAlignment.center,
//       crossAxisAlignment: CrossAxisAlignment.end,
//       children: [
//         Text('Not a member? '),
//         GestureDetector(
//           onTap: () {
//             _navigationService.pushNamed("/register");
//           },
//           child: Text(
//             'Register now',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Theme.of(context).colorScheme.primary,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
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
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  bool isLoading = false;

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
      resizeToAvoidBottomInset: false,
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          reverse: true,
          child: Column(
            children: [
              _headerText(),
              _loginForm(),
              _createAnAccountLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerText() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Hi, Welcome back!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Hello Again you\'ve been missed'),
          Icon(
            Icons.message,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _loginForm() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.40,
      margin: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.05,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextFieldCustom(
            controller: emailController,
            onSaved: (value) {
              emailController.text = value!;
            },
            validationRegEx: EMAIL_VALIDATION_REGEX,
            height: MediaQuery.of(context).size.height * 0.1,
            hintText: 'Email',
            obscureText: false,
          ),
          TextFieldCustom(
            controller: passwordController,
            onSaved: (value) {
              passwordController.text = value!;
            },
            validationRegEx: PASSWORD_VALIDATION_REGEX,
            height: MediaQuery.of(context).size.height * 0.1,
            hintText: 'Password',
            obscureText: true,
          ),
          _loginButton(),
        ],
      ),
    );
  }

  Widget _loginButton() {
    return (isLoading)
        ? CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          )
        : SizedBox(
            width: MediaQuery.of(context).size.width,
            child: MaterialButton(
              color: Theme.of(context).colorScheme.primary,
              child: Text(
                'Login',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
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

                // String email = emailController.text.trim();
                // String password = passwordController.text;
                //
                // if (password.isEmpty) {
                //   _alertService.showToast(
                //     text: 'Password is empty',
                //     icon: Icons.error,
                //     color: Colors.redAccent,
                //   );
                //   return;
                // }
                //
                // if (email.isEmpty) {
                //   _alertService.showToast(
                //     text: 'Email is empty',
                //     icon: Icons.error,
                //     color: Colors.redAccent,
                //   );
                //   return;
                // }
                //
                // try {
                //   setState(() {
                //     isLoading = true;
                //   });
                //
                //   bool result = await _authService.login(email, password);
                //
                //   if (result) {
                //     SharedPreferences prefs =
                //         await SharedPreferences.getInstance();
                //     await prefs.setBool('isLoggedIn', true);
                //     await prefs.setString('email', email);
                //
                //     _navigationService.pushReplacementNamed("/navigasi");
                //   } else {
                //     setState(() {
                //       isLoading = false;
                //     });
                //     _alertService.showToast(
                //       text: 'Incorrect email or password!',
                //       icon: Icons.error,
                //       color: Colors.redAccent,
                //     );
                //   }
                // } catch (e) {
                //   setState(() {
                //     isLoading = false;
                //   });
                //   _alertService.showToast(
                //     text: e.toString(),
                //     icon: Icons.error,
                //     color: Colors.redAccent,
                //   );
                // }
              },
            ),
          );
  }

  Widget _resendVerificationEmailLink() {
    return GestureDetector(
      onTap: () async {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
          _alertService.showToast(
            text: 'A new verification email has been sent.',
            icon: Icons.check,
            color: Colors.green,
          );
        }
      },
      child: Text(
        'Resend verification email',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _createAnAccountLink() {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Not a member? '),
            GestureDetector(
              onTap: () {
                _navigationService.pushNamed("/register");
              },
              child: Text(
                'Register now',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 5),
        // _resendVerificationEmailLink(),
        // GestureDetector(
        //   onTap: () {
        //     _navigationService.pushNamed("/updatePass");
        //   },
        //   child: Text(
        //     'Forgot Password',
        //     style: TextStyle(
        //       fontWeight: FontWeight.bold,
        //       color: Theme.of(context).colorScheme.primary,
        //       fontSize: 15,
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
