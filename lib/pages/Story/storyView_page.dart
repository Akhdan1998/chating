// import 'package:chating/utils.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get_it/get_it.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'package:story_view/story_view.dart';
//
// import '../../models/user_profile.dart';
// import '../../service/alert_service.dart';
//
// class StoryViewerScreen extends StatefulWidget {
//   final UserProfile userProfile;
//   final Future<void> Function() requestPermission;
//   final Future<void> Function(ImageSource) pickAndUploadMedia;
//
//   StoryViewerScreen({
//     required this.userProfile,
//     required this.requestPermission,
//     required this.pickAndUploadMedia,
//   });
//
//   @override
//   _StoryViewerScreenState createState() => _StoryViewerScreenState();
// }
//
// class _StoryViewerScreenState extends State<StoryViewerScreen> {
//   late StoryController _storyController;
//   final GetIt _getIt = GetIt.instance;
//   late AlertService _alertService;
//   String _timestamp = '';
//   List<Map<String, dynamic>> _seenStories = [];
//   bool play = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _storyController = StoryController();
//     _alertService = _getIt.get<AlertService>();
//     _loadStoryData();
//     _deleteExpiredStories();
//     _loadSeenStories();
//   }
//
//   @override
//   void dispose() {
//     _storyController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadStoryData() async {
//     try {
//       final storyData = await getUserStory(widget.userProfile.uid!);
//       if (storyData.isNotEmpty) {
//         final timestamp = storyData[0]['timestamp'] as Timestamp?;
//         final dateTime = timestamp?.toDate();
//
//         if (dateTime != null &&
//             DateTime.now().difference(dateTime).inHours >= 24) {
//           await _deleteExpiredStories();
//           setState(() {
//             _timestamp = 'Story expired';
//           });
//         } else {
//           setState(() {
//             _timestamp = dateTime != null
//                 ? DateFormat('HH:mm, dd MMM yyyy').format(dateTime)
//                 : '-';
//           });
//         }
//       } else {
//         setState(() {
//           _timestamp = 'No timestamp available';
//         });
//       }
//     } catch (e) {
//       print('Error loading story data: $e');
//       setState(() {
//         _timestamp = 'Error loading time';
//       });
//     }
//   }
//
//   Future<void> _deleteStory(String storyId) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('stories')
//           .doc(storyId)
//           .delete();
//       _alertService.showToast(
//         text: 'story_delete'.tr(),
//         icon: Icons.check,
//         color: Colors.green,
//       );
//       setState(() {});
//     } catch (e) {
//       _alertService.showToast(
//         text: 'story_delete_error'.tr(),
//         icon: Icons.error,
//         color: Colors.redAccent,
//       );
//       print('story_delete_error'.tr());
//     }
//   }
//
//   Future<void> _markStoryAsViewed(String uid) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(uid)
//           .update({'isViewed': true});
//     } catch (e) {
//       print('Error marking story as viewed: $e');
//     }
//   }
//
//   Future<List<Map<String, dynamic>>> getUserStory(String uid) async {
//     try {
//       QuerySnapshot querySnapshot = await FirebaseFirestore.instance
//           .collection('stories')
//           .where('uid', isEqualTo: uid)
//           .orderBy('timestamp', descending: true)
//           .get();
//
//       List<Map<String, dynamic>> stories = querySnapshot.docs
//           .map((doc) => {
//         'url': doc['url'],
//         'timestamp': doc['timestamp'],
//       })
//           .toList();
//
//       return stories;
//     } catch (e) {
//       print('Failed to fetch stories: $e');
//       return [];
//     }
//   }
//
//   Future<void> _deleteExpiredStories() async {
//     final now = DateTime.now();
//     try {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('stories')
//           .where('uid', isEqualTo: widget.userProfile.uid)
//           .get();
//
//       for (var doc in snapshot.docs) {
//         final data = doc.data();
//         final timestamp = data['timestamp'] as Timestamp?;
//         final storyTime = timestamp?.toDate();
//
//         if (storyTime != null && now.difference(storyTime).inHours >= 24) {
//           await _deleteStory(doc.id);
//         }
//       }
//     } catch (e) {
//       print('Error deleting expired stories: $e');
//     }
//   }
//
//   Future<void> _loadSeenStories() async {
//     try {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('stories')
//           .where('uid', isEqualTo: widget.userProfile.uid!)
//           .get();
//
//       final stories = snapshot.docs.map((doc) => doc.data()).toList();
//       setState(() {
//         _seenStories = stories;
//       });
//     } catch (e) {
//       print('Error loading seen stories: $e');
//     }
//   }
//
//   Future<void> seenStory() async {
//     _storyController.pause();
//
//     await showModalBottomSheet<void>(
//       context: context,
//       builder: (BuildContext context) {
//         return ListView.builder(
//           itemCount: _seenStories.length,
//           itemBuilder: (context, index) {
//             final story = _seenStories[index];
//             return ListTile(
//               leading: Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   image: DecorationImage(
//                     image: NetworkImage(widget.userProfile.pfpURL!),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//               title: Text(widget.userProfile.name!, style: StyleText(),),
//               subtitle: Text(
//                 DateFormat('HH:mm').format(
//                   story['timestamp'].toDate(),
//                 ), style: StyleText(),
//               ),
//               trailing: Icon(
//                 Icons.remove_red_eye,
//                 size: 20,
//               ),
//             );
//           },
//         );
//       },
//     ).whenComplete(() {
//       _storyController.play();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('stories')
//             .where('uid', isEqualTo: widget.userProfile.uid!)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Container();
//           }
//
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             Future.microtask(() async {
//               await widget.requestPermission();
//               await widget.pickAndUploadMedia(ImageSource.camera);
//               Navigator.pop(context);
//             });
//             return Container();
//           }
//
//           final stories = snapshot.data!.docs;
//           final storyItems = stories.map((story) {
//             final storyUrl = story['url'];
//             if (storyUrl != null) {
//               return StoryItem.pageImage(
//                 // imageFit: BoxFit.cover,
//                 url: storyUrl ?? 'https://via.placeholder.com/150',
//                 controller: _storyController,
//                 loadingWidget: Center(
//                   child: CircularProgressIndicator(),
//                 ),
//                 errorWidget: Text('failed_story'.tr(), style: StyleText(),),
//               );
//             } else {
//               return StoryItem.pageImage(
//                 // imageFit: BoxFit.cover,
//                 url: 'https://via.placeholder.com/150',
//                 controller: _storyController,
//                 loadingWidget: Center(
//                   child: CircularProgressIndicator(),
//                 ),
//                 errorWidget: Text('failed_story'.tr(), style: StyleText(),),
//               );
//             }
//           }).toList();
//
//           return Stack(
//             children: [
//               StoryView(
//                 controller: _storyController,
//                 storyItems: storyItems,
//                 onComplete: () async {
//                   await _markStoryAsViewed(widget.userProfile.uid!);
//                   await _loadSeenStories();
//                   Navigator.pop(context);
//                 },
//               ),
//               if (stories.isNotEmpty)
//                 Positioned(
//                   top: MediaQuery.of(context).padding.top + 20,
//                   left: 10,
//                   right: 10,
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Row(
//                         children: [
//                           IconButton(
//                             icon: Icon(
//                               Icons.arrow_back,
//                               color: Colors.white,
//                             ),
//                             onPressed: () {
//                               Navigator.pop(context);
//                             },
//                           ),
//                           CircleAvatar(
//                             backgroundImage:
//                                 NetworkImage(widget.userProfile.pfpURL!),
//                             radius: 18,
//                           ),
//                           SizedBox(width: 10),
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'my_story'.tr(),
//                                 style: StyleText(color: Colors.white,
//                                   fontSize: 15,),
//                               ),
//                               Text(
//                                 _timestamp,
//                                 style: StyleText(color: Colors.white,
//                                   fontSize: 12,),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                       Row(
//                         children: [
//                           // IconButton(
//                           //   onPressed: () {
//                           //     if (play) {
//                           //       _storyController.pause();
//                           //     } else {
//                           //       _storyController.play();
//                           //     }
//                           //
//                           //     setState(() {
//                           //       play = !play;
//                           //     });
//                           //   },
//                           //   icon: Icon(
//                           //     play ? Icons.pause : Icons.play_arrow,
//                           //     color: Colors.redAccent,
//                           //     size: 19,
//                           //   ),
//                           // ),
//                           IconButton(
//                             onPressed: () {
//                               _storyController.pause();
//
//                               showGeneralDialog(
//                                 context: context,
//                                 barrierDismissible: false,
//                                 barrierLabel: "Delete Story",
//                                 transitionDuration: Duration(milliseconds: 300),
//                                 pageBuilder: (context, animation, secondaryAnimation) {
//                                   return AlertDialog(
//                                     actions: [
//                                       TextButton(
//                                         onPressed: () {
//                                           _storyController.play();
//                                           Navigator.pop(context);
//                                         },
//                                         child: Text(
//                                           'no'.tr(),
//                                           style: StyleText(color: Colors.redAccent,
//                                             fontWeight: FontWeight.bold,),
//                                         ),
//                                       ),
//                                       TextButton(
//                                         onPressed: () async {
//                                           _deleteStory(stories[0].id)
//                                               .whenComplete(() {
//                                             Navigator.pop(context);
//                                             _storyController.next();
//                                           });
//                                         },
//                                         child: Text(
//                                           'yes'.tr(),
//                                           style: StyleText(color: Theme.of(context)
//                                               .colorScheme
//                                               .primary,
//                                             fontWeight: FontWeight.bold,),
//                                         ),
//                                       ),
//                                     ],
//                                     title: Text(
//                                       "delete_story".tr(),
//                                       style: StyleText(fontSize: 15),
//                                     ),
//                                   );
//                                 },
//                                 transitionBuilder: (context, animation, secondaryAnimation, child) {
//                                   return ScaleTransition(
//                                     scale: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
//                                     child: child,
//                                   );
//                                 },
//                               );
//                             },
//                             icon: Icon(
//                               Icons.delete,
//                               color: Colors.redAccent,
//                               size: 19,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               if (stories.isNotEmpty)
//                 Positioned(
//                   bottom: 0,
//                   child: GestureDetector(
//                     onTap: () {
//                       seenStory();
//                     },
//                     child: Container(
//                       alignment: Alignment.center,
//                       color: Colors.black.withOpacity(0.2),
//                       width: MediaQuery.of(context).size.width,
//                       height: 40,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             '${_seenStories.length}',
//                             style: StyleText(color: Colors.white),
//                           ),
//                           SizedBox(width: 5),
//                           Icon(
//                             Icons.remove_red_eye,
//                             color: Colors.white,
//                           )
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:story_view/story_view.dart';

import '../../models/user_profile.dart';
import '../../utils.dart';

class StoryViewerScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Future<void> Function() requestPermission;
  final Future<void> Function(ImageSource) pickAndUploadMedia;

  StoryViewerScreen({
    required this.userProfile,
    required this.requestPermission,
    required this.pickAndUploadMedia,
  });

  @override
  _StoryViewerScreenState createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late StoryController _storyController;
  List<Map<String, dynamic>> _seenStories = [];

  @override
  void initState() {
    super.initState();
    _storyController = StoryController();
    _loadSeenStories();
  }

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  /// Memuat data pengguna yang sudah melihat story
  Future<void> _loadSeenStories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stories')
          .doc(widget.userProfile.uid)
          .collection('viewers')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _seenStories = snapshot.docs
            .map((doc) => {
          'name': doc['name'],
          'profileImage': doc['profileImage'],
          'timestamp': doc['timestamp'] as Timestamp,
        })
            .toList();
      });
    } catch (e) {
      print('Error loading seen stories: $e');
    }
  }

  /// Menampilkan modal untuk melihat pengguna yang melihat story
  void _showSeenStoryModal() {
    _storyController.pause();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: _seenStories.length,
          itemBuilder: (context, index) {
            final viewer = _seenStories[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(viewer['profileImage']),
              ),
              title: Text(viewer['name']),
              subtitle: Text(
                DateFormat('HH:mm, dd MMM yyyy')
                    .format(viewer['timestamp'].toDate()),
              ),
              trailing: Icon(Icons.remove_red_eye, size: 20),
            );
          },
        );
      },
    ).whenComplete(() {
      _storyController.play();
    });
  }

  /// Membuat Story View
  Widget _buildStoryView(List<QueryDocumentSnapshot> stories) {
    final storyItems = stories.map((story) {
      return StoryItem.pageImage(
        url: story['url'],
        controller: _storyController,
        loadingWidget: Center(child: CircularProgressIndicator()),
        errorWidget: Center(child: Text('Failed to load story')),
      );
    }).toList();

    return StoryView(
      storyItems: storyItems,
      controller: _storyController,
      onComplete: () async {
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stories')
            .where('uid', isEqualTo: widget.userProfile.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No stories available'));
          }

          final stories = snapshot.data!.docs;

          return Stack(
            children: [
              _buildStoryView(stories),
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                left: 10,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CircleAvatar(
                      backgroundImage: NetworkImage(widget.userProfile.pfpURL!),
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'my_story'.tr(),
                          style: StyleText(color: Colors.white,
                            fontSize: 15,),
                        ),
                        // Text(
                        //   _timestamp,
                        //   style: StyleText(color: Colors.white,
                        //     fontSize: 12,),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: GestureDetector(
                  onTap: _showSeenStoryModal,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    color: Colors.black.withOpacity(0.5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_seenStories.length}',
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(width: 5),
                        Icon(Icons.remove_red_eye, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}