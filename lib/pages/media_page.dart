import 'dart:io';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:chating/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart' as vp;
import 'package:video_player/video_player.dart';

import '../models/user_profile.dart';
import '../service/alert_service.dart';

class MediaPage extends StatefulWidget {
  final UserProfile chatUser;

  MediaPage({
    required this.chatUser,
  });

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  int _selectedIndex = 0;
  PageController controller = PageController();

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
    controller.animateToPage(
      _selectedIndex,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: _selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: 50),
            color: Theme.of(context).colorScheme.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: Colors.white,
                  ),
                  width: 310,
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(2),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _navigateBottomBar(0),
                        child: Container(
                          width: 100,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: _selectedIndex == 0
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade200,
                          ),
                          child: Text(
                            'media'.tr(),
                            style: StyleText(
                              fontSize: 13,
                              color: _selectedIndex == 0
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      VerticalDivider(thickness: 2, width: 3),
                      GestureDetector(
                        onTap: () => _navigateBottomBar(1),
                        child: Container(
                          width: 100,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: _selectedIndex == 1
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade200,
                          ),
                          child: Text(
                            'Tautan',
                            style: StyleText(
                              fontSize: 13,
                              color: _selectedIndex == 1
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      VerticalDivider(thickness: 2, width: 3),
                      GestureDetector(
                        onTap: () => _navigateBottomBar(2),
                        child: Container(
                          width: 100,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: _selectedIndex == 2
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade200,
                          ),
                          child: Text(
                            'dokumen'.tr(),
                            style: StyleText(
                              fontSize: 13,
                              color: _selectedIndex == 2
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              physics: NeverScrollableScrollPhysics(),
              controller: controller,
              children: [
                Media(),
                Tautan(),
                Document(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget Tautan() {

    bool _isUrl(String text) {
      final urlPattern = RegExp(
        r'^(https?|ftp)://[^\s/$.?#].[^\s]*$',
        caseSensitive: false,
      );
      return urlPattern.hasMatch(text);
    }

    return Center(
      child: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('chats').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Container();
          }

          final linkMessages = snapshot.data!.docs.expand((doc) {
            return (doc['messages'] as List)
                .where((msg) => msg['messageType'] == 'Text' && _isUrl(msg['content']));
          }).toList();

          if (linkMessages.isEmpty) {
            return Container();
          }

          return ListView.builder(
            itemCount: linkMessages.length,
            itemBuilder: (context, index) {
              var document = linkMessages[index];
              var contentUrl = document['content'];
              var timestamp = (document['sentAt'] as Timestamp).toDate();
              var formattedDate = DateFormat('dd MMM yyyy HH:mm').format(timestamp);
              void _launchURL(String url) async {
                final Uri uri = Uri.parse(url);
                if (!await launchUrl(uri)) {
                  throw Exception('Could not launch $uri');
                }
              }
              return Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(left: 15, right: 15),
                    child: AnyLinkPreview(
                      displayDirection: UIDirection.uiDirectionHorizontal,
                        link: contentUrl,
                      onTap: () => _launchURL(contentUrl),
                      showMultimedia: true,
                      errorBody: '',
                      bodyStyle: StyleText(fontSize: 12),
                      errorWidget: Container(
                        height: 100,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported_sharp),
                      ),
                      errorImage: "https://google.com/",
                      cache: Duration(seconds: 3),
                      borderRadius: 12,
                      removeElevation: false,
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget Media() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('chats').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "no_media".tr(),
              style: StyleText(color: Colors.grey),
            ),
          );
        }
        final mediaItems = snapshot.data!.docs.expand((doc) {
          var messages = doc['messages'] as List;
          return messages.where((msg) =>
              msg['messageType'] == 'Image' || msg['messageType'] == 'Video');
        }).toList();

        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(10),
            child: LayoutGrid(
              columnSizes: [1.fr, 1.fr],
              rowSizes: List.generate(
                (mediaItems.length / 2).ceil(),
                (_) => auto,
              ),
              rowGap: 12,
              columnGap: 12,
              children: [
                for (var item in mediaItems)
                  Builder(builder: (context) {
                    var messageType = item['messageType'];
                    var contentUrl = item['content'];
                    var timestamp = item['sentAt'].toDate();
                    var formattedDate = timestamp != null
                        ? DateFormat('dd MMM yyyy HH:mm').format(timestamp)
                        : 'No date available';

                    if (messageType == 'Image') {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImageView(
                                imageUrl: contentUrl,
                                chatUser: widget.chatUser,
                                formatDate: formattedDate,
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            contentUrl,
                            fit: BoxFit.cover,
                            height: 200,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(Icons.broken_image_sharp,
                                    color: Colors.grey),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container();
                            },
                          ),
                        ),
                      );
                    } else if (messageType == 'Video') {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayer(
                                videoUrl: contentUrl,
                                chatUser: widget.chatUser,
                                formatDate: formattedDate,
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: VideoMessage(url: contentUrl),
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget Document() {
    return Center(
      child: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('chats').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Container();
          }

          final documentMessages = snapshot.data!.docs.expand((doc) {
            return (doc['messages'] as List)
                .where((msg) => msg['messageType'] == 'Document');
          }).toList();

          if (documentMessages.isEmpty) {
            return Container();
          }

          return ListView.builder(
            itemCount: documentMessages.length,
            itemBuilder: (context, index) {
              var document = documentMessages[index];
              var contentUrl = document['content'];
              var timestamp = (document['sentAt'] as Timestamp).toDate();
              var formattedDate =
                  DateFormat('dd MMM yyyy HH:mm').format(timestamp);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PDFViewScreen(
                        filePath: contentUrl,
                        fileName: document['fileName'] ?? 'Document',
                        dateTime: timestamp,
                      ),
                    ),
                  );
                },
                child: _documentListTile(contentUrl, formattedDate),
              );
            },
          );
        },
      ),
    );
  }

  Widget _documentListTile(String contentUrl, String formattedDate) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.description, color: Colors.blue),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contentUrl,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: StyleText(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, indent: 15, endIndent: 15,),
      ],
    );
  }
}

class PDFViewScreen extends StatefulWidget {
  final String filePath;
  final String fileName;
  final DateTime dateTime;

  const PDFViewScreen({
    required this.filePath,
    required this.fileName,
    required this.dateTime,
  });

  @override
  State<PDFViewScreen> createState() => _PDFViewScreenState();
}

class _PDFViewScreenState extends State<PDFViewScreen> {
  final AlertService _alertService = GetIt.instance.get<AlertService>();
  bool _isDownloading = false;
  double _progress = 0.0;

  Future<void> _downloadFile(String url, String fileName) async {
    if (await Permission.storage.request().isGranted) {
      setState(() => _isDownloading = true);
      try {
        String savePath = await _getSavePath(fileName);
        await Dio().download(
          url,
          savePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              setState(() => _progress = (received / total) * 100);
            }
          },
        );
        _alertService.showToast(
            text: 'file_download'.tr(),
            icon: Icons.check,
            color: Colors.green);
      } catch (e) {
        _alertService.showToast(
            text: 'file_error_download'.tr(),
            icon: Icons.error,
            color: Colors.red);
      } finally {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<String> _getSavePath(String fileName) async {
    final directory = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    return '${directory!.path}/$fileName';
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate =
        DateFormat('yyyy-MM-dd HH:mm').format(widget.dateTime);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: false,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.fileName,
              style: StyleText(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              formattedDate,
              style: StyleText(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async =>
                await _downloadFile(widget.filePath, widget.fileName),
            icon: _isDownloading
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                          value: _progress / 100,
                          color: Colors.white,
                          strokeWidth: 2.0),
                      Text('${_progress.toStringAsFixed(0)}%',
                          style: StyleText(color: Colors.white, fontSize: 12)),
                    ],
                  )
                : Icon(Icons.file_download_outlined, color: Colors.white),
          ),
        ],
      ),
      body: PDFView(
        filePath: widget.filePath,
        onRender: (_pages) => print('Document rendered with $_pages pages'),
        onError: (error) => print(error),
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
            // aspectRatio: _controller.value.aspectRatio,
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
        centerTitle: false,
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
          crossAxisAlignment: CrossAxisAlignment.start,
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

class VideoPlayer extends StatefulWidget {
  final String videoUrl;
  final UserProfile chatUser;
  final String formatDate;

  const VideoPlayer({
    required this.videoUrl,
    required this.chatUser,
    required this.formatDate,
  });

  @override
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  late vp.VideoPlayerController _controller;
  vp.VideoPlayerValue? _videoValue;
  final GetIt _getIt = GetIt.instance;
  late AlertService _alertService;
  double _progress = 0.0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _controller = vp.VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _controller.play();
          _videoValue = _controller.value;
        });
      });

    _controller.addListener(() {
      setState(() {
        _videoValue = _controller.value;
      });
    });

    _alertService = _getIt.get<AlertService>();
  }

  @override
  void dispose() {
    _controller.removeListener(() {});
    _controller.dispose();
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
    final duration = _videoValue?.duration ?? Duration.zero;
    final position = _videoValue?.position ?? Duration.zero;
    final isPlaying = _videoValue?.isPlaying ?? false;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: false,
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _controller.value.isInitialized
                  ? Stack(
                      children: [
                        vp.VideoPlayer(_controller),
                        if (_controller.value.isInitialized)
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isPlaying
                                      ? _controller.pause()
                                      : _controller.play();
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isPlaying
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.white,
                                ),
                                padding: const EdgeInsets.all(16.0),
                                child: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.black,
                                  size: 40.0,
                                ),
                              ),
                            ),
                          ),
                        if (_controller.value.isInitialized)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: StyleText(),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: StyleText(),
                                    ),
                                  ],
                                ),
                              ),
                              ValueListenableBuilder(
                                valueListenable: _controller,
                                builder:
                                    (context, VideoPlayerValue value, child) {
                                  return Slider(
                                    value: value.position.inSeconds
                                        .toDouble()
                                        .clamp(
                                            0.0,
                                            value.duration.inSeconds
                                                .toDouble()),
                                    min: 0.0,
                                    max: value.duration.inSeconds.toDouble(),
                                    onChanged: (newValue) {
                                      _controller.seekTo(
                                          Duration(seconds: newValue.toInt()));
                                    },
                                  );
                                },
                              ),
                              // Slider(
                              //   value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
                              //   min: 0.0,
                              //   max: duration.inSeconds.toDouble(),
                              //   onChanged: (value) {
                              //     _controller.seekTo(Duration(seconds: value.toInt()));
                              //   },
                              // ),
                            ],
                          ),
                      ],
                    )
                  : CircularProgressIndicator(), // Show loading indicator
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
