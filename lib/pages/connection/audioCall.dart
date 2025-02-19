import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
import '../../service/alert_service.dart';
import '../../widgets/utils.dart';

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
  Timer? _callTimeoutTimer;
  int _secondsElapsed = 0;
  AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _stopCallTimer();
    _cancelCallTimeoutTimer();
    _audioPlayer.dispose();
    _engine.release();
    super.dispose();
  }

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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uid = prefs.getString('uid');

    final callData = {
      'callerName': widget.userProfile.name,
      'callerImage': widget.userProfile.pfpURL,
      'callerPhoneNumber': widget.userProfile.phoneNumber,
      'callerUID': widget.userProfile.uid,
      'callerEmail': widget.userProfile.email,
      'callDate': Timestamp.now(),
      'callDuration': _formatDuration(_secondsElapsed),
      'type': 'voice',
      'currentUserUID': uid,
    };

    callData.forEach((key, value) {
      print('$key: $value');
    });

    await FirebaseFirestore.instance.collection('calls').add(callData);
  }

  Future<void> _toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await _engine.setEnableSpeakerphone(_isSpeakerOn);

    double volume = _isSpeakerOn ? 2.0 : 1.0;
    await _audioPlayer.setVolume(volume);

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
          _startCallTimeoutTimer();
          _playWaitingAudio();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUid = remoteUid;
            _startCallTimer();
            recorderController.record();
          });
          _cancelCallTimeoutTimer();
          _stopWaitingAudio();
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) async {
          setState(() {
            _remoteUid = null;
          });

          await recorderController.stop();

          _stopCallTimer();

          await _saveCallHistory();

          await _leaveChannel();

          _playWaitingAudio();
        },
        onError: (ErrorCodeType err, String msg) {
          print('Errorrrrrrrrrrrrr: $err - $msg');
          _alertService.showToast(
            text: 'error'.tr(),
            icon: Icons.error,
            color: Colors.red,
          );
        },
      ),);

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
      // print('channelID: ${channel}');
      print('NUMBER: ${widget.userProfile.phoneNumber}');
    } catch (e) {
      debugPrint("Error initializing Agora: $e");
    }
  }

  void _startCallTimeoutTimer() {
    _callTimeoutTimer = Timer(Duration(seconds: 30), () {
      if (_remoteUid == null) {
        _leaveChannel();
        _stopWaitingAudio();
      }
    });
  }

  void _cancelCallTimeoutTimer() {
    _callTimeoutTimer?.cancel();
  }

  Future<void> _leaveChannel() async {
    await _engine.leaveChannel();
    await _engine.release();
    _stopCallTimer();
    await _saveCallHistory();
    Navigator.of(context).pop();
    setState(() => _localUserJoined = false);
  }

  Future<void> _playWaitingAudio() async {
    await _audioPlayer.play(AssetSource('tut.mp3'),
        volume: _isSpeakerOn ? 2.0 : 1.0);
  }

  Future<void> _stopWaitingAudio() async {
    await _audioPlayer.stop();
  }

  Future<void> _requestPermissions() async {
    final status = await [Permission.microphone].request();
    if (status[Permission.microphone] != PermissionStatus.granted) {
      _alertService.showToast(
          text: 'permission_microphone'.tr(),
          icon: Icons.warning,
          color: Colors.yellowAccent);
    }
  }

  Future<void> _toggleMute() async {
    _isMuted = !_isMuted;
    await _engine.muteLocalAudioStream(_isMuted);
    setState(() {});
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
                style: StyleText(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _remoteUid != null
                    ? _formatDuration(_secondsElapsed)
                    : 'ringing'.tr(),
                style: StyleText(color: Colors.white),
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
            _toggleSpeaker,
          ),
          _buildControlButton(
            _isMuted ? Icons.mic_off : Icons.mic,
            _toggleMute,
          ),
          _buildControlButton(
            Icons.call_end,
            _leaveChannel,
            color: Colors.redAccent,
          ),
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
