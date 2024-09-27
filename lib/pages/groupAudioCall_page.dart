import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/group.dart';
import '../models/user_profile.dart';
import '../service/alert_service.dart';
import 'audioCall.dart';

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
  RecorderController _recorderController = RecorderController();
  int? _remoteUid;
  Timer? _callTimer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 16000;
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
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUids.add(remoteUid);
            _startCallTimer();
            onUserJoined();
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          setState(() {
            _remoteUids.remove(remoteUid);
            if (_remoteUids.isEmpty) _stopCallTimer();
          });
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
        uid: 0,
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

  void onUserJoined() {
    setState(() {
      _isJoined = true;
    });
  }

  Widget _renderLocalPreview() {
    if (_localUserJoined) {
      return Container(
        margin: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white.withOpacity(0.2),
        ),
        child: Stack(
          children: [
            AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine,
                canvas: VideoCanvas(uid: 0),
              ),
            ),
            Container(
              alignment: Alignment.center,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'You',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  CircleAvatar(
                    backgroundImage: NetworkImage(widget.users.first.pfpURL!),
                    radius: 35,
                  ),
                  // SizedBox(height: 20),
                  AudioWaveforms(
                    enableGesture: true,
                    size: Size(200, 50),
                    recorderController: _recorderController,
                    waveStyle: WaveStyle(
                      waveColor: Colors.black,
                      extendWaveform: true,
                      showMiddleLine: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _renderVideo(int uid) {
    return Container(
      margin: EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white.withOpacity(0.2),
      ),
      child: Stack(
        children: [
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _engine,
              canvas: VideoCanvas(uid: uid),
              connection: RtcConnection(channelId: channel),
            ),
          ),
          Positioned(
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    widget.users.first.name!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  CircleAvatar(
                    backgroundImage: NetworkImage(widget.users.first.pfpURL!),
                    radius: 35,
                  ),
                  SizedBox(height: 20),
                  AudioWaveforms(
                    enableGesture: true,
                    size: Size(200, 50),
                    recorderController: _recorderController,
                    waveStyle: WaveStyle(
                      waveColor: Colors.blueAccent,
                      extendWaveform: true,
                      showMiddleLine: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
                  _isJoined ? _formatDuration(_secondsElapsed) : 'Ringing...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
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
      body: GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(_remoteUids.length),
        ),
        itemCount: _remoteUids.length + 1,
        itemBuilder: (context, index) {if (index == 0) {
            return AspectRatio(
              aspectRatio: 9 / 16,
              child: _renderLocalPreview(),
            );
          } else {
            return AspectRatio(
              aspectRatio: 16 / 9,
              child: _renderVideo(_remoteUids[index - 1]),
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
                  child: Icon(Icons.volume_up, color: Colors.white),
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

  int _getCrossAxisCount(int numberOfParticipants) {
    if (numberOfParticipants == 1) {
      return 1; // 1 peserta
    } else if (numberOfParticipants == 2) {
      return 1; // 2 peserta, tampilkan 1 di atas 1
    } else if (numberOfParticipants == 3) {
      return 2; // 3 peserta, 2 di atas, 1 di bawah
    } else {
      return 2; // Lebih dari 3 peserta, 2 per baris
    }
  }
}
