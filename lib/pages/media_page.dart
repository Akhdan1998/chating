import 'package:any_link_preview/any_link_preview.dart';
import 'package:chating/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/group.dart';
import '../models/user_profile.dart';
import 'connection/detail_media.dart';

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

  Future<void> _downloadAndOpenPDF(
      String url, String fileName, DateTime dateTime) async {
    try {
      Dio dio = Dio();
      var tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;
      String filePath = '$tempPath/temp.pdf';

      await dio.download(url, filePath);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewScreen(
            filePath: filePath,
            fileName: fileName,
            dateTime: dateTime,
          ),
        ),
      );
    } catch (e) {
      print('Error saat mengunduh atau membuka file PDF: $e');
    }
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
                            'tautan'.tr(),
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

          final linkMessages = snapshot.data!.docs
              .expand((doc) {
                return (doc['messages'] as List).where((msg) =>
                    msg['messageType'] == 'Text' && _isUrl(msg['content']));
              })
              .toList()
              .reversed
              .toList();

          if (linkMessages.isEmpty) {
            return Container();
          }

          return ListView.builder(
            itemCount: linkMessages.length,
            itemBuilder: (context, index) {
              var document = linkMessages[index];
              var contentUrl = document['content'];
              // var timestamp = (document['sentAt'] as Timestamp).toDate();
              // var formattedDate = DateFormat('yyyy/MM/dd, HH:mm', context.locale.toString()).format(timestamp);
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
                      errorWidget: Container(),
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
      // stream: FirebaseFirestore.instance
      //     .collection('chats')
      //     .where('id', isEqualTo: widget.chatUser.uid)
      //     .orderBy('sentAt', descending: true)
      //     .snapshots(),
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
        final mediaItems = snapshot.data!.docs
            .expand((doc) {
              var messages = doc['messages'] as List;
              return messages.where((msg) =>
                  msg['messageType'] == 'Image' ||
                  msg['messageType'] == 'Video');
            })
            .toList()
            .reversed
            .toList();

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
                        ? DateFormat(
                                'yyyy/MM/dd, HH:mm', context.locale.toString())
                            .format(timestamp)
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
                          borderRadius: BorderRadius.circular(8),
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
                              builder: (context) => VideoPlayerScreen(
                                videoUrl: contentUrl,
                                chatUser: widget.chatUser,
                                formatDate: formattedDate,
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              VideoMessage(url: contentUrl),
                              Center(
                                child: Icon(
                                  Icons.play_circle,
                                  color: Colors.grey,
                                  size: 50,
                                ),
                              ),
                            ],
                          ),
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

  // Widget Document() {
  //   return Center(
  //     child: StreamBuilder(
  //       stream: FirebaseFirestore.instance.collection('chats').snapshots(),
  //       builder: (context, snapshot) {
  //         if (snapshot.connectionState == ConnectionState.waiting) {
  //           return CircularProgressIndicator();
  //         }
  //
  //         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
  //           return Container();
  //         }
  //
  //         final documentMessages = snapshot.data!.docs
  //             .expand((doc) {
  //               return (doc['messages'] as List)
  //                   .where((msg) => msg['messageType'] == 'Document');
  //             })
  //             .toList()
  //             .reversed
  //             .toList();
  //
  //         if (documentMessages.isEmpty) {
  //           return Container();
  //         }
  //
  //         return ListView.builder(
  //           itemCount: documentMessages.length,
  //           itemBuilder: (context, index) {
  //             var document = documentMessages[index];
  //             var contentUrl = document['content'];
  //             var timestamp = (document['sentAt'] as Timestamp).toDate();
  //             var formattedDate = DateFormat('yyyy/MM/dd, HH:mm', context.locale.toString()).format(timestamp);
  //
  //
  //             return GestureDetector(
  //               onTap: () {
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) => PDFViewScreen(
  //                       filePath: contentUrl,
  //                       fileName: document['fileName'] ?? 'Document',
  //                       dateTime: timestamp,
  //                     ),
  //                   ),
  //                 );
  //               },
  //               child: Container(
  //                 color: Colors.transparent,
  //                 child: Column(
  //                   children: [
  //                     Container(
  //                       padding: EdgeInsets.all(12),
  //                       child: Row(
  //                         children: [
  //                           Icon(Icons.description, color: Colors.blue),
  //                           SizedBox(width: 12),
  //                           Expanded(
  //                             child: Column(
  //                               crossAxisAlignment: CrossAxisAlignment.start,
  //                               children: [
  //                                 Text(
  //                                   contentUrl,
  //                                   overflow: TextOverflow.ellipsis,
  //                                   style: StyleText(fontWeight: FontWeight.bold),
  //                                 ),
  //                                 SizedBox(height: 4),
  //                                 Text(
  //                                   formattedDate,
  //                                   style: StyleText(fontSize: 13, color: Colors.grey),
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                     Divider(
  //                       height: 1,
  //                       indent: 15,
  //                       endIndent: 15,
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           },
  //         );
  //       },
  //     ),
  //   );
  // }

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

          final documentMessages = snapshot.data!.docs
              .expand((doc) => (doc['messages'] as List)
              .where((msg) => msg['messageType'] == 'Document'))
              .toList()
              .reversed
              .toList();

          if (documentMessages.isEmpty) {
            return Container();
          }

          return ListView.builder(
            itemCount: documentMessages.length,
            itemBuilder: (context, index) {
              var document = documentMessages[index];
              var contentUrl = document['content'];
              var fileName = document['fileName'] ?? 'dokumen'.tr();
              var timestamp = (document['sentAt'] as Timestamp).toDate();
              var formattedDate = DateFormat('yyyy/MM/dd, HH:mm', context.locale.toString())
                  .format(timestamp);

              return ListTile(
                leading: Icon(Icons.description, color: Colors.blue),
                title: Text(
                  document['fileName'] ?? 'dokumen'.tr(),
                  style: StyleText(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  formattedDate,
                  style: StyleText(fontSize: 13, color: Colors.grey),
                ),
                onTap: () => _downloadAndOpenPDF(contentUrl, fileName, DateTime.now()),
                // onTap: () {
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (context) => PDFViewScreen(
                //         filePath: contentUrl,
                //         fileName: document['fileName'] ?? 'Document',
                //         dateTime: timestamp,
                //       ),
                //     ),
                //   );
                // },
              );
            },
          );
        },
      ),
    );
  }
}

