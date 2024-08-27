import 'dart:io';

import 'package:chating/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../consts.dart';
import '../service/alert_service.dart';
import '../service/storage_service.dart';
import '../widgets/textfield.dart';

class EditPage extends StatefulWidget {
  final UserProfile userProfile;

  EditPage({required this.userProfile});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  File? _image;
  final GetIt _getIt = GetIt.instance;
  late AlertService _alertService;

  Future getImage() async {
    final Image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (Image == null) return;
    final imageTemporary = File(Image.path);
    setState(() {
      this._image = imageTemporary;
    });
  }

  @override
  void initState() {
    super.initState();
    _alertService = _getIt.get<AlertService>();
    nameController.text = widget.userProfile.name ?? '-';
    numberController.text = widget.userProfile.phoneNumber ?? '-';
  }

  Future<void> saveUserProfile() async {
    try {
      String? imageUrl;

      // If a new image is selected, upload it to Firebase Storage
      if (_image != null) {
        final storageService = StorageService();
        imageUrl = await storageService.uploadUserPfp(
          file: _image!,
          uid: widget.userProfile.uid!,
        );
      }

      // Create an updated user profile object
      final updatedUserProfile = UserProfile(
        uid: widget.userProfile.uid,
        name: nameController.text,
        phoneNumber: numberController.text,
        email: widget.userProfile.email,
        // Email is not editable in this case
        pfpURL: imageUrl ?? widget.userProfile.pfpURL,
      );

      // Save the updated profile to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userProfile.uid)
          .set(updatedUserProfile.toMap());

      _alertService.showToast(
        text: 'Profile updated successfully!',
        icon: Icons.check,
        color: Colors.green,
      );
    } catch (e) {
      print('ERRORRRRR ${e}');
      _alertService.showToast(
        text: e.toString(),
        icon: Icons.error,
        color: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Container(
          child: Text(
            'Edit Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.sizeOf(context).height,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: 30,
                color: Theme.of(context).colorScheme.primary,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(18),
                      topLeft: Radius.circular(18),
                    ),
                  ),
                ),
              ),
              Stack(
                fit: StackFit.loose,
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    child: GestureDetector(
                      onTap: () {
                        getImage();
                      },
                      child: _image != null
                          ? Container(
                              padding: EdgeInsets.all(10),
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: FileImage(_image!)),
                                borderRadius: BorderRadius.circular(100),
                              ),
                            )
                          : (widget.userProfile.pfpURL == "PLACEHOLDER_PFP")
                              ? Image.network('PLACEHOLDER_PFP')
                              : Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    image: DecorationImage(
                                        fit: BoxFit.cover,
                                        image: NetworkImage(
                                            widget.userProfile.pfpURL ?? '')),
                                  ),
                                ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 90, left: 80),
                    child: Icon(Icons.add_circle,
                        color: Theme.of(context).colorScheme.primary, size: 30),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.only(left: 20, right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name'),
                    SizedBox(height: 10),
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
                    SizedBox(height: 20),
                    Text('Phone Number'),
                    SizedBox(height: 10),
                    TextFieldCustom(
                      controller: numberController,
                      onSaved: (value) {
                        numberController.text = value!;
                      },
                      validationRegEx: PHONE_VALIDATION_REGEX,
                      height: MediaQuery.of(context).size.height * 0.1,
                      hintText: 'Phone Number',
                      obscureText: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(microseconds: 500),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          color: Colors.white,
          alignment: Alignment.bottomCenter,
          width: MediaQuery.of(context).size.width,
          height: 60,
          padding: EdgeInsets.fromLTRB(13, 8, 13, 8),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: 40,
            child: ElevatedButton(
              style: style,
              onPressed: () {
                saveUserProfile().whenComplete(() {      Navigator.pop(context);
                });
              },
              child: Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  final ButtonStyle style = ElevatedButton.styleFrom(
    textStyle:
        GoogleFonts.poppins().copyWith(fontSize: 14, color: Colors.white),
    backgroundColor: Colors.deepPurple,
  );
}
