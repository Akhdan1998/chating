import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/group.dart';
import '../models/user_profile.dart';
import '../service/alert_service.dart';
import '../utils.dart';

class GroupAudioCallScreen extends StatefulWidget {
  late final Group grup;
  final List<UserProfile> users;

  GroupAudioCallScreen({
    required this.grup,
    required this.users,
  });

  @override
  State<GroupAudioCallScreen> createState() => _GroupAudioCallScreenState();
}

class _GroupAudioCallScreenState extends State<GroupAudioCallScreen> {
  late final RtcEngine _engine;
  final _alertService = GetIt.instance<AlertService>();
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isJoined = false;
  List<int> _remoteUids = [];
  Timer? _callTimer;
  Timer? _joinTimeoutTimer;
  int _secondsElapsed = 0;
  late RecorderController recorderController;
  AudioPlayer _audioPlayer = AudioPlayer();

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

  Future<void> _toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await _engine.setEnableSpeakerphone(_isSpeakerOn);

    double volume = _isSpeakerOn ? 2.0 : 1.0;
    await _audioPlayer.setVolume(volume);

    setState(() {});
  }

  Future<void> _playWaitingAudio() async {
    await _audioPlayer.play(AssetSource('tut.mp3'),
        volume: _isSpeakerOn ? 2.0 : 1.0);
  }

  Future<void> _stopWaitingAudio() async {
    await _audioPlayer.stop();
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
    // _secondsElapsed = 0;
  }

  Future<void> _initAgora() async {
    try {
      await _requestPermissions();

      _engine = await createAgoraRtcEngine();
      await _engine.enableAudio();

      await _engine.enableAudioVolumeIndication(
          interval: 200, smooth: 3, reportVad: true);

      await _engine.initialize(RtcEngineContext(
        appId: appIdGroupAudio,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            setState(() => _localUserJoined = true);
            _startJoinTimeoutTimer();
            _playWaitingAudio();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            setState(() {
              _remoteUids.add(remoteUid);
              _startCallTimer();
              onUserJoined();
              recorderController.record();
            });
            _cancelJoinTimeoutTimer();
            _stopWaitingAudio();
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            setState(() {
              _remoteUids.remove(remoteUid);
              if (_remoteUids.isEmpty) {
                _stopCallTimer();
                _leaveChannel();
                recorderController.stop();
              }
            });
          },
          onError: (ErrorCodeType err, String msg) {
            _alertService.showToast(
                text: 'Error: $err - $msg',
                icon: Icons.error,
                color: Colors.red);
          },
        ),
      );

      await _engine.joinChannel(
        token: tokenGroupAudio,
        channelId: channel,
        options: ChannelMediaOptions(
          autoSubscribeAudio: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
        uid: 0,
      );
    } catch (e) {
      debugPrint("Error initializing Agora: $e");
    }
  }

  void _startJoinTimeoutTimer() {
    _joinTimeoutTimer = Timer(Duration(seconds: 30), () {
      if (_remoteUids.isEmpty) {
        _leaveChannel();
        _stopWaitingAudio();
      }
    });
  }

  void _cancelJoinTimeoutTimer() {
    _joinTimeoutTimer?.cancel();
  }

  Future<void> _leaveChannel() async {
    await _engine.leaveChannel();
    _stopCallTimer();
    Navigator.of(context).pop();
    await _saveCallHistory();
    setState(() => _localUserJoined = false);
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

  Future<void> _saveCallHistory() async {
    final callData = {
      'callerName': widget.grup.name,
      'callerImage': widget.grup.imageUrl,
      'callDate': Timestamp.now(),
      'callDuration': _formatDuration(_secondsElapsed),
      'type': 'voice',
    };

    await FirebaseFirestore.instance.collection('call_history').add(callData);
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleMute() async {
    _isMuted = !_isMuted;
    await _engine.muteLocalAudioStream(_isMuted);
    setState(() {});
  }

  void onUserJoined() {
    setState(() {
      _isJoined = true;
    });
  }

  Widget _renderLocalPreview() {
    if (_localUserJoined) {
      return Stack(
        children: [
          AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _engine,
              canvas: VideoCanvas(uid: 0),
            ),
          ),
          Container(
            height: _isJoined ? MediaQuery.of(context).size.height : 209,
            margin: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white.withOpacity(0.2),
            ),
            alignment: Alignment.center,
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'You',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.users.first.pfpURL!),
                  radius: 35,
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
              ],
            ),
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  Widget _renderVideo(int uid) {
    return Stack(
      children: [
        AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _engine,
            canvas: VideoCanvas(uid: uid),
            connection: RtcConnection(channelId: channel),
          ),
        ),
        Container(
          margin: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white.withOpacity(0.2),
          ),
          alignment: Alignment.center,
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.users.first.name!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              CircleAvatar(
                backgroundImage: NetworkImage(widget.users.first.pfpURL!),
                radius: 35,
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
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _stopCallTimer();
    _engine.release();
    recorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey.shade800,
              ),
              child: IconButton(
                icon: Icon(Icons.close_fullscreen, color: Colors.white),
                onPressed: () {},
              ),
            ),
            Column(
              children: [
                Text(
                  widget.grup.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isJoined
                      ? _formatDuration(_secondsElapsed)
                      : 'Waiting for other participants...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int totalUsers = _remoteUids.length + 1;

          if (totalUsers == 2) {
            return Column(
              children: [
                Expanded(
                  child: _renderLocalPreview(),
                ),
                Expanded(
                  child: _renderVideo(_remoteUids[0]),
                ),
              ],
            );
          } else {
            int crossAxisCount;

            if (totalUsers <= 4) {
              crossAxisCount = 2;
            } else {
              crossAxisCount = 3;
            }

            double aspectRatio = (constraints.maxWidth / crossAxisCount) /
                (constraints.maxHeight / (totalUsers / crossAxisCount));

            return GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: aspectRatio,
              ),
              itemCount: totalUsers,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _renderLocalPreview();
                } else {
                  return _renderVideo(_remoteUids[index - 1]);
                }
              },
            );
          }
        },
      ),
      bottomNavigationBar: Container(
        height: 100,
        padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.grey.shade800,
          ),
          padding: EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.black.withOpacity(0.2),
                  ),
                  child: Icon(Icons.more_horiz, color: Colors.white),
                ),
              ),
              GestureDetector(
                onTap: _toggleSpeaker,
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.black.withOpacity(0.2),
                  ),
                  child: Icon(
                    Icons.volume_up,
                    color: _isSpeakerOn ? Colors.red : Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.black.withOpacity(0.2),
                  ),
                  child: Icon(_isMuted ? Icons.mic_off : Icons.mic,
                      color: Colors.white),
                ),
              ),
              GestureDetector(
                onTap: _leaveChannel,
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.black.withOpacity(0.2),
                  ),
                  child: Icon(Icons.call_end, color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
