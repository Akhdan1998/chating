import 'dart:io';

import 'package:camera/camera.dart';
import 'package:chating/widgets/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:image/image.dart' as img;
import '../pages/Story/updates.dart';
import '../service/alert_service.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  bool _isCamera = true;
  bool _isVideo = false;
  FlashMode _flashMode = FlashMode.off;
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  double _currentZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _cameraController = CameraController(
        enableAudio: true,
        _cameras[0],
        ResolutionPreset.high,
      );
      await _cameraController.initialize();

      _maxZoomLevel = await _cameraController.getMaxZoomLevel();
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    if (_currentZoomLevel < _maxZoomLevel) {
      setState(() {
        _currentZoomLevel += 0.1;
        _cameraController.setZoomLevel(_currentZoomLevel);
      });
    }
  }

  void _zoomOut() {
    if (_currentZoomLevel > 1.0) {
      setState(() {
        _currentZoomLevel -= 0.1;
        _cameraController.setZoomLevel(_currentZoomLevel);
      });
    }
  }

  Future<void> _takePicture() async {
    if (!_cameraController.value.isInitialized) return;

    final XFile picture = await _cameraController.takePicture();
    print('Picture saved to: ${picture.path}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewScreen(
          filePath: picture.path,
          isVideo: false,
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    if (!_cameraController.value.isInitialized) return;

    await _cameraController.startVideoRecording();
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    if (!_cameraController.value.isInitialized) return;

    final XFile video = await _cameraController.stopVideoRecording();
    setState(() {
      _isRecording = false;
    });
    print('Video saved to: ${video.path}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewScreen(
          filePath: video.path,
          isVideo: true,
        ),
      ),
    );
  }

  Future<void> _flipCamera() async {
    final CameraDescription newCamera =
    _cameraController.description == _cameras[0]
        ? _cameras[1]
        : _cameras[0];

    _cameraController = CameraController(newCamera, ResolutionPreset.high);
    await _cameraController.initialize();
    setState(() {});
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
        print('Image selected: ${image.path}');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PreviewScreen(
              filePath: image.path,
              isVideo: false,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _toggleFlash() {
    setState(() {
      switch (_flashMode) {
        case FlashMode.off:
          _flashMode = FlashMode.auto;
          break;
        case FlashMode.auto:
          _flashMode = FlashMode.torch;
          break;
        case FlashMode.torch:
          _flashMode = FlashMode.off;
          break;
        default:
          _flashMode = FlashMode.off;
      }
      _cameraController.setFlashMode(_flashMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isCameraInitialized
          ? Stack(
              children: [
                Positioned.fill(
                  child: AspectRatio(
                    aspectRatio: _cameraController.value.aspectRatio,
                    child: CameraPreview(_cameraController),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  left: 0,
                  child: Container(
                    alignment: Alignment.centerLeft,
                    color: Colors.black.withOpacity(0.2),
                    padding: EdgeInsets.only(
                        left: 15, right: 15, top: 35, bottom: 5),
                    child: IconButton(
                      onPressed: _toggleFlash,
                      icon: Icon(
                        _flashMode == FlashMode.off
                            ? Icons.flash_off
                            : _flashMode == FlashMode.auto
                                ? Icons.flash_auto
                                : Icons.flash_on,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  left: 0,
                  child: Container(
                    color: Colors.transparent,
                    padding: EdgeInsets.only(
                        left: 15, right: 15, top: 10, bottom: 10),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(onPressed: _zoomOut, icon: Icon(Icons.zoom_out, color: Colors.white, size: 20,),),
                            IconButton(onPressed: _zoomIn, icon: Icon(Icons.zoom_in, color: Colors.white, size: 20,),),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isCamera = true;
                                  _isVideo = false;
                                });
                              },
                              child: Text(
                                'Camera',
                                style: StyleText(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isCamera = false;
                                  _isVideo = true;
                                });
                              },
                              child: Text(
                                'Video',
                                style: StyleText(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: _pickImageFromGallery,
                              icon: Icon(
                                Icons.photo_library,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                if (_isCamera) {
                                  await _takePicture();
                                } else if (_isVideo) {
                                  if (_isRecording) {
                                    await _stopRecording();
                                  } else {
                                    await _startRecording();
                                  }
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: _isVideo
                                          ? Colors.transparent
                                          : (_isCamera
                                              ? Colors.white
                                              : Colors.transparent),
                                      spreadRadius: 2,
                                      blurRadius: 0,
                                      offset: Offset(0, 0),
                                    ),
                                  ],
                                  border: Border.all(
                                      color: _isVideo
                                          ? Colors.white
                                          : (_isCamera
                                              ? Colors.black
                                              : Colors.transparent),
                                      width: 2),
                                  color: _isVideo
                                      ? Colors.red
                                      : (_isCamera
                                          ? Colors.white
                                          : Colors.transparent),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _flipCamera,
                              icon: Icon(
                                Icons.flip_camera_android,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}

class PreviewScreen extends StatefulWidget {
  final String filePath;
  final bool isVideo;

  const PreviewScreen({required this.filePath, required this.isVideo});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late AlertService _alertService;
  final GetIt _getIt = GetIt.instance;
  final currentUser =FirebaseAuth.instance;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _alertService = _getIt.get<AlertService>();
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController captionController = TextEditingController();
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: widget.isVideo
                ? VideoPreviewWidget(filePath: widget.filePath)
                : PhotoPreviewWidget(filePath: widget.filePath),
          ),
          Positioned(
            top: 0,
            right: 0,
            left: 0,
            child: Container(
              // color: Colors.black.withOpacity(0.2),
              padding: EdgeInsets.only(
                  left: 15, right: 15, top: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 20,),
                    ),
                  ),
                  (widget.isVideo) ? Container() : GestureDetector(
                    onTap: () async {
                      await cropPhoto(context, widget.filePath);
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.crop, color: Colors.white, size: 20,),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: captionController,
                      style: StyleText(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'hint_caption'.tr(),
                        hintStyle: StyleText(color: Colors.white),
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.3),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: () async {
                      context.loaderOverlay.show();

                      try {
                        // File asli
                        final file = File(widget.filePath);
                        print('Ukuran file sebelum kompresi: ${file.lengthSync()} bytes');

                        // Kompresi gambar
                        final image = img.decodeImage(file.readAsBytesSync())!;
                        final compressedImage = img.encodeJpg(image, quality: 50);
                        final compressedFilePath = '${file.path}.jpg';
                        final compressedFile = await File(compressedFilePath).writeAsBytes(compressedImage);
                        print('Ukuran file setelah kompresi: ${compressedFile.lengthSync()} bytes');

                        // Nama file di Firebase Storage
                        final fileName = 'stories/images/${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';

                        // Upload ke Firebase Storage
                        final uploadTask = FirebaseStorage.instance.ref().child(fileName).putFile(compressedFile);
                        final taskSnapshot = await uploadTask;
                        final downloadUrl = await taskSnapshot.ref.getDownloadURL();

                        // Simpan metadata ke Firestore
                        final localTimestamp = DateTime.now();
                        await FirebaseFirestore.instance.runTransaction((transaction) async {
                          final storiesRef = FirebaseFirestore.instance.collection('stories').doc();
                          final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.currentUser!.uid);

                          transaction.set(storiesRef, {
                            'url': downloadUrl,
                            'type': widget.isVideo ? 'video' : 'image',
                            'uid': currentUser.currentUser!.uid,
                            'description': captionController.text,
                            'timestamp': localTimestamp,
                          });

                          transaction.update(userRef, {
                            'hasUploadedStory': true,
                            'latestStoryUrl': downloadUrl,
                          });
                        });

                        context.loaderOverlay.hide();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UpdatesPage(),
                          ),
                        );
                      } catch (e) {
                        context.loaderOverlay.hide();
                        _alertService.showToast(
                          text: e.toString(),
                          icon: Icons.error,
                          color: Colors.red,
                        );
                        print('Failed to upload: $e');
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.send, color: Colors.white),
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

  Future<void> cropPhoto(BuildContext context, String filePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: filePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.white,
          toolbarWidgetColor: Colors.black,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio16x9,
            CropAspectRatioPreset.ratio4x3,
          ],
          activeControlsWidgetColor: Colors.blue,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio16x9,
            CropAspectRatioPreset.ratio4x3,
          ],
        ),
      ],
    );

    if (croppedFile != null) {
      // Save the cropped file or update the UI
      print('Cropped image saved at: ${croppedFile.path}');
    }
  }
}

class PhotoPreviewWidget extends StatelessWidget {
  final String filePath;

  const PhotoPreviewWidget({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return PhotoView(
      imageProvider: FileImage(File(filePath)),
      backgroundDecoration: BoxDecoration(
        color: Colors.black,
      ),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 2.0,
      initialScale: PhotoViewComputedScale.contained,
    );
  }
}

class VideoPreviewWidget extends StatefulWidget {
  final String filePath;

  const VideoPreviewWidget({required this.filePath});

  @override
  _VideoPreviewWidgetState createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  late FlickManager flickManager;

  @override
  void initState() {
    super.initState();
    flickManager = FlickManager(
      videoPlayerController: VideoPlayerController.file(File(widget.filePath)),
    );
  }

  @override
  void dispose() {
    flickManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlickVideoPlayer(
      flickManager: flickManager,
      flickVideoWithControls: FlickVideoWithControls(
        // controls: FlickPortraitControls(
        //   progressBarSettings: FlickProgressBarSettings(),
        // ), // Kontrol video default
      ),
    );
  }
}