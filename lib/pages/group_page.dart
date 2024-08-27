import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import '../main.dart';
import '../models/group.dart';
import '../models/user_profile.dart';
import '../service/alert_service.dart';
import '../service/auth_service.dart';
import '../service/database_service.dart';
import '../service/media_service.dart';
import '../service/storage_service.dart';
import 'detailGroup_page.dart';

class GroupPage extends StatefulWidget {
  final Group group;
  final List<UserProfile> users;

  GroupPage({required this.group, required this.users});

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

    initializeNotifications();
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

  // void _loadMessages() {
  //   _firestore
  //       .collection('messagesGroup')
  //       .where('groupId', isEqualTo: widget.group.id)
  //       .orderBy('createdAt', descending: true)
  //       .snapshots()
  //       .listen((snapshot) {
  //     List<ChatMessage> newMessages = [];
  //     for (var doc in snapshot.docs) {
  //       newMessages.add(ChatMessage.fromJson(doc.data()));
  //     }
  //     setState(() {
  //       if (newMessages.length > _messages.length) {
  //         final lastMessage = newMessages.first.text;
  //         // Display notification if there are new messages
  //         flutterLocalNotificationsPlugin.show(
  //           0,
  //           widget.group.name,
  //           lastMessage,
  //           const NotificationDetails(
  //             android: AndroidNotificationDetails(
  //               'Awokawok',
  //               'AwokAwokAwok',
  //               importance: Importance.high,
  //               priority: Priority.high,
  //             ),
  //           ),
  //         );
  //
  //         // Play sound
  //         audioPlayer.play(AssetSource('ting.mp3'));
  //       }
  //       _messages = newMessages;
  //     });
  //     _scrollToBottom();
  //   });
  // }

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

            // Play sound
            audioPlayer.play(AssetSource('ting.mp3'));
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

