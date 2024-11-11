// import 'package:chating/utils.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_layout_grid/flutter_layout_grid.dart';
// import 'package:video_player/video_player.dart' as vp;
// import '../consts.dart';
//
// class MediaPage extends StatefulWidget {
//
//   @override
//   State<MediaPage> createState() => _MediaPageState();
// }
//
// class _MediaPageState extends State<MediaPage> {
//   int _selectedIndex = 0;
//   PageController controller = PageController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   void _navigateBottomBar(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//
//     controller.animateToPage(_selectedIndex,
//         duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     controller = PageController(initialPage: _selectedIndex);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           Container(
//             padding: EdgeInsets.only(top: 50),
//             color: Theme.of(context).colorScheme.primary,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 IconButton(
//                   icon: Icon(
//                     Icons.arrow_back,
//                     color: Colors.white,
//                   ),
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                 ),
//                 Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(7),
//                     color: Colors.white,
//                   ),
//                   width: 247,
//                   alignment: Alignment.center,
//                   padding: EdgeInsets.all(2),
//                   child: Row(
//                     children: [
//                       GestureDetector(
//                         onTap: () {
//                           _navigateBottomBar(0);
//                         },
//                         child: Container(
//                           width: 120,
//                           height: 35,
//                           alignment: Alignment.center,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(7),
//                             color: _selectedIndex == 0
//                                 ? Theme.of(context).colorScheme.primary
//                                 : Colors.grey.shade200,
//                           ),
//                           child: Text(
//                             'media'.tr(),
//                             style: StyleText(fontSize: 16,
//                               color: _selectedIndex == 0
//                                   ? Colors.white : Theme.of(context).colorScheme.primary,),
//                           ),
//                         ),
//                       ),
//                       VerticalDivider(
//                         thickness: 2,
//                         width: 3,
//                       ),
//                       GestureDetector(
//                         onTap: () {
//                           _navigateBottomBar(1);
//                         },
//                         child: Container(
//                           width: 120,
//                           height: 35,
//                           alignment: Alignment.center,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(7),
//                             color: _selectedIndex == 1
//                                 ? Theme.of(context).colorScheme.primary
//                                 : Colors.grey.shade200,
//                           ),
//                           child: Text(
//                             'dokumen'.tr(),
//                             style: StyleText(fontSize: 16,
//                               color: _selectedIndex == 1
//                                   ? Colors.white : Theme.of(context).colorScheme.primary,),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(
//                     Icons.more_horiz,
//                     color: Colors.white,
//                   ),
//                   onPressed: () {},
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             height: MediaQuery.of(context).size.height - 98,
//             width: MediaQuery.of(context).size.width,
//             child: PageView(
//               physics: NeverScrollableScrollPhysics(),
//               controller: controller,
//               children: [
//                 Media(),
//                 Document(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget Media() {
//     return Center(
//       child: StreamBuilder(
//         stream: FirebaseFirestore.instance.collection('chats').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return Center(child: Text("No messages found"));
//           }
//
//           final messages = snapshot.data!.docs;
//
//           final mediaMessages = messages.where((message) {
//             var messageList = message['messages'] as List;
//             if (messageList.isEmpty) return false;
//             var messageType = messageList[0]['messageType'];
//             return messageType == 'Image' || messageType == 'Video';
//           }).toList();
//
//           return SingleChildScrollView(
//             child: LayoutGrid(
//               columnSizes: [1.fr, 1.fr],
//               rowSizes: List.generate((mediaMessages.length / 5).ceil(), (_) => auto),
//               rowGap: 3,
//               columnGap: 3,
//               children: [
//                 for (var message in mediaMessages)
//                   Builder(builder: (context) {
//                     var firstMessage = message['messages'][0];
//                     var messageType = firstMessage['messageType'];
//                     var contentUrl = firstMessage['content'];
//
//                     if (messageType == 'Image') {
//                       return Container(
//                         width: 150,
//                         height: 150,
//                         padding: EdgeInsets.all(8.0),
//                         child: Image.network(
//                           contentUrl,
//                           fit: BoxFit.cover,
//                           errorBuilder: (context, error, stackTrace) {
//                             return Icon(Icons.error, color: Colors.red);
//                           },
//                           loadingBuilder: (context, child, loadingProgress) {
//                             if (loadingProgress == null) return child;
//                             return Center(child: Image.network(PLACEHOLDER_PFP));
//                           },
//                         ),
//                       );
//                     } else if (messageType == 'Video') {
//                       return Container(
//                         width: 150,
//                         height: 150,
//                         padding: EdgeInsets.all(8.0),
//                         child: VideoMessage(url: contentUrl),
//                       );
//                     }
//                     return SizedBox.shrink();
//                   }),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget Document() {
//     return Center(
//       child: Text(
//         'dokumen'.tr(),
//         style: StyleText(),
//       ),
//     );
//   }
// }
//
// class VideoMessage extends StatefulWidget {
//   final String url;
//
//   const VideoMessage({Key? key, required this.url}) : super(key: key);
//
//   @override
//   _VideoMessageState createState() => _VideoMessageState();
// }
//
// class _VideoMessageState extends State<VideoMessage> {
//   late vp.VideoPlayerController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = vp.VideoPlayerController.network(widget.url)
//       ..initialize().then((_) {
//         setState(() {});
//       });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return _controller.value.isInitialized
//         ? Container(
//             padding: EdgeInsets.all(8.0),
//             child: AspectRatio(
//               aspectRatio: _controller.value.aspectRatio,
//               child: vp.VideoPlayer(_controller),
//             ),
//           )
//         : Center(child: CircularProgressIndicator());
//   }
// }

