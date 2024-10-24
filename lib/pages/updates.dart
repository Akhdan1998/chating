import 'dart:io';
import 'package:chating/pages/storyView_page.dart';
import 'package:chating/pages/otherUserStory_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:story_view/controller/story_controller.dart';
import '../models/user_profile.dart';
import '../service/alert_service.dart';
import '../service/auth_service.dart';
import '../service/database_service.dart';
import '../service/navigation_service.dart';
import 'package:image/image.dart' as img;

class UpdatesPage extends StatefulWidget {
  const UpdatesPage({super.key});

  @override
  State<UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage> {
  final StoryController _storyController = StoryController();
  late NavigationService _navigationService;
  final GetIt _getIt = GetIt.instance;
  late DatabaseService _databaseService;
  late AuthService _authService;
  final ImagePicker _picker = ImagePicker();
  final currentUser = FirebaseAuth.instance;
  Set<String> clickedUIDs = {};
  bool _isRequestingPermission = false;
  late AlertService _alertService;

  @override
  void initState() {
    super.initState();
    _navigationService = _getIt.get<NavigationService>();
    _databaseService = _getIt.get<DatabaseService>();
    _authService = _getIt.get<AuthService>();
    _alertService = _getIt.get<AlertService>();
  }

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    if (_isRequestingPermission) return;
    _isRequestingPermission = true;

    try {
      await Permission.camera.request();
    } finally {
      _isRequestingPermission = false;
    }
  }

  // Future<void> _pickAndUploadMedia(ImageSource source) async {
  //   final ImagePicker _picker = ImagePicker();
  //   context.loaderOverlay.show();
  //
  //   final XFile? pickedFile = await _picker.pickImage(source: source);
  //
  //   if (pickedFile == null) {
  //     context.loaderOverlay.hide();
  //     print('No image selected');
  //     return;
  //   }
  //
  //   File file = File(pickedFile.path);
  //   print('Ukuran file sebelum dikompresi: ${file.lengthSync()} bytes');
  //
  //   final img.Image? image = img.decodeImage(file.readAsBytesSync());
  //   if (image != null) {
  //     final compressedImage = img.encodeJpg(image, quality: 50);
  //     File compressedFile = File('${file.path}.jpg')
  //       ..writeAsBytesSync(compressedImage);
  //     print('Ukuran gambar setelah kompresi: ${compressedImage.length} bytes');
  //
  //     try {
  //       String fileName = 'stories/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
  //       UploadTask uploadTask = FirebaseStorage.instance
  //           .ref()
  //           .child(fileName)
  //           .putFile(compressedFile);
  //       TaskSnapshot taskSnapshot = await uploadTask;
  //       String downloadUrl = await taskSnapshot.ref.getDownloadURL();
  //
  //       DateTime localTimestamp = DateTime.now();
  //
  //       await FirebaseFirestore.instance.runTransaction((transaction) async {
  //         transaction.set(
  //           FirebaseFirestore.instance.collection('stories').doc(),
  //           {
  //             'url': downloadUrl,
  //             'serverTimestamp': FieldValue.serverTimestamp(),
  //             'localTimestamp': localTimestamp,
  //             'uid': currentUser.currentUser!.uid,
  //             'timestamp': localTimestamp,
  //           },
  //         );
  //
  //         transaction.update(
  //           FirebaseFirestore.instance.collection('users').doc(currentUser.currentUser!.uid),
  //           {
  //             'hasUploadedStory': true,
  //             'latestStoryUrl': downloadUrl,
  //           },
  //         );
  //       });
  //       context.loaderOverlay.hide();
  //       print('Upload successful: $downloadUrl');
  //     } catch (e) {
  //       print('Failed to upload: $e');
  //     } finally {
  //       context.loaderOverlay.hide();
  //     }
  //   } else {
  //     context.loaderOverlay.hide();
  //     print('Failed to decode image');
  //   }
  // }

