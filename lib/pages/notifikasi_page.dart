import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/group.dart';

class NotifikasiPage extends StatefulWidget {
  final Group group;

  NotifikasiPage({required this.group});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  bool isNotif = false;

  void _showModalBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sound Notification',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(10),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  (isNotif == true)
                      ? 'Other members will not see that you muted this chat. You will still be notified if you are mentioned.'
                      : 'You will be notified of all messages in this chat.',
                  textAlign:
                      (isNotif == true) ? TextAlign.left : TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isNotif = !isNotif;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  width: MediaQuery.sizeOf(context).width,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    (isNotif == true) ? 'Muted' : 'Sound it out',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
              'Notification',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.group.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          GestureDetector(
            onTap: () async {
              _showModalBottomSheet(context);
            },
            child: Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(top: 20, left: 20, right: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (isNotif == true) ? 'Mute Notifications' : 'Sound it out',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