import 'dart:io';

import 'package:chating/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
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
                  width: 247,
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(2),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _navigateBottomBar(0),
                        child: Container(
                          width: 120,
                          height: 35,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: _selectedIndex == 0
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade200,
                          ),
                          child: Text(
                            'media'.tr(),
                            style: TextStyle(
                              fontSize: 16,
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
                          width: 120,
                          height: 35,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: _selectedIndex == 1
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade200,
                          ),
                          child: Text(
                            'dokumen'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedIndex == 1
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
                MediaGrid(),
                Document(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget MediaGrid() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('chats').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("no_media".tr(), style: StyleText(color: Colors.grey),),);
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

                    if (messageType == 'Image') {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImageView(
                                imageUrl: contentUrl,
                                chatUser: widget.chatUser,
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
      child: Text(
        'dokumen'.tr(),
        style: TextStyle(fontSize: 16),
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

  ImageView({
    required this.chatUser,
    required this.imageUrl,
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
                text: 'Image downloaded successfully',
                icon: Icons.check,
                color: Colors.green,
              );
            });
          }
        },
        onDownloadError: (error) {
          setState(() {
            _isDownloading = false;
            _progress = 0.0;
            _alertService.showToast(
              text: 'Failed to download image: $error',
              icon: Icons.error,
              color: Colors.red,
            );
          });
        },
      );
    } catch (e) {
      print(e);
      setState(() {
        _isDownloading = false;
        _progress = 0.0;
        _alertService.showToast(
          text: 'Failed to download image: $e',
          icon: Icons.error,
          color: Colors.red,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // DateTime date = DateFormat('yyyy-MM-dd hh:mm').parse(widget.sendAt);
    // String day = DateFormat('yyyy-MM-dd HH:mm').format(date);
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
              'WKWKWK',
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

  const VideoPlayer({
    required this.videoUrl,
    required this.chatUser,
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
                text: 'Video berhasil dikompresi dan disimpan di Downloads',
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
              text: 'Failed to download video',
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
          text: 'Failed to download video: $e',
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
    // DateTime date =
    // DateFormat('yyyy-MM-dd hh:mm').parse(widget.dateTime.toString());
    // String day = DateFormat('yyyy-MM-dd HH:mm').format(date);
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
              'WKWKWKWKWK',
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
