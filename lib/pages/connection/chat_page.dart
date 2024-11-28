import 'dart:convert';
import 'dart:io';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:chating/models/user_profile.dart';
import 'package:chating/pages/connection/videoCall.dart';
import 'package:chating/service/media_service.dart';
import 'package:chating/service/storage_service.dart';
import 'package:chating/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../models/chat.dart';
import '../../models/message.dart' as chat;
import '../../models/message.dart';
import '../../service/alert_service.dart';
import '../../service/auth_service.dart';
import '../../service/database_service.dart';
import 'audioCall.dart';
import '../detailProfile_page.dart';
import 'package:http/http.dart' as http;

import 'detail_media.dart';

class ChatPage extends StatefulWidget {
  final UserProfile chatUser;

    ChatPage({
    super.key,
    required this.chatUser,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final GetIt _getIt = GetIt.instance;
  late AlertService _alertService;
  late AuthService _authService;
  late DatabaseService _databaseService;
  late MediaService _mediaService;
  late StorageService _storageService;
  ChatUser? currentUser, otherUser;
  bool _isVisible = false;
  late FlutterSoundRecorder recorder = FlutterSoundRecorder();
  bool play = false;
  File? audioFile;
  late AudioPlayer audioPlayer;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  String? currentAudioUrl;
  bool _showLastSeen = true;
  List<ChatMessage> messages = [];
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late FirebaseMessaging _firebaseMessaging;
  final Uuid uuid = Uuid();

  // Future<Map<String, dynamic>?> fetchToken(String channelName, int uid) async {
  //   final String url =
  //       'http://45.130.229.79:5656/vc-token?channelName=${channelName}&uid=${uid}';

  //   try {
  //     final response = await http.get(Uri.parse(url));
  //
  //     if (response.statusCode == 200) {
  //       print('Response body: ${response.body}');
  //
  //       final data = jsonDecode(response.body);
  //
  //       print('Decoded JSON response: $data');
  //
  //       if (data['uid'] is String) {
  //         data['uid'] = int.tryParse(data['uid']) ?? 0;
  //       }
  //
  //       return data;
  //     } else {
  //       print('Error: ${response.statusCode}');
  //       return null;
  //     }
  //   } catch (e) {
  //     print('Exception: $e');
  //     return null;
  //   }
  // }
  //
  // void _startVideoCall(String channelName, int uid) async {
  //   Map<String, dynamic>? data = await fetchToken(channelName, uid);
  //
  //   if (data != null) {
  //     int userUid = data['uid'] is int
  //         ? data['uid']
  //         : int.tryParse(data['uid'].toString()) ?? 0;
  //
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => VideoCallScreen(
  //           userProfile: widget.chatUser,
  //           token: data['token'],
  //           channelName: data['channelName'],
  //           uid: userUid,
  //         ),
  //       ),
  //     );
  //   } else {
  //     print('Gagal mendapatkan data');
  //   }
  // }

  // Future<String> _getPhoneNumber(String userId) async {
  //   var firestore = FirebaseFirestore.instance;
  //   var userDoc = await firestore.collection('users').doc(userId).get();
  //   return userDoc.data()!['phoneNumber'] ?? '';
  // }

  void _startVideoCall() async {
    // String phoneNumber = await _getPhoneNumber(widget.chatUser.uid!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(userProfile: widget.chatUser),
      ),
    );
  }

  void _startAudioCall() async {
    // String phoneNumber = await _getPhoneNumber(widget.chatUser.uid!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioCallScreen(userProfile: widget.chatUser),
      ),
    );
  }

  @override
  void initState() {
    _firebaseMessaging = FirebaseMessaging.instance;

    _firebaseMessaging.getToken().then((token) {
      print("FCM Token: $token");
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print('Message received: ${message.notification!.title}');
      }
    });

    super.initState();

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
      InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    audioPlayer = AudioPlayer();

    _authService = _getIt.get<AuthService>();
    _alertService = _getIt.get<AlertService>();
    _databaseService = _getIt.get<DatabaseService>();
    _mediaService = _getIt.get<MediaService>();
    _storageService = _getIt.get<StorageService>();
    currentUser = ChatUser(
      id: _authService.user!.uid,
      firstName: _authService.user!.displayName,
    );
    otherUser = ChatUser(
      id: widget.chatUser.uid!,
      firstName: widget.chatUser.name,
      profileImage: widget.chatUser.pfpURL,
    );
    _showTextAfterDelay();
    recorder = FlutterSoundRecorder();
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

    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showLastSeen = false;
        });
      }
    });

    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showLastSeen = false;
        });
      }
    });
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    audioPlayer.dispose();
    super.dispose();
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

  Future<void> uploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        await uploadToFirebase(file);
      } else {
        print('Pengguna membatalkan pemilihan file.');
      }
    } catch (e) {
      print('Error saat memilih file: $e');
    }
  }

  // Future<void> uploadToFirebase(File file) async {
  //   try {
  //     FirebaseStorage storage = FirebaseStorage.instance;
  //     String fileName =
  //         'mediaUsers/${DateTime.now().toIso8601String()}${p.extension(file.path)}';
  //     Reference ref = storage.ref().child(fileName);
  //     UploadTask uploadTask = ref.putFile(file);
  //     uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
  //       print(
  //           'Progres upload: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100} %');
  //     });
  //
  //     TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
  //
  //     String downloadURL = await taskSnapshot.ref.getDownloadURL();
  //
  //     print('File berhasil diupload. URL unduhan: $downloadURL');
  //
  //     chat.Message message = chat.Message(
  //       senderID: currentUser!.id,
  //       content: downloadURL,
  //       messageType: MessageType.Document,
  //       sentAt: Timestamp.now(),
  //       isRead: false,
  //     );
  //     await _databaseService.sendChatMessage(
  //       currentUser!.id,
  //       otherUser!.id,
  //       message,
  //     );
  //   } catch (e) {
  //     print('Error saat mengupload file: $e');
  //   }
  // }

  Future<void> uploadToFirebase(File file) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      String fileName =
          'mediaUsers/${DateTime.now().toIso8601String()}${p.extension(file.path)}';
      Reference ref = storage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(file);
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print(
            'Progres upload: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100} %');
      });

      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);

      String downloadURL = await taskSnapshot.ref.getDownloadURL();
      print('File berhasil diupload. URL unduhan: $downloadURL');

      // Generate a unique ID for the message
      String messageId = FirebaseFirestore.instance.collection('messages').doc().id;

      chat.Message message = chat.Message(
        id: messageId,
        senderID: currentUser!.id,
        content: downloadURL,
        messageType: MessageType.Document,
        sentAt: Timestamp.now(),
        isRead: false,
      );
      await _databaseService.sendChatMessage(
        currentUser!.id,
        otherUser!.id,
        message,
      );
    } catch (e) {
      print('Error saat mengupload file: $e');
    }
  }

  Future<void> _downloadAndOpenPDF(
      String url, String fileName, DateTime dateTime) async {
    try {
      Dio dio = Dio();
      var tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;
      String filePath = '$tempPath/temp.pdf';

      await dio.download(url, filePath);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewScreen(
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

  void _showPopup(BuildContext context, ChatMessage message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Popup",
      pageBuilder: (context, animation1, animation2) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'del'.tr(),
                  style: StyleText(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'desk_del'.tr(),
                  style: StyleText(fontSize: 15),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'no'.tr(),
                        style: StyleText(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        side: BorderSide(
                          width: 1,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _deleteMessage(message.user.id);
                      },
                      child: Text(
                        'yes'.tr(),
                        style: StyleText(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    if (currentUser == null || otherUser == null) return;

    try {
      await _databaseService.deleteChatMessage(
        currentUser!.id,
        otherUser!.id,
        messageId,
      );
      print("Pesan berhasil dihapus: $messageId");
    } catch (e) {
      print("Error menghapus pesan: $e");
    }
  }

  void deleteAllMessages() {
    setState(() {
      messages.clear();
    });
  }

  Future soundRecord() async {
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

  // Future<void> uploadAudioToFirebase(File file) async {
  //   try {
  //     FirebaseStorage storage = FirebaseStorage.instance;
  //     String fileName =
  //         'audio/${DateTime.now().toIso8601String()}${p.extension(file.path)}.aac';
  //     Reference ref = storage.ref().child(fileName);
  //     UploadTask uploadTask = ref.putFile(file);
  //     uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
  //       print(
  //           'Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
  //     });
  //
  //     TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
  //     String downloadURL = await taskSnapshot.ref.getDownloadURL();
  //     print('Audio file uploaded successfully. Download URL: $downloadURL');
  //
  //     chat.Message message = chat.Message(
  //       senderID: currentUser!.id,
  //       content: downloadURL,
  //       messageType: MessageType.Audio,
  //       sentAt: Timestamp.now(),
  //       isRead: false,
  //     );
  //     await _databaseService.sendChatMessage(
  //       currentUser!.id,
  //       otherUser!.id,
  //       message,
  //     );
  //   } catch (e) {
  //     print('Error uploading audio file: $e');
  //   }
  // }

  Future<void> uploadAudioToFirebase(File file) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      String fileName =
          'audio/${DateTime.now().toIso8601String()}${p.extension(file.path)}.aac';
      Reference ref = storage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(file);
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print(
            'Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
      });

      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      String downloadURL = await taskSnapshot.ref.getDownloadURL();
      print('Audio file uploaded successfully. Download URL: $downloadURL');

      // Generate a unique ID for the message
      String messageId = FirebaseFirestore.instance.collection('messages').doc().id;

      chat.Message message = chat.Message(
        id: messageId,
        senderID: currentUser!.id,
        content: downloadURL,
        messageType: MessageType.Audio,
        sentAt: Timestamp.now(),
        isRead: false,
      );
      await _databaseService.sendChatMessage(
        currentUser!.id,
        otherUser!.id,
        message,
      );
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
    recorder.setSubscriptionDuration(  Duration(milliseconds: 500));
  }

  Future<void> _showNotification(String message) async {
      AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

      NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'New Message',
      message,
      platformChannelSpecifics,
      payload: message,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                builder: (context) => DetailprofilePage(
                  chatUser: widget.chatUser,
                  onDeleteMessages: deleteAllMessages,
                ),
              ),
            );
          },
          child: Container(
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 37,
                  height: 37,
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(widget.chatUser.pfpURL!),
                  ),
                ),
                SizedBox(width: 15),
                Container(
                  width: MediaQuery.of(context).size.width - 236,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chatUser.name.toString(),
                        overflow: TextOverflow.ellipsis,
                        style: StyleText(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _isVisible
                          ? Text(
                              'info'.tr(),
                              style: StyleText(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            )
                          : _showLastSeen
                              ? lastSeen()
                              : Container(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.videocam,
              color: Colors.white,
            ),
            onPressed: () {
              _startVideoCall();
              // _startVideoCall(channel,
              //     int.tryParse(widget.chatUser.phoneNumber.toString()) ?? 0);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.call,
              color: Colors.white,
            ),
            onPressed: _startAudioCall,
          ),
        ],
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return StreamBuilder(
      stream: _databaseService.getChatData(currentUser!.id, otherUser!.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) return Container();

        Chat? chat = snapshot.data!.data();
        List<ChatMessage> messages = chat?.messages != null
            ? _generateChatMessageList(chat!.messages!)
            : [];

        if (messages.isNotEmpty) {
          ChatMessage latestMessage = messages.first;
          bool isNewMessage = latestMessage.createdAt.isAfter(
            DateTime.now().subtract(Duration(milliseconds: 500)),
          );

          if (isNewMessage && latestMessage.user.id != currentUser!.id) {
            _showNotification(latestMessage.text);
          }
        }

        return DashChat(
          quickReplyOptions: QuickReplyOptions(),
          messageListOptions: MessageListOptions(),
          messageOptions: MessageOptions(
            maxWidth: 250,
            textBeforeMedia: true,
            showOtherUsersName: false,
            showCurrentUserAvatar: false,
            showOtherUsersAvatar: false,
            onLongPressMessage: (ChatMessage message) =>
                _showPopup(context, message),
            messageDecorationBuilder: _messageDecorationBuilder,
            messageTextBuilder: _messageTextBuilder,
            onTapMedia: _handleMediaTap,
          ),
          inputOptions: InputOptions(
            textCapitalization: TextCapitalization.sentences,
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
              _buildMediaMenu(),
              GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(
                    play ? Icons.pause : Icons.keyboard_voice_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
          currentUser: currentUser!,
          onSend: _sendMessage,
          messages: messages,
        );
      },
    );
  }

  Widget _buildMediaMenu() {
    return PopupMenuButton(
      icon: Icon(
        Icons.add,
        color: Theme.of(context).colorScheme.primary,
      ),
      itemBuilder: (context) => [
        PopupMenuItem(child: _mediaMessageGallery(context)),
        PopupMenuItem(child: _mediaMessageCamera(context)),
        PopupMenuItem(child: _buildFileUploadButton()),
        PopupMenuItem(child: _mediaMessageVideoGallery(context)),
        PopupMenuItem(child: _mediaMessageVideoCamera(context)),
      ],
    );
  }

  Widget _buildFileUploadButton() {
    return ListTile(
      onTap: () {
        Navigator.pop(context);
        uploadFile();
      },
      title: Icon(Icons.file_present, color: Colors.blue),
    );
  }

  BoxDecoration _messageDecorationBuilder(
      ChatMessage message, ChatMessage? prev, ChatMessage? next) {
    bool isUser = message.user.id == currentUser!.id;
    return BoxDecoration(
      color: isUser
          ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
          : Colors.grey[300],
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _messageTextBuilder(
      ChatMessage message, ChatMessage? prev, ChatMessage? next) {
    bool isURL(String text) {
      final Uri? uri = Uri.tryParse(text);
      return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
    }

    void _launchURL(String url) async {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri)) throw Exception('Could not launch $uri');
    }

    List<TextSpan> _buildTextSpans(String text) {
      final List<TextSpan> spans = [];
      final RegExp urlPattern = RegExp(r'(https?://[^\s]+)');
      final Iterable<Match> matches = urlPattern.allMatches(text);
      int lastMatchEnd = 0;

      for (final Match match in matches) {
        if (match.start > lastMatchEnd) {
          spans.add(TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: StyleText(color: Colors.black87, fontSize: 15),
          ));
        }
        spans.add(TextSpan(
          text: match.group(0),
          style: StyleText(color: Colors.blue),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _launchURL(match.group(0)!),
        ));
        lastMatchEnd = match.end;
      }

      if (lastMatchEnd < text.length) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd),
          style: StyleText(color: Colors.black87, fontSize: 15),
        ));
      }
      return spans;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isURL(message.text)
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnyLinkPreview(
                    onTap: () => _launchURL(message.text),
                    link: message.text,
                    displayDirection: UIDirection.uiDirectionVertical,
                    showMultimedia: true,
                    bodyStyle: StyleText(fontSize: 12),
                    errorWidget: Container(
                      height: 100,
                      width: MediaQuery.sizeOf(context).width,
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image_rounded),
                    ),
                    errorImage: "https://google.com/",
                    borderRadius: 12,
                    removeElevation: false,
                  ),
                  SizedBox(height: 8),
                  RichText(
                    text: TextSpan(children: _buildTextSpans(message.text)),
                  ),
                ],
              )
            : RichText(
                text: TextSpan(children: _buildTextSpans(message.text)),
              ),
        Container(
          alignment: Alignment.centerRight,
          child: Text(
            DateFormat('HH:mm', context.locale.toString()).format(message.createdAt),
            style: StyleText(color: Colors.black87, fontSize: 12),
          ),
        ),
      ],
    );
  }

  void _toggleRecording() async {
    setState(() => play = !play);
    if (recorder.isRecording) {
      await soundStop();
    } else {
      await soundRecord();
    }
    setState(() {});
  }

  void _handleMediaTap(ChatMedia media) async {
    final String formattedDate = DateFormat('yyyy/MM/dd, HH:mm', context.locale.toString()).format(media.uploadedDate ?? DateTime.now());

    if (media.type == MediaType.image) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageView(
            imageUrl: media.url,
            chatUser: widget.chatUser,
            formatDate: formattedDate,
          ),
        ),
      );
    } else if (media.type == MediaType.file) {
      await _downloadAndOpenPDF(
          media.url, media.fileName, media.uploadedDate ?? DateTime.now());
    } else if (media.type == MediaType.video) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            videoUrl: media.url,
            chatUser: widget.chatUser,
            formatDate: formattedDate,
          ),
        ),
      );
    }
  }

  Widget lastSeen() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.chatUser.uid)
          .snapshots(),
      builder: (context, snapshots) {
        if (snapshots.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshots.hasData && snapshots.data != null) {
          var userProfile = snapshots.data!.data() as Map<String, dynamic>;
          bool isOnline = userProfile['isOnline'];
          Timestamp lastSeen = userProfile['lastSeen'];
          var lastSeenMessage;

          if (isOnline) {
            lastSeenMessage = 'Online';
          } else {
            DateTime lastSeenDt = lastSeen.toDate();
            DateTime now = DateTime.now();
            String formattedTime = DateFormat('HH:mm', context.locale.toString()).format(lastSeenDt);

            if (now.difference(lastSeenDt).inDays == 0) {
              lastSeenMessage = 'Last seen today at $formattedTime';
            } else if (now.difference(lastSeenDt).inDays == 1) {
              lastSeenMessage = 'Last seen yesterday at $formattedTime';
            } else {
              String formattedDate = DateFormat('yMd', context.locale.toString()).format(lastSeenDt);
              lastSeenMessage = 'Last seen $formattedDate at $formattedTime';
            }
          }

          return Text(
            lastSeenMessage,
            style: StyleText(
              color: Colors.white,
              fontSize: 11,
            ),
          );
        }

        return Center(
          child: Text(
            'data_available'.tr(),
            style: StyleText(color: Colors.grey),
          ),
        );
      },
    );
  }

  Future<void> _sendMessage(ChatMessage chatMessage) async {
    if (currentUser == null || otherUser == null) {
      print("Error: Users are not initialized");
      return;
    }

    String messageId = uuid.v4();
    String senderID = chatMessage.user.id ?? 'unknown_sender';
    print('AIDI: ${messageId}');
    chat.Message message;

    if (chatMessage.medias != null && chatMessage.medias!.isNotEmpty) {
      MediaType type = chatMessage.medias!.first.type;
      message = chat.Message(
        id: messageId,
        senderID: senderID,
        content: chatMessage.medias!.first.url ?? '',
        messageType: type == MediaType.image
            ? MessageType.Image
            : type == MediaType.video
                ? MessageType.Video
                : MessageType.Document,
        sentAt: Timestamp.fromDate(chatMessage.createdAt),
        isRead: false,
      );
    } else {
      String messageText = chatMessage.text ?? '';
      message = chat.Message(
        id: messageId,
        senderID: senderID,
        content: messageText,
        messageType: MessageType.Text,
        sentAt: Timestamp.fromDate(chatMessage.createdAt),
        isRead: false,
      );
    }

    try {
      await _databaseService.sendChatMessage(
        currentUser!.id,
        otherUser!.id,
        message,
      );
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // Future<void> _sendMessage(ChatMessage chatMessage) async {
  //   if (chatMessage.medias != null && chatMessage.medias!.isNotEmpty) {
  //     if (chatMessage.medias!.first.type == MediaType.image) {
  //       chat.Message message = chat.Message(
  //         senderID: chatMessage.user.id,
  //         content: chatMessage.medias!.first.url,
  //         messageType: MessageType.Image,
  //         sentAt: Timestamp.fromDate(chatMessage.createdAt),
  //         isRead: false,
  //       );
  //       await _databaseService.sendChatMessage(
  //         currentUser!.id,
  //         otherUser!.id,
  //         message,
  //       );
  //     } else if (chatMessage.medias!.first.type == MediaType.file) {
  //       chat.Message message = chat.Message(
  //         senderID: chatMessage.user.id,
  //         content: chatMessage.medias!.first.url,
  //         messageType: MessageType.Document,
  //         sentAt: Timestamp.fromDate(chatMessage.createdAt),
  //         isRead: false,
  //       );
  //       await _databaseService.sendChatMessage(
  //         currentUser!.id,
  //         otherUser!.id,
  //         message,
  //       );
  //     } else if (chatMessage.medias!.first.type == MediaType.video) {
  //       chat.Message message = chat.Message(
  //         senderID: chatMessage.user.id,
  //         content: chatMessage.medias!.first.url,
  //         messageType: MessageType.Video,
  //         sentAt: Timestamp.fromDate(chatMessage.createdAt),
  //         isRead: false,
  //       );
  //       await _databaseService.sendChatMessage(
  //         currentUser!.id,
  //         otherUser!.id,
  //         message,
  //       );
  //     }
  //   } else {
  //     chat.Message message = chat.Message(
  //       senderID: currentUser!.id,
  //       content: chatMessage.text,
  //       messageType: MessageType.Text,
  //       sentAt: Timestamp.fromDate(chatMessage.createdAt),
  //       isRead: false,
  //     );
  //     await _databaseService.sendChatMessage(
  //       currentUser!.id,
  //       otherUser!.id,
  //       message,
  //     );
  //   }
  // }

  List<ChatMessage> _generateChatMessageList(List<chat.Message> messages) {
    List<ChatMessage> chatMessages = messages.map((e) {
      if (e.messageType == MessageType.Image) {
        return ChatMessage(
          status: MessageStatus.sent,
          user: e.senderID == currentUser!.id ? currentUser! : otherUser!,
          createdAt: e.sentAt!.toDate(),
          medias: [
            ChatMedia(
              uploadedDate: e.sentAt!.toDate(),
              url: e.content!,
              fileName: "",
              type: MediaType.image,
            ),
          ],
        );
      } else if (e.messageType == MessageType.Document) {
        return ChatMessage(
          status: MessageStatus.received,
          user: e.senderID == currentUser!.id ? currentUser! : otherUser!,
          createdAt: e.sentAt!.toDate(),
          medias: [
            ChatMedia(
              uploadedDate: e.sentAt!.toDate(),
              url: e.content!,
              fileName: "File",
              type: MediaType.file,
            ),
          ],
        );
      } else if (e.messageType == MessageType.Audio) {
        return ChatMessage(
          status: MessageStatus.read,
          user: e.senderID == currentUser!.id ? currentUser! : otherUser!,
          text: "Audio message",
          createdAt: e.sentAt!.toDate(),
          customProperties: {"audioUrl": e.content},
        );
      } else if (e.messageType == MessageType.Video) {
        return ChatMessage(
          status: MessageStatus.sent,
          user: e.senderID == currentUser!.id ? currentUser! : otherUser!,
          createdAt: e.sentAt!.toDate(),
          medias: [
            ChatMedia(
              uploadedDate: e.sentAt!.toDate(),
              url: e.content!,
              fileName: "",
              type: MediaType.video,
            ),
          ],
        );
      } else {
        return ChatMessage(
          status: MessageStatus.read,
          user: e.senderID == currentUser!.id ? currentUser! : otherUser!,
          text: e.content!,
          createdAt: e.sentAt!.toDate(),
        );
      }
    }).toList();

    chatMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return chatMessages;
  }

  Widget _mediaMessageGallery(BuildContext context) {
    return ListTile(
      title: Icon(
        Icons.image,
        color: Colors.redAccent,
      ),
      onTap: () async {
        Navigator.pop(context);
        try {
          File? file = await _mediaService.getImageFromGalleryImage();
          if (file != null) {
            String chatID = genereteChatID(
              uid1: currentUser!.id,
              uid2: otherUser!.id,
            );
            String? downloadURL = await _storageService.uploadImageToChat(
                file: file, chatID: chatID);
            if (downloadURL != null) {
              ChatMessage chatMessage = ChatMessage(
                user: currentUser!,
                createdAt: DateTime.now(),
                medias: [
                  ChatMedia(
                    url: downloadURL,
                    fileName: "",
                    type: MediaType.image,
                  )
                ],
              );
              _sendMessage(chatMessage);
            }
          } else {
            file = await _mediaService.getVideoFromGallery();
            if (file != null) {
              String chatID = genereteChatID(
                uid1: currentUser!.id,
                uid2: otherUser!.id,
              );
              String? downloadURL = await _storageService.uploadVideoToChat(
                  file: file, chatID: chatID);
              if (downloadURL != null) {
                ChatMessage chatMessage = ChatMessage(
                  user: currentUser!,
                  createdAt: DateTime.now(),
                  medias: [
                    ChatMedia(
                      url: downloadURL,
                      fileName: "",
                      type: MediaType.video,
                    )
                  ],
                );
                _sendMessage(chatMessage);
              }
            }
          }
        } catch (e) {
          print('Error selecting or uploading media: $e');
        }
      },
    );
  }

  Widget _mediaMessageCamera(BuildContext context) {
    return ListTile(
      title: Icon(
        Icons.photo_camera,
        color: Colors.green,
      ),
      onTap: () async {
        Navigator.pop(context);
        try {
          File? file = await _mediaService.getImageFromCameraImage();
          if (file != null) {
            String chatID = genereteChatID(
              uid1: currentUser!.id,
              uid2: otherUser!.id,
            );
            String? downloadURL = await _storageService.uploadImageToChat(
                file: file, chatID: chatID);
            if (downloadURL != null) {
              ChatMessage chatMessage = ChatMessage(
                user: currentUser!,
                createdAt: DateTime.now(),
                medias: [
                  ChatMedia(
                    url: downloadURL,
                    fileName: "",
                    type: MediaType.image,
                  )
                ],
              );
              _sendMessage(chatMessage);
            }
          } else {
            file = await _mediaService.getVideoFromCamera();
            if (file != null) {
              String chatID = genereteChatID(
                uid1: currentUser!.id,
                uid2: otherUser!.id,
              );
              String? downloadURL = await _storageService.uploadVideoToChat(
                  file: file, chatID: chatID);
              if (downloadURL != null) {
                ChatMessage chatMessage = ChatMessage(
                  user: currentUser!,
                  createdAt: DateTime.now(),
                  medias: [
                    ChatMedia(
                      url: downloadURL,
                      fileName: "",
                      type: MediaType.video,
                    )
                  ],
                );
                _sendMessage(chatMessage);
              }
            }
          }
        } catch (e) {
          print('Error capturing or uploading image: $e');
        }
      },
    );
  }

  Widget _mediaMessageVideoGallery(BuildContext context) {
    return ListTile(
      title: Icon(
        Icons.video_library,
        color: Colors.orangeAccent,
      ),
      onTap: () async {
        Navigator.pop(context);
        try {
          File? file = await _mediaService.getVideoFromGallery();
          if (file != null) {
            String chatID = genereteChatID(
              uid1: currentUser!.id,
              uid2: otherUser!.id,
            );
            String? downloadURL = await _storageService.uploadVideoToChat(
                file: file, chatID: chatID);
            if (downloadURL != null) {
              ChatMessage chatMessage = ChatMessage(
                user: currentUser!,
                createdAt: DateTime.now(),
                medias: [
                  ChatMedia(
                    url: downloadURL,
                    fileName: "",
                    type: MediaType.video,
                  )
                ],
              );
              _sendMessage(chatMessage);
            }
          }
        } catch (e) {
          print('Error selecting or uploading video: $e');
        }
      },
    );
  }

  Widget _mediaMessageVideoCamera(BuildContext context) {
    return ListTile(
      title: Icon(Icons.videocam, color: Colors.purpleAccent),
      onTap: () async {
        Navigator.pop(context);
        try {
          File? file = await _mediaService.getVideoFromCamera();
          if (file != null) {
            String chatID = genereteChatID(
              uid1: currentUser!.id,
              uid2: otherUser!.id,
            );
            String? downloadURL = await _storageService.uploadVideoToChat(
                file: file, chatID: chatID);
            if (downloadURL != null) {
              ChatMessage chatMessage = ChatMessage(
                user: currentUser!,
                createdAt: DateTime.now(),
                medias: [
                  ChatMedia(
                      url: downloadURL, fileName: "", type: MediaType.video),
                ],
              );
              _sendMessage(chatMessage);
            }
          }
        } catch (e) {
          print('Error capturing or uploading video: $e');
        }
      },
    );
  }
}