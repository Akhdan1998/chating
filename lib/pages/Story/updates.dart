import 'dart:io';
import 'package:chating/pages/Story/storyView_page.dart';
import 'package:chating/pages/Story/otherUserStory_page.dart';
import 'package:chating/widgets/utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:story_view/controller/story_controller.dart';
import '../../models/user_profile.dart';
import '../../service/alert_service.dart';
import '../../service/auth_service.dart';
import '../../service/database_service.dart';
import '../../service/navigation_service.dart';
import 'package:image/image.dart' as img;

import '../../widgets/camera.dart';

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

    if (isVideo) {
      print('Uploading video: ${file.path}');

      String fileName =
          'stories/videos/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';

      try {
        UploadTask uploadTask =
            FirebaseStorage.instance.ref().child(fileName).putFile(file);

        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        DateTime localTimestamp = DateTime.now();
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.set(
            FirebaseFirestore.instance.collection('stories').doc(),
            {
              'url': downloadUrl,
              'type': 'video',
              'uid': currentUser.currentUser!.uid,
              'timestamp': localTimestamp,
              // 'serverTimestamp': FieldValue.serverTimestamp(),
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

      String fileName =
          'stories/images/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';

      try {
        UploadTask uploadTask = FirebaseStorage.instance
            .ref()
            .child(fileName)
            .putFile(File(compressedFilePath));

        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        DateTime localTimestamp = DateTime.now();
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.set(
            FirebaseFirestore.instance.collection('stories').doc(),
            {
              'url': downloadUrl,
              'type': 'image',
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
        return Column(
          children: [
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: Colors.green,
              ),
              title: Text(
                'take_photo'.tr(),
                style: StyleText(),
              ),
              onTap: () async {
                Navigator.pop(context);
                context.loaderOverlay.show();
                await _pickAndUploadMedia(ImageSource.camera, false);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: Colors.redAccent,
              ),
              title: Text(
                'choose_photo'.tr(),
                style: StyleText(),
              ),
              onTap: () async {
                Navigator.pop(context);
                context.loaderOverlay.show();
                await _pickAndUploadMedia(ImageSource.gallery, false);
              },
            ),
          ],
        );
      },
    );
  }

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

  // Future<bool> _hasViewedStory(String userId, String currentUserId) async {
  //   final storyViewDoc =
  //       FirebaseFirestore.instance.collection('storyViews').doc(userId);
  //   final storyViewSnapshot = await storyViewDoc.get();
  //   final existingViewers = storyViewSnapshot.data()?['viewers'] ?? [];
  //   return existingViewers.any((viewer) => viewer['uid'] == currentUserId);
  // }

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
              'update'.tr(),
              style: StyleText(
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
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'status'.tr(),
                        style: StyleText(
                          fontSize: MediaQuery.of(context).size.width * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        // _chooseStory(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CameraScreen(),
                          ),
                        );
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
                          builder: (context) => CameraScreen(),
                        ),
                      );
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => StoryViewerScreen(
                      //       userProfile: userProfile,
                      //       requestPermission: _requestPermission,
                      //       pickAndUploadMedia: (ImageSource source) =>
                      //           _pickAndUploadMedia(source, false),
                      //     ),
                      //   ),
                      // );
                    } else {
                      if (!_isRequestingPermission) {
                        await _requestPermission().then((_) async {
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
                          snapshot.data!.docs[0].data() as Map<String, dynamic>);
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
                              'my_story'.tr(),
                              style: StyleText(fontSize: screenWidth * 0.03),
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
                    var userProfile =
                        await _getUserProfile(currentUser.currentUser!.uid);

                    final storyData = await getUserStory(user.uid!);
                    if (storyData.isNotEmpty) {
                      final List<String> storyUrls = storyData
                          .map((story) => story['url'] as String)
                          .toList();

                      final storyViewDoc = FirebaseFirestore.instance
                          .collection('storyViews')
                          .doc(user.uid!);

                      final storyViewSnapshot = await storyViewDoc.get();

                      final existingViewers =
                          storyViewSnapshot.data()?['viewers'] ?? [];
                      final hasViewed = existingViewers
                          .any((viewer) => viewer['uid'] == userProfile.uid);

                      if (!hasViewed) {
                        await storyViewDoc.set({
                          'viewers': FieldValue.arrayUnion([
                            {
                              'uid': userProfile.uid,
                              'name': userProfile.name,
                              'pfpUrl': userProfile.pfpURL,
                              'timestamp': DateTime.now(),
                            }
                          ]),
                          'totalViews': FieldValue.increment(1),
                        }, SetOptions(merge: true));
                      }

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
                                style: StyleText(
                                  fontSize: screenWidth * 0.03,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                // return GestureDetector(
                //   onTap: () async {
                //     var userProfile =
                //         await _getUserProfile(currentUser.currentUser!.uid);
                //
                //     final storyData = await getUserStory(user.uid!);
                //     if (storyData.isNotEmpty) {
                //       final List<String> storyUrls = storyData
                //           .map((story) => story['url'] as String)
                //           .toList();
                //
                //       final storyViewDoc = FirebaseFirestore.instance
                //           .collection('storyViews')
                //           .doc(user.uid!);
                //
                //       final storyViewSnapshot = await storyViewDoc.get();
                //       final existingViewers = storyViewSnapshot.data()!['viewers'] ?? [];
                //       final hasViewed = existingViewers.any((viewer) => viewer['uid'] == userProfile.uid);
                //
                //       if (!hasViewed) {
                //         await storyViewDoc.set({
                //           'viewers': FieldValue.arrayUnion([
                //             {
                //               'uid': userProfile.uid,
                //               'name': userProfile.name,
                //               'pfpUrl': userProfile.pfpURL,
                //               'timestamp': DateTime.now(),
                //             }
                //           ]),
                //           'totalViews': FieldValue.increment(1),
                //         }, SetOptions(merge: true));
                //       }
                //
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
                //
                //     setState(() {
                //       clickedUIDs.add(user.uid!);
                //     });
                //   },
                //   child: FutureBuilder<List<dynamic>>(
                //     future: getUserStory(user.uid!),
                //     builder: (context, storySnapshot) {
                //       if (storySnapshot.connectionState ==
                //               ConnectionState.waiting ||
                //           storySnapshot.hasError) {
                //         return Container();
                //       } else if (storySnapshot.hasData &&
                //           storySnapshot.data!.isNotEmpty) {
                //         double screenWidth = MediaQuery.of(context).size.width;
                //         double containerSize = screenWidth * 0.16;
                //
                //         return FutureBuilder<bool>(
                //           future: _hasViewedStory(
                //               user.uid!, currentUser.currentUser!.uid),
                //           builder: (context, hasViewedSnapshot) {
                //             if (hasViewedSnapshot.connectionState ==
                //                 ConnectionState.waiting) {
                //               return Container();
                //             }
                //
                //             return Container(
                //               padding: EdgeInsets.all(screenWidth * 0.01),
                //               width: containerSize,
                //               child: Column(
                //                 children: [
                //                   Container(
                //                     width: containerSize,
                //                     height: containerSize,
                //                     decoration: BoxDecoration(
                //                       border: Border.all(
                //                         color: clickedUIDs.contains(user.uid!)
                //                             ? Colors.grey
                //                             : Colors.blue,
                //                         width: screenWidth * 0.005,
                //                       ),
                //                       shape: BoxShape.circle,
                //                       image: DecorationImage(
                //                         image: NetworkImage(user.pfpURL ?? ''),
                //                         fit: BoxFit.cover,
                //                       ),
                //                     ),
                //                   ),
                //                   SizedBox(height: screenWidth * 0.01),
                //                   Text(
                //                     user.name ?? '-',
                //                     style: StyleText(
                //                       fontSize: screenWidth * 0.03,
                //                     ),
                //                     overflow: TextOverflow.ellipsis,
                //                   ),
                //                 ],
                //               ),
                //             );
                //           },
                //         );
                //       } else {
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