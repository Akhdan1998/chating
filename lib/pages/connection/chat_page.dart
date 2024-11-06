import 'dart:io';
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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart' as vp;
import 'package:video_player/video_player.dart';
import '../../models/chat.dart';
import '../../models/message.dart' as chat;
import '../../models/message.dart';
import '../../service/alert_service.dart';
import '../../service/auth_service.dart';
import '../../service/database_service.dart';
import 'audioCall.dart';
import '../detailProfile_page.dart';
import 'package:any_link_preview/any_link_preview.dart';

class ChatPage extends StatefulWidget {
  final UserProfile chatUser;

  const ChatPage({
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
  final currentuser = FirebaseAuth.instance.currentUser;
  bool _showLastSeen = true;
  List<ChatMessage> messages = [];
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late FirebaseMessaging _firebaseMessaging;

  Future<String> _getPhoneNumber(String userId) async {
    var firestore = FirebaseFirestore.instance;
    var userDoc = await firestore.collection('users').doc(userId).get();
    return userDoc.data()!['phoneNumber'] ?? '';
  }

  void _startVideoCall() async {
    String phoneNumber = await _getPhoneNumber(widget.chatUser.uid!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(userProfile: widget.chatUser),
      ),
    );
  }

  void _startAudioCall() async {
    String phoneNumber = await _getPhoneNumber(widget.chatUser.uid!);

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
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
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

      chat.Message message = chat.Message(
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

  Future<void> launchPhoneCall(String phoneNumber) async {
    String url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
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

  void _deleteMessage(ChatMessage message) async {
    try {
      await _databaseService.deleteMessage(
          currentUser!.id, otherUser!.id, message.user.id);
      _alertService.showToast(
        text: 'Message deleted!',
        icon: Icons.check,
        color: Colors.green,
      );
    } catch (e) {
      _alertService.showToast(
        text: 'Failed to delete message',
        icon: Icons.error,
        color: Colors.red,
      );
    }
  }

  void _showDeleteMessageDialog(BuildContext context, ChatMessage message) {
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
              onPressed: () {
                _deleteMessage(message);
                Navigator.of(context).pop();
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

  void _showPopup(BuildContext context, ChatMessage message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          titlePadding: EdgeInsets.zero,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  'copy'.tr(),
                  style: StyleText(),
                ),
                trailing: Icon(
                  Icons.copy,
                  size: 19,
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.text))
                      .whenComplete(() {
                    _alertService.showToast(
                      text: 'copy'.tr(),
                      icon: Icons.copy,
                      color: Colors.green,
                    );
                  });
                  Navigator.pop(context);
                },
              ),
              Divider(height: 0),
              ListTile(
                title: Text('delete'.tr()),
                trailing: Icon(
                  Icons.delete,
                  size: 20,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteMessageDialog(context, message);
                },
              ),
            ],
          ),
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

      chat.Message message = chat.Message(
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
    recorder.setSubscriptionDuration(const Duration(milliseconds: 500));
  }

  Future<void> _showNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
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
            onPressed: _startVideoCall,
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
        if (!snapshot.hasData || snapshot.data == null) {
          return Container();
        }

        Chat? chat = snapshot.data!.data();
        List<ChatMessage> messages = chat?.messages != null
            ? _generateChatMessageList(chat!.messages!)
            : [];

        // List<ChatMessage> messages = [];
        // if (chat != null && chat.messages != null) {
        //   messages = _generateChatMessageList(chat.messages!);
        // }

        if (messages.isNotEmpty) {
          ChatMessage latestMessage = messages.first;
          bool isNewMessage = latestMessage.createdAt
              .isAfter(DateTime.now().subtract(Duration(milliseconds: 500)));

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
            onLongPressMessage: (ChatMessage message) {
              _showPopup(context, message);
            },
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

              List<TextSpan> _buildTextSpans(String text) {
                final List<TextSpan> spans = [];
                final RegExp urlPattern = RegExp(r'(https?://[^\s]+)');
                final Iterable<Match> matches = urlPattern.allMatches(text);
                int lastMatchEnd = 0;

                for (final Match match in matches) {
                  if (match.start > lastMatchEnd) {
                    spans.add(
                      TextSpan(
                        text: text.substring(lastMatchEnd, match.start),
                        style: StyleText(
                          color: Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    );
                  }

                  spans.add(
                    TextSpan(
                      text: match.group(0),
                      style: StyleText(color: Colors.blue),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchURL(match.group(0)!),
                    ),
                  );
                  lastMatchEnd = match.end;
                }

                if (lastMatchEnd < text.length) {
                  spans.add(TextSpan(
                    text: text.substring(lastMatchEnd),
                    style: StyleText(
                      color: Colors.black87,
                      fontSize: 15,
                    ),
                  ));
                }

                return spans;
              }

              if (message.customProperties?['audioUrl'] != null) {
                String audioUrl = message.customProperties!['audioUrl'];
                bool isCurrentlyPlaying =
                    (isPlaying && currentAudioUrl == audioUrl);

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            setState(() {
                              if (!isCurrentlyPlaying) {
                                isPlaying = true;
                                currentAudioUrl = audioUrl;
                              } else {
                                isPlaying = false;
                              }
                            });

                            if (isPlaying) {
                              await audioPlayer.play(UrlSource(audioUrl));
                            } else {
                              await audioPlayer.pause();
                            }
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Icon(
                              isCurrentlyPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                height: 10,
                                width: MediaQuery.of(context).size.width - 233,
                                child: Slider(
                                  min: 0,
                                  max: duration.inSeconds.toDouble(),
                                  value: isCurrentlyPlaying
                                      ? position.inSeconds.toDouble()
                                      : 0,
                                  inactiveColor: Colors.grey,
                                  onChanged: (value) async {
                                    setState(() {
                                      position =
                                          Duration(seconds: value.toInt());
                                    });
                                    await audioPlayer.seek(position);
                                    await audioPlayer.resume();
                                  },
                                ),
                              ),
                              Text(
                                isCurrentlyPlaying
                                    ? "${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}"
                                    : "0:00",
                                style: StyleText(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
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
              } else if (isURL(message.text)) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnyLinkPreview(
                      link: message.text,
                      showMultimedia: true,
                      onTap: () => _launchURL(message.text),
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
                      text: TextSpan(
                        children: _buildTextSpans(message.text),
                      ),
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
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: _buildTextSpans(message.text),
                      ),
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
              }
            },
            onTapMedia: (media) async {
              if (media.type == MediaType.image) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageView(
                      imageUrl: media.url,
                      chatUser: widget.chatUser,
                      dateTime: media.uploadedDate ?? DateTime.now(),
                    ),
                  ),
                );
              } else if (media.type == MediaType.file) {
                final Uri url = Uri.parse(media.url);
                String fileName = media.fileName;
                DateTime dateTime = media.uploadedDate ?? DateTime.now();
                await _downloadAndOpenPDF(url.toString(), fileName, dateTime);
              } else if (media.type == MediaType.video) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenVideoPlayer(
                      videoUrl: media.url,
                      chatUser: widget.chatUser,
                      dateTime: media.uploadedDate ?? DateTime.now(),
                    ),
                  ),
                );
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
                    child: ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        uploadFile();
                      },
                      title: Icon(
                        Icons.file_present,
                        color: Colors.blue,
                      ),
                    ),
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
          currentUser: currentUser!,
          onSend: _sendMessage,
          messages: messages,
        );
      },
    );
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
            String formattedTime = DateFormat('HH:mm').format(lastSeenDt);

            if (now.difference(lastSeenDt).inDays == 0) {
              lastSeenMessage = 'Last seen today at $formattedTime';
            } else if (now.difference(lastSeenDt).inDays == 1) {
              lastSeenMessage = 'Last seen yesterday at $formattedTime';
            } else {
              String formattedDate = DateFormat('yMd').format(lastSeenDt);
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
    if (chatMessage.medias != null && chatMessage.medias!.isNotEmpty) {
      if (chatMessage.medias!.first.type == MediaType.image) {
        chat.Message message = chat.Message(
          senderID: chatMessage.user.id,
          content: chatMessage.medias!.first.url,
          messageType: MessageType.Image,
          sentAt: Timestamp.fromDate(chatMessage.createdAt),
          isRead: false,
        );
        await _databaseService.sendChatMessage(
          currentUser!.id,
          otherUser!.id,
          message,
        );
      } else if (chatMessage.medias!.first.type == MediaType.file) {
        chat.Message message = chat.Message(
          senderID: chatMessage.user.id,
          content: chatMessage.medias!.first.url,
          messageType: MessageType.Document,
          sentAt: Timestamp.fromDate(chatMessage.createdAt),
          isRead: false,
        );
        await _databaseService.sendChatMessage(
          currentUser!.id,
          otherUser!.id,
          message,
        );
      } else if (chatMessage.medias!.first.type == MediaType.video) {
        chat.Message message = chat.Message(
          senderID: chatMessage.user.id,
          content: chatMessage.medias!.first.url,
          messageType: MessageType.Video,
          sentAt: Timestamp.fromDate(chatMessage.createdAt),
          isRead: false,
        );
        await _databaseService.sendChatMessage(
          currentUser!.id,
          otherUser!.id,
          message,
        );
      }
    } else {
      chat.Message message = chat.Message(
        senderID: currentUser!.id,
        content: chatMessage.text,
        messageType: MessageType.Text,
        sentAt: Timestamp.fromDate(chatMessage.createdAt),
        isRead: false,
      );
      await _databaseService.sendChatMessage(
        currentUser!.id,
        otherUser!.id,
        message,
      );
    }
  }

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
      title: Icon(
        Icons.videocam,
        color: Colors.purpleAccent,
      ),
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
          print('Error capturing or uploading video: $e');
        }
      },
    );
  }
}

