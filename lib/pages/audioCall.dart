import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:agora_rtm/agora_rtm.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/user_profile.dart';
import '../service/alert_service.dart';
import '../utils.dart';

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
  late RecorderController recorderController;
  int? _remoteUid;
  Timer? _callTimer;
  int _secondsElapsed = 0;
  // DateTime? _callStartTime;

  @override
  void initState() {
    super.initState();
    _initAgora();
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 16000;
  }

  Future<void> _saveCallHistory() async {
    final callData = {
      'callerName': widget.userProfile.name,
      'callerImage': widget.userProfile.pfpURL,
      'callerPhoneNumber': widget.userProfile.phoneNumber,
      'callDate': Timestamp.now(),
      'callDuration': _formatDuration(_secondsElapsed),
      'type': 'voice',
    };

    await FirebaseFirestore.instance.collection('call_history').add(callData);
  }

  // Future<void> _saveCallToFirestore(
  //     String callType,
  //     String callerId,
  //     String receiverId,
  //     String channelId,
  //     int callDuration,
  //     String callerPhoneNumber,
  //     ) async {
  //   try {
  //     await FirebaseFirestore.instance.collection('audioCall_history').add({
  //       'callType': callType,
  //       'callerId': callerId,
  //       'receiverId': receiverId,
  //       'channelId': channelId,
  //       'callStartTime': FieldValue.serverTimestamp(),
  //       'callDuration': _formatDuration(_secondsElapsed),
  //       'callerPhoneNumber': callerPhoneNumber,
  //     });
  //   } catch (e) {
  //     debugPrint('Error saving call to Firestore: $e');
  //   }
  // }
  //
  // int _calculateCallDuration() {
  //   if (_callStartTime == null) {
  //     return 0;
  //   }
  //
  //   DateTime callEndTime = DateTime.now();
  //
  //   Duration duration = callEndTime.difference(_callStartTime!);
  //
  //   return duration.inSeconds;
  // }

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

      await _engine.initialize(
        RtcEngineContext(
          appId: appIdAudio,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      _engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUid = remoteUid;
            _startCallTimer();
            recorderController.record();
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) async {
          setState(() {
            _remoteUid = null;
          });

          await recorderController.stop();

          _stopCallTimer();

          print('Durasi panggilan: ${_formatDuration(_secondsElapsed)}');

          await _saveCallHistory();

          await _leaveChannel();
        },
        onError: (ErrorCodeType err, String msg) {
          print('Errorrrrrrrrrrrrr: $err - $msg');
          _alertService.showToast(
            text: 'Error: $err - $msg',
            icon: Icons.error,
            color: Colors.red,
          );
        },
      ));

      await _engine.joinChannel(
        token: tokenAudio,
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
    await _engine.release();
    _stopCallTimer();
    await _saveCallHistory();
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
      backgroundColor: Colors.blueGrey,
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
            AudioWaveforms(
              padding: EdgeInsets.only(left: 100, right: 100),
              recorderController: recorderController,
              enableGesture: false,
              size: Size(double.infinity, 60),
              waveStyle: WaveStyle(
                waveCap: StrokeCap.square,
                waveColor: Colors.blueGrey,
                showMiddleLine: false,
                extendWaveform: true,
              ),
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
