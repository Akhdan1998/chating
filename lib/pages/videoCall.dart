import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:chating/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import '../service/alert_service.dart';
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
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  final GetIt _getIt = GetIt.instance;
  late AlertService _alertService;
  late String channelName;
  Timer? _callTimer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    channelName = widget.userProfile.phoneNumber!;
    _alertService = _getIt.get<AlertService>();
    _initAgora();
    // _initializeCameras();
    // context.read<VCCubit>().getVC(channelName);
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

  Future<void> joinChannel() async {
    await _engine.joinChannel(
      token: token,
      channelId: channelName,
      options: const ChannelMediaOptions(
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
      uid: int.parse(widget.userProfile.phoneNumber!.substring(1)),
    );

    print('TOKEN VIDEO CALLLLLLL ${token}');
    print('NUMBER ${widget.userProfile.phoneNumber!.substring(1)}');

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
          Navigator.pop(context);
        },
        onError: (ErrorCodeType err, String msg) {
          print('[onError] err: $err, msg: $msg');
        },
      ),
    );
  }

  Future<void> _initAgora() async {
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

      // String token = await fetchToken('+6281290763984');
      print('TOKEN VIDEO CALL ${token}');

      await _engine.joinChannel(
        token: token,
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

  // Future<void> _initializeCameras() async {
  //   _cameras = await availableCameras();
  //   _currentCameraIndex = _cameras.indexWhere((camera) => camera.lensDirection == CameraLensDirection.front);
  //
  //   _initializeController();
  // }

  // Future<void> _initializeController() async {
  //   final camera = _cameras[_currentCameraIndex];
  //   _controller = CameraController(camera, ResolutionPreset.high);
  //
  //   _initializeControllerFuture = _controller.initialize().then((_) async {
  //     await _controller.initialize();
  //     await _controller.setExposureMode(ExposureMode.auto);
  //     await _controller.setFocusMode(FocusMode.auto);
  //     setState(() {});
  //   });
  // }

  // Future<void> _toggleCamera() async {
  //   if (_cameras.length < 2) return;
  //
  //   await _controller.dispose();
  //   _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
  //   _initializeController();
  // }

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
    // _controller.dispose();
    super.dispose();
  }

  Widget _remoteVideo() {
    return _remoteUid != null
        ? AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _engine,
              canvas: VideoCanvas(
                uid: _remoteUid,
                renderMode: RenderModeType.renderModeFit,
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

  // Future<String?> fetchToken(String channelName) async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('http://45.130.229.79:5656/vc-token?channelName=$channelName&uid=123'),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> data = jsonDecode(response.body);
  //       final token = data['token'];
  //       print('Token: $token');
  //       print('RESPONSE : ${response.body}');
  //       return token;
  //     } else {
  //       print('Error: ${response.statusCode} - ${response.reasonPhrase}');
  //     }
  //   } catch (e) {
  //     print('Exception: $e');
  //   }
  //   return null;
  // }

  // Future<void> _initAgora() async {
  //   try {
  //     await _requestPermissions();
  //
  //     _engine = await createAgoraRtcEngine();
  //     await _engine.initialize(RtcEngineContext(appId: appId));
  //     await _engine.enableVideo();
  //     await _engine.startPreview();
  //
  //     // Mendaftarkan event handler untuk menangani event yang terjadi di channel
  //     _engine.registerEventHandler(RtcEngineEventHandler(
  //       onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
  //         debugPrint("Local user ${connection.localUid} joined");
  //         setState(() {
  //           _localUserJoined = true;
  //         });
  //       },
  //       onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
  //         debugPrint("Remote user $remoteUid joined");
  //         setState(() {
  //           _remoteUid = remoteUid;
  //         });
  //       },
  //       onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
  //         debugPrint("Remote user $remoteUid left channel");
  //         setState(() {
  //           _remoteUid = null;
  //         });
  //       },
  //       onError: (ErrorCodeType err, String msg) {
  //         debugPrint('[onError] err: $err, msg: $msg');
  //       },
  //     ));
  //
  //     // Ambil token dari server
  //     String? token = await fetchToken('+6281290763984');
  //
  //     if (token != null) {
  //       debugPrint('Token retrieved: $token');
  //       // Jika token berhasil diambil, bergabung ke channel
  //       await joinChannel(token);
  //     } else {
  //       debugPrint("Token is null, failed to join channel.");
  //     }
  //   } catch (e) {
  //     debugPrint("Error initializing Agora: $e");
  //   }
  // }

  // Future<void> _initAgora() async {
  //   try {
  //     await _requestPermissions();
  //
  //     _engine = await createAgoraRtcEngine();
  //     await _engine.initialize(RtcEngineContext(appId: appId));
  //     await _engine.enableVideo();
  //     await _engine.startPreview();
  //
  //     _engine.registerEventHandler(RtcEngineEventHandler(
  //       onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
  //         setState(() {
  //           _localUserJoined = true;
  //         });
  //       },
  //       onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
  //         setState(() {
  //           _remoteUid = remoteUid;
  //         });
  //       },
  //       onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
  //         setState(() {
  //           _remoteUid = null;
  //         });
  //       },
  //       onError: (ErrorCodeType err, String msg) {
  //         debugPrint('[onError] err: $err, msg: $msg');
  //       },
  //     ));
  //
  //     String? token = await fetchToken('userId');
  //
  //     if (token != null) {
  //       debugPrint('Token berhasil didapatkan: $token');
  //
  //       await _engine.joinChannel(
  //         token: token,
  //         channelId: 'userId',
  //         options: ChannelMediaOptions(
  //           autoSubscribeVideo: true,
  //           autoSubscribeAudio: true,
  //           publishCameraTrack: true,
  //           publishMicrophoneTrack: true,
  //           clientRoleType: ClientRoleType.clientRoleBroadcaster,
  //         ),
  //         uid: int.parse(widget.phoneNumber.substring(1)),
  //       );
  //     } else {
  //       debugPrint('Gagal mendapatkan token');
  //     }
  //   } catch (e) {
  //     debugPrint("Error initializing Agora: $e");
  //   }
  // }

  // Future<String?> fetchToken(String channelName) async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('http://45.130.229.79:5656/vc-token?channelName=$channelName&uid=123'),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> data = jsonDecode(response.body);
  //       final token = data['token'];
  //       debugPrint('RESPONSE : ${response.body}');
  //       debugPrint('STATUS CODE : ${response.statusCode}');
  //       debugPrint('TOKEN : $token');
  //       debugPrint('CHANNEL NAME : $channelName');
  //       return token;
  //     } else {
  //       debugPrint('Errorrrrrrrrrr: ${response.statusCode} - ${response.reasonPhrase}');
  //     }
  //   } catch (e) {
  //     debugPrint('Exception: $e');
  //   }
  //   return null;
  // }

  // Future<void> joinChannel(String token) async {
  //   try {
  //     await _engine.joinChannel(
  //       token: token,
  //       channelId: '+6281290763984',
  //       options: const ChannelMediaOptions(
  //         autoSubscribeVideo: true,
  //         autoSubscribeAudio: true,
  //         publishCameraTrack: true,
  //         publishMicrophoneTrack: true,
  //         clientRoleType: ClientRoleType.clientRoleBroadcaster,
  //       ),
  //       uid: int.parse(widget.phoneNumber.substring(1)),
  //     );
  //
  //     debugPrint('Joined channel with TOKEN: $token');
  //     debugPrint('Using UID: ${widget.phoneNumber.substring(1)}');
  //
  //     // Aktifkan video dan mulai preview setelah bergabung ke channel
  //     await _engine.enableVideo();
  //     await _engine.startPreview();
  //
  //     // Mendaftarkan ulang event handler setelah bergabung ke channel
  //     _engine.registerEventHandler(
  //       RtcEngineEventHandler(
  //         onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
  //           debugPrint("Local user ${connection.localUid} joined");
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
  //         onError: (ErrorCodeType err, String msg) {
  //           debugPrint('[onError] err: $err, msg: $msg');
  //         },
  //         onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
  //           debugPrint("Remote user $remoteUid left channel");
  //           setState(() {
  //             _remoteUid = null;
  //           });
  //         },
  //       ),
  //     );
  //   } catch (e) {
  //     debugPrint("Error joining channel: $e");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    canvas: VideoCanvas(
                      uid: int.parse(widget.userProfile.phoneNumber!.substring(1)),
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
                  // BlocBuilder<VCCubit, VCState>(builder: (context, state) {
                  //   if (state is VCLoaded) {
                  //     if (state.getvc != null) {
                  //       return GestureDetector(
                  //         onTap: () async {
                  //           String? token =
                  //               await fetchToken(state.getvc!.channelName!);
                  //           print('CHENNEL ${token}');
                  //           if (token != null) {
                  //             await joinChannel(token);
                  //           } else {
                  //             debugPrint(
                  //                 "Failed to get token, cannot join channel.");
                  //           }
                  //         },
                  //         child: Container(
                  //           padding: EdgeInsets.all(15),
                  //           decoration: BoxDecoration(
                  //             borderRadius: BorderRadius.circular(15),
                  //             color: Colors.black.withOpacity(0.2),
                  //           ),
                  //           child: Icon(Icons.call, color: Colors.green),
                  //         ),
                  //       );
                  //     } else {
                  //       return Container();
                  //     }
                  //   } else {
                  //     return Container();
                  //   }
                  // }),
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
                    onPressed:  _switchCamera,
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
                    Text(_remoteUid != null
                        ? _formatDuration(_secondsElapsed)
                        : 'Berdering...',
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