class FullScreenImageView extends StatefulWidget {
  final UserProfile chatUser;
  final String imageUrl;
  final DateTime dateTime;

  FullScreenImageView({
    required this.chatUser,
    required this.imageUrl,
    required this.dateTime,
  });

  @override
  State<FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<FullScreenImageView> {
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
                text: 'Image downloaded successfully',
                icon: Icons.check,
                color: Colors.green,
              );
            });
          }
        },
        onDownloadError: (error) {
          setState(() {
            _isDownloading = false;
            _progress = 0.0;
            _alertService.showToast(
              text: 'Failed to download image: $error',
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
          text: 'Failed to download image: $e',
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
              widget.chatUser.name.toString(),
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
          text: 'Image downloaded successfully',
          icon: Icons.check,
          color: Colors.green,
        );
      });
      print('File berhasil diunduh dan disimpan ke $savePath');
    } catch (e) {
      print('--------- $e');
      setState(() {
        _alertService.showToast(
          text: 'Error downloading file',
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

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final UserProfile chatUser;
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

  // Future<void> _downloadVideo(String url) async {
  //   try {
  //     setState(() {
  //       _isDownloading = true;
  //     });
  //
  //     // Unduh video dan simpan ke penyimpanan lokal
  //     await FileDownloader.downloadFile(
  //       url: url,
  //       name: "downloaded_video.mp4",
  //       onDownloadCompleted: (filePath) {
  //         setState(() {
  //           _alertService.showToast(
  //             text: 'Video downloaded successfully',
  //             icon: Icons.check,
  //             color: Colors.green,
  //           );
  //         });
  //       },
  //       onDownloadError: (error) {
  //         setState(() {
  //           _alertService.showToast(
  //             text: 'Failed to save video to gallery',
  //             icon: Icons.error,
  //             color: Colors.red,
  //           );
  //         });
  //       },
  //     );
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

  Future<void> _downloadVideo(String url) async {
    try {
      setState(() {
        _isDownloading = true;
      });

      final tempDir = await getTemporaryDirectory();
      final tempPath = "${tempDir.path}/temp_video.mp4";

      await FileDownloader.downloadFile(
        url: url,
        name: "temp_video.mp4",
        onDownloadCompleted: (filePath) async {
          final compressedVideo = await VideoCompress.compressVideo(
            filePath,
            quality: VideoQuality.LowQuality,
            deleteOrigin: true,
          );

          if (compressedVideo != null) {
            final downloadsDir = Directory('/storage/emulated/0/Download');
            final destinationPath = "${downloadsDir.path}/compressed_video.mp4";

            await compressedVideo.file!.copy(destinationPath);

            setState(() {
              _alertService.showToast(
                text: 'Video berhasil dikompresi dan disimpan di Downloads',
                icon: Icons.check,
                color: Colors.green,
              );
            });
          } else {
            throw 'Video compression failed';
          }
        },
        onDownloadError: (error) {
          setState(() {
            _alertService.showToast(
              text: 'Failed to download video',
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
          text: 'Failed to download video: $e',
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
              widget.chatUser.name.toString(),
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
                                padding: const EdgeInsets.all(16.0),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
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
