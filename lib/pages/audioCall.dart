import 'package:flutter/material.dart';

class AudioCallScreen extends StatefulWidget {
  final String meetingId;

  AudioCallScreen({required this.meetingId});

  @override
  _AudioCallScreenState createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audio Call'),
      ),
      body: Center(
        child: Text('Audio Call Screen'),
      ),
    );
  }
}
