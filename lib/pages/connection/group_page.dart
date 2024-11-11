import 'dart:io';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:chating/utils.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart' as vp;
import 'package:video_player/video_player.dart';
import '../../main.dart';
import '../../models/group.dart';
import '../../models/message.dart' as chat;
import '../../models/message.dart';
import '../../models/user_profile.dart';
import '../../service/alert_service.dart';
import '../../service/auth_service.dart';
import '../../service/database_service.dart';
import '../../service/media_service.dart';
import '../../service/storage_service.dart';
import '../detailGroup_page.dart';
import 'groupAudioCall_page.dart';
import 'groupVideoCall_page.dart';

class GroupPage extends StatefulWidget {
  final Group group;
  final List<UserProfile> userProfiles;

  GroupPage({
    required this.group,
    required this.userProfiles,
  });

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late AlertService _alertService;
  late DatabaseService _databaseService;
  late MediaService _mediaService;
  late StorageService _storageService;
  bool _isVisible = false;
  ChatUser? currentUser, otherUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User _user;
  late ChatUser _chatUser;
  List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isInGroup = true;
  late FlutterSoundRecorder recorder = FlutterSoundRecorder();
  bool play = false;
  File? audioFile;
  late AudioPlayer audioPlayer;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  String? currentAudioUrl;
  PlayerState audioPlayerState = PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeUser().then((_) {
      _setCurrentAndOtherUser();
      _clearMessages();
      _loadMessages();
      _showTextAfterDelay();
    });
    initRecorder();
    audioPlayer = AudioPlayer();
    audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });

    audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        duration = newDuration;
      });
    });

    audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        position = newPosition;
      });
    });
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    audioPlayer.dispose();
    super.dispose();
  }

  void _clearMessages() {
    setState(() {
      _messages = [];
    });
  }

  void _initializeServices() {
    _authService = _getIt.get<AuthService>();
    _alertService = _getIt.get<AlertService>();
    _databaseService = _getIt.get<DatabaseService>();
    _mediaService = _getIt.get<MediaService>();
    _storageService = _getIt.get<StorageService>();
  }

  void _loadMessages() {
    _firestore
        .collection('messagesGroup')
        .where('groupId', isEqualTo: widget.group.id)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      List<ChatMessage> newMessages = [];
      for (var doc in snapshot.docs) {
        newMessages.add(ChatMessage.fromJson(doc.data()));
      }
      setState(() {
        if (newMessages.length > _messages.length) {
          final lastMessage = newMessages.first;

          if (lastMessage.user.id != currentUser!.id) {
            flutterLocalNotificationsPlugin.show(
              0,
              widget.group.name,
              lastMessage.text,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'Awokawok',
                  'AwokAwokAwok',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
              ),
            );
          }
        }
        _messages = newMessages;
      });
      _scrollToBottom();
    });
  }

  void _sendMessage(ChatMessage message) {
    Map<String, dynamic> messageData = message.toJson();
    messageData['groupId'] = widget.group.id;

    _firestore.collection('messagesGroup').add(messageData).then((_) {
      _scrollToBottom();
    }).catchError((error) {
      print("Failed to send message: $error");
    });
  }

  void _setCurrentAndOtherUser() {
    currentUser = ChatUser(
      id: _authService.user!.uid,
      firstName: _authService.user!.displayName,
    );

    otherUser = ChatUser(
      id: widget.group.id,
      firstName: widget.group.name,
      profileImage: widget.group.imageUrl,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showTextAfterDelay() async {
    await Future.delayed(Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isVisible = true;
      });
    }

    await Future.delayed(Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _isVisible = false;
      });
    }
  }

  Future<void> _initializeUser() async {
    _user = _auth.currentUser!;
    _chatUser = ChatUser(
      id: _user.uid,
      firstName: _user.displayName,
      profileImage: _user.photoURL,
    );

    _clearMessages();
  }

  Future<void> uploadFile() async {
    Navigator.pop(context);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        List<String> uids = widget.group.members;
        await uploadToFirebase(file, MessageTypeGroup.Document, uids);
      }
    } catch (e) {
      print('Error saat memilih file: $e');
    }
  }

  Future<void> uploadToFirebase(
      File file, MessageTypeGroup messageType, List<String> uids) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      String fileName =
          'mediaGroup/${DateTime.now().toIso8601String()}${p.extension(file.path)}';
      Reference ref = storage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print(
            'Progres upload: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
      });

      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);

      String downloadURL = await taskSnapshot.ref.getDownloadURL();

      late ChatMessage message;
      if (messageType == MessageTypeGroup.Document) {
        message = ChatMessage(
          user: _chatUser,
          createdAt: DateTime.now(),
          medias: [
            ChatMedia(
              url: downloadURL,
              fileName: 'File',
              type: MediaType.file,
            ),
          ],
        );
      } else if (messageType == MessageTypeGroup.Image) {
        message = ChatMessage(
          user: _chatUser,
          createdAt: DateTime.now(),
          medias: [
            ChatMedia(
              url: downloadURL,
              fileName: '',
              type: MediaType.image,
            ),
          ],
        );
      } else if (messageType == MessageTypeGroup.Video) {
        message = ChatMessage(
          user: _chatUser,
          createdAt: DateTime.now(),
          medias: [
            ChatMedia(
              url: downloadURL,
              fileName: '',
              type: MediaType.video,
            ),
          ],
        );
      }

      _sendMessage(message);
    } catch (e) {
      print('Error saat mengupload file: $e');
    }
  }

  Future<void> launchPhoneCall(String phoneNumber) async {
    String url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _deleteAllMessages(String groupId) async {
    var collection = _firestore.collection('messagesGroup');
    var snapshots = await collection.where('groupId', isEqualTo: groupId).get();

    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }

    setState(() {
      _messages = [];
    });

    _alertService.showToast(
      text: 'successfully'.tr(),
      icon: Icons.check,
      color: Colors.green,
    );

    Navigator.pop(context);
  }

  Future<void> _leaveGroup() async {
    try {
      String userId = _auth.currentUser!.uid;
      DocumentReference groupRef =
          _firestore.collection('groups').doc(widget.group.id);

      await groupRef.update({
        'members': FieldValue.arrayRemove([userId])
      });

      await _deleteMessages();

      setState(() {
        _isInGroup = false;
      });

      _alertService.showToast(
        text: 'left_group'.tr(),
        icon: Icons.check,
        color: Colors.green,
      );
      Navigator.pop(context);
    } catch (e) {
      print("Failed to leave group: $e");
      _alertService.showToast(
        text: 'failed_leave_group'.tr(),
        icon: Icons.error,
        color: Colors.red,
      );
    }
  }

  Future<void> _deleteMessages() async {
    QuerySnapshot messagesSnapshot = await _firestore
        .collection('messagesGroup')
        .where('groupId', isEqualTo: widget.group.id)
        .get();

    for (QueryDocumentSnapshot doc in messagesSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _downloadAndOpenPDF(
      String url, String fileName, DateTime dateTime) async {
    try {
      Dio dio = Dio();
      var tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;
      String filePath =
          '$tempPath/${fileName}_${dateTime.toIso8601String()}.pdf';
      // String filePath = '$tempPath/temp.pdf';

      await dio.download(url, filePath);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewPage(
            filePath: filePath,
            fileName: fileName,
            dateTime: dateTime,
          ),
        ),
      );
    } catch (e) {
      print('Error saat mengunduh atau membuka file PDF: $e');
    }
  }

  void _showDeleteDialog(BuildContext context, ChatMessage message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return AlertDialog(
          actionsPadding: EdgeInsets.only(top: 1, bottom: 5, right: 10),
          title: Text(
            'del'.tr(),
            style: StyleText(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'desk_del'.tr(),
            style: StyleText(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'no'.tr(),
                style: StyleText(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _firestore
                      .collection('messagesGroup')
                      .doc(message.user.id)
                      .delete();

                  setState(() {
                    _messages.remove(message);
                    // messageIdMap.remove(message);
                  });

                  _alertService.showToast(
                    text: 'del'.tr(),
                    icon: Icons.check,
                    color: Colors.green,
                  );
                } catch (e) {
                  print('Error deleting message: $e');
                  _alertService.showToast(
                    text: 'successfully'.tr(),
                    icon: Icons.error,
                    color: Colors.red,
                  );
                }

                Navigator.pop(context);
              },
              child: Text(
                'yes'.tr(),
                style: StyleText(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: child,
        );
      },
    );
  }

  Future soundRecord() async {
    print('START RECORDDDDDDDDDD');
    await recorder.startRecorder(
      toFile: 'audio',
      // codec : Codec.mp3,
    );
  }

  Future<void> soundStop() async {
    final isPath = await recorder.stopRecorder();
    audioFile = File(isPath!);
    print('Recorded audio Flutter Sound: $isPath');
    if (audioFile != null) {
      await uploadAudioToFirebase(audioFile!);
    }
  }

  Future<void> uploadAudioToFirebase(File file) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      final fileName =
          'audioGroup/${DateTime.now().toIso8601String()}${p.extension(file.path)}';
      Reference ref = storage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(file);
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print(
            'Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
      });

      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      String downloadURL = await taskSnapshot.ref.getDownloadURL();
      print('Audio file uploaded successfully. Download URL: $downloadURL');

      ChatMessage message = ChatMessage(
        user: _chatUser,
        createdAt: DateTime.now(),
        medias: [
          ChatMedia(
            url: downloadURL,
            fileName: 'Audio',
            type: MediaType.video,
          ),
        ],
      );
      _sendMessage(message);

      // chat.Message message = chat.Message(
      //   senderID: currentUser!.id,
      //   content: downloadURL,
      //   messageType: MessageType.Audio,
      //   sentAt: Timestamp.now(),
      //   isRead: false,
      // );
      // await _databaseService.sendChatMessage(
      //   currentUser!.id,
      //   otherUser!.id,
      //   message,
      // );
    } catch (e) {
      print('Error uploading audio file: $e');
    }
  }

  Future initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw 'Microphone permissions not granted';
    }
    await recorder.openRecorder();
    recorder.setSubscriptionDuration(const Duration(milliseconds: 500));
  }

  Future<void> initializeNotifications(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'new_message_channel',
      'New Messages',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      widget.group.name,
      message,
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> memberNames = widget.group.members.map((memberId) {
      final user = widget.userProfiles.firstWhere(
        (user) => user.uid == memberId,
        orElse: () => UserProfile(
          uid: memberId,
          name: 'you'.tr(),
        ),
      );
      return user.name ?? 'you'.tr();
    }).toList();
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
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailGroupPage(
                  users: widget.userProfiles,
                  grup: widget.group,
                  onDeleteAllMessages: _deleteAllMessages,
                  onLeaveGroup: _leaveGroup,
                ),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(widget.group.imageUrl),
                radius: 18.5,
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.name,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _isVisible ? 'info_grup'.tr() : memberNames.join(", "),
                      overflow: TextOverflow.ellipsis,
                      style: StyleText(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.videocam,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupVideoCallScreen(
                    grup: widget.group,
                    users: widget.userProfiles,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.call,
              color: Colors.white,
            ),
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupAudioCallScreen(
                    grup: widget.group,
                    users: widget.userProfiles,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    if (!_isInGroup) {
      return Center(
        child: Text(
          "out_grup".tr(),
          style: StyleText(
            fontSize: 15,
            color: Colors.grey,
          ),
        ),
      );
    }

    return StreamBuilder(
      stream: _firestore
          .collection('messagesGroup')
          .where('groupId', isEqualTo: widget.group.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.data == null ||
            widget.group.members.isEmpty) {
          return Container();
        }

        var messages = snapshot.data!.docs;
        if (messages.isEmpty) {
          var newMessage = messages.last.data();
          if (newMessage['userId'] != currentUser?.id &&
              newMessage['text'] != null) {
            initializeNotifications(newMessage['text']);
          }
        }

        return DashChat(
          quickReplyOptions: QuickReplyOptions(),
          messageListOptions: MessageListOptions(
            separatorFrequency: SeparatorFrequency.days,
            showFooterBeforeQuickReplies: true,
            showDateSeparator: true,
            scrollController: _scrollController,
            scrollPhysics: AlwaysScrollableScrollPhysics(),
          ),
          messageOptions: MessageOptions(
            maxWidth: 250,
            textBeforeMedia: true,
            showOtherUsersName: false,
            showCurrentUserAvatar: false,
            showOtherUsersAvatar: false,
            messageDecorationBuilder: (ChatMessage message,
                ChatMessage? previousMessage, ChatMessage? nextMessage) {
              bool isUser = message.user.id == currentUser!.id;
              return BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              );
            },
            messageTextBuilder: (ChatMessage message,
                ChatMessage? previousMessage, ChatMessage? nextMessage) {
              bool isURL(String text) {
                final Uri? uri = Uri.tryParse(text);
                return uri != null &&
                    (uri.isScheme('http') || uri.isScheme('https'));
              }

              void _launchURL(String url) async {
                final Uri uri = Uri.parse(url);
                if (!await launchUrl(uri)) {
                  throw Exception('Could not launch $uri');
                }
              }

              List<TextSpan> textSpans = [];
              final RegExp urlPattern = RegExp(r'http[s]?://[^\s]+');
              final matches = urlPattern.allMatches(message.text);
              int lastMatchEnd = 0;

              for (final match in matches) {
                if (match.start > lastMatchEnd) {
                  textSpans.add(
                    TextSpan(
                      text: message.text.substring(lastMatchEnd, match.start),
                      style: StyleText(
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  );
                }

                textSpans.add(
                  TextSpan(
                    text: match.group(0),
                    style: StyleText(color: Colors.blue),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _launchURL(match.group(0)!),
                  ),
                );

                lastMatchEnd = match.end;
              }

              if (lastMatchEnd < message.text.length) {
                textSpans.add(TextSpan(
                  text: message.text.substring(lastMatchEnd),
                  style: StyleText(
                    color: Colors.black87,
                    fontSize: 15,
                  ),
                ));
              }

              final firstURLMatch = urlPattern.firstMatch(message.text);
              final firstURL = firstURLMatch?.group(0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (firstURL != null)
                    AnyLinkPreview(
                      link: firstURL,
                      showMultimedia: true,
                      onTap: () => _launchURL(firstURL),
                      errorBody: 'link_body'.tr(),
                      errorTitle: 'link_title'.tr(),
                      bodyStyle: StyleText(fontSize: 12),
                      errorWidget: Container(
                        height: 200,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported_sharp),
                      ),
                      errorImage: "https://google.com/",
                      cache: Duration(seconds: 3),
                      borderRadius: 12,
                      removeElevation: false,
                    ),
                  SizedBox(height: 8),
                  RichText(
                    text: TextSpan(children: textSpans),
                  ),
                  Container(
                    alignment: Alignment.centerRight,
                    child: Text(
                      DateFormat('HH:mm').format(message.createdAt),
                      style: StyleText(
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              );
            },
            showTime: true,
            onLongPressMessage: (ChatMessage message) {
              _showDeleteDialog(context, message);
            },
            onTapMedia: (media) async {
              if (media.type == MediaType.image) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImage(
                      imageUrl: media.url,
                      chatUser: otherUser!,
                      dateTime: media.uploadedDate ?? DateTime.now(),
                    ),
                  ),
                );
              } else if (media.type == MediaType.file) {
                final Uri url = Uri.parse(media.url);
                String fileName = media.fileName ?? 'File';
                DateTime dateTime = media.uploadedDate ?? DateTime.now();
                await _downloadAndOpenPDF(url.toString(), fileName, dateTime);
              } else if (media.type == MediaType.video) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenVideoPlayer(
                      videoUrl: media.url,
                      chatUser: otherUser!,
                      dateTime: media.uploadedDate ?? DateTime.now(),
                    ),
                  ),
                );
              }
            },
          ),
          inputOptions: InputOptions(
            alwaysShowSend: true,
            inputDecoration: InputDecoration(
              fillColor: Colors.grey.shade200,
              filled: true,
              hintText: "typing".tr(),
              hintStyle: StyleText(color: Colors.black38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
            ),
            leading: [
              PopupMenuButton(
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.primary,
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: _mediaMessageGallery(context),
                  ),
                  PopupMenuItem(
                    child: _mediaMessageCamera(context),
                  ),
                  PopupMenuItem(
                    child: _documentMessage(context),
                  ),
                  PopupMenuItem(
                    child: _mediaMessageVideoGallery(context),
                  ),
                  PopupMenuItem(
                    child: _mediaMessageVideoCamera(context),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  setState(() {
                    play = !play;
                  });
                  if (recorder.isRecording) {
                    await soundStop();
                    setState(() {});
                  } else {
                    await soundRecord();
                    setState(() {});
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(
                    (play == false)
                        ? Icons.keyboard_voice_rounded
                        : Icons.pause,
                    color: Theme.of(context).colorScheme.primary,
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
          currentUser: _chatUser,
          onSend: _sendMessage,
          messages: _messages,
        );
      },
    );
  }

  Widget _mediaMessageGallery(BuildContext context) {
    return ListTile(
      onTap: () async {
        Navigator.pop(context);
        try {
          XFile? file = await _mediaService.pickImageFromLibrary();
          if (file != null) {
            List<String> uids = widget.group.members;
            await uploadToFirebase(
                File(file.path), MessageTypeGroup.Image, uids);
          }
        } catch (e) {
          print('Error selecting or uploading image: $e');
        }
      },
      title: Icon(
        Icons.photo,
        color: Colors.redAccent,
      ),
    );
  }

  Widget _mediaMessageCamera(BuildContext context) {
    return ListTile(
      onTap: () async {
        Navigator.pop(context);
        try {
          XFile? file = await _mediaService.pickImageFromCamera();
          if (file != null) {
            List<String> uids = widget.group.members;
            await uploadToFirebase(
                File(file.path), MessageTypeGroup.Image, uids);
          }
        } catch (e) {
          print('Error capturing or uploading image: $e');
        }
      },
      title: Icon(
        Icons.camera_alt,
        color: Colors.green,
      ),
    );
  }

  Widget _mediaMessageVideoGallery(BuildContext context) {
    return ListTile(
      onTap: () async {
        Navigator.pop(context);
        try {
          XFile? file = await _mediaService.pickVideoFromLibrary();
          if (file != null) {
            List<String> uids = widget.group.members;
            await uploadToFirebase(
                File(file.path), MessageTypeGroup.Video, uids);
          }
        } catch (e) {
          print('Error selecting or uploading video: $e');
        }
      },
      title: Icon(
        Icons.video_library,
        color: Colors.orangeAccent,
      ),
    );
  }

  Widget _mediaMessageVideoCamera(BuildContext context) {
    return ListTile(
      onTap: () async {
        Navigator.pop(context);
        try {
          XFile? file = await _mediaService.pickVideoFromCamera();
          if (file != null) {
            List<String> uids = widget.group.members;
            await uploadToFirebase(
                File(file.path), MessageTypeGroup.Video, uids);
          }
        } catch (e) {
          print('Error capturing or uploading video: $e');
        }
      },
      title: Icon(
        Icons.videocam,
        color: Colors.purpleAccent,
      ),
    );
  }

  Widget _documentMessage(BuildContext context) {
    return ListTile(
      onTap: () async {
        await uploadFile();
      },
      title: Icon(
        Icons.file_present,
        color: Colors.blue,
      ),
    );
  }

  String? getUserNameById(String userId) {
    final user = widget.userProfiles.firstWhere(
      (user) => user.uid == userId,
      orElse: () => UserProfile(uid: userId, name: ''),
    );
    return user.name;
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final ChatUser chatUser;
  final DateTime dateTime;

  const FullScreenVideoPlayer({
    required this.videoUrl,
    required this.chatUser,
    required this.dateTime,
  });

  @override
  _FullScreenVideoPlayerState createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late vp.VideoPlayerController _controller;
  vp.VideoPlayerValue? _videoValue;
  final GetIt _getIt = GetIt.instance;
  late AlertService _alertService;
  double _progress = 0.0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _controller = vp.VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _controller.play();
          _videoValue = _controller.value;
        });
      });

    _controller.addListener(() {
      setState(() {
        _videoValue = _controller.value;
      });
    });

    _alertService = _getIt.get<AlertService>();
  }

  @override
  void dispose() {
    _controller.removeListener(() {});
    _controller.dispose();
    super.dispose();
  }

  Future<void> _downloadVideo(String url) async {
    try {
      setState(() {
        _isDownloading = true;
        _progress = 0.0;
      });

      FileDownloader.downloadFile(
        url: url,
        // onProgress: (progress) {
        //   // Update progress
        //   print("Download progress: $progress%");
        //   setState(() {
        //     _progress = progress.toDouble();
        //   });
        // },
        onDownloadCompleted: (filePath) async {
          if (filePath != null) {
            final compressedVideo = await VideoCompress.compressVideo(
              filePath,
              quality: VideoQuality.LowQuality,
              deleteOrigin: true,
            );

            if (compressedVideo != null) {
              setState(() {
                _alertService.showToast(
                  text: 'download_video'.tr() + '${compressedVideo.file!.path}',
                  icon: Icons.check,
                  color: Colors.green,
                );
              });
            } else {
              print('Gagal mengompresi video');
            }
          } else {
            setState(() {
              _alertService.showToast(
                text: 'failed_download_video'.tr(),
                icon: Icons.error,
                color: Colors.red,
              );
            });
          }
        },
        onDownloadError: (error) {
          setState(() {
            _alertService.showToast(
              text: 'failed_download_video'.tr(),
              icon: Icons.error,
              color: Colors.red,
            );
          });
        },
      );
    } catch (e) {
      print("Error: $e");
      setState(() {
        _alertService.showToast(
          text: 'failed_download_video'.tr(),
          icon: Icons.error,
          color: Colors.red,
        );
      });
    } finally {
      setState(() {
        _isDownloading = false;
        _progress = 0.0;
      });
    }
  }

  // Future<void> _downloadVideo(String url) async {
  //   try {
  //     var dio = Dio();
  //     var tempDir = await getTemporaryDirectory();
  //     String fullPath = '${tempDir.path}/video.mp4';
  //     setState(() {
  //       _isDownloading = true;
  //     });
  //     await dio.download(
  //       url,
  //       fullPath,
  //       onReceiveProgress: (received, total) {
  //         if (total != -1) {
  //           double progress = (received / total * 100);
  //           print("Download progress: $progress%");
  //           setState(() {
  //             _progress = progress;
  //           });
  //         }
  //       },
  //     );
  //     File file = File(fullPath);
  //     if (await file.exists()) {
  //       final result = await ImageGallerySaver.saveFile(file.path);
  //       if (result['isSuccess']) {
  //         setState(() {
  //           _alertService.showToast(
  //             text: 'Video downloaded successfully',
  //             icon: Icons.check,
  //             color: Colors.green,
  //           );
  //         });
  //       } else {
  //         setState(() {
  //           _alertService.showToast(
  //             text: 'Failed to save video to gallery',
  //             icon: Icons.error,
  //             color: Colors.red,
  //           );
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     print(e);
  //     setState(() {
  //       _alertService.showToast(
  //         text: 'Failed to download video $e',
  //         icon: Icons.error,
  //         color: Colors.red,
  //       );
  //     });
  //   } finally {
  //     setState(() {
  //       _isDownloading = false;
  //       _progress = 0.0;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final duration = _videoValue?.duration ?? Duration.zero;
    final position = _videoValue?.position ?? Duration.zero;
    final isPlaying = _videoValue?.isPlaying ?? false;
    DateTime date =
        DateFormat('yyyy-MM-dd hh:mm').parse(widget.dateTime.toString());
    String day = DateFormat('yyyy-MM-dd HH:mm').format(date);
    return Scaffold(
      backgroundColor: Colors.white,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatUser.firstName!,
              style: StyleText(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              day,
              style: StyleText(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await _downloadVideo(widget.videoUrl);
            },
            icon: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _isDownloading
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 27,
                          height: 27,
                          child: CircularProgressIndicator(
                            value: _progress / 100,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2.0,
                            key: ValueKey<int>(1),
                          ),
                        ),
                        Text(
                          '${_progress.toStringAsFixed(0)}%',
                          style: StyleText(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Icon(
                      Icons.file_download_outlined,
                      color: Colors.white,
                      key: ValueKey<int>(0),
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _controller.value.isInitialized
                  ? Stack(
                      children: [
                        vp.VideoPlayer(_controller),
                        if (_controller.value.isInitialized)
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isPlaying
                                      ? _controller.pause()
                                      : _controller.play();
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isPlaying
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.white,
                                ),
                                padding: EdgeInsets.all(16.0),
                                child: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.black,
                                  size: 40.0,
                                ),
                              ),
                            ),
                          ),
                        if (_controller.value.isInitialized)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: StyleText(),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: StyleText(),
                                    ),
                                  ],
                                ),
                              ),
                              ValueListenableBuilder(
                                valueListenable: _controller,
                                builder:
                                    (context, VideoPlayerValue value, child) {
                                  return Slider(
                                    value: value.position.inSeconds
                                        .toDouble()
                                        .clamp(
                                            0.0,
                                            value.duration.inSeconds
                                                .toDouble()),
                                    min: 0.0,
                                    max: value.duration.inSeconds.toDouble(),
                                    onChanged: (newValue) {
                                      _controller.seekTo(
                                          Duration(seconds: newValue.toInt()));
                                    },
                                  );
                                },
                              ),
                              // Slider(
                              //   value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
                              //   min: 0.0,
                              //   max: duration.inSeconds.toDouble(),
                              //   onChanged: (value) {
                              //     _controller.seekTo(Duration(seconds: value.toInt()));
                              //   },
                              // ),
                            ],
                          ),
                      ],
                    )
                  : CircularProgressIndicator(), // Show loading indicator
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class FullScreenImage extends StatefulWidget {
  final ChatUser chatUser;
  final String imageUrl;
  final DateTime dateTime;

  FullScreenImage({
    required this.chatUser,
    required this.imageUrl,
    required this.dateTime,
  });

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  final GetIt _getIt = GetIt.instance;
  late AlertService _alertService;
  double _progress = 0.0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _alertService = _getIt.get<AlertService>();
  }

  Future<void> downloadImage(String url) async {
    try {
      setState(() {
        _isDownloading = true;
        _progress = 0.0;
      });

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = "${tempDir.path}/temp_image.jpg";

      await FileDownloader.downloadFile(
        url: url,
        name: "temp_image.jpg",
        onProgress: (fileName, progress) {
          setState(() {
            _progress = progress;
            print("Download progress: $progress%");
          });
        },
        onDownloadCompleted: (path) async {
          final compressedFilePath = "${tempDir.path}/compressed_image.jpg";
          final compressedFile = await FlutterImageCompress.compressAndGetFile(
            path,
            compressedFilePath,
            quality: 70,
          );

          if (compressedFile != null) {
            setState(() {
              _isDownloading = false;
              _progress = 0.0;
              _alertService.showToast(
                text: 'download_image'.tr(),
                icon: Icons.check,
                color: Colors.green,
              );
            });
          }
        },
        onDownloadError: (e) {
          setState(() {
            _isDownloading = false;
            _progress = 0.0;
            _alertService.showToast(
              text: 'failed_download_image'.tr(),
              icon: Icons.error,
              color: Colors.red,
            );
          });
        },
      );
    } catch (e) {
      print(e);
      setState(() {
        _isDownloading = false;
        _progress = 0.0;
        _alertService.showToast(
          text: 'failed_download_image'.tr(),
          icon: Icons.error,
          color: Colors.red,
        );
      });
    }
  }

  // Future<void> downloadImage(String url) async {
  //   try {
  //     var dio = Dio();
  //     var tempDir = await getTemporaryDirectory();
  //     String fullPath = tempDir.path + "/image.jpg";
  //     setState(() {
  //       _isDownloading = true;
  //     });
  //     await dio.download(
  //       url,
  //       fullPath,
  //       onReceiveProgress: (received, total) {
  //         if (total != -1) {
  //           double progress = (received / total * 100);
  //           print("Download progress: $progress%");
  //           setState(() {
  //             _progress = progress;
  //           });
  //         }
  //       },
  //     );
  //     File file = File(fullPath);
  //     if (await file.exists()) {
  //       final result = await ImageGallerySaver.saveFile(file.path);
  //       if (result['isSuccess']) {
  //         setState(() {
  //           _alertService.showToast(
  //             text: 'Image downloaded successfully',
  //             icon: Icons.check,
  //             color: Colors.green,
  //           );
  //         });
  //       } else {
  //         setState(() {
  //           _alertService.showToast(
  //             text: 'Failed to save image to gallery',
  //             icon: Icons.error,
  //             color: Colors.red,
  //           );
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     print(e);
  //     setState(() {
  //       _alertService.showToast(
  //         text: 'Failed to download image $e',
  //         icon: Icons.error,
  //         color: Colors.red,
  //       );
  //     });
  //   } finally {
  //     setState(() {
  //       _isDownloading = false;
  //       _progress = 0.0;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    DateTime date =
        DateFormat('yyyy-MM-dd hh:mm').parse(widget.dateTime.toString());
    String day = DateFormat('yyyy-MM-dd HH:mm').format(date);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatUser.firstName.toString(),
              style: StyleText(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              day,
              style: StyleText(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await downloadImage(widget.imageUrl);
            },
            icon: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _isDownloading
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 27,
                          height: 27,
                          child: CircularProgressIndicator(
                            value: _progress / 100,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2.0,
                            key: ValueKey<int>(1),
                          ),
                        ),
                        Text(
                          '${_progress.toStringAsFixed(0)}%',
                          style: StyleText(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Icon(
                      Icons.file_download_outlined,
                      color: Colors.white,
                      key: ValueKey<int>(0),
                    ),
            ),
          ),
        ],
      ),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(widget.imageUrl),
          backgroundDecoration: BoxDecoration(
            color: Colors.white,
          ),
          minScale: PhotoViewComputedScale.contained * 0.9,
          maxScale: PhotoViewComputedScale.covered * 2,
        ),
      ),
    );
  }
}

