import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:chating/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import '../service/alert_service.dart';
import '../utils.dart';
import 'audioCall.dart';

class VideoCallScreen extends StatefulWidget {
  final UserProfile userProfile;

  VideoCallScreen({required this.userProfile});

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  int? _remoteUid;
  late RtcEngine _engine;
  bool _localUserJoined = false;
  late Future<void> _initializeControllerFuture;
  int _currentCameraIndex = 0;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  final GetIt _getIt = GetIt.instance;
  late AlertService _alertService;
  late String channelName;
  Timer? _callTimer;
  int _secondsElapsed = 0;
  Offset _localVideoPosition = Offset(20, 150);
  final double videoWidth = 130;
  final double videoHeight = 180;

  @override
  void initState() {
    super.initState();
    channelName = widget.userProfile.phoneNumber!;
    _alertService = _getIt.get<AlertService>();
    _initAgora();
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

  // Future<void> joinChannel() async {
  //   await _engine.joinChannel(
  //     token: tokenVideo,
  //     channelId: channelVideo,
  //     options: const ChannelMediaOptions(
  //       autoSubscribeVideo: true,
  //       autoSubscribeAudio: true,
  //       publishCameraTrack: true,
  //       publishMicrophoneTrack: true,
  //       clientRoleType: ClientRoleType.clientRoleBroadcaster,
  //     ),
  //     uid: int.parse(widget.userProfile.phoneNumber!.substring(1)),
  //   );
  //
  //   print('TOKEN VIDEO CALLLLLLL ${tokenVideo}');
  //   print('NUMBER ${widget.userProfile.phoneNumber!.substring(1)}');
  //
  //   await _engine.enableVideo();
  //
  //   await _engine.startPreview();
  //
  //   _engine.registerEventHandler(
  //     RtcEngineEventHandler(
  //       onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
  //         debugPrint("local user ${connection.localUid} joined");
  //         setState(() {
  //           _localUserJoined = true;
  //         });
  //       },
  //       onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
  //         setState(() {
  //           _remoteUid = remoteUid;
  //           _startCallTimer();
  //         });
  //       },
  //       onUserOffline: (RtcConnection connection, int remoteUid,
  //           UserOfflineReasonType reason) {
  //         setState(() {
  //           _remoteUid = null;
  //           _stopCallTimer();
  //         });
  //         Navigator.pop(context);
  //       },
  //       onError: (ErrorCodeType err, String msg) {
  //         print('[onError] err: $err, msg: $msg');
  //       },
  //     ),
  //   );
  // }

  Future<void> _initAgora() async {
    try {
      await _requestPermissions();

      _engine = await createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(appId: appIdVideo));
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
            _startCallTimer();
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          setState(() {
            _remoteUid = null;
            _stopCallTimer();
          });
          _endCall();
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('[onError] err: $err, msg: $msg');
        },
      ));

      print('TOKEN VIDEO CALL ${tokenVideo}');

      await _engine.joinChannel(
        token: tokenVideo,
        channelId: channel,
        options: ChannelMediaOptions(
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
          publishCameraTrack: true,
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
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    if (cameraStatus != PermissionStatus.granted ||
        microphoneStatus != PermissionStatus.granted) {
      _alertService.showToast(
        text: 'Camera and microphone permissions are required.',
        icon: Icons.warning,
        color: Colors.yellowAccent,
      );
      return;
    }
  }

  void _switchCamera() async {
    try {
      await _engine.switchCamera();
    } catch (e) {
      print("Error switching camera: $e");
    }
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _engine.muteLocalAudioStream(_isMuted);
  }

  Future<void> _toggleVideo() async {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
    await _engine.muteLocalVideoStream(!_isVideoEnabled);
  }

  Future<void> _endCall() async {
    await _engine.leaveChannel();
    await _engine.release();
    // await _controller.dispose();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    _stopCallTimer();
    super.dispose();
  }

  Widget _remoteVideo() {
    return _remoteUid != null
        ? AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _engine,
              canvas: VideoCanvas(
                uid: _remoteUid,
                renderMode: RenderModeType.renderModeHidden,
              ),
              connection: RtcConnection(channelId: 'userId'),
            ),
          )
        : Container(
            width: MediaQuery.sizeOf(context).width,
            height: MediaQuery.sizeOf(context).height,
            color: Colors.blueGrey,
          );
  }

  void _snapToEdge(Offset position, Size screenSize) {
    double leftEdge = 0;
    double rightEdge = screenSize.width - videoWidth;
    double topEdge = 0;
    double bottomEdge = screenSize.height - videoHeight;

    double deltaLeft = position.dx;
    double deltaRight = rightEdge - position.dx;
    double deltaTop = position.dy;
    double deltaBottom = bottomEdge - position.dy;

    if (position.dx > screenSize.width / 4 &&
        position.dx < screenSize.width * 3 / 4) {
      if (deltaLeft < deltaRight) {
        position = Offset(leftEdge, position.dy);
      } else {
        position = Offset(rightEdge, position.dy);
      }
    }

    if (position.dy > screenSize.height / 4 &&
        position.dy < screenSize.height * 3 / 4) {
      if (deltaTop < deltaBottom) {
        position = Offset(position.dx, topEdge);
      } else {
        position = Offset(position.dx, bottomEdge);
      }
    }

    setState(() {
      _localVideoPosition = position;
    });
  }

  Widget _localVideo() {
    return _localUserJoined
        ? Positioned(
            left: _localVideoPosition.dx,
            top: _localVideoPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _localVideoPosition += details.delta;

                  _localVideoPosition = Offset(
                    _localVideoPosition.dx.clamp(
                        0.0, MediaQuery.of(context).size.width - videoWidth),
                    _localVideoPosition.dy.clamp(
                        0.0, MediaQuery.of(context).size.height - videoHeight),
                  );
                });
              },
              onPanEnd: (details) {
                final screenSize = MediaQuery.of(context).size;
                _snapToEdge(_localVideoPosition, screenSize);
              },
              child: Container(
                width: videoWidth,
                height: videoHeight,
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine,
                    canvas: VideoCanvas(
                      uid: 0,
                      renderMode: RenderModeType.renderModeHidden,
                    ),
                  ),
                ),
              ),
            ),
          )
        : Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(child: _remoteVideo()),
          Positioned(
            bottom: 120,
            right: 20,
            child: _localVideo(),
          ),
          if (_localUserJoined)
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 100,
                height: MediaQuery.of(context).size.height,
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine,
                    canvas: VideoCanvas(
                      uid: int.parse(
                          widget.userProfile.phoneNumber!.substring(1)),
                      renderMode: RenderModeType.renderModeFit,
                    ),
                  ),
                ),
              ),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.grey.shade800,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.flip_camera_ios_rounded,
                        color: Colors.white),
                    onPressed: _switchCamera,
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
                      widget.userProfile.phoneNumber!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
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
                    icon:
                        Icon(Icons.person_add_alt_1_sharp, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
