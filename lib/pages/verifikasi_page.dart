import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

class Verifikasi extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  Verifikasi({required this.phoneNumber, required this.verificationId});

  @override
  State<Verifikasi> createState() => _VerifikasiState();
}

class _VerifikasiState extends State<Verifikasi> {
  bool verifikasi = false;
  late Timer _timer;
  int _start = 60;

  void startTimer() {
    _start = 60; // Reset timer ke 60 detik
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_start > 0) {
          _start--;
        } else {
          _timer.cancel();
          verifikasi = false; // Reset verifikasi setelah waktu habis
        }
      });
    });
  }

  String formatTimer(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  void _verifyOTP(String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: widget.verificationId,
      smsCode: smsCode,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
    // Setelah berhasil login
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
      body: Container(
        padding:  EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify OTP Code',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10),
                (verifikasi == true) ? Text(
                  'Masukan kode OTP yang kamu terima lewat SMS di ${widget.phoneNumber}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ) : Text(
                  'Please select a method below to get the OTP code.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: (verifikasi == true) ? 10 : 30),
                (verifikasi == true) ? OtpTextField(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  keyboardType: TextInputType.number,
                  numberOfFields: 6,
                  enabledBorderColor: Colors.grey,
                  borderColor: Theme.of(context).colorScheme.primary,
                  focusedBorderColor:
                  Theme.of(context).colorScheme.primary,
                  showFieldAsBox: true,
                  onCodeChanged: (String code) {},
                  onSubmit: (String otpCode) {},
                ) : Image.asset(
                  'assets/verifikasi.jpg',
                ),
                SizedBox(height: (verifikasi == true) ? 10 : 30),
                (verifikasi == true) ? Center(
                  child: Text(
                    formatTimer(_start),
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ) : GestureDetector(
                  onTap: () {
                    setState(() {
                      verifikasi = true;
                    });
                    startTimer();
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.chat,
                              color: Theme.of(context).primaryColor,
                              size: 28,
                            ),
                            SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Send via SMS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  widget.phoneNumber,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            (verifikasi == true) ? Container() : Text(
              'If nothing is selected within 7 seconds, a code will be sent automatically via SMS.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}