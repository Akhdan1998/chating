import 'package:chating/models/user_profile.dart';
import 'package:chating/widgets/utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/consts.dart';
import '../../service/alert_service.dart';
import '../../service/auth_service.dart';
import '../../widgets/textfield.dart';

class UpdatePasswordPage extends StatefulWidget {
  final UserProfile userProfile;

  UpdatePasswordPage({required this.userProfile});

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController =
      TextEditingController();
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late AlertService _alertService;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _alertService = _getIt.get<AlertService>();
    emailController.text = widget.userProfile.email ?? '-';
  }

  Future<void> _updatePassword() async {
    if (newPasswordController.text != confirmNewPasswordController.text) {
      _alertService.showToast(
        text: 'New passwords do not match.',
        icon: Icons.error,
        color: Colors.redAccent,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Reauthenticate the user
      bool reauthenticated =
          await _authService.reauthenticateUser(currentPasswordController.text);
      if (!reauthenticated) {
        _alertService.showToast(
          text: 'Current password is incorrect.',
          icon: Icons.error,
          color: Colors.redAccent,
        );
        return;
      }

      // Update the user's password
      await _authService.updatePassword(newPasswordController.text);
      _alertService.showToast(
        text: 'Password updated successfully.',
        icon: Icons.check,
        color: Colors.green,
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _alertService.showToast(
        text: 'Failed to update password: ${e.message}',
        icon: Icons.error,
        color: Colors.redAccent,
      );
    } catch (e) {
      _alertService.showToast(
        text: 'An error occurred: $e',
        icon: Icons.error,
        color: Colors.redAccent,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'update_password'.tr(),
          style: StyleText(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _passwordUpdateForm(),
              SizedBox(height: 20),
              _updatePasswordButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordUpdateForm() {
    return Column(
      children: [
        TextFieldCustom(
          readOnly: true,
          controller: emailController,
          hintText: 'email'.tr(),
          obscureText: false,
          validationRegEx: EMAIL_VALIDATION_REGEX,
          onSaved: (value) {
            emailController.text = value!;
          },
          height: MediaQuery.of(context).size.height * 0.1,
        ),
        const SizedBox(height: 20),
        TextFieldCustom(
          controller: currentPasswordController,
          hintText: 'current_password'.tr(),
          obscureText: true,
          validationRegEx: NAME_VALIDATION_REGEX,
          onSaved: (value) {
            currentPasswordController.text = value!;
          },
          height: MediaQuery.of(context).size.height * 0.1,
        ),
        const SizedBox(height: 20),
        TextFieldCustom(
          controller: newPasswordController,
          hintText: 'new_password'.tr(),
          obscureText: true,
          validationRegEx: NAME_VALIDATION_REGEX,
          onSaved: (value) {
            newPasswordController.text = value!;
          },
          height: MediaQuery.of(context).size.height * 0.1,
        ),
        const SizedBox(height: 20),
        TextFieldCustom(
          controller: confirmNewPasswordController,
          hintText: 'new_password_confirm'.tr(),
          obscureText: true,
          validationRegEx: NAME_VALIDATION_REGEX,
          onSaved: (value) {
            confirmNewPasswordController.text = value!;
          },
          height: MediaQuery.of(context).size.height * 0.1,
        ),
      ],
    );
  }

  Widget _updatePasswordButton() {
    final ButtonStyle style = ElevatedButton.styleFrom(
      textStyle:
          GoogleFonts.poppins().copyWith(fontSize: 14, color: Colors.white),
      backgroundColor: Theme.of(context).colorScheme.primary,
    );

    return isLoading
        ? CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          )
        : Container(
            width: double.infinity,
            child: ElevatedButton(
              style: style, // Use the defined style here
              onPressed: _updatePassword,
              child: Text(
                'update_password'.tr(),
                style: StyleText(color: Colors.white),
              ),
            ),
          );
  }
}
