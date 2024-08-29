import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:get_it/get_it.dart';

import '../consts.dart';
import '../models/user_profile.dart';
import '../service/alert_service.dart';
import '../service/auth_service.dart';
import '../service/database_service.dart';
import '../service/media_service.dart';
import '../service/navigation_service.dart';
import '../service/storage_service.dart';
import '../widgets/textfield.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  File? selectedImage;
  final GetIt _getIt = GetIt.instance;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  // final TextEditingController otpController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _registerFormKey = GlobalKey();
  // final FirebaseFirestore _auth = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  late String _verificationId;

  bool isLoading = false;
  bool login = false;
  bool otpe = false;

  late AuthService _authService;
  late AlertService _alertService;
  late MediaService _mediaService;
  late NavigationService _navigationService;
  late StorageService _storageService;
  late DatabaseService _databaseService;

  int _selectedIndex = 1;
  PageController controller = PageController(initialPage: 1);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // void sendOtp() async {
  //   String phoneNumber = numberController.text.trim();
  //
  //   // Cek apakah nomor telepon sudah diawali dengan kode negara
  //   if (!phoneNumber.startsWith('+')) {
  //     // Tambahkan kode negara Indonesia secara otomatis
  //     phoneNumber = '+62${phoneNumber.substring(1)}';
  //   }
  //
  //   try {
  //     await FirebaseAuth.instance.verifyPhoneNumber(
  //       phoneNumber: phoneNumber,
  //       verificationCompleted: (PhoneAuthCredential credential) {
  //         // Opsi untuk login otomatis, jika berhasil diverifikasi secara otomatis
  //       },
  //       verificationFailed: (FirebaseAuthException e) {
  //         // Tangani kesalahan verifikasi
  //         print('Verification failed: ${e.message}');
  //       },
  //       codeSent: (String verificationId, int? resendToken) {
  //         setState(() {
  //           this.verificationId = verificationId;
  //           otpe = true;
  //         });
  //       },
  //       codeAutoRetrievalTimeout: (String verificationId) {
  //         // Waktu habis untuk verifikasi otomatis
  //       },
  //     );
  //   } catch (e) {
  //     print('Failed to send OTP: $e');
  //   }
  // }

  // void verifyOtp(String otp) async {
  //   try {
  //     PhoneAuthCredential credential = PhoneAuthProvider.credential(
  //       verificationId: verificationId!,
  //       smsCode: otp,
  //     );
  //
  //     await FirebaseAuth.instance.signInWithCredential(credential);
  //
  //     setState(() {
  //       otpe = true;
  //     });
  //
  //     print('Phone number calls and users can log in.');
  //   } catch (e) {
  //     print('Failed to verify OTP: $e');
  //   }
  // }

  // Fungsi untuk mengirim OTP

  // Future<void> _verifyPhoneNumber(String phoneNumber) async {
  //   await _auth.verifyPhoneNumber(
  //     phoneNumber: phoneNumber,
  //     verificationCompleted: (PhoneAuthCredential credential) async {
  //       // Verifikasi otomatis (hanya untuk beberapa perangkat)
  //       await _auth.signInWithCredential(credential);
  //     },
  //     verificationFailed: (FirebaseAuthException e) {
  //       // Gagal memverifikasi
  //       if (e.code == 'invalid-phone-number') {
  //         print('Nomor telepon tidak valid.');
  //       } else {
  //         print('Verifikasi gagal: ${e.message}');
  //       }
  //     },
  //     codeSent: (String verificationId, int? resendToken) {
  //       // Kode OTP terkirim
  //       setState(() {
  //         _verificationId = verificationId;
  //         otpe = true;  // Menampilkan OtpTextField
  //       });
  //     },
  //     codeAutoRetrievalTimeout: (String verificationId) {
  //       _verificationId = verificationId;
  //     },
  //   );
  // }

  // Future<void> _submitOTP(String otpCode) async {
  //   PhoneAuthCredential credential = PhoneAuthProvider.credential(
  //     verificationId: _verificationId,
  //     smsCode: otpCode,
  //   );
  //
  //   // Login dengan credential
  //   await _auth.signInWithCredential(credential);
  // }

  @override
  void initState() {
    super.initState();
    _mediaService = _getIt.get<MediaService>();
    _navigationService = _getIt.get<NavigationService>();
    _authService = _getIt.get<AuthService>();
    _storageService = _getIt.get<StorageService>();
    _alertService = _getIt.get<AlertService>();
    _databaseService = _getIt.get<DatabaseService>();
    controller = PageController(initialPage: _selectedIndex);
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
              _registerForm(),
              _loginAccountLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerText() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: const Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Let's get going!",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Register an account using the form below'),
        ],
      ),
    );
  }

  Widget _registerForm() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.60,
      margin: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.05,
      ),
      child: Form(
        key: _registerFormKey,
        child: Column(
          children: [
            // Container(
            //   width: MediaQuery.of(context).size.width,
            //   height: 45,
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(8),
            //     color: Colors.grey.shade300,
            //   ),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       GestureDetector(
            //         onTap: () {
            //           setState(() {
            //             _navigateBottomBar(0);
            //           });
            //         },
            //         child: Container(
            //           alignment: Alignment.center,
            //           width: MediaQuery.of(context).size.width - 235.8,
            //           margin: EdgeInsets.all(5),
            //           padding: EdgeInsets.all(5),
            //           decoration: BoxDecoration(
            //             borderRadius: BorderRadius.circular(8),
            //             color: (_selectedIndex == 0)
            //                 ? Theme.of(context).colorScheme.primary
            //                 : Colors.grey.shade300,
            //           ),
            //           child: Text(
            //             'Phone number',
            //             style: TextStyle(
            //               color: (_selectedIndex == 0)
            //                   ? Colors.white
            //                   : Theme.of(context).colorScheme.primary,
            //             ),
            //           ),
            //         ),
            //       ),
            //       GestureDetector(
            //         onTap: () {
            //           setState(() {
            //             _navigateBottomBar(1);
            //           });
            //         },
            //         child: Container(
            //           alignment: Alignment.center,
            //           width: MediaQuery.of(context).size.width - 235.8,
            //           margin: EdgeInsets.all(5),
            //           padding: EdgeInsets.all(5),
            //           decoration: BoxDecoration(
            //             borderRadius: BorderRadius.circular(8),
            //             color: (_selectedIndex == 1)
            //                 ? Theme.of(context).colorScheme.primary
            //                 : Colors.grey.shade300,
            //           ),
            //           child: Text(
            //             'Email',
            //             style: TextStyle(
            //               color: (_selectedIndex == 1)
            //                   ? Colors.white
            //                   : Theme.of(context).colorScheme.primary,
            //             ),
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // SizedBox(height: 20),
            // Container(
            //   height: MediaQuery.of(context).size.height - 422,
            //   width: MediaQuery.of(context).size.width,
            //   child: PageView(
            //     physics: NeverScrollableScrollPhysics(),
            //     controller: controller,
            //     children: [
            //       _phone(),
            //       _email(),
            //     ],
            //   ),
            // ),
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _pfpSelectionField(),
                SizedBox(height: 15),
                TextFieldCustom(
                  controller: nameController,
                  onSaved: (value) {
                    nameController.text = value!;
                  },
                  validationRegEx: NAME_VALIDATION_REGEX,
                  height: MediaQuery.of(context).size.height * 0.1,
                  hintText: 'Name',
                  obscureText: false,
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width - 40,
                      child: TextFieldCustom(
                        controller: numberController,
                        onSaved: (value) {
                          numberController.text = value!;
                        },
                        validationRegEx: PHONE_VALIDATION_REGEX,
                        height: MediaQuery.of(context).size.height * 0.1,
                        hintText: '+62 (+6281290763984)',
                        obscureText: false,
                      ),
                    ),
                    // SizedBox(width: 5),
                    // GestureDetector(
                    //   onTap: () {
                    //     final phoneNumber = numberController.text.trim();
                    //     if (phoneNumber.isNotEmpty) {
                    //       _verifyPhoneNumber(phoneNumber);
                    //     } else {
                    //       _alertService.showToast(
                    //         text: 'Phone number cannot be empty.',
                    //         icon: Icons.error,
                    //         color: Colors.redAccent,
                    //       );
                    //       // Tampilkan pesan jika nomor telepon kosong
                    //       print('Nomor telepon tidak boleh kosong.');
                    //     }
                    //   },
                    //   child: Container(
                    //     padding: EdgeInsets.all(15),
                    //     decoration: BoxDecoration(
                    //       borderRadius: BorderRadius.circular(5),
                    //       color: Theme.of(context).colorScheme.primary,
                    //     ),
                    //     child: Icon(
                    //       Icons.send,
                    //       color: Colors.white,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
                // SizedBox(height: 10),
                // (otpe == true)
                //     ?
                // OtpTextField(
                //         numberOfFields: 6,
                //         onSubmit: (String otpCode) {
                //           _submitOTP(otpCode).whenComplete(() {
                //             _alertService.showToast(
                //               text: 'BERHASIL',
                //               icon: Icons.check,
                //               color: Colors.green,
                //             );
                //           });
                //           setState(() {
                //             otpe = false;
                //           });
                //         },
                //       )
                //     OtpTextField(
                //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //             keyboardType: TextInputType.number,
                //             numberOfFields: 6,
                //             enabledBorderColor: Colors.grey,
                //             borderColor: Theme.of(context).colorScheme.primary,
                //             focusedBorderColor:
                //                 Theme.of(context).colorScheme.primary,
                //             showFieldAsBox: true,
                //             onCodeChanged: (String code) {},
                //             onSubmit: (String otpCode) {
                //               _submitOTP(otpCode).whenComplete(() {
                //                 showDialog(context: context, builder: (BuildContext context) {
                //                   return AlertDialog(
                //                     content: Text('BERHASIL')
                //                   );
                //                 });
                //                 setState(() {
                //                   otpe = false;
                //                 });
                //               });
                //             },
                //           )
                //     : Container(),
                SizedBox(height: 10),
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
                SizedBox(height: 10),
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
                SizedBox(height: 5),
                _registerButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget _email() {
  //   return Column(
  //     mainAxisSize: MainAxisSize.max,
  //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Center(child: _pfpSelectionField()),
  //       TextFieldCustom(
  //         controller: nameController,
  //         onSaved: (value) {
  //           nameController.text = value!;
  //         },
  //         validationRegEx: NAME_VALIDATION_REGEX,
  //         height: MediaQuery.of(context).size.height * 0.1,
  //         hintText: 'Name',
  //         obscureText: false,
  //       ),
  //       Row(
  //         children: [
  //           Container(
  //             width: MediaQuery.of(context).size.width - 100,
  //             child: TextFieldCustom(
  //               controller: numberController,
  //               onSaved: (value) {
  //                 numberController.text = value!;
  //               },
  //               validationRegEx: PHONE_VALIDATION_REGEX,
  //               height: MediaQuery.of(context).size.height * 0.1,
  //               hintText: 'Phone Number',
  //               obscureText: false,
  //             ),
  //           ),
  //           SizedBox(width: 5),
  //           GestureDetector(
  //             onTap: () {},
  //             child: Container(
  //               padding: EdgeInsets.all(15),
  //               decoration: BoxDecoration(
  //                 borderRadius: BorderRadius.circular(5),
  //                 color: Theme.of(context).colorScheme.primary,
  //               ),
  //               child: Icon(Icons.send, color: Colors.white,),
  //             ),
  //           ),
  //         ],
  //       ),
  //       TextFieldCustom(
  //         controller: emailController,
  //         onSaved: (value) {
  //           emailController.text = value!;
  //         },
  //         validationRegEx: EMAIL_VALIDATION_REGEX,
  //         height: MediaQuery.of(context).size.height * 0.1,
  //         hintText: 'Email',
  //         obscureText: false,
  //       ),
  //       TextFieldCustom(
  //         controller: passwordController,
  //         onSaved: (value) {
  //           passwordController.text = value!;
  //         },
  //         validationRegEx: PASSWORD_VALIDATION_REGEX,
  //         height: MediaQuery.of(context).size.height * 0.1,
  //         hintText: 'Password',
  //         obscureText: true,
  //       ),
  //       _registerButton(),
  //     ],
  //   );
  // }

  // Widget _phone() {
  //   final TextEditingController phoneController = TextEditingController();
  //   final TextEditingController otpController = TextEditingController();
  //   String? verificationId;
  //   bool isOtpSent = false;
  //
  //   Future<String?> formatPhoneNumber(String phoneNumber) async {
  //     try {
  //       final isValid = await PhoneNumberUtil.isValidPhoneNumber(
  //         phoneNumber: phoneNumber,
  //         isoCode: 'ID',
  //       );
  //
  //       if (!isValid!) {
  //         throw Exception('Invalid phone number');
  //       }
  //
  //       final formattedNumber = await PhoneNumberUtil.formatAsYouType(
  //           phoneNumber: phoneNumber, isoCode: 'ID');
  //
  //       print('--------- $formattedNumber');
  //
  //       return formattedNumber;
  //     } catch (e) {
  //       print('Error formatting phone number: $e');
  //       return null;
  //     }
  //   }
  //
  //   void sendOtp() async {
  //     setState(() {
  //       isLoading = true;
  //     });
  //
  //     try {
  //       final formattedPhoneNumber = await formatPhoneNumber(phoneController.text);
  //
  //       if (formattedPhoneNumber == null) {
  //         _alertService.showToast(
  //           text: 'Invalid phone number format.',
  //           icon: Icons.error,
  //           color: Colors.redAccent,
  //         );
  //         return;
  //       }
  //
  //       print('------ $formattedPhoneNumber');
  //
  //       await FirebaseAuth.instance.verifyPhoneNumber(
  //         phoneNumber: formattedPhoneNumber,
  //         verificationCompleted: (PhoneAuthCredential credential) async {
  //           await FirebaseAuth.instance.signInWithCredential(credential);
  //         },
  //         verificationFailed: (FirebaseAuthException e) {
  //           print('--- $e');
  //           _alertService.showToast(
  //             text: 'Verification failed. ${e.message}',
  //             icon: Icons.error,
  //             color: Colors.redAccent,
  //           );
  //         },
  //         codeSent: (String verificationId, int? resendToken) {
  //           setState(() {
  //             this.verificationId = verificationId;
  //             isOtpSent = true;
  //           });
  //         },
  //         codeAutoRetrievalTimeout: (String verificationId) {},
  //       );
  //     } catch (e) {
  //       _alertService.showToast(
  //         text: 'Error during OTP sending.',
  //         icon: Icons.error,
  //         color: Colors.redAccent,
  //       );
  //     } finally {
  //       setState(() {
  //         isLoading = false;
  //       });
  //     }
  //   }
  //
  //   void verifyOtp() async {
  //     setState(() {
  //       isLoading = true;
  //     });
  //
  //     try {
  //       PhoneAuthCredential credential = PhoneAuthProvider.credential(
  //         verificationId: verificationId!,
  //         smsCode: otpController.text,
  //       );
  //
  //       await FirebaseAuth.instance.signInWithCredential(credential);
  //
  //       // After successful login, you can perform additional tasks
  //       _alertService.showToast(
  //         text: 'Phone number verified successfully!',
  //         icon: Icons.check,
  //         color: Colors.green,
  //       );
  //
  //       // Navigate or create user profile here
  //     } catch (e) {
  //       _alertService.showToast(
  //         text: 'Error during OTP verification.',
  //         icon: Icons.error,
  //         color: Colors.redAccent,
  //       );
  //     } finally {
  //       setState(() {
  //         isLoading = false;
  //       });
  //     }
  //   }
  //
  //   return Column(
  //     children: [
  //       TextFieldCustom(
  //         controller: phoneController,
  //         onSaved: (value) {
  //           phoneController.text = value!;
  //         },
  //         validationRegEx: PHONE_VALIDATION_REGEX,
  //         height: MediaQuery.of(context).size.height * 0.1,
  //         hintText: 'Enter your phone number',
  //         obscureText: false,
  //       ),
  //       if (!isOtpSent)
  //         MaterialButton(
  //           color: Theme.of(context).colorScheme.primary,
  //           child: Text(
  //             'Send OTP',
  //             style: TextStyle(color: Colors.white),
  //           ),
  //           onPressed: sendOtp,
  //         ),
  //       if (isOtpSent)
  //         Column(
  //           children: [
  //             TextFieldCustom(
  //               controller: otpController,
  //               onSaved: (value) {
  //                 otpController.text = value!;
  //               },
  //               validationRegEx: NAME_VALIDATION_REGEX,
  //               height: MediaQuery.of(context).size.height * 0.1,
  //               hintText: 'Enter OTP',
  //               obscureText: false,
  //             ),
  //             MaterialButton(
  //               color: Theme.of(context).colorScheme.primary,
  //               child: Text(
  //                 'Verify OTP',
  //                 style: TextStyle(color: Colors.white),
  //               ),
  //               onPressed: verifyOtp,
  //             ),
  //           ],
  //         ),
  //     ],
  //   );
  // }

  Widget _pfpSelectionField() {
    return Stack(
      children: [
        Positioned(
          child: GestureDetector(
            onTap: () async {
              File? file = await _mediaService.getImageFromGalleryImage();
              if (file != null) {
                setState(() {
                  selectedImage = file;
                });
              }
            },
            child: CircleAvatar(
              radius: MediaQuery.of(context).size.width * 0.15,
              backgroundImage: selectedImage != null
                  ? FileImage(selectedImage!)
                  : NetworkImage(PLACEHOLDER_PFP) as ImageProvider,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.only(top: 90, left: 90),
          child: Icon(Icons.add_circle,
              color: Theme.of(context).colorScheme.primary, size: 30),
        ),
      ],
    );
  }

  Widget _registerButton() {
    return (isLoading == true)
        ? CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          )
        : SizedBox(
            width: MediaQuery.of(context).size.width,
            child: MaterialButton(
              color: Theme.of(context).colorScheme.primary,
              child: Text(
                'Register',
                style: TextStyle(color: Colors.white),
              ),
              // onPressed: () => _registerWithEmailAndPhone(),
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  _alertService.showToast(
                    text: 'Name cannot be empty.',
                    icon: Icons.error,
                    color: Colors.redAccent,
                  );
                  return;
                }

                if (numberController.text.isEmpty) {
                  _alertService.showToast(
                    text: 'Phone number cannot be empty.',
                    icon: Icons.error,
                    color: Colors.redAccent,
                  );
                  return;
                }

                if (emailController.text.isEmpty) {
                  _alertService.showToast(
                    text: 'Email cannot be empty.',
                    icon: Icons.error,
                    color: Colors.redAccent,
                  );
                  return;
                }

                if (passwordController.text.isEmpty) {
                  _alertService.showToast(
                    text: 'Password cannot be empty.',
                    icon: Icons.error,
                    color: Colors.redAccent,
                  );
                  return;
                }

                if (!_registerFormKey.currentState!.validate()) {
                  _alertService.showToast(
                    text: 'Please fill in all fields correctly.',
                    icon: Icons.error,
                    color: Colors.redAccent,
                  );
                  return;
                }

                try {
                  setState(() {
                    isLoading = true;
                  });
                  String email = emailController.text;
                  String password = passwordController.text;

                  UserCredential userCredential =
                      await _authService.signup(email, password);

                  if (userCredential.user != null) {
                    await userCredential.user!.sendEmailVerification();

                    String? pfpURL;
                    if (selectedImage != null) {
                      pfpURL = await _storageService.uploadUserPfp(
                        file: selectedImage!,
                        uid: userCredential.user!.uid,
                      );
                    }

                    await _databaseService.createUserProfile(
                      userProfile: UserProfile(
                        uid: userCredential.user!.uid,
                        name: nameController.text,
                        pfpURL: pfpURL ?? PLACEHOLDER_PFP,
                        phoneNumber: numberController.text,
                        email: emailController.text,
                        hasUploadedStory: false,
                        isViewed: false,
                      ),
                    );

                    _alertService.showToast(
                      text:
                          'Registration successful. Please verify your email.',
                      icon: Icons.check,
                      color: Colors.green,
                    );
                    _navigationService.goBack();
                  } else {
                    _alertService.showToast(
                      text: 'Registration failed.',
                      icon: Icons.error,
                      color: Colors.redAccent,
                    );
                  }
                } catch (e) {
                  _alertService.showToast(
                    text: 'Phone Number or Email has already been used.',
                    icon: Icons.error,
                    color: Colors.redAccent,
                  );
                } finally {
                  setState(() {
                    isLoading = false;
                  });
                }
              },
            ),
          );
  }

  Widget _loginAccountLink() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('Already have an account? '),
        GestureDetector(
          onTap: () {
            _navigationService.goBack();
          },
          child: Text(
            'Login',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  // Future<void> _registerWithEmailAndPhone() async {
  //   if (_registerFormKey.currentState?.validate() ?? false) {
  //     try {
  //       setState(() {
  //         isLoading = true;
  //       });
  //
  //       // 1. Registrasi dengan Email dan Password
  //       UserCredential userCredential =
  //       await _auth.createUserWithEmailAndPassword(
  //         email: emailController.text.trim(),
  //         password: passwordController.text.trim(),
  //       );
  //
  //       // 2. Verifikasi nomor telepon
  //       await _verifyPhoneNumber(numberController.text.trim());
  //
  //
  //       _alertService.showToast(
  //         text: 'Verification code sent. Enter OTP to complete registration.',
  //         icon: Icons.check,
  //         color: Colors.green,
  //       );
  //       // _showToast('Verification code sent. Enter OTP to complete registration.');
  //
  //     } catch (e) {
  //       _alertService.showToast(
  //         text: e.toString(),
  //         icon: Icons.error,
  //         color: Colors.redAccent,
  //       );
  //       // _showToast('Registration failed: $e');
  //     } finally {
  //       setState(() {
  //         isLoading = false;
  //       });
  //     }
  //   } else {
  //     _alertService.showToast(
  //       text: 'Please fill in all fields.',
  //       icon: Icons.error,
  //       color: Colors.redAccent,
  //     );
  //     // _showToast('Please fill in all fields.');
  //   }
  // }

  // Future<void> _verifyNumber(String phoneNumber) async {
  //   await _auth.verifyPhoneNumber(
  //     phoneNumber: phoneNumber,
  //     verificationCompleted: (PhoneAuthCredential credential) async {
  //       // Verifikasi otomatis
  //       await _auth.signInWithCredential(credential);
  //     },
  //     verificationFailed: (FirebaseAuthException e) {
  //       // Gagal verifikasi
  //       _alertService.showToast(
  //         text: e.message!,
  //         icon: Icons.check,
  //         color: Colors.green,
  //       );
  //       // _showToast('Verification failed: ${e.message}');
  //     },
  //     codeSent: (String verificationId, int? resendToken) {
  //       // Kode OTP terkirim
  //       setState(() {
  //         _verificationId = verificationId;
  //         otpe = true;
  //       });
  //     },
  //     codeAutoRetrievalTimeout: (String verificationId) {
  //       _verificationId = verificationId;
  //     },
  //   );
  // }

  // Future<void> _submitOTPE(String otpCode) async {
  //   try {
  //     PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(
  //       verificationId: _verificationId!,
  //       smsCode: otpCode,
  //     );
  //
  //     // 3. Hubungkan akun email dengan nomor telepon
  //     await FirebaseAuth.instance.currentUser?.linkWithCredential(phoneAuthCredential);
  //
  //     _alertService.showToast(
  //       text: 'Registration and phone verification successful.',
  //       icon: Icons.check,
  //       color: Colors.green,
  //     );
  //     // _showToast('Registration and phone verification successful.');
  //   } catch (e) {
  //     _alertService.showToast(
  //       text: e.toString(),
  //       icon: Icons.error,
  //       color: Colors.redAccent,
  //     );
  //     // _showToast('Failed to link phone number: $e');
  //   }
  // }
}