//

class MediaPageGroup extends StatefulWidget {
  final List<UserProfile> users;
  late final Group grup;

  MediaPageGroup({required this.users, required this.grup});

  @override
  State<MediaPageGroup> createState() => _MediaPageGroupState();
}

class _MediaPageGroupState extends State<MediaPageGroup> {
  int _selectedIndex = 0;
  PageController controller = PageController();
  List<Map<String, dynamic>> mediaList = [];

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
    fetchMediaList();
  }

  Future<void> fetchMediaList() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('messagesGroup')
        .where('groupId', isEqualTo: widget.grup.id)
        .orderBy('createdAt', descending: true)
        .get();

    List<Map<String, dynamic>> tempList = [];
    for (var doc in snapshot.docs) {
      if (doc['medias'] != null) {
        for (var media in doc['medias']) {
          tempList.add({
            'url': media['url'],
            'type': media['type'],
          });
        }
      }
    }

    setState(() {
      mediaList = tempList;
    });
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
                            'tautan'.tr(),
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
                MediaGroup(),
                TautanGroup(),
                DocumentGroup(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget TautanGroup() {
    bool _isUrl(String text) {
      final urlPattern = RegExp(
        r'^(https?|ftp)://[^\s/$.?#].[^\s]*$',
        caseSensitive: false,
      );
      return urlPattern.hasMatch(text);
    }

    Future<void> _launchURL(String url) async {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri)) {
        throw Exception('Could not launch $uri');
      }
    }

    return Center(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messagesGroup')
            .where('groupId', isEqualTo: widget.grup.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Container();
          }

          final linkMessages = snapshot.data!.docs
              .where((msg) => _isUrl(msg['text']))
              .toList()
              .reversed
              .toList();

          if (linkMessages.isEmpty) {
            return Container();
          }

          return ListView.builder(
            itemCount: linkMessages.length,
            itemBuilder: (context, index) {
              final contentUrl = linkMessages[index]['text'];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: AnyLinkPreview(
                  displayDirection: UIDirection.uiDirectionHorizontal,
                  link: contentUrl,
                  onTap: () => _launchURL(contentUrl),
                  showMultimedia: true,
                  bodyStyle: const TextStyle(fontSize: 12),
                  errorWidget: Container(),
                  errorImage: "https://google.com/",
                  cache: const Duration(seconds: 3),
                  borderRadius: 12,
                  removeElevation: false,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget MediaGroup() {
    return mediaList.isEmpty
        ? Center(child: CircularProgressIndicator())
        : Container(
            padding: EdgeInsets.all(10),
            child: LayoutGrid(
              columnSizes: [1.fr, 1.fr],
              rowSizes:
                  List.generate((mediaList.length / 2).ceil(), (index) => auto),
              rowGap: 12,
              columnGap: 12,
              children: mediaList.map((media) {
                if (media['type'] == 'video') {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerGroup(
                            videoUrl: media['url'],
                            users: widget.users,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoMessage(url: media['url']),
                          Icon(
                            Icons.play_circle,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (media['type'] == 'image') {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageViewGroup(
                            imageUrl: media['url'],
                            users: widget.users,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        media['url'],
                        fit: BoxFit.cover,
                        height: 200,
                        width: double.infinity,
                      ),
                    ),
                  );
                } else {
                  return Container();
                }
              }).toList(),
            ),
          );
  }

  Widget DocumentGroup() {
    return Center(
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('messagesGroup')
            .where('groupId', isEqualTo: widget.grup.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Container();
          }

          final documentImages = snapshot.data!.docs.expand((doc) {
            final medias = doc['medias'] as List<dynamic>?;
            return medias?.where((media) => media['type'] == 'file') ?? [];
          }).toList();

          if (documentImages.isEmpty) {
            return Container();
          }

          return ListView.builder(
            itemCount: documentImages.length,
            itemBuilder: (context, index) {
              var doc = documentImages[index];
              var docs = doc['url'];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocsGroup(
                        docu: docs,
                        users: widget.users,
                      ),
                    ),
                  );
                },
                child: Container(
                  color: Colors.transparent,
                  child: Column(
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
                                    docs,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        StyleText(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '-',
                                    style: StyleText(
                                        fontSize: 13, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        indent: 15,
                        endIndent: 15,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}