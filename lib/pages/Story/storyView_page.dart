import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:story_view/story_view.dart';

import '../../models/user_profile.dart';
import '../../service/alert_service.dart';

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
  final GetIt _getIt = GetIt.instance;
  late AlertService _alertService;
  String _timestamp = '';
  List<Map<String, dynamic>> _seenStories = [];
  bool play = true;

  @override
  void initState() {
    super.initState();
    _storyController = StoryController();
    _alertService = _getIt.get<AlertService>();
    _loadStoryData();
    _deleteExpiredStories();
    _loadSeenStories();
  }

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _loadStoryData() async {
    try {
      final storyData = await getUserStory(widget.userProfile.uid!);
      if (storyData.isNotEmpty) {
        final timestamp = storyData[0]['timestamp'] as Timestamp?;
        final dateTime = timestamp?.toDate();

        if (dateTime != null &&
            DateTime.now().difference(dateTime).inHours >= 24) {
          await _deleteExpiredStories();
          setState(() {
            _timestamp = 'Story expired';
          });
        } else {
          setState(() {
            _timestamp = dateTime != null
                ? DateFormat('HH:mm, dd MMM yyyy').format(dateTime)
                : 'Unknown time';
          });
        }
      } else {
        setState(() {
          _timestamp = 'No timestamp available';
        });
      }
    } catch (e) {
      print('Error loading story data: $e');
      setState(() {
        _timestamp = 'Error loading time';
      });
    }
  }

  Future<void> _deleteStory(String storyId) async {
    try {
      await FirebaseFirestore.instance
          .collection('stories')
          .doc(storyId)
          .delete();
      _alertService.showToast(
        text: 'Successfully deleted story!',
        icon: Icons.check,
        color: Colors.green,
      );
      setState(() {});
    } catch (e) {
      _alertService.showToast(
        text: e.toString(),
        icon: Icons.error,
        color: Colors.redAccent,
      );
      print('Error deleting story: $e');
    }
  }

  Future<void> _markStoryAsViewed(String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'isViewed': true});
    } catch (e) {
      print('Error marking story as viewed: $e');
    }
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

  Future<void> _deleteExpiredStories() async {
    final now = DateTime.now();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stories')
          .where('uid', isEqualTo: widget.userProfile.uid)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        final storyTime = timestamp?.toDate();

        if (storyTime != null && now.difference(storyTime).inHours >= 24) {
          await _deleteStory(doc.id);
        }
      }
    } catch (e) {
      print('Error deleting expired stories: $e');
    }
  }

  Future<void> _loadSeenStories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stories')
          .where('uid', isEqualTo: widget.userProfile.uid!)
          .get();

      final stories = snapshot.docs.map((doc) => doc.data()).toList();
      setState(() {
        _seenStories = stories;
      });
    } catch (e) {
      print('Error loading seen stories: $e');
    }
  }

  Future<void> seenStory() async {
    _storyController.pause();

    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: _seenStories.length,
          itemBuilder: (context, index) {
            final story = _seenStories[index];
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(widget.userProfile.pfpURL!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Text(widget.userProfile.name!),
              subtitle: Text(
                DateFormat('HH:mm').format(
                  story['timestamp'].toDate(),
                ),
              ),
              trailing: Icon(
                Icons.remove_red_eye,
                size: 20,
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _storyController.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stories')
            .where('uid', isEqualTo: widget.userProfile.uid!)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Container();
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            Future.microtask(() async {
              await widget.requestPermission();
              await widget.pickAndUploadMedia(ImageSource.camera);
              Navigator.pop(context);
            });
            return Container();
          }

          final stories = snapshot.data!.docs;
          final storyItems = stories.map((story) {
            final storyUrl = story['url'];
            if (storyUrl != null) {
              return StoryItem.pageImage(
                // imageFit: BoxFit.cover,
                url: storyUrl ?? 'https://via.placeholder.com/150',
                controller: _storyController,
                loadingWidget: Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: Text('Failed to load story'),
              );
            } else {
              return StoryItem.pageImage(
                // imageFit: BoxFit.cover,
                url: 'https://via.placeholder.com/150',
                controller: _storyController,
                loadingWidget: Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: Text('Failed to load story'),
              );
            }
          }).toList();

          return Stack(
            children: [
              StoryView(
                controller: _storyController,
                storyItems: storyItems,
                onComplete: () async {
                  await _markStoryAsViewed(widget.userProfile.uid!);
                  await _loadSeenStories();
                  Navigator.pop(context);
                },
              ),
              if (stories.isNotEmpty)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 10,
                  right: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          CircleAvatar(
                            backgroundImage:
                                NetworkImage(widget.userProfile.pfpURL!),
                            radius: 18,
                          ),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Story',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                _timestamp,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // IconButton(
                          //   onPressed: () {
                          //     if (play) {
                          //       _storyController.pause();
                          //     } else {
                          //       _storyController.play();
                          //     }
                          //
                          //     setState(() {
                          //       play = !play;
                          //     });
                          //   },
                          //   icon: Icon(
                          //     play ? Icons.pause : Icons.play_arrow,
                          //     color: Colors.redAccent,
                          //     size: 19,
                          //   ),
                          // ),
                          IconButton(
                            onPressed: () {
                              _storyController.pause();

                              showGeneralDialog(
                                context: context,
                                barrierDismissible: false,
                                barrierLabel: "Delete Story",
                                transitionDuration: Duration(milliseconds: 300),
                                pageBuilder: (context, animation, secondaryAnimation) {
                                  return AlertDialog(
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          _storyController.play();
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          'No',
                                          style: GoogleFonts.poppins().copyWith(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          _deleteStory(stories[0].id)
                                              .whenComplete(() {
                                            Navigator.pop(context);
                                            _storyController.next();
                                          });
                                        },
                                        child: Text(
                                          'Yes',
                                          style: GoogleFonts.poppins().copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                    title: Text(
                                      "Are you sure you want to delete this story?",
                                      style: TextStyle(fontSize: 15),
                                    ),
                                  );
                                },
                                transitionBuilder: (context, animation, secondaryAnimation, child) {
                                  return ScaleTransition(
                                    scale: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                                    child: child,
                                  );
                                },
                              );
                            },
                            icon: Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                              size: 19,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (stories.isNotEmpty)
                Positioned(
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {
                      seenStory();
                    },
                    child: Container(
                      alignment: Alignment.center,
                      color: Colors.black.withOpacity(0.2),
                      width: MediaQuery.of(context).size.width,
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${_seenStories.length}',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(
                            Icons.remove_red_eye,
                            color: Colors.white,
                          )
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