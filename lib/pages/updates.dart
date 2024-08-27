import 'dart:io';
import 'package:chating/pages/storyView_page.dart';
import 'package:chating/pages/otherUserStory_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:story_view/controller/story_controller.dart';
import '../models/user_profile.dart';
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

  // File? _originalFile;
  // File? _compressedFile;

  @override
  void initState() {
    super.initState();
    _navigationService = _getIt.get<NavigationService>();
    _databaseService = _getIt.get<DatabaseService>();
    _authService = _getIt.get<AuthService>();
  }

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  // Future<void> _requestPermission() async {
  //   if (await Permission.camera.request().isGranted &&
  //       await Permission.storage.request().isGranted) {
  //     // Permission granted, do nothing
  //   } else {
  //     // Handle permission denied
  //   }
  // }

  Future<void> _requestPermission() async {
    if (_isRequestingPermission) return;
    _isRequestingPermission = true;

    try {
      // Ganti dengan kode permintaan izin yang sebenarnya
      await Permission.camera.request();
    } finally {
      _isRequestingPermission = false;
    }
  }

  // Future<void> _pickAndUploadMedia(ImageSource source) async {
  //   final XFile? pickedFile = await _picker.pickImage(source: source);
  //   if (pickedFile != null) {
  //     File file = File(pickedFile.path);
  //     try {
  //       String fileName =
  //           'stories/${DateTime.now().millisecondsSinceEpoch.toString()}_${pickedFile.name}';
  //       UploadTask uploadTask =
  //       FirebaseStorage.instance.ref().child(fileName).putFile(file);
  //       TaskSnapshot taskSnapshot = await uploadTask;
  //       String downloadUrl = await taskSnapshot.ref.getDownloadURL();
  //
  //       DateTime localTimestamp = DateTime.now();
  //
  //       // Save the story data with both the server-side and local timestamps
  //       await FirebaseFirestore.instance.collection('stories').add({
  //         'url': downloadUrl,
  //         'serverTimestamp': FieldValue.serverTimestamp(),
  //         'localTimestamp': localTimestamp,
  //         'uid': currentUser.currentUser!.uid,
  //         'timestamp': localTimestamp, // Tambahkan field ini
  //       });
  //
  //       await FirebaseFirestore.instance
  //           .collection('users')
  //           .doc(currentUser.currentUser!.uid)
  //           .update({
  //         'hasUploadedStory': true,
  //         'latestStoryUrl': downloadUrl,
  //       });
  //
  //       print('Upload successful: $downloadUrl');
  //     } catch (e) {
  //       print('Failed to upload: $e');
  //     }
  //   }
  // }

  Future<void> _pickAndUploadMedia(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      print('Ukuran file sebelum dikompresi: ${file.lengthSync()} bytes');
      final img.Image? image = img.decodeImage(file.readAsBytesSync());
      if (image != null) {
        final compressedImage = img.encodeJpg(image, quality: 50);
        File compressedFile = File('${file.path}.jpg')
          ..writeAsBytesSync(compressedImage);
        print(
            'Ukuran gambar setelah kompresi: ${compressedImage.length} bytes');
        try {
          String fileName =
              'stories/${DateTime.now().millisecondsSinceEpoch.toString()}_${pickedFile.name}';
          UploadTask uploadTask = FirebaseStorage.instance
              .ref()
              .child(fileName)
              .putFile(compressedFile);
          TaskSnapshot taskSnapshot = await uploadTask;
          String downloadUrl = await taskSnapshot.ref.getDownloadURL();

          DateTime localTimestamp = DateTime.now();

          await FirebaseFirestore.instance.collection('stories').add({
            'url': downloadUrl,
            'serverTimestamp': FieldValue.serverTimestamp(),
            'localTimestamp': localTimestamp,
            'uid': currentUser.currentUser!.uid,
            'timestamp': localTimestamp, // Tambahkan field ini
          });

          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.currentUser!.uid)
              .update({
            'hasUploadedStory': true,
            'latestStoryUrl': downloadUrl,
          });

          print('Upload successful: $downloadUrl');
        } catch (e) {
          print('Failed to upload: $e');
        }
      } else {
        print('Failed to decode image');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getUserStory(String uid) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('stories')
          .where('uid', isEqualTo: uid)
          .orderBy('timestamp', descending: true) // Gunakan field 'timestamp'
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
      body: Container(
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
                      await _requestPermission().whenComplete(() async {
                        await _pickAndUploadMedia(ImageSource.camera);
                      });
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
                            pickAndUploadMedia: _pickAndUploadMedia,
                          ),
                        ),
                      );
                    } else {
                      if (!_isRequestingPermission) {
                        await _requestPermission().then((_) async {
                          await _pickAndUploadMedia(ImageSource.camera);
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

                      // Using MediaQuery to scale the UI based on screen size
                      double screenWidth = MediaQuery.of(context).size.width;
                      double screenHeight = MediaQuery.of(context).size.height;
                      double avatarSize =
                          screenWidth * 0.15; // Scale avatar size
                      double iconSize = screenWidth * 0.05; // Scale icon size
                      double margin = screenWidth * 0.05; // Scale margin

                      return Container(
                        margin: EdgeInsets.only(left: margin),
                        padding: EdgeInsets.all(screenWidth * 0.01),
                        // Scaled padding
                        width: screenWidth * 0.2,
                        // Scaled container width
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
                                  child: Icon(
                                    Icons.add_circle,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: iconSize,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            // Scaled space
                            Text(
                              'My Story',
                              style: TextStyle(
                                  fontSize:
                                      screenWidth * 0.03), // Scaled font size
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
                // return GestureDetector(
                //   onTap: () async {
                //     var userProfile =
                //     await _getUserProfile(currentUser.currentUser!.uid);
                //
                //     if (userProfile.hasUploadedStory) {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) => StoryViewerScreen(
                //             userProfile: userProfile,
                //             requestPermission: _requestPermission,
                //             pickAndUploadMedia: _pickAndUploadMedia,
                //           ),
                //         ),
                //       );
                //     } else {
                //       if (!_isRequestingPermission) {
                //         await _requestPermission().then((_) async {
                //           await _pickAndUploadMedia(ImageSource.camera);
                //         });
                //       }
                //     }
                //   },
                //   child: StreamBuilder(
                //     stream: FirebaseFirestore.instance
                //         .collection('users')
                //         .where('uid', isEqualTo: currentUser.currentUser!.uid)
                //         .snapshots(),
                //     builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                //       if (!snapshot.hasData ||
                //           snapshot.connectionState == ConnectionState.waiting) {
                //         return Container();
                //       }
                //
                //       var userProfile = UserProfile.fromMap(
                //           snapshot.data!.docs[0].data()
                //               as Map<String, dynamic>);
                //       bool hasUploadedStory = userProfile.hasUploadedStory;
                //
                //       return Container(
                //         margin: EdgeInsets.only(left: 20),
                //         padding: EdgeInsets.all(3),
                //         width: 80,
                //         child: Column(
                //           children: [
                //             Stack(
                //               children: [
                //                 Container(
                //                   width: 60,
                //                   height: 60,
                //                   decoration: BoxDecoration(
                //                     border: Border.all(
                //                       color: hasUploadedStory
                //                           ? Colors.grey
                //                           : Colors.white,
                //                       width: 2,
                //                     ),
                //                     shape: BoxShape.circle,
                //                     image: DecorationImage(
                //                       image: NetworkImage(userProfile.pfpURL!),
                //                       fit: BoxFit.cover,
                //                     ),
                //                   ),
                //                 ),
                //                 Positioned(
                //                   top: 41,
                //                   right: 0,
                //                   bottom: 0,
                //                   left: 40,
                //                   child: Icon(
                //                     Icons.add_circle,
                //                     color:
                //                         Theme.of(context).colorScheme.primary,
                //                     size: 20,
                //                   ),
                //                 ),
                //               ],
                //             ),
                //             SizedBox(height: 5),
                //             Text(
                //               'My Story',
                //               style: TextStyle(fontSize: 12),
                //             ),
                //           ],
                //         ),
                //       );
                //     },
                //   ),
                // );
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
                              // Responsive spacing
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

                // UserProfile user = users[index - 1].data();
                // return GestureDetector(
                //   onTap: () async {
                //     final storyData = await getUserStory(user.uid!);
                //     if (storyData.isNotEmpty) {
                //       final List<String> storyUrls = storyData
                //           .map((story) => story['url'] as String)
                //           .toList();
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) => OtherUser(
                //             userProfile: user,
                //             storyData: storyUrls,
                //           ),
                //         ),
                //       );
                //     } else {
                //       print('No story data available');
                //     }
                //     setState(() {
                //       clickedUIDs.add(user.uid!);
                //     });
                //   },
                //   child: FutureBuilder<List<dynamic>>(
                //     future: getUserStory(user.uid!),
                //     builder: (context, snapshot) {
                //       if (snapshot.connectionState == ConnectionState.waiting) {
                //         return Container();
                //       } else if (snapshot.hasError) {
                //         return Container();
                //       } else if (snapshot.hasData &&
                //           snapshot.data!.isNotEmpty) {
                //         return Container(
                //           padding: EdgeInsets.all(3),
                //           width: 66,
                //           child: Column(
                //             children: [
                //               Container(
                //                 width: 60,
                //                 height: 60,
                //                 decoration: BoxDecoration(
                //                   border: Border.all(
                //                     color: clickedUIDs.contains(user.uid!)
                //                         ? Colors.grey
                //                         : Colors.blue,
                //                     width: 2,
                //                   ),
                //                   shape: BoxShape.circle,
                //                   image: DecorationImage(
                //                     image: NetworkImage(user.pfpURL ?? ''),
                //                     fit: BoxFit.cover,
                //                   ),
                //                 ),
                //               ),
                //               SizedBox(height: 5),
                //               Text(
                //                 user.name ?? '-',
                //                 style: TextStyle(
                //                   overflow: TextOverflow.ellipsis,
                //                   fontSize: 12,
                //                 ),
                //               ),
                //             ],
                //           ),
                //         );
                //       } else {
                //         // Jika user belum membuat story, tampilkan Container
                //         return Container();
                //       }
                //     },
                //   ),
                // );
              }
            },
          );
        }
        return Container();
      },
    );
  }
}
