import 'package:chating/pages/media_page.dart';
import 'package:chating/pages/connection/videoCall.dart';
import 'package:chating/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/fitur.dart';
import '../models/user_profile.dart';
import 'connection/audioCall.dart';

class DetailprofilePage extends StatefulWidget {
  final UserProfile chatUser;
  final VoidCallback onDeleteMessages;

  DetailprofilePage({
    required this.chatUser,
    required this.onDeleteMessages,
  });

  @override
  State<DetailprofilePage> createState() => _DetailprofilePageState();
}

class _DetailprofilePageState extends State<DetailprofilePage> {
  List<Fitur> fitur = [
    Fitur(
      id: '1',
      icon: Icons.call,
      title: 'Audio',
    ),
    Fitur(
      id: '2',
      icon: Icons.videocam_outlined,
      title: 'Video',
    ),
    Fitur(
      id: '3',
      icon: Icons.search,
      title: 'Search',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: true,
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
        title: Text(
          'contact_info'.tr(),
          overflow: TextOverflow.ellipsis,
          style: StyleText(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                showGeneralDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: '',
                  barrierColor: Colors.black54,
                  transitionDuration: Duration(milliseconds: 300),
                  pageBuilder: (context, anim1, anim2) {
                    return AlertDialog(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      content: Image.network(widget.chatUser.pfpURL!),
                    );
                  },
                  transitionBuilder: (context, anim1, anim2, child) {
                    return Transform.scale(
                      scale: anim1.value,
                      child: child,
                    );
                  },
                );
              },
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                      image: NetworkImage(widget.chatUser.pfpURL!),
                      fit: BoxFit.cover),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              widget.chatUser.name!,
              style: StyleText(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              widget.chatUser.phoneNumber ?? '-',
              style: StyleText(
                fontSize: 15,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 15),
            Wrap(
              spacing: 14,
              runSpacing: 15,
              children: fitur
                  .map(
                    (e) => ButtonFitur(
                      fitur: e,
                      chatUser: widget.chatUser,
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 15),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MediaPage(),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.only(left: 20, right: 20),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(width: 10),
                    Container(
                      width: MediaQuery.sizeOf(context).width - 94,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'media_document'.tr(),
                            style: StyleText(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '6',
                                style: StyleText(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.only(left: 20, right: 20),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: widget.onDeleteMessages,
                    child: Container(
                      color: Colors.transparent,
                      width: MediaQuery.sizeOf(context).width,
                      child: Text(
                        'clear_chat'.tr(),
                        style: StyleText(color: Colors.red),
                      ),
                    ),
                  ),
                  Divider(
                    height: 20,
                    color: Colors.black12,
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      color: Colors.transparent,
                      width: MediaQuery.sizeOf(context).width,
                      child: Text(
                        'blokir'.tr() + '${widget.chatUser.name}',
                        style: StyleText(color: Colors.red),
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
  }
}

class ButtonFitur extends StatefulWidget {
  final Fitur? fitur;
  final UserProfile chatUser;

  ButtonFitur({
    required this.fitur,
    required this.chatUser,
  });

  @override
  State<ButtonFitur> createState() => _ButtonFiturState();
}

class _ButtonFiturState extends State<ButtonFitur> {
  void _handleCall(String callType) async {
    String phoneNumber = await _getPhoneNumber(widget.chatUser.uid!);

    if (callType == 'audio') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioCallScreen(userProfile: widget.chatUser),
        ),
      );
    } else if (callType == 'video') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(userProfile: widget.chatUser),
        ),
      );
    }
  }

  Future<String> _getPhoneNumber(String userId) async {
    var firestore = FirebaseFirestore.instance;
    var userDoc = await firestore.collection('users').doc(userId).get();
    return userDoc.data()!['phoneNumber'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double buttonSize = screenWidth * 0.27;

    return GestureDetector(
      onTap: () {
        switch (widget.fitur!.id) {
          case '1':
            _handleCall('audio');
            break;
          case '2':
            _handleCall('video');
            break;
          case '3':
            print('SEARCH ACTION');
            break;
          default:
            break;
        }
      },
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.fitur!.icon,
              size: buttonSize * 0.3,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 5),
            Text(
              widget.fitur!.title!,
              style: StyleText(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          ],
        ),
      ),
    );
  }
}