class PDFViewPage extends StatefulWidget {
  final String filePath;
  final String fileName;
  final DateTime dateTime;

  PDFViewPage({
    required this.filePath,
    required this.fileName,
    required this.dateTime,
  });

  @override
  State<PDFViewPage> createState() => _PDFViewPageState();
}

class _PDFViewPageState extends State<PDFViewPage> {
  final GetIt _getIt = GetIt.instance;
  late AlertService _alertService;
  double _progress = 0.0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _alertService = _getIt.get<AlertService>();
  }

  Future<void> _downloadAndSaveFile(String url, String fileName) async {
    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }

      Dio dio = Dio();
      String savePath = await _getFilePath(fileName);

      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print((received / total * 100).toStringAsFixed(0) + "%");
          }
        },
      );

      setState(() {
        _alertService.showToast(
          text: 'download_file'.tr(),
          icon: Icons.check,
          color: Colors.green,
        );
      });
      print('File berhasil diunduh dan disimpan ke $savePath');
    } catch (e) {
      print('--------- $e');
      setState(() {
        _alertService.showToast(
          text: 'failed_download_file'.tr(),
          icon: Icons.error,
          color: Colors.red,
        );
      });
    }
  }

  Future<String> _getFilePath(String fileName) async {
    Directory directory;

    if (Platform.isAndroid) {
      directory = (await getExternalStorageDirectory())!;
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    return '${directory.path}/$fileName';
  }

  @override
  Widget build(BuildContext context) {
    DateTime date =
        DateFormat('yyyy-MM-dd hh:mm').parse(widget.dateTime.toString());
    String day = DateFormat('yyyy-MM-dd HH:mm').format(date);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.fileName.toString(),
              style: StyleText(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              day,
              style: StyleText(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              setState(() {
                _isDownloading = true;
              });
              await _downloadAndSaveFile(widget.filePath, widget.fileName);
              setState(() {
                _isDownloading = false;
              });
            },
            icon: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _isDownloading
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: _progress / 100,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2.0,
                          key: ValueKey<int>(1),
                        ),
                        Text(
                          '${_progress.toStringAsFixed(0)}%',
                          style: StyleText(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Icon(
                      Icons.file_download_outlined,
                      color: Colors.white,
                      key: ValueKey<int>(0),
                    ),
            ),
          ),
        ],
      ),
      body: PDFView(
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: false,
        onError: (error) {
          print(error.toString());
        },
        onRender: (_pages) {
          print('Document rendered with $_pages pages');
        },
        onPageError: (page, error) {
          print('$page: ${error.toString()}');
        },
        filePath: widget.filePath,
      ),
    );
  }
}
