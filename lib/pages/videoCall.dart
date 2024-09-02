import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String appId = 'de71d649f3e24489b4b66acd07983a96';
const String token = '5f51651473204af393e12e0617bb6dd1';

class VideoCallScreen extends StatefulWidget {
  final String channelName;

  VideoCallScreen({required this.channelName});

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  int? _remoteUid;
  late final RtcEngine _engine;
  bool _localUserJoined = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    try {
      await _requestPermissions();

      // Buat instance RtcEngine
      _engine = await createAgoraRtcEngine();

      // Inisialisasi RtcEngine dan set channel profile menjadi komunikasi
      await _engine.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Aktifkan modul video
      await _engine.enableVideo();

      // Mulai preview video lokal
      await _engine.startPreview();

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("local user ${connection.localUid} joined");
            setState(() {
              _localUserJoined = true;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("Remote user $remoteUid joined");
            setState(() {
              _remoteUid = remoteUid;
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint("Remote user $remoteUid left channel");
            setState(() {
              _remoteUid = null;
            });
          },
        ),
      );

      await _engine.joinChannel(
        token: token,
        channelId: widget.channelName,
        options: const ChannelMediaOptions(
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
        uid: 1234, // Gunakan UID unik untuk pengguna
      );

    } catch (e) {
      debugPrint("Error initializing Agora: $e");
    }
  }

  // Future<void> _initAgora() async {
  //   try {
  //     await _requestPermissions();
  //
  //     // Buat instance RtcEngine
  //     _engine = await createAgoraRtcEngine();
  //
  //     // Inisialisasi RtcEngine dan set channel profile menjadi komunikasi
  //     await _engine.initialize(const RtcEngineContext(
  //       appId: appId,
  //       channelProfile: ChannelProfileType.channelProfileCommunication,
  //     ));
  //
  //     // Aktifkan modul video
  //     await _engine.enableVideo();
  //
  //     // Mulai preview video lokal
  //     await _engine.startPreview();
  //
  //     _engine.registerEventHandler(
  //       RtcEngineEventHandler(
  //         onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
  //           debugPrint("local user ${connection.localUid} joined");
  //           setState(() {
  //             _localUserJoined = true;
  //           });
  //         },
  //         onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
  //           debugPrint("Remote user $remoteUid joined");
  //           setState(() {
  //             _remoteUid = remoteUid;
  //           });
  //         },
  //         onUserOffline: (RtcConnection connection, int remoteUid,
  //             UserOfflineReasonType reason) {
  //           debugPrint("Remote user $remoteUid left channel");
  //           setState(() {
  //             _remoteUid = null;
  //           });
  //         },
  //       ),
  //     );
  //
  //     // Fetch the corresponding UID from Firestore based on the phone number
  //     String channelName =
  //     await _getChannelNameFromPhoneNumber(widget.phoneNumber);
  //
  //     await _engine.joinChannel(
  //       token: token,
  //       channelId: channelName,
  //       options: const ChannelMediaOptions(
  //           autoSubscribeVideo: true,
  //           autoSubscribeAudio: true,
  //           publishCameraTrack: true,
  //           publishMicrophoneTrack: true,
  //           clientRoleType: ClientRoleType.clientRoleBroadcaster),
  //       uid: 1234,
  //     );
  //
  //   } catch (e) {
  //     debugPrint("Error initializing Agora: $e");
  //   }
  // }

  // Future<String> _getChannelNameFromPhoneNumber(String phoneNumber) async {
  //   try {
  //     QuerySnapshot querySnapshot = await FirebaseFirestore.instance
  //         .collection('users')
  //         .where('phoneNumber', isEqualTo: phoneNumber)
  //         .get();
  //
  //     if (querySnapshot.docs.isNotEmpty) {
  //       return querySnapshot.docs.first
  //           .id; // Assuming the UID or other unique ID is used as the channel name
  //     } else {
  //       throw Exception("User with phone number $phoneNumber not found");
  //     }
  //   } catch (e) {
  //     throw Exception("Error fetching user data: $e");
  //   }
  // }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: true,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Video Call'),
      ),
      body: Stack(
        children: [
          Center(child: _remoteVideo()),
          if (_localUserJoined)
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 100,
                height: MediaQuery.of(context).size.height,
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine,
                    canvas: VideoCanvas(uid: 1234, renderMode: RenderModeType.renderModeFit),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid, renderMode: RenderModeType.renderModeFit),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return const Text(
        'Waiting for other users to join',
        textAlign: TextAlign.center,
      );
    }
  }

  // Widget _remoteVideo() {
  //   if (_remoteUid != null) {
  //     return AgoraVideoView(
  //       controller: VideoViewController.remote(
  //         rtcEngine: _engine,
  //         canvas: VideoCanvas(uid: _remoteUid, renderMode: RenderModeType.renderModeFit),
  //         connection: RtcConnection(channelId: widget.phoneNumber),
  //       ),
  //     );
  //   } else {
  //     return const Text(
  //       'Waiting for other users to join',
  //       textAlign: TextAlign.center,
  //     );
  //   }
  // }
}
