import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/group.dart';
import '../models/user_profile.dart';
import '../utils.dart';
import 'audioCall.dart';

class GroupVideoCallScreen extends StatefulWidget {
  late final Group grup;
  final List<UserProfile> users;

  GroupVideoCallScreen({
    required this.grup,
    required this.users,
  });

  @override
  _GroupVideoCallScreenState createState() => _GroupVideoCallScreenState();
}

class _GroupVideoCallScreenState extends State<GroupVideoCallScreen> {
  late RtcEngine _engine;
  bool _localUserJoined = false;
  List<int> _remoteUids = [];
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  Timer? _timer;
  int _duration = 0;
  bool _secondUserJoined = false;
  RecorderController _recorderController = RecorderController();

  @override
  void initState() {
    super.initState();
    _initAgora();
    _startTimer();
  }

  void _startTimer() {
    if (_secondUserJoined || _timer != null) return;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _duration++;
      });
    });
  }

  Future<void> _initAgora() async {
    await _requestPermissions();

    _engine = await createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appIdGroupVideo));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUids.add(remoteUid);
            if (_remoteUids.length == 1 && !_secondUserJoined) {
              _secondUserJoined = true;
              _duration = 0; // Reset duration to 0
              _startTimer(); // Start the timer
            }
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          setState(() {
            _remoteUids.remove(remoteUid);
            if (_remoteUids.isEmpty) {
              _endCall();
            } else if (_remoteUids.length == 1) {
              _timer?.cancel();
            }
          });
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.joinChannel(
      token: tokenGroupVideo,
      channelId: channel,
      uid: 0,
      options: ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _engine.muteLocalAudioStream(_isMuted);
  }

  void _toggleVideo() {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
    _engine.muteLocalVideoStream(!_isVideoEnabled);
  }

  void _endCall() {
    _engine.leaveChannel();
    Navigator.pop(context);
  }

  Widget _buildVideoGrid(double maxWidth, double maxHeight) {
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
      int crossAxisCount = 1;
      if (totalUsers > 2 && totalUsers <= 4) {
        crossAxisCount = 2;
      } else if (totalUsers > 4) {
        crossAxisCount = 3;
      }

      double aspectRatio = maxWidth / maxHeight;

      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: aspectRatio * (crossAxisCount / totalUsers),
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
  }

  Widget _renderVideo(int uid) {
    return Container(
      color: Colors.transparent,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _engine,
            canvas: VideoCanvas(uid: uid),
            connection: RtcConnection(channelId: channel),
          ),
        ),
      ),
    );
  }

  Widget _renderLocalPreview() {
    if (_localUserJoined) {
      return Container(
        color: Colors.transparent,
        child: AspectRatio(
          aspectRatio: 1.0,
          child: AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _engine,
              canvas: VideoCanvas(uid: 0),
            ),
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  String _formatDuration(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int secs = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildVideoGrid(
                  constraints.maxWidth, constraints.maxHeight);
            },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
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
                    onTap: _toggleVideo,
                    child: Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.black.withOpacity(0.2),
                      ),
                      child: Icon(
                          _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                          color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
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
                    onTap: _endCall,
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
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      _secondUserJoined
                          ? _formatDuration(_duration)
                          : 'Ringing...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey.shade800,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.person_add_alt_1_sharp,
                            color: Colors.white),
                        onPressed: () {},
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey.shade800,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.flip_camera_ios_rounded,
                            color: Colors.white),
                        onPressed: () {
                          _engine.switchCamera();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
