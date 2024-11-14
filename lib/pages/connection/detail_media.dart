import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart' as vp;
import 'package:video_player/video_player.dart';

import '../../models/user_profile.dart';
import '../../service/alert_service.dart';
import '../../utils.dart';

class PDFViewScreen extends StatefulWidget {
  final String filePath;
  final String fileName;
  final DateTime dateTime;

  PDFViewScreen({
    required this.filePath,
    required this.fileName,
    required this.dateTime,
  });

  @override
  _PDFViewScreenState createState() => _PDFViewScreenState();
}

class _PDFViewScreenState extends State<PDFViewScreen> {
  bool _isDownloading = false;
  double _progress = 0.0;
  final GetIt _getIt = GetIt.instance;
  late AlertService _alertService;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _alertService = _getIt.get<AlertService>();
    print('DOK DOK DOK ${widget.filePath}');
  }

  Future<void> _downloadAndSaveFile(String url, String fileName) async {
    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }

      Dio dio = Dio();
      String savePath = await _getFilePath(fileName);

      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print((received / total * 100).toStringAsFixed(0) + "%");
          }
        },
      );

      setState(() {
        _alertService.showToast(
          text: 'file_download'.tr(),
          icon: Icons.check,
          color: Colors.green,
        );
      });
      print('File berhasil diunduh dan disimpan ke $savePath');
    } catch (e) {
      print('--------- $e');
      setState(() {
        _alertService.showToast(
          text: 'file_error_download'.tr(),
          icon: Icons.error,
          color: Colors.red,
        );
      });
    }
  }

  Future<String> _getFilePath(String fileName) async {
    Directory directory;

    if (Platform.isAndroid) {
      directory = (await getExternalStorageDirectory())!;
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    return '${directory.path}/$fileName';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.fileName,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              DateFormat('yyyy/MM/dd, HH:mm', context.locale.toString()).format(widget.dateTime),
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              setState(() {
                _isDownloading = true;
              });
              await _downloadAndSaveFile(widget.filePath, widget.fileName);
              setState(() {
                _isDownloading = false;
              });
            },
            icon: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _isDownloading
                  ? Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _progress / 100,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2.0,
                    key: ValueKey<int>(1),
                  ),
                  Text(
                    '${_progress.toStringAsFixed(0)}%',
                    style: StyleText(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
                  : Icon(
                Icons.file_download_outlined,
                color: Colors.white,
                key: ValueKey<int>(0),
              ),
            ),
          ),
        ],
      ),
      body: PDFView(
        filePath: widget.filePath,
        onError: (error) => print('Error: $error'),
        onRender: (_pages) => print('Document rendered with $_pages pages'),
        onPageError: (page, error) => print('$page: $error'),
      ),
    );
  }
}

class VideoMessage extends StatefulWidget {
  final String url;

  const VideoMessage({Key? key, required this.url}) : super(key: key);

  @override
  _VideoMessageState createState() => _VideoMessageState();
}

class _VideoMessageState extends State<VideoMessage> {
  late vp.VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = vp.VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: 10 / 10.5,
            child: vp.VideoPlayer(_controller),
          )
        : Center(child: CircularProgressIndicator());
  }
}

class ImageView extends StatefulWidget {
  final UserProfile chatUser;
  final String imageUrl;
  final String formatDate;

  ImageView({
    required this.chatUser,
    required this.imageUrl,
    required this.formatDate,
  });

