import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:story_view/controller/story_controller.dart';
import 'package:story_view/widgets/story_view.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/user_profile.dart';
import '../../service/alert_service.dart';
import '../../widgets/utils.dart';

class OtherUser extends StatefulWidget {
  final UserProfile userProfile;
  final List<String> storyData;

  OtherUser({
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
  final TextEditingController replyController = TextEditingController();
  final AlertService _alertService = GetIt.instance.get<AlertService>();
  int currentStoryIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.addListener(_handleFocusChange);
    checkAndDeleteExpiredStories();
    for (var i = 0; i < widget.storyData.length; i++) {
      print('Story $i: ${widget.storyData[i]}');
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
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _storyController.dispose();
    replyController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    _focusNode.hasFocus ? _storyController.pause() : _storyController.play();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final isKeyboardVisible =
        WidgetsBinding.instance.window.viewInsets.bottom > 0;
    isKeyboardVisible ? _storyController.pause() : _storyController.play();
  }

  Future<void> _sendReply() async {
    final replyText = replyController.text.trim();
    if (replyText.isEmpty) {
      print('ERRORRRRRRR');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('replies').add({
        'uid': widget.userProfile.uid,
        'storyUrl': widget.storyData[currentStoryIndex],
        'reply': replyText,
        'timestamp': Timestamp.now(),
      });

      // _alertService.showToast(
      //   text: 'reply_send'.tr(),
      //   icon: Icons.check,
      //   color: Colors.green,
      // );
      replyController.clear();
    } catch (e) {
      print('ERRORRRRRRR ${e}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final storyItems = widget.storyData.map((url) {
      return StoryItem.pageImage(
        url: url,
        controller: _storyController,
        loadingWidget: Center(child: CircularProgressIndicator()),
        errorWidget: Center(
          child: Text(
            'failed_story'.tr(),
            style: StyleText(color: Colors.grey),
          ),
        ),
      );
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          StoryView(
            storyItems: storyItems,
            controller: _storyController,
            onComplete: () => Navigator.pop(context),
          ),
          _buildTopBar(context),
          _buildReplyBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 5,
      right: 5,
      child: Row(
        children: [
          BackButton(color: Colors.white),
          CircleAvatar(
            backgroundImage: NetworkImage(widget.userProfile.pfpURL!),
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userProfile.name ?? '-',
                style: StyleText(color: Colors.white, fontSize: 15),
              ),
              FutureBuilder<String>(
                future: _getLastStoryTime(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox.shrink();
                  }
                  return Text(
                    snapshot.data ?? '-',
                    style: StyleText(color: Colors.white, fontSize: 12),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<String> _getLastStoryTime() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('stories')
        .where('uid', isEqualTo: widget.userProfile.uid)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return '-';
    }

    final timestamp = snapshot.docs.first['timestamp'] as Timestamp;
    return DateFormat('HH:mm', context.locale.toString())
        .format(timestamp.toDate());
  }

  Widget _buildReplyBar() {
    return Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: replyController,
                style: StyleText(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'hint_reply'.tr(),
                  hintStyle: StyleText(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.3),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(width: 10),
            GestureDetector(
              onTap: _sendReply,
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
    );
  }
}