  // void _loadMessages() {
  //   _firestore
  //       .collection('messagesGroup')
  //       .where('groupId', isEqualTo: widget.group.id)
  //       .orderBy('createdAt', descending: true)
  //       .snapshots()
  //       .listen((snapshot) {
  //     List<ChatMessage> messages = [];
  //     for (var doc in snapshot.docs) {
  //       messages.add(ChatMessage.fromJson(doc.data()));
  //     }
  //     setState(() {
  //       _messages = messages;
  //     });
  //     _scrollToBottom();
  //   });
  // }

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
    WidgetsBinding.instance!.addPostFrameCallback((_) {
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

  // Future<void> uploadToFirebase(
  //     File file, MessageTypeGroup messageType, List<String> uids) async {
  //   try {
  //     FirebaseStorage storage = FirebaseStorage.instance;
  //     String fileName =
  //         'mediaGroup/${DateTime.now().toIso8601String()}${p.extension(file.path)}.pdf';
  //     Reference ref = storage.ref().child(fileName);
  //     UploadTask uploadTask = ref.putFile(file);
  //
  //     uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
  //       print(
  //           'Progres upload: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
  //     });
  //
  //     TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
  //
  //     String downloadURL = await taskSnapshot.ref.getDownloadURL();
  //
  //     ChatMessage message;
  //     if (messageType == MessageTypeGroup.Document) {
  //       message = ChatMessage(
  //         user: _chatUser,
  //         createdAt: DateTime.now(),
  //         medias: [
  //           ChatMedia(
  //             url: downloadURL,
  //             fileName: 'File',
  //             type: MediaType.file,
  //           ),
  //         ],
  //       );
  //     } else {
  //       message = ChatMessage(
  //         user: _chatUser,
  //         createdAt: DateTime.now(),
  //         medias: [
  //           ChatMedia(
  //             url: downloadURL,
  //             fileName: '',
  //             type: MediaType.image,
  //           ),
  //         ],
  //       );
  //     }
  //
  //     _sendMessage(message);
  //   } catch (e) {
  //     print('Error saat mengupload file: $e');
  //   }
  // }

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
      text: 'Chat cleared successfully',
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
        text: 'You have left the group',
        icon: Icons.check,
        color: Colors.green,
      );
      Navigator.pop(context);
    } catch (e) {
      print("Failed to leave group: $e");
      _alertService.showToast(
        text: e.toString(),
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
      String filePath = '$tempPath/${fileName}_${dateTime.toIso8601String()}.pdf';
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

  Map<ChatMessage, String> messageIdMap = {};
  void _showDeleteDialog(BuildContext context, ChatMessage message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          actionsPadding: EdgeInsets.only(top: 1, bottom: 5, right: 10),
          title: Text('Delete Message',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
          content: Text(
            'Are you sure you want to delete this message?',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () {
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
                try {
                  await _firestore
                      .collection('messagesGroup')
                      .doc(message.user.id)
                      .delete();

                  setState(() {
                    _messages.remove(message);
                    messageIdMap.remove(message);
                  });

                  Navigator.pop(context);
                } catch (e) {
                  print('Error deleting message: $e');
                  _alertService.showToast(
                    text: e.toString(),
                    icon: Icons.error,
                    color: Colors.red,
                  );
                }
              },
              child: Text(
                'Yes',
                style: GoogleFonts.poppins().copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
    print('STOP RECORDDDDDDDDDD');
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
      String fileName = 'audioGroup/${DateTime.now().toIso8601String()}${p.extension(file.path)}.aac';
      Reference ref = storage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(file);
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
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
    } catch (e) {
      print('Error uploading audio file: $e');
    }
  }

  // void _sendMessageWithAudio(String audioUrl) {
  //   ChatMessage message = ChatMessage(
  //     text: 'Voice message',
  //     user: _chatUser,
  //     customProperties: {'audioUrl': audioUrl},
  //     createdAt: DateTime.now(),
  //   );
  //   _firestore.collection('messagesGroup').add(message.toJson());
  // }

  Future initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw 'Microphone permissions not granted';
    }
    await recorder.openRecorder();
    recorder.setSubscriptionDuration(const Duration(milliseconds: 500));
  }

  // void _playAudio(String url) async {
  //   final AudioPlayer audioPlayer = AudioPlayer();
  //   await audioPlayer.play(UrlSource(url)).then((_) {
  //     print('Audio started playing');
  //   }).catchError((error) {
  //     print('Error playing audio: $error');
  //   });
  // }

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  @override
  Widget build(BuildContext context) {
    List<String> memberNames = widget.group.members.map((memberId) {
      final user = widget.users.firstWhere(
        (user) => user.uid == memberId,
        orElse: () => UserProfile(
          uid: memberId,
          name: 'You',
        ),
      );
      return user.name ?? 'You';
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
                  users: widget.users,
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _isVisible
                          ? 'Click here for group info'
                          : memberNames.join(", "),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                    // SizedBox(height: 4),
                    // Text(
                    //   _isInGroup ? 'Online' : 'Offline',
                    //   style: TextStyle(fontSize: 14, color: Colors.green),
                    // ),
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
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.call,
              color: Colors.white,
            ),
            onPressed: () async {
              String phoneNumber = await _databaseService
                  .getPhoneNumberFromFirestore(otherUser!.id);
              await launchPhoneCall(phoneNumber);
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
          "You have left the group",
          style: TextStyle(fontSize: 15, color: Colors.grey),
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

        // final newMessages = snapshot.data!.docs;
        // if (newMessages.isNotEmpty) {
        //   // Display notification
        //   flutterLocalNotificationsPlugin.show(
        //     0,
        //     widget.group.name,
        //     'Anda memiliki pesan baru di grup',
        //     const NotificationDetails(
        //       android: AndroidNotificationDetails(
        //         'Awokawok',
        //         'AwokAwokAwok',
        //         importance: Importance.high,
        //         priority: Priority.high,
        //       ),
        //     ),
        //   );
        //
        //   // Play sound
        //   audioPlayer.play(AssetSource('ting.mp3'));
        // }

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
            textBeforeMedia: false,
            showOtherUsersName: false,
            showCurrentUserAvatar: false,
            showOtherUsersAvatar: false,
            messageDecorationBuilder: (ChatMessage message,
                ChatMessage? previousMessage, ChatMessage? nextMessage) {
              bool isUser = message.user.id == currentUser!.id;
              return BoxDecoration(
                color: isUser ? Colors.deepPurple.shade200 : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              );
            },
            messageTextBuilder: (ChatMessage message,
                ChatMessage? previousMessage, ChatMessage? nextMessage) {
              bool isUser = message.user.id == currentUser!.id;
              String? userName = getUserNameById(message.user.id);
              String? audioUrl = message.customProperties?['audioUrl'];
              print('------- VOICE NOTE ------- $audioUrl');
              return Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    Container(
                      width: MediaQuery.sizeOf(context).width,
                      child: Text(
                        userName ?? '-',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.deepPurple.shade200,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerRight,
                    child: Text(
                      DateFormat('HH:mm').format(message.createdAt),
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 11,
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
              }
            },
          ),
          inputOptions: InputOptions(
            alwaysShowSend: true,
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


    // return StreamBuilder(
    //   stream: _firestore
    //       .collection('messagesGroup')
    //       .where('groupId', isEqualTo: widget.group.id)
    //       .snapshots(),
    //   builder: (context, snapshot) {
    //     if (!snapshot.hasData ||
    //         snapshot.data == null ||
    //         widget.group.members.isEmpty) {
    //       return Container();
    //     }
    //
    //     return DashChat(
    //       quickReplyOptions: QuickReplyOptions(),
    //       messageListOptions: MessageListOptions(
    //         separatorFrequency: SeparatorFrequency.days,
    //         showFooterBeforeQuickReplies: true,
    //         showDateSeparator: true,
    //         scrollController: _scrollController,
    //         scrollPhysics: AlwaysScrollableScrollPhysics(),
    //       ),
    //       messageOptions: MessageOptions(
    //         maxWidth: 250,
    //         textBeforeMedia: false,
    //         showOtherUsersName: false,
    //         showCurrentUserAvatar: false,
    //         showOtherUsersAvatar: false,
    //         messageDecorationBuilder: (ChatMessage message,
    //             ChatMessage? previousMessage, ChatMessage? nextMessage) {
    //           bool isUser = message.user.id == currentUser!.id;
    //           return BoxDecoration(
    //             color: isUser ? Colors.deepPurple.shade200 : Colors.grey[300],
    //             borderRadius: BorderRadius.circular(12),
    //           );
    //         },
    //         messageTextBuilder: (ChatMessage message,
    //             ChatMessage? previousMessage, ChatMessage? nextMessage) {
    //           bool isUser = message.user.id == currentUser!.id;
    //           String? userName = getUserNameById(message.user.id);
    //           String? audioUrl = message.customProperties?['audioUrl'];
    //           print('------- VOICE NOTE ------- $audioUrl');
    //           return Column(
    //             crossAxisAlignment: isUser
    //                 ? CrossAxisAlignment.end
    //                 : CrossAxisAlignment.start,
    //             children: [
    //               if (!isUser)
    //                 Container(
    //                   width: MediaQuery.sizeOf(context).width,
    //                   child: Text(
    //                     userName ?? '-',
    //                     overflow: TextOverflow.ellipsis,
    //                     style: TextStyle(
    //                       color: Colors.deepPurple.shade200,
    //                       fontSize: 15,
    //                       fontWeight: FontWeight.bold,
    //                     ),
    //                   ),
    //                 ),
    //               // if (audioUrl != null && audioUrl.isNotEmpty)
    //               //   GestureDetector(
    //               //     onTap: () async {
    //               //       if (currentAudioUrl == audioUrl && audioPlayer.state == PlayerState.playing) {
    //               //         await audioPlayer.pause();
    //               //         setState(() {
    //               //           currentAudioUrl = null;
    //               //         });
    //               //       } else {
    //               //         if (currentAudioUrl != null) {
    //               //           await audioPlayer.stop();
    //               //         }
    //               //         await audioPlayer.play(UrlSource(audioUrl));
    //               //         setState(() {
    //               //           currentAudioUrl = audioUrl;
    //               //         });
    //               //       }
    //               //     },
    //               //     child: Container(
    //               //       color: Colors.red,
    //               //       child: Icon(
    //               //         currentAudioUrl == audioUrl && audioPlayer.state == PlayerState.playing ? Icons.pause : Icons.play_arrow,
    //               //         color: Colors.deepPurple.shade200,
    //               //       ),
    //               //     ),
    //               //   ),
    //               Container(
    //                 alignment: Alignment.centerLeft,
    //                 child: Text(
    //                   message.text,
    //                   style: TextStyle(
    //                     fontSize: 14,
    //                     color: Colors.black87,
    //                   ),
    //                 ),
    //               ),
    //               // if (audioUrl != null && audioUrl.isNotEmpty) ...[
    //               //   SizedBox(height: 5),
    //               //   IconButton(onPressed: () {}, icon: Icon(Icons.play_arrow)),
    //               // ],
    //               Container(
    //                 alignment: Alignment.centerRight,
    //                 child: Text(
    //                   DateFormat('HH:mm').format(message.createdAt),
    //                   style: TextStyle(
    //                     color: Colors.black87,
    //                     fontSize: 11,
    //                   ),
    //                 ),
    //               ),
    //             ],
    //           );
    //         },
    //         showTime: true,
    //         onLongPressMessage: (ChatMessage message) {
    //           _showDeleteDialog(context, message);
    //         },
    //         onTapMedia: (media) async {
    //           if (media.type == MediaType.image) {
    //             Navigator.push(
    //               context,
    //               MaterialPageRoute(
    //                 builder: (context) => FullScreenImage(
    //                   imageUrl: media.url,
    //                   chatUser: otherUser!,
    //                   dateTime: media.uploadedDate ?? DateTime.now(),
    //                 ),
    //               ),
    //             );
    //           } else if (media.type == MediaType.file) {
    //             final Uri url = Uri.parse(media.url);
    //             String fileName = media.fileName ?? 'File';
    //             DateTime dateTime = media.uploadedDate ?? DateTime.now();
    //             await _downloadAndOpenPDF(url.toString(), fileName, dateTime);
    //           }
    //         },
    //       ),
    //       inputOptions: InputOptions(
    //         alwaysShowSend: true,
    //         leading: [
    //           PopupMenuButton(
    //             icon: Icon(
    //               Icons.add,
    //               color: Theme.of(context).colorScheme.primary,
    //             ),
    //             itemBuilder: (context) => [
    //               PopupMenuItem(
    //                 child: _mediaMessageGallery(context),
    //               ),
    //               PopupMenuItem(
    //                 child: _mediaMessageCamera(context),
    //               ),
    //               PopupMenuItem(
    //                 child: _documentMessage(context),
    //               ),
    //               PopupMenuItem(
    //                 child: _mediaMessageVideoGallery(context),
    //               ),
    //               PopupMenuItem(
    //                 child: _mediaMessageVideoCamera(context),
    //               ),
    //             ],
    //           ),
    //           GestureDetector(
    //             onTap: () async {
    //               setState(() {
    //                 play = !play;
    //               });
    //               if (recorder.isRecording) {
    //                 await soundStop();
    //                 setState(() {});
    //               } else {
    //                 await soundRecord();
    //                 setState(() {});
    //               }
    //             },
    //             child: Container(
    //               color: Colors.transparent,
    //               padding: EdgeInsets.only(right: 10),
    //               child: Icon(
    //                 (play == false)
    //                     ? Icons.keyboard_voice_rounded
    //                     : Icons.pause,
    //                 color: Theme.of(context).colorScheme.primary,
    //                 size: 21,
    //               ),
    //             ),
    //           ),
    //         ],
    //       ),
    //       currentUser: _chatUser,
    //       onSend: _sendMessage,
    //       messages: _messages,
    //     );
    //   },
    // );
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
            await uploadToFirebase(File(file.path), MessageTypeGroup.Video, uids);
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
            await uploadToFirebase(File(file.path), MessageTypeGroup.Video, uids);
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
    final user = widget.users.firstWhere(
      (user) => user.uid == userId,
      orElse: () => UserProfile(uid: userId, name: ''),
    );
    return user.name;
  }
}

class FullScreenImage extends StatelessWidget {
  final ChatUser chatUser;
  final String imageUrl;
  final DateTime dateTime;

  FullScreenImage({
    required this.chatUser,
    required this.imageUrl,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    DateTime date = DateFormat('yyyy-MM-dd hh:mm').parse(dateTime.toString());
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
              chatUser.firstName.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              day,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
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

class PDFViewPage extends StatelessWidget {
  final String filePath;
  final String fileName;
  final DateTime dateTime;

  PDFViewPage({
    required this.filePath,
    required this.fileName,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    DateTime date = DateFormat('yyyy-MM-dd hh:mm').parse(dateTime.toString());
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
              fileName.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              day,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
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
        filePath: filePath,
      ),
    );
  }
}
