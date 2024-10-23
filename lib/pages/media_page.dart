import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

    controller.animateToPage(_selectedIndex,
        duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
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
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
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
                      // GestureDetector(
                      //   onTap: () {
                      //     _navigateBottomBar(0);
                      //   },
                      //   child: Container(
                      //     alignment: Alignment.center,
                      //     height: 30,
                      //     width: 100,
                      //     decoration: BoxDecoration(
                      //       color: _selectedIndex == 0
                      //           ? Colors.deepPurple.shade100
                      //           : Colors.grey.shade300,
                      //       borderRadius: BorderRadius.only(
                      //         topLeft: Radius.circular(5),
                      //         bottomLeft: Radius.circular(5),
                      //       ),
                      //     ),
                      //     child: Text(
                      //       'Media',
                      //       style: TextStyle(
                      //         color: Theme.of(context).colorScheme.primary,
                      //         fontWeight: _selectedIndex == 0
                      //             ? FontWeight.bold
                      //             : FontWeight.normal,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      GestureDetector(
                        onTap: () {
                          _navigateBottomBar(0);
                        },
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
                            'Media',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedIndex == 0
                                  ? Colors.white : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      VerticalDivider(
                        thickness: 2,
                        width: 3,
                      ),
                      GestureDetector(
                        onTap: () {
                          _navigateBottomBar(1);
                        },
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
                            'Document',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedIndex == 1
                                  ? Colors.white : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      // GestureDetector(
                      //   onTap: () {
                      //     _navigateBottomBar(1);
                      //   },
                      //   child: Container(
                      //     alignment: Alignment.center,
                      //     height: 30,
                      //     width: 100,
                      //     decoration: BoxDecoration(
                      //       color: _selectedIndex == 1
                      //           ? Colors.deepPurple.shade100
                      //           : Colors.grey.shade300,
                      //       borderRadius: BorderRadius.only(
                      //         topRight: Radius.circular(5),
                      //         bottomRight: Radius.circular(5),
                      //       ),
                      //     ),
                      //     child: Text(
                      //       'Document',
                      //       style: TextStyle(
                      //         color: Theme.of(context).colorScheme.primary,
                      //         fontWeight: _selectedIndex == 1
                      //             ? FontWeight.bold
                      //             : FontWeight.normal,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
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
