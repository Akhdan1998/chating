import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:get_it/get_it.dart';
import '../service/alert_service.dart';

class Verifikasi extends StatefulWidget {
  final String phoneNumber;
  final String nama;

  Verifikasi({required this.phoneNumber, required this.nama});

  @override
  _VerifikasiState createState() => _VerifikasiState();
}

class _VerifikasiState extends State<Verifikasi> {
  bool isOtpSent = false;
  late Timer _timer;
  int _remainingTime = 7;
  int _remaining = 60;
  late AlertService _alertService;
  final GetIt _getIt = GetIt.instance;
  String _verificationId = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _alertService = _getIt.get<AlertService>();
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
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otpCode,
      );
      await _auth.signInWithCredential(credential);
      _alertService.showToast(
          text: 'OTP Verified!', icon: Icons.check, color: Colors.green,);
    } catch (e) {
      _alertService.showToast(
        text: 'Invalid OTP Code: $e',
        icon: Icons.error,
        color: Colors.redAccent,
      );
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
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildContent(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
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

  Widget _buildOtpField() {
    return OtpTextField(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      keyboardType: TextInputType.number,
      numberOfFields: 6,
      enabledBorderColor: Colors.grey,
      borderColor: Theme.of(context).colorScheme.primary,
      focusedBorderColor: Theme.of(context).colorScheme.primary,
      showFieldAsBox: true,
      onSubmit: (String otpCode) => _verifyOTP(otpCode),
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
