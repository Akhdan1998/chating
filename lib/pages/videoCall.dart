// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:camera/camera.dart';
//
// const String appId = 'de71d649f3e24489b4b66acd07983a96';
// const String token =
//     '007eJxTYPA8ZLN/482MfYX3zC7IfOb/+LWwW/pOzuuna16wFZ+96/RJgSEl1dwwxczEMs041cjExMIyySTJzCwxOcXA3NLCONHSzEvxelpDICNDiow1KyMDBIL4fAzaZkYWhkaWBuZmxpYWJgwMAKDnIww=';
//
// class VideoCallScreen extends StatefulWidget {
//   final String phoneNumber;
//
//   VideoCallScreen({required this.phoneNumber});
//
//   @override
//   _VideoCallScreenState createState() => _VideoCallScreenState();
// }
//
// class _VideoCallScreenState extends State<VideoCallScreen> {
//   int? _remoteUid;
//   late final RtcEngine _engine;
//   bool _localUserJoined = false;
//   late CameraController _controller;
//   late Future<void> _initializeControllerFuture;
//   List<CameraDescription> _cameras = [];
//   int _currentCameraIndex = 0;
//   bool _isMuted = false;
//   bool _isVideoEnabled = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _initAgora();
//     _initializeCameras();
//     print('PHONE NUMBERRRRRRRRRRRRR ${widget.phoneNumber}');
//
//     availableCameras().then((cameras) {
//       final CameraDescription camera = cameras.first;
//       _controller = CameraController(
//         camera,
//         ResolutionPreset.high,
//       );
//
//       _initializeControllerFuture = _controller.initialize().then((_) async {
//         await _controller.setExposureMode(ExposureMode.auto);
//         await _controller.setFocusMode(FocusMode.auto);
//       });
//
//       setState(() {});
//     });
//   }
//
//   Future<void> _initAgora() async {
//     try {
//       await _requestPermissions();
//
//       _engine = await createAgoraRtcEngine();
//
//       await _engine.initialize(const RtcEngineContext(
//         appId: appId,
//         channelProfile: ChannelProfileType.channelProfileCommunication,
//       ));
//
//       await _engine.enableVideo();
//
//       await _engine.startPreview();
//
//       _engine.registerEventHandler(
//         RtcEngineEventHandler(
//           onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
//             debugPrint("local user ${connection.localUid} joined");
//             setState(() {
//               _localUserJoined = true;
//             });
//           },
//           onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
//             debugPrint("Remote user $remoteUid joined");
//             setState(() {
//               _remoteUid = remoteUid;
//             });
//           },
//           onUserOffline: (RtcConnection connection, int remoteUid,
//               UserOfflineReasonType reason) {
//             debugPrint("Remote user $remoteUid left channel");
//             setState(() {
//               _remoteUid = null;
//             });
//           },
//           onError: (ErrorCodeType err, String msg) {
//             print('[onError] err: $err, msg: $msg');
//           },
//         ),
//       );
//
//       await _engine.joinChannel(
//         token: token,
//         channelId: '+6281290763984',
//         options: const ChannelMediaOptions(
//           autoSubscribeVideo: true,
//           autoSubscribeAudio: true,
//           publishCameraTrack: true,
//           publishMicrophoneTrack: true,
//           clientRoleType: ClientRoleType.clientRoleBroadcaster,
//         ),
//         uid: int.parse(widget.phoneNumber.substring(1)),
//       );
//
//       print('TOKENNNNN ${token}');
//       print('NUMBERRR ${widget.phoneNumber.substring(1)}');
//     } catch (e) {
//       debugPrint("Error initializing Agora: $e");
//     }
//   }
//
//   Future<void> joinChannel() async {
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
//     print('TOKENNNNN ${token}');
//     print('NUMBERRR ${widget.phoneNumber.substring(1)}');
//
//     await _engine.enableVideo();
//
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
//         onError: (ErrorCodeType err, String msg) {
//           print('[onError] err: $err, msg: $msg');
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
//   }
//
//   Future<void> _requestPermissions() async {
//     await [Permission.camera, Permission.microphone].request();
//   }
//
//   Future<void> _initializeCameras() async {
//     _cameras = await availableCameras();
//     _currentCameraIndex = _cameras.indexWhere(
//       (camera) => camera.lensDirection == CameraLensDirection.front,
//     );
//
//     _initializeController();
//   }
//
//   Future<void> _initializeController() async {
//     _controller = CameraController(
//       _cameras[_currentCameraIndex],
//       ResolutionPreset.high,
//     );
//
//     _initializeControllerFuture = _controller.initialize().then((_) async {
//       await _controller.setExposureMode(ExposureMode.auto);
//       await _controller.setFocusMode(FocusMode.auto);
//     });
//
//     setState(() {});
//   }
//
//   void _toggleCamera() async {
//     if (_cameras.length < 2) return;
//
//     await _controller.dispose();
//
//     _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
//
//     _initializeController();
//   }
//
//   void _toggleMute() async {
//     if (_isMuted) {
//       // Aktifkan mikrofon
//       await _engine.muteLocalAudioStream(false);
//     } else {
//       // Matikan mikrofon
//       await _engine.muteLocalAudioStream(true);
//     }
//
//     // Update status mikrofon
//     setState(() {
//       _isMuted = !_isMuted;
//     });
//   }
//
//   void _endCall() async {
//     // Matikan panggilan di Agora
//     await _engine.leaveChannel();
//
//     // Lepaskan sumber daya Agora
//     await _engine.release();
//
//     // Hapus kontroler kamera jika ada
//     await _controller?.dispose();
//
//     // Kembali ke layar sebelumnya
//     Navigator.pop(context);
//   }
//
//   void _toggleVideo() async {
//     if (_isVideoEnabled) {
//       // Matikan video
//       await _engine.muteLocalVideoStream(true);
//     } else {
//       // Aktifkan video
//       await _engine.muteLocalVideoStream(false);
//     }
//
//     // Update status video
//     setState(() {
//       _isVideoEnabled = !_isVideoEnabled;
//     });
//   }
//
//   @override
//   void dispose() {
//     _engine.leaveChannel();
//     _engine.release();
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Stack(
//         children: [
//           Center(child: _remoteVideo()),
//           if (_localUserJoined)
//             Align(
//               alignment: Alignment.topLeft,
//               child: SizedBox(
//                 width: 100,
//                 height: MediaQuery.of(context).size.height,
//                 child: AgoraVideoView(
//                   controller: VideoViewController(
//                     rtcEngine: _engine,
//                     canvas: VideoCanvas(
//                         uid: 1234, renderMode: RenderModeType.renderModeFit),
//                   ),
//                 ),
//               ),
//             ),
//           Positioned(
//             bottom: 20,
//             left: 20,
//             right: 20,
//             child: Container(
//               width: MediaQuery.sizeOf(context).width,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(15),
//                 color: Colors.black.withOpacity(0.1),
//               ),
//               padding: EdgeInsets.all(10),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   IconButton(
//                     onPressed: () {},
//                     icon: Icon(
//                       Icons.more_horiz,
//                       color: Colors.black,
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: _toggleVideo,
//                     icon: Icon(
//                       _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
//                       color: Colors.black,
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: () {},
//                     icon: Icon(
//                       Icons.volume_up,
//                       color: Colors.black,
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: _toggleMute,
//                     icon: Icon(
//                       _isMuted ? Icons.mic_off : Icons.mic,
//                       color: Colors.black,
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: _endCall,
//                     icon: Icon(
//                       Icons.call_end,
//                       color: Colors.black,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           Positioned(
//             top: 60,
//             left: 20,
//             right: 20,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(15),
//                     color: Colors.black.withOpacity(0.1),
//                   ),
//                   child: IconButton(
//                     icon: Icon(
//                       Icons.flip_camera_ios_rounded,
//                       color: Colors.black,
//                     ),
//                     onPressed: _toggleCamera,
//                   ),
//                 ),
//                 Column(
//                   children: [
//                     Text(
//                       'WKWKWKWKWKWKWK',
//                       style: TextStyle(
//                         color: Colors.black,
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text('Berdering...'),
//                   ],
//                 ),
//                 Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(15),
//                     color: Colors.black.withOpacity(0.1),
//                   ),
//                   child: IconButton(
//                     icon: Icon(
//                       Icons.person_add_alt_1_sharp,
//                       color: Colors.black,
//                     ),
//                     onPressed: () {},
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       // floatingActionButton: FloatingActionButton(
//       //   onPressed: () {
//       //     joinChannel();
//       //   },
//       // ),
//     );
//   }
//
//   Widget _remoteVideo() {
//     if (_remoteUid != null) {
//       return AgoraVideoView(
//         controller: VideoViewController.remote(
//           rtcEngine: _engine,
//           canvas: VideoCanvas(
//               uid: _remoteUid, renderMode: RenderModeType.renderModeFit),
//           connection: RtcConnection(
//             channelId: widget.phoneNumber,
//           ),
//         ),
//       );
//     } else {
//       return Container(
//         width: MediaQuery.sizeOf(context).width,
//         height: MediaQuery.sizeOf(context).height,
//         child: _controller == null
//             ? Center(child: CircularProgressIndicator())
//             : FutureBuilder<void>(
//                 future: _initializeControllerFuture,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.done) {
//                     // Menampilkan preview kamera dengan rasio aspek yang benar
//                     return CameraPreview(_controller!);
//                   } else {
//                     // Menampilkan loading indicator saat kamera sedang diinisialisasi
//                     return Center(child: CircularProgressIndicator());
//                   }
//                 },
//               ),
//       );
//     }
//   }
// }

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';

import '../service/alert_service.dart';

const String appId = 'de71d649f3e24489b4b66acd07983a96';
const String token = '007eJxTYPA8ZLN/482MfYX3zC7IfOb/+LWwW/pOzuuna16wFZ+96/RJgSEl1dwwxczEMs041cjExMIyySTJzCwxOcXA3NLCONHSzEvxelpDICNDiow1KyMDBIL4fAzaZkYWhkaWBuZmxpYWJgwMAKDnIww=';

class VideoCallScreen extends StatefulWidget {
  final String phoneNumber;

  VideoCallScreen({required this.phoneNumber});

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

  @override
  void initState() {
    super.initState();
    _alertService = _getIt.get<AlertService>();
    _initAgora();
    _initializeCameras();
  }

  Future<void> joinChannel() async {
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

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    if (cameraStatus != PermissionStatus.granted || microphoneStatus != PermissionStatus.granted) {
      _alertService.showToast(
        text: 'Camera and microphone permissions are required.',
        icon: Icons.warning,
        color: Colors.yellowAccent,
      );
      return;
    }

    _initializeCameras();
  }

  Future<void> _initializeCameras() async {
    _cameras = await availableCameras();
    _currentCameraIndex = _cameras.indexWhere((camera) => camera.lensDirection == CameraLensDirection.front);

    _initializeController();
  }

  Future<void> _initializeController() async {
    final camera = _cameras[_currentCameraIndex];
    _controller = CameraController(camera, ResolutionPreset.high);

    _initializeControllerFuture = _controller.initialize().then((_) async {
      await _controller.setExposureMode(ExposureMode.auto);
      await _controller.setFocusMode(FocusMode.auto);
      setState(() {});
    });
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length < 2) return;

    await _controller.dispose();
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    _initializeController();
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
    await _controller.dispose();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    _controller.dispose();
    super.dispose();
  }

  Widget _remoteVideo() {
    return _remoteUid != null
        ? AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _engine,
              canvas: VideoCanvas(
                  uid: _remoteUid, renderMode: RenderModeType.renderModeFit),
              connection: RtcConnection(channelId: '+6281290763984'),
            ),
          )
        : FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Container(
                    height: MediaQuery.sizeOf(context).height,
                    width: MediaQuery.sizeOf(context).width,
                    child: CameraPreview(_controller));
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          );
  }

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
                      uid: int.parse(widget.phoneNumber.substring(1)),
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
                      child: Icon(_isVideoEnabled ? Icons.videocam : Icons.videocam_off, color: Colors.white),
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
                      child: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      joinChannel();
                    },
                    child: Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.black.withOpacity(0.2),
                      ),
                      child:Icon(Icons.call, color: Colors.green),
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
                      child:Icon(Icons.call_end, color: Colors.redAccent),
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
                    icon: Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
                    onPressed: _toggleCamera,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      'WKWKWKWKWKWKWK',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Berdering...'),
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
        ],
      ),
    );
  }
}