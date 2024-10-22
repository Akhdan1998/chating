import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../consts.dart';
import '../service/alert_service.dart';
import '../service/auth_service.dart';
import '../service/database_service.dart';
import '../service/media_service.dart';
import '../service/navigation_service.dart';
import '../service/storage_service.dart';
import '../widgets/textfield.dart';

class RegisterPage extends StatefulWidget {
  RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  File? selectedImage;
  final GetIt _getIt = GetIt.instance;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _registerFormKey = GlobalKey();
  FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;

  late AuthService _authService;
  late AlertService _alertService;
  late MediaService _mediaService;
  late NavigationService _navigationService;
  late StorageService _storageService;
  late DatabaseService _databaseService;

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
      resizeToAvoidBottomInset: false,
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
          "Let's get going!",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Register an account using the form below',
          style: TextStyle(
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
            child: Icon(Icons.add, size: 17, color: Colors.white,),
          ),

        ],
      ),
    );
  }

  Widget _registerButton() {
    return isLoading
        ? CircularProgressIndicator(
            color: Colors.white)
        : SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onRegisterPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                'Register',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blueGrey,
                ),
              ),
            ),
          );
  }

  void _onRegisterPressed() async {
    if (_registerFormKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        // Proses registrasi dan penanganan error
      } catch (e) {
        _alertService.showToast(
          text: 'Error: $e',
          icon: Icons.error,
          color: Colors.redAccent,
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _loginAccountLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account? ',
          style: TextStyle(
            color: Colors.white,
          ),),
        GestureDetector(
          onTap: () => _navigationService.goBack(),
          child: Text(
            'Login',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
