import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../consts.dart';

class PanggilanPage extends StatefulWidget {

  @override
  State<PanggilanPage> createState() => _PanggilanPageState();
}

class _PanggilanPageState extends State<PanggilanPage> {
  int _selectedIndex = 0;
  PageController controller = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });

    controller.animateToPage(
      _selectedIndex,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 15,
        toolbarHeight: 100,
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: Colors.white,
                  ),
                  width: 207,
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _navigateBottomBar(0);
                        },
                        child: Container(
                          width: 100,
                          height: 35,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: _selectedIndex == 0
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade200,
                          ),
                          child: Text(
                            'All',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedIndex == 0
                                  ? Colors.white : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 2),
                      GestureDetector(
                        onTap: () {
                          _navigateBottomBar(1);
                        },
                        child: Container(
                          width: 100,
                          height: 35,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: _selectedIndex == 1
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade200,
                          ),
                          child: Text(
                            'Missed',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedIndex == 1
                                  ? Colors.white : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.add_circle,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                'Calling',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: PageView(
          physics: NeverScrollableScrollPhysics(),
          controller: controller,
          children: [
            AllCallsPage(),
            MissedCallsPage(),
          ],
        ),
      ),
    );
  }
}

class AllCallsPage extends StatelessWidget {
  const AllCallsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(15),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('call_history')
                  .orderBy('callDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No call history found.'));
                }

                final callHistory = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: callHistory.length,
                  itemBuilder: (context, index) {
                    final call = callHistory[index].data() as Map<String, dynamic>;
                    final DateTime callDate = (call['callDate'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final String dayOfWeek = DateFormat.EEEE().format(callDate);

                    return Column(
                      children: [
                        CallItem(
                          name: call['callerName'] ?? '',
                          date: dayOfWeek,
                          callType: call['type'] ?? '',
                          avatarUrl: call['callerImage'] ?? '',
                        ),
                        SizedBox(height: 10),
                      ],
                    );
                  },
                );

              },
            ),
          ),
        ],
      ),
    );
  }
}

class CallItem extends StatelessWidget {
  final String name;
  final String date;
  final String callType;
  final String avatarUrl;

  const CallItem({
    required this.name,
    required this.date,
    required this.callType,
    required this.avatarUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade200,
      ),
      child: Row(
        children: [
          CircleAvatar(
      child: avatarUrl.isEmpty ? Icon(Icons.person, color: Colors.white,) : null,
            backgroundImage: NetworkImage(avatarUrl.isNotEmpty ? avatarUrl : 'PLACEHOLDER_PFP'),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isNotEmpty ? name : '', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(callType == 'voice' ? Icons.call : Icons.videocam, size: 15),
                        SizedBox(width: 5),
                        Text(callType.isNotEmpty ? callType : '', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      date.isNotEmpty ? date : '',
                      style: TextStyle(fontSize: 10),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.info_outline, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MissedCallsPage extends StatelessWidget {
  const MissedCallsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 15, right: 15, top: 15),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(PLACEHOLDER_PFP),
                ),
                SizedBox(width: 10),
                Container(
                  width: MediaQuery.of(context).size.width - 110,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sadelih'),
                          Row(
                            children: [
                              Icon(
                                Icons.missed_video_call_outlined,
                                size: 20,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Unanswered',
                                style: TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Sunday',
                            style: TextStyle(fontSize: 10),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.info_outline,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
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
