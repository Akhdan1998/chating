import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MediaPage extends StatefulWidget {
  const MediaPage({super.key});

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  int _selectedIndex = 0;
  PageController controller = PageController();
  List<String> _mediaUrls = [];
  List<String> _documentUrls = [];

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });

    controller.animateToPage(_selectedIndex,
        duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: _selectedIndex);
    _fetchMediaUrls();
    _fetchDocumentUrls();
  }

  Future<void> _fetchMediaUrls() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore.collection('chats').get();
      final mediaUrls = querySnapshot.docs
          .where((doc) => doc.data().containsKey('messageType') && doc['messageType'] == 'Image')
          .map((doc) => doc['content'] as String)
          .toList();

      setState(() {
        _mediaUrls = mediaUrls;
      });
    } catch (e) {
      print('Error fetching media URLs: $e');
    }
  }

  Future<void> _fetchDocumentUrls() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore.collection('chats').get();
      final documentUrls = querySnapshot.docs
          .where((doc) => doc.data().containsKey('messageType') && doc['messageType'] == 'Document')
          .map((doc) => doc['content'] as String)
          .toList();

      setState(() {
        _documentUrls = documentUrls;
      });
    } catch (e) {
      print("Error fetching document URLs: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   automaticallyImplyLeading: true,
      //   centerTitle: true,
      //   backgroundColor: Theme.of(context).colorScheme.primary,
      //   leading: IconButton(
      //     icon: Icon(
      //       Icons.arrow_back,
      //       color: Colors.white,
      //     ),
      //     onPressed: () {
      //       Navigator.pop(context);
      //     },
      //   ),
      //   title: Text(
      //     'Contact Info',
      //     overflow: TextOverflow.ellipsis,
      //     style: TextStyle(
      //       color: Colors.white,
      //       fontSize: 18,
      //       fontWeight: FontWeight.bold,
      //     ),
      //   ),
      // ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: 50),
            color: Theme.of(context).colorScheme.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _navigateBottomBar(0);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        height: 30,
                        width: 100,
                        decoration: BoxDecoration(
                          color: _selectedIndex == 0
                              ? Colors.deepPurple.shade100
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(5),
                            bottomLeft: Radius.circular(5),
                          ),
                        ),
                        child: Text(
                          'Media',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: _selectedIndex == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    VerticalDivider(
                      thickness: 3,
                      width: 3,
                    ),
                    GestureDetector(
                      onTap: () {
                        _navigateBottomBar(1);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        height: 30,
                        width: 100,
                        decoration: BoxDecoration(
                          color: _selectedIndex == 1
                              ? Colors.deepPurple.shade100
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(5),
                            bottomRight: Radius.circular(5),
                          ),
                        ),
                        child: Text(
                          'Document',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: _selectedIndex == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height - 98,
            width: MediaQuery.of(context).size.width,
            child: PageView(
              controller: controller,
              children: [
                Media(),
                Document(),
                // MediaContent(mediaUrls: _mediaUrls),
                // DocumentContent(documentUrls: _documentUrls),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget MediaContent({required List<String> mediaUrls}) {
    return ListView.builder(
      itemCount: mediaUrls.length,
      itemBuilder: (context, index) {
        final url = mediaUrls[index];
        return Image.network(
          url,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Text('Failed to load image');
          },
        );
      },
    );
  }


  Widget DocumentContent({required List<String> documentUrls}) {
    return ListView.builder(
      itemCount: documentUrls.length,
      itemBuilder: (context, index) {
        final url = documentUrls[index];
        return Image.network(url); // Misalnya hanya menampilkan gambar
      },
    );
  }

  Widget Media() {
    return Center(
      child: Text('Media'),
    );
  }

  Widget Document() {
    return Center(
      child: Text('Document'),
    );
  }
}