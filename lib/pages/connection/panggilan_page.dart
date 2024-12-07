import 'package:chating/widgets/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/consts.dart';

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
                            'all_call'.tr(),
                            style: StyleText(
                              fontSize: 12,
                              color: _selectedIndex == 0
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
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
                            'missed'.tr(),
                            style: StyleText(
                              fontSize: 12,
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
                'calling'.tr(),
                style: StyleText(
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
  AllCallsPage({super.key});

  String? userUid;

  @override
  Widget build(BuildContext context) {
    if (userUid == null) {
      return Center(
        child: Text(
          'try_call'.tr(),
          style: StyleText(color: Colors.grey),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('calls')
            .where('currentUserUID', isEqualTo: userUid)
            .orderBy('callDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'call_history'.tr(),
                style: StyleText(color: Colors.grey),
              ),
            );
          }

          final callHistory = snapshot.data!.docs;

          return ListView.separated(
            itemCount: callHistory.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              final call = callHistory[index].data() as Map<String, dynamic>;
              final DateTime callDate =
                  (call['callDate'] as Timestamp?)?.toDate() ?? DateTime.now();
              final String formattedDate =
                  DateFormat.yMMMd(context.locale.toString()).format(callDate);
              final String formattedTime = DateFormat.Hm().format(callDate);
              final String callType = call['type'] ?? 'voice';
              final String durationStr = call['callDuration'] ?? '00:00';
              final List<String> parts = durationStr.split(':');
              final int minutes = int.tryParse(parts[0]) ?? 0;
              final int seconds = int.tryParse(parts[1]) ?? 0;
              final int callDurationInSeconds = (minutes * 60) + seconds;

              return CallItem(
                name: call['callerName'] ?? '',
                date: formattedDate,
                time: formattedTime,
                callType: callType,
                avatarUrl: call['callerImage'] ?? '',
                callerPhoneNumber: call['callerPhoneNumber'] ?? '',
                duration: callDurationInSeconds,
              );
            },
          );
        },
      ),
    );
  }
}

class CallItem extends StatefulWidget {
  final String name;
  final String date;
  final String time;
  final String callType;
  final String avatarUrl;
  final String callerPhoneNumber;
  final int duration;

  const CallItem({
    required this.name,
    required this.date,
    required this.time,
    required this.callType,
    required this.avatarUrl,
    required this.callerPhoneNumber,
    required this.duration,
    super.key,
  });

  @override
  State<CallItem> createState() => _CallItemState();
}

class _CallItemState extends State<CallItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 15, top: 15, bottom: 15),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundImage: widget.avatarUrl.isNotEmpty
                    ? NetworkImage(widget.avatarUrl)
                    : null,
                child: widget.avatarUrl.isEmpty ? Icon(Icons.person) : null,
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name, style: StyleText(fontSize: 16)),
                  Row(
                    children: [
                      Icon(
                        widget.callType == 'voice'
                            ? Icons.call
                            : Icons.videocam,
                        size: 15,
                      ),
                      SizedBox(width: 5),
                      Text(
                        widget.callType == 'voice' ? tr('voice') : tr('video'),
                        style: StyleText(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.date.isNotEmpty ? widget.date : '',
                    style: StyleText(fontSize: 10),
                  ),
                  Text(
                    widget.time.isNotEmpty ? widget.time : '',
                    style: StyleText(fontSize: 9),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: '',
                    barrierColor: Colors.black54,
                    transitionDuration: Duration(milliseconds: 300),
                    pageBuilder: (context, anim1, anim2) {
                      return AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(widget.duration ~/ 60).toString().padLeft(2, '0')}:${(widget.duration % 60).toString().padLeft(2, '0')}',
                              style: StyleText(fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    },
                    transitionBuilder: (context, anim1, anim2, child) {
                      return Transform.scale(
                        scale: anim1.value,
                        child: child,
                      );
                    },
                  );
                },
                icon: Icon(Icons.info_outline, size: 20),
              ),
            ],
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
                          Text(
                            'Sadelih',
                            style: StyleText(),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.missed_video_call_outlined,
                                size: 20,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Unanswered',
                                style: StyleText(fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Sunday',
                            style: StyleText(fontSize: 10),
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
