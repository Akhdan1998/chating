import 'dart:async';
import 'dart:io';
import 'package:chating/utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../consts.dart';
import '../../service/alert_service.dart';
import '../../service/media_service.dart';
import '../../widgets/textfield.dart';
import 'package:flutter/foundation.dart' as foundation;

class Verifikasi extends StatefulWidget {
  final String phoneNumber;

  // final String nama;

  Verifikasi({required this.phoneNumber});

  @override
  _VerifikasiState createState() => _VerifikasiState();
}

class _VerifikasiState extends State<Verifikasi> {
  bool isOtpSent = false;
  bool isName = false;
  bool isLoading = false;
  late Timer _timer;
  int _remainingTime = 7;
  int _remaining = 60;
  late AlertService _alertService;
  final GetIt _getIt = GetIt.instance;
  String _verificationId = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  File? selectedImage;
  final TextEditingController nameController = TextEditingController();
  bool showEmojiPicker = false;
  late MediaService _mediaService;

  @override
  void initState() {
    super.initState();
    _alertService = _getIt.get<AlertService>();
    _mediaService = _getIt.get<MediaService>();
    autoSend();
  }

  void autoSend() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _timer.cancel();
          setState(() {
            isOtpSent = true;
          });
          // _sendOTP();
        }
      });
    });
  }

  Future<void> _sendOTP() async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        timeout: Duration(seconds: 60),
        verificationCompleted: (credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _alertService.showToast(
            text: 'Failed to send OTP: ${e.message}',
            icon: Icons.error,
            color: Colors.redAccent,
          );
          print('Error sending OTP: ${e.code} - ${e.message}');
        },
        codeSent: (verificationId, _) {
          setState(() {
            _verificationId = verificationId;
            isOtpSent = true;
          });
          _startTimer();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      print('An unexpected error occurred: $e');
      _alertService.showToast(
        text: 'An unexpected error occurred. Please try again.',
        icon: Icons.error,
        color: Colors.redAccent,
      );
    }
  }

  Future<void> _verifyOTP(String otpCode) async {
    setState(() {
      isLoading = true;
    });
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otpCode,
      );
      await _auth.signInWithCredential(credential);

      _alertService.showToast(
        text: 'OTP Verified!',
        icon: Icons.check,
        color: Colors.green,
      );

    } catch (e) {
      print('OTP ERROR $e');
      _alertService.showToast(
        text: 'Invalid OTP Code, please try again.',
        icon: Icons.error,
        color: Colors.redAccent,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _startTimer() {
    _remaining = 60;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _timer.cancel();
          isOtpSent = false;
        }
      });
    });
  }

  String _formatTimer(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: (isName)
            ? Container()
            : IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.arrow_back),
              ),
        actions: [
          (isName)
              ? IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.more_vert),
                )
              : Container(),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildContent(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return (isName)
        ? Container(
            height: MediaQuery.of(context).size.height - 145,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Info profil'.tr(),
                      style: StyleText(fontSize: 16, fontWeight: FontWeight.w600,),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Mohon berikan nama dan foto profil (opsional) Anda'.tr(),
                      textAlign: TextAlign.center,
                      style: StyleText(fontSize: 15),
                    ),
                    SizedBox(height: 30),
                    GestureDetector(
                      onTap: () async {
                        File? file = await _mediaService.getImageFromGalleryImage();
                        if (file != null) {
                          setState(() {
                            selectedImage = file;
                          });
                        }
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: selectedImage != null
                                ? FileImage(selectedImage!)
                                : NetworkImage(PLACEHOLDER_PFP)
                                    as ImageProvider,
                          ),
                          Container(
                            padding: EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            child: Icon(
                              Icons.add,
                              size: 17,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: TextFieldCustom(
                            autoFocus: true,
                            textCapitalization: TextCapitalization.sentences,
                            controller: nameController,
                            onSaved: (value) {
                              nameController.text = value!;
                            },
                            validationRegEx: NAME_VALIDATION_REGEX,
                            height: MediaQuery.of(context).size.height * 0.1,
                            hintText: 'name'.tr(),
                            obscureText: false,
                          ),
                        ),
                        SizedBox(width: 10),
                        IconButton(
                          icon: Icon(Icons
                              .emoji_emotions_outlined),
                          onPressed: () {
                            setState(() {
                              showEmojiPicker =
                                  !showEmojiPicker;
                            });
                          },
                        ),
                      ],
                    ),
                    if (showEmojiPicker)
                      EmojiPicker(
                        onBackspacePressed: () {
                          if (nameController.text.isNotEmpty) {
                            nameController.text = nameController.text
                                .substring(0, nameController.text.length - 1);
                          }
                        },
                        textEditingController: nameController,
                        config: Config(
                          height: 210,
                          checkPlatformCompatibility: true,
                          emojiViewConfig: EmojiViewConfig(
                            emojiSizeMax: 20 *
                                (foundation.defaultTargetPlatform ==
                                        TargetPlatform.android
                                    ? 1.20
                                    : 1.0),
                          ),
                          viewOrderConfig: ViewOrderConfig(
                            top: EmojiPickerItem.categoryBar,
                            middle: EmojiPickerItem.emojiView,
                          ),
                          skinToneConfig: SkinToneConfig(),
                          categoryViewConfig: CategoryViewConfig(),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: _registerButton(),
                ),
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verify OTP Code', style: _headerStyle),
              SizedBox(height: 10),
              Text(
                isOtpSent
                    ? 'Enter the OTP code you received via SMS at ${widget.phoneNumber}'
                    : 'Please select a method below to get the OTP code.',
                style: _bodyStyle,
              ),
              SizedBox(height: isOtpSent ? 30 : 10),
              isOtpSent
                  ? Container()
                  : Image.asset(
                      'assets/verifikasi.jpg',
                    ),
              SizedBox(height: isOtpSent ? 10 : 20),
              isOtpSent ? _buildOtpField() : _buildSendOtpButton(),
              SizedBox(height: 30),
              if (isOtpSent) _buildTimer(),
            ],
          );
  }

  Widget _registerButton() {
    return isLoading
        ? CircularProgressIndicator(color: Colors.white)
        : SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                'next'.tr(),
                style: StyleText(fontSize: 16,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,),
              ),
            ),
          );
  }

  Widget _buildOtpField() {
    return OtpTextField(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      keyboardType: TextInputType.number,
      numberOfFields: 6,
      enabledBorderColor: Colors.grey,
      borderColor: Theme.of(context).colorScheme.primary,
      focusedBorderColor: Theme.of(context).colorScheme.primary,
      showFieldAsBox: true,
      onSubmit: (String otpCode) {
        setState(() {
          isName = true;
        });
        _verifyOTP(otpCode);
      },
    );
  }

  Widget _buildSendOtpButton() {
    return GestureDetector(
      // onTap: _sendOTP,
      onTap: () {
        setState(() {
          isOtpSent = true;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.chat,
                    color: Theme.of(context).primaryColor, size: 28),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Send via SMS',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(widget.phoneNumber,
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Theme.of(context).primaryColor, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer() {
    return Center(
      child: Text(
        _formatTimer(_remaining),
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFooter() {
    return isOtpSent
        ? Container()
        : Text(
            'If nothing is selected within $_remainingTime seconds, a code will be sent automatically via SMS.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          );
  }

  TextStyle get _headerStyle => TextStyle(
      fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87);

  TextStyle get _bodyStyle => TextStyle(fontSize: 16, color: Colors.grey[600]);
}