  // Future<void> _pickAndUploadMedia(ImageSource source, bool isVideo) async {
  //   final ImagePicker _picker = ImagePicker();
  //   context.loaderOverlay.show();
  //
  //   final XFile? pickedFile = await _picker.pickImage(source: source);
  //   if (pickedFile == null) {
  //     context.loaderOverlay.hide();
  //     print('No image selected');
  //     return;
  //   }
  //
  //   File file = File(pickedFile.path);
  //   print('File size before compression: ${file.lengthSync()} bytes');
  //
  //   final img.Image? image = img.decodeImage(await file.readAsBytes());
  //   if (image == null) {
  //     context.loaderOverlay.hide();
  //     print('Failed to decode image');
  //     return;
  //   }
  //
  //   final compressedImage = img.encodeJpg(image, quality: 50);
  //   final String compressedFilePath = '${file.path}.jpg';
  //   await File(compressedFilePath).writeAsBytes(compressedImage);
  //   print('File size after compression: ${compressedImage.length} bytes');
  //
  //   String fileName =
  //       'stories/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
  //   try {
  //     UploadTask uploadTask = FirebaseStorage.instance
  //         .ref()
  //         .child(fileName)
  //         .putFile(File(compressedFilePath));
  //
  //     TaskSnapshot taskSnapshot = await uploadTask;
  //     String downloadUrl = await taskSnapshot.ref.getDownloadURL();
  //
  //     DateTime localTimestamp = DateTime.now();
  //     await FirebaseFirestore.instance.runTransaction((transaction) async {
  //       transaction.set(
  //         FirebaseFirestore.instance.collection('stories').doc(),
  //         {
  //           'url': downloadUrl,
  //           'serverTimestamp': FieldValue.serverTimestamp(),
  //           'localTimestamp': localTimestamp,
  //           'uid': currentUser.currentUser!.uid,
  //           'timestamp': localTimestamp,
  //         },
  //       );
  //
  //       transaction.update(
  //         FirebaseFirestore.instance
  //             .collection('users')
  //             .doc(currentUser.currentUser!.uid),
  //         {
  //           'hasUploadedStory': true,
  //           'latestStoryUrl': downloadUrl,
  //         },
  //       );
  //     });
  //     context.loaderOverlay.hide();
  //     print('Upload successful: $downloadUrl');
  //   } catch (e) {
  //     context.loaderOverlay.hide();
  //     _alertService.showToast(
  //       text: e.toString(),
  //       icon: Icons.error,
  //       color: Colors.red,
  //     );
  //     print('Failed to upload: $e');
  //   } finally {
  //     context.loaderOverlay.hide();
  //   }
  // }

  Future<void> _pickAndUploadMedia(ImageSource source, bool isVideo) async {
    final ImagePicker _picker = ImagePicker();
    context.loaderOverlay.show();

    XFile? pickedFile;

    if (isVideo) {
      pickedFile = await _picker.pickVideo(source: source);
    } else {
      pickedFile = await _picker.pickImage(source: source);
    }

    if (pickedFile == null) {
      context.loaderOverlay.hide();
      print('No media selected');
      return;
    }

    File file = File(pickedFile.path);

    // Jika media adalah video, langsung upload tanpa kompresi
    if (isVideo) {
      print('Uploading video: ${file.path}');

      // Nama file untuk video
      String fileName = 'stories/videos/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';

      try {
        UploadTask uploadTask = FirebaseStorage.instance
            .ref()
            .child(fileName)
            .putFile(file);  // Unggah file video langsung tanpa kompresi

        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        DateTime localTimestamp = DateTime.now();
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.set(
            FirebaseFirestore.instance.collection('stories').doc(),
            {
              'url': downloadUrl,
              'type': 'video', // Tambahkan informasi jenis file (video)
              'serverTimestamp': FieldValue.serverTimestamp(),
              'localTimestamp': localTimestamp,
              'uid': currentUser.currentUser!.uid,
              'timestamp': localTimestamp,
            },
          );

          transaction.update(
            FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.currentUser!.uid),
            {
              'hasUploadedStory': true,
              'latestStoryUrl': downloadUrl,
            },
          );
        });

