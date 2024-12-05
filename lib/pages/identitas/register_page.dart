import 'dart:io';
import 'package:chating/widgets/utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/consts.dart';
import '../../models/user_profile.dart';
import '../../service/alert_service.dart';
import '../../service/auth_service.dart';
import '../../service/database_service.dart';
import '../../service/media_service.dart';
import '../../service/navigation_service.dart';
import '../../service/storage_service.dart';
import '../../widgets/textfield.dart';

class RegisterPage extends StatefulWidget {
  RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GetIt _getIt = GetIt.instance;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _registerFormKey = GlobalKey();
  late AuthService _authService;
  late AlertService _alertService;
  late MediaService _mediaService;
  late NavigationService _navigationService;
  late StorageService _storageService;
  late DatabaseService _databaseService;
  File? selectedImage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _mediaService = _getIt.get<MediaService>();
    _navigationService = _getIt.get<NavigationService>();
    _authService = _getIt.get<AuthService>();
    _storageService = _getIt.get<StorageService>();
    _alertService = _getIt.get<AlertService>();
    _databaseService = _getIt.get<DatabaseService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        alignment: Alignment.center,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _headerText(),
              SizedBox(height: 20),
              _registerForm(),
              SizedBox(height: 20),
              _loginAccountLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "go".tr(),
          style: StyleText(
            fontWeight: FontWeight.w500,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'title_register'.tr(),
          style: StyleText(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _registerForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        children: [
          _pfpSelectionField(),
          SizedBox(height: 15),
          TextFieldCustom(
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
          SizedBox(height: 10),
          TextFieldCustom(
            controller: numberController,
            onSaved: (value) {
              numberController.text = value!;
            },
            validationRegEx: PHONE_VALIDATION_REGEX,
            height: MediaQuery.of(context).size.height * 0.1,
            hintText: '081290763984',
            obscureText: false,
          ),
          SizedBox(height: 10),
          TextFieldCustom(
            controller: emailController,
            onSaved: (value) {
              emailController.text = value!;
            },
            validationRegEx: EMAIL_VALIDATION_REGEX,
            height: MediaQuery.of(context).size.height * 0.1,
            hintText: 'email'.tr(),
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
            hintText: 'password'.tr(),
            obscureText: true,
          ),
          SizedBox(height: 20),
          _registerButton(),
        ],
      ),
    );
  }

  Widget _pfpSelectionField() {
    return GestureDetector(
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
                : NetworkImage(PLACEHOLDER_PFP) as ImageProvider,
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
    );
  }

  Widget _registerButton() {
    return isLoading
        ? CircularProgressIndicator(color: Colors.white)
        : SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onRegisterPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                'register'.tr(),
                style: StyleText(
                  fontSize: 16,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
  }

  void _onRegisterPressed() async {
    if (nameController.text.isEmpty) {
      _alertService.showToast(
        text: 'cannot_name'.tr(),
        icon: Icons.error,
        color: Colors.redAccent,
      );
      return;
    }

    if (numberController.text.isEmpty) {
      _alertService.showToast(
        text: 'cannot_number'.tr(),
        icon: Icons.error,
        color: Colors.redAccent,
      );
      return;
    }

    if (emailController.text.isEmpty) {
      _alertService.showToast(
        text: 'cannot_email'.tr(),
        icon: Icons.error,
        color: Colors.redAccent,
      );
      return;
    }

    if (passwordController.text.isEmpty) {
      _alertService.showToast(
        text: 'cannot_pass'.tr(),
        icon: Icons.error,
        color: Colors.redAccent,
      );
      return;
    }

    if (!_registerFormKey.currentState!.validate()) {
      _alertService.showToast(
        text: 'correctly'.tr(),
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
          text: 'regis_success'.tr(),
          icon: Icons.check,
          color: Colors.green,
        );
        _navigationService.goBack();
      } else {
        _alertService.showToast(
          text: 'regis_failed'.tr(),
          icon: Icons.error,
          color: Colors.redAccent,
        );
      }
    } catch (e) {
      _alertService.showToast(
        text: 'already_been_used'.tr(),
        icon: Icons.error,
        color: Colors.redAccent,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _loginAccountLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'have_account'.tr(),
          style: StyleText(color: Colors.white),
        ),
        GestureDetector(
          onTap: () => _navigationService.goBack(),
          child: Text(
            'in'.tr(),
            style: StyleText(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
