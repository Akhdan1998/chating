import 'dart:async';
import 'package:chating/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:story_view/controller/story_controller.dart';
import 'package:story_view/widgets/story_view.dart';
import '../models/user_profile.dart';
import '../service/alert_service.dart';
import '../widgets/textfield.dart';

class OtherUser extends StatefulWidget {
  final UserProfile userProfile;
  final List<String> storyData;

  const OtherUser({
    Key? key,
    required this.userProfile,
    required this.storyData,
  }) : super(key: key);

  @override
  State<OtherUser> createState() => _OtherUserState();
}

class _OtherUserState extends State<OtherUser> with WidgetsBindingObserver {
  final StoryController _storyController = StoryController();
  final FocusNode _focusNode = FocusNode();
  final GetIt _getIt = GetIt.instance;
  late AlertService _alertService;
  final TextEditingController replyController = TextEditingController();
  int currentStoryIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.addListener(_handleFocusChange);
    checkAndDeleteExpiredStories();
    _alertService = _getIt.get<AlertService>();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _storyController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _storyController.pause();
    } else {
      _storyController.play();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    if (bottomInset > 0.0) {
      _storyController.pause();
    } else {
      _storyController.play();
    }
  }

  Future<void> deleteStory(String uid) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('stories')
          .where('uid', isEqualTo: uid)
          .get();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        String fileUrl = doc['url'];

        Reference fileRef = FirebaseStorage.instance.refFromURL(fileUrl);
        await fileRef.delete();

        await doc.reference.delete();
      }

      print('Stories successfully deleted for uid: $uid');
    } catch (e) {
      print('Failed to delete stories: $e');
      _alertService.showToast(
        text: 'delete_status'.tr(),
        icon: Icons.error,
        color: Colors.red,
      );
    }
  }

  Future<void> checkAndDeleteExpiredStories() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('stories').get();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Timestamp timestamp = doc['timestamp'];
        DateTime uploadTime = timestamp.toDate();
        DateTime currentTime = DateTime.now();

        if (currentTime.difference(uploadTime).inHours >= 24) {
          String fileUrl = doc['url'];

          Reference fileRef = FirebaseStorage.instance.refFromURL(fileUrl);
          await fileRef.delete();

          await doc.reference.delete();

          print('Expired story deleted for uid: ${doc['uid']}');
        }
      }
    } catch (e) {
      print('Failed to delete expired stories: $e');
      _alertService.showToast(
        text: 'expired_status'.tr(),
        icon: Icons.error,
        color: Colors.red,
      );
    }
  }

  Future<void> sendReply() async {
    if (replyController.text.isNotEmpty) {
      try {
        String storyUrl = widget.storyData[currentStoryIndex];

        await FirebaseFirestore.instance.collection('replies').add({
          'uid': widget.userProfile.uid,
          'storyUrl': storyUrl,
          'reply': replyController.text,
          'timestamp': Timestamp.now(),
        });

        _alertService.showToast(
          text: 'reply_send'.tr(),
          icon: Icons.check,
          color: Colors.green,
        );

        replyController.clear();
      } catch (e) {
        print('Errorrrrrr $e');
        _alertService.showToast(
          text: 'reply_error'.tr(),
          icon: Icons.error,
          color: Colors.red,
        );
      }
    } else {
      _alertService.showToast(
        text: 'reply'.tr(),
        icon: Icons.error,
        color: Colors.red,
      );
    }
  }

  Future<void> markStoryAsSeen(String storyId) async {
    try {
      await FirebaseFirestore.instance
          .collection('stories')
          .doc(storyId)
          .update({
        'seenBy': FieldValue.arrayUnion([widget.userProfile.uid]),
      });

      print('Story marked as seen for uid: ${widget.userProfile.uid}');
    } catch (e) {
      print('Failed to mark story as seen: $e');
      _alertService.showToast(
        text: 'as_seen'.tr(),
        icon: Icons.error,
        color: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<StoryItem> storyItems = widget.storyData.map((url) {
      return StoryItem.pageImage(
        // imageFit: BoxFit.cover,
        loadingWidget: Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: Text('Failed to load story'),
        url: url,
        controller: _storyController,
      );
    }).toList();
    return Scaffold(
      body: Stack(
        children: [
          StoryView(
            storyItems: storyItems,
            controller: _storyController,
            onComplete: () {
              Navigator.pop(context);
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 5,
            right: 5,
            child: Container(
              width: MediaQuery.of(context).size.width - 17,
              child: Row(
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
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(widget.userProfile.pfpURL!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userProfile.name ?? '-',
                        style: StyleText(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              height: 50,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      style: StyleText(color: Colors.white),
                      textCapitalization: TextCapitalization.sentences,
                      controller: replyController,
                      onSaved: (value) {
                        replyController.text = value!;
                      },
                      decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.withOpacity(0.3),
                          hintText: 'hint_reply'.tr(),
                          hintStyle: StyleText(color: Colors.white)),
                    ),
                  ),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      sendReply();
                    },
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}