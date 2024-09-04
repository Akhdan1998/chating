import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';

import '../service/alert_service.dart';

const String appId = 'de71d649f3e24489b4b66acd07983a96';
const String token = '007eJxTYPA8ZLN/482MfYX3zC7IfOb/+LWwW/pOzuuna16wFZ+96/RJgSEl1dwwxczEMs041cjExMIyySTJzCwxOcXA3NLCONHSzEvxelpDICNDiow1KyMDBIL4fAzaZkYWhkaWBuZmxpYWJgwMAKDnIww=';


class AudioCallScreen extends StatefulWidget {
  final String phoneNumber;

  AudioCallScreen({required this.phoneNumber});

  @override
  _AudioCallScreenState createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  late final RtcEngine _engine;
  final GetIt _getIt = GetIt.instance;
  late AlertService _alertService;
  bool _localUserJoined = false;
  bool _isMuted = false;
  int? _remoteUid;

  @override
  void initState() {
    super.initState();
    _initAgoraEngine();
  }

  Future<void> _initAgoraEngine() async {
    try {
      await _requestPermissions();

      _engine = await createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(appId: appId));
      await _engine.enableVideo();
      await _engine.startPreview();

      _engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          setState(() {
            _remoteUid = null;
          });
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('[onError] err: $err, msg: $msg');
        },
      ));

      await _engine.joinChannel(
        token: token,
        channelId: '+6281290763984',
        options: ChannelMediaOptions(
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
        uid: int.parse(widget.phoneNumber.substring(1)),
      );
    } catch (e) {
      debugPrint("Error initializing Agora: $e");
    }
  }

  Future<void> _joinChannel() async {
    await _engine.joinChannel(
      token: token,
      channelId: '+6281290763984',
      options: const ChannelMediaOptions(
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
      uid: int.parse(widget.phoneNumber.substring(1)),
    );

    print('TOKENNNNN ${token}');
    print('NUMBERRR ${widget.phoneNumber.substring(1)}');

    await _engine.enableVideo();

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
        onError: (ErrorCodeType err, String msg) {
          print('[onError] err: $err, msg: $msg');
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
  }

  Future<void> _leaveChannel() async {
    await _engine.leaveChannel();
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    if (cameraStatus != PermissionStatus.granted || microphoneStatus != PermissionStatus.granted) {
      _alertService.showToast(
        text: 'Microphone permissions are required.',
        icon: Icons.warning,
        color: Colors.yellowAccent,
      );
      return;
    }

    // _initializeCameras();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _joinChannel,
              child: const Text('Join Call'),
            ),
            ElevatedButton(
              onPressed: _leaveChannel,
              child: const Text('Leave Call'),
            ),
          ],
        ),
      ),
    );
  }
}