        context.loaderOverlay.hide();
        print('Video upload successful: $downloadUrl');
      } catch (e) {
        context.loaderOverlay.hide();
        _alertService.showToast(
          text: e.toString(),
          icon: Icons.error,
          color: Colors.red,
        );
        print('Failed to upload video: $e');
      }

    } else {
      // Proses kompresi untuk gambar
      print('File size before compression: ${file.lengthSync()} bytes');

      final img.Image? image = img.decodeImage(await file.readAsBytes());
      if (image == null) {
        context.loaderOverlay.hide();
        print('Failed to decode image');
        return;
      }

      final compressedImage = img.encodeJpg(image, quality: 50);
      final String compressedFilePath = '${file.path}.jpg';
      await File(compressedFilePath).writeAsBytes(compressedImage);
      print('File size after compression: ${compressedImage.length} bytes');

      // Nama file untuk gambar
      String fileName = 'stories/images/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';

      try {
        UploadTask uploadTask = FirebaseStorage.instance
            .ref()
            .child(fileName)
            .putFile(File(compressedFilePath));  // Unggah file gambar yang telah dikompresi

        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        DateTime localTimestamp = DateTime.now();
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.set(
            FirebaseFirestore.instance.collection('stories').doc(),
            {
              'url': downloadUrl,
              'type': 'image', // Tambahkan informasi jenis file (gambar)
              'serverTimestamp': FieldValue.serverTimestamp(),
              'localTimestamp': localTimestamp,
              'uid': currentUser.currentUser!.uid,
              'timestamp': localTimestamp,
            },
          );

          transaction.update(
            FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.currentUser!.uid),
            {
              'hasUploadedStory': true,
              'latestStoryUrl': downloadUrl,
            },
          );
        });

        context.loaderOverlay.hide();
        print('Image upload successful: $downloadUrl');
      } catch (e) {
        context.loaderOverlay.hide();
        _alertService.showToast(
          text: e.toString(),
          icon: Icons.error,
          color: Colors.red,
        );
        print('Failed to upload image: $e');
      }
    }
  }

  void _chooseStory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.camera_alt,
                color: Colors.green,),
              title: Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                context.loaderOverlay.show();
                await _pickAndUploadMedia(ImageSource.camera, false);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library,
                color: Colors.redAccent,),
              title: Text('Choose Photo from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                context.loaderOverlay.show();
                await _pickAndUploadMedia(ImageSource.gallery, false);
              },
            ),
            // ListTile(
            //   leading: Icon(Icons.videocam),
            //   title: Text('Record Video'),
            //   onTap: () async {
            //     Navigator.pop(context); // Tutup modal
            //     await _pickAndUploadMedia(ImageSource.camera, true); // Ambil video
            //   },
            // ),
            // ListTile(
            //   leading: Icon(Icons.video_library),
            //   title: Text('Choose Video from Gallery'),
            //   onTap: () async {
            //     Navigator.pop(context); // Tutup modal
            //     await _pickAndUploadMedia(ImageSource.gallery, true); // Pilih video dari galeri
            //   },
            // ),
          ],
        );
      },
    );
  }

  //kompres video
  // Future<void> _pickAndUploadMedia(ImageSource source, bool isVideo) async {
  //   final ImagePicker _picker = ImagePicker();
  //   context.loaderOverlay.show();
  //
  //   XFile? pickedFile;
  //
  //   if (isVideo) {
  //     pickedFile = await _picker.pickVideo(source: source);
  //   } else {
  //     pickedFile = await _picker.pickImage(source: source);
  //   }
  //
  //   if (pickedFile == null) {
  //     context.loaderOverlay.hide();
  //     print('No media selected');
  //     return;
  //   }
  //
  //   File file = File(pickedFile.path);
  //
  //   // Jika media adalah video, kompresi sebelum upload
  //   if (isVideo) {
  //     print('Original video size: ${file.lengthSync()} bytes');
  //
  //     try {
  //       // Kompresi video
  //       MediaInfo? compressedVideo = await VideoCompress.compressVideo(
  //         file.path,
  //         quality: VideoQuality.MediumQuality, // Pilih kualitas kompresi
  //         deleteOrigin: false, // Jangan hapus video asli
  //       );
  //
  //       if (compressedVideo == null || compressedVideo.file == null) {
  //         context.loaderOverlay.hide();
  //         print('Failed to compress video');
  //         return;
  //       }
  //
  //       File compressedFile = compressedVideo.file!;
  //       print('Compressed video size: ${compressedFile.lengthSync()} bytes');
  //
  //       // Nama file untuk video yang dikompresi
  //       String fileName = 'stories/videos/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
  //
  //       // Unggah video yang sudah dikompresi
  //       UploadTask uploadTask = FirebaseStorage.instance
  //           .ref()
  //           .child(fileName)
  //           .putFile(compressedFile);
  //
  //       TaskSnapshot taskSnapshot = await uploadTask;
  //       String downloadUrl = await taskSnapshot.ref.getDownloadURL();
  //
  //       DateTime localTimestamp = DateTime.now();
  //       await FirebaseFirestore.instance.runTransaction((transaction) async {
  //         transaction.set(
  //           FirebaseFirestore.instance.collection('stories').doc(),
  //           {
  //             'url': downloadUrl,
  //             'type': 'video', // Tambahkan informasi jenis file (video)
  //             'serverTimestamp': FieldValue.serverTimestamp(),
  //             'localTimestamp': localTimestamp,
  //             'uid': currentUser.currentUser!.uid,
  //             'timestamp': localTimestamp,
  //           },
  //         );
  //
  //         transaction.update(
  //           FirebaseFirestore.instance
  //               .collection('users')
  //               .doc(currentUser.currentUser!.uid),
  //           {
  //             'hasUploadedStory': true,
  //             'latestStoryUrl': downloadUrl,
  //           },
  //         );
  //       });
  //
  //       context.loaderOverlay.hide();
  //       print('Video upload successful: $downloadUrl');
  //     } catch (e) {
  //       context.loaderOverlay.hide();
  //       _alertService.showToast(
  //         text: e.toString(),
  //         icon: Icons.error,
  //         color: Colors.red,
  //       );
  //       print('Failed to upload video: $e');
  //     }
  //
  //   } else {
  //     // Proses kompresi untuk gambar
  //     print('File size before compression: ${file.lengthSync()} bytes');
  //
  //     final img.Image? image = img.decodeImage(await file.readAsBytes());
  //     if (image == null) {
  //       context.loaderOverlay.hide();
  //       print('Failed to decode image');
  //       return;
  //     }
  //
  //     final compressedImage = img.encodeJpg(image, quality: 50);
  //     final String compressedFilePath = '${file.path}.jpg';
  //     await File(compressedFilePath).writeAsBytes(compressedImage);
  //     print('File size after compression: ${compressedImage.length} bytes');
  //
  //     // Nama file untuk gambar
  //     String fileName = 'stories/images/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
  //
  //     try {
  //       UploadTask uploadTask = FirebaseStorage.instance
  //           .ref()
  //           .child(fileName)
  //           .putFile(File(compressedFilePath));  // Unggah file gambar yang telah dikompresi
  //
  //       TaskSnapshot taskSnapshot = await uploadTask;
  //       String downloadUrl = await taskSnapshot.ref.getDownloadURL();
  //
  //       DateTime localTimestamp = DateTime.now();
  //       await FirebaseFirestore.instance.runTransaction((transaction) async {
  //         transaction.set(
  //           FirebaseFirestore.instance.collection('stories').doc(),
  //           {
  //             'url': downloadUrl,
  //             'type': 'image', // Tambahkan informasi jenis file (gambar)
  //             'serverTimestamp': FieldValue.serverTimestamp(),
  //             'localTimestamp': localTimestamp,
  //             'uid': currentUser.currentUser!.uid,
  //             'timestamp': localTimestamp,
  //           },
  //         );
  //
  //         transaction.update(
  //           FirebaseFirestore.instance
  //               .collection('users')
  //               .doc(currentUser.currentUser!.uid),
  //           {
  //             'hasUploadedStory': true,
  //             'latestStoryUrl': downloadUrl,
  //           },
  //         );
  //       });
  //
  //       context.loaderOverlay.hide();
  //       print('Image upload successful: $downloadUrl');
  //     } catch (e) {
  //       context.loaderOverlay.hide();
  //       _alertService.showToast(
  //         text: e.toString(),
  //         icon: Icons.error,
  //         color: Colors.red,
  //       );
  //       print('Failed to upload image: $e');
  //     }
  //   }
  // }

  // Future<void> _pickAndUploadMedia(ImageSource source) async {
  //   final ImagePicker _picker = ImagePicker();
  //   final XFile? pickedFile = await _picker.pickImage(source: source);
  //
  //   if (pickedFile == null) return;
  //
  //   try {
  //     final File file = File(pickedFile.path);
  //
  //     final File? compressedFile = await _compressImage(file);
  //
  //     if (compressedFile == null) throw 'Gagal mengkompres gambar';
  //
  //     print('Mengunggah gambar...');
  //
  //     String fileName = 'stories/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
  //     final uploadTask = FirebaseStorage.instance.ref(fileName).putFile(compressedFile);
  //
  //     final snapshot = await uploadTask;
  //     final downloadUrl = await snapshot.ref.getDownloadURL();
  //
  //     DateTime localTimestamp = DateTime.now();
  //
  //     await FirebaseFirestore.instance.runTransaction((transaction) async {
  //       transaction.set(FirebaseFirestore.instance.collection('stories').doc(), {
  //         'url': downloadUrl,
  //         'serverTimestamp': FieldValue.serverTimestamp(),
  //         'localTimestamp': localTimestamp,
  //         'uid': currentUser.currentUser!.uid,
  //         'timestamp': localTimestamp,
  //       });
  //
  //       transaction.update(FirebaseFirestore.instance.collection('users').doc(currentUser.currentUser!.uid), {
  //         'hasUploadedStory': true,
  //         'latestStoryUrl': downloadUrl,
  //       });
  //     });
  //     context.loaderOverlay.hide();
  //     print('Upload sukses: $downloadUrl');
  //   } catch (e) {
  //     context.loaderOverlay.hide();
  //     _alertService.showToast(
  //       text: 'Select at least 2 users to create a group',
  //       icon: Icons.error,
  //       color: Colors.red,
  //     );
  //     print('Gagal mengunggah: $e');
  //   } finally {
  //     context.loaderOverlay.hide();
  //   }
  // }

  // Future<File?> _compressImage(File file) async {
  //   final compressedImage = await FlutterImageCompress.compressAndGetFile(
  //     file.absolute.path,
  //     '${file.path}_compressed.jpg',
  //     quality: 50,
  //   );
  //
  //   if (compressedImage != null) {
  //     return File(compressedImage.path);
  //   } else {
  //     return null;
  //   }
  // }

  Future<List<Map<String, dynamic>>> getUserStory(String uid) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('stories')
          .where('uid', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> stories = querySnapshot.docs
          .map((doc) => {
                'url': doc['url'],
                'timestamp': doc['timestamp'],
              })
          .toList();

      return stories;
    } catch (e) {
      print('Failed to fetch stories: $e');
      return [];
    }
  }

  Future<UserProfile> _getUserProfile(String uid) async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

      final docSnapshot = await userDoc.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return UserProfile.fromMap(data);
      } else {
        throw Exception('User profile not found');
      }
    } catch (e) {
      print('Error getting user profile: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: LayoutBuilder(
          builder: (context, constraints) {
            return Text(
              'Updates',
              style: TextStyle(
                color: Colors.white,
                fontSize: constraints.maxWidth * 0.08,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: LoaderOverlay(
        switchOutCurve: Curves.linear,
        switchInCurve: Curves.easeIn,
        useDefaultLoading: true,
        child: Container(
          padding:
              EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Status',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        // await _requestPermission().whenComplete(() async {
                        //   await _pickAndUploadMedia(ImageSource.camera);
                        // });
                        _chooseStory(context);
                      },
                      icon: Icon(Icons.camera_alt),
                      iconSize: MediaQuery.of(context).size.width * 0.06,
                    ),
                  ],
                ),
              ),
              Expanded(child: _storyList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _storyList() {
    return StreamBuilder(
      stream: _databaseService.getUserProfiles(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container();
        }

        if (snapshot.hasData && snapshot.data != null) {
          final users = snapshot.data!.docs;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: users.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: () async {
                    var userProfile =
                        await _getUserProfile(currentUser.currentUser!.uid);

                    if (userProfile.hasUploadedStory) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoryViewerScreen(
                            userProfile: userProfile,
                            requestPermission: _requestPermission,
                            pickAndUploadMedia: (ImageSource source) => _pickAndUploadMedia(source, false),
                            // pickAndUploadMedia: _pickAndUploadMedia,
                          ),
                        ),
                      );
                    } else {
                      if (!_isRequestingPermission) {
                        await _requestPermission().then((_) async {
                          // await _pickAndUploadMedia(ImageSource.camera);
                          _chooseStory(context);
                        });
                      }
                    }
                  },
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('uid', isEqualTo: currentUser.currentUser!.uid)
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.connectionState == ConnectionState.waiting) {
                        return Container();
                      }

                      var userProfile = UserProfile.fromMap(
                          snapshot.data!.docs[0].data()
                              as Map<String, dynamic>);
                      bool hasUploadedStory = userProfile.hasUploadedStory;
                      double screenWidth = MediaQuery.of(context).size.width;
                      double screenHeight = MediaQuery.of(context).size.height;
                      double avatarSize = screenWidth * 0.15;
                      double iconSize = screenWidth * 0.04;
                      double margin = screenWidth * 0.05;

                      return Container(
                        margin: EdgeInsets.only(left: margin),
                        padding: EdgeInsets.all(screenWidth * 0.01),
                        width: screenWidth * 0.2,
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: avatarSize,
                                  height: avatarSize,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: hasUploadedStory
                                          ? Colors.grey
                                          : Colors.white,
                                      width: 2,
                                    ),
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: NetworkImage(userProfile.pfpURL!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: avatarSize * 0.68,
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(1),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: iconSize,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'My Story',
                              style: TextStyle(fontSize: screenWidth * 0.03),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              } else {
                UserProfile user = users[index - 1].data();
                return GestureDetector(
                  onTap: () async {
                    final storyData = await getUserStory(user.uid!);
                    if (storyData.isNotEmpty) {
                      final List<String> storyUrls = storyData
                          .map((story) => story['url'] as String)
                          .toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OtherUser(
                            userProfile: user,
                            storyData: storyUrls,
                          ),
                        ),
                      );
                    } else {
                      print('No story data available');
                    }
                    setState(() {
                      clickedUIDs.add(user.uid!);
                    });
                  },
                  child: FutureBuilder<List<dynamic>>(
                    future: getUserStory(user.uid!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting ||
                          snapshot.hasError) {
                        return Container();
                      } else if (snapshot.hasData &&
                          snapshot.data!.isNotEmpty) {
                        double screenWidth = MediaQuery.of(context).size.width;
                        double containerSize = screenWidth * 0.16;

                        return Container(
                          padding: EdgeInsets.all(screenWidth * 0.01),
                          width: containerSize,
                          child: Column(
                            children: [
                              Container(
                                width: containerSize,
                                height: containerSize,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: clickedUIDs.contains(user.uid!)
                                        ? Colors.grey
                                        : Colors.blue,
                                    width: screenWidth * 0.005,
                                  ),
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage(user.pfpURL ?? ''),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenWidth * 0.01),
                              Text(
                                user.name ?? '-',
                                style: TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: screenWidth * 0.03,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Container();
                      }
                    },
                  ),
                );
              }
            },
          );
        }
        return Container();
      },
    );
  }
}
