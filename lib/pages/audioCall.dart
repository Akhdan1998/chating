import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/user_profile.dart';
import '../service/alert_service.dart';

String appId = 'be76645285084ce7a1d7d4cd2bd94dd0';
String token =
    '007eJxTYJhvKtIf9PPs769XXr29lBq36Oel1mtbaownNWs+DdPMlFuqwJCSam6YYmZimWacamRiYmGZZJJkZpaYnGJgbmlhnGhpdl71W1pDICODX+V9VkYGCATx2RhKi1OLPFMYGAC3vyO2';
String channel = "userId";

class AudioCallScreen extends StatefulWidget {
  final UserProfile userProfile;

  AudioCallScreen({required this.userProfile});

  @override
  _AudioCallScreenState createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  late final RtcEngine _engine;
  final _alertService = GetIt.instance<AlertService>();
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  int? _remoteUid;
  Timer? _callTimer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await _engine.setEnableSpeakerphone(_isSpeakerOn);
    setState(() {});
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _secondsElapsed = 0;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _initAgora() async {
    try {
      await _requestPermissions();

      _engine = await createAgoraRtcEngine();
      await _engine.enableAudio();

      await _engine.initialize(RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication));

      _engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUid = remoteUid;
            _startCallTimer();
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          setState(() {
            _remoteUid = null;
            _stopCallTimer();
          });
          _leaveChannel();
        },
        onError: (ErrorCodeType err, String msg) {
          _alertService.showToast(
              text: 'Error: $err - $msg', icon: Icons.error, color: Colors.red);
        },
      ));

      await _engine.joinChannel(
        token: token,
        channelId: channel,
        options: ChannelMediaOptions(
          autoSubscribeAudio: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
        uid: int.parse(widget.userProfile.phoneNumber!.substring(1)),
      );
    } catch (e) {
      debugPrint("Error initializing Agora: $e");
    }
  }

  Future<void> _requestPermissions() async {
    final status = await [Permission.microphone].request();
    if (status[Permission.microphone] != PermissionStatus.granted) {
      _alertService.showToast(
          text: 'Microphone permission is required.',
          icon: Icons.warning,
          color: Colors.yellowAccent);
    }
  }

  Future<void> _leaveChannel() async {
    await _engine.leaveChannel();
    _stopCallTimer();
    Navigator.of(context).pop();
    setState(() => _localUserJoined = false);
  }

  Future<void> _toggleMute() async {
    _isMuted = !_isMuted;
    await _engine.muteLocalAudioStream(_isMuted);
    setState(() {});
  }

  @override
  void dispose() {
    _stopCallTimer();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Container(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHeader(),
            CircleAvatar(
              backgroundImage: NetworkImage(widget.userProfile.pfpURL!),
              radius: 100,
            ),
            _buildControlPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.grey.shade800,
            ),
            child: IconButton(
              icon: Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
              onPressed: () {},
            ),
          ),
          Column(
            children: [
              Text(
                widget.userProfile.name!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _remoteUid != null
                    ? _formatDuration(_secondsElapsed)
                    : 'Ringing...',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.grey.shade800,
            ),
            child: IconButton(
              icon: Icon(Icons.person_add_alt_1_sharp, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey.shade800,
      ),
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(Icons.more_horiz, () {}),
          _buildControlButton(Icons.videocam, () {}),
          _buildControlButton(
              color: _isSpeakerOn ? Colors.red : Colors.white,
              Icons.volume_up,
              _toggleSpeaker),
          _buildControlButton(
              _isMuted ? Icons.mic_off : Icons.mic, _toggleMute),
          _buildControlButton(Icons.call_end, _leaveChannel,
              color: Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed,
      {Color color = Colors.white}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.black.withOpacity(0.2),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}
