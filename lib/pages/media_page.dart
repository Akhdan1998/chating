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

import 'package:chating/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:video_player/video_player.dart' as vp;

class MediaPage extends StatefulWidget {
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
          return Center(child: Text("No media found"));
        }

        final mediaItems = snapshot.data!.docs.expand((doc) {
          var messages = doc['messages'] as List;
          return messages.where((msg) =>
              msg['messageType'] == 'Image' || msg['messageType'] == 'Video');
        }).toList();

        return SingleChildScrollView(
          child: LayoutGrid(
            columnSizes: [1.fr, 1.fr],
            rowSizes:
                List.generate((mediaItems.length / 2).ceil(), (_) => auto),
            rowGap: 8,
            columnGap: 8,
            children: [
              for (var item in mediaItems)
                Builder(builder: (context) {
                  var messageType = item['messageType'];
                  var contentUrl = item['content'];

                  if (messageType == 'Image') {
                    return Container(
                      padding: EdgeInsets.all(8.0),
                      child: Image.network(
                        contentUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.error, color: Colors.red);
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(child: CircularProgressIndicator());
                        },
                      ),
                    );
                  } else if (messageType == 'Video') {
                    return Container(
                      padding: EdgeInsets.all(8.0),
                      child: VideoMessage(url: contentUrl),
                    );
                  }
                  return SizedBox.shrink();
                }),
            ],
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
            aspectRatio: _controller.value.aspectRatio,
            child: vp.VideoPlayer(_controller),
          )
        : Center(child: CircularProgressIndicator());
  }
}
