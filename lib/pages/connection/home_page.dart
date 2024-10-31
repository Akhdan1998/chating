import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:chating/models/user_profile.dart';
import 'package:chating/pages/connection/chat_page.dart';
import 'package:chating/service/auth_service.dart';
import 'package:chating/service/database_service.dart';
import 'package:chating/service/navigation_service.dart';
import 'package:chating/widgets/chat_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../consts.dart';
import '../../models/group.dart';
import '../../service/alert_service.dart';
import '../../service/media_service.dart';
import '../../widgets/textfield.dart';
import 'group_page.dart';
import 'package:image/image.dart' as img;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  late DatabaseService _databaseService;
  late MediaService _mediaService;
  List<UserProfile> _users = [];
  final List<int> selectedUserIndexes = [];
  final TextEditingController groupController = TextEditingController();
  List<Map<String, dynamic>> _chatListData = [];
  File? selectedImage;
  final currentuser = FirebaseAuth.instance.currentUser;
  UserProfile? _userProfile;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late AudioPlayer audioPlayer;
  final ImagePicker _picker = ImagePicker();
  final currentUser = FirebaseAuth.instance;

  Future<void> _pickAndUploadMedia(ImageSource source, bool isVideo) async {
    final ImagePicker _picker = ImagePicker();

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

  //kompress video
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

  Future<void> _requestPermission() async {
    if (await Permission.camera.request().isGranted && await Permission.storage.request().isGranted) {
      // Permission granted, do nothing
    } else {
      // Handle permission denied
    }
  }

  Future<void> _loadUserProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userProfileString = prefs.getString('userProfile');
    if (userProfileString != null) {
      final Map<String, dynamic> userProfileMap = jsonDecode(userProfileString);
      setState(() {
        _userProfile = UserProfile.fromMap(userProfileMap);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _databaseService.online(currentuser!.uid);
  }

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
    _databaseService = _getIt.get<DatabaseService>();
    _mediaService = _getIt.get<MediaService>();
    WidgetsBinding.instance.addObserver(this);
    _databaseService.online(currentuser!.uid);
    _loadUserProfileData();
  }

  Future<void> createGroup(
      List<UserProfile> members, String groupName, String groupImageURL) async {
    try {
      String creatorUserID = _authService.user!.uid;

      Group newGroup = Group(
        id: '',
        name: groupName,
        messagesGroup: [],
        imageUrl: groupImageURL,
        members: [
          ...members.map((user) => user.uid!).toList(),
          creatorUserID,
        ],
        createdAt: DateTime.now(),
        latestMessageSentAt: Timestamp.now(),
      );

      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('groups')
          .add(newGroup.toMap());

      await docRef.update({
        'id': docRef.id,
      });

      _alertService.showToast(
        text: 'Group created successfully!',
        icon: Icons.check,
        color: Colors.green,
      );

      _addGroupToChatList(
        docRef.id,
        groupName,
        newGroup.members,
        groupImageURL,
      );

      // _navigationService.push(
      //   MaterialPageRoute(builder: (context) {
      //     return GroupPage(
      //       group: newGroup,
      //       users: members,
      //     );
      //   }),
      // );
    } catch (e) {
      _alertService.showToast(
        text: 'Failed to create group!',
        icon: Icons.error,
        color: Colors.red,
      );
    } finally {
      groupController.clear();
      selectedUserIndexes.clear();
      selectedImage = null;
      // Navigator.pop(context);
    }
  }

  void _addGroupToChatList(
      String groupId, String groupName, List<String> members, String imageUrl) {
    setState(() {
      _chatListData.add({
        'id': groupId,
        'name': groupName,
        'members': members,
        'imageUrl': imageUrl,
        'lastMessage': '',
        'lastMessageTime': DateTime.now(),
        'createdAt': DateTime.now(),
      });
    });
  }

  void _showModalBottomSheet(BuildContext context) async {
    bool _isLoading = false;
    var userProfiles = await _databaseService.getUserProfiles().first;
    setState(() {
      _users = userProfiles.docs
          .map((doc) => doc.data() as UserProfile)
          .toList();
    });
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            groupController.clear();
            selectedUserIndexes.clear();
            selectedImage = null;
            return true;
          },
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                padding: MediaQuery.of(context).viewInsets,
                child: Container(
                  height: 500,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Add members',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  File? file = await _mediaService
                                      .getImageFromGalleryImage();
                                  if (file != null) {
                                    setState(() {
                                      selectedImage = file;
                                    });
                                  } else {
                                    setState(() {
                                      _alertService.showToast(
                                        text: 'No image selected!',
                                        icon: Icons.warning,
                                        color: Colors.orange,
                                      );
                                    });
                                  }
                                },
                                child: CircleAvatar(
                                  radius:
                                      MediaQuery.of(context).size.width * 0.10,
                                  backgroundImage: selectedImage != null
                                      ? FileImage(selectedImage!)
                                      : NetworkImage(PLACEHOLDER_PFP)
                                          as ImageProvider,
                                ),
                              ),
                              Positioned(
                                child: Container(
                                  padding: EdgeInsets.only(top: 58, left: 58),
                                  child: Icon(Icons.add_circle,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 25),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: TextFieldCustom(
                              controller: groupController,
                              onSaved: (value) {
                                groupController.text = value!;
                              },
                              validationRegEx: NAME_VALIDATION_REGEX,
                              height: MediaQuery.of(context).size.height * 0.1,
                              hintText: 'Group Name (optional)',
                              obscureText: false,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            UserProfile user = _users[index];
                            bool isSelected = selectedUserIndexes.contains(index);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedUserIndexes.remove(index);
                                  } else {
                                    selectedUserIndexes.add(index);
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.only(top: 10, bottom: 10),
                                color: Colors.transparent,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Colors.white,
                                        border: Border.all(
                                          width: 1,
                                          color: Colors.grey,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Container(
                                      width:
                                          MediaQuery.sizeOf(context).width - 70,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(user.name ?? '-'),
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                image: NetworkImage(user.pfpURL!),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 10),
                      _createGroupButton(setState, _isLoading, context),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<List<Contact>> _fetchContacts() async {
    // Pastikan izin telah diberikan sebelum mengambil kontak
    PermissionStatus status = await Permission.contacts.request();
    if (status.isGranted) {
      return await ContactsService.getContacts().then((contacts) => contacts.toList());
    } else {
      return [];
    }
  }

  void _bottomSheetContach(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                height: 850,
                padding: EdgeInsets.only(top: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'New Chat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<List<Contact>>(
                        future: _fetchContacts(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Terjadi kesalahan'));
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(child: Text('Tidak ada kontak yang ditemukan'));
                          } else {
                            return ListView.builder(
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                final contact = snapshot.data![index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(contact.initials()),
                                  ),
                                  title: Text(contact.displayName ?? 'Tidak ada nama'),
                                  subtitle: Text(
                                    contact.phones!.isNotEmpty
                                        ? contact.phones!.first.value ?? ''
                                        : '',
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 15,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: MediaQuery.sizeOf(context).width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      showMenu(
                        context: context,
                        position: RelativeRect.fromLTRB(0, 0, 0, 0),
                        items: [
                          PopupMenuItem(
                            child: GestureDetector(
                              onTap: () async {
                                Navigator.pop(context);
                                // var userProfiles = await _databaseService.getUserProfiles().first;
                                // setState(() {
                                //   _users = userProfiles.docs
                                //       .map((doc) => doc.data() as UserProfile)
                                //       .toList();
                                // });
                                _showModalBottomSheet(context);
                              },
                              child: Container(
                                color: Colors.transparent,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('New Group'),
                                    SizedBox(width: 20),
                                    Icon(
                                      Icons.group,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    child: Icon(
                      Icons.more_horiz,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          await _requestPermission().whenComplete(() async {
                            // await _pickAndUploadMedia(ImageSource.camera);
                            _chooseStory(context);
                          });
                        },
                        icon: Icon(
                          Icons.photo_camera,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _bottomSheetContach(context);
                        },
                        icon: Icon(
                          Icons.add_circle,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              'Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        toolbarHeight: 100,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _buildUI(),
    );
  }

  Widget _createGroupButton(
      void Function(void Function()) setState, bool isLoading, BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: MaterialButton(
        color: Theme.of(context).colorScheme.primary,
        onPressed: () async {
          setState(() {
            isLoading = true;
          });

          if (selectedUserIndexes.length < 2) {
            _alertService.showToast(
              text: 'Select at least 2 users to create a group',
              icon: Icons.warning,
              color: Colors.orange,
            );
            setState(() {
              isLoading = false;
            });
            return;
          }

          if (selectedImage == null) {
            _alertService.showToast(
              text: 'Select an image for the group',
              icon: Icons.warning,
              color: Colors.orange,
            );
            setState(() {
              isLoading = false;
            });
            return;
          }

          if (groupController.text.trim().isEmpty) {
            _alertService.showToast(
              text: 'Enter a name for the group',
              icon: Icons.warning,
              color: Colors.orange,
            );
            setState(() {
              isLoading = false;
            });
            return;
          }

          try {
            firebase_storage.Reference ref = firebase_storage
                .FirebaseStorage.instance
                .ref()
                .child('groupProfile')
                .child('${DateTime.now().toIso8601String()}');
            firebase_storage.UploadTask uploadTask =
                ref.putFile(selectedImage!);
            await uploadTask.whenComplete(() async {
              String imageUrl = await ref.getDownloadURL();
              await createGroup(
                selectedUserIndexes.map((index) => _users[index]).toList(),
                groupController.text.trim(),
                imageUrl,
              ).whenComplete(() {
                Navigator.pop(context);
                setState(() {
                  isLoading = false;
                });
              });
            });
          } catch (e) {
            print('Error uploading image: $e');
            _alertService.showToast(
              text: 'Failed to upload image!',
              icon: Icons.error,
              color: Colors.red,
            );
            setState(() {
              isLoading = false;
            });
          }
        },
        child: (isLoading == true)
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Create Group',
                style: TextStyle(color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildUI() {
    return SafeArea(
      child: LoaderOverlay(
        switchOutCurve: Curves.linear,
        switchInCurve: Curves.easeIn,
        useDefaultLoading: true,
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.only(left: 10, right: 10),
          child: _chatListAndGroups()
        ),
      ),
    );
  }

  Widget _chatListAndGroups() {
    if (_authService.user == null) {
      return Center(
        child: Text(
          "The user is not authenticated or the user collection is not initialized. Please log out and log back in.",
          textAlign: TextAlign.center,
        ),
      );
    }
    return StreamBuilder(
      stream: CombineLatestStream.list([
        _databaseService.getUserProfiles(),
        _databaseService.getChatGroups(),
      ]),
      builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
        if (snapshot.hasError) {
          return Container();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final userSnapshot = snapshot.data![0];
          final groupSnapshot = snapshot.data![1];

          if (userSnapshot.docs == null || groupSnapshot.docs == null) {
            return Center(
              child: Text('No data available'),
            );
          }

          final users = snapshot.data![0].docs
              .map((doc) => doc.data() as UserProfile)
              .toList();
          final chatGroups = snapshot.data![1].docs
              .map((doc) => Group.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

          final combinedList = [
            ...users.map((user) => {'type': 'user', 'data': user}),
            ...chatGroups.map((group) => {'type': 'group', 'data': group}),
          ];

          combinedList.sort((a, b) {
            var aTimestamp = (a['type'] == 'group')
                ? ((a['data'] as Group).latestMessageSentAt ?? Timestamp.now())
                : Timestamp.now();
            var bTimestamp = (b['type'] == 'group')
                ? ((b['data'] as Group).latestMessageSentAt ?? Timestamp.now())
                : Timestamp.now();

            return bTimestamp.compareTo(aTimestamp);
          });
          return ListView.separated(
            itemCount: combinedList.length,
            separatorBuilder: (context, index) => Divider(
              height: 0,
              color: Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              var item = combinedList[index];
              if (item['type'] == 'user') {
                UserProfile user = item['data'] as UserProfile;
                return ChatTile(
                  userProfile: user,
                  onTap: () async {
                    final chatExists = await _databaseService.checkChatExist(
                      _authService.user!.uid,
                      user.uid!,
                    );
                    if (!chatExists) {
                      await _databaseService.createNewChat(
                        _authService.user!.uid,
                        user.uid!,
                      );
                    }
                    _navigationService.push(
                      MaterialPageRoute(builder: (context) {
                        return ChatPage(
                          chatUser: user,
                        );
                      }),
                    );
                  },
                  onLongPress: () {
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: '',
                      transitionDuration: Duration(milliseconds: 300),
                      pageBuilder: (context, anim1, anim2) {
                        return AlertDialog(
                          actionsPadding: EdgeInsets.only(top: 1, bottom: 5, right: 10),
                          title: Text(
                            'Delete chat with ${user.name}',
                            style: TextStyle(fontSize: 15),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _alertService.showToast(
                                  text: 'All messages with ${user.name} were successfully deleted!',
                                  icon: Icons.info,
                                  color: Colors.red,
                                );
                              },
                              child: Text(
                                'Yes',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      transitionBuilder:
                          (context, anim1, anim2, child) {
                        return Transform.scale(
                          scale: anim1.value,
                          child: child,
                        );
                      },
                    );
                  },
                );
              } else if (item['type'] == 'group') {
                Group group = item['data'] as Group;

                if (!group.members.contains(_authService.user!.uid)) {
                  return Container();
                }

                List<String> memberNames = group.members.map((memberId) {
                  final user = users.firstWhere(
                        (user) => user.uid == memberId,
                    orElse: () => UserProfile(
                      uid: memberId,
                      name: 'You',
                    ),
                  );
                  return user.name ?? 'You';
                }).toList();

                String memberNamesStr = memberNames.join(', ');
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: group.imageUrl.isNotEmpty
                        ? NetworkImage(group.imageUrl)
                        : NetworkImage(PLACEHOLDER_PFP),
                  ),
                  title: Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    memberNamesStr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w100,
                    ),
                  ),
                  onTap: () {
                    _navigationService.push(
                      MaterialPageRoute(builder: (context) {
                        return GroupPage(
                          group: group,
                          userProfiles: users,
                        );
                      }),
                    );
                  },
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          actionsPadding: EdgeInsets.only(top: 1, bottom: 5, right: 10),
                          title: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Do you want to exit the group "${group.name}"?',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 15),
                              ),
                              SizedBox(height: 5),
                              Container(
                                padding: EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.blueGrey.shade100,
                                ),
                                child: Text(
                                  'Only group admins will be notified that you leave the group.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins().copyWith(
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await _databaseService.leaveGroup(group.id, _authService.user!.uid);
                                Navigator.pop(context);
                                _alertService.showToast(
                                  text: 'You have left the group "${group.name}"',
                                  icon: Icons.info,
                                  color: Colors.orange,
                                );
                              },
                              child: Text(
                                'Yes',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              }
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          );
        }
        return Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }

  Widget _chatList() {
    return StreamBuilder(
      stream: _databaseService.getUserProfiles(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container();
        }

        if (snapshot.hasData && snapshot.data != null) {
          final users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              UserProfile user = users[index].data();
              return ChatTile(
                userProfile: user,
                onTap: () async {
                  final chatExists = await _databaseService.checkChatExist(
                    _authService.user!.uid,
                    user.uid!,
                  );
                  if (!chatExists) {
                    await _databaseService.createNewChat(
                      _authService.user!.uid,
                      user.uid!,
                    );
                  }
                  setState(() {
                    if (!_users.contains(user)) {
                      _users.add(user);
                    }
                    // selectedUser = user;
                  });
                  _navigationService.push(
                    MaterialPageRoute(builder: (context) {
                      return ChatPage(
                        chatUser: user,
                      );
                    }),
                  );
                },
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        actionsPadding: EdgeInsets.only(top: 1, bottom: 5, right: 10),
                        title: Text(
                          'Delete chat with ${user.name}',
                          style: TextStyle(fontSize: 15),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.redAccent,
                                // fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _alertService.showToast(
                                text:
                                'All messages with ${user.name} were successfully deleted!',
                                icon: Icons.info,
                                color: Colors.red,
                              );
                            },
                            child: Text(
                              'Yes',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        }
        return Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}