  @override
  State<ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  final GetIt _getIt = GetIt.instance;
  late AlertService _alertService;
  double _progress = 0.0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _alertService = _getIt.get<AlertService>();
  }

  Future<void> downloadImage(String url) async {
    try {
      setState(() {
        _isDownloading = true;
        _progress = 0.0;
      });

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = "${tempDir.path}/temp_image.jpg";

      await FileDownloader.downloadFile(
        url: url,
        name: "temp_image.jpg",
        onProgress: (fileName, progress) {
          setState(() {
            _progress = progress;
            print("Download progress: $progress%");
          });
        },
        onDownloadCompleted: (path) async {
          final compressedFilePath = "${tempDir.path}/compressed_image.jpg";
          final compressedFile = await FlutterImageCompress.compressAndGetFile(
            path,
            compressedFilePath,
            quality: 70,
          );

          if (compressedFile != null) {
            setState(() {
              _isDownloading = false;
              _progress = 0.0;
              _alertService.showToast(
                text: 'download_image'.tr(),
                icon: Icons.check,
                color: Colors.green,
              );
            });
          }
        },
        onDownloadError: (error) {
          setState(() {
            print('Error: ${error}');
            _isDownloading = false;
            _progress = 0.0;
            _alertService.showToast(
              text: 'failed_download_image'.tr(),
              icon: Icons.error,
              color: Colors.red,
            );
          });
        },
      );
    } catch (e) {
      print(e);
      setState(() {
        print('Error: ${e}');
        _isDownloading = false;
        _progress = 0.0;
        _alertService.showToast(
          text: 'failed_download_image'.tr(),
          icon: Icons.error,
          color: Colors.red,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Column(
          children: [
            Text(
              widget.chatUser.name.toString(),
              style: StyleText(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.formatDate,
              style: StyleText(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await downloadImage(widget.imageUrl);
            },
            icon: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _isDownloading
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 27,
                          height: 27,
                          child: CircularProgressIndicator(
                            value: _progress / 100,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2.0,
                            key: ValueKey<int>(1),
                          ),
                        ),
                        Text(
                          '${_progress.toStringAsFixed(0)}%',
                          style: StyleText(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Icon(
                      Icons.file_download_outlined,
                      color: Colors.white,
                      key: ValueKey<int>(0),
                    ),
            ),
          ),
        ],
      ),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(widget.imageUrl),
          backgroundDecoration: BoxDecoration(
            color: Colors.white,
          ),
          minScale: PhotoViewComputedScale.contained * 0.9,
          maxScale: PhotoViewComputedScale.covered * 2,
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final UserProfile chatUser;
  final String formatDate;

  VideoPlayerScreen({
    required this.videoUrl,
    required this.chatUser,
    required this.formatDate,
  });

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late FlickManager flickManager;
  final GetIt _getIt = GetIt.instance;
  late AlertService _alertService;
  double _progress = 0.0;
  bool _isDownloading = false;

  Future<void> _downloadVideo(String url) async {
    try {
      setState(() {
        _isDownloading = true;
      });

      final tempDir = await getTemporaryDirectory();
      final tempPath = "${tempDir.path}/temp_video.mp4";

      await FileDownloader.downloadFile(
        url: url,
        name: "temp_video.mp4",
        onDownloadCompleted: (filePath) async {
          final compressedVideo = await VideoCompress.compressVideo(
            filePath,
            quality: VideoQuality.LowQuality,
            deleteOrigin: true,
          );

          if (compressedVideo != null) {
            final downloadsDir = Directory('/storage/emulated/0/Download');
            final destinationPath = "${downloadsDir.path}/compressed_video.mp4";

            await compressedVideo.file!.copy(destinationPath);

            setState(() {
              _alertService.showToast(
                text: 'download_video'.tr(),
                icon: Icons.check,
                color: Colors.green,
              );
            });
          } else {
            throw 'Video compression failed';
          }
        },
        onDownloadError: (error) {
          setState(() {
            _alertService.showToast(
              text: 'failed_download_video'.tr(),
              icon: Icons.error,
              color: Colors.red,
            );
          });
        },
      );
    } catch (e) {
      print("Error: $e");
      setState(() {
        _alertService.showToast(
          text: 'failed_download_video'.tr(),
          icon: Icons.error,
          color: Colors.red,
        );
      });
    } finally {
      setState(() {
        _isDownloading = false;
        _progress = 0.0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    flickManager = FlickManager(
      videoPlayerController: VideoPlayerController.network(widget.videoUrl),
    );
    _alertService = _getIt.get<AlertService>();
  }

  @override
  void dispose() {
    flickManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Column(
          children: [
            Text(
              widget.chatUser.name.toString(),
              style: StyleText(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.formatDate,
              style: StyleText(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await _downloadVideo(widget.videoUrl);
            },
            icon: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _isDownloading
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 27,
                          height: 27,
                          child: CircularProgressIndicator(
                            value: _progress / 100,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2.0,
                            key: ValueKey<int>(1),
                          ),
                        ),
                        Text(
                          '${_progress.toStringAsFixed(0)}%',
                          style: StyleText(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Icon(
                      Icons.file_download_outlined,
                      color: Colors.white,
                      key: ValueKey<int>(0),
                    ),
            ),
          ),
        ],
      ),
      body: Expanded(
        child: FlickVideoPlayer(
          flickManager: flickManager,
        ),
      ),
    );
  }
}

//

class VideoPlayerGroup extends StatefulWidget {
  final String videoUrl;
  final List<UserProfile> users;

  VideoPlayerGroup({required this.videoUrl, required this.users});

  @override
  _VideoPlayerGroupState createState() => _VideoPlayerGroupState();
}

class _VideoPlayerGroupState extends State<VideoPlayerGroup> {
  late FlickManager flickManager;
  final GetIt _getIt = GetIt.instance;
  late AlertService _alertService;
  double _progress = 0.0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _alertService = _getIt.get<AlertService>();
    flickManager = FlickManager(
      videoPlayerController: VideoPlayerController.network(widget.videoUrl),
    );
  }

  @override
  void dispose() {
    flickManager.dispose();
    super.dispose();
  }

  Future<void> _downloadVideo(String url) async {
    try {
      setState(() {
        _isDownloading = true;
      });

      final tempDir = await getTemporaryDirectory();
      final tempPath = "${tempDir.path}/temp_video.mp4";

      await FileDownloader.downloadFile(
        url: url,
        name: "temp_video.mp4",
        onDownloadCompleted: (filePath) async {
          final compressedVideo = await VideoCompress.compressVideo(
            filePath,
            quality: VideoQuality.LowQuality,
            deleteOrigin: true,
          );

          if (compressedVideo != null) {
            final downloadsDir = Directory('/storage/emulated/0/Download');
            final destinationPath = "${downloadsDir.path}/compressed_video.mp4";

            await compressedVideo.file!.copy(destinationPath);

            setState(() {
              _alertService.showToast(
                text: 'download_video'.tr(),
                icon: Icons.check,
                color: Colors.green,
              );
            });
          } else {
            throw 'Video compression failed';
          }
        },
        onDownloadError: (error) {
          setState(() {
            _alertService.showToast(
              text: 'failed_download_video'.tr(),
              icon: Icons.error,
              color: Colors.red,
            );
          });
        },
      );
    } catch (e) {
      print("Error: $e");
      setState(() {
        _alertService.showToast(
          text: 'failed_download_video'.tr(),
          icon: Icons.error,
          color: Colors.red,
        );
      });
    } finally {
      setState(() {
        _isDownloading = false;
        _progress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Column(
          children: [
            Text(
              widget.users.first.name!,
              style: StyleText(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Wkwkwkwkwk',
              style: StyleText(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await _downloadVideo(widget.videoUrl);
            },
            icon: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _isDownloading
                  ? Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 27,
                    height: 27,
                    child: CircularProgressIndicator(
                      value: _progress / 100,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.0,
                      key: ValueKey<int>(1),
                    ),
                  ),
                  Text(
                    '${_progress.toStringAsFixed(0)}%',
                    style: StyleText(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
                  : Icon(
                Icons.file_download_outlined,
                color: Colors.white,
                key: ValueKey<int>(0),
              ),
            ),
          ),
        ],
      ),
      body: FlickVideoPlayer(flickManager: flickManager),
    );
  }
}

class ImageViewGroup extends StatefulWidget {
  final String imageUrl;
  final List<UserProfile> users;

  ImageViewGroup({
    required this.imageUrl,
    required this.users,
  });

  @override
  State<ImageViewGroup> createState() => _ImageViewGroupState();
}

class _ImageViewGroupState extends State<ImageViewGroup> {
  final GetIt _getIt = GetIt.instance;
  late AlertService _alertService;
  double _progress = 0.0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _alertService = _getIt.get<AlertService>();
  }

  Future<void> downloadImage(String url) async {
    try {
      setState(() {
        _isDownloading = true;
        _progress = 0.0;
      });

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = "${tempDir.path}/temp_image.jpg";

      await FileDownloader.downloadFile(
        url: url,
        name: "temp_image.jpg",
        onProgress: (fileName, progress) {
          setState(() {
            _progress = progress;
            print("Download progress: $progress%");
          });
        },
        onDownloadCompleted: (path) async {
          final compressedFilePath = "${tempDir.path}/compressed_image.jpg";
          final compressedFile = await FlutterImageCompress.compressAndGetFile(
            path,
            compressedFilePath,
            quality: 70,
          );

          if (compressedFile != null) {
            setState(() {
              _isDownloading = false;
              _progress = 0.0;
              _alertService.showToast(
                text: 'download_image'.tr(),
                icon: Icons.check,
                color: Colors.green,
              );
            });
          }
        },
        onDownloadError: (error) {
          setState(() {
            print('Error: ${error}');
            _isDownloading = false;
            _progress = 0.0;
            _alertService.showToast(
              text: 'failed_download_image'.tr(),
              icon: Icons.error,
              color: Colors.red,
            );
          });
        },
      );
    } catch (e) {
      print(e);
      setState(() {
        print('Error: ${e}');
        _isDownloading = false;
        _progress = 0.0;
        _alertService.showToast(
          text: 'failed_download_image'.tr(),
          icon: Icons.error,
          color: Colors.red,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Column(
          children: [
            Text(
              widget.users.first.name!,
              style: StyleText(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'WKWKWKWKWKWK',
              style: StyleText(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await downloadImage(widget.imageUrl);
            },
            icon: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _isDownloading
                  ? Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 27,
                    height: 27,
                    child: CircularProgressIndicator(
                      value: _progress / 100,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.0,
                      key: ValueKey<int>(1),
                    ),
                  ),
                  Text(
                    '${_progress.toStringAsFixed(0)}%',
                    style: StyleText(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
                  : Icon(
                Icons.file_download_outlined,
                color: Colors.white,
                key: ValueKey<int>(0),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(widget.imageUrl),
          backgroundDecoration: BoxDecoration(
            color: Colors.white,
          ),
          minScale: PhotoViewComputedScale.contained * 0.9,
          maxScale: PhotoViewComputedScale.covered * 2,
        ),
      ),
    );
  }
}

class DocsGroup extends StatefulWidget {
  final String docu;
  final List<UserProfile> users;

  DocsGroup({
    required this.docu,
    required this.users,
  });

  @override
  State<DocsGroup> createState() => _DocsGroupState();
}

class _DocsGroupState extends State<DocsGroup> {
  final GetIt _getIt = GetIt.instance;
  late AlertService _alertService;
  double _progress = 0.0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _alertService = _getIt.get<AlertService>();
  }

  Future<void> downloadImage(String url) async {
    try {
      setState(() {
        _isDownloading = true;
        _progress = 0.0;
      });

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = "${tempDir.path}/temp_image.jpg";

      await FileDownloader.downloadFile(
        url: url,
        name: "temp_image.jpg",
        onProgress: (fileName, progress) {
          setState(() {
            _progress = progress;
            print("Download progress: $progress%");
          });
        },
        onDownloadCompleted: (path) async {
          final compressedFilePath = "${tempDir.path}/compressed_image.jpg";
          final compressedFile = await FlutterImageCompress.compressAndGetFile(
            path,
            compressedFilePath,
            quality: 70,
          );

          if (compressedFile != null) {
            setState(() {
              _isDownloading = false;
              _progress = 0.0;
              _alertService.showToast(
                text: 'download_image'.tr(),
                icon: Icons.check,
                color: Colors.green,
              );
            });
          }
        },
        onDownloadError: (error) {
          setState(() {
            print('Error: ${error}');
            _isDownloading = false;
            _progress = 0.0;
            _alertService.showToast(
              text: 'failed_download_image'.tr(),
              icon: Icons.error,
              color: Colors.red,
            );
          });
        },
      );
    } catch (e) {
      print(e);
      setState(() {
        print('Error: ${e}');
        _isDownloading = false;
        _progress = 0.0;
        _alertService.showToast(
          text: 'failed_download_image'.tr(),
          icon: Icons.error,
          color: Colors.red,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Column(
          children: [
            Text(
              widget.users.first.name!,
              style: StyleText(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'WKWKWKWKWKWK',
              style: StyleText(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await downloadImage(widget.docu);
            },
            icon: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _isDownloading
                  ? Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 27,
                    height: 27,
                    child: CircularProgressIndicator(
                      value: _progress / 100,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.0,
                      key: ValueKey<int>(1),
                    ),
                  ),
                  Text(
                    '${_progress.toStringAsFixed(0)}%',
                    style: StyleText(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
                  : Icon(
                Icons.file_download_outlined,
                color: Colors.white,
                key: ValueKey<int>(0),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: PDFView(
          enableSwipe: true,
          swipeHorizontal: true,
          autoSpacing: false,
          pageFling: false,
          onError: (error) {
            print('errorrrrrr ${error}');
          },
          onRender: (_pages) {
            print('Document rendered with $_pages pages');
          },
          onPageError: (page, error) {
            print('$page: ${error.toString()}');
          },
          filePath: widget.docu,
        ),
      ),
    );
  }
}